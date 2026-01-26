#!/bin/bash
set -e

# Ensure GitHub Copilot CLI is set up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/setup-copilot.sh" || exit 1

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations> [model]"
  exit 1
fi

ITERATIONS=$1
MODEL="${2:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="-m $MODEL"
fi

for ((i=1; i<=$ITERATIONS; i++)); do
  echo "Iteration $i of $ITERATIONS..."
  
  result=$(gh copilot suggest $MODEL_FLAG "@prd.json @progress.txt \
  1. Find the highest-priority task and implement it. \
  2. Run your tests and type checks. \
  3. Update the PRD with what was done. \
  4. Append your progress to progress.txt. \
  5. Commit your changes. \
  ONLY WORK ON A SINGLE TASK. \
  If the PRD is complete, output <promise>COMPLETE</promise>.")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi
done

echo "Completed $ITERATIONS iterations. Check progress.txt for status."
