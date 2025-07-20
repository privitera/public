#!/bin/bash

# Public wrapper script for deploying from private repository
# This script handles authentication for accessing the private deployment repo

set -e

# Colors - Standard ANSI for better compatibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
GREY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${GREEN}========================================${NC}"
echo -e "${BOLD}${GREEN}Stage 2 Deployment System${NC}"
echo -e "${BOLD}${GREEN}========================================${NC}"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Please run the Stage 1 setup first:"
    echo "  wget -qO- https://privitera.github.io/public/stage1-setup.sh | sudo bash"
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

# Get GitHub username
GITHUB_USER=$(gh api user -q .login)
echo -e "${BLUE}GitHub user:${NC} $GITHUB_USER"

# Set up cleanup trap
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap cleanup EXIT INT TERM

echo -e "${YELLOW}Cloning private deployment repository...${NC}"
cd "$TEMP_DIR"

# Function to show progress
show_progress() {
    local progress=$1
    local total=$2
    local width=40
    local percentage=$((progress * 100 / total))
    local filled=$((width * progress / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' '-'
    printf "] %3d%%" $percentage
}

# Clone the private deployments repository
REPO_NAME="deployments-private"
echo -e "${GREY}Repository: github.com:${GITHUB_USER}/${REPO_NAME}.git${NC}"

if ! git clone --progress "git@github.com:${GITHUB_USER}/${REPO_NAME}.git" 2>&1 | while IFS= read -r line; do
    if [[ "$line" =~ Receiving\ objects:\ +([0-9]+)%\ \(([0-9]+)/([0-9]+)\) ]]; then
        current="${BASH_REMATCH[2]}"
        total="${BASH_REMATCH[3]}"
        show_progress $current $total
    elif [[ "$line" =~ "Cloning into" ]]; then
        echo -e "${GREY}$line${NC}"
    elif [[ "$line" =~ "error:" ]] || [[ "$line" =~ "fatal:" ]]; then
        echo -e "\n${RED}$line${NC}"
        
        # Check if it's a repository not found error
        if [[ "$line" =~ "Repository not found" ]] || [[ "$line" =~ "Could not read from remote repository" ]]; then
            echo -e "\n${YELLOW}If you haven't created your private deployments repository yet:${NC}"
            echo "1. Fork or create: https://github.com/privitera/deployments-private"
            echo "2. Make sure it's private"
            echo "3. Run this script again"
        fi
        exit 1
    fi
done; then
    echo -e "\n${RED}Error: Failed to clone repository${NC}"
    echo "Please check your GitHub authentication and repository access"
    exit 1
fi

echo -e "\n${GREEN}✓ Repository cloned successfully${NC}"

# Check if deploy.sh exists
if [ ! -f "${REPO_NAME}/deploy.sh" ]; then
    echo -e "${RED}Error: deploy.sh not found in repository${NC}"
    echo "Expected location: ${REPO_NAME}/deploy.sh"
    exit 1
fi

# Make it executable
chmod +x "${REPO_NAME}/deploy.sh"

# Change to repository directory
cd "${REPO_NAME}"

# Execute the deployment script
echo -e "\n${YELLOW}Launching deployment TUI...${NC}"
echo -e "${GREY}Select your deployment profile from the menu${NC}\n"

# Check if running in an interactive terminal
if [ -t 0 ] && [ -t 1 ]; then
    # Interactive terminal available, run normally
    ./deploy.sh
else
    # No interactive terminal
    echo -e "${RED}Error: This script requires an interactive terminal${NC}"
    echo "The deployment TUI needs keyboard input to select profiles"
    echo ""
    echo "Please run this command directly in your terminal:"
    echo -e "  ${GREEN}wget https://privitera.github.io/public/deployment/deploy-wrapper.sh && bash deploy-wrapper.sh && rm deploy-wrapper.sh${NC}"
    exit 1
fi

# Cleanup happens automatically via trap