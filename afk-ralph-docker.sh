#!/bin/bash
set -e

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

PROMPT_LINES=()
if [ -f "$EXTRA_FILE" ]; then
  PROMPT_LINES+=("@$EXTRA_FILE")
fi
if [ -n "$EXTRA_INSTRUCTIONS" ]; then
  PROMPT_LINES+=("Additional instructions:" "$EXTRA_INSTRUCTIONS")
fi
PROMPT_LINES+=(
  "@prd.json @progress.txt"
  "$PRD_TEXT in the @prd.json file.  Filter for incomplete tasks (passes :false) and sort by priority ascending.  Take the first one you find and implement it."
  "2. Run your tests and type checks."
  "3. Update the PRD with what was done."
  "4. Append your progress to progress.txt."
  "5. Commit your changes."
  "6. Update the prd.json with passes:true if the task is fully complete."
  "ONLY WORK ON A SINGLE TASK."
  "If the PRD is complete, output <promise>COMPLETE</promise>."
)
PROMPT="$(printf '%s\n' "${PROMPT_LINES[@]}")"

# Check if GH_TOKEN is set
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN environment variable must be set"
  echo "Run: export GH_TOKEN=\$(gh auth token)"
  exit 1
fi

for ((i=1; i<=$ITERATIONS; i++)); do
  echo "Iteration $i of $ITERATIONS..."
  
  # Run docker with -t for terminal output, capture output to temp file
  TEMP_OUTPUT=$(mktemp)
  docker run --rm -t \
    -v "$PWD:/workspace" \
    -w /workspace \
    -e GH_TOKEN="${GH_TOKEN}" \
    -e RALPH_PROMPT="$PROMPT" \
    ralph-copilot:latest \
    bash -c "
      # Authenticate with GitHub
      echo \"\$GH_TOKEN\" | gh auth login --with-token
      
      # Run the copilot command
      copilot $MODEL_FLAG --yolo -p \"\$RALPH_PROMPT\"
    " | tee "$TEMP_OUTPUT"
  
  # Check for completion in captured output
  if grep -q "<promise>COMPLETE</promise>" "$TEMP_OUTPUT"; then
    rm "$TEMP_OUTPUT"
    echo "PRD complete after $i iterations."
    exit 0
  fi
  rm "$TEMP_OUTPUT"
done

echo "Completed $ITERATIONS iterations. Check progress.txt for status."
