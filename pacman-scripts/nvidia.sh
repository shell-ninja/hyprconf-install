#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# I copied this script from JaKooLit. See here https://github.com/JaKooLit

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
   _  __     _    ___     
  / |/ /_ __(_)__/ (_)__ _
 /    / |/ / / _  / / _ `/
/_/|_/|___/_/\_,_/_/\_,_/ 
                          
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
log="$log_dir/nvdia-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "libva-nvidia-driver-git" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg nt "No need to run this script again..."
        sleep 2
        exit 0
    fi

else
    mkdir -p "$log_dir"
    touch "$log"
fi


nvidia_pkg=(
    nvidia-dkms
    nvidia-settings
    nvidia-utils
    libva
    libva-nvidia-driver-git
)

# checking already installed packages 
for skipable in "${nvidia_pkg[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${nvidia_pkg[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Instlling nvidia packages...
for __nvidia in "${to_install[@]}"; do
    install_package "$__nvidia"
    if sudo pacman -Q "$__nvidia" &>/dev/null; then
        echo "[ DONE ] - $__nvidia was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $__nvidia!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

# Install additional Nvidia packages
msg act "Installing addition Nvidia packages..."
for krnl in $(cat /usr/lib/modules/*/pkgbase); do
    for NVIDIA in "${krnl}-headers" "${nvidia_pkg[@]}"; do
        install_package "$NVIDIA" 2>&1 | tee -a "$log"
    done
done

# Check if the Nvidia modules are already added in mkinitcpio.conf and add if not
if grep -qE '^MODULES=.*nvidia. *nvidia_modeset.*nvidia_uvm.*nvidia_drm' /etc/mkinitcpio.conf; then
    msg att "Nvidia modules already included in /etc/mkinitcpio.conf" 2>&1 | tee -a "$log"
else
    sudo sed -Ei 's/^(MODULES=\([^\)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | tee -a "$log"
    msg dn "Nvidia modules added in /etc/mkinitcpio.conf"
fi

sudo mkinitcpio -P 2>&1 | tee -a "$log"
printf "\n\n\n"

# Additional Nvidia steps
NVEA="/etc/modprobe.d/nvidia.conf"
if [ -f "$NVEA" ]; then
    msg dn "Seems like nvidia-drm modeset=1 is already added in your system..moving on."
else
    msg act "Adding options to $NVEA."
    sudo echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | tee -a "$log"
    echo
fi

# additional for GRUB users
# Check if /etc/default/grub exists
if [ -f /etc/default/grub ]; then
    # Check if nvidia_drm.modeset=1 is already present
    if ! sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        # Add nvidia_drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT
        sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
        # Regenerate GRUB configuration
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        msg att "nvidia-drm.modeset=1 added to /etc/default/grub" 2>&1 | tee -a "$log"
    else
        msg skp "nvidia-drm.modeset=1 is already present in /etc/default/grub" 2>&1 | tee -a "$log"
    fi
else
    echo "/etc/default/grub does not exist"
fi

# Blacklist nouveau
fn_ask "Would you like to blacklist nouveau?" "Yes!" "No!"
if [[ $? -eq 0 ]]; then
    NOUVEAU="/etc/modprobe.d/nouveau.conf"
    if [ -f "$NOUVEAU" ]; then
        msg act "Seems like nouveau is already blacklisted..moving on"
    else
        printf "\n"
        echo "blacklist nouveau" | sudo tee -a "$NOUVEAU" 2>&1 | tee -a "$log"
        msg dn "Has been added to $NOUVEAU"

        # To completely blacklist nouveau (See wiki.archlinux.org/title/Kernel_module#Blacklisting 6.1)
        if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
            echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a "$log"
        else
            echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a "$log"
        fi
    fi
else
    msg err "Skipping nouveau blacklisting." 2>&1 | tee -a "$log"
fi

sleep 1 & clear
