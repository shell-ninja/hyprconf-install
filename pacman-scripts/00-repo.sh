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
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"

source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/aur_helper-$(date +%d-%m-%y).log"

# Check for existing AUR helpers
aur_helper=$(command -v yay 2>/dev/null || command -v paru 2>/dev/null)

_aur="yay"
if [[ -f "$parent_dir/.cache/aur" ]]; then
    _aur=$(tr -d '[:space:]' < "$parent_dir/.cache/aur" 2>/dev/null)
fi
[[ -z "$_aur" ]] && _aur="yay"

# Handle Skip choice
if [[ "$_aur" == "Skip" ]]; then
    msg skp "Skipping AUR helper installation as requested."
    msg act "Synchronizing pacman package databases..."
    sudo pacman -Syu --noconfirm 2>&1 | tee -a "$log"
    exit 0
fi

# Check if the requested or another AUR helper is already installed
if command -v "$_aur" &>/dev/null; then
    msg dn "$_aur is already installed! Moving on..."
    echo "[ DONE ] - $_aur is already installed" >> "$log"
    msg act "Performing a full system update..."
    "$_aur" -Syu --noconfirm 2>&1 | tee -a "$log"
    exit 0
elif [[ -n "$aur_helper" ]]; then
    msg dn "Found existing AUR helper ($aur_helper). Updating system..."
    echo "[ DONE ] - Found existing $aur_helper" >> "$log"
    "$aur_helper" -Syu --noconfirm 2>&1 | tee -a "$log"
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

build_dir="$parent_dir/.cache/aur-build"
sudo rm -rf "$build_dir"
mkdir -p "$build_dir"

# Determine user to run makepkg (makepkg cannot run as root)
build_cmd() {
    if [[ $EUID -eq 0 && -n "$SUDO_USER" ]]; then
        chown -R "$SUDO_USER:" "$build_dir"
        sudo -u "$SUDO_USER" makepkg -si --noconfirm 2>&1 | tee -a "$log"
    else
        makepkg -si --noconfirm 2>&1 | tee -a "$log"
    fi
}

installed=false

# Try precompiled binary package first (-bin) for fast installation
msg act "Attempting to install precompiled ${_aur}-bin..."
if git clone "https://aur.archlinux.org/${_aur}-bin.git" "$build_dir/${_aur}-bin" 2>&1 | tee -a "$log"; then
    cd "$build_dir/${_aur}-bin" || exit 1
    if build_cmd; then
        installed=true
    fi
    cd "$parent_dir" || true
fi

# Fallback to source compilation if -bin failed or was not available
if [[ "$installed" != true ]]; then
    msg act "Attempting to build ${_aur} from source repository..."
    rm -rf "$build_dir/${_aur}"
    if git clone "https://aur.archlinux.org/${_aur}.git" "$build_dir/${_aur}" 2>&1 | tee -a "$log"; then
        cd "$build_dir/${_aur}" || exit 1
        if build_cmd; then
            installed=true
        fi
        cd "$parent_dir" || true
    fi
fi

# Clean up build artifacts
sudo rm -rf "$build_dir"

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
