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
   __ __                                    __ 
  / // /_ _____  _______ __ _____  ___ ___ / /_
 / _  / // / _ \/ __(_-</ // / _ \(_-</ -_) __/
/_//_/\_, / .__/_/ /___/\_,_/_//_/___/\__/\__/ 
     /___/_/                                    
'
}

clear && display_text
printf " \n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/hyprland-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

mkdir -p "$log_dir"
touch "$log"


# Check if hyprsunset is already available as a package first
if sudo zypper se -i hyprsunset &> /dev/null; then
    msg skp "hyprsunset is already installed. Skipping..."
    sleep 1 && clear
    exit 0
fi

if ! sudo zypper se -i git &> /dev/null; then
    install_package git
fi

if ! sudo zypper se -i cmake &> /dev/null; then
    install_package cmake
fi

if ! sudo zypper se -i make &> /dev/null; then
    install_package make
fi

if git clone --depth=1 https://github.com/hyprwm/hyprsunset "$parent_dir/.cache/hyprsunset" &> /dev/null; then
    cd "$parent_dir/.cache/hyprsunset"
    mkdir build
    cd build
    sleep 1
    cmake ..
    sleep 1
    sudo make install

    sleep 1

    if command -v hyprsunset &> /dev/null; then
        msg dn "Hyprsunset was installed successfully!"
        echo "[ DONE ] - Hyprsunset was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        msg err "Hyprsunset failed to install. Maybe there was an issue..."
        echo "[ ERROR ] - Sorry, could not install Hyprsunset.\n" 2>&1 | tee -a "$log" &> /dev/null
    fi 
fi

sleep 1 && clear
