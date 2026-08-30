#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# Color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
purple="\e[1;38;2;189;147;249m"  # Electric neon purple
end="\e[1;0m"

display_text() {
    cat <<"EOF"
   ___             __ __    __            
  / _ |__ ______  / // /__ / /__  ___ ____
 / __ / // / __/ / _  / -_) / _ \/ -_) __/
/_/ |_\_,_/_/   /_//_/\__/_/ .__/\__/_/   
                          /_/                   
   
EOF
}

clear && display_text
printf " \n\n"

###------ Startup ------###

# install script dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
parent_dir="$(dirname "$dir")"
cache_dir="$parent_dir/.cache"
aur_cache="$cache_dir/aur"

source "$dir/1-global_script.sh"
source "$parent_dir/interaction_fn.sh"  

log_dir="$parent_dir/Logs"
log="$log_dir/aur_helper-$(date +%d-%m-%y).log"

# getting aur helper from cache or user input
if [[ -f "$aur_cache" ]]; then
    _aur=$(tr -d '[:space:]' < "$aur_cache")
fi
[[ -z "$_aur" ]] && _aur="yay"

# Handle Skip choice
if [[ "$_aur" == "Skip" ]]; then
    msg skp "Skipping AUR helper installation as requested."
    msg act "Synchronizing pacman package databases..."
    sudo pacman -Syu --noconfirm 2>&1 | tee -a "$log"
    exit 0
fi

# Check if the requested AUR helper is already installed
if command -v "$_aur" &>/dev/null; then
    msg dn "$_aur is already installed! Moving on..."
    echo "[ DONE ] - $_aur is already installed" >> "$log"
    msg act "Performing a full system update..."
    "$_aur" -Syu --noconfirm 2>&1 | tee -a "$log"
    exit 0
fi

# Ensure pacman db lock is removed if stale
sudo rm -f /var/lib/pacman/db.lck &>/dev/null

# Install base-devel, git, and curl prerequisites
msg act "Ensuring base-devel, git, and curl prerequisites are installed..."
sudo pacman -Sy --needed --noconfirm base-devel git curl 2>&1 | tee -a "$log"
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    msg err "Failed to install base-devel or git prerequisites."
    echo "[ ERROR ] - Failed to install base-devel / git" >> "$log"
    exit 1
fi

msg act "Installing $_aur helper..."

installed=false

# Try precompiled binary package first (-bin) for fast installation
msg act "Attempting to install precompiled ${_aur}-bin..."
# rm -rf "$build_dir/${_aur}-bin"
if git clone "https://aur.archlinux.org/${_aur}.git" "$cache_dir/${_aur}" 2>&1 | tee -a "$log"; then
    cd "$cache_dir/${_aur}" || exit 1
    if makepkg -si --noconfirm 2>&1 | tee -a "$log"; then
        installed=true
    fi
    cd "$parent_dir" || true
fi


if command -v "$_aur" &>/dev/null; then
    msg dn "$_aur was installed successfully!"
    echo "[ DONE ] - $_aur helper was installed successfully!" >> "$log"

    msg act "Performing a full system update with $_aur..."
    "$_aur" -Syyu --noconfirm 2>&1 | tee -a "$log"
    exit 0
else
    msg err "Could not install $_aur helper. Please check $log for details."
    echo "[ ERROR ] - Could not install $_aur helper" >> "$log"
    exit 1
fi

clear