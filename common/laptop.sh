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

display_text() {
    gum style \
        --border rounded \
        --align center \
        --width 60 \
        --margin "1" \
        --padding "1" \
'
   __             __          
  / /  ___ ____  / /____  ___ 
 / /__/ _ `/ _ \/ __/ _ \/ _ \
/____/\_,_/ .__/\__/\___/ .__/
         /_/           /_/    
                               
'
}

clear && display_text
printf " \n \n"

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
log="$log_dir/laptop-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

packages=(
    brightnessctl
    wlroots
)

msg att "This system is a Laptop." 
msg act "Proceeding with some configuration..."

# Install necessary packages
for pkgs in "${packages[@]}"; do
    install_package "$pkgs" || { msg err "Could not install $pkgs, exiting..."; exit 1; } 2>&1 | tee -a "$log"
done
