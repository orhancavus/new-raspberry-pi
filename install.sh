#!/usr/bin/env bash
# ==============================================================================
# Master Setup Runner for Raspberry Pi Development Station
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    echo -e "${CYAN}${BOLD}         Raspberry Pi 5 AI & Dev Station Setup Suite               ${NC}"
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    echo -e " Target User: ${GREEN}${USER}${NC} | Host: ${GREEN}$(hostname)${NC}"
    echo -e " Config File: ${YELLOW}${CONFIG_FILE}${NC}"
    echo -e "${CYAN}--------------------------------------------------------------------${NC}"
}

run_step() {
    local step_num="$1"
    local script_name="$2"
    local desc="$3"
    
    echo -e "\n${BOLD}${BLUE}>>> Running Phase ${step_num}: ${desc}${NC}"
    local script_path="$SCRIPT_DIR/scripts/${script_name}"
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        bash "$script_path"
    else
        echo -e "${YELLOW}Warning: Script $script_path not found!${NC}"
    fi
}

run_all() {
    echo -e "\n${BOLD}${GREEN}Starting Complete Step-by-Step Installation...${NC}"
    run_step "1" "01_system_base.sh" "Base System, Essential CLI Tools & eza"
    run_step "2" "02_shell_zsh.sh" "Zsh, Oh-My-Zsh & Productivity Plugins"
    run_step "3" "03_python_uv.sh" "Python Environment & Astral uv"
    run_step "4" "04_nodejs.sh" "Node.js & NVM"
    run_step "5" "05_hailo_ai.sh" "Raspberry Pi AI Kit & Hailo NPU Setup"
    run_step "6" "06_ollama.sh" "Ollama Local LLM Engine & Models"
    run_step "7" "07_cloudflared.sh" "Cloudflare Tunnel (cloudflared)"
    run_step "8" "08_workspace_dirs.sh" "Workspace Hierarchy & Agent Directories"
    run_step "9" "09_git_ssh.sh" "Git Identity, SSH Key & GitHub CLI"
    run_step "10" "10_docker.sh" "Docker CE Engine (Optional)"

    echo -e "\n${CYAN}${BOLD}====================================================================${NC}"
    echo -e "${GREEN}${BOLD}             ✔ All Installation Phases Finished!                   ${NC}"
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    echo -e "Recommendations:"
    echo -e "  1. If you configured PCIe Gen 3 for Hailo, reboot with: ${BOLD}sudo reboot${NC}"
    echo -e "  2. Test your Hailo AI Hat after reboot: ${BOLD}hailortcli fw-control identify${NC}"
    echo -e "  3. Log in to GitHub if desired: ${BOLD}gh auth login${NC}"
    echo -e "  4. Switch your shell to Zsh: ${BOLD}chsh -s $(which zsh)${NC}"
    echo -e "${CYAN}--------------------------------------------------------------------${NC}\n"
}

show_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}Select an option:${NC}"
        echo -e "  ${GREEN}1)${NC} Run Full Installation (All 10 Phases)"
        echo -e "  ${CYAN}2)${NC} Base System, CLI Tools & eza (01)"
        echo -e "  ${CYAN}3)${NC} Zsh, Oh-My-Zsh & Plugins (02)"
        echo -e "  ${CYAN}4)${NC} Python Environment & Astral uv (03)"
        echo -e "  ${CYAN}5)${NC} Node.js & NVM (04)"
        echo -e "  ${CYAN}6)${NC} Raspberry Pi AI Kit / Hailo NPU & PCIe Gen 3 (05)"
        echo -e "  ${CYAN}7)${NC} Ollama Local LLMs (06)"
        echo -e "  ${CYAN}8)${NC} Cloudflare Tunnel & Helper Script (07)"
        echo -e "  ${CYAN}9)${NC} Workspace Directories & Agent Skills (08)"
        echo -e "  ${CYAN}10)${NC} Git, SSH Key & GitHub CLI (09)"
        echo -e "  ${CYAN}11)${NC} Docker Engine (10)"
        echo -e "  ${YELLOW}0)${NC} Exit"
        echo -e "${CYAN}--------------------------------------------------------------------${NC}"
        read -r -p "Enter choice [0-11]: " choice

        case "$choice" in
            1) run_all; break ;;
            2) run_step "1" "01_system_base.sh" "Base System & CLI Tools"; read -r -p "Press Enter to continue..." ;;
            3) run_step "2" "02_shell_zsh.sh" "Zsh & Plugins"; read -r -p "Press Enter to continue..." ;;
            4) run_step "3" "03_python_uv.sh" "Python & uv"; read -r -p "Press Enter to continue..." ;;
            5) run_step "4" "04_nodejs.sh" "Node.js & NVM"; read -r -p "Press Enter to continue..." ;;
            6) run_step "5" "05_hailo_ai.sh" "Hailo AI Kit & PCIe"; read -r -p "Press Enter to continue..." ;;
            7) run_step "6" "06_ollama.sh" "Ollama Local LLMs"; read -r -p "Press Enter to continue..." ;;
            8) run_step "7" "07_cloudflared.sh" "Cloudflare Tunnel"; read -r -p "Press Enter to continue..." ;;
            9) run_step "8" "08_workspace_dirs.sh" "Workspace Folders"; read -r -p "Press Enter to continue..." ;;
            10) run_step "9" "09_git_ssh.sh" "Git, SSH & GitHub CLI"; read -r -p "Press Enter to continue..." ;;
            11) run_step "10" "10_docker.sh" "Docker Engine"; read -r -p "Press Enter to continue..." ;;
            0) echo "Exiting."; exit 0 ;;
            *) echo "Invalid option."; sleep 1 ;;
        esac
    done
}

# Command line arguments parsing
if [ "${1:-}" = "--all" ] || [ "${1:-}" = "-a" ]; then
    run_all
elif [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Usage: ./install.sh [OPTION]"
    echo "Options:"
    echo "  --all, -a     Run all installation phases unattended"
    echo "  --step <1-10> Run a specific installation step"
    echo "  --help, -h    Display this help message"
    echo "  (no args)     Launch interactive menu"
elif [ "${1:-}" = "--step" ]; then
    case "${2:-}" in
        1) run_step "1" "01_system_base.sh" "Base System & CLI Tools" ;;
        2) run_step "2" "02_shell_zsh.sh" "Zsh & Plugins" ;;
        3) run_step "3" "03_python_uv.sh" "Python & uv" ;;
        4) run_step "4" "04_nodejs.sh" "Node.js & NVM" ;;
        5) run_step "5" "05_hailo_ai.sh" "Hailo AI Kit & PCIe" ;;
        6) run_step "6" "06_ollama.sh" "Ollama Local LLMs" ;;
        7) run_step "7" "07_cloudflared.sh" "Cloudflare Tunnel" ;;
        8) run_step "8" "08_workspace_dirs.sh" "Workspace Folders" ;;
        9) run_step "9" "09_git_ssh.sh" "Git, SSH & GitHub CLI" ;;
        10) run_step "10" "10_docker.sh" "Docker Engine" ;;
        *) echo "Invalid step number: ${2:-}"; exit 1 ;;
    esac
else
    show_menu
fi
