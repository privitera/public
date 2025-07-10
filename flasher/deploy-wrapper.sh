#!/bin/bash

# Wrapper script for deploying from private repository
# This script is public and handles authentication for the private repo

set -e

# Colors for output - Paul Tol's colorblind-safe palette
GREEN='\033[38;2;0;158;115m'   # Success messages
YELLOW='\033[38;2;238;119;51m' # Warnings and prompts
RED='\033[38;2;204;51;17m'     # Errors
GREY='\033[38;2;187;187;187m'  # Secondary info
NC='\033[0m' # No Color

echo -e "${GREEN}Battery Flasher Deployment Wrapper${NC}"
echo "===================================="
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Please run the Stage 1 setup first:"
    echo "  curl -sL https://privitera.github.io/public/flasher/stage1-setup.sh | sudo bash"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub${NC}"
    echo "Please authenticate first:"
    echo "  gh auth login"
    echo ""
    echo "Choose: GitHub.com → SSH → Generate new SSH key"
    exit 1
fi

# Set up cleanup trap for interrupts
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
        # Note: The deployment script should have copied all needed files
        # to their permanent locations (/root/flasher, /etc/systemd/system, etc)
        rm -rf "$TEMP_DIR"
    fi
}

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap cleanup EXIT INT TERM

echo -e "${YELLOW}Cloning private repository...${NC}"
cd "$TEMP_DIR"

# Clone the private repo using gh
if ! git clone git@github.com:privitera/flasher.git &> /dev/null; then
    echo -e "${RED}Error: Failed to clone repository${NC}"
    echo "Please check your GitHub authentication and try again"
    exit 1
fi

# Check if deploy.sh exists
if [ ! -f "flasher/deploy.sh" ]; then
    echo -e "${RED}Error: deploy.sh not found in repository${NC}"
    exit 1
fi

# Make it executable
chmod +x flasher/deploy.sh

# Execute the deployment script with sudo
echo -e "${YELLOW}Running deployment script...${NC}"
cd flasher

# Check if running in an interactive terminal
if [ -t 0 ] && [ -t 1 ]; then
    # Interactive terminal available, run normally
    sudo ./deploy.sh
else
    # No interactive terminal - provide instructions for interactive setup
    echo -e "${YELLOW}┌────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│ Interactive Setup Required                                 │${NC}"
    echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${RED}The hardware configurator needs an interactive terminal.${NC}"
    echo -e "${GREY}(Press Ctrl+C to exit)${NC}"
    echo ""
    echo "Please run the deployment directly:"
    echo -e "  ${GREEN}cd /tmp/${NC}"
    echo -e "  ${GREEN}git clone git@github.com:privitera/flasher.git${NC}"
    echo -e "  ${GREEN}cd flasher && sudo ./deploy.sh${NC}"
    echo ""
    echo "Or use auto-detection mode (less options):"
    echo -e "  ${GREEN}cd /tmp/${NC}"
    echo -e "  ${GREEN}git clone git@github.com:privitera/flasher.git${NC}"
    echo -e "  ${GREEN}cd flasher && sudo ./deploy.sh --auto${NC}"
    echo ""
    exit 1
fi

# Script will clean up temp directory on exit due to trap