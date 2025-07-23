#!/bin/bash
# Stage 1 Setup Script - Universal MS-01 Bootstrap
# Minimal setup for GitHub authentication and Stage 2 deployment
set -e

# Script info
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Universal Stage 1 Setup"

# Colors for output - Standard ANSI colors
GREEN='\033[0;32m'   # Success messages
YELLOW='\033[1;33m'  # Warnings and prompts
RED='\033[0;31m'     # Errors
BLUE='\033[0;34m'    # Info
BOLD='\033[1m'       # Bold text
NC='\033[0m'         # No Color

echo -e "${BOLD}${GREEN}========================================${NC}"
echo -e "${BOLD}${GREEN}${SCRIPT_NAME} v${SCRIPT_VERSION}${NC}"
echo -e "${BOLD}${GREEN}========================================${NC}"
echo ""
echo "This script prepares your system for deployment."
echo ""

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run with sudo${NC}"
   echo "Please run: sudo bash $0"
   exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo -e "${BLUE}Detected OS:${NC} $NAME $VERSION"
fi

# Update package lists
echo -e "\n${YELLOW}Updating package lists...${NC}"
apt-get update

# Install minimal dependencies
echo -e "\n${YELLOW}Installing essential dependencies...${NC}"
apt-get install -y \
    curl \
    git \
    wget \
    ca-certificates \
    gnupg \
    lsb-release

# Check if GitHub CLI is already installed
if command -v gh &> /dev/null; then
    echo -e "\n${GREEN}GitHub CLI already installed:${NC} $(gh --version | head -n1)"
else
    # Install GitHub CLI
    echo -e "\n${YELLOW}Installing GitHub CLI...${NC}"
    
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    # Update and install gh
    apt-get update
    apt-get install -y gh
fi

# Configure git to use GitHub CLI for authentication
echo -e "\n${YELLOW}Configuring git authentication...${NC}"
git config --global credential.helper "!gh auth git-credential"

# Create deployment base directory
DEPLOY_DIR="/opt/deployment"
echo -e "\n${YELLOW}Creating deployment directory...${NC}"
mkdir -p "$DEPLOY_DIR"

# Save deployment info
cat > "$DEPLOY_DIR/.stage1-info" << EOF
STAGE1_VERSION=$SCRIPT_VERSION
STAGE1_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)
EOF

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Stage 1 Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Authenticate with GitHub (as your regular user, not root):"
echo -e "   ${GREEN}gh auth login${NC}"
echo ""
echo "   • Choose: GitHub.com"
echo "   • Choose: SSH (recommended)"
echo "   • Follow the prompts to authenticate"
echo ""
echo "2. Run your Stage 2 deployment script"
echo "   Your Stage 2 script will provide an interactive TUI to select"
echo "   deployment configuration and apply your customizations."
echo ""
echo -e "${BLUE}System ready for deployment!${NC}"
echo ""