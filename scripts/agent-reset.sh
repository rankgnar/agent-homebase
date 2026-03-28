#!/bin/bash

# =============================================================================
# agent-homebase — Reset script
# =============================================================================
# Saves the agent's state and restarts the service.
# Can be called by the agent itself (e.g., from a Telegram /reset command).
# =============================================================================

VAULT_DIR="$HOME/.obsidian-vault"
TODAY=$(date +%Y-%m-%d)

echo "Saving state before restart..."

# Append a reset entry to the daily log
LOG_FILE="$VAULT_DIR/logs/$TODAY.md"
if [ -f "$LOG_FILE" ]; then
    echo "" >> "$LOG_FILE"
    echo "## Context Reset — $(date +%H:%M)" >> "$LOG_FILE"
    echo "- Agent context reset triggered (manual or scheduled)" >> "$LOG_FILE"
else
    cat > "$LOG_FILE" << EOF
---
tags:
  - log
updated: $TODAY
---
# $TODAY

## Context Reset — $(date +%H:%M)
- Agent context reset triggered (manual or scheduled)
EOF
fi

echo "State saved. Restarting agent..."

# Restart the systemd service
sudo /usr/bin/systemctl restart claude-agent

echo "Agent restarted."
