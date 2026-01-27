#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations> [model]"
  exit 1
fi

ITERATIONS=$1
MODEL="${2:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="--model $MODEL"
fi

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
    ralph-copilot:latest \
    bash -c "
      # Authenticate with GitHub
      echo \"\$GH_TOKEN\" | gh auth login --with-token
      
      # Run the copilot command
      copilot $MODEL_FLAG --yolo -p \"@prd.json @progress.txt \
  1. Find the highest-priority task and implement it. \
  2. Run your tests and type checks. \
  3. Update the PRD with what was done. \
  4. Append your progress to progress.txt. \
  5. Commit your changes. \
  6. Update the prd.json with passes:true if the task is fully complete. \
  ONLY WORK ON A SINGLE TASK. \
  If the PRD is complete, output <promise>COMPLETE</promise>.\"
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
