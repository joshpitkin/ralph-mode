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

EXTRA_ARG="${2:-}"
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
# PROMPT_LINES+=(
#  "@prd.json @progress.txt"
#  "1. Read the PRD and progress file."
#  "2. Find the next incomplete task and implement it."
#  "3. Commit your changes."
#  "4. Update progress.txt with what you did."
#  "5. Update the prd.json with passes:true if the task is fully complete."
#  "ONLY DO ONE TASK AT A TIME."
#)
PROMPT="$(printf '%s\n' "${PROMPT_LINES[@]}")"

echo $PROMPT

copilot $MODEL_FLAG --yolo -p "$PROMPT"
