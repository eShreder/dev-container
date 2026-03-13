#!/bin/bash
# Entrypoint script for dev-container
# Installs AI agents (claude-code, codex) into persistent npm prefix
# so they survive container rebuilds without re-downloading.

set -e

NPM_GLOBAL="$HOME/.npm-global"

# Ensure npm global directory exists
mkdir -p "$NPM_GLOBAL"

# Install claude-code if not present
if ! command -v claude &>/dev/null; then
    echo "[entrypoint] Installing claude-code..."
    npm install -g @anthropic-ai/claude-code@latest
fi

# Install codex if not present
if ! command -v codex &>/dev/null; then
    echo "[entrypoint] Installing codex..."
    npm install -g @openai/codex@latest
fi

exec "$@"
