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
  __  __     _          __       ____
 / / / /__  (_)__  ___ / /____ _/ / /
/ /_/ / _ \/ / _ \(_-</ __/ _ `/ / / 
\____/_//_/_/_//_/___/\__/\_,_/_/_/    
                                    
'
}

clear && display_text
printf " \n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log
log_dir="$parent_dir/Logs"
log="$log_dir/uninstall-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

removable_pkg=(
    wofi
    mako
    dunst
    rofi-wayland
    waybar
    wlogout
    swaync
)


for pkg in "${removable_pkg[@]}"; do
    if sudo pacman -Q "$pkg" &> /dev/null; then
        msg att "$pkg was found. It will be removed."
        sudo pacman -Rns --noconfirm "$pkg" &> /dev/null 2>&1 | tee -a "$log"
        
        sleep 1

        if sudo pacman -Q "$pkg" &> /dev/null; then
            msg err "Could not remove $pkg..."
        else
            msg dn "$pkg was removed successfully!"
        fi
    fi
done

exit 0
