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
source "$parent_dir/interaction_fn.sh"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/xdg_dp-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

mkdir -p "$log_dir"
touch "$log"

xdg=(
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
)

removable=(
    xdg-desktop-portal-wlr
    xdg-desktop-portal-lxqt
)

# checking already installed packages 
for skipable in "${xdg[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${xdg[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Instlling xdg packages...
for xdg_pkgs in "${to_install[@]}"; do
    install_package "$xdg_pkgs"
    if sudo pacman -Q "$xdg_pkgs" &>/dev/null; then
        echo "[ DONE ] - $xdg_pkgs was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $xdg_pkgs!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

echo

# Clean out other portals
msg att "Checking for other XDG-Desktop-Portal-Implementations..." && sleep 1

for xdgs in "${removable[@]}"; do
    if sudo pacman -Q "$xdgs" &> /dev/null; then

        fn_ask "Would you like to remove $xdgs?" "Yes!" "No!"

        if [[ $? -eq 0 ]]; then
            msg act "Removing $xdgs..."
            sudo pacman -Rns --noconfirm "$xdgs" 2>&1 | tee -a "$log" &> /dev/null
        else
            msg skp "Won't remove $xdgs.."
        fi
    fi
done

sleep 1 && clear
