#!/usr/bin/env bash
#
#
#==> show-keybinds-menu [flags]
#
# DESCRIPTION:
#   Parse keybinds markdown file and display in rofi menu with formating
#   Use <!-- SKIP_START --> & <!-- SKIP_END --> to skip sections in the keybinds.md
#
# FLAGS:
#   -f, --file      Keybinds file path
#   -p, --prompt    Prompt text
#   -t, --theme     Theme file path
#   -a, --awk       AWK script path
#   -h, --help      Show this help message
#
show-keybinds-menu() {
    # Default values
    local keybinds_file="$MYDE_DIR/wiki/docs/user-guide/keybinds.md"
    local theme_file="${SRC_DIR}/rofi/keybinds-menu.rasi"
    local awk_script_path="${SRC_DIR}/parse-keybinds.awk"
    local prompt_text="Keybinds Help"
    local keybinds

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -kf|--keybinds-file)
                keybinds_file="$2"
                shift 2
                ;;
            -p|--prompt)
                prompt_text="$2"
                shift 2
                ;;
            -t|--theme)
                theme_file="$2"
                shift 2
                ;;
            -a|--awk)
                awk_script_path="$2"
                shift 2
                ;;
            *)
                log.error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Validate input
    if [[ ! -f "$keybinds_file" ]]; then
        log.error "Keybinds file '$keybinds_file' not found"
        return 1
    fi

    if [[ ! -f "$theme_file" ]]; then
        log.error "Rofi theme file '$theme_file' not found"
        return 1
    fi

    # ================ Parsing Logic ================

    # Check if AWK script exists
    if [[ ! -f "$awk_script_path" ]]; then
        log.error "AWK script not found at '$awk_script_path'"
        return 1
    fi

    keybinds=$(awk -f "$awk_script_path" "$keybinds_file")

    # ================ Display Rofi ================

    log.debug "Theme file:    $theme_file"
    log.debug "Keybinds file: $keybinds_file"
    log.debug "AWK script:    $awk_script_path"
    log.debug "Prompt text:   $prompt_text"

    if [[ -n "$keybinds" ]]; then
        echo -e "$keybinds" | rofi \
            -dmenu \
            -i \
            -markup-rows \
            -p "$prompt_text" \
            -theme "$theme_file" >/dev/null 2>&1
    else
        log.error "No keybinds found"
        return 1
    fi
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
