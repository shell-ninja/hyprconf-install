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

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/hyprland-$(date +%d-%m-%y).log"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "hypridle" "$log" | awk '{print $2}')
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Core Hyprland packages already installed. Skipping..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

_hypr=(
    hyprland
    hyprlock
    hypridle
)

# checking already installed packages 
for skipable in "${_hypr[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${_hypr[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Check for Debian 13 (trixie)
is_debian_13=false
if grep -qiE 'trixie|version_id="?13"?' /etc/os-release 2>/dev/null; then
    is_debian_13=true
fi

if [[ "$is_debian_13" == true ]]; then
    if ! grep -q "^deb.*trixie-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        msg act "Adding trixie-backports repository for Hyprland..."
        echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/trixie-backports.list > /dev/null
        sudo apt-get update
    fi
fi

# Installation of Hyprland basics
for hypr_pkgs in "${to_install[@]}"; do
    msg act "Installing $hypr_pkgs..."
    if [[ "$is_debian_13" == true ]]; then
        sudo apt-get install -y -t trixie-backports "$hypr_pkgs"
    else
        sudo apt-get install -y "$hypr_pkgs"
    fi

    if dpkg -s "$hypr_pkgs" &> /dev/null; then
        echo "[ DONE ] - '$hypr_pkgs' was installed successfully" >> "$log"
    else
        echo "[ ERROR ] - Failed to install '$hypr_pkgs'" >> "$log"
    fi
done

sudo apt-get install -y hyprland-guiutils 2>&1 | tee -a "$log" >/dev/null && msg dn "hyprland-guiutils installed successfully."

# installing pyprland
if ! command -v pypr &> /dev/null && [ ! -x "$HOME/.local/bin/pypr" ]; then
    msg act "Installing pyprland via pip..."
    sudo apt-get install -y python3-pip python3-aiofiles 2>&1 | tee -a "$log" >/dev/null
    pip install --break-system-packages --user pyprland 2>&1 | tee -a "$log" || pip install --user pyprland 2>&1 | tee -a "$log"

    export PATH="$PATH:$HOME/.local/bin"

    if command -v pypr &> /dev/null || [ -x "$HOME/.local/bin/pypr" ]; then
        msg dn "pyprland installed successfully."
    else
        msg err "Failed to install pyprland."
    fi
else
    msg dn "pyprland is already installed."
fi

# Execute helper scripts only when running standalone (not under TUI orchestrator)
if [[ "${HYPRCONF_TUI:-}" != "1" ]]; then
    "$dir/2.1-hyprcursor.sh"
    "$dir/2.2-hyprsunset.sh"
fi

sleep 1 && clear
