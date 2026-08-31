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
orange="\e[1;38;5;214m"
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/fonts-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "noto-fonts-emoji" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi

else
    mkdir -p "$log_dir"
    touch "$log"
fi

# necessary fonts [ new installable fonts should be added here ]
fonts=(
    ttf-font-awesome
    ttf-cascadia-code-nerd
    ttf-jetbrains-mono-nerd
    ttf-meslo-nerd
    noto-fonts
    noto-fonts-emoji
)

# checking already installed packages 
for skipable in "${fonts[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${fonts[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Instlling main packages...
for font in "${to_install[@]}"; do
    install_package "$font"
    if sudo pacman -Q "$font" &>/dev/null; then
        echo "[ DONE ] - $font was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $font!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

sleep 1 && clear
