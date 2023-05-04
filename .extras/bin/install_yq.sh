#!/usr/bin/env bash

# Install yq using the adrianjuhl.yq ansible role.

usage()
{
  cat <<USAGE_TEXT
Usage:  $(basename "${BASH_SOURCE[0]}")
            [--dry_run]
            [--show_diff]
            [--verbose]
            [--install_bin_dir=<dir>]
            [--requires_become=<true|false>]
            [--yq_version=<yq_version>]
            [--script_debug]
            [--help | -h]

Install yq using the adrianjuhl.yq ansible role.

Available options:
    --dry_run
        Run the configuration process without making changes.
    --show_diff
        Show before/after changes to config.
    --verbose
        Show additional detail.
    --install_bin_dir=<dir>
        The base directory where the yq executable is to be installed. Defaults to "/usr/local/bin".
    --requires_become=<true|false>
        Is privilege escalation required for the installation? Defaults to true (as needed to install into the default install_bin_dir).
    --yq_version
        The version of yq to install. (Optional. If not given the default version set in the role will be installed.)
    --script_debug
        Print script debug info.
    --help, -h
        Print this help and exit.
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

  ASK_BECOME_PASS_OPTION=""
  if [ "${REQUIRES_BECOME}" = "${TRUE_STRING}" ]; then
    ASK_BECOME_PASS_OPTION="--ask-become-pass"
  fi

  ansible-playbook ${ANSIBLE_CHECK_MODE_ARGUMENT} ${ANSIBLE_DIFF_MODE_ARGUMENT} ${ANSIBLE_VERBOSE_ARGUMENT} ${ASK_BECOME_PASS_OPTION} -v \
    --inventory="localhost," \
    --connection=local \
    --extra-vars="adrianjuhl__yq__yq_install_bin_directory=${INSTALL_BIN_DIR}" \
    --extra-vars="local_playbook__install_yq__requires_become=${REQUIRES_BECOME}" \
    --extra-vars="${YQ_VERSION_EXTRAVAR}" \
    ${THIS_SCRIPT_DIRECTORY}/../.ansible/playbooks/configure_yq.yml
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
  ANSIBLE_VERBOSE_ARGUMENT=""
  YQ_VERSION=""
  YQ_VERSION_EXTRAVAR=""
  INSTALL_BIN_DIR="/usr/local/bin"
  REQUIRES_BECOME="${TRUE_STRING}"
  REQUIRES_BECOME_PARAM=""
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --dry_run)
        ANSIBLE_CHECK_MODE_ARGUMENT="--check"
        ;;
      --show_diff)
        ANSIBLE_DIFF_MODE_ARGUMENT="--diff"
        ;;
      --verbose)
        ANSIBLE_VERBOSE_ARGUMENT="-vvv"
        ;;
      --help | -h)
        usage
        exit
        ;;
      --script_debug)
        set -x
        ;;
      --yq_version)
        msg "Error: Missing version value for yq_version param."
        abort_script
        ;;
      --yq_version=)
        msg "Error: Missing version value for yq_version param."
        abort_script
        ;;
      --yq_version=*)
        YQ_VERSION="${1#*=}"
        ;;
      --install_bin_dir=*)
        INSTALL_BIN_DIR="${1#*=}"
        ;;
      --requires_become=*)
        REQUIRES_BECOME_PARAM="${1#*=}"
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
  case "${REQUIRES_BECOME_PARAM}" in
    "true")
      REQUIRES_BECOME="${TRUE_STRING}"
      ;;
    "false")
      REQUIRES_BECOME="${FALSE_STRING}"
      ;;
    "")
      REQUIRES_BECOME="${TRUE_STRING}"
      ;;
    *)
      msg "Error: Invalid requires_become param value: ${REQUIRES_BECOME_PARAM}, expected one of: true, false"
      abort_script
      ;;
  esac
  case "${YQ_VERSION}" in
    "")
      # Use the default yq version value defined in the role.
      ;;
    *)
      YQ_VERSION_EXTRAVAR="adrianjuhl__yq__yq_version=${YQ_VERSION}"
      ;;
  esac
  #echo "REQUIRES_BECOME_PARAM is: ${REQUIRES_BECOME_PARAM}"
  #echo "REQUIRES_BECOME is: ${REQUIRES_BECOME}"
  #echo "YQ_VERSION is: ${YQ_VERSION}"
  #echo "YQ_VERSION_EXTRAVAR is: ${YQ_VERSION_EXTRAVAR}"
}

initialize()
{
  set -o pipefail
  THIS_SCRIPT_PROCESS_ID=$$
  initialize_this_script_directory_variable
  initialize_abort_script_config
  initialize_true_and_false_strings
}

initialize_this_script_directory_variable()
{
  # THIS_SCRIPT_DIRECTORY where this script resides.
  # See: https://www.binaryphile.com/bash/2020/01/12/determining-the-location-of-your-script-in-bash.html
  # See: https://stackoverflow.com/a/67149152
  THIS_SCRIPT_DIRECTORY=$(cd "$(dirname -- "$BASH_SOURCE")"; cd -P -- "$(dirname "$(readlink -- "$BASH_SOURCE" || echo .)")"; pwd)
}

initialize_true_and_false_strings()
{
  # Bash doesn't have a native true/false, just strings and numbers,
  # so this is as clear as it can be, using, for example:
  # if [ "${my_boolean_var}" = "${TRUE_STRING}" ]; then
  # where previously 'my_boolean_var' is set to either ${TRUE_STRING} or ${FALSE_STRING}
  TRUE_STRING="true"
  FALSE_STRING="false"
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
