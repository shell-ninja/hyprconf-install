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

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/vs_code_theme-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

vs_code_dir="$HOME/.config/Code"
vs_code_plugins_dir="$HOME/.vscode"

    # backing up vs code directory "Code"
    if [ -d "$vs_code_dir" ]; then
        msg act "Backing up .config/Code directory..."
        mv "$vs_code_dir" "$vs_code_dir"-${USER} 2>&1 | tee -a "$log"
    fi

    # backing up vs code directory "Plugins"
    if [ -d "$vs_code_plugins_dir" ]; then
        msg act "Backing up directory..."
        mv "$vs_code_plugins_dir" "$vs_code_plugins_dir"-${USER} 2>&1 | tee -a "$log"
    fi
    
# copying vs code themes and plugins dir
msg act "Copying config..."
assets_dir="$parent_dir/assets"

cp -r "$assets_dir/Code" "$HOME/.config/" 2>&1 | tee -a "$log"
cp -r "$assets_dir/.vscode" "$HOME/" 2>&1 | tee -a "$log"

sleep 1

msg dn "Vs Code themes and some plugins have been copied"

sleep 1 && clear
