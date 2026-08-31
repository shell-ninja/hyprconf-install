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
orange="\e[1;38;5;214m"
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

cache_dir="$parent_dir/.cache"
pkgman_cache="$cache_dir/pkgman"
source "$pkgman_cache"

# install script dir
source "$parent_dir/${pkgman}-scripts/1-global_script.sh"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/desktop-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

packages=(
    ddcutil
)

msg att "This system is a Desktop." 
msg act "Proceeding with some configuration..."

# Install necessary packages
for pkgs in "${packages[@]}"; do
    install_package "$pkgs" || { msg err "Could not install $pkgs, exiting..."; exit 1; } 2>&1 | tee -a "$log"
done

sleep 1 && clear

msg act "Enabling i2c-dev kernel module..."
sudo modprobe i2c-dev
echo i2c-dev | sudo tee /etc/modules-load.d/i2c.conf

USER_NAME=$(whoami)
msg act "Adding user '$USER_NAME' to i2c group..."
sudo usermod -aG i2c "$USER_NAME"

msg att "Checking for /dev/i2c-* devices..." && sleep 1
if ls /dev/i2c-* &>/dev/null; then
    msg dn "/dev/i2c devices detected."
fi

msg act "Detecting DDC/CI capable monitors..."
ddcutil detect || msg err "No monitors detected. Make sure DDC/CI is enabled in your monitor settings."

echo
msg dn "Setup complete."

sleep 1 && clear
