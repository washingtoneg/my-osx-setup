#!/bin/bash

set -euo pipefail

# Variables for internal script usage
CURRENT_DIR=$(pwd)
DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOMEBREW_DOWNLOAD_URL=https://raw.githubusercontent.com/Homebrew/install/master/install

cleanup() {
  cd "$CURRENT_DIR" &>/dev/null
}

source_bash_utils() {
  # shellcheck disable=SC1090
  # shellcheck disable=SC1091
  source "$DIRECTORY/bash_utils.sh"
}

install_ansible_dependencies() {
  info "Installing Ansible dependencies if necessary..."
  local ansible_dependencies=(python ansible jq)

  for dependency in  ${ansible_dependencies[*]}; do
    brew install "$dependency" 2>&1 | tee -a "$LOG_FILE" || brew upgrade "$dependency" 2>&1 | tee -a "$LOG_FILE"
  done
}

install_homebrew() {
  info "Checking for Homebrew, and installing if necessary"
  if test ! "$(command -v brew &>/dev/null)"; then
    info 'Installing homebrew...'
     ruby -e "$(curl -fsSL $HOMEBREW_DOWNLOAD_URL)" 2>&1 | tee -a "$LOG_FILE"
  else
    info 'Homebrew installed.'
  fi
}

install_xcode() {
  info "Checking for xcode, and installing if necessary"
  if ! [[ -d /Library/Developer/CommandLineTools/Library/ ]]; then
    info 'Installing xcode...'
    xcode-select --install
    while [ ! -d /Library/Developer/CommandLineTools/Library/ ] ;
    do
      sleep 2
    done
  else
    info 'Xcode already installed.'
  fi
}

run_ansible() {
  info "Running ansible to continue with local setup..."
  pushd "${DIRECTORY}/ansible" &>/dev/null
    ANSIBLE_LOG_PATH=$LOG_FILE ansible-playbook playbooks/darwin_bootstrap.yml -v --ask-become-pass
  popd
}

trap_signals() {
  trap "{ debug 'Running cleanup'; cleanup; }" EXIT
  trap "{ debug 'Running cleanup'; cleanup; fatal 'User interrupt detected. Exitting...'; }" SIGINT
  trap "{ debug 'Running cleanup'; cleanup; fatal 'There was an error'}" ERR
}

main() {
  trap_signals
  source_bash_utils
  install_xcode
  install_homebrew
  install_ansible_dependencies
  run_ansible
}

main
