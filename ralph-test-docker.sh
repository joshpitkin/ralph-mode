#!/bin/bash

# Ralph-once with Docker isolation
# This runs a single iteration inside a Docker container

# Optional model parameter
MODEL="${1:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="--model $MODEL"
fi

EXTRA_ARG="${2:-}"
EXTRA_FILE="${RALPH_EXTRA_FILE:-ralph-extra.md}"
EXTRA_INSTRUCTIONS="${RALPH_EXTRA:-}"
if [ -n "$EXTRA_ARG" ]; then
  if [ -n "$EXTRA_INSTRUCTIONS" ]; then
    EXTRA_INSTRUCTIONS="$EXTRA_INSTRUCTIONS"$'\n'"$EXTRA_ARG"
  else
    EXTRA_INSTRUCTIONS="$EXTRA_ARG"
  fi
fi

PROMPT_LINES=()
if [ -f "$EXTRA_FILE" ]; then
  PROMPT_LINES+=("@$EXTRA_FILE")
fi
if [ -n "$EXTRA_INSTRUCTIONS" ]; then
  PROMPT_LINES+=("$EXTRA_INSTRUCTIONS")
fi
# PROMPT_LINES+=(
#   "@prd.json @progress.txt"
#   "1. Read the PRD and progress file."
#   "2. Find the next incomplete task with the lowest priority number and implement it."
#   "3. Commit your changes."
#   "4. Update progress.txt with what you did."
#   "5. Update the prd.json with passes:true if the task is fully complete."
#   "ONLY DO ONE TASK AT A TIME."
# )
PROMPT="$(printf '%s\n' "${PROMPT_LINES[@]}")"

# Check if GH_TOKEN is set
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN environment variable must be set"
  echo "Run: export GH_TOKEN=\$(gh auth token)"
  exit 1
fi

docker run --rm -it \
  -v "$PWD:/workspace" \
  -w /workspace \
  -e GH_TOKEN="${GH_TOKEN}" \
  -e RALPH_PROMPT="$PROMPT" \
  ${FIRECRAWL_API_KEY:+-e FIRECRAWL_API_KEY="${FIRECRAWL_API_KEY}"} \
  ralph-copilot:latest \
  bash -c "
    # Authenticate with GitHub
    echo \"\$GH_TOKEN\" | gh auth login --with-token

    # Seed global Copilot instructions into workspace if not already present
    mkdir -p /workspace/.github
    cp -n ~/.config/github-copilot/copilot-instructions.md /workspace/.github/copilot-instructions.md 2>/dev/null || true

    # Run the copilot command
    copilot $MODEL_FLAG --yolo -p \"\$RALPH_PROMPT\"
  "
