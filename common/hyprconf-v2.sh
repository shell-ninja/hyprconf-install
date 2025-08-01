#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

display_text() {
    gum style \
        --border rounded \
        --align center \
        --width 60 \
        --margin "1" \
        --padding "1" \
'
   ___       __  ____ __      
  / _ \___  / /_/ _(_) /__ ___
 / // / _ \/ __/ _/ / / -_|_-<
/____/\___/\__/_//_/_/\__/___/
                               
'
}

clear && display_text
printf " \n \n"

###------ Startup ------###

dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/hyprconf-v2-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

# hyprconf repo url
url="https://github.com/shell-ninja/hyprconf-v2/archive/refs/heads/main.zip"
target_dir="$parent_dir/.cache/hyprconf-v2"
zip_path="$target_dir.zip"

echo

# Download the ZIP silently with a progress bar
wget --quiet --show-progress "$url" -O "$zip_path"

# ---------------------- new ---------------------- #
# Extract only if download succeeded
if [[ -f "$zip_path" ]]; then
    mkdir -p "$target_dir"
    unzip "$zip_path" "hyprconf-v2-main/*" -d "$target_dir" > /dev/null
    mv "$target_dir/hyprconf-v2-main/"* "$target_dir" && rmdir "$target_dir/hyprconf-v2-main"
    rm "$zip_path"
fi
# ---------------------- new ---------------------- #


# ---------------------- old ---------------------- #
# Clone the repository and log the output
# if [[ ! -d "$parent_dir/.cache/hyprconf-v2" ]]; then
#     msg act "Cloning hyprconf-v2 dotfiles repository..."
#     git clone --depth=1 https://github.com/shell-ninja/hyprconf-v2.git "$parent_dir/.cache/hyprconf-v2" 2>&1 | tee -a "$log" &> /dev/null
# fi
# ---------------------- old ---------------------- #

sleep 1

# if repo clonned successfully, then setting up the config
if [[ -d "$parent_dir/.cache/hyprconf-v2" ]]; then
  cd "$parent_dir/.cache/hyprconf-v2" || { msg err "Could not changed directory to $parent_dir/.cache/hyprconf-v2" 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log"); exit 1; }

  chmod +x hyprconf-v2.sh
  
  ./hyprconf-v2.sh || { msg err "Could not run the setup script for hyprconf-v2." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log"); exit 1; }
fi

if [[ -f "$HOME/.config/hypr/scripts/startup.sh" ]]; then
  msg dn "Dotfiles setup was successful..." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")
else
  msg err "Could not setup dotfiles.." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")
  exit 1
fi

sleep 1 && clear
