#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# Color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
purple="\e[1;38;2;189;147;249m"  # Electric neon purple
end="\e[1;0m"

display_text() {
    cat <<"EOF"
   ___             __ __    __            
  / _ |__ ______  / // /__ / /__  ___ ____
 / __ / // / __/ / _  / -_) / _ \/ -_) __/
/_/ |_\_,_/_/   /_//_/\__/_/ .__/\__/_/   
                          /_/                   
   
EOF
}

clear && display_text
printf " \n\n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"

source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/aur_helper-$(date +%d-%m-%y).log"

# Check for existing AUR helpers
aur_helper=$(command -v yay || command -v paru)

# install git before installing the aur helper.
if ! pacman -Qs git &> /dev/null; then
    sudo pacman -S --noconfirm base-devel git 2>&1 | tee -a "$log" &>/dev/null
fi

_aur=$(cat "$parent_dir/.cache/aur")

msg act "Installing $_aur"

sudo rm -rf /var/lib/pacman/db.lck &> /dev/null
git clone https://aur.archlinux.org/${_aur}.git "$parent_dir/.cache/${_aur}" &> /dev/null
cd "$parent_dir/.cache/${_aur}" || exit 1
makepkg -si --noconfirm
sleep 1
cd "$parent_dir" || exit 1
sudo rm -rf "$parent_dir/.cache/${_aur}"


if [[ -n "$(command -v $_aur)" ]]; then
    msg dn "$_aur was installed successfully!"
    echo "[ DONE ] - $_aur helper was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null

    msg act "Performing a full system update.."
    "$_aur" -Syyu --noconfirm 2>&1 | tee -a "$log"
    exit 0
else
    msg err "Could not install aru helper. Maybe there was an issue."
    echo "[ ERROR ] - Could not install aru helper. Maybe there was an issue." 2>&1 | tee -a "$log" &>/dev/null
    exit 1
fi

sleep 1 && clear
