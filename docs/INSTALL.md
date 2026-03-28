# Installation Guide

Step-by-step guide to set up a 24/7 AI agent on your VPS from scratch.

**Time required**: ~30 minutes
**Difficulty**: Beginner-friendly (if you can SSH, you can do this)

> **Tip**: When copying commands from this guide, make sure to copy the entire command in one line. If a command looks broken across multiple lines in your terminal, delete it and paste it again carefully. A partial command will fail.

## Prerequisites

- A VPS running Ubuntu 24.04+ (any provider — Hostinger, DigitalOcean, Hetzner, etc.)
- SSH access to the VPS
- A [Claude Max subscription](https://claude.ai) (for Claude Code)
- A Telegram account (optional, for mobile access)
- A Gemini API key (optional, for voice note transcription — free at https://aistudio.google.com/api-keys)

---

## Phase 1: Security (Do This First)

### Step 1: SSH into your VPS

```bash
ssh root@your-server-ip
```

### Step 2: Create a dedicated user

Never run your agent as root.

```bash
adduser agent-user
usermod -aG sudo agent-user
su - agent-user
```

### Step 3: Secure SSH access

**Option A: Tailscale (recommended)**

Tailscale creates a private network — your SSH port is never exposed to the internet.

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

After setup, SSH using your Tailscale IP instead of the public IP.

**Option B: Traditional hardening**

```bash
# Disable root login
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication (SSH keys only)
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH
sudo systemctl restart sshd

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw enable
```

### Step 4: Configure swap

Prevents the system from killing processes when RAM runs out.

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

Verify: `free -h` should show 4G under Swap.

### Step 5: Enable automatic security updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## Phase 2: Install the Stack

### Option A: Automated (recommended)

```bash
git clone https://github.com/rankgnar/agent-homebase.git
cd agent-homebase
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The script is interactive — it asks for your details and installs everything. Skip to **Phase 3** after it completes.

### Option B: Manual

#### Step 6: System packages

```bash
sudo apt update && sudo apt install -y tmux git curl wget build-essential ffmpeg unzip
```

#### Step 7: Node.js 22

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version   # Should show v22.x
```

#### Step 8: Bun

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
bun --version
```

#### Step 9: Claude Code

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
npm install -g @anthropic-ai/claude-code
claude --version
```

#### Step 10: GitHub CLI

```bash
sudo apt install -y gh
gh auth login
```

#### Step 11: Set up the Obsidian Vault

```bash
cp -r /path/to/agent-homebase/vault-template ~/.obsidian-vault
```

Edit the boot files to match your setup:

```bash
nano ~/.obsidian-vault/boot/identity.md
nano ~/.obsidian-vault/boot/stack.md
nano ~/.obsidian-vault/boot/state.md
```

#### Step 12: Set up CLAUDE.md

```bash
cp /path/to/agent-homebase/CLAUDE.md ~/CLAUDE.md
nano ~/CLAUDE.md
```

Replace all `{{TOKENS}}` with your actual values:
- `{{AGENT_NAME}}` — your agent's name
- `{{USER_NAME}}` — your name
- `{{LANGUAGE}}` — your preferred language
- `{{USER_EMAIL}}` — your email

#### Step 13: Configure Claude Code settings

```bash
cp config-templates/settings.json ~/.claude/settings.json
cp config-templates/mcp.json ~/.claude/.mcp.json
```

---

## Phase 3: Telegram Setup

### Step 14: Create a Telegram bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Choose a name and username for your bot
4. **Copy the bot token**

### Step 15: Configure the Telegram plugin

Start Claude Code:

```bash
claude
```

Inside Claude Code, run these commands one at a time:

```
/install-plugin telegram@claude-plugins-official
```

Then exit and relaunch Claude Code for the plugin to load:

```
/exit
```

```bash
claude
```

Now configure the bot token:

```
/telegram:configure YOUR_BOT_TOKEN
```

Then pair your Telegram account:

```
/telegram:access
```

This gives you a pairing code. Go to Telegram, find your bot, and send the code as a message. This links your Telegram account as an authorized user.

> **Important**: After configuring the plugin, you must exit Claude Code and relaunch it with the `--channels` flag for the bot to actually respond to Telegram messages. See Phase 4.

### Step 16: Authenticate Claude Code

If you haven't already authenticated:

```bash
claude
```

Follow the authentication flow. You'll need your Claude Max subscription.

---

## Phase 4: Voice Notes Setup (Optional)

This enables your agent to transcribe and respond to voice messages sent via Telegram.

### Step 17: Get a Gemini API key

> **Important**: You need a key from **Google AI Studio**, NOT from Google Cloud Console. They look similar but are different services.

1. Go to **https://aistudio.google.com/api-keys**
2. Click **"Create API Key"**
3. Select or create a project
4. Copy the key (starts with `AIza...`)

**Verify the key works** before continuing:

```bash
curl "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY_HERE" 2>/dev/null | head -3
```

If you see `"models": [` — the key works. If you see `"error"` — the key is wrong (probably from Google Cloud Console instead of AI Studio).

> **Common mistake**: Google Cloud Console (console.cloud.google.com) also lets you create API keys that start with `AIza...`, but those keys don't work with the Gemini API unless you enable the Generative Language API in your Google Cloud project. The easiest path is to use Google AI Studio directly.

### Step 18: Configure the Gemini key

The key must be in Claude Code's settings file so the agent can access it:

```bash
nano ~/.claude/settings.json
```

Add the `GEMINI_API_KEY` to the `env` section:

```json
{
  "enabledPlugins": {
    "telegram@claude-plugins-official": true
  },
  "env": {
    "GEMINI_API_KEY": "YOUR_KEY_HERE"
  }
}
```

> **Important**: Adding the key to `~/.bashrc` is NOT enough. Claude Code reads environment variables from its own `settings.json`, not from your shell profile.

### Step 19: Install the transcription script

```bash
mkdir -p ~/.claude/scripts
cp /path/to/agent-homebase/scripts/transcribe.ts ~/.claude/scripts/transcribe.ts
```

If you used `setup.sh`, this was already done automatically.

### Verify voice notes work

After completing the setup, test it:

```bash
bun ~/.claude/scripts/transcribe.ts /path/to/any/audio-file.oga
```

If it prints transcribed text, everything works. If it shows "API key not valid", your Gemini key is from the wrong source (see Step 17).

---

## Phase 5: Launch

### Step 20: Start with tmux

tmux keeps your agent alive after you close SSH. This is what makes it run 24/7.

```bash
tmux new -s claude
```

Inside the tmux session, start Claude Code with Telegram:

**With permission prompts (safe, asks before each action):**

```bash
claude --channels plugin:telegram@claude-plugins-official
```

**Without permission prompts (autonomous, for 24/7 Telegram use):**

```bash
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

> **Note**: `--dangerously-skip-permissions` gives the agent full autonomy. This is safe if your VPS is properly secured (Tailscale, no root, dedicated user). The CLAUDE.md rules already instruct the agent to avoid destructive operations.
>
> The `--channels` flag is required for the agent to respond to Telegram messages. Without it, the bot stays silent.

### Step 21: Test it

1. Open Telegram on your phone
2. Find your bot
3. Send a text message — the agent should respond
4. Send a voice note — the agent should transcribe and respond (if you set up Gemini)

### Step 22: Disconnect

Simply **close your SSH window** (click the X). The tmux session continues running in the background. Your agent stays alive and keeps responding to Telegram messages.

> **Important**: Do NOT use `Ctrl+B D` to detach — in some cases this can cause Claude Code to stop responding to Telegram. Just close the SSH window directly.

---

## Phase 6: Auto-Restart with systemd (Optional)

By default, if your VPS reboots or the tmux session crashes, the agent stays dead until you manually relaunch it. systemd fixes this — it automatically restarts the agent.

### Step 23: Install the systemd service

```bash
sudo cp ~/agent-homebase/scripts/claude-agent.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable claude-agent
sudo systemctl start claude-agent
```

### Step 24: Verify it works

```bash
sudo systemctl status claude-agent
```

You should see `Active: active (exited)` and `Session 'claude' started.`

Also verify tmux is running:

```bash
tmux ls
```

Send a Telegram message to confirm the bot responds.

### What this does

| Event | What happens |
|---|---|
| VPS reboots | systemd starts the agent automatically |
| tmux session crashes | systemd restarts it after 30 seconds |
| You run `sudo systemctl stop claude-agent` | Agent stops gracefully |
| You run `sudo systemctl start claude-agent` | Agent starts in tmux |

### systemd commands reference

| Action | Command |
|---|---|
| Start agent | `sudo systemctl start claude-agent` |
| Stop agent | `sudo systemctl stop claude-agent` |
| Check status | `sudo systemctl status claude-agent` |
| View logs | `journalctl -u claude-agent -f` |
| Disable auto-start | `sudo systemctl disable claude-agent` |
| Re-enable auto-start | `sudo systemctl enable claude-agent` |

> **Note**: systemd launches the agent inside tmux. You can still `tmux attach -t claude` to see what the agent is doing, and close the SSH window to disconnect safely.

### Customizing the service

The service files are in `~/agent-homebase/scripts/`:

- `agent-start.sh` — creates the tmux session and launches Claude Code
- `agent-stop.sh` — gracefully stops the session
- `claude-agent.service` — the systemd unit file

If you change these files, reload systemd:

```bash
sudo cp ~/agent-homebase/scripts/claude-agent.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart claude-agent
```

---

## Restarting the Agent

Whenever you change `~/CLAUDE.md` or `~/.claude/settings.json`, you need to restart Claude Code for changes to take effect:

1. Reconnect to tmux: `tmux attach -t claude`
2. Inside Claude Code, type: `/exit`
3. Relaunch: `claude --channels plugin:telegram@claude-plugins-official`

Settings changes are **not** picked up automatically — a restart is always required.

---

## tmux Reference

These are the commands you'll use regularly to manage your agent:

| Action | Command |
|---|---|
| Create session | `tmux new -s claude` |
| Reconnect | `tmux attach -t claude` |
| Check status | `tmux ls` |
| Kill session | `tmux kill-session -t claude` |
| Disconnect safely | Close the SSH window |

> **Common mistake**: Use `-t` to attach (target), NOT `-s` (that creates a new session).

### If the session died

```bash
tmux ls                  # Check — if "no server running", create a new one
tmux new -s claude
claude --channels plugin:telegram@claude-plugins-official
```

---

## What's Next?

Once your agent is running:

1. **Customize `~/CLAUDE.md`** — define your agent's personality and rules
2. **Add projects** — create directories in `~/.obsidian-vault/projects/`
3. **Track tasks** — use `queue/index.md` as your shared task board
4. **Build knowledge** — your agent saves learnings to `knowledge/`

The agent manages its own memory. Just talk to it.
