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
 ________                
/_  __/ /  ___ __ _  ___ 
 / / / _ \/ -_)  ; \/ -_)
/_/ /_//_/\__/_/_/_/\__/ 
                          
                               
'
}

clear && display_text
printf " \n \n"

printf " \n"

###------ Startup ------###

# finding the presend directory and log file
# install script dir
dir="$(dirname "$(realpath "$0")")"

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/themes-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

url="https://github.com/shell-ninja/themes_icons/archive/refs/heads/main.zip"
target_dir="$parent_dir/.cache/themes_icons"
zip_path="$target_dir.zip"

# Download the ZIP silently with a progress bar
curl -L "$url" -o "$zip_path"

echo

# ---------------------- new ---------------------- #
# Extract only if download succeeded
if [[ -f "$zip_path" ]]; then
    mkdir -p "$target_dir"
    unzip "$zip_path" "themes_icons-main/*" -d "$target_dir" > /dev/null
    mv "$target_dir/themes_icons-main/"* "$target_dir" && rmdir "$target_dir/themes_icons-main"
    rm "$zip_path"
fi
# ---------------------- new ---------------------- #

if [[ -d "$parent_dir/.cache/themes_icons" ]]; then
    cd "$parent_dir/.cache/themes_icons"
    chmod +x extract.sh
    ./extract.sh
fi

if [[ -d "$HOME/.icons/Bibata-Modern-Ice" ]]; then
    sudo cp -r "$HOME/.icons"/* /usr/share/icons/ &> /dev/null
fi

sleep 1 && clear
