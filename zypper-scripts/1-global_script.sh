#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"
source "$parent_dir/interaction_fn.sh"


###------ Startup ------###

# skip already installed packages
skip_installed() {

    [[ ! -f "$installed_cache" ]] && touch "$installed_cache"

    if sudo zypper se -i "$1" &> /dev/null; then
        msg skp "$1 is already installed. Skipping..." && sleep 0.1
        if ! grep -qx "$1" "$installed_cache"; then
            echo "$1" >> "$installed_cache"
        fi
    fi
}

# package installation function..
install_package() {

    msg act "Installing $1..."
    sudo zypper in -y "$1"

    if sudo zypper se -i "$1" &> /dev/null ; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe there was an issue..."
    fi
}

# package installation function for devel_basis..
install_package_base() {

    msg act "Installing $1..."
    sudo zypper in -y -t pattern "$1"

    if sudo zypper se -i "$1" &> /dev/null ; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe there was an issue..."
    fi
}

# package installation function no recommends..
install_package_no_recommands() {

    msg act "Installing $1..."
    sudo zypper in -y --no-recommends "$1"
    
    if sudo zypper se -i "$1" &> /dev/null ; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe there was an issue..."
    fi
}

# package installation via opi
install_package_opi() {

    msg act "Installing $1..."
    sudo opi "$1" -n

    if sudo zypper se -i "$1" &> /dev/null ; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe there was an issue..."
    fi
}
