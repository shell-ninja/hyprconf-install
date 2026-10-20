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

# present dir
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/sddm-$(date +%d-%m-%y).log"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "qt6-qtsvg" "$log" | awk {'print $2'})
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
    qml-module-qtgraphicaleffects
    qml-module-qtquick-controls2
    sddm
    qml6-module-qtquick
    qml6-module-qtquick-controls
    qml6-module-qtquick-layouts
    qml6-module-qt5compat-graphicaleffects
    qml6-module-qtqml
    libqt6svg6
    qml6-module-qtquick-virtualkeyboard
    qml6-module-qtmultimedia
)

logins=(
    lightdm
    gdm
    gdm3
    lxdm
    lxdm-gtk3
)

# checking already installed packages
for skipable in "${sddm[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${sddm[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Pre-seed debconf so apt doesn't prompt for default display manager
echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections

# Installing SDDM greeter packages
for sddm_pkgs in "${to_install[@]}"; do
    install_package "$sddm_pkgs"
    if dpkg -s "$sddm_pkgs" &> /dev/null; then
        echo "[ DONE ] - $sddm_pkgs was installed successfully!" >> "$log"
    else
        echo "[ ERROR ] - Failed to install $sddm_pkgs" >> "$log"
    fi
done

# Disable conflicting login managers if present
for login_manager in "${logins[@]}"; do
    if dpkg -s "$login_manager" &> /dev/null; then
        msg act "Disabling conflicting display manager: $login_manager..."
        sudo systemctl disable "$login_manager" 2>&1 | tee -a "$log" >/dev/null || true
    fi
done

# Enable sddm as the default display manager
msg act "Activating sddm service..."
sudo systemctl set-default graphical.target 2>&1 | tee -a "$log"
sudo systemctl enable sddm.service 2>&1 | tee -a "$log"

# run sddm theme script (only when run standalone outside TUI installer)
common_scripts="$parent_dir/common"
if [[ "$HYPRCONF_TUI" != "1" ]]; then
    "$common_scripts/sddm_theme.sh"
fi

sleep 1 && clear
