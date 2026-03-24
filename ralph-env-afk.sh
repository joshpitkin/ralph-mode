#!/bin/bash
set -e

# Run the Copilot afk loop inside an already-running ralph environment container.
# Start the container first with: ./ralph-env-start.sh
#
# Usage: ./ralph-env-afk.sh <iterations> [model] [prd_id] [extra_instructions]

# Derive the container name from the current project directory (must match ralph-env-start.sh)
CONTAINER_NAME="ralph-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "No running environment found for this project (expected container: $CONTAINER_NAME)."
  echo "Start one with: ./ralph-env-start.sh"
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations> [model] [prd_id] [extra_instructions]"
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

EXTRA_ARG="${4:-}"
EXTRA_FILE="${RALPH_EXTRA_FILE:-ralph-extra.md}"
EXTRA_INSTRUCTIONS="${RALPH_EXTRA:-}"
if [ -n "$EXTRA_ARG" ]; then
  if [ -n "$EXTRA_INSTRUCTIONS" ]; then
    EXTRA_INSTRUCTIONS="$EXTRA_INSTRUCTIONS"$'\n'"$EXTRA_ARG"
  else
    EXTRA_INSTRUCTIONS="$EXTRA_ARG"
  fi
fi

for ((i=1; i<=$ITERATIONS; i++)); do
  echo "Iteration $i of $ITERATIONS..."

  # Build the prompt fresh each iteration so STEERING.md changes take effect
  # immediately without restarting the container.
  PROMPT_LINES=()
  if [ -f "STEERING.md" ]; then
    PROMPT_LINES+=("@STEERING.md")
  fi
  if [ -f "$EXTRA_FILE" ]; then
    PROMPT_LINES+=("@$EXTRA_FILE")
  fi
  if [ -n "$EXTRA_INSTRUCTIONS" ]; then
    PROMPT_LINES+=("Additional instructions:" "$EXTRA_INSTRUCTIONS")
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
  # Pass the prompt via environment variable to avoid shell quoting issues
  # shellcheck disable=SC2086
  docker exec -t -w /workspace \
    -e RALPH_PROMPT="$PROMPT" \
    "$CONTAINER_NAME" \
    bash -c "copilot $MODEL_FLAG --yolo -p \"\$RALPH_PROMPT\"" | tee "$TEMP_OUTPUT"

  if grep -q "<promise>COMPLETE</promise>" "$TEMP_OUTPUT"; then
    rm "$TEMP_OUTPUT"
    echo "PRD complete after $i iterations."
    exit 0
  fi
  rm "$TEMP_OUTPUT"
done

echo "Completed $ITERATIONS iterations. Check progress.txt for status."
