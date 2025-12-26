#  _                    _
# | |    ___   __ _  __| | ___ _ __
# | |   / _ \ / _` |/ _` |/ _ \ '__|
# | |__| (_) | (_| | (_| |  __/ |
# |_____\___/ \__,_|\__,_|\___|_|
#
# Load All components of MyCTL


#=================== Helper Functions ====================

# Usage: extract-method-names <lib_file_path>
extract-method-names() {
    local file_path="$1"
    local awk_script="${SRC_DIR}/extract-method-names.awk"

    # Validate input
    [[ -z "$file_path" ]] && {
        _elog "ERROR: No file path provided to extract-method-names"
        return 1
    }

    [[ ! -f "$file_path" ]] && {
        _elog "ERROR: File not found: $file_path"
        return 1
    }

    [[ ! -f "$awk_script" ]] && {
        _elog "ERROR: AWK script not found: $awk_script"
        return 1
    }

    # Extract function names using the AWK script
    awk -f "$awk_script" "$file_path"
}

# Usage: export-lib-methods <lib_file_path>
export-lib-methods() {
    local file_path="$1"

    while IFS= read -r method_name; do
        [ -n "$method_name" ] && \
        export -f $method_name
    done < <(extract-method-names "$file_path")
}


#=================== Load Components ====================

[[ -z "$LIB_DIR" ]] && {
    _elog "ERROR: LIB_DIR is not set"
    exit 1
}

for lib_name in colors logger import-lib; do

    _lib_path="${LIB_DIR}/${lib_name}.sh"

    if [[ -f "$_lib_path" ]]; then
        if source "$_lib_path"; then
            export-lib-methods "$_lib_path"
            IMPORTED_LIBS["$(realpath "$_lib_path")"]=1
        else
            _elog "FATAL: Failed to source ${lib_name} from '$_lib_path'"
            exit 1
        fi
    else
        _elog "FATAL: Cannot load ${lib_name} from '$_lib_path'"
        exit 1
    fi
done

unset _lib_path
