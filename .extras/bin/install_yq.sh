#!/usr/bin/env bash

# Install yq using the adrianjuhl.yq ansible role.

usage()
{
  cat <<USAGE_TEXT
Usage: $(basename "${BASH_SOURCE[0]}") [--dry_run] [--show_diff] [--help | -h] [--verbose | -v]

Install yq using the adrianjuhl.yq ansible role.

Available options:
  --dry_run
      Run the role without making changes.

  --show_diff
      Run the role in diff mode.

  --help, -h
      Print this help and exit.

  --verbose, -v
      Print script debug info.
USAGE_TEXT
}

main()
{
  initialize
  parse_script_params "${@}"
  install_yq
}

install_yq()
{
  export ANSIBLE_ROLES_PATH=${THIS_SCRIPT_DIRECTORY}/../.ansible/roles/:${HOME}/.ansible/roles/

  # Install the dependencies of the playbook:
  ANSIBLE_ROLES_PATH=${HOME}/.ansible/roles/ ansible-galaxy install --role-file=${THIS_SCRIPT_DIRECTORY}/../.ansible/roles/requirements_yq.yml --force
  last_command_return_code="$?"
  if [ "${last_command_return_code}" -ne 0 ]; then
    msg "Error: ansible-galaxy role installations failed."
    abort_script
  fi

  ansible-playbook ${ANSIBLE_CHECK_MODE_ARGUMENT} ${ANSIBLE_DIFF_MODE_ARGUMENT} -v \
    --inventory="localhost," \
    --connection=local \
    --ask-become-pass \
    ${THIS_SCRIPT_DIRECTORY}/../.ansible/playbooks/install_yq.yml
  last_command_return_code="$?"
  if [ "${last_command_return_code}" -ne 0 ]; then
    msg "Error: ansible-playbook run failed."
    abort_script
  fi
}

parse_script_params()
{
  #msg "script params (${#}) are: ${@}"
  # default values of variables set from params
  ANSIBLE_CHECK_MODE_ARGUMENT=""
  ANSIBLE_DIFF_MODE_ARGUMENT=""
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --dry_run)
        ANSIBLE_CHECK_MODE_ARGUMENT="--check"
        ;;
      --show_diff)
        ANSIBLE_DIFF_MODE_ARGUMENT="--diff"
        ;;
      --help | -h)
        usage
        exit
        ;;
      --verbose | -v)
        set -x
        ;;
      -?*)
        msg "Error: Unknown parameter: ${1}"
        msg "Use --help for usage help"
        abort_script
        ;;
      *) break ;;
    esac
    shift
  done
}

initialize()
{
  set -o pipefail
  THIS_SCRIPT_PROCESS_ID=$$
  THIS_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "${0}")")"
  initialize_abort_script_config

  # Bash doesn't have a native true/false, just strings and numbers,
  # so this is as clear as it can be, using, for example:
  # if [ "${my_boolean_var}" = "${TRUE_STRING}" ]; then
  # where previously 'my_boolean_var' is set to either ${TRUE_STRING} or ${FALSE_STRING}
  TRUE_STRING="true_string"
  FALSE_STRING="false_string"
}

initialize_abort_script_config()
{
  # Exit shell script from within the script or from any subshell within this script - adapted from:
  # https://cravencode.com/post/essentials/exit-shell-script-from-subshell/
  # Exit with exit status 1 if this (top level process of this script) receives the SIGUSR1 signal.
  # See also the abort_script() function which sends the signal.
  trap "exit 1" SIGUSR1
}

abort_script()
{
  echo >&2 "aborting..."
  kill -SIGUSR1 ${THIS_SCRIPT_PROCESS_ID}
  exit
}

msg()
{
  echo >&2 -e "${@}"
}

# Main entry into the script - call the main() function
main "${@}"
