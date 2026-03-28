---
tags:
  - boot
  - stack
updated: {{DATE}}
---
# Stack & Infrastructure

## VPS
- Ubuntu Linux
- User: `{{UNIX_USER}}` at `/home/{{UNIX_USER}}`
- Persistent session in tmux — session name: `claude`
- Claude Code with Telegram channel active

## Available Tools
- Git + GitHub CLI (`gh`)
- Node.js + npm + Bun
- ffmpeg — available for audio/video
- Web access — search and fetch
- Obsidian vault — `~/.obsidian-vault/`

## Limitations
- No standalone API key — uses Claude Max subscription
- Claude Code sessions can expire on very high context
- VPS is headless — no GUI
- On high context: notify user and save state before restart

## References
- [[boot/state]] — current state
- [[boot/identity]] — who I am and how I work
