#!/bin/bash

set -eo pipefail

readonly NAME_OF_CALLING_SCRIPT=$(basename "$0")

# Variables for internal script usage
AUTHOR_USERNAME=washingtoneg
BASH_UTILS_URL="https://raw.githubusercontent.com/${AUTHOR_USERNAME}/my-osx-setup/master/bash_utils.sh"
DIRECTORY=$(pwd)
GITHUB_API_URL=https://api.github.com
GITHUB_SSH_KEYS=''
HOMEBREW_DOWNLOAD_URL=https://raw.githubusercontent.com/Homebrew/install/master/install
LOCAL_BASH_UTILS="$(mktemp /tmp/bash_util_XXXXX)" || exit 1
SCRIPT_NAME=bash_utils.sh
SSH_CONFIG="$(mktemp /tmp/ssh_config_XXXXX)" || exit 1

# User-defined variables (set by environment variables)
COMPUTER_ALIAS=${COMPUTER_ALIAS:-unset}
GITHUB_API_TOKEN=${GITHUB_API_TOKEN:-unset}
GITHUB_EMAIL=${GITHUB_EMAIL:-unset}
GITHUB_USERNAME=${GITHUB_USERNAME:-unset}
SCRATCH_PATH=${SCRATCH_PATH:-unset}
SSH_KEY_EMAIL=${SSH_KEY_EMAIL:-unset}
SSH_KEY_FILE=${SSH_KEY_FILE:-~/.ssh/id_rsa_github}
SSH_KEY_PASSWORD=${SSH_KEY_PASSWORD:-unset}
WORKSPACE_PATH=${WORKSPACE_PATH:-unset}

add_ssh_key_to_github() {
  local data="$(cat << EOF
{ "scopes":
  [ "admin:public_key", "admin:gpg_key", "gist", "notifications", "repo", "user" ],
  "title": "$SSH_KEY_TITLE",
  "key": "$(local_ssh_key_content)"
}
EOF
)"

  info "Adding $SSH_KEY_TITLE SSH key to GitHub"
  github_api POST 'user/keys' "$data" | stream_warn
}

check_github_api_token() {
  if [[ "$GITHUB_API_TOKEN" == 'unset' ]]; then
    fatal 'GITHUB_API_TOKEN environment variable is not set.'
  fi
}

check_ssh_key_exists_locally() {
  local title=''
  local key=''

  if [[ -f $SSH_KEY_FILE ]]; then
    info "SSH_KEY_FILE already exists at $SSH_KEY_FILE"
    check_ssh_key_exists_in_github
  else
    warn "SSH_KEY_FILE does not exist."
    create_ssh_key
  fi
}

check_ssh_key_exists_in_github() {
  info 'Checking GitHub for existing SSH keys...'
  GITHUB_SSH_KEYS=$(github_api GET 'user/keys')
  debug "Existing keys: $(echo $GITHUB_SSH_KEYS)"

  if ! [[ $(echo "$GITHUB_SSH_KEYS" | grep "$SSH_KEY_TITLE") ]]; then
    info "No SSH keys exist in GitHub for $GITHUB_USERNAME with the title $SSH_KEY_TITLE"
    add_ssh_key_to_github
  else
    compare_ssh_keys
  fi
}

cleanup() {
  rm "$LOCAL_BASH_UTILS"
  rm "$SSH_CONFIG"
  cd $DIRECTORY &>/dev/null
}

clone_repos_from_github() {
  local repos=(dotfiles my-osx-setup)

  info "Cloning git repos to $WORKSPACE_PATH if they don't exist..."
  for repo in ${repos[*]}; do
  local repo_path="${WORKSPACE_PATH}/${repo}"

    if ! [[ -d "$repo_path" ]]; then
      warn "Cloning the $repo repo to ${repo_path}..."
      git clone "https://github.com/${AUTHOR_USERNAME}/${repo}.git" $repo_path | stream_warn
      pushd $repo_path &>/dev/null
        warn "Setting the origin remote URL in $repo_path to use th git protocol"
        git remote set-url origin "git@github.com:${GITHUB_USERNAME}/${repo}.git"
      popd &>/dev/null
    fi
  done
}

compare_ssh_keys() {
  local key_match=''

  info "Comparing $SSH_KEY_FILE contents with $SSH_KEY_TITLE contents in GitHub..."
  debug "Local SSH Key content: $(local_ssh_key_content)"

  key_match=$(echo "$GITHUB_SSH_KEYS" | grep "$(local_ssh_key_content)" || true)
  debug "Matching $SSH_KEY_FILE content with keys in GitHub: $key_match"

  if ! [[ -z "$key_match" ]]; then
    info "$SSH_KEY_FILE contents match SSH key with id=$id in GitHub"
  else
    info "$SSH_KEY_FILE contents do not match $SSH_KEY_TITLE in GitHub"
    check_if_label_used_for_different_key

    add_ssh_key_to_github
  fi
}

check_if_label_used_for_different_key() {
  info "Checking to see if an SSH key with label $SSH_KEY_TITLE exists in GitHub..."
  id=$(parse_github_ssh_key_json "$GITHUB_SSH_KEYS" "$SSH_KEY_TITLE")
  debug "GitHub SSH key id for key matching label $SSH_KEY_TITLE): $id"

  if ! [[ -z "$id" ]]; then
    delete_ssh_key_from_github $id
  fi
}

create_ssh_config_file() {
  debug "Creating SSH config file"
  cat <<EOF > $SSH_CONFIG
Host            remote github.com
IdentityFile    $SSH_KEY_FILE
User            git
StrictHostKeyChecking no
EOF
}

create_ssh_key() {
  if [[ "$SSH_KEY_EMAIL" == 'unset' ]]; then
    select_prompt ssh_key_email
  else
    info "SSH_KEY_EMAIL set to: $SSH_KEY_EMAIL from environment."
  fi

  info "Generating SSH key for $SSH_KEY_EMAIL at ${SSH_KEY_FILE}..."
  select_prompt ssh_key_password

  # Creates a new SSH key, using the provided email as a label
  # set the password, file name, and overwrite if necessary
  echo -e 'y\n' | \
  ssh-keygen -q -t rsa -b 4096 \
    -C "$SSH_KEY_EMAIL" \
    -N "$SSH_KEY_PASSWORD" \
    -f "$SSH_KEY_FILE" | stream_warn

  debug "Local SSH Key content: $(local_ssh_key_content)"
  compare_ssh_keys
}

create_user_paths() {
  info "Creating \$scratch and \$work directories if they don't exist..."
  if ! [[ -d "$WORKSPACE_PATH" ]]; then
    warn "WORKSPACE_PATH $WORKSPACE_PATH does not exist. Creating directory..."
    debug $(mkdir "$WORKSPACE_PATH")
  fi

  if ! [[ -d "$SCRATCH_PATH" ]]; then
    warn "SCRATCH_PATH $SCRATCH_PATH does not exist. Creating directory..."
    debug $(mkdir "$SCRATCH_PATH")
  fi
}

delete_ssh_key_from_github() {
  warn "Deleting $SSH_KEY_TITLE in GitHub"
  local id=$1
  github_api DELETE "user/keys/$id" | stream_warn
}

get_bash_utils() {
  curl --silent "$BASH_UTILS_URL" > $LOCAL_BASH_UTILS
  source $LOCAL_BASH_UTILS
}

github_api() {
  local method=$1
  local endpoint=$2
  local data=$3

  curl --silent "${GITHUB_API_URL}/${endpoint}" \
    -H "Authorization: token $GITHUB_API_TOKEN" \
    -X "$method" \
    -d "$data"
}

install_homebrew() {
  info "Checking for Homebrew, and installing if necessary"
  if test ! $(which brew); then
    info 'Installing homebrew...'
    ruby -e "$(curl -fsSL $HOMEBREW_DOWNLOAD_URL)" | stream_info
  else
    info 'Homebrew installed.'
  fi
}

install_ansible_dependencies() {
  info "Installing Ansible dependencies if necessary..."
  local ansible_dependencies=(python ansible)

  for dependency in  ${ansible_dependencies[*]}; do
    brew install $dependency || brew upgrade $dependency | stream_info
  done
}

local_ssh_key_content() {
  cat "${SSH_KEY_FILE}.pub" | cut -f1,2 -d' '
}

parse_github_ssh_key_json() {
  local json=$1
  local ssh_key_title=$2
  local value=''

  value=$(
    echo $json | \
    SSH_KEY_TITLE="$SSH_KEY_TITLE" python -c 'import json,os,sys;
json_obj = json.load(sys.stdin);
ssh_key_title = os.environ.get("SSH_KEY_TITLE");
print (item["id"] for item in json_obj if item["title"] == ssh_key_title).next()
'
  )
  echo $value
}

prompt_user_for_initial_input() {
  if [[ "$COMPUTER_ALIAS" == 'unset' ]]; then
    select_prompt computer_alias
    SSH_KEY_TITLE="${GITHUB_USERNAME}@${COMPUTER_ALIAS}"
  else
    info "COMPUTER_ALIAS set to: $COMPUTER_ALIAS from environment."
  fi

  if [[ "$WORKSPACE_PATH" == 'unset' ]]; then
    select_prompt workspace_path
  else
    info "WORKSPACE_PATH set to: $WORKSPACE_PATH from environment."
  fi

  if [[ "$SCRATCH_PATH" == 'unset' ]]; then
    select_prompt scratch_path
  else
    info "SCRATCH_PATH set to: $SCRATCH_PATH from environment."
  fi
}

select_prompt() {
  local selector="$1"
  local message=''
  local variable=''
  local value=''

  case "$selector" in
    computer_alias)
      message='Please enter the alias you would like associated with your local machine:  '
      variable=COMPUTER_ALIAS
      ;;
    github_email)
      message='Please enter the email address associated with your Github user:  '
      variable=GITHUB_EMAIL
      ;;
    github_username)
      message='Please enter your Github username:  '
      variable=GITHUB_USERNAME
      ;;
    scratch_path)
      message='Please enter the path you would like associated with your $scratch directory:  '
      variable=SCRATCH_PATH
      ;;
    ssh_key_email)
      message='Please enter the email address you would like associated with your SSH key:  '
      variable=SSH_KEY_EMAIL
      ;;
    ssh_key_password)
      message='Please create a password for your SSH key (minimum five characters):  '
      variable=SSH_KEY_PASSWORD
      ;;
    workspace_path)
      message='Please enter the path you would like associated with your $work directory:  '
      variable=WORKSPACE_PATH
      ;;
  esac

  warn "$message"
  if [[ "$variable" != 'SSH_KEY_PASSWORD' ]]; then
    read -e -p "$message" value
    export $variable=$value
    debug "$variable variable set to: ${!variable}"
  else
    stty -echo
    read -e -p "$message" value
    printf "\n"
    stty echo
    export $variable=$value
    debug "$variable variable set to: <REDACTED>"
  fi
}

set_git_aliases() {
  if [[ "$GITHUB_USERNAME" == 'unset' ]]; then
    select_prompt github_username
  else
    info "GITHUB_USERNAME set to: $GITHUB_USERNAME from environment."
  fi

  if [[ "$GITHUB_EMAIL" == 'unset' ]]; then
    select_prompt github_email
  else
    info "GITHUB_EMAIL set to: $GITHUB_EMAIL from environment."
  fi

  if [[ $(git config --global user.name) != $GITHUB_USERNAME ]]; then
    warn "Setting git user.name to $GITHUB_USERNAME"
    git config --global user.name "$GITHUB_USERNAME"
  fi

  if [[ $(git config --global user.email) != $GITHUB_EMAIL ]]; then
    warn "Setting git user.email to $GITHUB_EMAIL"
    git config --global user.email "$GITHUB_EMAIL"
  fi
}

start_ssh_agent() {
  info 'Starting the ssh-agent in the background'
  eval "$(ssh-agent -s)" | stream_info

  info "Removing ALL identity files from ssh-agent"
  ssh-add -D | stream_info

  info "Adding the $SSH_KEY_EMAIL identity to the ssh-agent"
  ssh-add -K $SSH_KEY_FILE | stream_info

  echo "$(ssh-add -l)" | stream_debug
}

symlink_dotfiles() {
  pushd "${WORKSPACE_PATH}/dotfiles" &>/dev/null
    local my_dotfiles="$(ls -d .[^.*]* | grep -v '^.git$\|^.gitignore$')"
    local dotfile=''

    info "Symlinking the following dotfiles to HOME directory:"
    info "$(echo $my_dotfiles)"

    for dotfile in ${my_dotfiles[*]}; do
      if ! [[ -L "${HOME}/${dotfile}" ]]; then
        warn "Symlinking ${WORKSPACE_PATH}/dotfiles/${dotfile} to ${HOME}/${dotfile}"
        ln -fns "${WORKSPACE_PATH}/dotfiles/${dotfile}" "${HOME}/${dotfile}"
      fi
    done
  popd
}

trap_signals() {
  trap "{ debug 'Running cleanup'; cleanup; }" EXIT
  trap "{ debug 'Running cleanup'; cleanup; fatal 'User interrupt detected. Exitting...'; }" SIGINT
}

run_ansible() {
  info "Running ansible to continue with local setup..."
  pushd "${WORKSPACE_PATH}/my-osx-setup/ansible" &>/dev/null
    exec ansible-playbook playbooks/darwin_bootstrap.yml -v
  popd
}

main() {
  trap_signals
  get_bash_utils
  check_github_api_token
  prompt_user_for_initial_input
  check_ssh_key_exists_locally
  start_ssh_agent
  create_ssh_config_file
  create_user_paths
  clone_repos_from_github
  symlink_dotfiles
  set_git_aliases
  install_homebrew
  install_ansible_dependencies
  run_ansible
}

main
