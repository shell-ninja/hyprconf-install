#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# Color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[38;5;214m"
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"

source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/aur_helper-$(date +%d-%m-%y).log"

# Check for existing AUR helpers
aur_helper=$(command -v yay 2>/dev/null || command -v paru 2>/dev/null)

if [[ -n "$aur_helper" ]]; then
    msg dn "AUR helper '$(basename "$aur_helper")' is already installed."
    msg act "Synchronizing system databases with $(basename "$aur_helper")..."
    "$aur_helper" -Syyu --noconfirm 2>&1 | tee -a "$log"
    exit 0
fi

# Ensure base-devel and git are present
if ! pacman -Qs git &> /dev/null || ! pacman -Qs base-devel &> /dev/null; then
    msg act "Installing base-devel and git..."
    sudo pacman -S --needed --noconfirm base-devel git 2>&1 | tee -a "$log" &>/dev/null
fi

_aur=$(cat "$parent_dir/.cache/aur" 2>/dev/null || echo "yay-bin")
helper_cmd="${_aur%-bin}"

msg act "Building and installing $_aur..."

sudo rm -f /var/lib/pacman/db.lck &> /dev/null
build_dir="$parent_dir/.cache/${_aur}"
rm -rf "$build_dir" 2>/dev/null || true
git clone "https://aur.archlinux.org/${_aur}.git" "$build_dir" 2>&1 | tee -a "$log" &> /dev/null

if [[ -d "$build_dir" ]]; then
    cd "$build_dir" || exit 1
    if [[ "$EUID" -eq 0 && -n "$SUDO_USER" ]]; then
        chown -R "$SUDO_USER:" "$build_dir"
        sudo -u "$SUDO_USER" makepkg -si --noconfirm 2>&1 | tee -a "$log"
    else
        makepkg -si --noconfirm 2>&1 | tee -a "$log"
    fi
    cd "$parent_dir" || exit 1
    rm -rf "$build_dir"
fi

if command -v "$helper_cmd" &>/dev/null || command -v "$_aur" &>/dev/null; then
    active_helper=$(command -v "$helper_cmd" 2>/dev/null || command -v "$_aur" 2>/dev/null)
    msg dn "AUR helper '$(basename "$active_helper")' installed successfully."
    echo "[ DONE ] - AUR helper '$(basename "$active_helper")' installed successfully." >> "$log"

    msg act "Performing full system synchronization..."
    "$active_helper" -Syyu --noconfirm 2>&1 | tee -a "$log"
    exit 0
else
    msg err "Failed to install AUR helper: '$_aur'. Check '$log' for details."
    echo "[ ERROR ] - Could not install AUR helper: '$_aur'." >> "$log"
    exit 1
fi

sleep 1 && clear
