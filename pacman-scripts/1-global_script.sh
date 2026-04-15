#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

# initial texts
attention="[${orange} ATTENTION ${end}]"
action="[${green} ACTION ${end}]"
note="[${magenta} NOTE ${end}]"
done="[${cyan} DONE ${end}]"
ask="[${orange} QUESTION ${end}]"
error="[${red} ERROR ${end}]"

# sourcing the intaraction functions
dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"
source "$parent_dir/interaction_fn.sh"

[[ ! -f "$installed_cache" ]] && touch "$installed_cache"

###------ Startup ------###

aur_helper=$(command -v yay || command -v paru) # find the aur helper

# skip already insalled packages
skip_installed() {

    [[ -z "$installed_cache" ]] && touch "$installed_cache"

    if "$aur_helper" -Q "$1" &> /dev/null; then
        msg skp "$1 is already installed. Skipping..." && sleep 0.1
        if ! grep -qx "$1" "$installed_cache"; then
            echo "$1" >> "$installed_cache"
        fi
    fi
}


# package installation function..
install_package() {

    msg act "Installing $1..."
    "$aur_helper" -S --noconfirm "$1" &> /dev/null

    if "$aur_helper" -Q "$1" &> /dev/null; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe therer is an issue..."
    fi
}


# package installation function..
install_package_nocheck() {

    msg act "Installing $1..."
    "$aur_helper" -S --noconfirm --mflags "--nocheck" "$1" &> /dev/null

    if "$aur_helper" -Q "$1" &> /dev/null; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe therer is an issue..."
    fi
}
