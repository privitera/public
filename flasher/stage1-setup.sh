#!/bin/bash

# Stage 1 Setup Script - Prepares Pi for private repo access (Headless version)
# This script is hosted in the public repo and sets up GitHub authentication

set -e

# Colors for output - Paul Tol's colorblind-safe palette
GREEN='\033[38;2;0;158;115m'   # Success messages
YELLOW='\033[38;2;238;119;51m' # Warnings and prompts
RED='\033[38;2;204;51;17m'     # Errors
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Battery Flasher - Stage 1 Setup (Headless)${NC}"
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
apt-get update
apt-get install -y gh

# Set up headless browser configuration
echo -e "\n${YELLOW}Setting up headless configuration...${NC}"
# Create a profile script that sets BROWSER=echo for all users
cat > /etc/profile.d/headless-browser.sh << 'EOF'
# Prevent browser launch attempts on headless system
export BROWSER=echo
EOF
chmod +x /etc/profile.d/headless-browser.sh

# Also set it in the current sudo user's bashrc
SUDO_USER_HOME=$(getent passwd ${SUDO_USER} | cut -d: -f6)
if [ -f "${SUDO_USER_HOME}/.bashrc" ]; then
    echo "" >> "${SUDO_USER_HOME}/.bashrc"
    echo "# Prevent browser launch on headless system" >> "${SUDO_USER_HOME}/.bashrc"
    echo "export BROWSER=echo" >> "${SUDO_USER_HOME}/.bashrc"
fi

# Also create a wrapper for gh to ensure BROWSER is set
cat > /usr/local/bin/gh-headless << 'EOF'
#!/bin/bash
# Wrapper for gh that ensures BROWSER=echo
export BROWSER=echo
exec /usr/bin/gh "$@"
EOF
chmod +x /usr/local/bin/gh-headless

echo -e "${GREEN}✓ Stage 1 setup complete!${NC}"
echo ""

# Check if we need to authenticate with GitHub
if [ -n "${SUDO_USER}" ]; then
    # Running with sudo, check auth status as the regular user
    if ! sudo -u ${SUDO_USER} gh auth status &> /dev/null; then
        echo -e "${YELLOW}GitHub authentication required${NC}"
        echo ""
        echo "Starting GitHub authentication..."
        echo "- Choose: GitHub.com"
        echo "- Choose: SSH"
        echo "- Choose: Generate new SSH key (or use existing)"
        echo "- Choose: Login with a web browser"
        echo ""
        echo "When prompted, copy the one-time code and open this URL on another device:"
        echo "https://github.com/login/device"
        echo ""
        
        # Run gh auth login as the regular user with BROWSER=echo
        sudo -u ${SUDO_USER} env BROWSER=echo gh auth login
        
        if sudo -u ${SUDO_USER} gh auth status &> /dev/null; then
            echo ""
            echo -e "${GREEN}✓ GitHub authentication successful!${NC}"
        else
            echo ""
            echo -e "${RED}GitHub authentication failed or was cancelled${NC}"
            echo "You can retry with: gh-headless auth login"
        fi
    else
        echo -e "${GREEN}✓ Already authenticated with GitHub${NC}"
    fi
else
    # Not running with sudo, check directly
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}Please authenticate with GitHub:${NC}"
        echo -e "   ${GREEN}gh-headless auth login${NC}"
    else
        echo -e "${GREEN}✓ Already authenticated with GitHub${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}Next step - Run the deployment:${NC}"
echo ""
echo -e "${GREEN}wget --no-cookies --no-cache https://privitera.github.io/public/flasher/deploy-wrapper.sh -O deploy-wrapper.sh && bash deploy-wrapper.sh && rm deploy-wrapper.sh${NC}"
echo ""
echo "The deployment will:"
echo "• Clone the private repository"
echo "• Launch interactive hardware configurator"
echo "• Build flashbatt from source"
echo "• Configure all services"
echo "• Set up the complete system"
echo ""