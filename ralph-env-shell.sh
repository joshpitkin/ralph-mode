#!/bin/bash
set -e

# Derive the container name from the current project directory (must match ralph-env-start.sh)
CONTAINER_NAME="ralph-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "No running environment found for this project (expected container: $CONTAINER_NAME)."
  echo "Start one with: ./ralph-env-start.sh"
  exit 1
fi

echo "Opening shell in container '$CONTAINER_NAME' (workspace mounted at /workspace)..."
echo "Run 'ralph <iterations> [model]' to start a Copilot loop."
echo ""
docker exec -it -w /workspace "$CONTAINER_NAME" bash
