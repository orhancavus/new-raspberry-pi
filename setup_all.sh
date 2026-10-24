#!/usr/bin/env bash
# ==============================================================================
# Standalone All-In-One Raspberry Pi Setup Script
# Automatically generated based on setup history analysis (rp_tenkanhm.txt)
#
# Target: Raspberry Pi 5 / Debian Bookworm (arm64)
# Features:
#   - Base packages & modern CLI (eza, ag, tmux, zip)
#   - Zsh, Oh-My-Zsh & plugins (autosuggestions, syntax-highlighting)
#   - Python Astral uv package manager
#   - Node.js LTS (v20) via NVM
#   - Hailo AI Kit (hailo-all, python3-hailort) + PCIe Gen 3 enablement
#   - Ollama local AI runtime & model pulls (qwen2.5:1.5b, moondream)
#   - Cloudflare Tunnel (cloudflared) & quick launcher helper
#   - Developer workspace structure (~/pydev/...)
#   - Git identity & ED25519 SSH key generation + GitHub CLI
#   - Docker CE Engine (Optional)
# ==============================================================================

set -euo pipefail

# Configuration Defaults (can be overridden with environment variables)
GIT_USER_NAME="${GIT_USER_NAME:-your_username}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-your_email@example.com}"
NODE_VERSION="${NODE_VERSION:-20}"
PULL_OLLAMA_MODELS="${PULL_OLLAMA_MODELS:-true}"
ENABLE_PCIE_GEN3="${ENABLE_PCIE_GEN3:-true}"
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
OLLAMA_MODELS=("qwen2.5:1.5b" "moondream")

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo -e "${CYAN}${BOLD}        Starting Standalone Raspberry Pi 5 Automated Setup         ${NC}"
echo -e "${CYAN}${BOLD}====================================================================${NC}"

# Ensure running on Debian/Ubuntu/Raspberry Pi OS
if ! command -v apt &> /dev/null; then
    echo "Error: apt package manager not found. This script requires Debian/Raspberry Pi OS." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 1. Base System, Package Updates & Essential CLI Tools
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 1/10] System Updates & Essential CLI Tools...${NC}"
sudo apt update -y && sudo apt upgrade -y

sudo apt install -y \
    build-essential curl wget gpg gpg-agent ca-certificates \
    software-properties-common silversearcher-ag tmux zip unzip tar gzip \
    git vim nano htop rpicam-apps

echo -e "${BLUE}--> Configuring 'eza' repository...${NC}"
sudo mkdir -p -m 755 /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --yes
fi
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

sudo apt update -y && sudo apt install -y eza
echo -e "${GREEN}✔ Base system tools and 'eza' installed.${NC}"

# ------------------------------------------------------------------------------
# 2. Zsh, Oh-My-Zsh & Plugins
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 2/10] Zsh & Shell Productivity Setup...${NC}"
if ! command -v zsh &> /dev/null; then
    sudo apt install -y zsh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}--> Installing Oh-My-Zsh (unattended)...${NC}"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
fi

if grep -q "^plugins=" "$ZSHRC"; then
    if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
        sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
    fi
else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
fi

if ! grep -q "alias ls='eza'" "$ZSHRC"; then
    cat << 'EOF' >> "$ZSHRC"

# Modern CLI aliases
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2'
fi
alias tmux-dev='tmux attach -t my-dev || tmux new -t my-dev'
EOF
fi
echo -e "${GREEN}✔ Zsh and plugins configured.${NC}"

# ------------------------------------------------------------------------------
# 3. Python Environment & Astral uv
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 3/10] Python & Astral uv Package Manager...${NC}"
sudo apt install -y python3 python3-pip python3-venv python3-dev

curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    fi
done
echo -e "${GREEN}✔ Astral uv installed: $(uv --version 2>/dev/null || echo 'in ~/.local/bin')${NC}"

# ------------------------------------------------------------------------------
# 4. Node.js & NVM
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 4/10] Node.js & NVM Setup...${NC}"
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if [ -f "$ZSHRC" ] && ! grep -q 'NVM_DIR' "$ZSHRC"; then
    cat << 'EOF' >> "$ZSHRC"

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
fi

nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
nvm use default
echo -e "${GREEN}✔ Node.js $(node -v) (npm $(npm -v)) installed.${NC}"

# ------------------------------------------------------------------------------
# 5. Raspberry Pi AI Kit & Hailo NPU Setup
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 5/10] Raspberry Pi AI Kit (Hailo NPU)...${NC}"
sudo apt update -y && sudo apt install -y hailo-all python3-hailort

CONFIG_TXT=""
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_TXT="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_TXT="/boot/config.txt"
fi

if [ -n "$CONFIG_TXT" ] && [ "$ENABLE_PCIE_GEN3" = "true" ]; then
    if ! grep -q "^dtparam=pciex1" "$CONFIG_TXT"; then
        echo "dtparam=pciex1" | sudo tee -a "$CONFIG_TXT" > /dev/null
    fi
    if ! grep -q "^dtparam=pciex1_gen=3" "$CONFIG_TXT"; then
        echo "dtparam=pciex1_gen=3" | sudo tee -a "$CONFIG_TXT" > /dev/null
    fi
    echo -e "${GREEN}✔ Configured PCIe Gen 3 in $CONFIG_TXT${NC}"
fi

# ------------------------------------------------------------------------------
# 6. Ollama Local LLM Engine & Models
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 6/10] Ollama Local LLM Engine...${NC}"
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
fi

sudo systemctl enable --now ollama || true

echo -e "${BLUE}--> Waiting for Ollama service to start...${NC}"
RETRIES=15
until curl -s http://localhost:11434/api/tags > /dev/null || [ $RETRIES -eq 0 ]; do
    sleep 2
    RETRIES=$((RETRIES - 1))
done

if [ "$PULL_OLLAMA_MODELS" = "true" ] && [ $RETRIES -gt 0 ]; then
    for model in "${OLLAMA_MODELS[@]}"; do
        echo -e "${BLUE}--> Pulling Ollama model: ${model}...${NC}"
        ollama pull "$model" || true
    done
fi
echo -e "${GREEN}✔ Ollama engine setup completed.${NC}"

# ------------------------------------------------------------------------------
# 7. Cloudflare Tunnel (cloudflared)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 7/10] Cloudflare Tunnel (cloudflared)...${NC}"
sudo mkdir -p --mode=0755 /usr/share/keyrings
if [ ! -f /usr/share/keyrings/cloudflare-main.gpg ]; then
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
fi
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list > /dev/null

sudo apt update -y && sudo apt install -y cloudflared

cat << 'EOF' > "$HOME/start_cloudflared.sh"
#!/usr/bin/env bash
PORT="${1:-3000}"
HOST="${2:-localhost}"
echo "Starting Cloudflare Quick Tunnel for http://${HOST}:${PORT}..."
cloudflared tunnel --url "http://${HOST}:${PORT}"
EOF
chmod +x "$HOME/start_cloudflared.sh"
echo -e "${GREEN}✔ cloudflared installed and ~/start_cloudflared.sh created.${NC}"

# ------------------------------------------------------------------------------
# 8. Workspace Directory Structure
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 8/10] Workspace Directories...${NC}"
mkdir -p "$HOME/pydev/01_agents"
mkdir -p "$HOME/pydev/02_apps"
mkdir -p "$HOME/pydev/03_ai_experiments"
mkdir -p "$HOME/pydev/04_tools_cli"
mkdir -p "$HOME/pydev/05_rasbpi"
mkdir -p "$HOME/.agents/skills"
echo -e "${GREEN}✔ Development directory tree ready in ~/pydev/${NC}"

# ------------------------------------------------------------------------------
# 9. Git, SSH & GitHub CLI
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}${BOLD}[Phase 9/10] Git, SSH & GitHub CLI...${NC}"

if [ "$GIT_USER_NAME" = "your_username" ] || [ -z "$GIT_USER_NAME" ]; then
    EXISTING_NAME=$(git config --global user.name 2>/dev/null || true)
    if [ -n "$EXISTING_NAME" ]; then
        GIT_USER_NAME="$EXISTING_NAME"
    elif [ -t 0 ]; then
        read -r -p "Enter your Git user name: " input_name
        GIT_USER_NAME="${input_name:-$GIT_USER_NAME}"
    fi
fi

if [ "$GIT_USER_EMAIL" = "your_email@example.com" ] || [ -z "$GIT_USER_EMAIL" ]; then
    EXISTING_EMAIL=$(git config --global user.email 2>/dev/null || true)
    if [ -n "$EXISTING_EMAIL" ]; then
        GIT_USER_EMAIL="$EXISTING_EMAIL"
    elif [ -t 0 ]; then
        read -r -p "Enter your Git email: " input_email
        GIT_USER_EMAIL="${input_email:-$GIT_USER_EMAIL}"
    fi
fi

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "raspberrypi" -f "$HOME/.ssh/id_ed25519" -N ""
fi

sudo apt update -y && sudo apt install -y gh
echo -e "${GREEN}✔ Git configured for $GIT_USER_NAME <$GIT_USER_EMAIL> and GitHub CLI installed.${NC}"

# ------------------------------------------------------------------------------
# 10. Docker CE Engine (Optional)
# ------------------------------------------------------------------------------
if [ "$INSTALL_DOCKER" = "true" ]; then
    echo -e "\n${BLUE}${BOLD}[Phase 10/10] Docker Engine Setup...${NC}"
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sudo sh /tmp/get-docker.sh
        rm -f /tmp/get-docker.sh
    fi
    sudo usermod -aG docker "$USER" || true
    sudo systemctl enable --now docker || true
    echo -e "${GREEN}✔ Docker installed: $(docker --version 2>/dev/null || echo 'active')${NC}"
fi

echo -e "\n${CYAN}${BOLD}====================================================================${NC}"
echo -e "${GREEN}${BOLD}             🎉 Setup Completed Successfully!                       ${NC}"
echo -e "${CYAN}${BOLD}====================================================================${NC}"
echo -e "Next steps:"
echo -e "  - Reboot system to finalize PCIe Gen 3 & Hailo drivers: ${BOLD}sudo reboot${NC}"
echo -e "  - Test Hailo NPU: ${BOLD}hailortcli fw-control identify${NC}"
echo -e "  - Switch shell to Zsh: ${BOLD}chsh -s $(which zsh)${NC}"
echo -e "  - Log in to GitHub: ${BOLD}gh auth login${NC}"
echo -e "${CYAN}--------------------------------------------------------------------${NC}\n"
