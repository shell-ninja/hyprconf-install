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
log_dir="$parent_dir/Logs"
log="$log_dir/pywal-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"


msg act "Installing pywal.."
sudo pip install pywal --break-system-packages 2>&1 | tee -a "$log"

sleep 1

if command -v wal &> /dev/null; then
    msg dn "pywal was installed successfully!"
else
    msg err "Could not install pywal."
    exit 1
fi


sleep 1 && clear
