#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for ((i=1; i<=$1; i++)); do
  echo "Iteration $i of $1..."
  
  result=$(docker run --rm \
    -v "$SCRIPT_DIR:/workspace" \
    -w /workspace \
    -e GH_TOKEN="${GH_TOKEN}" \
    ralph-copilot:latest \
    bash -c 'gh copilot suggest "@prd.json @progress.txt \
  1. Find the highest-priority task and implement it. \
  2. Run your tests and type checks. \
  3. Update the PRD with what was done. \
  4. Append your progress to progress.txt. \
  5. Commit your changes. \
  ONLY WORK ON A SINGLE TASK. \
  If the PRD is complete, output <promise>COMPLETE</promise>."')

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi
done

echo "Completed $1 iterations. Check progress.txt for status."
