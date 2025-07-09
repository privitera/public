#!/bin/bash

# Interactive deployment runner - handles GitHub auth and deployment
# This script runs gh auth login interactively, then automatically proceeds to deployment

set -e

# Colors for output - Paul Tol's colorblind-safe palette
GREEN='\033[38;2;0;158;115m'   # Success messages
YELLOW='\033[38;2;238;119;51m' # Warnings and prompts
RED='\033[38;2;204;51;17m'     # Errors
BLUE='\033[38;2;0;119;187m'    # Headers
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Battery Flasher - Automated Deploy      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Please run the Stage 1 setup first:"
    echo "  curl -sL https://privitera.github.io/public/flasher/stage1-setup.sh | sudo bash"
    exit 1
fi

# Check if already authenticated
if gh auth status &> /dev/null; then
    echo -e "${GREEN}✓ Already authenticated with GitHub${NC}"
    echo ""
else
    echo -e "${YELLOW}Step 1: GitHub Authentication${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "You'll now be prompted to authenticate with GitHub."
    echo "Recommended choices:"
    echo "  • GitHub.com"
    echo "  • SSH protocol"
    echo "  • Generate new SSH key (or use existing)"
    echo ""
    echo -e "${YELLOW}Starting GitHub authentication...${NC}"
    echo ""
    
    # Run gh auth login interactively
    gh auth login
    
    echo ""
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Authentication failed or was cancelled${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ GitHub authentication successful${NC}"
echo ""
echo -e "${YELLOW}Step 2: Running Deployment${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Downloading and running the deployment script..."
echo "This will launch the interactive hardware configurator."
echo ""

# Short pause to let user read the message
sleep 2

# Run the deployment
exec bash -c "wget https://privitera.github.io/public/flasher/deploy-wrapper.sh && bash deploy-wrapper.sh && rm deploy-wrapper.sh"