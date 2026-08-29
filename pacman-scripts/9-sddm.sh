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
        --width 40 \
        --margin "1" \
        --padding "1" \
        '
   _______  ___  __  ___
  / __/ _ \/ _ \/  |/  /
 _\ \/ // / // / /|_/ / 
/___/____/____/_/  /_/   

'
}

clear && display_text
printf " \n \n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
common_scripts="$parent_dir/common"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/sddm-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "sddm" "$log" | awk {'print $2'})
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
sddm=(
    qt6-5compat
    qt6-declarative
    qt6-svg
    qt6-virtualkeyboard 
    qt6-multimedia-ffmpeg
    sddm
)

logins=(
    lightdm 
    gdm 
    lxdm
    lxdm-gtk3
)


# checking already installed packages 
for skipable in "${sddm[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${sddm[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Instlling main packages...
for sddm_pkgs in "${to_install[@]}"; do
    install_package "$sddm_pkgs"
    if sudo pacman -Q "$sddm_pkgs" &>/dev/null; then
        echo "[ DONE ] - $sddm_pkgs was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $sddm_pkgs!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

# Check if other login managers are installed and disabling their service before enabling sddm
for login_manager in "${logins[@]}"; do
    if sudo pacman -Q "$login_manager" &> /dev/null; then
        msg att "Disabling $login_manager..."
        sudo systemctl disable "$login_manager" 2>&1 | tee -a "$log"
        echo
    fi
done

msg act "Activating sddm service..."
sudo systemctl enable sddm.service 2>&1 | tee -a "$log"

# run sddm theme script
"$common_scripts/sddm_theme.sh"

sleep 1 && clear
