#!/bin/bash

# Run Deploy Script - Automates GitHub authentication and deployment
# This script handles the authentication flow and then runs the deployment

set -e

# Colors for output - Paul Tol's colorblind-safe palette
GREEN='\033[38;2;0;158;115m'   # Success messages
YELLOW='\033[38;2;238;119;51m' # Warnings and prompts
RED='\033[38;2;204;51;17m'     # Errors
NC='\033[0m' # No Color

echo -e "${GREEN}Battery Flasher - Automated Deployment${NC}"
echo "======================================"
echo ""

# Set BROWSER to prevent launch attempts
export BROWSER=echo

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI not installed${NC}"
    echo "Please run stage1 setup first:"
    echo "  curl -sL https://privitera.github.io/public/flasher/stage1-setup.sh | sudo bash"
    exit 1
fi

# Check if already authenticated
if gh auth status &> /dev/null; then
    echo -e "${GREEN}✓ Already authenticated with GitHub${NC}"
else
    echo -e "${YELLOW}Starting GitHub authentication...${NC}"
    echo ""
    echo "You will see a one-time code. Copy it and browse to:"
    echo "https://github.com/login/device"
    echo ""
    gh auth login
fi

echo ""
echo -e "${YELLOW}Starting deployment...${NC}"
echo ""

# Run the deployment with cookie-free wget
exec bash -c "wget --no-cookies --no-cache https://privitera.github.io/public/flasher/deploy-wrapper.sh -O deploy-wrapper.sh && bash deploy-wrapper.sh && rm deploy-wrapper.sh"