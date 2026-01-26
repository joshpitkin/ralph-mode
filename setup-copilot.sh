#!/bin/bash
# Helper script to ensure GitHub Copilot CLI is installed and authenticated

set -e

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "GitHub CLI is not authenticated. Please run: gh auth login"
    exit 1
fi

# Check if copilot is installed
if ! command -v copilot &> /dev/null; then
    echo "Installing GitHub Copilot CLI via npm..."
    npm install -g @github/copilot
    echo "✓ GitHub Copilot CLI installed"
else
    echo "✓ GitHub Copilot CLI already installed"
fi

# Verify it works
if copilot --help &> /dev/null; then
    echo "✓ GitHub Copilot CLI is ready"
else
    echo "Warning: GitHub Copilot CLI may not be properly configured"
fi
