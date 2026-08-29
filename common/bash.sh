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
   ___           __ 
  / _ )___ ____ / / 
 / _  / _ `(_-</ _ \
/____/\_,_/___/_//_/
                     
'
}

clear && display_text
printf " \n \n"

###------ Startup ------###

dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

cache_dir="$parent_dir/.cache"

log_dir="$parent_dir/Logs"
log="$log_dir/bash-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

# check if there is a .bash directory available. if available, then backup it.
if [ -d ~/.bash ]; then
    msg nt "A ${green}.bash${end} directory is available. Backing it up.." && sleep 1

    mv ~/.bash ~/.bash-${USER} 2>&1 | tee -a "$log" &> /dev/null
    msg dn ".bash directory was backed up successfully!" 
fi

# now install bash
bash <(curl https://raw.githubusercontent.com/shell-ninja/Bash/main/direct_install.sh) 2>&1 | tee -a "$log"

clear
