#!/usr/bin/env bash

# Install yq using the adrianjuhl.yq ansible role.

help_usage()
{
  cat <<USAGE_TEXT
Usage:  ${THIS_SCRIPT_NAME}
            [--yq_version=<yq_version>]
            [--install_bin_directory=<directory>]
            [--requires_become=<true|false>]
            [--dry_run]
            [--show_diff]
            [--verbose]
            [--help | -h]

Install yq using the adrianjuhl.yq ansible role.

Options:
    --yq_version
        The version of yq to install.
        Optional. If not given the default version set in the role will be installed.
    --install_bin_directory=<dir>
        The base directory where the yq executable is to be installed.
        Defaults to "/usr/local/bin".
    --requires_become=<true|false>
        Is privilege escalation required for the installation?
        Defaults to true (as needed to install into the default install_bin_directory).
    --dry_run
        Run the configuration process without making changes.
    --show_diff
        Show before/after changes to config.
    --verbose
        Show additional detail.
    --help, -h
        Print this help and exit.
USAGE_TEXT
}

main()
{
  initialize || { echo >&2 "Error: Failed to initialize script environment."; return 1; }
  parse_script_params "${@}" || { echo >&2 "Error: Failed to parse parameters."; return 1; }
  if [ "${show_help}" = "${TRUE_STRING}" ]; then
    help_usage
    return 0
  fi
  install_yq || { echo >&2 "Error: Failed to install yq."; return 1; }
}

install_yq()
{
  deterine_install_bin_directory || { echo >&2 "Error: Failed to determine install bin directory."; return 1; }
#  export ANSIBLE_ROLES_PATH=${THIS_SCRIPT_DIRECTORY}/../.ansible/roles/:${HOME}/.ansible/roles/
  install_ansible_role_dependencies || { echo >&2 "Error: Failed to install ansible role dependencies."; return 1; }
  determine_ansible_ask_become_option
  declare -a playbook_command_options_array
  construct_command_options_array \
    "playbook_command_options_array" \
    "${ansible_check_mode_argument}" \
    "${ansible_diff_mode_argument}" \
    "${ansible_verbose_argument}" \
    "${ansible_ask_become_pass_option}" \
    "--inventory=localhost," \
    "--connection=local" \
    "--extra-vars=adrianjuhl__yq__yq_install_bin_directory=${install_bin_directory}" \
    "--extra-vars=adrianjuhl__yq__yq_installation_requires_become=${requires_become}" \
    "${yq_version_ansible_extravar}"
  ansible-playbook \
    "${playbook_command_options_array[@]}" \
    "${THIS_SCRIPT_DIRECTORY}/../.ansible/playbooks/configure_yq.yml"
  last_command_return_code="${?}"
  if [ "${last_command_return_code}" -ne 0 ]; then
    echo >&2 "Error: Failed to run ansible playbook."
    return 1
  fi
}

deterine_install_bin_directory()
{
  install_bin_directory="$(cd "${install_bin_directory}" || exit 1; pwd)"
  last_command_return_code="${?}"
  if [ "${last_command_return_code}" -ne 0 ]; then
    echo >&2 "Error: Failed to determine install bin directory."
    return 1
  fi
}

install_ansible_role_dependencies()
{
  ANSIBLE_ROLES_PATH=${HOME}/.ansible/roles/ \
      ansible-galaxy \
      install \
      "--role-file=${THIS_SCRIPT_DIRECTORY}/../.ansible/roles/requirements_yq.yml" \
      --force
  last_command_return_code="${?}"
  if [ "${last_command_return_code}" -ne 0 ]; then
    echo >&2 "Error: Failed to install ansible role dependencies."
    return 1
  fi
}

determine_ansible_ask_become_option()
{
  ansible_ask_become_pass_option=""
  if [ "${requires_become}" = "${TRUE_STRING}" ]; then
    ansible_ask_become_pass_option="--ask-become-pass"
  fi
}

parse_script_params()
{
  #echo >&2 "script params (${#}) are: ${@}"
  # default values of variables set from params
  ansible_check_mode_argument=""
  ansible_diff_mode_argument=""
  ansible_verbose_argument=""
  yq_version=""
  yq_version_ansible_extravar=""
  install_bin_directory="/usr/local/bin"
  requires_become="${TRUE_STRING}"
  requires_become_param=""
  show_help="${FALSE_STRING}"
  enable_verbose="${FALSE_STRING}"
  while [ "${#}" -gt 0 ]
  do
    case "${1-}" in
      --yq_version)
        echo >&2 "Error: Missing version value for yq_version param."
        return 1
        ;;
      --yq_version=)
        echo >&2 "Error: Missing version value for yq_version param."
        return 1
        ;;
      --yq_version=*)
        yq_version="${1#*=}"
        ;;
      --install_bin_directory=*)
        install_bin_directory="${1#*=}"
        ;;
      --requires_become)
        requires_become_param="${TRUE_STRING}"
        ;;
      --requires_become=)
        echo >&2 "Error: Missing value for requires_become param."
        return 1
        ;;
      --requires_become=*)
        requires_become_param="${1#*=}"
        ;;
      --dry_run)
        ansible_check_mode_argument="--check"
        ;;
      --show_diff)
        ansible_diff_mode_argument="--diff"
        ;;
      --verbose)
        enable_verbose="${TRUE_STRING}"
        ansible_verbose_argument="-vvv"
        ;;
      --help | -h)
        show_help="${TRUE_STRING}"
        ;;
      -?*)
        echo >&2 "Error: Unknown parameter: ${1}"
        echo >&2 "Use --help for usage help"
        return 1
        ;;
      *) break ;;
    esac
    shift
  done
  if [ -n "${requires_become_param}" ]; then
    case "${requires_become_param}" in
      "true")
        requires_become="${TRUE_STRING}"
        ;;
      "false")
        requires_become="${FALSE_STRING}"
        ;;
      *)
        echo >&2 "Error: Invalid requires_become param value: ${requires_become_param}, expected one of: true, false"
        return 1
        ;;
    esac
  fi
  if [ -n "${yq_version}" ]; then
    yq_version_ansible_extravar="--extra-vars=adrianjuhl__yq__yq_version=${yq_version}"
  fi
  if [ "${enable_verbose}" = "${TRUE_STRING}" ]; then
    echo "requires_become_param is: ${requires_become_param}"
    echo "requires_become is: ${requires_become}"
    echo "yq_version is: ${yq_version}"
    echo "yq_version_ansible_extravar is: ${yq_version_ansible_extravar}"
  fi
}

construct_command_options_array()
  # Creates an array as named with the first parameter and populates it with the
  # non-blank/non-empty values of the remaining parameters.
  # Parameters:
  #   ${1}     - the name of the array
  #   ${2}...  - the values to populate the array with (the blank/empty values will be ignored)
  # For example:
  #   construct_command_options_array "command_options_array" "value1" "value2"
  #   declare -p command_options_array
  #   echo "command_options_array: ${command_options_array[*]}"
  #   for value in "${command_options_array[@]}"; do echo "value is: ${value}"; done
  #   mvn \
  #     "${command_options_array[@]}"
{
  # shellcheck disable=SC2064
  trap "$(shopt -p extglob)" RETURN  # Restores the extglob shopt when this fuction returns.
  shopt -s extglob
  local -n __construct_command_options_array__command_options_array="${1}"
  shift
  __construct_command_options_array__command_options_array=()
  for element in "${@}"
  do
    trimmed_element="${element}"
    trimmed_element="${trimmed_element##+([[:space:]])}" # trim leading whitespace
    trimmed_element="${trimmed_element%%+([[:space:]])}" # time trailing whitespace
    if [ -n "${trimmed_element}" ]; then
      __construct_command_options_array__command_options_array+=("${trimmed_element}")
    fi
  done
}

initialize()
{
  set -o pipefail
  set -o nounset
  THIS_SCRIPT_PROCESS_ID=$$
  initialize_abort_script_config
  initialize_this_script_directory_variable || { return 1; }
  initialize_this_script_name_variable
  initialize_true_and_false_strings
  initialize_function_capture_stdout_and_stderr
}

initialize_abort_script_config()
{
  # Exit shell script from within the script or from any subshell within this script - adapted from:
  # https://cravencode.com/post/essentials/exit-shell-script-from-subshell/
  # Exit with exit status 1 if this (top level process of this script) receives the SIGUSR1 signal.
  # See also the abort_script() function which sends the signal.
  trap "exit 1" SIGUSR1
}

initialize_this_script_directory_variable()
{
  # Determines the value of THIS_SCRIPT_DIRECTORY, the absolute directory name where this script resides.
  # See: https://www.binaryphile.com/bash/2020/01/12/determining-the-location-of-your-script-in-bash.html
  # See: https://stackoverflow.com/a/67149152
  local last_command_return_code
  # shellcheck disable=SC2034
  THIS_SCRIPT_DIRECTORY="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1; cd -P -- "$(dirname "$(readlink -- "${BASH_SOURCE[0]}" || echo .)")" || exit 1; pwd)"
  last_command_return_code="$?"
  if [ "${last_command_return_code}" -gt 0 ]; then
    # This should not occur for the above command pipeline.
    echo >&2 "Error: Failed to determine the value of this_script_directory."
    return 1
  fi
}

initialize_this_script_name_variable()
{
  local path_to_invoked_script
  local default_script_name
  path_to_invoked_script="${BASH_SOURCE[0]}"
  default_script_name=""
  if grep -q '/dev/fd' <(dirname "${path_to_invoked_script}"); then
    # The script was invoked via process substitution
    if [ -z "${default_script_name}" ]; then
      THIS_SCRIPT_NAME="<script invoked via file descriptor (process substitution) and no default name set>"
    else
      THIS_SCRIPT_NAME="${default_script_name}"
    fi
  else
    THIS_SCRIPT_NAME="$(basename "${path_to_invoked_script}")"
  fi
}

initialize_true_and_false_strings()
{
  # Bash doesn't have a native true/false, just strings and numbers,
  # so this is as clear as it can be, using, for example:
  # if [ "${my_boolean_var}" = "${TRUE_STRING}" ]; then
  # where previously 'my_boolean_var' is set to either ${TRUE_STRING} or ${FALSE_STRING}
  # shellcheck disable=SC2034
  TRUE_STRING="true"
  # shellcheck disable=SC2034
  FALSE_STRING="false"
}

initialize_function_capture_stdout_and_stderr()
{
  local capture_stdout_and_stderr_script_path
  capture_stdout_and_stderr_script_path="/usr/local/bin/capture_stdout_and_stderr.sh"
  if [ -f "${capture_stdout_and_stderr_script_path}" ]; then
    # shellcheck source=/dev/null
    . "${capture_stdout_and_stderr_script_path}"
  else
    echo >&2 "[WARNING] capture_stdout_and_stderr script file was not found (${capture_stdout_and_stderr_script_path})."
  fi
}

abort_script()
{
  echo >&2 "aborting..."
  kill -SIGUSR1 ${THIS_SCRIPT_PROCESS_ID}
  exit
}

# Main entry into the script - call the main() function
main "${@}"
