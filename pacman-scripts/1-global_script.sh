#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
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

get_aur_helper() {
    local pref=""
    if [[ -f "$aur_cache" ]]; then
        pref=$(tr -d '[:space:]' < "$aur_cache" 2>/dev/null)
    elif [[ -f "$cache_dir/aur" ]]; then
        pref=$(tr -d '[:space:]' < "$cache_dir/aur" 2>/dev/null)
    fi

    if [[ "$pref" == "paru" ]] && command -v paru &>/dev/null; then
        echo "paru"
    elif [[ "$pref" == "yay" ]] && command -v yay &>/dev/null; then
        echo "yay"
    elif [[ "$pref" == "Skip" ]]; then
        echo ""
    elif command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

aur_helper=$(get_aur_helper)

# skip already installed packages
skip_installed() {
    [[ ! -f "$installed_cache" ]] && touch "$installed_cache"
    [[ -z "$aur_helper" ]] && aur_helper=$(get_aur_helper)

    if pacman -Q "$1" &> /dev/null || ([[ -n "$aur_helper" ]] && "$aur_helper" -Q "$1" &> /dev/null); then
        msg skp "$1 is already installed."
        if ! grep -qx "$1" "$installed_cache"; then
            echo "$1" >> "$installed_cache"
        fi
    fi
}

# package installation function
install_package() {
    msg act "Installing $1..."
    [[ -z "$aur_helper" ]] && aur_helper=$(get_aur_helper)

    if [[ -n "$aur_helper" ]]; then
        "$aur_helper" -S --noconfirm "$1" &> /dev/null
    else
        sudo pacman -S --needed --noconfirm "$1" &> /dev/null
    fi

    if pacman -Q "$1" &> /dev/null || ([[ -n "$aur_helper" ]] && "$aur_helper" -Q "$1" &> /dev/null); then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install."
    fi
}

# package installation function with nocheck
install_package_nocheck() {
    msg act "Installing $1..."
    [[ -z "$aur_helper" ]] && aur_helper=$(get_aur_helper)

    if [[ -n "$aur_helper" ]]; then
        "$aur_helper" -S --noconfirm --mflags "--nocheck" "$1" &> /dev/null
    else
        sudo pacman -S --needed --noconfirm "$1" &> /dev/null
    fi

    if pacman -Q "$1" &> /dev/null || ([[ -n "$aur_helper" ]] && "$aur_helper" -Q "$1" &> /dev/null); then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install."
    fi
}
