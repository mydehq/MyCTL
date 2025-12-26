#!/bin/env bash

get-distro() {
    local distro_name

    if [ -z "$DISTRO_NAME" ]; then
        if [ -f /etc/os-release ]; then
            distro_name="$(source /etc/os-release && echo "$ID")"
        else
            log.error "/etc/os-release not found"
            log.fatal "Failed to detect distro"
        fi
    else
        [ -n "$DISTRO_NAME" ] && distro_name="$DISTRO_NAME"
    fi

    if [ -z "$distro_name" ]; then
        log.fatal "Unsupported Linux distribution."
    fi

    echo "$distro_name"
}

# auto avail distro name
DISTRO_NAME="$(get-distro)" && declare -rx DISTRO_NAME

# get-distro-base [<distro>]
# Auto detects current distro if not provided
# shellcheck disable=SC2120
get-distro-base() {
    local distro_name distro_base

    if [ "$#" -eq 0 ]; then
        distro_name="$(get-distro)"
    elif [ "$#" -eq 1 ]; then
        distro_name="$1"
    else
        log.fatal "Only 1 argument is allowed."
    fi

    case "$distro_name" in
        arch|arch32|archcraft|blackarch|cachyos|chimeraos|endeavouros|rebornos|steamos)
            distro_base="arch"
            ;;
        alpine)
            distro_base="alpine"
            ;;
        debian|devuan|kali|parrot|pika|raspbian|tails|trisquel)
            distro_base="debian"
            ;;
        fedora|amzn|aurora|bazzite|bluefin|ultramarine)
            distro_base="fedora"
            ;;
        opensuse|opensuse-leap|opensuse-tumbleweed)
            distro_base="opensuse"
            ;;
        rhel|almalinux|centos|clearos|eurolinux|miraclelinux|rocky|scientific)
            distro_base="rhel"
            ;;
        ubuntu|bodhi|elementary|linuxmint|pop|endless|zorin|neon)
            distro_base="ubuntu"
            ;;
        *)
            log.fatal "Unsupported Linux distribution: $distro_name"
            ;;
    esac

    if [ -n "$distro_base" ]; then
        log.debug "Distro base: $distro_base"
        echo "$distro_base"
    else
        log.fatal "Failed to determine distro base."
    fi
}


# get-pkg-manager [<distro>] - Auto detects current distro if not provided
# Supported pkg managers:
#               apt, apk, dnf, [paru, yay, pacman], flatpak, snap, brew
# Falls back to:
#               flatpak/snap/brew - if distro pkg manager is not found/supported
get-pkg-manager() {
    local distro distro_base pkg_manager

    if [ "$#" -eq 0 ]; then
        distro="$DISTRO_NAME"
    elif [ "$#" -eq 1 ]; then
        distro="$1"
    else
        log.fatal "Only 1 argument is allowed."
    fi


    distro_base="$(get-distro-base "$distro")" || exit 1  # Distro will be added if given else current will be detected

    case "$distro_base" in
        arch)
            case $distro in
                # some immutable distros doesn't allow package managers
                steamos)
                    pkg_manager="flatpak"
                    ;;
                *)
                    if has-cmd paru; then
                        pkg_manager="paru"
                    elif has-cmd yay; then
                        pkg_manager="yay"
                    elif has-cmd pacman; then
                        pkg_manager="pacman"
                    fi
                    ;;
            esac
            ;;
        alpine)
            pkg_manager="apk"
            ;;
        debian|ubuntu)
            pkg_manager="apt"
            ;;
        fedora|rhel)
            case $distro in
                aurora|bazzite|bluefin)
                    pkg_manager="flatpak"
                    ;;
                *)
                    pkg_manager="dnf"
                    ;;
            esac
            ;;
        opensuse)
            pkg_manager="zypper"
            ;;
        *)
            log.debug "Unsupported distro: $distro"
            ;;
    esac

    # Check if primary package manager is available
    if [ -n "$pkg_manager" ] && has-cmd "$pkg_manager"; then
        echo "$pkg_manager"
        return 0
    fi

    log.debug "Primary package manager not available"
    log.debug "Checking global package managers"

    # Fall back to global package managers
    for gbl_pm in flatpak snap brew; do
        if has-cmd "$gbl_pm"; then
            echo "$gbl_pm"
            return 0
        fi
    done

    log.fatal "No supported package managers found."
}


pkg-add() {
    log.nyi
}


pkg-remove() {
    log.nyi
}
