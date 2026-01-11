#!/bin/bash

set -euo pipefail

# Variables for internal script usage
CURRENT_DIR=$(pwd)
DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Detect architecture and set Homebrew prefix
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi
export HOMEBREW_PREFIX
export ARCH

# Updated Homebrew install URL
HOMEBREW_DOWNLOAD_URL=https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

cleanup() {
  cd "$CURRENT_DIR" &>/dev/null
}

source_bash_utils() {
  # shellcheck disable=SC1090
  # shellcheck disable=SC1091
  source "$DIRECTORY/bash_utils.sh"
}

install_rosetta() {
  # Install Rosetta 2 on Apple Silicon
  if [[ "$ARCH" == "arm64" ]]; then
    info "Checking for Rosetta 2..."
    if ! /usr/bin/pgrep -q oahd; then
      info "Installing Rosetta 2 for Intel compatibility..."
      sudo softwareupdate --install-rosetta --agree-to-license
      info "✓ Rosetta 2 installed"
    else
      info "✓ Rosetta 2 already installed"
    fi
  fi
}

install_ansible_dependencies() {
  info "Installing Ansible dependencies if necessary..."
  # Note: python is now python@3.13, not python or python@2
  local ansible_dependencies=(python@3.13 jq)

  for dependency in ${ansible_dependencies[*]}; do
    if ! brew list "$dependency" &>/dev/null; then
      brew install "$dependency" 2>&1 | tee -a "$LOG_FILE"
    else
      brew upgrade "$dependency" 2>&1 | tee -a "$LOG_FILE" || true
    fi
  done

  # Install Ansible via pip3
  if ! command -v ansible &>/dev/null; then
    info "Installing Ansible via pip3..."
    python3 -m pip install --user --upgrade --break-system-packages ansible 2>&1 | tee -a "$LOG_FILE"
  else
    info "Ansible already installed."
  fi

  # Ensure Ansible is in PATH - detect actual Python version
  PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  export PATH="$HOME/Library/Python/${PYTHON_VERSION}/bin:$PATH"
  
  # Add Python user bin to bash profile for persistent PATH
  if ! grep -q "Library/Python/${PYTHON_VERSION}/bin" ~/.bash_profile 2>/dev/null; then
    info "Adding Python user bin to ~/.bash_profile"
    echo "" >> ~/.bash_profile
    echo "# Python user packages" >> ~/.bash_profile
    echo "export PATH=\"\$HOME/Library/Python/${PYTHON_VERSION}/bin:\$PATH\"" >> ~/.bash_profile
  fi

  # Install Ansible Galaxy collections
  info "Installing Ansible Galaxy collections..."
  ansible-galaxy collection install community.general 2>&1 | tee -a "$LOG_FILE"
}

install_homebrew() {
  info "Checking for Homebrew, and installing if necessary"
  if ! command -v brew &>/dev/null; then
    info 'Installing homebrew...'
    /bin/bash -c "$(curl -fsSL $HOMEBREW_DOWNLOAD_URL)" 2>&1 | tee -a "$LOG_FILE"
    
    # Add Homebrew to PATH for this session
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    
    # Add to bash profile for future sessions
    if ! grep -q "brew shellenv" ~/.bash_profile 2>/dev/null; then
      echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> ~/.bash_profile
    fi
  else
    info 'Homebrew already installed.'
    # Ensure it's in PATH
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
  fi
}

install_xcode() {
  info "Checking for Xcode Command Line Tools, and installing if necessary"
  if ! xcode-select -p &>/dev/null; then
    info 'Installing Xcode Command Line Tools...'
    info 'This may take 10-20 minutes. Please wait...'
    
    # Try the interactive installer
    xcode-select --install 2>/dev/null || true
    
    # Wait for installation to complete
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
    
    info '✓ Command Line Tools installed successfully'
  else
    info "✓ Command Line Tools already installed at $(xcode-select -p)"
  fi
  
  # Accept license if needed
  sudo xcodebuild -license accept 2>/dev/null || true
}

run_ansible() {
  info "Running ansible to continue with local setup..."
  
  # Ensure Ansible is in PATH - detect actual Python version
  PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  export PATH="$HOME/Library/Python/${PYTHON_VERSION}/bin:$PATH"
  
  info "Using Python ${PYTHON_VERSION} - packages in ~/Library/Python/${PYTHON_VERSION}/bin"
  
  pushd "${DIRECTORY}/ansible" &>/dev/null
    ANSIBLE_CONFIG=ansible.cfg ANSIBLE_LOG_PATH=$LOG_FILE ansible-playbook playbooks/darwin_bootstrap.yml -v --ask-become-pass
  popd &>/dev/null
}

trap_signals() {
  trap "{ debug 'Running cleanup'; cleanup; }" EXIT
  trap "{ debug 'Running cleanup'; cleanup; fatal 'User interrupt detected. Exitting...'; }" SIGINT
  trap "{ debug 'Running cleanup'; cleanup; fatal 'There was an error'}" ERR
}

check_github_token() {
  # Temporarily disable error trap to avoid recursion on empty input
  trap - ERR

  if [[ -z "${GITHUB_API_TOKEN:-}" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  GitHub API Token Required"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This setup requires a GitHub Personal Access Token for SSH key setup."
    echo ""
    echo "To create one:"
    echo "  1. Visit: https://github.com/settings/tokens/new"
    echo "  2. Note: my-osx-setup token"
    echo "  3. Expiration: 90 days"
    echo "  4. Scopes: Check ONLY 'admin:public_key', user:email, read:user"
    echo "  5. Click 'Generate token'"
    echo ""
    echo "Opening GitHub in your browser..."
    open "https://github.com/settings/tokens/new?description=my-osx-setup&scopes=admin:public_key,user:email,read:user"
    echo "" echo -n "Paste your GitHub token here: "
    read -s GITHUB_API_TOKEN
    echo ""
    export GITHUB_API_TOKEN
    [[ -z "$GITHUB_API_TOKEN" ]] && fatal "No token provided. Cannot continue."
  fi

  # Re-enable error trap
  trap "{ debug 'Running cleanup'; cleanup; fatal 'There was an error'}" ERR
}

main() {
  trap_signals
  source_bash_utils
  
  # Show detected architecture
  if [[ "$ARCH" == "arm64" ]]; then
    info "Apple Silicon detected - using $HOMEBREW_PREFIX"
  else
    info "Intel detected - using $HOMEBREW_PREFIX"
  fi
  
  install_xcode
  install_rosetta
  install_homebrew
  install_ansible_dependencies
  check_github_token
  run_ansible
}

main
