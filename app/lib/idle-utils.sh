#!/usr/bin/env bash

# Idle management utilities for hypridle

#=============== Configuration ===================

IDLE_MANAGER="hypridle"

#=================================================

# Usage: get-inhibitor-stat [-j|--json] [-q|--quiet]
# Returns the status of the idle manager (running = idle allowed, stopped = idle inhibited)
get-inhibitor-stat() {
    local idle_manager="${IDLE_MANAGER}"
    local return_json=false \
          quiet=false

    if [ -z "$idle_manager" ]; then
        log.error "IDLE_MANAGER is not set"
        return 1
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "Usage: get-inhibitor-stat [-j|--json] [-q|--quiet]"
                return 0
                ;;
            -j|--json) return_json=true ;;
            -q|--quiet) quiet=true ;;
            *)
                echo "Invalid arg: $1"
                return 1
                ;;
        esac
        shift
    done

    ! has-cmd "$idle_manager" && {
        ! $quiet && ! $return_json && log.error "$idle_manager is not installed"
        $return_json && echo '{ "status": "error", "text": "", "class": "errored" }'
        return 1
    }

    # Check if idle manager is running using pgrep
    if pgrep -x "$idle_manager" >/dev/null 2>&1; then
        # Idle manager is running - idle is allowed (inhibition is OFF)
        if $return_json; then
            ! $quiet && echo '{ "status": "false", "text": "󰾪", "class": "deactivated" }'
            return 0 
        else
            ! $quiet && echo false
            return 1
        fi
    else
        # Idle manager is stopped - idle is inhibited (inhibition is ON)
        if $return_json; then
            ! $quiet && echo '{ "status": "true", "text": "󰅶", "class": "activated" }'
        else
            ! $quiet && echo true
        fi
        return 0
    fi
}


#=================================================

# Toggle idle inhibition on/off by stopping/starting the idle manager
toggle-idle-inhibitor() {
    local idle_manager="${IDLE_MANAGER}"

    if [ -z "$idle_manager" ]; then
        log.error "IDLE_MANAGER is not set"
        return 1
    fi

    if ! has-cmd "$idle_manager"; then
        notify-send \
            -i dialog-error \
            -u critical \
            -h string:x-canonical-private-synchronous:idle-inhibition \
            -h boolean:transient:true \
            "$idle_manager Not found" "Please install $idle_manager"
        log.error "\n$idle_manager is not installed"
        return 1
    fi

    # Check if hypridle is running using pgrep
    if pgrep -x "$idle_manager" >/dev/null 2>&1; then
        # Idle manager is running, so stop it (prevent system from going idle)
        pkill -x "$idle_manager"
        notify-send \
            -i cs-power \
            -u critical \
            -h string:x-canonical-private-synchronous:idle-inhibition \
            -h boolean:transient:true \
            "Idle Inhibition" "Turned ON"
        log.success "\nIdle Inhibition turned ON"
    else
        # Idle manager is not running, so start it (allow system to go idle)
        $idle_manager &
        notify-send \
            -i battery-profile-powersave \
            -u normal \
            -t 3000 \
            -h string:x-canonical-private-synchronous:idle-inhibition \
            -h boolean:transient:true \
            "Idle Inhibition" "Turned OFF"
        sleep 1
        log.success "\nIdle Inhibition turned OFF"
    fi

    # Refresh waybar if running
    pkill -RTMIN+10 waybar 2>/dev/null || true
}

#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
