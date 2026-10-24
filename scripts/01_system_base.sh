#!/usr/bin/env bash
# ==============================================================================
# Phase 1: Base System, Package Updates & Essential CLI Tools
# ==============================================================================
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[1/10] Starting Base System & CLI Tools Setup...${NC}"

# Ensure running under Debian/Raspberry Pi OS
if ! command -v apt &> /dev/null; then
    echo "Error: apt package manager not found. This script requires Debian/Raspberry Pi OS." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo -e "${BLUE}--> Updating package list and upgrading system packages...${NC}"
sudo apt update -y
sudo apt upgrade -y

echo -e "${BLUE}--> Installing essential tools and dependencies...${NC}"
sudo apt install -y \
    build-essential \
    curl \
    wget \
    gpg \
    gpg-agent \
    ca-certificates \
    software-properties-common \
    silversearcher-ag \
    tmux \
    zip \
    unzip \
    tar \
    gzip \
    git \
    vim \
    nano \
    htop \
    rpicam-apps

echo -e "${BLUE}--> Installing 'eza' (modern, feature-rich replacement for 'ls')...${NC}"
sudo mkdir -p -m 755 /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --yes
fi

echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

sudo apt update -y
sudo apt install -y eza

echo -e "${GREEN}✔ Base system packages and 'eza' installed successfully.${NC}"
