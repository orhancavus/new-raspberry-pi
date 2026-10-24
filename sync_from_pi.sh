#!/usr/bin/env bash
# ==============================================================================
# Intelligent Remote Sync Script: Raspberry Pi -> macOS
# ==============================================================================
# Features:
#   - Dynamic .gitignore filtering (--filter=':- .gitignore')
#   - Excludes heavy dependencies (node_modules, .venv, .next, __pycache__)
#   - Excludes temporary logs, caches, build outputs, and keystores
#   - Resumable transfers with on-the-wire compression (-avz --partial)
#   - Real-time overall transfer progress (--info=progress2)
#   - Safe dry-run mode (--dry-run) to preview files before syncing
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDE_FILE="$SCRIPT_DIR/rsync-exclude.txt"

# Text Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Defaults
REMOTE_HOST=""
REMOTE_USER="tenkanhm"
REMOTE_PATH="~/pydev/"
LOCAL_DEST="$HOME/Downloads/rpi-pydev-backup"
SSH_PORT="22"
DRY_RUN=false
EXCLUDE_GIT=false

usage() {
    echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --host <ip/host>     Remote Raspberry Pi IP or hostname (e.g. 192.168.1.101)"
    echo "  -u, --user <username>    Remote SSH user (default: tenkanhm)"
    echo "  -r, --remote <path>      Remote path to copy (default: ~/pydev/)"
    echo "  -d, --dest <path>        Local macOS destination directory (default: ~/Downloads/rpi-pydev-backup)"
    echo "  -p, --port <port>        SSH port (default: 22)"
    echo "  -n, --dry-run            Simulate transfer without copying any files"
    echo "      --exclude-git        Also exclude .git repositories"
    echo "      --help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --host 192.168.1.101 --dry-run"
    echo "  $0 --host 192.168.1.101 --user tenkanhm --remote ~/pydev/ --dest ~/Development/rpi_backup"
    exit 0
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--host) REMOTE_HOST="$2"; shift 2 ;;
        -u|--user) REMOTE_USER="$2"; shift 2 ;;
        -r|--remote) REMOTE_PATH="$2"; shift 2 ;;
        -d|--dest) LOCAL_DEST="$2"; shift 2 ;;
        -p|--port) SSH_PORT="$2"; shift 2 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        --exclude-git) EXCLUDE_GIT=true; shift ;;
        --help) usage ;;
        *) echo -e "${RED}Unknown argument: $1${NC}"; usage ;;
    esac
done

# Check if rsync is available
if ! command -v rsync &> /dev/null; then
    echo -e "${RED}Error: 'rsync' is not installed on this system.${NC}"
    echo "Install via Homebrew: brew install rsync"
    exit 1
fi

# Interactive prompt if host is not provided
if [ -z "$REMOTE_HOST" ]; then
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    echo -e "${CYAN}${BOLD}       Intelligent Remote Sync: Raspberry Pi -> macOS               ${NC}"
    echo -e "${CYAN}${BOLD}====================================================================${NC}"
    
    read -r -p "Enter Raspberry Pi IP or Hostname [e.g. 192.168.1.101 or raspberrypi.local]: " input_host
    REMOTE_HOST="${input_host:-}"
    if [ -z "$REMOTE_HOST" ]; then
        echo -e "${RED}Error: Hostname/IP is required.${NC}"
        exit 1
    fi

    read -r -p "Enter SSH Username on Raspberry Pi [default: ${REMOTE_USER}]: " input_user
    REMOTE_USER="${input_user:-$REMOTE_USER}"

    read -r -p "Enter Remote Path to sync [default: ${REMOTE_PATH}]: " input_remote
    REMOTE_PATH="${input_remote:-$REMOTE_PATH}"

    read -r -p "Enter Local Destination [default: ${LOCAL_DEST}]: " input_dest
    LOCAL_DEST="${input_dest:-$LOCAL_DEST}"

    read -r -p "Perform a Dry Run first to preview files? [Y/n]: " input_dry
    if [[ "$input_dry" =~ ^[Nn] ]]; then
        DRY_RUN=false
    else
        DRY_RUN=true
    fi
fi

# Expand tilde in local path
LOCAL_DEST="${LOCAL_DEST/#\~/$HOME}"
mkdir -p "$LOCAL_DEST"

# Build rsync options array
RSYNC_ARGS=(
    -avz
    --partial
    --filter=":- .gitignore"
)

# Check if rsync supports modern --info=progress2
if rsync --info=help 2>&1 | grep -q 'progress2'; then
    RSYNC_ARGS+=(--info=progress2)
else
    RSYNC_ARGS+=(-P)
fi

# Include global exclude list if available
if [ -f "$EXCLUDE_FILE" ]; then
    RSYNC_ARGS+=(--exclude-from="$EXCLUDE_FILE")
fi

# Optional: exclude .git repositories
if [ "$EXCLUDE_GIT" = "true" ]; then
    RSYNC_ARGS+=(--exclude=".git/")
fi

# Dry run flag
if [ "$DRY_RUN" = "true" ]; then
    RSYNC_ARGS+=(-n --stats)
fi

echo -e "\n${BLUE}${BOLD}>>> Sync Configuration:${NC}"
echo -e "  Remote Source: ${GREEN}${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}${NC}"
echo -e "  Local Target:  ${GREEN}${LOCAL_DEST}/${NC}"
echo -e "  SSH Port:      ${YELLOW}${SSH_PORT}${NC}"
echo -e "  Filtering:     ${CYAN}Active (Honors .gitignore + rsync-exclude.txt)${NC}"
if [ "$DRY_RUN" = "true" ]; then
    echo -e "  Mode:          ${YELLOW}${BOLD}[DRY RUN - Simulation Only]${NC}"
else
    echo -e "  Mode:          ${GREEN}${BOLD}[LIVE TRANSFER]${NC}"
fi
echo -e "${CYAN}--------------------------------------------------------------------${NC}\n"

# Execute rsync
rsync "${RSYNC_ARGS[@]}" \
    -e "ssh -p ${SSH_PORT}" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}" \
    "${LOCAL_DEST}/"

echo -e "\n${CYAN}--------------------------------------------------------------------${NC}"
if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}${BOLD}✔ Dry run complete.${NC} No files were transferred."
    echo -e "To execute the real transfer, run:"
    echo -e "  ${BOLD}$0 --host ${REMOTE_HOST} --user ${REMOTE_USER} --remote \"${REMOTE_PATH}\" --dest \"${LOCAL_DEST}\"${NC}"
else
    echo -e "${GREEN}${BOLD}✔ Sync completed successfully!${NC}"
    echo -e "Files saved to: ${BOLD}${LOCAL_DEST}/${NC}"
fi
echo -e "${CYAN}====================================================================${NC}\n"
