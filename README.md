# Impulse Labs Public Pages

This repository hosts public landing pages and deployment scripts for various Impulse Labs projects.

## Projects

### [Linux System Deployment](deployment/)
Universal deployment system for Ubuntu workstations and servers.

**[→ Open Deployment Page](https://privitera.github.io/public/deployment/)**

Two-stage deployment system with interactive TUI for selecting from multiple profiles:
- **The Works™** - Full-featured Ubuntu workstation with modern CLI tools
- **BareBones** - Lightweight setup with essentials only
- **Impulse Dev** - Corporate development environment
- **Custom Profiles** - RPi battery flasher, battery tester, and more

### [Battery Flasher](flasher/)
Automated battery firmware flashing system for Raspberry Pi.

**[→ Open Deployment Page](https://privitera.github.io/public/flasher/)**

One-click deployment system that configures CAN interfaces, builds the flashbatt tool, and sets up all required services.

## Quick Start

### Linux System Deployment

```bash
# Stage 1: Install prerequisites and authenticate
wget -qO- https://privitera.github.io/public/stage1-setup.sh | sudo bash

# Stage 2: Run deployment (after authentication)
wget -qO- https://privitera.github.io/public/deployment/deploy-wrapper.sh | bash
```

### Battery Flasher Deployment

```bash
# One-command deployment
curl -sL https://privitera.github.io/public/flasher/ | bash
```

## About

This repository contains only the public-facing deployment pages and bootstrap scripts. The actual source code and deployment configurations are maintained in private repositories for security.

## Contributing

For access to source code or to contribute, please contact the project maintainers.

## License

© 2025 Impulse Labs - Internal Use Only