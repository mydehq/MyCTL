
# Usage:
#       import-lib [library1] [library2]        Import one or more libraries
#       import-lib --check|-c <library>         Check if library is imported
#       import-lib --list|-l                    List all imported libraries
#       import-lib --help|-h                    Show this help
import-lib() {
    local mode="import"
    local lib_files=()
    local target_paths=()
    local lib_file

    # Parse flags
    while [ $# -gt 0 ]; do
        case "$1" in
            --check|-c)
                mode="check"
                shift
                [ -z "$1" ] && {
                    log.error "No library file specified for --check."
                    exit 1
                }
                lib_files=("$1")
                shift
                ;;
            --list|-l)
                mode="list"
                shift
                ;;
            --help|-h)
                cat << 'EOF'
                    import-lib - Import library files with tracking

                Usage:
                    import-lib [library1] [library2]        Import one or more libraries
                    import-lib --check|-c <library>         Check if library is imported
                    import-lib --list|-l                    List all imported libraries
                    import-lib --help|-h                    Show this help
EOF
                return 0
                ;;
            -*)
                log.error "Unknown flag: $1"
                exit 1
                ;;
            *)
                lib_files+=("$1")
                shift
                ;;
        esac
    done

    # Helper to get display name
    _get_lib_display_name() {
        local lib_path="$1"
        local display_name resolved_lib_dir

        resolved_lib_dir=$(realpath "$LIB_DIR" 2>/dev/null || echo "$LIB_DIR")

        if [[ "$lib_path" == "$resolved_lib_dir"/* ]]; then
            display_name=$(basename "$lib_path" .sh)
        elif [[ "$lib_path" == *"$LIB_DIR"* ]]; then
            display_name=$(basename "$lib_path" .sh)
        else
            if [[ "$lib_path" == "$PWD"/* ]]; then
                display_name="${lib_path#"$PWD"/}"
            else
                display_name="$lib_path"
            fi
        fi
        echo "$display_name"
    }

    # Handle different modes
    case "$mode" in
        list)

            if [[ ${#IMPORTED_LIBS[@]} -eq 0 ]]; then
                log.debug "No libraries imported yet."
                return 0
            fi

            for lib_path in "${!IMPORTED_LIBS[@]}"; do
                echo "$(_get_lib_display_name "$lib_path")"
            done
            return 0
            ;;
        check)
            [ -z "${lib_files[0]}" ] && {
                log.error "No library file specified to check."
                return 1
            }

            lib_file="${lib_files[0]}"

            if [[ "$lib_file" == */* || "$lib_file" == /* ]]; then
                target_paths+=("$lib_file")
                [[ "$lib_file" != *.sh ]] && target_paths+=("${lib_file}.sh")
            else
                target_paths+=("${LIB_DIR}/${lib_file}")
                [[ "$lib_file" != *.sh ]] && target_paths+=("${LIB_DIR}/${lib_file}.sh")
            fi

            for p in "${target_paths[@]}"; do
                if [ -f "$p" ]; then
                    local resolved_path
                    resolved_path=$(realpath "$p")
                    [[ -v "IMPORTED_LIBS[$resolved_path]" ]] && return 0
                    break
                fi
            done
            return 1
            ;;

       import)
            [ ${#lib_files[@]} -eq 0 ] && {
                log.error "No library file(s) specified to import."
                exit 1
            }

            for lib_file in "${lib_files[@]}"; do
                [ -z "$lib_file" ] && continue

                target_paths=()

                if [[ "$lib_file" == */* || "$lib_file" == /* ]]; then
                    target_paths+=("$lib_file")
                    [[ "$lib_file" != *.sh ]] && target_paths+=("${lib_file}.sh")
                else
                    target_paths+=("${LIB_DIR}/${lib_file}")
                    [[ "$lib_file" != *.sh ]] && target_paths+=("${LIB_DIR}/${lib_file}.sh")
                fi

                local found=false
                local resolved_path=""

                for p in "${target_paths[@]}"; do
                    [ -f "$p" ] && {
                        resolved_path=$(realpath "$p")

                        # Check if already imported
                        if [[ -v "IMPORTED_LIBS[$resolved_path]" ]]; then
                            found=true
                            break
                        fi

                        local pretty_name="$(_get_lib_display_name "$p")"

                        if source "$p"; then
                            # Export all functions defined in library file
                            while IFS= read -r func_name; do
                                if [[ -n "$func_name" ]]; then
                                    export -f "$func_name"
                                fi
                            done < <(extract-method-names "$p")

                            IMPORTED_LIBS["$resolved_path"]=1
                            found=true
                            log.debug "Successfully sourced $pretty_name"

                        else
                            log.debug "Failed to source $pretty_name"
                        fi
                        break
                    }
                done

                [ "$found" = false ] && {
                    log.error "Library file '${lib_file}' not found."
                    exit 1
                }
            done
            return 0
            ;;
    esac
}



#--------------- If executed directly ----------------------

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is part of myctl lib."
    echo "Use 'myctl help' for more info."
fi
