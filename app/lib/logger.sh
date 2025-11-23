#!/usr/bin/env bash

# ==================== Configuration ====================

# Default log level (debug, info, warn, error, fatal)
LOG_LEVEL="${LOG_LEVEL:-info}"

# Enable/disable colored output
LOG_COLOR="${LOG_COLOR:-true}"

# Enable/disable timestamps
LOG_TIMESTAMP="${LOG_TIMESTAMP:-false}"

# Log file path (empty = disabled)
LOG_FILE="${LOG_FILE:-}"

# Notification settings
LOG_NOTIFY="${LOG_NOTIFY:-false}"

NOTIFY_BIN="$(command -v notify-send)"

# ==================== Color Codes ====================

case $LOG_LEVEL in
    debug) LOG_LEVEL=0;;
    info) LOG_LEVEL=1;;
    warn) LOG_LEVEL=2;;
    error) LOG_LEVEL=3;;
    fatal) LOG_LEVEL=4;;
    *) LOG_LEVEL=1;;
esac

if [[ "$LOG_COLOR" == "true" ]]; then
    COLOR_RESET='\033[0m'
    COLOR_DEBUG='\033[0;36m'    # Cyan
    COLOR_INFO='\033[0;32m'     # Green
    COLOR_WARN='\033[1;33m'     # Yellow
    COLOR_ERROR='\033[0;31m'    # Red
    COLOR_FATAL='\033[1;31m'    # Bold Red
    COLOR_CONTEXT='\033[0;35m'  # Magenta
else
    COLOR_RESET=''
    COLOR_DEBUG=''
    COLOR_INFO=''
    COLOR_WARN=''
    COLOR_ERROR=''
    COLOR_FATAL=''
    COLOR_CONTEXT=''
fi

# ==================== Helper Functions ====================

# Get timestamp if enabled
_log_timestamp() {
    if [[ "$LOG_TIMESTAMP" == "true" ]]; then
        date '+%Y-%m-%d %H:%M:%S'
    fi
}

# Auto-detect context from caller
_log_detect_context() {
    local i=1   # skip current func
    local caller_file="unknown"
    local caller_func="main"
    local filename

    # Find the first caller outside of logger.sh and _utils.sh
    while [[ -n "${BASH_SOURCE[$i]}" ]]; do
        local current_file="${BASH_SOURCE[$i]}"
        local current_func="${FUNCNAME[$i]}"

        # If the current file is not logger.sh or _utils.sh, then it's our caller
        if [[ "$current_file" != *"/logger.sh"* && "$current_file" != *"/_utils.sh"* ]]; then
            caller_file="$current_file"
            caller_func="$current_func"
            break
        fi
        ((i++))
    done

    # Extract filename without path and extension
    filename=$(basename "$caller_file" .sh)

    # Determine if it's a lib function or main command
    if [[ -n "${LIB_DIR}" && "$caller_file" == "${LIB_DIR}/"* ]]; then
        # Library function - use function name if available
        if [[ "$caller_func" != "main" && "$caller_func" != "source" ]]; then
            echo "lib:${caller_func}"
        else
            echo "lib:${filename}"
        fi
    elif [[ "$filename" == "myctl" ]]; then
        # Main myctl command
        echo "myctl"
    else
        # Other scripts
        echo "${filename}"
    fi
}

# Format log message with prefix
_log_format() {
    local level="$1"
    local context="$2"
    local message="$3"
    local color="$4"

    local timestamp=""

    [[ "$LOG_TIMESTAMP" == "true" ]] && timestamp="$(_log_timestamp) "

    if [[ -n "$context" ]]; then
        echo -e "${timestamp}${COLOR_CONTEXT}[${context}]${COLOR_RESET} ${color}${level}:${COLOR_RESET} ${message}"
    else
        echo -e "${timestamp}${color}${level}:${COLOR_RESET} ${message}"
    fi
}

# Write to log file if enabled
_log_to_file() {
    local message="$1"
    local clean_message

    if [[ -n "$LOG_FILE" ]]; then
        # Strip color codes for file output
        clean_message=$(echo -e "$message" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')

        echo "$clean_message" >> "$LOG_FILE"
    fi
}

# Send desktop notification
_log_notify() {
    local level="$1"
    local message="$2"
    local urgency="normal"
    local icon="dialog-information"

    # Skip if notifications disabled or notify-send not available
    [[ "$LOG_NOTIFY" != "true" ]] && return 0
    [[ -z "$NOTIFY_BIN" ]] && return 0

    # Set urgency and icon based on level
    case "$level" in
        FATAL|CRITICAL|ERROR)
            urgency="critical"
            icon="dialog-error"
            ;;
        WARN)
            urgency="normal"
            icon="dialog-warning"
            ;;
        INFO|USAGE|SUCCESS)
            urgency="low"
            icon="dialog-information"
            ;;
        *)
            return 0  # Don't notify for debug
            ;;
    esac

    "$NOTIFY_BIN" -u "$urgency" -i "$icon" "MyDE" "$message" 2>/dev/null
}

# ==================== Core Logging Functions ====================


# Generic log function
# Usage: _log <level_num> <level_name> <color> <message> [options]
_log() {
    local level_num="$1"
    local level_name="$2"
    local color="$3"
    local message="$4" # The message is expected as a single argument here.
    local notify=false
    local custom_context=""
    local formatted
    local context=""

    shift 4 # Shift past level_num, level_name, color, and message

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--notify)
                notify=true
                shift
                ;;
            -c|--context)
                custom_context="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Check log level threshold
    [[ $level_num -lt $LOG_LEVEL ]] && return 0

    # Determine context only if log level is debug
    [[ "$LOG_LEVEL" -eq 0 ]] && {
        if [[ -n "$custom_context" ]]; then
            context="$custom_context"
        else
            if [[ -n "${cmd_map[cmd]}" ]]; then
                context="${cmd_map[cmd]}"
            else
                context="$(_log_detect_context)"
            fi
        fi
    }

    # Format message
    formatted="$(_log_format "$level_name" "$context" "$message" "$color")"

    # Level 1 (eg. INFO/SUCCESS): stdout (user-facing messages)
    # Other levels (eg. DEBUG/WARN/ERROR/FATAL): stderr (diagnostic messages)
    if [[ $level_num -eq 1 ]]; then
        echo -e "$formatted"
    else
        echo -e "$formatted" >&2
    fi

    # Write to log file
    _log_to_file "$formatted"

    # Send notification if requested or for fatal errors
    if [[ "$notify" == "true" ]] || [[ $level_num -ge 4 ]]; then
        _log_notify "$level_name" "$message"
    fi
}

# ==================== Public API ====================

# Debug level (0) - Detailed information for debugging
log.debug() {
    _log 0 "DEBUG" "$COLOR_DEBUG" "$*"
}

# Info level (1) - General informational messages
log.info() {
    _log 1 "INFO" "$COLOR_INFO" "$*"
}

# Success message (always shown, info level)
log.success() {
    _log 1 "SUCCESS" "$COLOR_INFO" "$*"
}

# Show Usage message (info level)
log.usage() {
    _log 1 "USAGE" "$COLOR_INFO" "$*"
}

# Warning level (2) - Warning messages
log.warn() {
    _log 2 "WARN" "$COLOR_WARN" "$*"
}

# Error level (3) - Error messages
log.error() {
    _log 3 "ERROR" "$COLOR_ERROR" "$*"
}

# Fatal level (4) - Fatal errors (auto-notifies)
log.fatal() {
    _log 4 "FATAL" "$COLOR_FATAL" "$*"
    exit 1
}


# ==================== Convenience Functions ====================

# Log with custom context (for when auto-detection isn't suitable)
log.with_context() {
    local context="$1"
    local level="$2"
    shift 2

    case "$level" in
        debug)    log.debug -c "$context" "$@" ;;
        info)     log.info -c "$context" "$@" ;;
        warn)     log.warn -c "$context" "$@" ;;
        error)    log.error -c "$context" "$@" ;;
        fatal)    log.fatal -c "$context" "$@" ;;
        critical) log.critical -c "$context" "$@" ;;
        *)        log.info -c "$context" "$@" ;;
    esac
}

# Set log level dynamically
log.set_level() {
    case "$1" in
        debug)    LOG_LEVEL=0 ;;
        info)     LOG_LEVEL=1 ;;
        warn)     LOG_LEVEL=2 ;;
        error)    LOG_LEVEL=3 ;;
        fatal)    LOG_LEVEL=4 ;;
        *)
            echo "Invalid log level: $1" >&2
            echo "Valid levels: debug, info, warn, error, fatal" >&2
            return 1
            ;;
    esac
}

# Enable/disable colored output
log.set_color() {
    case "$1" in
        on|true|1)  LOG_COLOR=true ;;
        off|false|0) LOG_COLOR=false ;;
        *)
            echo "Usage: log.set_color {on|off}" >&2
            return 1
            ;;
    esac
}

# Enable/disable timestamps
log.set_timestamp() {
    case "$1" in
        on|true|1)  LOG_TIMESTAMP=true ;;
        off|false|0) LOG_TIMESTAMP=false ;;
        *)
            echo "Usage: log.set_timestamp {on|off}" >&2
            return 1
            ;;
    esac
}

# Set log file
log.set_log_file() {
    LOG_FILE="${1:-$LOG_FILE}"
    local log_dir

    # Create log directory if needed
    if [[ -n "$LOG_FILE" ]]; then
        log_dir=$(dirname "$LOG_FILE")
        mkdir -p "$log_dir" 2>/dev/null
    fi
}

log.nyi() {
    log.warn "Not yet Implemented"
}



#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
