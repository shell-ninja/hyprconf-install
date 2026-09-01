#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
purple="\e[1;38;2;189;147;249m"  # Electric neon purple
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"
cache_dir="$parent_dir/.cache"
source "$parent_dir/interaction_fn.sh"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/apt-repo-$(date +%d-%m-%y).log"

# checking if the script already ran
if [[ -f "$log" ]]; then
    error=$(grep "ERROR" "$log")
    if [[ -z "$error" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 0.5
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

mkdir -p "$cache_dir"

# Determine Debian codename (trixie or unstable)
debian_codename="trixie"
if grep -qiE 'sid|unstable' /etc/os-release 2>/dev/null; then
    debian_codename="unstable"
elif grep -qiE 'trixie|version_id="?13"?' /etc/os-release 2>/dev/null; then
    debian_codename="trixie"
fi

# Add Noctalia repository keyring
msg act "Adding Noctalia repository keyring..."
keyring_deb="$cache_dir/nickh-archive-keyring.deb"
if wget -q -O "$keyring_deb" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb 2>&1 | tee -a "$log" && sudo dpkg -i "$keyring_deb" 2>&1 | tee -a "$log"; then
    msg dn "Noctalia repository keyring installed successfully."
    echo "[ DONE ] - Noctalia repository keyring installed" >> "$log"
else
    msg err "Failed to install Noctalia repository keyring."
    echo "[ ERROR ] - Failed to install Noctalia repository keyring" >> "$log"
fi

# Add Noctalia sources list
msg act "Adding Noctalia ($debian_codename) repository..."
sources_url="https://pkg.noctalia.dev/deb/noctalia-${debian_codename}.sources"
sources_file="/etc/apt/sources.list.d/noctalia-${debian_codename}.sources"

if sudo wget -q -O "$sources_file" "$sources_url" 2>&1 | tee -a "$log"; then
    msg dn "Noctalia repository added successfully."
    echo "[ DONE ] - Noctalia repository added" >> "$log"
else
    msg err "Failed to add Noctalia repository."
    echo "[ ERROR ] - Failed to add Noctalia repository" >> "$log"
fi

msg act "Updating APT repositories..."
sudo apt-get update 2>&1 | tee -a "$log" || { msg err "Failed to update apt repositories."; exit 1; }

msg dn "Repositories updated successfully."
