# agent-homebase

**Turn a blank VPS into a 24/7 AI agent with persistent memory and Telegram access.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-orange.svg)]()
[![Claude Code](https://img.shields.io/badge/Claude_Code-Powered-blueviolet.svg)]()

```
┌──────────────────────────────────────────────────────────────────────┐
│                            YOUR VPS                                  │
│                                                                      │
│  ┌──────────┐    ┌───────────────┐    ┌───────────────────────────┐  │
│  │  tmux    │    │  Claude Code   │    │     Dual Memory System    │  │
│  │ session  │───>│  (AI Agent)    │<──>│                           │  │
│  │ "claude" │    │               │    │  Native Memory (auto)     │  │
│  └──────────┘    └──────┬────────┘    │  ├─ user profile          │  │
│                         │             │  ├─ preferences           │  │
│                         │             │  └─ feedback              │  │
│                  ┌──────┴────────┐    │                           │  │
│                  │   Telegram    │    │  Obsidian Vault (on-demand)│  │
│                  │   Channel     │    │  ├─ boot/ (state)         │  │
│                  └──────┬────────┘    │  ├─ projects/             │  │
│                         │             │  ├─ knowledge/            │  │
│                         │             │  ├─ queue/                │  │
│                         │             │  └─ logs/                 │  │
│                         │             └───────────────────────────┘  │
└─────────────────────────┼───────────────────────────────────────────┘
                          │
                    ┌─────┴─────┐
                    │ Telegram  │
                    │   Bot     │
                    └─────┬─────┘
                          │
                    ┌─────┴─────┐
                    │    You    │
                    │ (mobile)  │
                    └───────────┘
```

## What is this?

A production-tested guide to running **Claude Code as a persistent AI agent** on a VPS. Not a toy demo — this is the exact architecture running in production right now.

The agent runs 24/7 inside tmux, is reachable via Telegram from your phone, and has persistent memory that survives restarts and context resets.

## Features

| Feature | Details |
|---|---|
| **Always-on AI agent** | Claude Code running 24/7 inside tmux |
| **Telegram access** | Talk to your agent from your phone, anywhere |
| **Dual memory system** | Native memory (auto-loaded) + Obsidian vault (on-demand) |
| **Context recovery** | Agent reads its state on boot and picks up where it left off |
| **Task tracking** | Queue system with pending/in-progress/completed states |
| **Session logging** | Chronological log of everything the agent does |
| **Custom identity** | Your agent, your rules, your language via CLAUDE.md |
| **Audio transcription** | Send voice notes via Telegram, agent transcribes and responds |
| **Hardened permissions** | Secure allow/deny rules for bash commands and tools |
| **Auto-restart** | systemd service restarts the agent if it crashes or the VPS reboots |
| **Interactive setup** | No broken placeholders — setup.sh asks for your details |

## Prerequisites

- A VPS running Ubuntu 24.04+ (any provider — Hostinger, DigitalOcean, Hetzner, etc.)
- SSH access to the VPS
- A [Claude Max subscription](https://claude.ai) (for Claude Code)
- A Telegram account (optional, for mobile access)

## Quick Start

```bash
ssh your-vps
git clone https://github.com/rankgnar/agent-homebase.git
cd agent-homebase
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script is fully interactive — it asks for your agent name, language, email, and configures everything automatically.

For manual installation, follow the [step-by-step guide](docs/INSTALL.md).

## How the Dual Memory System Works

Most setups use a single memory system. This one uses **two layers with clear roles**:

| Layer | Location | Loaded | Stores |
|---|---|---|---|
| **Native Memory** | `~/.claude/` | Automatically, every session | User profile, preferences, feedback, corrections |
| **Obsidian Vault** | `~/.obsidian-vault/` | On demand (via CLAUDE.md instructions) | Projects, knowledge, tasks, logs, sensitive data |

**Why two?** Native memory is always available at zero cost — the agent just knows your preferences. The vault is for structured, evolving project data that the agent actively manages.

This means no duplication, no conflicts. The native memory is the agent's "instinct" and the vault is its "library".

For a deep dive, see the [Memory System guide](docs/MEMORY.md).

## Repo Structure

```
agent-homebase/
├── README.md                 # You are here
├── CLAUDE.md                 # Agent instructions template (personalized by setup.sh)
├── LICENSE
├── docs/
│   ├── INSTALL.md            # Step-by-step installation guide
│   ├── MEMORY.md             # How the dual memory system works
│   └── TROUBLESHOOTING.md    # Common errors and fixes
├── vault-template/           # Obsidian vault structure
│   ├── home.md               # Main index (MOC)
│   ├── CLAUDE.md             # Vault-specific conventions
│   ├── boot/
│   │   ├── state.md          # Current state (read first on every boot)
│   │   ├── identity.md       # Agent identity and behavior
│   │   └── stack.md          # Infrastructure and tools
│   ├── projects/index.md
│   ├── knowledge/index.md
│   ├── queue/index.md
│   ├── logs/index.md
│   ├── scratch/index.md
│   └── vault/index.md
├── config-templates/
│   ├── settings.json         # Claude Code permissions (hardened)
│   └── mcp.json              # MCP servers (Context7)
└── scripts/
    ├── setup.sh              # Interactive installation script
    ├── transcribe.ts         # Audio transcription via Gemini API
    ├── agent-start.sh        # Auto-start script (used by systemd)
    ├── agent-stop.sh         # Graceful stop script (used by systemd)
    └── claude-agent.service  # systemd unit file for auto-restart
```

## Security Recommendations

This guide assumes you've already hardened your VPS. Before installing:

1. **Create a dedicated user** — never run the agent as root
2. **Use Tailscale or similar** — don't expose SSH to the public internet
3. **Disable root SSH login** — `PermitRootLogin no` in `/etc/ssh/sshd_config`
4. **Disable password auth** — use SSH keys only
5. **Configure swap** — prevents OOM kills on memory spikes
6. **Keep the system updated** — enable unattended-upgrades

See [INSTALL.md](docs/INSTALL.md) for details on each step.

## After Setup

Once your agent is running:

1. **Talk to it via Telegram** — it responds like a person
2. **Create projects** — the agent organizes them in `vault/projects/`
3. **Track tasks** — use `queue/index.md` as your shared task board
4. **Build knowledge** — the agent saves learnings to `knowledge/`

The agent manages its own memory. Just talk to it and it figures the rest out.

## Customization

| File | What to change |
|---|---|
| `~/CLAUDE.md` | Agent identity, language, rules, work style |
| `~/.obsidian-vault/boot/identity.md` | Who you are, how you work |
| `~/.obsidian-vault/boot/stack.md` | Your tools and infrastructure |
| `~/.claude/settings.json` | Add/remove bash permissions |

Most of this is handled by `setup.sh` during installation.

## Permissions

By default, Claude Code **asks for permission** before running any command. This is the safest approach — you approve each action.

For a 24/7 Telegram agent where you're not always watching the terminal, you have two options:

### Option A: Skip all permission prompts

```bash
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

This gives the agent full autonomy — it can run any command without asking. Best for trusted environments where the VPS is locked down (Tailscale, no root, dedicated user).

### Option B: Selective deny list

If you want autonomy but with guardrails, add a deny list to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)"
    ]
  }
}
```

Then launch with:

```bash
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

The agent runs freely but is blocked from the explicitly denied commands.

> **Recommendation**: If your VPS is properly secured (Tailscale, no root, dedicated user), `--dangerously-skip-permissions` is safe and practical for Telegram use. The CLAUDE.md rules already tell the agent not to do destructive operations without confirmation.

## Troubleshooting

See the [Troubleshooting guide](docs/TROUBLESHOOTING.md) — it covers every real error encountered during setup.

## License

MIT — Use it, fork it, make it yours.

---

Built and tested in production. March 2026.
