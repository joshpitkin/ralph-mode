#!/bin/bash
set -e

# Derive a stable container name from the current project directory name.
# This means each project gets its own persistent environment.
CONTAINER_NAME="ralph-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"

# Check if the container is already running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '$CONTAINER_NAME' is already running."
  echo ""
  echo "  Open a shell:            ./ralph-env-shell.sh"
  echo "  Run afk loop (external): ./ralph-env-afk.sh <iterations> [model]"
  echo "  Stop container:          ./ralph-env-stop.sh"
  echo ""
  echo "From inside the shell, run:  ralph <iterations> [model]"
  exit 0
fi

# Remove any stopped container with the same name
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Require GH_TOKEN
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN environment variable must be set"
  echo "Run: export GH_TOKEN=\$(gh auth token)"
  exit 1
fi

echo "Starting persistent ralph environment: $CONTAINER_NAME"
echo "Workspace: $PWD"
echo ""

docker run -d \
  --name "$CONTAINER_NAME" \
  -v "$PWD:/workspace" \
  -w /workspace \
  -e GH_TOKEN="${GH_TOKEN}" \
  ${FIRECRAWL_API_KEY:+-e FIRECRAWL_API_KEY="${FIRECRAWL_API_KEY}"} \
  ralph-copilot:latest \
  tail -f /dev/null

# Brief pause to let the container process start before exec-ing into it
sleep 1

# Authenticate GitHub CLI inside the container.
# Non-fatal: the token is already exported as $GH_TOKEN in the container env,
# so copilot commands can still work even if gh auth login returns non-zero.
echo "Authenticating GitHub CLI..."
docker exec "$CONTAINER_NAME" bash -c 'echo "$GH_TOKEN" | gh auth login --with-token 2>&1' || \
  echo "Warning: gh auth login returned non-zero (token may already be set or is invalid — check GH_TOKEN)."
echo "GitHub CLI step done."

# Seed global Copilot instructions into workspace if not already present
echo "Seeding Copilot instructions..."
docker exec "$CONTAINER_NAME" bash -c '
  mkdir -p /workspace/.github
  cp -n ~/.config/github-copilot/copilot-instructions.md /workspace/.github/copilot-instructions.md 2>/dev/null || true
'
echo "Instructions seeded."

# Inject the `ralph` helper command so it can be invoked from inside the shell.
# This command mirrors the afk loop logic but runs entirely within the container.
TMPSCRIPT=$(mktemp)
cat > "$TMPSCRIPT" << 'INNERSCRIPT'
#!/bin/bash
# ralph - run the Copilot yolo loop from inside the ralph environment container.
#
# Usage: ralph <iterations> [model] [prd_id]
#
# STEERING.md is re-read at the start of every iteration so you can steer the
# agent between loops by editing the file without restarting the container.
# Place STEERING.md in your project root (/workspace).

set -e

if [ -z "$1" ]; then
  echo "Usage: ralph <iterations> [model] [prd_id]"
  echo ""
  echo "  iterations  Number of loop iterations to run"
  echo "  model       Optional model name (passed as --model)"
  echo "  prd_id      Optional specific task id to work on"
  echo ""
  echo "Reads STEERING.md, ralph-extra.md, prd.json, and progress.txt from the workspace."
  exit 1
fi

ITERATIONS=$1
MODEL="${2:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="--model $MODEL"
fi

PRD_ID="${3:-}"
PRD_TEXT="1. Use jq to find the next task"
if [ -n "$PRD_ID" ]; then
  PRD_TEXT="1. Use jq to find the task with id $PRD_ID"
fi

EXTRA_FILE="${RALPH_EXTRA_FILE:-ralph-extra.md}"

for ((i=1; i<=$ITERATIONS; i++)); do
  echo "Iteration $i of $ITERATIONS..."

  PROMPT_LINES=()

  # Re-read STEERING.md at the top of every iteration so edits take effect
  # between loops without restarting the container.
  if [ -f "STEERING.md" ]; then
    PROMPT_LINES+=("@STEERING.md")
  fi
  if [ -f "$EXTRA_FILE" ]; then
    PROMPT_LINES+=("@$EXTRA_FILE")
  fi
  PROMPT_LINES+=(
    "@prd.json @progress.txt"
    "$PRD_TEXT in the @prd.json file.  Filter for incomplete tasks (passes:false) and sort by priority ascending.  Take the first one you find and implement it."
    "2. Run your tests and type checks."
    "3. Update the PRD with what was done."
    "4. Append your progress to progress.txt."
    "5. Commit your changes."
    "6. Update the prd.json with passes:true if the task is fully complete."
    "ONLY WORK ON A SINGLE TASK."
    "If the PRD is complete, output <promise>COMPLETE</promise>."
  )
  PROMPT="$(printf '%s\n' "${PROMPT_LINES[@]}")"

  TEMP_OUTPUT=$(mktemp)
  # shellcheck disable=SC2086
  copilot $MODEL_FLAG --yolo -p "$PROMPT" | tee "$TEMP_OUTPUT"

  if grep -q "<promise>COMPLETE</promise>" "$TEMP_OUTPUT"; then
    rm "$TEMP_OUTPUT"
    echo "PRD complete after $i iterations."
    exit 0
  fi
  rm "$TEMP_OUTPUT"
done

echo "Completed $ITERATIONS iterations. Check progress.txt for status."
INNERSCRIPT

echo "Copying ralph helper into container..."
docker cp "$TMPSCRIPT" "$CONTAINER_NAME:/tmp/ralph-helper"
rm "$TMPSCRIPT"
echo "Installing ralph helper..."
docker exec -u root "$CONTAINER_NAME" bash -c 'install -m 755 /tmp/ralph-helper /usr/local/bin/ralph && rm /tmp/ralph-helper'
echo "ralph helper installed."

echo ""
echo "Container '$CONTAINER_NAME' is ready."
echo ""
echo "  Open a shell:            ./ralph-env-shell.sh"
echo "  Run afk loop (external): ./ralph-env-afk.sh <iterations> [model]"
echo "  Stop container:          ./ralph-env-stop.sh"
echo ""
echo "From inside the shell, run:  ralph <iterations> [model]"
