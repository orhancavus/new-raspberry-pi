#!/usr/bin/env bash
# ==============================================================================
# Phase 5: Raspberry Pi AI Kit (Hailo-8 / Hailo-8L / Hailo-10 NPU)
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.env"
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

ENABLE_PCIE_GEN3="${ENABLE_PCIE_GEN3:-true}"

echo -e "${BLUE}[5/10] Starting Raspberry Pi AI Kit (Hailo NPU) Setup...${NC}"

echo -e "${BLUE}--> Installing Hailo software stack (hailo-all & python3-hailort)...${NC}"
sudo apt update -y
sudo apt install -y hailo-all python3-hailort

# Locate config.txt (/boot/firmware/config.txt on Bookworm, /boot/config.txt on older versions)
CONFIG_TXT=""
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_TXT="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    CONFIG_TXT="/boot/config.txt"
fi

if [ -n "$CONFIG_TXT" ] && [ "$ENABLE_PCIE_GEN3" = "true" ]; then
    echo -e "${BLUE}--> Configuring PCIe Gen 3 for Hailo NPU in $CONFIG_TXT...${NC}"
    
    # Check if pciex1 is present
    if ! grep -q "^dtparam=pciex1" "$CONFIG_TXT"; then
        echo "dtparam=pciex1" | sudo tee -a "$CONFIG_TXT" > /dev/null
        echo -e "${GREEN}  Added 'dtparam=pciex1' to $CONFIG_TXT${NC}"
    fi

    # Check if pciex1_gen=3 is present
    if ! grep -q "^dtparam=pciex1_gen=3" "$CONFIG_TXT"; then
        echo "dtparam=pciex1_gen=3" | sudo tee -a "$CONFIG_TXT" > /dev/null
        echo -e "${GREEN}  Added 'dtparam=pciex1_gen=3' to $CONFIG_TXT${NC}"
    fi
fi

echo -e "${BLUE}--> Checking Hailo device status...${NC}"
if command -v hailortcli &> /dev/null; then
    if hailortcli fw-control identify 2>/dev/null; then
        echo -e "${GREEN}✔ Hailo NPU identified and active!${NC}"
    else
        echo -e "${YELLOW}Note: Hailo NPU driver is installed, but hardware may require a reboot to initialize PCIe.${NC}"
        echo -e "${YELLOW}After reboot, run: 'hailortcli fw-control identify'${NC}"
    fi
else
    echo -e "${RED}hailortcli command not found. Please review apt installation output.${NC}"
fi

echo -e "${GREEN}✔ Hailo AI stack installed.${NC}"
