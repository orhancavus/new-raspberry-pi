#!/usr/bin/env bash
# ==============================================================================
# Phase 10: Docker Engine Installation (Optional)
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.env"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

INSTALL_DOCKER="${INSTALL_DOCKER:-true}"

echo -e "${BLUE}[10/10] Starting Docker Engine Setup...${NC}"

if [ "$INSTALL_DOCKER" != "true" ]; then
    echo -e "${YELLOW}--> Docker installation is disabled in config.env. Skipping.${NC}"
    exit 0
fi

if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}--> Fetching and running official Docker installation script...${NC}"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
else
    echo -e "${YELLOW}--> Docker is already installed: $(docker --version)${NC}"
fi

# Add current user to docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
    echo -e "${BLUE}--> Adding user '$USER' to the 'docker' group...${NC}"
    sudo usermod -aG docker "$USER"
    echo -e "${YELLOW}Note: You will need to log out and back in (or run 'newgrp docker') to use docker without sudo.${NC}"
fi

# Enable and start docker service
sudo systemctl enable --now docker || true

DOCKER_VER=$(docker --version)
echo -e "${GREEN}✔ Docker installation complete: ${DOCKER_VER}${NC}"
