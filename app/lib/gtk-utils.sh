#!/usr/bin/env bash

#------------- Configuration -----------------#

GTK_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
GNOME_SCHEMA="org.gnome.desktop.interface"

#------------- Internal Functions ---------------#

_get_gtk_config_value() {
    local key="$1"

    if [ ! -f "$GTK_CONFIG_FILE" ]; then
        log.error "GTK config file not found at $GTK_CONFIG_FILE"
        return 1
    fi

    grep "^$key=" "$GTK_CONFIG_FILE" | sed 's/.*\s*=\s*//'
}

_set_gtk_config_value() {
    local key="$1"
    local value="$2"

    if [ ! -f "$GTK_CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$GTK_CONFIG_FILE")"
    fi

    if ! grep -q "^$key=" "$GTK_CONFIG_FILE" 2>/dev/null; then
        echo "$key=$value" >> "$GTK_CONFIG_FILE"
    else
        sed -i "s|^\($key\s*=\s*\).*|\1$value|" "$GTK_CONFIG_FILE"
    fi
}

#------------- Public API ---------------#

get-gtk-theme(){
    _get_gtk_config_value 'gtk-theme-name'
}

get-gtk-icon-theme(){
    _get_gtk_config_value 'gtk-icon-theme-name'
}

get-gtk-cursor-theme(){
    _get_gtk_config_value 'gtk-cursor-theme-name'
}

get-gtk-cursor-size(){
    _get_gtk_config_value 'gtk-cursor-theme-size'
}

get-gtk-font-name(){
    _get_gtk_config_value 'gtk-font-name' | sed 's/ [0-9\.]*$//'
}

get-gtk-font-size(){
    _get_gtk_config_value 'gtk-font-name' | sed 's/.* \([0-9\.]*\)$/\1/'
}

get-gtk-summary() {
    if [ ! -f "$GTK_CONFIG_FILE" ]; then
        log.error "GTK config file not found at $GTK_CONFIG_FILE"
        return 1
    fi

    echo "GTK Theme: $(get-gtk-theme)"
    echo "Icon Theme: $(get-gtk-icon-theme)"
    echo "Cursor Theme: $(get-gtk-cursor-theme)"
    echo "Cursor Size: $(get-gtk-cursor-size)"
    echo "Font: $(get-gtk-font-name) $(get-gtk-font-size)"
}

set-gtk-theme() {
    local new_theme="$1"

    [ -z "$new_theme" ] && {
        log.error "No theme name provided.";
        return 1;
    }

    log.info "Setting GTK theme to '$new_theme'..."

    gsettings set "$GNOME_SCHEMA" gtk-theme "$new_theme" && \
    _set_gtk_config_value 'gtk-theme-name' "$new_theme" && \
    log.success "GTK theme updated." || \
    {
        log.error "Failed to set GTK theme.";
        return 1;
    }
}

set-gtk-icon-theme() {
    local new_theme="$1"

    [ -z "$new_theme" ] && {
        log.error "No icon theme name provided.";
        return 1;
    }

    log.info "Setting icon theme to '$new_theme'..."
    gsettings set "$GNOME_SCHEMA" icon-theme "$new_theme" && \
    _set_gtk_config_value 'gtk-icon-theme-name' "$new_theme" && \
    log.success "Icon theme updated." || \
    {
        log.error "Failed to set icon theme.";
        return 1;
    }
}

set-gtk-cursor-theme() {
    local new_theme="$1"
    local cursor_size

    cursor_size=$(get-gtk-cursor-size)

    [ -z "$new_theme" ] && { log.error "No cursor theme name provided."; return 1; }

    log.info "Setting cursor theme to '$new_theme'..."

    gsettings set "$GNOME_SCHEMA" cursor-theme "$new_theme" && \
    hyprctl setcursor "$new_theme" "$cursor_size" && \
    _set_gtk_config_value 'gtk-cursor-theme-name' "$new_theme" && \

    log.success "Cursor theme updated." || {
        log.error "Failed to set cursor theme.";
        return 1;
    }
}

set-gtk-cursor-size() {
    local new_size="$1"

    [ -z "$new_size" ] && {
        log.error "No cursor size provided.";
        return 1;
    }

    log.info "Setting cursor size to '$new_size'..."
    gsettings set "$GNOME_SCHEMA" cursor-size "$new_size" && \
    _set_gtk_config_value 'gtk-cursor-theme-size' "$new_size" && \
    log.success "Cursor size updated." || \
    { log.error "Failed to set cursor size."; return 1; }
}

set-gtk-font-name() {
    local new_font_name="$1"
    local font_size
    local new_font

    [ -z "$new_font_name" ] && {
        log.error "No font name provided.";
        return 1;
    }

    font_size=$(get-gtk-font-size)
    new_font="$new_font_name $font_size"

    log.info "Setting font to '$new_font_name'..."

    gsettings set "$GNOME_SCHEMA" font-name "$new_font" && \
    _set_gtk_config_value 'gtk-font-name' "$new_font" && \
    log.success "Font name updated." || \
    { log.error "Failed to set font name."; return 1; }
}

set-gtk-font-size() {
    local new_font_size="$1"
    local font_name
    local new_font

    [ -z "$new_font_size" ] && {
        log.error "No font size provided.";
        return 1;
    }

    font_name=$(get-gtk-font-name)
    new_font="$font_name $new_font_size"

    log.info "Setting font size to '$new_font_size'..."

    gsettings set "$GNOME_SCHEMA" font-name "$new_font" && \
    _set_gtk_config_value 'gtk-font-name' "$new_font" && \
    log.success "Font size updated." || \
    { log.error "Failed to set font size."; return 1; }
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
