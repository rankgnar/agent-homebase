#!/bin/bash

# =============================================================================
# agent-homebase — Auto-start script for systemd
# =============================================================================
# This script ensures Claude Code runs inside a tmux session.
# Called by systemd if the process dies or the VPS reboots.
#
# What it does:
#   1. Checks if a tmux session "claude" already exists
#   2. If not, creates one and launches Claude Code with Telegram
#   3. If yes, does nothing (avoids duplicate sessions)
# =============================================================================

SESSION_NAME="claude"
CLAUDE_BIN="$HOME/.local/bin/claude"
WORK_DIR="$HOME"

# Ensure PATH includes all tools
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export HOME="/home/rankgnar"

# Check if session already exists
if /usr/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already running. Skipping."
    exit 0
fi

# Create tmux session and launch Claude Code
/usr/bin/tmux new-session -d -s "$SESSION_NAME" -c "$WORK_DIR" \
    "$CLAUDE_BIN --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official"

echo "Session '$SESSION_NAME' started."
