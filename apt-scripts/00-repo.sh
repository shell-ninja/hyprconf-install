#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/apt-repo-$(date +%d-%m-%y).log"

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


if grep -qiE 'ubuntu|mint|pop' /etc/os-release 2>/dev/null; then
    if ! grep -rq "avengemedia/danklinux" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        msg act "Adding danklinux PPA for Quickshell..."
        sudo apt-get install -y software-properties-common &>/dev/null
        sudo add-apt-repository -y ppa:avengemedia/danklinux 2>&1 | tee -a "$log" || true
    fi
fi

msg act "Updating APT repositories..."
sudo apt-get update 2>&1 | tee -a "$log" || { msg err "Failed to update apt repositories."; exit 1; }

msg dn "Repositories updated successfully."
