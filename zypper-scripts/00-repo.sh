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
        --width 60 \
        --margin "1" \
        --padding "1" \
'
   ___                    _ __           _       
  / _ \___ ___  ___  ___ (_) /____  ____(_)__ ___
 / , _/ -_) _ \/ _ \(_-</ / __/ _ \/ __/ / -_|_-<
/_/|_|\__/ .__/\___/___/_/\__/\___/_/ /_/\__/___/
        /_/                                       
'
}

clear && display_text
printf " \n"


###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/repo-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

# packman repository
packman_repo="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/"

dependencies=(
  devel_basis
)


# Adding Packman repository and switching over to Packman
msg act "Adding Packman repository (Globally)...."

sudo zypper -n --quiet ar --refresh -p 90 "$packman_repo" packman 2>&1 | tee -a "$log"
sudo zypper --gpg-auto-import-keys refresh 2>&1 | tee -a "$log"
sudo zypper -n dup --from packman --allow-vendor-change 2>&1 | tee -a "$log"

echo 

for deps in "${dependencies[@]}"; do
    install_package_base "$deps"
    if sudo zypper se -i "$deps" &> /dev/null ; then
      echo "[ DONE ] - '$deps' was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
      echo "[ ERROR ] - Sorry, could not install '$deps'" 2>&1 | tee -a "$log" &> /dev/null
    fi
done

# installing opi
install_package opi
if sudo zypper se -i opi &> /dev/null ; then
  echo "[ DONE ] - 'opi' was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
else
  echo "[ ERROR ] - Sorry, could not install 'opi'" 2>&1 | tee -a "$log" &> /dev/null
fi

clear
