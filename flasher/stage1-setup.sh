#!/bin/bash

# Stage 1 Setup Script - Prepares Pi for private repo access
# This script is hosted in the public repo and sets up GitHub authentication

set -e

# Colors for output - Paul Tol's colorblind-safe palette
GREEN='\033[38;2;0;158;115m'   # Success messages
YELLOW='\033[38;2;238;119;51m' # Warnings and prompts
RED='\033[38;2;204;51;17m'     # Errors
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
    software-properties-common \
    python3-pip \
    python3-dev \
    jq

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
echo "   - Choose: SSH"
echo "   - Choose: Generate new SSH key (or use existing)"
echo "   - Follow the prompts to authenticate"
echo ""
echo "2. After authentication, run the deployment:"
echo -e "   ${GREEN}wget https://privitera.github.io/public/flasher/deploy-wrapper.sh && bash deploy-wrapper.sh && rm deploy-wrapper.sh${NC}"
echo ""
echo "The deployment will:"
echo "• Clone the private repository"
echo "• Launch interactive hardware configurator"
echo "• Build flashbatt from source"
echo "• Configure all services"
echo "• Set up the complete system"
echo ""
echo -e "${YELLOW}Optional:${NC} To automate steps 1 & 2, run this script:"
echo -e "   ${GREEN}curl -sL https://privitera.github.io/public/flasher/run-deploy.sh | bash${NC}"
echo ""