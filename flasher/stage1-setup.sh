#!/bin/bash

# Stage 1 Setup Script - Prepares Pi for private repo access
# This script is hosted in the public repo and sets up GitHub authentication

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Battery Flasher - Stage 1 Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "This script will prepare your Raspberry Pi for the Battery Flasher installation."
echo ""

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run with sudo${NC}"
   echo "Please run: sudo bash stage1-setup.sh"
   exit 1
fi

# Update package lists
echo -e "\n${YELLOW}Updating package lists...${NC}"
apt-get update

# Install essential dependencies
echo -e "\n${YELLOW}Installing essential dependencies...${NC}"
apt-get install -y \
    curl \
    git \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Install GitHub CLI
echo -e "\n${YELLOW}Installing GitHub CLI...${NC}"
# Add GitHub CLI repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Update and install gh
apt-get update
apt-get install -y gh

# Create flasher directory
echo -e "\n${YELLOW}Creating flasher directory...${NC}"
mkdir -p /opt/flasher
cd /opt/flasher

# Configure git to use GitHub CLI for authentication
echo -e "\n${YELLOW}Configuring git authentication...${NC}"
git config --global credential.helper "!gh auth git-credential"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Stage 1 Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Authenticate with GitHub (as the current user, not root):"
echo -e "   ${GREEN}gh auth login${NC}"
echo ""
echo "   - Choose: GitHub.com"
echo "   - Choose: HTTPS"
echo "   - Choose: Login with a web browser (or paste token)"
echo "   - Follow the prompts to authenticate"
echo ""
echo "2. After authentication, run the main installer:"
echo -e "   ${GREEN}curl -sL https://raw.githubusercontent.com/privitera/flasher/main/deploy.sh | sudo bash${NC}"
echo ""
echo "The main installer will:"
echo "• Clone the private repository"
echo "• Build flashbatt from source"
echo "• Configure all services"
echo "• Set up the complete system"
echo ""