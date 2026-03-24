#!/bin/bash

# Derive the container name from the current project directory (must match ralph-env-start.sh)
CONTAINER_NAME="ralph-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping container '$CONTAINER_NAME'..."
  docker stop "$CONTAINER_NAME"
  docker rm "$CONTAINER_NAME"
  echo "Container stopped and removed."
else
  # Clean up a stopped (but not removed) container if one exists
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker rm "$CONTAINER_NAME"
    echo "Removed stopped container '$CONTAINER_NAME'."
  else
    echo "No container found: $CONTAINER_NAME"
  fi
fi
