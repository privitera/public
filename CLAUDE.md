# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a static website repository for Impulse Labs Public Pages, hosted via GitHub Pages. It contains landing pages for various deployment tools and projects. The repository is entirely static HTML/CSS/JavaScript with no build process required.

## Architecture and Structure

### Project Organization
- `index.html` - Main landing page with project overview
- `flasher/` - Battery Flasher deployment system with cyberpunk-themed UI
- `deployment/` - Additional deployment configurations  
- `stage1-setup.sh` - Universal system preparation script for GitHub authentication

### Key Components

**Deployment Pipeline:**
1. `stage1-setup.sh` - Prepares system with GitHub CLI and basic dependencies
2. `flasher/deploy-wrapper.sh` - Public wrapper that clones private repositories and runs deployment
3. `flasher/stage1-setup.sh` - Flasher-specific setup script

**Frontend Architecture:**
- Pure HTML/CSS/JavaScript (no frameworks)
- Cyberpunk/terminal aesthetic with advanced CSS animations
- Matrix rain effects, glitch text, animated grid backgrounds
- Interactive command copying functionality

### Deployment System Design

The repository implements a two-stage deployment pattern:
- **Stage 1 (Public):** Basic system setup and GitHub authentication
- **Stage 2 (Private):** Repository-specific deployment via authenticated private repos

This allows for secure deployment of proprietary tools while maintaining public accessibility for initial setup.

## Development Guidelines

### Styling Conventions
- Uses CSS custom properties (--neon-cyan, --neon-pink, etc.) for consistent theming
- Animations are performance-optimized using GPU acceleration
- Responsive design with clamp() for fluid typography
- Terminal/cyberpunk aesthetic maintained across all pages

### File Organization
- Each project gets its own subdirectory (e.g., `flasher/`)
- Deployment scripts are co-located with their landing pages
- All external dependencies loaded via CDN (Google Fonts)

### Security Considerations
- Public repository only contains setup scripts and landing pages
- Actual application code resides in private repositories
- Authentication handled through GitHub CLI in deployment scripts

## Common Tasks

Since this is a static site with no build process:
- **Editing:** Modify HTML/CSS/JavaScript files directly
- **Testing:** Open `index.html` in browser or use `python3 -m http.server`
- **Deployment:** Changes automatically deploy via GitHub Pages on push to main branch

## Script Execution

To test deployment scripts locally:
```bash
# Test stage1 setup
sudo bash stage1-setup.sh

# Test flasher deployment wrapper  
bash flasher/deploy-wrapper.sh
```

Note: Deployment scripts require GitHub authentication and may clone private repositories.