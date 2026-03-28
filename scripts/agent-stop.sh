#!/bin/bash

# =============================================================================
# agent-homebase — Stop script for systemd
# =============================================================================
# Gracefully stops the Claude Code tmux session.
# =============================================================================

SESSION_NAME="claude"

if /usr/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    # Send Ctrl+C to gracefully stop Claude Code
    /usr/bin/tmux send-keys -t "$SESSION_NAME" C-c
    sleep 2
    # Kill the session
    /usr/bin/tmux kill-session -t "$SESSION_NAME"
    echo "Session '$SESSION_NAME' stopped."
else
    echo "No session '$SESSION_NAME' found."
fi
