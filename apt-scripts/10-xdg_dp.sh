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

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/xdg_dp-$(date +%d-%m-%y).log"

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

# Check for Debian 13 (trixie)
is_debian_13=false
if grep -qiE 'trixie|version_id="?13"?' /etc/os-release 2>/dev/null; then
    is_debian_13=true
fi

if [[ "$is_debian_13" == true ]]; then
    if ! grep -q "^deb.*trixie-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        msg act "Adding trixie-backports repository for XDG portals..."
        echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/trixie-backports.list > /dev/null
        sudo apt-get update
    fi
fi

# Instlling xdg packages...
for xdg_pkgs in "${to_install[@]}"; do
    msg act "Installing $xdg_pkgs..."
    if [[ "$is_debian_13" == true && "$xdg_pkgs" == "xdg-desktop-portal-hyprland" ]]; then
        sudo apt-get install -y -t trixie-backports "$xdg_pkgs"
    else
        sudo apt-get install -y "$xdg_pkgs"
    fi
    
    if dpkg -s "$xdg_pkgs" &> /dev/null; then
        echo "[ DONE ] - $xdg_pkgs was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $xdg_pkgs!" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

# checking for other xdg desktop portals
msg att "Checking for other XDG-Desktop-Portal-Implementations..." && sleep 1

for xdgs in "${removable[@]}"; do
  	if dpkg -s "$xdgs" &> /dev/null; then

        fn_ask "Would you like to remove $xdgs?" "Yes!" "No!"

        if [[ $? -eq 0 ]]; then
            msg act "Removing $xdgs..."
            sudo apt-get remove -y "$xdgs" 2>&1 | tee -a "$log" &> /dev/null
        else
            msg skp "Won't remove $xdgs.."
        fi
  	fi
done

sleep 1 && clear
