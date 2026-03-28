# Installation Guide

Step-by-step guide to set up a 24/7 AI agent on your VPS from scratch.

**Time required**: ~30 minutes
**Difficulty**: Beginner-friendly (if you can SSH, you can do this)

## Prerequisites

- A VPS running Ubuntu 24.04+ (any provider — Hostinger, DigitalOcean, Hetzner, etc.)
- SSH access to the VPS
- A [Claude Max subscription](https://claude.ai) (for Claude Code)
- A Telegram account (optional)

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

Inside Claude Code:

```
/install-plugin telegram@claude-plugins-official
/telegram:configure YOUR_BOT_TOKEN
```

Then pair your account:

```
/telegram:access
```

Send the pairing code to your bot on Telegram.

### Step 16: Authenticate Claude Code

```bash
claude
```

Follow the authentication flow. You'll need your Claude Max subscription.

---

## Phase 4: Launch

### Step 17: Start with tmux

```bash
tmux new -s claude
claude --channels plugin:telegram@claude-plugins-official
```

### Step 18: Test it

1. Open Telegram on your phone
2. Find your bot
3. Send a message — the agent should respond
4. (Optional) Send a voice note — the agent should transcribe and respond

### Step 19: Disconnect

Simply **close your SSH window**. The tmux session continues running.

To reconnect later:

```bash
ssh your-vps
tmux attach -t claude
```

---

## What's Next?

Once your agent is running:

1. **Customize `~/CLAUDE.md`** — define your agent's personality and rules
2. **Add projects** — create directories in `~/.obsidian-vault/projects/`
3. **Track tasks** — use `queue/index.md` as your shared task board
4. **Build knowledge** — your agent saves learnings to `knowledge/`

The agent manages its own memory. Just talk to it.
