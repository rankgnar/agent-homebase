#!/bin/bash

# =============================================================================
# agent-homebase — Interactive Setup Script
# =============================================================================
# Sets up a complete AI agent environment on a fresh Ubuntu VPS.
# Run as your agent user (NOT root).
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VAULT_DIR="$HOME/.obsidian-vault"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

print_step()    { echo -e "\n${BLUE}==> ${NC}$1"; }
print_success() { echo -e "${GREEN}    [OK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}    [!]${NC} $1"; }
print_error()   { echo -e "${RED}    [ERROR]${NC} $1"; }

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 already installed ($(command -v "$1"))"
        return 0
    else
        return 1
    fi
}

prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [ -n "$default" ]; then
        read -p "    $prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -p "    $prompt: " result
        echo "$result"
    fi
}

# -----------------------------------------------------------------------------
# Pre-flight checks
# -----------------------------------------------------------------------------

echo ""
echo "============================================="
echo "  agent-homebase"
echo "  24/7 AI Agent + Telegram + Persistent Memory"
echo "============================================="
echo ""

if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this script as root."
    echo "         Create a dedicated user first. See: docs/INSTALL.md"
    exit 1
fi

print_step "System info"
echo "    User:     $(whoami)"
echo "    Home:     $HOME"
echo "    OS:       $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo ""

# -----------------------------------------------------------------------------
# Interactive configuration
# -----------------------------------------------------------------------------

print_step "Let's configure your agent"
echo ""

AGENT_NAME=$(prompt_with_default "Agent name" "Agent")
USER_NAME=$(prompt_with_default "Your name/username" "$(whoami)")
USER_EMAIL=$(prompt_with_default "Your email (for git config)" "$(git config user.email 2>/dev/null)")
LANGUAGE=$(prompt_with_default "Agent response language" "English")

echo ""
print_step "Gemini API key (optional — enables voice note transcription via Telegram)"
echo "    Get one free at: https://aistudio.google.com/app/apikey"
echo ""
GEMINI_KEY=$(prompt_with_default "Gemini API key (Enter to skip)" "")

echo ""
echo "    ─────────────────────────────────"
echo "    Agent name:  $AGENT_NAME"
echo "    Your name:   $USER_NAME"
echo "    Email:       $USER_EMAIL"
echo "    Language:    $LANGUAGE"
echo "    Gemini key:  ${GEMINI_KEY:+(set)}"
echo "    ─────────────────────────────────"
echo ""

read -p "    Continue with these settings? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Date values for templates
TODAY=$(date +%Y-%m-%d)
MONTH=$(date +%Y-%m)
UNIX_USER=$(whoami)

# -----------------------------------------------------------------------------
# Step 1: System packages
# -----------------------------------------------------------------------------

print_step "Installing system packages..."

sudo apt update -qq
sudo apt install -y -qq tmux git curl wget build-essential ffmpeg unzip > /dev/null 2>&1

print_success "tmux, git, curl, wget, build-essential, ffmpeg, unzip"

# -----------------------------------------------------------------------------
# Step 2: Node.js
# -----------------------------------------------------------------------------

print_step "Checking Node.js..."

if check_command node; then
    :
else
    print_step "Installing Node.js 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - > /dev/null 2>&1
    sudo apt install -y -qq nodejs > /dev/null 2>&1
    print_success "Node.js $(node --version) installed"
fi

# -----------------------------------------------------------------------------
# Step 3: npm global directory
# -----------------------------------------------------------------------------

print_step "Configuring npm global directory..."

mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"

if ! grep -q '.npm-global/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.npm-global/bin:$PATH"

print_success "npm global prefix set to ~/.npm-global"

# -----------------------------------------------------------------------------
# Step 4: Bun
# -----------------------------------------------------------------------------

print_step "Checking Bun..."

if check_command bun; then
    :
else
    print_step "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash > /dev/null 2>&1

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$HOME/.bun/bin:$PATH"

    if ! grep -q 'BUN_INSTALL' "$HOME/.bashrc"; then
        echo 'export BUN_INSTALL="$HOME/.bun"' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.bun/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    print_success "Bun $(bun --version) installed"
fi

# -----------------------------------------------------------------------------
# Step 5: Claude Code
# -----------------------------------------------------------------------------

print_step "Checking Claude Code..."

if check_command claude; then
    print_success "Claude Code already installed"
else
    print_step "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code > /dev/null 2>&1
    print_success "Claude Code installed"
fi

# -----------------------------------------------------------------------------
# Step 6: GitHub CLI
# -----------------------------------------------------------------------------

print_step "Checking GitHub CLI..."

if check_command gh; then
    print_success "GitHub CLI already installed"
else
    print_step "Installing GitHub CLI..."
    sudo apt install -y -qq gh > /dev/null 2>&1
    print_success "GitHub CLI installed"
fi

# -----------------------------------------------------------------------------
# Step 7: Git config
# -----------------------------------------------------------------------------

print_step "Configuring git..."

git config --global user.name "$USER_NAME"
if [ -n "$USER_EMAIL" ]; then
    git config --global user.email "$USER_EMAIL"
fi

print_success "git user: $USER_NAME <$USER_EMAIL>"

# -----------------------------------------------------------------------------
# Step 8: Obsidian Vault
# -----------------------------------------------------------------------------

print_step "Setting up Obsidian vault..."

if [ -d "$VAULT_DIR" ]; then
    print_warning "Vault already exists at $VAULT_DIR — skipping (won't overwrite)"
else
    cp -r "$REPO_DIR/vault-template" "$VAULT_DIR"

    # Replace all tokens in vault files
    find "$VAULT_DIR" -name "*.md" -exec sed -i \
        -e "s/{{DATE}}/$TODAY/g" \
        -e "s/{{MONTH}}/$MONTH/g" \
        -e "s/{{AGENT_NAME}}/$AGENT_NAME/g" \
        -e "s/{{USER_NAME}}/$USER_NAME/g" \
        -e "s/{{USER_EMAIL}}/$USER_EMAIL/g" \
        -e "s/{{LANGUAGE}}/$LANGUAGE/g" \
        -e "s/{{UNIX_USER}}/$UNIX_USER/g" \
        {} +

    print_success "Vault created at $VAULT_DIR"
fi

# -----------------------------------------------------------------------------
# Step 9: CLAUDE.md
# -----------------------------------------------------------------------------

print_step "Setting up CLAUDE.md..."

if [ -f "$HOME/CLAUDE.md" ]; then
    print_warning "CLAUDE.md already exists at ~/CLAUDE.md — skipping (won't overwrite)"
else
    sed -e "s/{{AGENT_NAME}}/$AGENT_NAME/g" \
        -e "s/{{USER_NAME}}/$USER_NAME/g" \
        -e "s/{{USER_EMAIL}}/$USER_EMAIL/g" \
        -e "s/{{LANGUAGE}}/$LANGUAGE/g" \
        "$REPO_DIR/CLAUDE.md" > "$HOME/CLAUDE.md"

    print_success "CLAUDE.md personalized and copied to ~/CLAUDE.md"
fi

# -----------------------------------------------------------------------------
# Step 10: Claude Code settings
# -----------------------------------------------------------------------------

print_step "Configuring Claude Code settings..."

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/scripts"

if [ -f "$SETTINGS_FILE" ]; then
    print_warning "Settings file already exists — skipping (won't overwrite)"
else
    sed -e "s|__HOME__|$HOME|g" \
        -e "s|__GEMINI_API_KEY__|$GEMINI_KEY|g" \
        "$REPO_DIR/config-templates/settings.json" > "$SETTINGS_FILE"

    print_success "Claude Code settings configured"
fi

# -----------------------------------------------------------------------------
# Step 11: MCP servers
# -----------------------------------------------------------------------------

print_step "Configuring MCP servers..."

MCP_FILE="$CLAUDE_DIR/.mcp.json"

if [ -f "$MCP_FILE" ]; then
    print_warning "MCP config already exists — skipping (won't overwrite)"
else
    cp "$REPO_DIR/config-templates/mcp.json" "$MCP_FILE"
    print_success "MCP servers configured (Context7)"
fi

# -----------------------------------------------------------------------------
# Step 12: Transcription script
# -----------------------------------------------------------------------------

print_step "Installing audio transcription script..."

TRANSCRIBE_FILE="$CLAUDE_DIR/scripts/transcribe.ts"

if [ -f "$TRANSCRIBE_FILE" ]; then
    print_warning "Transcription script already exists — skipping"
else
    cp "$REPO_DIR/scripts/transcribe.ts" "$TRANSCRIBE_FILE"
    print_success "transcribe.ts installed at $TRANSCRIBE_FILE"
fi

# -----------------------------------------------------------------------------
# Step 13: Shell environment
# -----------------------------------------------------------------------------

print_step "Configuring shell environment..."

if ! grep -q '# --- agent-homebase ---' "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" << BASHEOF

# --- agent-homebase ---
export PATH="\$HOME/.local/bin:\$PATH"
BASHEOF

    if [ -n "$GEMINI_KEY" ]; then
        echo "export GEMINI_API_KEY=\"$GEMINI_KEY\"" >> "$HOME/.bashrc"
    fi

    print_success "Shell environment configured"
else
    print_warning "Shell additions already present — skipping"
fi

export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:$PATH"

# -----------------------------------------------------------------------------
# Done!
# -----------------------------------------------------------------------------

echo ""
echo "============================================="
echo -e "  ${GREEN}Setup complete!${NC}"
echo "============================================="
echo ""
echo "  Next steps:"
echo ""
echo "  1. Authenticate Claude Code:"
echo "     $ claude"
echo ""
echo "  2. Install the Telegram plugin (inside Claude Code):"
echo "     /install-plugin telegram@claude-plugins-official"
echo ""
echo "  3. Configure Telegram:"
echo "     /telegram:configure YOUR_BOT_TOKEN"
echo "     /telegram:access"
echo ""
echo "  4. Launch with tmux:"
echo "     $ tmux new -s claude"
echo "     $ claude --channels plugin:telegram@claude-plugins-official"
echo ""
echo "  5. Close the SSH window — your agent is now running 24/7!"
echo ""
echo "  ─────────────────────────────────────────────"
echo "  Permissions: Claude Code will ask for permission"
echo "  before running commands. This is the safest default."
echo ""
echo "  For unattended Telegram use, see docs/INSTALL.md"
echo "  on configuring automatic permissions."
echo "  ─────────────────────────────────────────────"
echo ""
echo "  Full guide:       docs/INSTALL.md"
echo "  Memory system:    docs/MEMORY.md"
echo "  Troubleshooting:  docs/TROUBLESHOOTING.md"
echo ""
