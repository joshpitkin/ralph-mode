#!/bin/bash
set -e

# Ensure GitHub Copilot CLI is set up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/setup-copilot.sh" || exit 1

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations> [model] [extra_instructions]"
  exit 1
fi

ITERATIONS=$1
MODEL="${2:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="--model $MODEL"
fi

EXTRA_ARG="${3:-}"
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

  PROMPT_LINES=()
  if [ -f "$EXTRA_FILE" ]; then
    PROMPT_LINES+=("@$EXTRA_FILE")
  fi
  if [ -n "$EXTRA_INSTRUCTIONS" ]; then
    PROMPT_LINES+=("Additional instructions:" "$EXTRA_INSTRUCTIONS")
  fi
  PROMPT_LINES+=(
    "@prd.json @progress.txt"
    "1. Find the highest-priority task and implement it."
    "2. Run your tests and type checks."
    "3. Update the PRD with what was done."
    "4. Append your progress to progress.txt."
    "5. Commit your changes."
    "6. Update the prd.json with passes:true if the task is fully complete."
    "ONLY WORK ON A SINGLE TASK."
    "If the PRD is complete, output <promise>COMPLETE</promise>."
  )
  PROMPT="$(printf '%s\n' "${PROMPT_LINES[@]}")"

  result=$(copilot $MODEL_FLAG -p "$PROMPT")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi
done

echo "Completed $ITERATIONS iterations. Check progress.txt for status."
