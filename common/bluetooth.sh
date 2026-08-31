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
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

cache_dir="$parent_dir/.cache"
pkgman_cache="$cache_dir/pkgman"
source "$pkgman_cache"

# install script dir
source "$parent_dir/${pkgman}-scripts/1-global_script.sh"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/bluetooth-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

if [[ "$pkgman" == "pacman" ]]; then
  bluetooth=(
    bluez
    bluez-utils
    blueman
  )
elif [[ "$pkgman" == "dnf" ]]; then
  bluetooth=(
    bluez
    bluez-tools
    blueman
    python3-cairo
  )
elif [[ "$pkgman" == "apt" ]]; then
  bluetooth=(
    bluez
    bluez-tools
    blueman
  )
elif [[ "$pkgman" == "zypper" ]]; then
  bluetooth=(
    bluez
    blueman
  )
fi

# Bluetooth

msg act "Installing Bluetooth Packages..."
 for bluetooth_pkgs in "${bluetooth[@]}"; do
   install_package "$bluetooth_pkgs"
  done

msg act "Activating Bluetooth Services..."
sudo systemctl enable --now bluetooth.service 2>&1 | tee -a "$log"

clear
