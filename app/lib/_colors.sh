#    ____      _
#  / ___|___ | | ___  _ __ ___
# | |   / _ \| |/ _ \| '__/ __|
# | |__| (_) | | (_) | |  \__ \
# \.____\___/|_|\___/|_|  |___/
#
# MyCTL Colors
# Detect Terminal support level & expor colors
#
# Available Colors:
# _RED,    _GREEN,  _BLUE,
# _CYAN,   _WHITE,  _YELLOW,
# _ORANGE, _PURPLE, _GRAY
#
# Bold Colors:
# _BOLD_RED,    _BOLD_GREEN,  _BOLD_BLUE,
# _BOLD_CYAN,   _BOLD_WHITE,  _BOLD_YELLOW,
# _BOLD_ORANGE, _BOLD_PURPLE, _BOLD_GRAY
#
# Reset Color:
# _NC

#===================== Color Definations ====================

# 8-Bit (256 Colors)
declare -A _colors_8bit=(
    [black]='\033[0;30m'
    [red]='\033[0;31m'
    [green]='\033[0;32m'
    [blue]='\033[0;34m'
    [cyan]='\033[0;36m'
    [white]='\033[0;37m'
    [yellow]='\033[38;5;226m'
    [orange]='\033[38;5;208m'
    [purple]='\033[38;5;93m'
    [gray]='\033[38;5;244m'

    #------- BOLD -------
    [bold_black]='\033[1;30m'
    [bold_red]='\033[1;31m'
    [bold_green]='\033[1;32m'
    [bold_blue]='\033[1;34m'
    [bold_cyan]='\033[1;36m'
    [bold_white]='\033[1;37m'
    [bold_yellow]='\033[1m\033[38;5;226m'
    [bold_orange]='\033[1m\033[38;5;208m'
    [bold_purple]='\033[1m\033[38;5;93m'
    [bold_gray]='\033[1m\033[38;5;244m'

    [nc]='\033[0m'
)

# 4-Bit (16 Colors)
declare -A _colors_4bit=(
    [black]='\033[0;30m'
    [red]='\033[0;31m'
    [green]='\033[0;32m'
    [blue]='\033[0;34m'
    [purple]='\033[0;35m'
    [cyan]='\033[0;36m'
    [white]='\033[0;37m'
    [yellow]='\033[0;33m'
    [orange]='\033[0;33m' # use yellow
    [gray]='\033[0;30m'

    #------ BOLD -------
    [bold_black]='\033[1;30m'
    [bold_red]='\033[1;31m'
    [bold_green]='\033[1;32m'
    [bold_blue]='\033[1;34m'
    [bold_purple]='\033[1;35m'
    [bold_cyan]='\033[1;36m'
    [bold_white]='\033[1;37m'
    [bold_yellow]='\033[1;33m'
    [bold_orange]='\033[1;33m'
    [bold_gray]='\033[1;30m'

    [nc]='\033[0m'
)


#===================== Export Logic ====================

export-color-codes() {
    local color_map_ref="4BIT" col_key col_value

    # Check for 256color support
    if [[ "$TERM" == *256color* ]]; then
        color_map_ref="_colors_8bit"
        export COLOR_MODE="8BIT"
    else
        color_map_ref="_colors_4bit"
        export COLOR_MODE="4BIT"
    fi

    # Use Bash nameref to select the correct map
    declare -n selected_ref_map="$color_map_ref"

    for key in "${!selected_ref_map[@]}"; do

        # Get the value (ANSI code)
        col_value="${selected_ref_map[$key]}"

        # Convert the key to uppercase and add the underscore prefix
        col_key="_$(echo "$key" | tr '[:lower:]' '[:upper:]')"

        export "$col_key"="$col_value"
    done
}

echo-all-colors() {
    echo -e "${_RED}Red${_NC} | ${_ORANGE}Orange${_NC} | ${_BLUE}Blue${_NC} | ${_GREEN}Green${_NC} | ${_YELLOW}Yellow${_NC} | ${_CYAN}Cyan${_NC} | ${_PURPLE}Purple${_NC} | ${_GRAY}Gray${_NC} | "
    echo -e "${_BOLD_RED}Red${_NC} | ${_BOLD_ORANGE}Orange${_NC} | ${_BOLD_BLUE}Blue${_NC} | ${_BOLD_GREEN}Green${_NC} | ${_BOLD_YELLOW}Yellow${_NC} | ${_BOLD_CYAN}Cyan${_NC} | ${_BOLD_PURPLE}Purple${_NC} | ${_BOLD_GRAY}Gray${_NC} | "
}




#============== Export Colors ===============
export-color-codes
