#!/bin/bash

# Ralph-once with Docker isolation
# This runs a single iteration inside a Docker container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional model parameter
MODEL="${1:-}"
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

docker run --rm -it \
  -v "$SCRIPT_DIR:/workspace" \
  -w /workspace \
  -e GH_TOKEN="${GH_TOKEN}" \
  ralph-copilot:latest \
  bash -c "
    # Authenticate with GitHub
    echo \"\$GH_TOKEN\" | gh auth login --with-token
    
    # Run the copilot command
    copilot $MODEL_FLAG --yolo -p \"@prd.json @progress.txt \
1. Read the PRD and progress file. \
2. Find the next incomplete task and implement it. \
3. Commit your changes. \
4. Update progress.txt with what you did. \
ONLY DO ONE TASK AT A TIME.\"
  "
