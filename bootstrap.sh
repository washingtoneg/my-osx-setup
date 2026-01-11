#!/usr/bin/env bash
#
# bootstrap.sh - Minimal pre-setup to break the SSH key chicken-and-egg problem
#
# This script:
# 1. Downloads the my-osx-setup repo WITHOUT needing SSH keys (uses HTTPS)
# 2. Runs the setup script
# 3. After setup completes, guides you through SSH key setup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/washingtoneg/my-osx-setup/master/bootstrap.sh | bash
#
# Or download and inspect first:
#   curl -fsSL https://raw.githubusercontent.com/washingtoneg/my-osx-setup/master/bootstrap.sh > bootstrap.sh
#   chmod +x bootstrap.sh
#   ./bootstrap.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  my-osx-setup Bootstrap (Apple Silicon Compatible)"
echo "  Breaking the SSH key chicken-and-egg problem"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if we're on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo -e "${RED}✗ Error: This script is for macOS only${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Running on macOS $(sw_vers -productVersion)"
echo -e "${BLUE}ℹ${NC} Architecture: $(uname -m)"
echo ""

# Create temporary directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

cd "$TMP_DIR"
echo "Working in temporary directory: $TMP_DIR"
echo ""

# Clone the repository using HTTPS (no SSH key needed!)
echo "Downloading my-osx-setup repository..."
echo -e "${YELLOW}Using HTTPS (no SSH key required)${NC}"
echo ""

if git --version &>/dev/null; then
  # Git is available, use clone
  git clone https://github.com/washingtoneg/my-osx-setup.git
  cd my-osx-setup
else
  # Git not available yet, use curl to download
  echo "Git not found, downloading as ZIP..."
  curl -fsSL https://github.com/washingtoneg/my-osx-setup/archive/refs/heads/master.zip -o repo.zip
  
  # Check if unzip is available
  if command -v unzip &>/dev/null; then
    unzip -q repo.zip
    cd my-osx-setup-master
  else
    echo -e "${RED}✗ Error: Neither git nor unzip is available${NC}"
    echo "Please install Xcode Command Line Tools first:"
    echo "  xcode-select --install"
    exit 1
  fi
fi

echo -e "${GREEN}✓${NC} Repository downloaded"
echo ""

# Show user what's about to happen
cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ready to run setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This will:
  • Install Xcode Command Line Tools
  • Install Rosetta 2 (Apple Silicon only)
  • Install Homebrew at the correct path for your architecture
  • Install Python 3.12 and Ansible
  • Provision your Mac with all configured packages and apps

⚠️  IMPORTANT:
  • You will be prompted for your password (sudo) multiple times
  • This is interactive - do not walk away
  • Installation takes 30-60 minutes
  • Your Mac should be plugged into power

Press ENTER to continue or Ctrl+C to cancel...
EOF
read -r

echo ""
echo "Running setup.sh..."
echo ""

# Make setup.sh executable
chmod +x setup.sh

# Run the setup script
./setup.sh

SETUP_EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $SETUP_EXIT_CODE -eq 0 ]]; then
  echo -e "  ${GREEN}✓ Setup Complete!${NC}"
else
  echo -e "  ${RED}✗ Setup encountered errors${NC}"
  echo "  Check the logs for details"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $SETUP_EXIT_CODE -eq 0 ]]; then
  echo "Next steps:"
  echo ""
  echo "1. Generate SSH key (if you don't have one):"
  echo -e "   ${BLUE}ssh-keygen -t ed25519 -C 'your_email@example.com'${NC}"
  echo ""
  echo "2. Add SSH key to GitHub:"
  echo -e "   ${BLUE}cat ~/.ssh/id_ed25519.pub | pbcopy${NC}"
  echo "   Then paste at: https://github.com/settings/ssh/new"
  echo ""
  echo "3. Test SSH connection:"
  echo -e "   ${BLUE}ssh -T git@github.com${NC}"
  echo ""
  echo "4. Now you can clone repos with SSH!"
  echo -e "   ${BLUE}git clone git@github.com:washingtoneg/dotfiles.git${NC}"
  echo ""
fi

echo "Temporary files cleaned up automatically."
echo ""
