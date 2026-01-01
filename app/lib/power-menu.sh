#!/usr/bin/env bash
#
#
#==> show-power-menu [flags]
#
# DESCRIPTION:
#   Shows power management options in rofi menu
#   Includes shutdown, reboot, lock, suspend, logout, and screen off options
#
# FLAGS:
#   -p, --prompt    Prompt text     (default: hostname)
#   -t, --theme     Theme file path (default: ~/.config/rofi/conf/power-menu.rasi)
#   -h, --help      Show this help message
#
show-power-menu() {
    # Default values
    local theme_file="${SRC_DIR}/rofi/power-menu.rasi"
    local prompt_text=""
    local uptime host

    declare -A cmd_str=(
        ["shutdown"]=' ⏼  Shutdown'
        ["reboot"]='   Reboot'
        ["lock"]='   Lock'
        ["screen-off"]=' 󰖦  Screen Off'
        ["suspend"]=' ⏾  Suspend'
        ["logout"]=' 󰗽  Logout'
    )

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--prompt)
                prompt_text="$2"
                shift 2
                ;;
            -t|--theme)
                theme_file="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: show-power-menu [flags]"
                echo ""
                echo "FLAGS:"
                echo "  -p, --prompt    Prompt text     (default: hostname)"
                echo "  -t, --theme     Theme file path (default: $theme_file)"
                echo "  -h, --help      Show this help message"
                return 0
                ;;
            *)
                log.error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # System Information
    uptime="$(uptime -p | sed -e 's/up //g')"
    host=$(hostname)

    # Use hostname as default prompt if not provided
    [[ -z "$prompt_text" ]] && prompt_text="$host"

    # Validate theme file
    if [[ ! -f "$theme_file" ]]; then
        log.error "Rofi theme file '$theme_file' not found"
        return 1
    fi

    # ==================== Helper Functions ======================

    rofi_cmd() {
        rofi -dmenu \
            -p "$prompt_text" \
            -mesg "Uptime: $uptime" \
            -theme "$theme_file"
    }

    # Display rofi menu and get user choice
    run_rofi() {
        local choice
        choice=$(echo -e "${cmd_str[suspend]}\n${cmd_str[shutdown]}\n${cmd_str[lock]}\n${cmd_str[screen-off]}\n${cmd_str[reboot]}\n${cmd_str[logout]}" | rofi_cmd)

        [[ -z "$choice" ]] && return 1

        echo "$choice"
    }

    # ==================== Power Management Functions ======================

    lock-cmd() {
        sleep 0.3
        loginctl lock-session self
    }

    shutdown-cmd() {
        systemctl poweroff
    }

    reboot-cmd() {
        systemctl reboot
    }

    suspend-cmd() {
        playerctl pause
        lock-cmd && sleep 0.3
        systemctl suspend
    }

    screen-off-cmd() {
        lock-cmd
        case "$DESKTOP_SESSION" in
            hyprland*)
                sleep 0.5 && hyprctl dispatch dpms toggle
                ;;
            *)
                log.warn "Screen off is not available in $DESKTOP_SESSION" -n
                return 1
                ;;
        esac
    }

    logout-cmd() {
        if has-cmd loginctl; then
            loginctl terminate-session self
        else
            case "$DESKTOP_SESSION" in
                'plasma')
                qdbus6 org.kde.ksmserver /KSMServer logout 0 0 0
                ;;
                'gnome')
                gnome-session-quit --logout --no-prompt
                ;;
                *-uwsm)
                uwsm stop
                ;;
                'hyprland')
                hyprctl dispatch exit
                ;;
            esac
        fi
    }

    #========================== Main Logic =========================

    # Get user choice and exit if none selected
    local chosen
    chosen="$(run_rofi)"

    [[ -z "$chosen" ]] && return 0

    # Execute the corresponding action based on the chosen display string
    case $chosen in
        "${cmd_str[shutdown]}")
            shutdown-cmd
            ;;
        "${cmd_str[reboot]}")
            reboot-cmd
            ;;
        "${cmd_str[lock]}")
            lock-cmd
            ;;
        "${cmd_str[suspend]}")
            suspend-cmd
            ;;
        "${cmd_str[logout]}")
            logout-cmd
            ;;
        "${cmd_str[screen-off]}")
            screen-off-cmd
            ;;
        *)
            return 1
            ;;
    esac
}



#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
