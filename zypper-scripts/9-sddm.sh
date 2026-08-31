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

# present dir
parent_dir="$(dirname "$dir")"
common_scripts="$parent_dir/common"
source "$parent_dir/interaction_fn.sh"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/sddm-$(date +%d-%m-%y).log"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "xorg-x11-server" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

# packages for sddm
sddm_pkgs=(
  libqt5-qtgraphicaleffects
  libqt5-qtquickcontrols
  libqt5-qtquickcontrols2
  sddm-qt6
  xauth
  xf86-input-evdev
  xorg-x11-server
)

# checking already installed packages 
for skipable in "${sddm_pkgs[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${sddm_pkgs[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

for sddm in "${to_install[@]}" ; do
  install_package_no_recommands "$sddm"
    if sudo zypper se -i "$sddm" &> /dev/null ; then
        echo "[ DONE ] - $sddm was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $sddm..." 2>&1 | tee -a "$log" &> /dev/null
    fi
done

# Check if other login managers are installed and disabling their service before enabling sddm
for login_manager in lightdm gdm lxdm lxdm-gtk3; do
  if sudo  zypper se -i "$login_manager" &> /dev/null; then
    msg att "Disabling $login_manager..."
    sudo systemctl disable "$login_manager" 2>&1 | tee -a "$log"
  fi
done

# activation of sddm service
msg act "Activating login manager (sddm)"
sudo systemctl set-default graphical.target 2>&1 | tee -a "$log"
sudo update-alternatives --set default-displaymanager /usr/lib/X11/displaymanagers/sddm 2>&1 | tee -a "$log"
sudo systemctl enable sddm.service 2>&1 | tee -a "$log"

# run sddm theme script
"$common_scripts/sddm_theme.sh"

sleep 1 && clear
