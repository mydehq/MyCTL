#!/usr/bin/env bash

# Show a wob-style on-screen display (OSD) bar for levels

# =================== Configuration ====================#

 WOB_MAX_LEVEL="${WOB_MAX_LEVEL:-200}"
 WOB_INFO_FILE="${WOB_INFO_FILE:-$LOG_DIR/wob-pipe.info}"

# =================== Functions ====================#

# Check If wob daemon is running; if not, start it
start-wob-daemon() {
    local wob_pipe="/tmp/${HYPRLAND_INSTANCE_SIGNATURE:-myde_$(date +%s)}.wob"

    command -v wob >/dev/null 2>&1 || {
        log.fatal "wob not found. Please install wob"
    }

    log.debug "Wob pipe: '$wob_pipe'"

    echo "$wob_pipe" > "$WOB_INFO_FILE"

    if [ -e "$wob_pipe" ] && [ ! -p "$wob_pipe" ]; then
        log.error "$wob_pipe exists but is not a FIFO pipe!"
        rm "$wob_pipe" && mkfifo "$wob_pipe"
    elif [ ! -p "$wob_pipe" ]; then
        log.info "Creating FIFO pipe at $wob_pipe"
        mkfifo "$wob_pipe"
    fi

    # Check if the daemon is already running
    pgrep -f "tail -f $wob_pipe" >/dev/null && {
        log.info "Wob daemon is already running."
        return 0
    }

    # Launch the daemon
    log.debug "Starting wob daemon... "

    tail -f "$wob_pipe" | wob & disown || {
        log.error "Failed to start wob daemon."
        return 1
    }
}


# show-wobar <level>
show-wobar() {
    local level="$1" max_level=${WOB_INFO_FILE:-199} wob_pipe="" max_level="$WOB_MAX_LEVEL"

    [ -z "$level" ] && {
        log.fatal "No level specified for wob OSD."
    }

    ! [[ "$level" =~ ^[0-9]+$ ]] && {
        log.fatal "Invalid level: '$level'. Must be a non-negative integer."
    }

    (( level > max_level )) && {
        level=$max_level
    }

    if [ -f "$WOB_INFO_FILE" ]; then
        wob_pipe=$(<"$WOB_INFO_FILE")
    else
        log.error "Wob info file not found at $WOB_INFO_FILE"

        log.info "Starting wob daemon..."
        start-wob-daemon || log.fatal "Failed to start wob daemon."
        wob_pipe=$(<"$WOB_INFO_FILE")
    fi

    log.debug "wob_pipe: $wob_pipe"

    [ "$wob_pipe" == "" ] && {
        log.fatal "Wob pipe path is empty."
    }

    echo "$level" > "$wob_pipe" || {
        log.error "Failed to write level to wob pipe at '$wob_pipe'."
        return 1
    }

    log.debug "Wob pipe read from info file: '$wob_pipe'"

}



#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
