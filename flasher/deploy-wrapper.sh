#!/bin/bash

# Wrapper script for deploying from private repository
# This script is public and handles authentication for the private repo

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

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
    # No interactive terminal, run with auto mode
    echo -e "${YELLOW}Note: Running in non-interactive mode${NC}"
    sudo ./deploy.sh --auto
fi

# Script will clean up temp directory on exit due to trap