#!/bin/env bash

import_lib "hyprlang-utils"

#============= Configuration =============#

SNIP_DEFAULT_MODE="$(read-conf default_ss_mode)"
SNIP_CAPTURE_CMD="grimblast --freeze save"
SNIP_FILE="$(read-conf ss_save_path)/$(read-conf ss_file_name).png"
SNIP_EDITOR_CMD="satty --filename - --output-filename"

#================ Functions ==============#

snip() {
    local mode="${1:-area}" \
          default_mode="$SNIP_DEFAULT_MODE" \
          snip_cmd="$SNIP_CAPTURE_CMD" \
          edit_cmd="$SNIP_EDITOR_CMD"  \
          snip_file="$SNIP_FILE"       \
          final_cmd

    case "$mode" in
        "") mode="$default_mode"
            ;;
        area) mode="area"
            ;;
        active) mode="active"
            ;;
        screen) mode="screen"
            ;;
        *) log.fatal "Invalid mode: $mode"
            ;;
    esac

    log.debug "Mode: $mode"
    log.debug "Output file: $snip_file"
    log.debug "Snipping command: $snip_cmd $mode -"
    log.debug "Editor command: $edit_cmd"

    final_cmd="$snip_cmd $mode - | $edit_cmd $snip_file"  && log.debug "Final command: $final_cmd"

    if ! eval "$final_cmd"; then
        log.fatal "Failed to capture screenshot"
    fi
}


#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
