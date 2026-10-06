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


# skip already insalled packages
skip_installed() {

    [[ ! -f "$installed_cache" ]] && touch "$installed_cache"

    if dpkg -s "$1" &> /dev/null; then
        msg skp "$1 is already installed. Skipping..." && sleep 0.1
        if ! grep -qx "$1" "$installed_cache"; then
            echo "$1" >> "$installed_cache"
        fi
    fi
}

# package installation function..
install_package() {

    msg act "Installing $1..."

    is_debian_13=false
    if grep -qiE 'trixie|version_id="?13"?' /etc/os-release 2>/dev/null; then
        is_debian_13=true
    fi

    if [[ "$is_debian_13" == true ]]; then
        sudo apt-get install -y -t trixie-backports "$1" || sudo apt-get install -y "$1"
    else
        sudo apt-get install -y "$1"
    fi
    
    if dpkg -s "$1" &> /dev/null ; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe there was an issue..."
    fi
}
