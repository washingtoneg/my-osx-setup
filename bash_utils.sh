#!/bin/bash

export DEBUG="${DEBUG:-false}"
export EMOJI_SUPPORT="${EMOJI_SUPPORT:-true}"
export LOG_DIR="${LOG_DIR:-''}"
export LOG_FILE="${LOG_FILE:-/tmp/my_bash_script.log}"
export LOG_FILE_REGEXP="${LOG_FILE_REGEXP:-'*.log'}"
export USE_CLEAN_TERM="${USE_CLEAN_TERM:-false}"

# Text colors

export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export CYAN=$(tput setaf 6)
export WHITE=$(tput setaf 7)
export VISIBLE=$(tput cnorm)

# End color escape sequence
export END="\033[0m"

check_mark_icon() {
  print_icon check_mark
}

create_log_file() {
  trap print_and_symlink_log_location EXIT

  mkdir -p "$LOG_DIR"
  touch "$LOG_FILE" > /dev/null
}

debug() {
  local msg

  msg="$1"

  # Enable debug ouput only if --debug option passed
  if [[ "$DEBUG" == 'true' ]]; then
    log debug "$msg"
  fi
}

fatal() {
  local msg

  msg="$1"

  if [[ "$USE_CLEAN_TERM" == 'true' ]]; then
    warn 'An error occured. Your terminal will be restored after exit.'

    # Give the user a moment to absorb the failure if using clean terminal
    sleep 2
  fi

  log fatal "$msg"
  exit 1
}

fingers_crossed_icon() {
  print_icon fingers_crossed
}

info() {
  local msg

  msg="$1"
  log info "$msg"
}

installed_icon() {
  print_icon installed
}

log() {
  local level msg color

  level="$1"
  msg="$2"

  text=$(echo $level | tr [a-z] [A-Z])

  case "${level}" in
    debug) color="$CYAN";;
    fatal) color="$RED";;
    info) color="$VISIBLE";;
    notice) color="$GREEN";;
    warn) color="$YELLOW";;
  esac

  if [[ $(echo $LOG_FILE) == 'STDOUT' ]]; then
    log_command $color $text $msg 2>&1
  else
    log_command $color $text $msg 2>&1 | tee -a $LOG_FILE
  fi
}

log_command() {
  local color text msg

  color="$1"
  text="$2"

  # Process all arguments except the first 2
  msg="${@:3}"

  echo -e "${color}$(timestamp) $(caller 2 | awk '{print $NF}') [${text}]: ${msg}${END}\r"
}

print_and_symlink_log_location() {
  # Print log file location if it exists and symlink
  # last_log_file to it for convenience
  if [[ -n "$LOG_FILE"  ]] && [[ "$LOG_FILE" != 'STDOUT' ]]; then
    info "Session logs stored at $LOG_FILE and symlinked to $LOG_DIR/last_log_file"
    ln -fs "$LOG_FILE" "${LOG_DIR}/last_log_file"
  fi

  # Rotate logs if necessary
  log_rotate
}

log_rotate() {
  info "Checking to see if log files need to be rotated..."

  max=10
  counter=0

  ls -t $(echo "${LOG_DIR}/${LOG_FILE_REGEXP}") |
    while read file; do
      counter=$((counter+1))
      if [[ "$counter" -gt "$max" ]]; then
        warn "$file removed via logrotation"
        rm -f "$file"
      fi
    done
}

missing_icon() {
  print_icon missing
}

notice() {
  local msg

  msg="$1"
  log notice "$msg"
}

print_icon() {
  local icon utf8 ascii

  icon="$1"

  case "${icon}" in
    check_mark)
      utf8="\xe2\x9c\x94"
      ascii='[check mark]'
      ;;
    fingers_crossed)
      utf8="\xf0\x9f\xa4\x9e"
      ascii='[scouts honor]'
      ;;
    installed)
      utf8="\xf0\x9f\x91\x8d"
      ascii='+'
      ;;
    missing)
      utf8="\xe2\x9d\x8c"
      ascii='-'
      ;;
  esac

  if [[ $(echo $EMOJI_SUPPORT) == 'true' ]]; then
    echo -e "$utf8"
  else
    echo "$ascii"
  fi
}

restore_terminal() {
  # Restore screen
  tput rmcup

  print_and_symlink_log_location
}

stream_debug() {
  while read -e line ; do
    debug "$line"
  done
}

stream_info() {
  while read -e line ; do
    info "$line"
  done
}

stream_warn() {
  while read -e line ; do
    warn "$line"
  done
}

terminal_check() {
  # Check if xterm and if tput is installed
  if [[ $(echo $TERM) == "xterm"* ]]; then
    debug 'xterm detected'

    if [[ $(command -v tput) ]]; then
      debug 'tput installed'
      warn 'Sending output to a clean terminal. Use --log-dir option to persist output.'
      use_clean_terminal
    else
      warn 'tput is not not installed. A new terminal screen will not be created.'
    fi
  else
    warn 'xterm not matched in you $TERM environment variable. A new terminal screen will not be created.'
  fi
}

timestamp() {
  date +"%b %d %Y %T"
}

use_clean_terminal() {
  trap restore_terminal EXIT
  info "Using a new, secondary terminal screen (I'll put it back $(fingers_crossed_icon) )..."
  sleep 2

  # Save screen, clear screen
  tput smcup
  clear
}

warn() {
  local msg

  msg="$1"
  log warn "$msg"
}

debug "Finished sourcing bash_utils"
