#!/bin/bash

set -e

AUTHOR_USERNAME=washingtoneg
CONTENT_URL=https://gist.githubusercontent.com
FILE_URI=6dfc7440fab5d99dc09b762d6403001d/raw/b7f1dd0b3476c2cee0255a2287998fe57f30e862/bash_utils.sh
BASH_UTILS="$(mktemp /tmp/bash_util_XXXXX)" || exit 1
DIRECTORY=$(pwd)

cleanup() {
  rm "$BASH_UTILS"
}

get_bash_utils() {
  curl --silent "$CONTENT_URL/$AUTHOR_USERNAME/$FILE_URI" > $BASH_UTILS
  source $BASH_UTILS
}

install_homebrew() {
  # Check for Homebrew, install if we don't have it
  if test ! $(which brew); then
    info 'Installing homebrew...'
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" | stream_info
  else
    info 'Homebrew installed.'
  fi
}

main() {
  trap "{ cleanup; cd $DIRECTORY &>/dev/null; }" EXIT
  get_bash_utils
  install_homebrew
  brew install python | stream_info
  brew install ansible | stream_info
  cd ansible &>/dev/null
  exec ansible-playbook playbooks/darwin_bootstrap.yml -v
}

main

