# Troubleshooting

Real errors encountered during setup and their exact solutions.

---

## Installation Issues

### `command not found: claude`

**Cause**: npm global bin directory is not in your PATH.

**Fix**:

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code
```

### `command not found: bun`

**Cause**: Bun installed but PATH not updated.

**Fix**:

```bash
echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### `error: unzip is required to install bun`

**Cause**: unzip not installed (not included by default on some Ubuntu setups).

**Fix**:

```bash
sudo apt install -y unzip
curl -fsSL https://bun.sh/install | bash
```

### `EACCES: permission denied` when installing npm packages globally

**Cause**: npm trying to write to a root-owned directory.

**Fix**:

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### PATH not available inside Claude Code

**Cause**: Claude Code's shell environment doesn't inherit your `.bashrc` PATH changes.

**Fix**: Add PATH to Claude Code settings (`~/.claude/settings.json`):

```json
{
  "env": {
    "PATH": "/home/YOUR_USER/.bun/bin:/home/YOUR_USER/.npm-global/bin:${PATH}",
    "BUN_INSTALL": "/home/YOUR_USER/.bun"
  }
}
```

---

## Security Issues

### Tailscale not connecting

**Symptoms**: `tailscale status` shows "Stopped" or connection timeout.

**Fix**:

```bash
sudo tailscale up
tailscale status    # Should show "Running"
```

If the node was removed from your Tailscale network, re-authenticate:

```bash
sudo tailscale up --reset
```

### Swap not active after reboot

**Symptoms**: `free -h` shows 0B swap after restarting.

**Fix**: Verify `/etc/fstab` has the swap entry:

```bash
cat /etc/fstab | grep swap
# Should show: /swapfile none swap sw 0 0
```

If missing, add it:

```bash
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo swapon /swapfile
```

---

## tmux Issues

### `tmux attach -s claude` doesn't work

**Cause**: Wrong flag. `-s` is for **creating** sessions, `-t` is for **targeting** existing ones.

**Fix**:

```bash
tmux attach -t claude    # Correct: -t flag
```

### `can't find session: claude`

**Cause**: No tmux session named "claude" exists. Either it was never created or it was killed.

**Fix**:

```bash
tmux ls                      # Check if any sessions exist
tmux new -s claude           # Create a new one
claude --channels plugin:telegram@claude-plugins-official   # Relaunch the agent
```

### Session died after SSH disconnect

**Cause**: tmux session crashed or was killed by the OS (e.g., OOM killer).

**Fix**:

```bash
tmux ls                      # Check if any sessions exist
tmux new -s claude           # Create a new one
claude --channels plugin:telegram@claude-plugins-official
```

> **Tip**: Make sure swap is configured (`free -h`). Without swap, the OS may kill processes when RAM is full.

### Agent stops responding to Telegram after `Ctrl+B D`

**Cause**: In some configurations, detaching with `Ctrl+B D` can freeze the Claude Code process.

**Workaround**: Do NOT use `Ctrl+B D`. Instead, just **close the SSH window directly** (click the X). The tmux session continues running in the background.

### How to check if the agent is running

```bash
tmux ls
```

- If you see `claude: ...` → agent is alive
- If you see `no server running` → create a new session with `tmux new -s claude`

### Quick reference: tmux commands

| Action | Command |
|---|---|
| Create session | `tmux new -s claude` |
| Reconnect | `tmux attach -t claude` |
| Check status | `tmux ls` |
| Kill session | `tmux kill-session -t claude` |
| Disconnect safely | Close the SSH window |

---

## systemd Issues

### Agent doesn't start after VPS reboot

**Check in order**:

1. **Is the service enabled?**
   ```bash
   sudo systemctl is-enabled claude-agent
   ```
   If it says `disabled`, enable it: `sudo systemctl enable claude-agent`

2. **Check the service status:**
   ```bash
   sudo systemctl status claude-agent
   ```

3. **Check the logs:**
   ```bash
   journalctl -u claude-agent --no-pager -n 20
   ```

### Service says "active" but bot doesn't respond

**Cause**: systemd started the service but tmux session may not have launched properly.

**Fix**:

```bash
tmux ls                              # Check if session exists
sudo systemctl restart claude-agent  # Force restart
tmux ls                              # Check again
```

### How to manually restart the agent via systemd

```bash
sudo systemctl restart claude-agent
```

This stops the current session and starts a new one.

---

## Telegram Issues

### Bot doesn't respond to messages

**Check in order**:

1. **Is Claude Code running?**
   ```bash
   tmux ls
   tmux attach -t claude
   ```

2. **Was it started with the Telegram channel?**
   ```bash
   claude --channels plugin:telegram@claude-plugins-official
   ```

3. **Is the plugin enabled?** Check `~/.claude/settings.json`:
   ```json
   {
     "enabledPlugins": {
       "telegram@claude-plugins-official": true
     }
   }
   ```

4. **Is your account paired?** Run inside Claude Code:
   ```
   /telegram:access
   ```

### "Forbidden" error when bot tries to respond

**Cause**: You haven't started a conversation with the bot, or the bot was blocked.

**Fix**: Open Telegram, find your bot, and press "Start" or unblock it.

### Pairing code not working

**Cause**: The pairing code expires quickly.

**Fix**: Generate a new one with `/telegram:access` and use it immediately.

---

## Voice Notes / Audio Issues

### Agent says "I can't process audio"

**Cause**: The CLAUDE.md is missing the audio transcription instructions, or the agent doesn't know about the transcribe.ts script.

**Fix**: Make sure `~/CLAUDE.md` contains the "Audio / Voice Notes" section with instructions to use `bun ~/.claude/scripts/transcribe.ts`. See the template CLAUDE.md in this repo.

### "API key not valid" when transcribing audio

**Cause**: Wrong type of API key. Google Cloud Console keys and Google AI Studio keys look the same (both start with `AIza...`) but they are NOT interchangeable.

**Fix**:

1. Go to **https://aistudio.google.com/api-keys** (NOT console.cloud.google.com)
2. Create a new API key there
3. Verify it works:
   ```bash
   curl "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY" 2>/dev/null | head -3
   ```
   You should see `"models": [` — if you see `"error"`, the key is wrong.

4. Update `~/.claude/settings.json`:
   ```json
   {
     "env": {
       "GEMINI_API_KEY": "YOUR_WORKING_KEY"
     }
   }
   ```

5. **Restart Claude Code** — settings.json changes are NOT picked up automatically.

### "GEMINI_API_KEY not set" error

**Cause**: The key is in `~/.bashrc` but not in Claude Code's settings.

**Fix**: Claude Code reads environment variables from `~/.claude/settings.json`, NOT from your shell profile. Add the key to the `env` section of settings.json (see above).

### transcribe.ts not found

**Cause**: The transcription script wasn't installed.

**Fix**:

```bash
mkdir -p ~/.claude/scripts
cp ~/agent-homebase/scripts/transcribe.ts ~/.claude/scripts/transcribe.ts
```

---

## Settings Changes Not Taking Effect

### Changed settings.json but nothing happened

**Cause**: Claude Code only reads settings.json on startup.

**Fix**: Restart Claude Code:

1. Reconnect to tmux: `tmux attach -t claude`
2. Inside Claude Code: `/exit`
3. Relaunch: `claude --channels plugin:telegram@claude-plugins-official`

This applies to ALL changes: env variables, permissions, plugin settings.

---

## Memory Issues

### Agent doesn't read the vault on startup

**Cause**: `CLAUDE.md` not in the right location or missing vault instructions.

**Fix**: Make sure `~/CLAUDE.md` exists and contains the boot sequence instructions. Claude Code reads `CLAUDE.md` from the working directory on startup.

### Agent writes notes without frontmatter

**Cause**: Instructions in CLAUDE.md not specific enough.

**Fix**: The CLAUDE.md template includes explicit formatting rules. Make sure the `Note Format` section is present.

### Native memory vs vault confusion

**Cause**: Not clear what should go where.

**Fix**: See the [Memory System guide](MEMORY.md). Rule of thumb:
- **How we work** → native memory (auto-loaded)
- **What we're working on** → vault (on-demand)

---

## Context Issues

### Agent loses context mid-conversation

**Cause**: Claude Code's context window fills up on long sessions.

**What happens**: Earlier messages get compressed or dropped.

**Mitigation**: The CLAUDE.md includes auto-save rules that persist state to the vault on task completion and farewell detection. On context reset, the agent reads `boot/state.md` and picks up where it left off.

### Agent doesn't remember previous sessions

**Cause**: State not saved before the session ended.

**Fix**: Check `logs/` for the last session log — it should have enough context to resume. The agent is instructed to save on farewell keywords ("bye", "see you", etc.).

### Shell snapshot errors

**Symptoms**: Errors like `syntax error near unexpected token 'fi'` on every bash command.

**Fix**: Find and fix the corrupted snapshot:

```bash
ls ~/.claude/shell-snapshots/
# Edit the broken file — usually an empty if/fi block
# Add 'true' inside the empty block
```

---

## General Tips

- **Always use tmux** — never run Claude Code directly in SSH
- **Check `boot/state.md`** — if the agent seems confused, read this file to see what it thinks is happening
- **One session at a time** — don't run multiple Claude Code instances with the same Telegram channel
- **Restart cleanly** — say "save state and close" before killing the session
- **The vault is the source of truth** — if something is wrong, check `logs/` for history
