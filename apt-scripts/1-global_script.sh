#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

red="\e[1;38;2;247;118;142m"
green="\e[1;38;2;166;227;161m"
yellow="\e[1;38;2;224;175;104m"
blue="\e[1;38;2;122;162;247m"
magenta="\e[1;38;2;187;154;247m"
cyan="\e[1;38;2;125;207;255m"
purple="\e[1;38;2;189;147;249m"   # Electric neon purple
lavender="\e[1;38;2;203;166;247m" # Soft lavender
end="\e[0m"

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
parent_dir="$(dirname "$dir")"
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"
source "$parent_dir/interaction_fn.sh"

[[ ! -f "$installed_cache" ]] && touch "$installed_cache"

# Suppress repetitive screen clears if running under TUI
if [[ -n "$HYPRCONF_TUI" || ! -t 1 ]]; then
    clear() { :; }
fi

###------ Startup ------###

# skip already installed packages
skip_installed() {
    [[ ! -f "$installed_cache" ]] && touch "$installed_cache"

    if dpkg -s "$1" &> /dev/null; then
        msg skp "$1 is already installed."
        if ! grep -qx "$1" "$installed_cache"; then
            echo "$1" >> "$installed_cache"
        fi
    fi
}

# package installation function
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
        msg err "$1 failed to install."
    fi
}
