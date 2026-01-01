#!/bin/bash

set -e

#-------- Configuration --------

PROJ_NAME='myctl'
VERSION='1.11.2'

TARBALL_NAME="${PROJ_NAME,,}-${VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/mydehq/$PROJ_NAME/releases/download/v${VERSION}/${TARBALL_NAME}"

TMP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/${PROJ_NAME}-installer"
INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}"

BIN_DIR="$INSTALL_ROOT/../bin"
LIB_DIR="$INSTALL_ROOT/../lib/$PROJ_NAME"
SRC_DIR="$INSTALL_ROOT/../src/$PROJ_NAME"
ICON_DIR="$INSTALL_ROOT/icons"
MODULE_DIR="$INSTALL_ROOT/$PROJ_NAME/modules"

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/${PROJ_NAME}"


#-------------- Helper Functions ---------------

#log func
log.error() { echo -e "\033[0;31m✗ $1\033[0m" >&2; }
log.info() { echo -e "\033[0;34mℹ $1\033[0m" >&2; }
log.warn() { echo -e "\033[0;33m⚠ $1\033[0m" >&2; }
log.success() { echo -e "\033[0;32m✓ $1\033[0m" >&2; }

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

path-contains() {
  local needle="$1"
  local dir canon_needle canon_dir

  # Expand ~
  [[ "$needle" == "~/"* ]] && needle="$HOME/${needle#~/}"

  # Convert to absolute + canonical path
  canon_needle="$(realpath -m "$needle" 2>/dev/null)" || return 1

  IFS=':' read -r -a _path_dirs <<< "$PATH"
  for dir in "${_path_dirs[@]}"; do
    canon_dir="$(realpath -m "$dir" 2>/dev/null)" || continue
    [[ "$canon_dir" == "$canon_needle" ]] && return 0
  done

  return 1
}

add-to-path() {
  local path_to_add="$1"
  local shell rc_file

  [[ "$path_to_add" == "~/"* ]] && path_to_add="$HOME/${path_to_add#~/}"
  path_to_add="$(realpath -m "$path_to_add")"

  path-contains "$path_to_add" && return 0

  shell="$(basename "$(getent passwd "$USER" | cut -d: -f7)")"

  case "$shell" in
    bash)
      rc_file="$HOME/.bashrc"
      ;;
    zsh)
      rc_file="$HOME/.zshrc"
      ;;
    fish)
      fish -c "fish_add_path $path_to_add" || return 0
      ;;
    *)
      echo "Unknown shell ($shell). Please add $path_to_add to PATH manually."
      return 1
      ;;
  esac

  {
    echo ""
    echo "# Added by myctl"
    echo "export PATH=\"$path_to_add:\$PATH\""
  } >> "$rc_file"
}


#-------------- Main Logic ---------------

echo

if ! path-contains "${BIN_DIR}"; then
    log.warn "$BIN_DIR is not in PATH."

    log.info "Adding to PATH..."
    add-to-path "$BIN_DIR" || {
        log.error "Failed to add $BIN_DIR to PATH."
        exit 1
    }
    log.success "Done"
    export PATH="$BIN_DIR:$PATH"
fi

if has-cmd myctl; then
    log.warn "myctl is already installed."

    log.info "Checking for Updates..."

    local_ver=$(myctl version) || {
        log.error "Failed to get local version."
        exit 1
    }

    local_ver=${local_ver##*v}
    local_ver=${local_ver%% *}

    if [[ "$local_ver" != "$VERSION" ]]; then
        log.warn "New version available. ($local_ver -> $VERSION)"
        _message="Starting Updating..."
    else
        log.success "myctl is up to date."
        exit 0
    fi
fi

log.info "${_message:-Starting installation...}"

log.info "Creating required directories..."
mkdir -p "${BIN_DIR}" "${TMP_DIR}" "${LIB_DIR}" "${SRC_DIR}" "${MODULE_DIR}" "${ICON_DIR}" "${CONF_DIR}" || {
    log.error "Failed to create Required directories."
    exit 1
}
log.success "Done"

log.info "Downloading $TARBALL_NAME..."
curl -fL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${TARBALL_NAME}" || {
    log.error "Failed to download $PROJ_NAME Tarball."
    exit 1
}
log.success "Done"

log.info "Extracting binary tarball..."
tar -xf "${TMP_DIR}/${TARBALL_NAME}" -C "${TMP_DIR}" --strip-components=1 || {
    log.error "Failed to extract $PROJ_NAME binary."
    exit 1
}
log.success "Done"

log.info "copying binary(s)..."
cp --no-preserve=ownership "${TMP_DIR}/bin/"* "${BIN_DIR}/"
for bin in "${TMP_DIR}/bin/"*; do
    chmod +x "${BIN_DIR}/$(basename "$bin")"
done

log.info "Copying Libraries..."
cp -r --no-preserve=ownership "${TMP_DIR}/lib/"* "${LIB_DIR}/"

log.info "Copying Src files..."
cp -r --no-preserve=ownership "${TMP_DIR}/src/"* "${SRC_DIR}/"

log.info "Copying Icons..."
cp --no-preserve=ownership "${TMP_DIR}/icons/icon.svg" "${ICON_DIR}/$PROJ_NAME.svg"

# log.info "Copying Modules..."
# cp -r --no-preserve=ownership "${TMP_DIR}/modules/"* "${MODULE_DIR}/"

echo
log.success "Installation Completed Successfully"
