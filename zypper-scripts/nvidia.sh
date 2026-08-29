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

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/nvidia-$(date +%d-%m-%y).log"

mkdir -p "$log_dir"
touch "$log"

nvidia_pkg=(
  dkms
  libvdpau1
  libva-vdpau-driver
  libva-utils
  libglvnd
  libglvnd-devel
  Mesa-libva
  xf86-video-nv
)

nvidia_drivers=(
  nvidia-video-G06
  nvidia-gl-G06
  nvidia-utils-G06
  nvidia-compute-utils-G06
)

# checking already installed packages 
for skipable in "${nvidia_pkg[@]}" "${nvidia_drivers[@]}"; do
    skip_installed "$skipable"
done

to_install_nvidia_pkg=($(printf "%s\n" "${nvidia_pkg[@]}" | grep -vxFf "$installed_cache"))
to_install_nvidia_drivers=($(printf "%s\n" "${nvidia_drivers[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# adding NVIDIA repo
sudo zypper -n --quiet ar --refresh -p 90 https://download.nvidia.com/opensuse/tumbleweed NVIDIA 2>&1 | tee -a "$log" || true
sudo zypper --gpg-auto-import-keys refresh 2>&1 | tee -a "$log"


# automatic install of nvidia driver
sudo zypper install-new-recommends --repo NVIDIA 2>&1 | tee -a "$log"

# Install additional Nvidia packages
 for nvidia_packages in "${to_install_nvidia_pkg[@]}"; do
   sudo zypper in --auto-agree-with-licenses -y "$nvidia_packages"
    if sudo zypper se -i "$nvidia_packages" &> /dev/null ; then
        echo "[ DONE ] - $nvidia_packages was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $nvidia_packages..." 2>&1 | tee -a "$log" &> /dev/null
    fi
 done

# Install additional Nvidia drivers
 for nvidia_packages in "${to_install_nvidia_drivers[@]}"; do
   sudo zypper in --auto-agree-with-licenses -y "$nvidia_packages"
    if sudo zypper se -i "$nvidia_packages" &> /dev/null ; then
        echo "[ DONE ] - $nvidia_packages was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $nvidia_packages..." 2>&1 | tee -a "$log" &> /dev/null
    fi
 done

# adding additional nvidia-stuff
msg act "Adding nvidia-stuff to /etc/default/grub"

# Additional options to add to GRUB_CMDLINE_LINUX
additional_options="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1"

# Check if additional options are already present in GRUB_CMDLINE_LINUX
if grep -q "GRUB_CMDLINE_LINUX.*$additional_options" /etc/default/grub; then
  echo "GRUB_CMDLINE_LINUX already contains the additional options" 2>&1 | tee -a "$log"
  else
  # Append the additional options to GRUB_CMDLINE_LINUX
  sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$additional_options /" /etc/default/grub
  echo "Added the additional options to GRUB_CMDLINE_LINUX" 2>&1 | tee -a "$log"
fi

# Update GRUB configuration
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

msg dn "Nvidia DRM modeset and additional options have been added to /etc/default/grub.\n   Please reboot for changes to take effect." 2>&1 | tee -a "$log"

sleep 1 && clear
