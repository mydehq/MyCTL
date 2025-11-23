#!/usr/bin/env bash


#==> get-rofi-theme
#
# DESCRIPTION:
#   Get the currently active rofi color theme name
#
# OUTPUT:
#   Prints the current theme name (without .rasi extension)
#   Returns "unknown" if theme cannot be determined
#
get-rofi-theme() {
    local rofi_config="$HOME/.config/rofi/config.rasi"
    local theme

    if [[ ! -f "$rofi_config" ]]; then
        log.error "Rofi config file not found: $rofi_config"
        return 1
    fi

    theme=$(grep -oP '@import ".*?/colors/\K[^"]*(?=\.rasi")' "$rofi_config" 2>/dev/null)

    if [[ -z "$theme" ]]; then
        log.warn "No theme found in config"
        return 1
    fi

    echo "$theme"
    return 0
}


#==> list-rofi-themes
#
# DESCRIPTION:
#   List all available rofi color themes
#
# OUTPUT:
#   Prints one theme name per line (without .rasi extension)
#   Returns 1 if colors directory doesn't exist or is empty
#
list-rofi-themes() {
    local colors_dir="$HOME/.config/rofi/colors"
    local themes

    if [[ ! -d "$colors_dir" ]]; then
        log.error "Theme directory '$colors_dir' not found"
        return 1
    fi

    themes=$(find "$colors_dir" -name "*.rasi" -not -name "README.md" -exec basename {} .rasi \; | sort)

    if [[ -z "$themes" ]]; then
        log.error "No theme files found in $colors_dir"
        return 1
    fi

    echo "$themes"
    return 0
}


#==> set-rofi-theme <theme_name>
#
# DESCRIPTION:
#   set rofi color theme by name
#   Sets the specified theme in rofi config file
#
# ARGUMENTS:
#   theme_name      Name of the theme to apply (without .rasi extension)
#
# FLAGS:
#   -h, --help      Show this help message
#
set-rofi-theme() {
    # Default values
    local rofi_config="$HOME/.config/rofi/config.rasi"
    local colors_dir="$HOME/.config/rofi/colors"
    local theme_name

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "Usage: set-rofi-theme <theme_name>"
                echo ""
                echo "DESCRIPTION:"
                echo "  Change rofi color theme by name"
                echo ""
                echo "ARGUMENTS:"
                echo "  theme_name      Name of the theme to apply (without .rasi extension)"
                echo ""
                echo "Available themes:"
                if list-rofi-themes >/dev/null 2>&1; then
                    list-rofi-themes | sed 's/^/  - /'
                fi
                return 0
                ;;
            -*)
                log.error "Unknown option: $1"
                shift
                return 1
                ;;
            *)
                if [[ -z "$theme_name" ]]; then
                    theme_name="$1"
                else
                    log.error "Multiple theme names provided"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Check if theme name is provided
    if [[ -z "$theme_name" ]]; then
        log.error "Theme name is required"
        log.usage "set-rofi-theme <theme-name>"
        return 1
    fi

    # Validate directories and files
    if [[ ! -d "$colors_dir" ]]; then
        log.error "Colors directory '$colors_dir' not found"
        return 1
    fi

    if [[ ! -f "$rofi_config" ]]; then
        log.error "Rofi config file '$rofi_config' not found"
        return 1
    fi

    #========================== Main Logic =========================

    local theme_path="$colors_dir/$theme_name.rasi"
    local current_theme

    # Check if theme file exists
    if [[ ! -f "$theme_path" ]]; then
        log.error "Theme file '$theme_path' not found"
        echo "Available themes:" >&2
        if list-rofi-themes >/dev/null 2>&1; then
            list-rofi-themes | sed 's/^/  - /' >&2
        fi
        return 1
    fi

    # Get current theme
    current_theme=$(get-rofi-theme)

    # Check if already using this theme
    if [[ "$theme_name" == "$current_theme" ]]; then
        log.info "Theme '$theme_name' is already active"
        return 0
    fi

    # Create backup
    cp "$rofi_config" "$rofi_config.bak" || {
        log.error "Failed to create backup"
        return 1
    }

    # Update the import line
    sed -i "s|@import \".*colors/.*\.rasi\"|@import \"~/.config/rofi/colors/$theme_name.rasi\"|g" "$rofi_config"

    if [[ $? -eq 0 ]]; then
        log.success "Applied theme: $theme_name"
        # Send notification if notify-send is available
        command -v notify-send >/dev/null 2>&1 && \
            notify-send "Rofi Theme" "Applied theme: $theme_name" -i preferences-desktop-theme
        return 0
    else
        # Restore backup on failure
        mv "$rofi_config.bak" "$rofi_config"
        log.error "Failed to apply theme"
        return 1
    fi
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
