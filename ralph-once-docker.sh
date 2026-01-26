#!/bin/bash

# Ralph-once with Docker isolation
# This runs a single iteration inside a Docker container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker run --rm -it \
  -v "$SCRIPT_DIR:/workspace" \
  -w /workspace \
  -e GH_TOKEN="${GH_TOKEN}" \
  ralph-copilot:latest \
  bash -c 'gh copilot suggest "@prd.json @progress.txt \
1. Read the PRD and progress file. \
2. Find the next incomplete task and implement it. \
3. Commit your changes. \
4. Update progress.txt with what you did. \
ONLY DO ONE TASK AT A TIME."'
