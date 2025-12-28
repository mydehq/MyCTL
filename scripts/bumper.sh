#!/bin/bash
#
#  ____
# | __ ) _   _ _ __ ___  _ __   ___ _ __
# |  _ \| | | | '_ ` _ \| '_ \ / _ \ '__|
# | |_) | |_| | | | | | | |_) |  __/ |
# |____/ \__,_|_| |_| |_| .__/ \___|_|
#                      |_|
#
#  CZ Hook for bumping Versions
#

declare -A VERSION_FILES

#================= Configuration =================

NEW_VERSION="${1:-$CZ_PRE_NEW_VERSION}"

VERSION_FILES=(
    ["PKGBUILD"]="s/^ *pkgver=.*/pkgver={{new_version}}/; s/^ *pkgrel=.*/pkgrel=1/"
    ["app/bin/myctl"]="s/^MYCTL_VER=.*/MYCTL_VER='{{new_version}}'/"
    ["install.sh"]="s/^VERSION=.*/VERSION='{{new_version}}'/"
)

#==================== Helpers ======================

#log funcs
log.error() { echo -e "\033[0;31m✗ $1\033[0m" >&2; }
log.info() { echo -e "\033[0;34mℹ $1\033[0m" >&2; }
log.success() { echo -e "\033[0;32m✓ $1\033[0m" >&2; }

# Check if cmd is available
has-cmd() {
  local cmd_str cmd_bin exit_code=0

  [[ "$#" -eq 0 ]] && {
    log.error "No arguments provided."
    return 2
  }

  for cmd_str in "$@"; do
    cmd_bin="${cmd_str%% *}"

    if ! command -v "$cmd_bin" &>/dev/null; then
      exit_code=1
    fi
  done

  return "$exit_code"
}

#==================== Main Logic ======================

#--------------- Check for pwd --------------

if [[ "$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]')" != "$MYCTL_DIR" ]]; then
    log.error "Please run this script from the Root of the project"
    exit 1
fi

#--------- Check if version was passed --------
if [ -z "$NEW_VERSION" ]; then
    log.error "Error: No version argument provided."
    exit 1
fi

#--------- Check Commands ------------
has-cmd sed git || {
    log.error "Missing required commands: git sed"
    exit 1
}
log.success "Required Commands Available: git sed\n"

for file in "${!VERSION_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        log.error "File not found: $file"
        exit 1
    fi

    regex="${VERSION_FILES[$file]}"
    regex="${regex//'{{new_version}}'/$NEW_VERSION}"

    log.info "Bumping file: $file"
    if sed -i "${regex}" "$file"; then
        printf "    "; log.success "Done"
    else
        log.error "Failed to update $file"
        exit 1
    fi
done

log.success "Successfully Bumped '${!VERSION_FILES[*]}'\n"

#----------- Stage Files ----------
log.info "Staging files"
git add "${!VERSION_FILES[@]}" || {
    log.error "Failed to stage files"
    exit 1
}

#------------ Done ---------------
echo
log.success "All files are updated & staged.\n"
