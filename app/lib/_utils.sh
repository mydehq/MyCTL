#!/usr/bin/env bash

# Enable alias expansion in non-interactive mode
shopt -s expand_aliases

#--------------------

# Usage: extract-method-names <lib_file_path>
extract-method-names() {
    local file_path="$1"
    local awk_script="${SRC_DIR}/extract-method-names.awk"

    # Validate input
    [[ -z "$file_path" ]] && {
        echo "ERROR: No file path provided to extract-method-names" >&2
        return 1
    }

    [[ ! -f "$file_path" ]] && {
        echo "ERROR: File not found: $file_path" >&2
        return 1
    }

    [[ ! -f "$awk_script" ]] && {
        echo "ERROR: AWK script not found: $awk_script" >&2
        return 1
    }

    # Extract function names using the AWK script
    awk -f "$awk_script" "$file_path"
}

#-------------------

# Usage: export-lib-methods <lib_file_path>
export-lib-methods() {
    local file_path="$1"

    while IFS= read -r method_name; do
        [ -n "$method_name" ] && \
        export -f $method_name
    done < <(extract-method-names "$file_path")
}

#--------------------

for lib_name in _colors logger import-lib; do

    _LIB_PATH="${LIB_DIR}/${lib_name}.sh"

    if [[ -f "$_LIB_PATH" ]]; then
        if source "$_LIB_PATH"; then
            export-lib-methods "$_LIB_PATH"
            IMPORTED_LIBS["$(realpath "$_LIB_PATH")"]=1
        else
            echo "FATAL: Failed to source ${lib_name} from '$_LIB_PATH'" >&2
            exit 1
        fi
    else
        echo "FATAL: Cannot load ${lib_name} from '$_LIB_PATH'" >&2
        exit 1
    fi
done

#------------------

# shellcheck disable=SC2142
alias shift-arg='shift && [ -n "$1" ]'

#------------------

self() {
    "$THIS_PATH" "$@"
}

#---------------

# Usage: run-script <script-path>
run-script() {
    local script_path="$1"

    shift  # Shift to skip the 1st argument (script path)

    if [ -x "$script_path" ]; then
        "$script_path" "$@"
    else
        log.error "Script '$script_path' not found or not executable."
        exit 1
    fi
}

#---------------

invalid-cmd() {
    local unknown_cmd="$1"
    echo "" >&2

    if [ "$unknown_cmd" == "" ]; then
        log.error "No command provided."
    else
        log.error "Unknown command: '$unknown_cmd'."
    fi
}

#---------------

help-menu() {
    local command="${cmd_map[cmd]}"

    ! [ ${cmd_map[usage]+_} ] && {
        if [ "$command" == "myctl" ]; then
            cmd_map[usage]="${cmd_map[cmd]} <cmd> [subcommand]"
        else
            cmd_map[usage]="myctl ${cmd_map[cmd]} [subcommand]"
        fi
    }

    echo "" >&2
    if [ "$command" == "myctl" ]; then
        echo "MyCTL - Control Various Functions of MyDE" >&2
        echo "" >&2
        echo "Usage: ${cmd_map[usage]}" >&2
    else
        echo "MyCTL - '$command' command" >&2
        echo "" >&2
        echo "Usage: ${cmd_map[usage]}" >&2
    fi
    echo "" >&2

    echo "Commands: " >&2
    _print_help_cmds cmd_map
}

#---------------

# _print_help_cmds <dict_name>
_print_help_cmds() {
    local -n arr="$1"
    local -a skip_keys=(cmd usage)
    local -a filtered_keys=()
    local max_len=0

    arr[help]="Show help menu"
    skip_keys+=("help")

    # First loop: Find maximum key length and filter out skipped keys
    for key in "${!arr[@]}"; do
        local should_skip=0
        for s_key in "${skip_keys[@]}"; do
            if [[ "$key" == "$s_key" ]]; then
                should_skip=1
                break
            fi
        done
        if [[ "$should_skip" -eq 0 ]]; then
            filtered_keys+=("$key")
            (( ${#key} > max_len )) && max_len=${#key}
        fi
    done

    # Print filtered commands
    for key in "${filtered_keys[@]}"; do
        printf "   %-$((max_len + 4))s %s\n" "$key" "${arr[$key]}" >&2
    done

    # print help at last
    printf "   %-$((max_len + 4))s %s\n" "help" "${arr[help]}" >&2
}

#-----------------

# Usage: read-hconf <key_name> <hypr_file>
# Limitation: Doesn't expand hyprlang vars. only shell vars/cmds.
# TODO:
#       default file support
#       default value support
read-conf() {
    local key_name raw_value final_value \
          hypr_file="${2:-$MYDE_CONF}"

    [[ -z "$1" ]] && {
        log.error "Error: No key name provided."
        return 1
    }

    key_name=$1

    [[ ! -f "$hypr_file" ]] && {
        log.error "Error: Config file not found at $hypr_file"
        return 1
    }

    # Find the key & Extract Value
    raw_value=$(awk -F'=' -v key="$key_name" '
      $0 ~ key && /^\s*\$/ {
        sub(/#.*/, "", $2)               # Remove comments from the value
        gsub(/^[ \t]+|[ \t]+$/, "", $2)  # Trim leading/trailing whitespace
        print $2                         # Print the trimmed value
      }
    ' "$hypr_file")

    [[ -z "$raw_value" ]] && {
        log.error "Error: Key not found: $key_name"
        return 1
    }

    # Expand Value
    final_value=$(eval echo "$raw_value")

    # Return Result
    echo "$final_value"
}

#----------------

has-cmd() {
  local cmd_str cmd_bin
  local exit_code=0

  [[ "$#" -eq 0 ]] && {
    log.error "No arguments provided."
    return 2
  }

  # Iterate over every argument passed to the function
  for cmd_str in "$@"; do
    cmd_bin="${cmd_str%% *}"   # first token before any space

    log.debug "Checking Command: $cmd_bin"

    if command -v "$cmd_bin" &>/dev/null; then
      log.debug "$cmd_bin is available."
    else
      log.debug "$cmd_bin is not available."
      exit_code=1
    fi
  done

  return "$exit_code"
}

#----------------

get-file-hash() {
  local file="$1"

  ! has-cmd sha256sum && {
    log.error "'sha256sum' command not found."
  }

  if [ -f "$file" ]; then
      sha256sum "$file" | awk '{print $1}'
  else
      log.error "File not found: $file"
  fi
}

#----------------

# Usage: send-notification [flags] <content>
# Flags:
#    -i,--icon      <ICON>                  icon name/path to use (default: myctl/myde)
#    -b,--bar       <percentage>            Show progress bar with percentage (default: 0)
#    -u,--urgency   <low|normal|critical>   urgency level (default: normal)
#    -t,--timeout   <timeoutInMS>           timeout value in milliseconds
#    -h,--heading   <string>                heading text (default: MyCTL/MyDE)
#    -T,--transient                         tell daemon not to store in history (default: false)
#    -id,--id-str   <idNum/String>          notification ID string.
#                                           notification with same id will be replaced by new one.
send-notification() {
    local icon="myctl"
    local id=""
    local heading="MyCTL"
    local urgency="normal"
    local timeout=""
    local content=""
    local transient="false"
    local show_bar="false"
    local bar_percent="0"
    local notify_id

    # Internal logging helper
    _elog() {
        echo -e "$(_tab 2>/dev/null)${_BOLD_RED}✗ ERROR: $1${_NC}" >&2
    }

    # Dependency check
    if ! command -v notify-send &> /dev/null; then
        _elog "notify-send not found."
        return 1
    fi

    # Environment check
    if [[ "$INSIDE_MYDE" == "true" ]]; then
        icon="myde"
        heading="MyDE"
    fi

    # Argument Parsing
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -i|--icon)
                [[ -z "$2" ]] && _elog "Icon required." && return 1
                icon="$2"; shift 2 ;;
            -b|--bar)
                show_bar="true"
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    bar_percent="$2"
                    shift 2
                else
                    _elog "Invalid percentage: $2"
                    return 1
                fi
                ;;
            -u|--urgency)
                if [[ -z "$2" ]]; then
                    _elog "Urgency value needed (low|normal|critical)"
                    return 1
                fi

                case "$2" in
                    low|normal|critical)
                        urgency="$2"
                        shift 2
                        ;;
                    *)
                        _elog "Invalid urgency: $2"
                        return 1
                        ;;
                esac
            ;;
            -t|--timeout)
                timeout="$2"; shift 2 ;;
            -h|--heading)
                heading="$2"; shift 2 ;;
            -T|--transient)
                transient="true"; shift 1 ;;
            -id|--id-str)
                id="$2"; shift 2 ;;
            -*)
                _elog "Unknown option: $1"
                return 1 ;;
            *)
                content="$1"; shift 1 ;;
        esac
    done

    if [[ -z "$content" ]]; then
        _elog "Notification content is required"
        return 1
    fi

    if [[ -z "$timeout" ]]; then
        if [[ "$urgency" == "critical" ]]; then
            timeout=10000
        fi
    fi

    # Bar >100% overflow
    if [[ "$show_bar" == "true" ]] && [[ "$bar_percent" -gt 100 ]]; then
        urgency="critical"
        bar_percent=$((bar_percent - 100))
    fi

    local cmd_args=()
    cmd_args+=("-i" "$icon")
    cmd_args+=("-u" "$urgency")
    cmd_args+=("-h" "boolean:transient:$transient")

    if [ -n "$timeout" ]; then
        cmd_args+=("-t" "$timeout")
    fi

    # Conditional flags
    if [[ -n "$id" ]]; then
        cmd_args+=("-h" "string:x-canonical-private-synchronous:$id")
    fi

    if [[ "$show_bar" == "true" ]]; then
        cmd_args+=("-h" "int:value:$bar_percent")
    fi

    if [[ "$LOG_MIN_LEVEL" == "debug" ]]; then
        log.debug "Sending notification:"
        log.tab.inc
        for ((i = 0; i < ${#cmd_args[@]}; i += 2)); do
            log.debug "${cmd_args[i]}='${cmd_args[i+1]}'"
        done
        log.tab.dec
    fi

    notify_id=$(notify-send -p "${cmd_args[@]}" "$heading" "$content")

    if [[ -z "$notify_id" ]]; then
        log.error "Failed to send notification"
        return 1
    fi

    log.debug "Notification ID: $notify_id"

    if [[ "$urgency" == "critical" && -z "$timeout" ]]; then
        local sleep_time
        sleep_time=$(awk "BEGIN {print $timeout/1000}")

        (
            sleep "$sleep_time"
            gdbus call --session \
                --dest org.freedesktop.Notifications \
                --object-path /org/freedesktop/Notifications \
                --method org.freedesktop.Notifications.CloseNotification \
                "$notify_id" > /dev/null
        ) & disown
    fi
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
