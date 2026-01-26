#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations> [model]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ITERATIONS=$1
MODEL="${2:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="-m $MODEL"
fi

# Check if GH_TOKEN is set
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN environment variable must be set"
  echo "Run: export GH_TOKEN=\$(gh auth token)"
  exit 1
fi

for ((i=1; i<=$ITERATIONS; i++)); do
  echo "Iteration $i of $ITERATIONS..."
  
  result=$(docker run --rm \
    -v "$SCRIPT_DIR:/workspace" \
    -w /workspace \
    -e GH_TOKEN="${GH_TOKEN}" \
    ralph-copilot:latest \
    bash -c "
      # Authenticate and install copilot extension (if not already done)
      echo \"\$GH_TOKEN\" | gh auth login --with-token
      gh extension list | grep -q github/gh-copilot || gh extension install github/gh-copilot
      
      # Run the copilot command
      gh copilot suggest $MODEL_FLAG \"@prd.json @progress.txt \
  1. Find the highest-priority task and implement it. \
  2. Run your tests and type checks. \
  3. Update the PRD with what was done. \
  4. Append your progress to progress.txt. \
  5. Commit your changes. \
  ONLY WORK ON A SINGLE TASK. \
  If the PRD is complete, output <promise>COMPLETE</promise>.\"
    ")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi
done

echo "Completed $ITERATIONS iterations. Check progress.txt for status."
