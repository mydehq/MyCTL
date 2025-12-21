#   _
#  | |    ___   __ _  __ _  ___ _ __
#  | |   / _ \ / _` |/ _` |/ _ \ '__|
#  | |__| (_) | (_| | (_| |  __/ |
#  |_____\___/ \__, |\__, |\___|_|
#              |___/ |___/
#
# MyCTL Logger
# Centralized logging system with color support and formatting options
#

# ==================== Configuration ====================

# Default log level (debug, normal, info, success, warn, error, fatal)
LOG_MIN_LEVEL="${LOG_MIN_LEVEL:-info}"

# Enable/Disable colored output (true/false)
LOG_COLOR="${LOG_COLOR:-true}"

# Log file path (empty = disabled)
LOG_FILE="${LOG_FILE:-}"

# Notification settings
LOG_NOTIFY="${LOG_NOTIFY:-false}"

# Show caller method in debug mode
LOG_SHOW_CALLER="${LOG_SHOW_CALLER:-false}"


# ================= Pre Processing ====================

readonly LOG_FILE
export LOG_MIN_LEVEL LOG_TAB LOG_COLOR LOG_TIMESTAMP LOG_SHOW_CALLER

#================ Detect Context ==================

_log_caller() {
    local i=1
    local caller_file caller_func

    # Find the first caller outside of logger.sh and _utils.sh
    while [[ -n "${BASH_SOURCE[$i]}" ]]; do
        case "${BASH_SOURCE[$i]}" in
            */logger.sh|*/_utils.sh)
                ((i++))
                ;;
            *)
                break
                ;;
        esac
    done

    # Fallback to defaults if we went off the stack
    caller_file="${BASH_SOURCE[$i]:-unknown}"
    caller_func="${FUNCNAME[$i]:-main}"

    local filename="${caller_file##*/}"  # Remove everything up to last /
    filename="${filename%.sh}"           # Remove .sh suffix

    # Check if LIB_DIR is set and if caller_file starts with it
    if [[ -n "${LIB_DIR}" && "${caller_file}" == "${LIB_DIR}"* ]]; then
        if [[ "$caller_func" != "main" && "$caller_func" != "source" ]]; then
            echo "${caller_func}"
        else
            echo "${filename}"
        fi
    else
        # If the script is the main myctl script (or variant), show 'main'
        if [[ "$filename" == "myctl"* ]]; then
            if [[ "$caller_func" != "main" ]]; then
                 echo "${caller_func}"
            else
                 echo "main"
            fi
        else
             echo "${filename}"
        fi
    fi
}


#===================== Log Indentation ====================

# Initialize LOG_TAB
export LOG_TAB=0

_tab() {
    local cmd="$1" arg="$2"
    local step="${arg:-1}"

    # Default LOG_TAB if not set globally
    : "${LOG_TAB:=0}"

    case "$cmd" in
        inc)
            [[ "$step" =~ ^[0-9]+$ ]] || { log.error "step must be positive int"; return 1; }
            (( LOG_TAB += step ))
            ;;
        dec)
            [[ "$step" =~ ^[0-9]+$ ]] || { log.error "step must be positive int"; return 1; }
            (( LOG_TAB -= step ))
            (( LOG_TAB < 0 )) && LOG_TAB=0
            ;;
        set)
            [[ "$arg" =~ ^[0-9]+$ ]] || { log.error "level must be non-negative int"; return 1; }
            LOG_TAB=$arg
            ;;
        reset)
            LOG_TAB=0
            ;;
        get)
            echo "$LOG_TAB"
            ;;
        "")
            (( LOG_TAB > 0 )) && printf "%*s" $((LOG_TAB * 4)) ""
            ;;
        *)
            log.error "Invalid command: $cmd"
            return 1
            ;;
    esac
}


#============== Central Logging Method ====================

# Usage: _log <level> [flags] <message>
# FLAGS:
#    -b,--bold                 Enable bold text
#    -c,--color <color>        Color name to use
#    -t,--tab                  Increase indentation level (for single message)
#    -p,--plain                Disable color output (Overrides defaults)
#    -cf,--caller-func <name>  Set caller function name
#
# Levels: debug < info < success < warn < error < fatal
# Colors: black, red, green, blue, cyan, white, yellow,
#         orange, purple, gray
_log() {
    local msg_level="$1" && shift
    local return_code=0 \
          bold_flag=false notify_user=false increase_tab=false no_color=false explicit_caller=false \
          min_level_num color icon message leading_newlines timestamp caller_func caller_name_raw \
          _color  _icon _level n_urgency n_icon

    #---------- Internal Error Logger -----------
    _elog() {
        echo -e "$(_tab)${_BOLD_RED}✗ ERROR: $1${_NC}" >&2
    }

    #----- convert level to num -------
    _lvl2num() {
        case "$1" in
            [0-9]|[0-9][0-9])
                if [[ "$1" -ge 10 && "$1" -le 60 ]]; then
                    echo "$1"
                else
                    _elog "Invalid numeric level '$1'. Defaulting to 15(normal)."
                    echo 15 # Default to normal
                fi
                ;;
            fatal)            echo 60  ;;
            error)            echo 50  ;;
            warn|ask)         echo 40  ;;
            success)          echo 30  ;;
            info)             echo 20  ;;
            normal|"")        echo 15  ;;
            debug)            echo 10  ;;
            *)
                _elog "Error: Invalid level name '$1'. Defaulting to normal."
                echo 15
                ;;
        esac
    }


    #------ Parse arguments (flags) -----------

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -b|--bold)
                bold_flag=true
                shift
                ;;
            -p|--plain)
                no_color=true
                shift
                ;;
            -c|--color)
                case "$2" in
                    black|red|green|blue|cyan|white|yellow|orange|purple|gray)
                        color="$2"
                        ;;
                    *)
                        _elog "Error: Invalid color name '$2'"
                        return 1
                        ;;
                esac
                shift 2
                ;;
            -cf|--caller)
                [ -z "$2" ] && {
                    _elog "Error: Missing caller function name"
                    return 1
                }
                caller_name_raw="$2"
                caller_func=" [$2]"
                explicit_caller=true
                shift 2
                ;;
            -i|--icon)
                icon="$2"
                shift 2
                ;;
            -n|--notify)
                notify_user=true
                shift
                ;;
            -t|--tab)
                increase_tab=true
                shift
                ;;
            *)
                message="$1"
                shift
                ;;
        esac
    done


    #------- Set defaults based on arg's level -------

    case "$msg_level" in
        debug)   _color="gray"; _icon="#"
                 n_urgency="low"; n_icon="dialog-icon-preview"
            ;;
        info)    _color="blue";  _icon="i"
                 n_urgency="low"; n_icon="dialog-information"
            ;;
        success) _color="green"; _icon="+"
                 n_urgency="low"; n_icon="dialog-yes"
            ;;
        warn)    _color="yellow"; _icon="!"
                 n_urgency="normal"; n_icon="dialog-warning"
            ;;
        ask)     _color="yellow"; _icon="?"
                 n_urgency="normal"; n_icon="dialog-question"
            ;;
        error)   _color="red"; _icon="x";  return_code=1;
                 n_urgency="critical"; n_icon="dialog-error"
            ;;
        fatal)   _color="red";  _icon="X";  return_code=1;   bold_flag=true;
                 n_urgency="critical";  n_icon="dialog-error"
            ;;
        *)       _color="";  _icon=">"
                 n_urgency="low"; n_icon="dialog-info"
            ;;
    esac


    #--------- Determine Level of Suppression ---------------

    # Convert min log level & message level to numbers
    min_level_num="$(_lvl2num "$LOG_MIN_LEVEL")"
    msg_level_num="$(_lvl2num "$msg_level")"

    # Suppress logs if level < min required level
    if [ "$msg_level_num" -lt "$min_level_num" ]; then
        return 0
    fi


    #------------ Decide Color ----------------

    # Override default color if given by flag
    [ -z "$color" ] && color="$_color"

    if [ "$no_color" = true ] || [ "$LOG_COLOR" = false ]; then
        color=""
    else
        { $bold_flag && color="_bold_${color}"; } || color="_${color}"

        # Capitalize & get the color value
        color="${color^^}"
        color="${!color}"
    fi

    #------------- Override Icon if flag given --------------

    [ -z "$icon" ] && icon="$_icon"

    #---- Handle leading newlines ----------

    # Finds and preserves escaped newlines at the start of the message
    while [ "${message#\\n}" != "$message" ]; do
        leading_newlines+="\n"
        message="${message#\\n}"
    done
    echo -en "$leading_newlines" >&2

    #------------ Find Caller ----------

    # Show caller if explicitly enabled OR if we are in debug (min_level <= 10) mode
    if [[ "$min_level_num" -le 10 ]] || $LOG_SHOW_CALLER; then
        if [[ -z "$caller_func" ]]; then
             caller_func=" [$(_log_caller)]" || {
                _elog "Failed to get caller function"
                return 1
            }
        fi
    fi

    #---------- Print Message -----------

    # Print to STDERR
    echo -e "$(_tab)${color}${icon}${_NC}${_GRAY}${caller_func}${_NC} ${color}${message}${_NC}" >&2

    # Print to Log File
    if [ -n "$LOG_FILE" ]; then

        # Create directory if it doesn't exist
        if [ ! -d "$LOG_DIR" ]; then
            if ! mkdir -p "$LOG_DIR"; then
                _elog "Couldn't create log directory at '$LOG_DIR'. Log not saved."
                return $return_code
            fi
        fi

        # Create file if it doesn't exist
        if [ ! -f "$LOG_FILE" ]; then
            if ! touch "$LOG_FILE"; then
                _elog "Couldn't create log file at '$LOG_FILE'. Log not saved."
                return $return_code
            fi
        fi

        # Write to log file
        if [ -w "$LOG_FILE" ]; then
            timestamp="$(date +"%y-%m-%d %H:%M:%S")"
            echo -e "[$timestamp] $(_tab)${icon} ${message}" >> "$LOG_FILE"
        else
            _elog "Log file at '$LOG_FILE' is not writable. Log not saved."
        fi

    elif [ "$msg_level_num" -ge 40 ]; then
        _elog "LOG_FILE variable is not set. Log was not saved."
    fi

    # Send Notification
    if $notify_user || [ "$LOG_NOTIFY" = "true" ]; then
        send-notification \
            -u "$n_urgency" \
            -i "$n_icon"    \
            ${explicit_caller:+ -h "$caller_name_raw" } \
            "$message"
    fi

    return ${return_code}
}


#=============== Public API ==================

# _log wrappers
log()         { _log ""  "$@";     }
log.debug()   { _log debug "$@";   }
log.info()    { _log info "$@";    }
log.success() { _log success "$@"; }
log.warn()    { _log warn "$@";    }
log.error()   { _log error "$@";   }
log.fatal()   { _log fatal "$@"; exit 1; }
log.nyi()     { log.warn "Not yet Implemented"; }

# _tab wrappers
log.tab.inc()   { _tab inc "$@"; }
log.tab.dec()   { _tab dec "$@"; }
log.tab.set()   { _tab set "$@"; }
log.tab.get()   { _tab set;      }
log.tab.reset() { _tab reset;    }

# LOG_MIN_LEVEL wrappers
log.level.set() { LOG_MIN_LEVEL="$1";    }
log.level.get() { echo "$LOG_MIN_LEVEL"; }

# LOG_COLOR wrappers
log.color.get() { echo "$LOG_COLOR"; }
log.color.set() {
    case "$1" in
        true)   LOG_COLOR=true ;;
        false) LOG_COLOR=false ;;
        *) log.error "Invalid argument '$1'" ;;
    esac
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
