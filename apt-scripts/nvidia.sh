#!/bin/bash

# I copied this script from JaKooLit. See here https://github.com/JaKooLit

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
log="$log_dir/nvidia-$(date +%d-%m-%y).log"

mkdir -p "$log_dir"
touch "$log"

nvidia_pkg=(
  nvidia-driver
  firmware-misc-nonfree
  libva2
  nvidia-vaapi-driver
)


# checking already installed packages 
for skipable in "${nvidia_pkg[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${nvidia_pkg[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# installing nvidia packages
for __nvidia in "${to_install[@]}"; do
    install_package "$__nvidia"
    if dpkg -s "$__nvidia" &>/dev/null; then
        echo "[ DONE ] - $__nvidia was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $__nvidia!" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

# Additional options to add to GRUB_CMDLINE_LINUX
additional_options="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1"

# Check if additional options are already present in GRUB_CMDLINE_LINUX
if grep -q "GRUB_CMDLINE_LINUX.*$additional_options" /etc/default/grub; then
	msg skp "GRUB_CMDLINE_LINUX already contains the additional options" 2>&1 | tee -a "$log"
else
	# Append the additional options to GRUB_CMDLINE_LINUX
	sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$additional_options /" /etc/default/grub
    msg dn "Added the additional options to GRUB_CMDLINE_LINUX" 2>&1 | tee -a "$log"
fi

# Update GRUB configuration
sudo update-grub

msg dn "Nvidia DRM modeset and additional options have been added to /etc/default/grub. Please reboot for changes to take effect." 2>&1 | tee -a "$log"

clear
