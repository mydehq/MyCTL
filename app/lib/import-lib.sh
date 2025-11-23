
import_lib() {
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
                    import_lib - Import library files with tracking

                Usage:
                    import_lib [library1] [library2]        Import one or more libraries
                    import_lib --check|-c <library>         Check if library is imported
                    import_lib --list|-l                    List all imported libraries
                    import_lib --help|-h                    Show this help
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

    # Handle different modes
    case "$mode" in
        list)

            if [[ ${#IMPORTED_LIBS[@]} -eq 0 ]]; then
                log.debug "No libraries imported yet."
                return 0
            fi

            for lib_path in "${!IMPORTED_LIBS[@]}"; do

                local display_name resolved_lib_dir

                resolved_lib_dir=$(realpath "$LIB_DIR" 2>/dev/null || echo "$LIB_DIR")

                # Check if it's in the standard lib directory (using resolved paths)
                if [[ "$lib_path" == "$resolved_lib_dir"/* ]]; then
                    # Extract just the filename, remove .sh extension if present
                    display_name=$(basename "$lib_path" .sh)
                elif [[ "$lib_path" == *"$LIB_DIR"* ]]; then
                    # Handle relative lib paths
                    display_name=$(basename "$lib_path" .sh)
                else
                    # For non-standard paths, show relative path if possible
                    if [[ "$lib_path" == "$PWD"/* ]]; then
                        # Show relative to current directory
                        display_name="${lib_path#$PWD/}"
                    else
                        # Show the full path for absolute paths outside current dir
                        display_name="$lib_path"
                    fi
                fi

                echo "$display_name"
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

                        log.debug "Attempting to source $p"
                        if source "$p"; then
                            log.debug "Successfully sourced $p"
                            log.debug "Running awk to find functions..."

                            # Export all functions defined in library file
                            while IFS= read -r func_name; do
                                if [[ -n "$func_name" ]]; then
                                    log.debug "Exporting function: $func_name"
                                    export -f $func_name
                                fi
                            done < <(extract_method_names "$p")

                            IMPORTED_LIBS["$resolved_path"]=1
                            found=true

                        else
                            log.debug "Failed to source $p"
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
