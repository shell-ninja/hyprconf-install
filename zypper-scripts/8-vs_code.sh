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
        --width 40 \
        --margin "1" \
        --padding "1" \
'
 _   __        _____        __   
| | / /__     / ___/__  ___/ /__ 
| |/ (_-<_   / /__/ _ \/ _  / -_)
|___/___(_)  \___/\___/\_,_/\__/ 
                                 
'
}

clear && display_text
printf " \n \n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# present dir
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/vs_code-$(date +%d-%m-%y).log"

mkdir -p "$log_dir"
touch "$log"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    if [[ -z "$errors" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

if [[ -n $(command -v code) ]]; then
    msg skp "Skipping vs-code. It's already installed."
else
    msg act "Installing Vs-Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>&1 | tee -a "$log" &> /dev/null
    sudo zypper addrepo https://packages.microsoft.com/yumrepos/vscode vscode 2>&1 | tee -a "$log" &> /dev/null
    sudo zypper refresh 2>&1 | tee -a "$log" &> /dev/null
    sudo zypper in -y code 2>&1 | tee -a "$log"
fi

common_scripts="$parent_dir/common"
"$common_scripts/vs_code_theme.sh"

clear
