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

# Check if copilot extension is installed
if ! gh extension list | grep -q "github/gh-copilot"; then
    echo "Installing GitHub Copilot CLI extension..."
    gh extension install github/gh-copilot
    echo "✓ GitHub Copilot CLI extension installed"
else
    echo "✓ GitHub Copilot CLI extension already installed"
fi

# Verify it works
if copilot --help &> /dev/null; then
    echo "✓ GitHub Copilot CLI is ready"
else
    echo "Warning: GitHub Copilot CLI may not be properly configured"
fi
