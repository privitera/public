#!/bin/bash
# Stage 2 Deployment Wrapper - Launches private deployment TUI
# This script clones the private repository and runs the whiptail-based deploy.sh
set -e

# Colors - Wong/Tol hybrid colorblind-safe palette (matching deployments-private)
COLOR_BLUE='\033[38;2;0;114;178m'        # #0072B2 - Primary blue
COLOR_ORANGE='\033[38;2;230;159;0m'      # #E69F00 - Warning/attention
COLOR_LIGHT_BLUE='\033[38;2;86;180;233m' # #56B4E9 - Info/secondary
COLOR_GREEN='\033[38;2;0;158;115m'       # #009E73 - Success
COLOR_VERMILLION='\033[38;2;213;94;0m'   # #D55E00 - Error/danger
COLOR_GREY='\033[38;2;187;187;187m'     # #BBBBBB - Neutral
COLOR_RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Symbols (ASCII for compatibility)
SUCCESS='[OK]'
WARNING='[!]'
ERROR='[X]'
INFO='[i]'

echo -e "${BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
echo -e "${BOLD}${COLOR_BLUE}Stage 2 Deployment System${COLOR_RESET}"
echo -e "${BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
echo ""

# Check if whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo -e "${COLOR_VERMILLION}${ERROR} Error: whiptail is not installed${COLOR_RESET}"
    echo "Please run Stage 1 setup first:"
    echo "  wget -qO- https://privitera.github.io/public/stage1-setup.sh | sudo bash"
    exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${COLOR_VERMILLION}${ERROR} Error: GitHub CLI (gh) is not installed${COLOR_RESET}"
    echo "Please run Stage 1 setup first:"
    echo "  wget -qO- https://privitera.github.io/public/stage1-setup.sh | sudo bash"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${COLOR_VERMILLION}${ERROR} Error: Not authenticated with GitHub${COLOR_RESET}"
    echo "Please authenticate first:"
    echo "  gh auth login"
    echo ""
    echo "Choose: GitHub.com → SSH → Generate new SSH key"
    exit 1
fi

# Get GitHub username
GITHUB_USER=$(gh api user -q .login 2>/dev/null || echo "unknown")
echo -e "${COLOR_LIGHT_BLUE}${INFO} GitHub user:${COLOR_RESET} $GITHUB_USER"

# Check if running in an interactive terminal
# When run via Stage 1's auto-launch, we might not have stdin but we do have stdout/stderr
if [ ! -t 1 ] && [ ! -t 2 ]; then
    echo -e "${COLOR_VERMILLION}${ERROR} This script requires an interactive terminal${COLOR_RESET}"
    echo "The deployment TUI needs keyboard input to select profiles."
    echo ""
    echo "Please run this command directly in your terminal:"
    echo -e "  ${COLOR_BLUE}wget https://privitera.github.io/public/deployment/deploy-wrapper.sh && bash deploy-wrapper.sh && rm deploy-wrapper.sh${COLOR_RESET}"
    exit 1
fi

# Set up cleanup trap
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo -e "\n${COLOR_ORANGE}Cleaning up temporary files...${COLOR_RESET}"
        rm -rf "$TEMP_DIR"
    fi
}

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap cleanup EXIT INT TERM

echo -e "${COLOR_ORANGE}Cloning private deployment repository...${COLOR_RESET}"
cd "$TEMP_DIR"

# Function to show progress
show_progress() {
    local progress=$1
    local total=$2
    local width=50
    local percentage=$((progress * 100 / total))
    local filled=$((width * progress / total))
    
    # Use simple ASCII characters for compatibility
    printf "\r${COLOR_BLUE}["
    
    # Filled portion with simple hashes
    local i
    for ((i=0; i<filled; i++)); do
        printf "#"
    done
    
    # Empty portion with dots
    printf "%$((width - filled))s" | tr ' ' '.'
    
    printf "]${COLOR_RESET} ${COLOR_GREEN}%3d%%${COLOR_RESET}" $percentage
}

# Clone the private deployments repository
REPO_NAME="deployments-private"
echo -e "${COLOR_GREY}Repository: github.com:${GITHUB_USER}/${REPO_NAME}.git${COLOR_RESET}"

# First, check if the user has access to the repository
echo -e "${COLOR_ORANGE}Checking repository access...${COLOR_RESET}"
if ! gh repo view "${GITHUB_USER}/${REPO_NAME}" &>/dev/null; then
    # Try the original repository
    if ! gh repo view "privitera/${REPO_NAME}" &>/dev/null; then
        echo -e "\n${COLOR_VERMILLION}${ERROR} Repository not found or access denied${COLOR_RESET}"
        echo ""
        echo "Please ensure you have:"
        echo "1. Forked or been granted access to: https://github.com/privitera/deployments-private"
        echo "2. Made sure the repository is set to private"
        echo "3. Authenticated with the correct GitHub account"
        echo ""
        echo -e "${COLOR_ORANGE}To create your own fork:${COLOR_RESET}"
        echo "  gh repo fork privitera/deployments-private --private"
        exit 1
    else
        # Use the original repository
        REPO_OWNER="privitera"
        echo -e "${COLOR_GREEN}${SUCCESS} Using original repository${COLOR_RESET}"
    fi
else
    REPO_OWNER="$GITHUB_USER"
    echo -e "${COLOR_GREEN}${SUCCESS} Repository access confirmed${COLOR_RESET}"
fi

# Clone with progress output
if ! git clone --progress "git@github.com:${REPO_OWNER}/${REPO_NAME}.git" 2>&1 | while IFS= read -r line; do
    if [[ "$line" =~ Receiving\ objects:\ +([0-9]+)%\ \(([0-9]+)/([0-9]+)\) ]]; then
        current="${BASH_REMATCH[2]}"
        total="${BASH_REMATCH[3]}"
        show_progress $current $total
    elif [[ "$line" =~ "Cloning into" ]]; then
        echo -e "${COLOR_GREY}$line${COLOR_RESET}"
    elif [[ "$line" =~ "error:" ]] || [[ "$line" =~ "fatal:" ]]; then
        echo -e "\n${COLOR_VERMILLION}$line${COLOR_RESET}"
        exit 1
    fi
done; then
    echo -e "\n${COLOR_VERMILLION}${ERROR} Failed to clone repository${COLOR_RESET}"
    echo "Please check your GitHub authentication and repository access"
    exit 1
fi

echo -e "\n${COLOR_GREEN}${SUCCESS} Repository cloned successfully${COLOR_RESET}"

# Check if deploy.sh exists
if [ ! -f "${REPO_NAME}/deploy.sh" ]; then
    echo -e "${COLOR_VERMILLION}${ERROR} deploy.sh not found in repository${COLOR_RESET}"
    echo "Expected location: ${REPO_NAME}/deploy.sh"
    echo ""
    echo "The repository structure may have changed. Please check:"
    echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}"
    exit 1
fi

# Make deploy.sh executable
chmod +x "${REPO_NAME}/deploy.sh"

# Change to repository directory
cd "${REPO_NAME}"

# Show what's about to happen
echo -e "\n${COLOR_ORANGE}Launching deployment TUI...${COLOR_RESET}"
echo -e "${COLOR_GREY}You will be able to select from these profiles:${COLOR_RESET}"
echo ""
echo "  - The Works(TM) - Full Ubuntu deployment (everything)"
echo "  - BareBones - Lightweight Ubuntu with essentials"
echo "  - Impulse Dev - Corporate dev with sw repo"
echo "  - FLASH_BATT - RPi battery flasher"
echo "  - BATTERY_TESTER - RPi battery testing & CAN"
echo "  - Custom - Manual configuration"
echo ""
echo -e "${DIM}Use arrow keys to navigate, Enter to select${COLOR_RESET}"
echo ""

# Small pause to let user read the information
sleep 2

# Execute the deployment script
./deploy.sh

# Check exit status
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\n${COLOR_GREEN}${SUCCESS} Deployment completed successfully!${COLOR_RESET}"
    echo -e "${DIM}Temporary files will be cleaned up automatically${COLOR_RESET}"
else
    echo -e "\n${COLOR_VERMILLION}${ERROR} Deployment failed with exit code: $EXIT_CODE${COLOR_RESET}"
    echo "Check the logs for more information"
fi

# Cleanup happens automatically via trap