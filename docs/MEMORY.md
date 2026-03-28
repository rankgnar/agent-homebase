# Dual Memory System

## The Problem

Claude Code loses all context when a session ends or the context window fills up. A single memory vault can help, but it duplicates what Claude Code already stores natively, creating confusion about the source of truth.

## The Solution: Two Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code Agent                         │
│                                                             │
│  ┌──────────────────────┐  ┌─────────────────────────────┐  │
│  │   Native Memory      │  │      Obsidian Vault         │  │
│  │   (Layer 1)          │  │      (Layer 2)              │  │
│  │                      │  │                             │  │
│  │   Auto-loaded every  │  │   Consulted on demand       │  │
│  │   session. Zero cost.│  │   via CLAUDE.md boot rules. │  │
│  │                      │  │                             │  │
│  │   ├─ User profile    │  │   ├─ boot/ (state)         │  │
│  │   ├─ Preferences     │  │   ├─ projects/             │  │
│  │   ├─ Feedback        │  │   ├─ knowledge/            │  │
│  │   └─ References      │  │   ├─ queue/                │  │
│  │                      │  │   ├─ logs/                 │  │
│  │   "Instinct"         │  │   ├─ scratch/              │  │
│  │                      │  │   └─ vault/ (secrets)      │  │
│  │                      │  │                             │  │
│  │                      │  │   "Library"                 │  │
│  └──────────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Layer 1: Native Claude Code Memory

**Location**: `~/.claude/projects/.../memory/` (managed by Claude Code itself)

**Loaded**: Automatically, every session. You never need to tell the agent to read this.

**What goes here**:
- Who you are (role, expertise, GitHub username)
- How you like to work (direct? verbose? language?)
- Corrections and feedback ("don't do X", "always do Y")
- References to external systems (Linear project, Grafana URL)

**Why here?** These are things the agent should always know without being told. They're small, stable, and rarely change. Auto-loading means zero token cost and zero chance of forgetting.

### Layer 2: Obsidian Vault

**Location**: `~/.obsidian-vault/`

**Loaded**: On demand — the CLAUDE.md instructs the agent to read `boot/state.md` at the start of each session, then other files as needed.

**What goes here**:
- Current work state (`boot/state.md`)
- Project details, specs, decisions (`projects/`)
- Learned patterns and solutions (`knowledge/`)
- Task tracking (`queue/`)
- Session history (`logs/`)
- Temporary work (`scratch/`)
- Sensitive data like tokens (`vault/`)

**Why here?** This data is large, structured, and constantly evolving. It needs organization by topic, not a flat list. The agent actively manages it — creating, updating, and cleaning up files.

## Decision Matrix

```
Is it about HOW we work together?
  └── YES → Native memory (auto-loaded)

Is it about WHAT we're working on?
  └── YES → Vault (on-demand)

Is it a correction or preference?
  └── YES → Native memory

Is it project-specific data?
  └── YES → Vault → projects/

Is it a reusable pattern or solution?
  └── YES → Vault → knowledge/

Is it a task or to-do?
  └── YES → Vault → queue/index.md

Is it sensitive (token, credential)?
  └── YES → Vault → vault/
```

## Boot Sequence

Every time the agent starts a new session:

```
1. Native memory loads automatically          (Layer 1 — free)
2. Read boot/state.md                         (Layer 2 — "what was I doing?")
3. If context is new: read identity.md, stack.md  ("who am I?")
4. Read queue/index.md                        ("what's pending?")
5. Ready to work
```

This means even after a full context reset (crash, restart, context overflow), the agent recovers in seconds.

## Auto-Save Triggers

The agent saves to the vault without being asked when:

| Trigger | What gets saved | Where |
|---|---|---|
| Task completed | Task marked done + log entry | `queue/index.md` + `logs/` |
| New learning | Knowledge note with tags | `knowledge/` |
| Important decision | Decision + reasoning | `logs/` daily entry |
| New project started | Project directory + index | `projects/name/index.md` |
| Farewell detected | Full state dump | `boot/state.md` + `logs/` |

## Vault Structure

```
~/.obsidian-vault/
│
├── boot/                    THE BRAIN STEM
│   ├── state.md            Current state — read FIRST, updated LAST
│   ├── identity.md         Who the agent is, who it works with
│   └── stack.md            Tools, access, infrastructure, limits
│
├── projects/                ACTIVE WORK
│   ├── index.md            Map of all projects
│   └── project-name/
│       └── index.md        Project description, status, links
│
├── knowledge/               LEARNED PATTERNS
│   ├── index.md            Map of knowledge
│   └── topic-name.md       Specific pattern or solution
│
├── queue/                   TASK BOARD
│   └── index.md            Pending / In Progress / Completed
│
├── logs/                    SESSION HISTORY
│   ├── index.md            Log index by month
│   └── YYYY-MM-DD.md       Daily log with sessions
│
├── scratch/                 TEMPORARY
│   └── index.md            WIP, cleaned regularly
│
└── vault/                   SECRETS (never committed)
    └── index.md            Tokens, credentials, private configs
```

## Note Format

Every note must have frontmatter:

```markdown
---
tags:
  - area/subtype
updated: YYYY-MM-DD
---
# Note Title

Content. Link to other notes with [[wikilinks]].

> [!warning]
> Use callouts for critical information.
```

### Conventions

| Convention | Example | Why |
|---|---|---|
| Frontmatter | `tags`, `updated` required | Searchable metadata |
| Wikilinks | `[[boot/state]]` | Internal linking |
| Nested tags | `#project/active` | Hierarchical organization |
| Callouts | `> [!warning]` | Visual emphasis |
| kebab-case | `my-project.md` | Consistent file naming |

## Syncing with Obsidian App (Optional)

The vault is just a directory of `.md` files. The agent works headlessly via read/write. But you can optionally sync to your local machine and browse it with the Obsidian app.

### Via Git

```bash
# On VPS
cd ~/.obsidian-vault
git init && git add -A && git commit -m "vault sync"
git remote add origin git@github.com:you/your-vault.git
git push -u origin main

# On local machine
git clone git@github.com:you/your-vault.git ~/my-vault
# Open ~/my-vault as a vault in Obsidian
```

> **Important**: The `vault/` directory contains sensitive data. Exclude it from sync or use a private repo.

## Why Not Just Use the Vault for Everything?

Claude Code's native memory is **free** — it loads automatically without consuming context window tokens. Putting user preferences there means the agent always knows them, even if it doesn't read the vault.

The vault is powerful but costs tokens to read. Using it only for structured, evolving project data keeps the boot sequence fast and the context window efficient.

Two systems, clear boundaries, zero conflicts.
