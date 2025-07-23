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

# Function to show progress bar
show_progress() {
    local progress=$1
    local total=$2
    local width=50
    local percentage=$((progress * 100 / total))
    local filled=$((width * progress / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((width - filled))s" | tr ' ' '▒'
    printf "] %3d%%" $percentage
}

# Clone with progress output
echo -e "${GREY}Repository: github.com:privitera/flasher.git${NC}"
if ! git clone --progress git@github.com:privitera/flasher.git 2>&1 | while IFS= read -r line; do
    # Parse git progress output
    if [[ "$line" =~ Receiving\ objects:\ +([0-9]+)%\ \(([0-9]+)/([0-9]+)\) ]]; then
        percent="${BASH_REMATCH[1]}"
        current="${BASH_REMATCH[2]}"
        total="${BASH_REMATCH[3]}"
        show_progress $current $total
    elif [[ "$line" =~ Resolving\ deltas:\ +([0-9]+)%\ \(([0-9]+)/([0-9]+)\) ]]; then
        percent="${BASH_REMATCH[1]}"
        current="${BASH_REMATCH[2]}"
        total="${BASH_REMATCH[3]}"
        printf "\r${GREEN}Resolving deltas...${NC} "
        show_progress $current $total
    elif [[ "$line" =~ "Cloning into" ]]; then
        echo -e "${GREY}$line${NC}"
    elif [[ "$line" =~ "Submodule" ]] && [[ ! "$line" =~ "registered" ]]; then
        # Don't show submodule registration messages
        :
    elif [[ "$line" =~ "error:" ]] || [[ "$line" =~ "fatal:" ]]; then
        echo -e "\n${RED}$line${NC}"
        exit 1
    fi
done; then
    echo -e "\n${RED}Error: Failed to clone repository${NC}"
    echo "Please check your GitHub authentication and try again"
    exit 1
fi

echo -e "\n${GREEN}✓ Repository cloned successfully${NC}"

# Check if deploy.sh exists
if [ ! -f "flasher/deploy.sh" ]; then
    echo -e "${RED}Error: deploy.sh not found in repository${NC}"
    exit 1
fi

# Make it executable
chmod +x flasher/deploy.sh

# Initialize submodules if present
if [ -f .gitmodules ]; then
    echo -e "${YELLOW}Initializing submodules...${NC}"
    
    # Function to show spinner
    spinner() {
        local pid=$1
        local delay=0.1
        local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local msg="${2:-Processing...}"
        while [ -d /proc/$pid ]; do
            local temp=${spinstr#?}
            printf "\r${YELLOW}%c${NC} %s" "$spinstr" "$msg"
            spinstr=$temp${spinstr%"$temp"}
            sleep $delay
        done
        printf "\r${GREEN}✓${NC} %s\n" "$msg"
    }
    
    # Run git submodule update with progress
    git submodule update --init --recursive --progress 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ "Cloning into" ]]; then
            echo -e "${GREY}$line${NC}"
        elif [[ "$line" =~ Receiving\ objects:\ +([0-9]+)%\ \(([0-9]+)/([0-9]+)\) ]]; then
            percent="${BASH_REMATCH[1]}"
            current="${BASH_REMATCH[2]}"
            total="${BASH_REMATCH[3]}"
            show_progress $current $total
        elif [[ "$line" =~ "Submodule path" ]]; then
            echo -e "\n${CYAN}$line${NC}"
        fi
    done
    echo -e "\n${GREEN}✓ Submodules initialized${NC}"
fi

# Create system directories with proper permissions before running deploy
echo -e "${YELLOW}Creating system directories...${NC}"
sudo mkdir -p /var/lib/battery-flasher
sudo mkdir -p /var/log/battery-flasher
# Ensure directories are writable by both root and user
sudo chmod 777 /var/lib/battery-flasher /var/log/battery-flasher
# Remove any existing config that might have wrong permissions
sudo rm -f /var/lib/battery-flasher/hardware_config.json

# Execute the deployment script
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