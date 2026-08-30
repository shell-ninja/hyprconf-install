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
   ___                    _ __           _       
  / _ \___ ___  ___  ___ (_) /____  ____(_)__ ___
 / , _/ -_) _ \/ _ \(_-</ / __/ _ \/ __/ / -_|_-<
/_/|_|\__/ .__/\___/___/_/\__/\___/_/ /_/\__/___/
        /_/                                       
'
}

clear && display_text
printf " \n \n"


###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/copr-$(date +%d-%m-%y).log"

# checking if the script already ran
if [[ -f "$log" ]]; then
    error=$(grep "ERROR" "$log")
    if [[ -z "$error" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 0.5
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi


# List of COPR repositories to be added and enabled
copr_repos=(
    solopasha/hyprland
    tofik/nwg-shell
    erikreider/SwayNotificationCenter  
    alternateved/eza
    jkinred/satty
)

# enabling 3rd party repo
install_package https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>&1 | tee -a "$log"


# Enable COPR Repositories 
for repo in "${copr_repos[@]}";do 
  sudo dnf copr enable -y "$repo" 2>&1 | tee -a "$log" || { msg err "Failed to enable necessary copr repos."; exit 1; }
done
