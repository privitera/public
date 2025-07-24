#!/bin/bash
# Stage 1 Setup Script - Universal Deployment Bootstrap
# Prepares system for Stage 2 whiptail-based deployment
set -e

# Script info
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="Universal Stage 1 Setup"

# Colors - Wong/Tol hybrid colorblind-safe palette (matching deployments-private)
COLOR_BLUE='\033[38;2;0;114;178m'        # #0072B2 - Primary blue
COLOR_ORANGE='\033[38;2;230;159;0m'      # #E69F00 - Warning/attention
COLOR_LIGHT_BLUE='\033[38;2;86;180;233m' # #56B4E9 - Info/secondary
COLOR_GREEN='\033[38;2;0;158;115m'       # #009E73 - Success
COLOR_VERMILLION='\033[38;2;213;94;0m'   # #D55E00 - Error/danger
COLOR_RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Symbols for better UX
SUCCESS='✓'
WARNING='⚠'
ERROR='✗'
INFO='ℹ'

echo -e "${BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
echo -e "${BOLD}${COLOR_BLUE}${SCRIPT_NAME} v${SCRIPT_VERSION}${COLOR_RESET}"
echo -e "${BOLD}${COLOR_BLUE}========================================${COLOR_RESET}"
echo ""
echo "This script prepares your system for the Stage 2 deployment TUI."
echo ""

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${COLOR_VERMILLION}${ERROR} This script must be run with sudo${COLOR_RESET}"
   echo "Please run: sudo bash $0"
   exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo -e "${COLOR_LIGHT_BLUE}${INFO} Detected OS:${COLOR_RESET} $NAME $VERSION"
fi

# Check Ubuntu version for compatibility
if [[ "$ID" == "ubuntu" ]]; then
    VERSION_ID_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
    if [[ "$VERSION_ID_MAJOR" -lt 20 ]]; then
        echo -e "${COLOR_ORANGE}${WARNING} Ubuntu version $VERSION_ID detected${COLOR_RESET}"
        echo "This deployment system is tested on Ubuntu 20.04+"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Update package lists
echo -e "\n${COLOR_ORANGE}Updating package lists...${COLOR_RESET}"
apt-get update -qq

# Install essential dependencies including whiptail
echo -e "\n${COLOR_ORANGE}Installing essential dependencies...${COLOR_RESET}"
PACKAGES=(
    curl
    git
    wget
    ca-certificates
    gnupg
    lsb-release
    whiptail      # For Stage 2 TUI
    jq            # For JSON parsing
    bc            # For calculations
)

# Check which packages need installation
TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    apt-get install -y "${TO_INSTALL[@]}"
    echo -e "${COLOR_GREEN}${SUCCESS} Installed: ${TO_INSTALL[*]}${COLOR_RESET}"
else
    echo -e "${COLOR_GREEN}${SUCCESS} All essential packages already installed${COLOR_RESET}"
fi

# Check if GitHub CLI is already installed
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n1 | cut -d' ' -f3)
    echo -e "\n${COLOR_GREEN}${SUCCESS} GitHub CLI already installed: v${GH_VERSION}${COLOR_RESET}"
else
    # Install GitHub CLI
    echo -e "\n${COLOR_ORANGE}Installing GitHub CLI...${COLOR_RESET}"
    
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    # Update and install gh
    apt-get update -qq
    apt-get install -y gh
    echo -e "${COLOR_GREEN}${SUCCESS} GitHub CLI installed${COLOR_RESET}"
fi


# Configure git to use GitHub CLI for authentication
echo -e "\n${COLOR_ORANGE}Configuring git authentication...${COLOR_RESET}"
git config --global credential.helper "!gh auth git-credential"

# Create deployment tracking directory
DEPLOY_DIR="/opt/deployment"
echo -e "\n${COLOR_ORANGE}Creating deployment directory...${COLOR_RESET}"
mkdir -p "$DEPLOY_DIR"

# Save deployment info with more details
cat > "$DEPLOY_DIR/.stage1-info" << EOF
STAGE1_VERSION=$SCRIPT_VERSION
STAGE1_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)
OS_NAME=$NAME
OS_VERSION=$VERSION_ID
ARCH=$(uname -m)
WHIPTAIL_VERSION=$(dpkg -l whiptail 2>/dev/null | grep "^ii" | awk '{print $3}')
GH_VERSION=$(gh --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo "unknown")
USER_HOME=/home/${SUDO_USER:-$USER}
EOF

# Test whiptail installation only if in proper terminal
echo -e "\n${COLOR_ORANGE}Verifying whiptail installation...${COLOR_RESET}"
if [ -t 0 ] && [ -t 1 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
    # Only test if we have a real terminal
    if TERM=xterm-256color whiptail --title "Test" --msgbox "Whiptail is working correctly!" 8 40 2>/dev/null; then
        echo -e "${COLOR_GREEN}${SUCCESS} Whiptail TUI verified${COLOR_RESET}"
    else
        echo -e "${COLOR_ORANGE}${WARNING} Whiptail test failed${COLOR_RESET}"
    fi
else
    # Just verify it's installed
    if command -v whiptail &> /dev/null; then
        echo -e "${COLOR_GREEN}${SUCCESS} Whiptail installed (test skipped - no interactive terminal)${COLOR_RESET}"
    else
        echo -e "${COLOR_VERMILLION}${ERROR} Whiptail installation failed${COLOR_RESET}"
        exit 1
    fi
fi

echo -e "\n${COLOR_GREEN}========================================${COLOR_RESET}"
echo -e "${COLOR_GREEN}${SUCCESS} Stage 1 Setup Complete!${COLOR_RESET}"
echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
echo ""

# Store the actual username for later
ACTUAL_USER=${SUDO_USER:-$USER}

# Check if already authenticated
if sudo -u "$ACTUAL_USER" gh auth status &>/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}${SUCCESS} GitHub CLI already authenticated${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_ORANGE}Ready to run Stage 2 deployment:${COLOR_RESET}"
    echo -e "   ${COLOR_BLUE}wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash${COLOR_RESET}"
else
    echo -e "${COLOR_ORANGE}GitHub authentication required${COLOR_RESET}"
    echo ""
    echo "Would you like to authenticate with GitHub now? [Y/n]"
    if [ -t 0 ]; then
        read -r response < /dev/tty
    else
        # Can't read when piped, default to no
        response="n"
        echo -e "${DIM}(Skipping interactive auth - run 'gh auth login' manually)${COLOR_RESET}"
    fi
    response=${response:-Y}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${COLOR_LIGHT_BLUE}${INFO} Starting GitHub authentication...${COLOR_RESET}"
        echo "   • Choose: GitHub.com"
        echo "   • Choose: SSH (recommended)"
        echo "   • Generate new SSH key: Yes"
        echo "   • Passphrase: Optional (press Enter to skip)"
        echo "   • Title: $(hostname) (or custom name)"
        echo ""
        echo -e "${DIM}Note: Browser will not open in SSH sessions. Copy the provided URL manually.${COLOR_RESET}"
        echo ""
        
        # Run gh auth login as the actual user
        # Set BROWSER=echo to prevent browser launch attempts in CLI
        sudo -u "$ACTUAL_USER" BROWSER=echo gh auth login
        
        if sudo -u "$ACTUAL_USER" gh auth status &>/dev/null 2>&1; then
            echo -e "\n${COLOR_GREEN}${SUCCESS} Authentication successful!${COLOR_RESET}"
        else
            echo -e "\n${COLOR_VERMILLION}${ERROR} Authentication failed or cancelled${COLOR_RESET}"
            echo ""
            echo "To authenticate later, run:"
            echo -e "   ${COLOR_BLUE}gh auth login${COLOR_RESET}"
            echo ""
            echo "Then run Stage 2 deployment:"
            echo -e "   ${COLOR_BLUE}wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash${COLOR_RESET}"
        fi
    else
        echo ""
        echo -e "${COLOR_ORANGE}To authenticate later, run:${COLOR_RESET}"
        echo -e "   ${COLOR_BLUE}gh auth login${COLOR_RESET}"
        echo ""
        echo "Then run Stage 2 deployment:"
        echo -e "   ${COLOR_BLUE}wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash${COLOR_RESET}"
    fi
fi

echo ""
echo -e "${COLOR_LIGHT_BLUE}${INFO} Available deployment profiles:${COLOR_RESET}"
echo "   • The Works™ - Full Ubuntu deployment"
echo "   • BareBones - Lightweight essentials"
echo "   • Impulse Dev - Corporate dev environment"
echo "   • FLASH_BATT - RPi battery flasher"
echo "   • BATTERY_TESTER - RPi battery testing"
echo ""
echo -e "${DIM}System ready | Whiptail TUI enabled${COLOR_RESET}"
echo ""

# Offer to run Stage 2 if authenticated
if sudo -u "$ACTUAL_USER" gh auth status &>/dev/null 2>&1; then
    # Check if we can read from terminal (not piped)
    if [ -t 0 ]; then
        echo -e "${COLOR_ORANGE}Would you like to proceed with Stage 2 deployment now? [Y/n]${COLOR_RESET}"
        read -r proceed_response < /dev/tty
        proceed_response=${proceed_response:-Y}
        
        if [[ "$proceed_response" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${COLOR_LIGHT_BLUE}${INFO} Launching Stage 2 deployment...${COLOR_RESET}"
            echo ""
            # Run Stage 2 as the actual user
            sudo -u "$ACTUAL_USER" bash -c 'wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash'
        else
            echo ""
            echo -e "${COLOR_ORANGE}To run Stage 2 deployment later:${COLOR_RESET}"
            echo -e "   ${COLOR_BLUE}wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash${COLOR_RESET}"
        fi
    else
        # Can't read input when piped - automatically proceed if authenticated
        echo ""
        echo -e "${COLOR_LIGHT_BLUE}${INFO} Automatically proceeding to Stage 2...${COLOR_RESET}"
        echo -e "${DIM}(Already authenticated and running non-interactively)${COLOR_RESET}"
        echo ""
        sleep 2
        # Run Stage 2 as the actual user
        sudo -u "$ACTUAL_USER" bash -c 'wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash'
    fi
fi