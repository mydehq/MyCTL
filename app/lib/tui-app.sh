#!/usr/bin/env bash
#
#
#==> open-tui [flags] <cmd> [args...]
#
# DESCRIPTION:
#   Open any TUI application in Default/specified terminal emulator.
#   Supports passing Class name & Terminal name.
#
# FLAGS:
#   -e, --exec     Command to run
#   -t, --term     Terminal emulator
#   -c, --class    Application class
#   -p, --pin      Pin the tui window
#   -f, --float    Float the tui window (when needed for pinning)
#   -h, --help     Show this help message
#
# Usage examples:
#   open-tui htop
#   open-tui "bash -c 'tmux new -A -s dev"
#   open-tui -c MyClass -t alacritty -- bash -c 'tmux new -A -s dev'
#   open-tui -c MyClass -t kitty -e htop

#--------------- Config ------------------#
TUI_PIN_CMD="${TUI_PIN_CMD:-hyprctl dispatch pin active}"
TUI_FLOAT_CMD="${TUI_FLOAT_CMD:-hyprctl dispatch setfloating}"
TUI_PIN_FLOAT_NEEDED_MSG="${TUI_PIN_FLOAT_NEEDED_MSG:-Window does not qualify to be pinned}"

#-------------- Functions ------------------#

open-tui() {
    local exec_cmd cmd_bin \
          terminal_cmd="${TERMINAL:-wezterm start}" terminal_bin term_class \
          float_win=false  float_cmd="${TUI_FLOAT_CMD:-hyprctl dispatch setfloating}" float_result \
          pin_win=false pin_result pin_cmd="${TUI_PIN_CMD:-hyprctl dispatch pin}" \
          pin_need_float_msg="${TUI_PIN_FLOAT_NEEDED_MSG:-Window does not qualify to be pinned}"

   [[ $# -eq 0 ]] && {
       log.error "No arguments provided."
       return 1
   }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--term)
                shift_arg || { log.error "No terminal name specified after '-t|--term'"; help_menu; return 1; }
                terminal_cmd="$1"
                ;;
            -c|--class)
                shift_arg || { log.error "No class name specified after '-c|--class'"; help_menu; return 1; }
                term_class="$1"
                ;;
            --|'-e'|--exec)
                shift_arg || { log.error "No command specified after '-e|--exec'"; return 1; }
                exec_cmd="$*"
                break
                ;;
            -p|--pin)
                pin_win=true
                ;;
            -f|--float)
                float_win=true
                ;;
            -h|--help|help)
                help_menu
                ;;
            -*)
                log.error "Unknown option: $1"
                help_menu
                return 1
                ;;
            *)
                exec_cmd="$*"
                break
                ;;
        esac
        shift
    done

    # Extract the bin name
    terminal_bin="${terminal_cmd%% *}"
    cmd_bin="${exec_cmd%% *}"

    log.debug "Using terminal: $terminal_bin"

    # Validate required arguments
    if [[ -z "$exec_cmd" ]]; then
        log.error "No command specified to execute. Use -e/--exec or pass the command after '--'."
        help_menu
        return 1
    fi

    if ! command -v "$terminal_bin" >/dev/null 2>&1; then
        log.error "Terminal '$terminal_bin' not found in PATH."
        help_menu
        return 1
    fi

    [[ -z "$term_class" ]] && term_class="$cmd_bin"
    log.debug "Term class: $term_class"

    exec_cmd="${terminal_cmd} --class $term_class -e $exec_cmd"
    log.debug "Final command: $exec_cmd"

    $exec_cmd >/dev/null 2>&1 & disown || {
        log.error "Failed to launch terminal command."
        return 1
    }

    sleep 0.5

    $float_win && {
        log.debug "float_cmd: $float_cmd class:$term_class"

        float_result="$($float_cmd)" && log.debug "Float Cmd Output: '$float_result'"

        if [[ "$float_result" == "ok" ]]; then
            log.debug "Successfully floated window."
        else
            log.error "Failed to float window."
            log.error "Reason: $float_result"
            return 1
        fi
    }

    $pin_win && {
        log.debug "pin_cmd: $pin_cmd"

        pin_result="$($pin_cmd)" && log.debug "Pin Cmd Output: '$pin_result'"

        if [[ "$pin_result" == "ok" ]]; then
            log.debug "Successfully pinned window with class '$term_class'."
        elif [[ "$pin_result" == "$pin_need_float_msg" ]]; then
            log.warn "Window '$term_class' needs to be floated to be pinned."
        else
            log.error "Failed to pin window."
            log.error "Reason: $pin_result"
            return 1
        fi
    }

    return 0
}



#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
