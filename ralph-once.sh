#!/bin/bash

# Ensure GitHub Copilot CLI is set up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/setup-copilot.sh" || exit 1

# Optional model parameter
MODEL="${1:-}"
MODEL_FLAG=""
if [ -n "$MODEL" ]; then
  MODEL_FLAG="--model $MODEL"
fi

copilot $MODEL_FLAG -p "@prd.json @progress.txt \
1. Read the PRD and progress file. \
2. Find the next incomplete task and implement it. \
3. Commit your changes. \
4. Update progress.txt with what you did. \
5. Update the prd.json with passes:true if the task is fully complete. \
ONLY DO ONE TASK AT A TIME."
