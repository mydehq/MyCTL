#!/bin/env bash

#========================= Configuration =========================#

MAX_VOLUME=${MAX_VOLUME:-153}
MAX_MIC=${MAX_MIC:-$MAX_VOLUME}

#========================= Functions =========================#

# set readonly
readonly MAX_VOLUME MAX_MIC

get-volume() {
    local mic=false volume
    local wpctl_device="@DEFAULT_AUDIO_SINK@"

    # Enable quiet mode to prevent log contamination of return value
    local old_quiet_mode="$MYCTL_QUIET_MODE"
    export MYCTL_QUIET_MODE="true"

    case "$1" in
        -m|--mic)
            mic=true
            wpctl_device="@DEFAULT_AUDIO_SOURCE@"
            ;;
    esac

    # Use wpctl to get the volume and convert the reported fractional value to percent
    # Add 0.5 before converting to int.
    volume="$(
        wpctl get-volume "$wpctl_device" \
            | awk '{ printf("%d", ($2 * 100) + 0.5) }'
    )"

    # Restore previous quiet mode state
    export MYCTL_QUIET_MODE="$old_quiet_mode"

    [ -z "$volume" ] && log.error "Failed to get volume level." && return 1

    echo "$volume"
}

# get-mute [-m|--mic]
# Return: "true" if muted, else "false"
get-mute() {
    local mic=false status
    local wpctl_device="@DEFAULT_AUDIO_SINK@"

    # Enable quiet mode to prevent log contamination of return value
    local old_quiet_mode="$MYCTL_QUIET_MODE"
    export MYCTL_QUIET_MODE="true"

    case "$1" in
        -m|--mic)
            mic=true
            wpctl_device="@DEFAULT_AUDIO_SOURCE@"
            ;;
    esac

    status="$(wpctl get-volume $wpctl_device | grep -o 'MUTED')"

    # Restore previous quiet mode state
    export MYCTL_QUIET_MODE="$old_quiet_mode"

    { [[ "$status" == "MUTED" ]] && echo "true"; } || {
        echo "false"
        return 1
    }
}

# set-mute [-m|--mic] [-u] [-t]
set-mute() {
    local mic=false mic_flag action=1 cmd_str
    local wpctl_device="@DEFAULT_AUDIO_SINK@"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -m|--mic)
                mic=true
                mic_flag="-m"
                wpctl_device="@DEFAULT_AUDIO_SOURCE@"
                ;;
            -u|--unmute)
                action=0
                ;;
            -t|--toggle)
                action="toggle"
                ;;
            *)
                invalid-cmd && help-menu
                ;;
        esac
        shift
    done

    cmd_str="wpctl set-mute $wpctl_device $action" && log.debug "Final command: '$cmd_str'"

    if eval "$cmd_str"; then
        return 0
    else
        log.error "Failed to set mute via wpctl"
        return 1
    fi
}


# Usage: set-volume [-m|--mic] [+\-]<level> | <exact_level>
set-volume() {
    local change symbol direction req_level current_level new_level
    local mic=false mic_flag device

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -m|--mic)
                mic=true
                ;;
            *)
                if [[ "$1" =~ ^[+-][0-9]+$ ]]; then
                    direction="${1:0:1}"
                    change="${1:1}"
                elif [[ "$1" =~ ^[0-9]+$ ]]; then
                    req_level="$1"
                else
                    log.error "Invalid volume argument: '$1'. Expected +<level>, -<level>, or <level>."
                    return 1
                fi
                ;;
        esac
        shift
    done

    log.debug "0. Requested Level: $req_level, Change: $change, direction: $direction"

    # Determine Max Limit and Target Device
    if "$mic"; then
        mic_flag="-m"
        max_limit=$MAX_MIC
        device="@DEFAULT_AUDIO_SOURCE@"
        current_level=$(get-volume -m)
    else
        max_limit=$MAX_VOLUME
        device="@DEFAULT_AUDIO_SINK@"
        current_level=$(get-volume)
    fi

    log.debug "1. Current Level: $current_level, Change: $change,  req_level: $req_level, Current Level: $current_level"

    # Validate current level
    ! [[ "$current_level" =~ ^[0-9]+$ ]] && {
        log.error "Unable to parse current volume level: '$current_level'."
        return 2
    }

    # Determine requested level
    if [ "$direction" == "+" ]; then
        [ -z "$req_level" ] && req_level=$((current_level + change))
    else
        [ -z "$req_level" ] && req_level=$((current_level - change))
    fi

    log.debug "2. Current Level: $current_level, Change: $change,  req_level: $req_level, Current Level: $current_level"

    # Clamp requested level to valid range [0, max_limit]
    if (( req_level > max_limit )); then
        log.warn "Max Volume limit: $max_limit"
        req_level=$max_limit
    elif (( req_level < 0 )); then
        req_level=0
    fi

    log.debug "Final: Current Level: $current_level, Change: $change,  req_level: $req_level, Current Level: $current_level"

    if ! wpctl set-volume "$device" "${req_level}%"; then
        log.error "Failed to Set volume via wpctl"
        return 3
    else
        if [ "$(get-volume $mic_flag)" != "$req_level" ]; then
            log.error "Volume set verification failed. Expected: $req_level, Got: $(get-volume)"
            return 4
        fi
    fi

    self show wobar "$req_level"
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
