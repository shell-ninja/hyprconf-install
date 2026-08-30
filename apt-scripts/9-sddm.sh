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
    qml6-module-qt5compat-graphicaleffects
    qml6-module-qtqml
    libqt6svg6
    qml6-module-qtquick-virtualkeyboard
    qml6-module-qtmultimedia
)

logins=(
    lightdm
    gdm
    lxdm
    lxdm-gtk3
)


# Disable other login managers if installed
for login_manager in "${logins[@]}"; do
    if dpkg -s "$login_manager" &> /dev/null; then
        msg att "$login_manager Login Manager found. Won't install SDDM here."

        exit 0
    fi
done

# checking already installed packages
for skipable in "${sddm[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${sddm[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Pre-seed debconf so apt doesn't prompt for default display manager
echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections

for sddm_pkgs in "${to_install[@]}"; do
    install_package "$sddm_pkgs"
    if dpkg -s "$sddm_pkgs" &> /dev/null; then
        echo "[ DONE ] - $sddm_pkgs was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $sddm_pkgs!" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

# Disable other login managers if installed
for login_manager in "${logins[@]}"; do
    if dpkg -s "$login_manager" &> /dev/null; then
        msg act "Disabling $login_manager..."
        sudo systemctl disable "$login_manager" 2>&1 | tee -a "$log"
    fi
done

# Enable sddm as the default display manager
msg act "Activating sddm service..."
sudo systemctl set-default graphical.target 2>&1 | tee -a "$log"
sudo systemctl enable sddm.service 2>&1 | tee -a "$log"

sleep 1 && clear
