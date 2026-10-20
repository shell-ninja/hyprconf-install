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

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/hyprland-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "hyprcursor" "$log" | awk '{print $2}')
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Hyprland packages already installed. Skipping..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

aur_helper=$(command -v yay || command -v paru)

_hypr=(
    hyprland
    hyprlock
    hypridle
    hyprcursor
)

# Checking already installed packages
for skipable in "${_hypr[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${_hypr[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Installing core packages
for hypr_pkgs in "${to_install[@]}"; do
    install_package "$hypr_pkgs"

    if sudo pacman -Q "$hypr_pkgs" &>/dev/null; then
        echo "[ DONE ] - $hypr_pkgs installed successfully." >> "$log"
    else
        echo "[ ERROR ] - Failed to install $hypr_pkgs" >> "$log"
    fi
done

sleep 1 && clear
