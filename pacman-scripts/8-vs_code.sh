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
 _   __        _____        __   
| | / /__     / ___/__  ___/ /__ 
| |/ (_-<_   / /__/ _ \/ _  / -_)
|___/___(_)  \___/\___/\_,_/\__/ 
                                 
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

log_dir="$parent_dir/Logs"
log="$log_dir/vs_code-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "visual-studio-code-bin" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi

else
    mkdir -p "$log_dir"
    touch "$log"
fi

aur_helper=$(command -v yay || command -v paru) # find the aur helper

vs_code=(
    visual-studio-code-bin
)

# checking already installed packages 
for skipable in "${vs_code[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${vs_code[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# installing vs code
if [[ ${#to_install[@]} -gt 0 ]]; then
    for code in "${to_install[@]}"; do
        install_package "$code"
        if sudo "$aur_helper" -Q "$code" &>/dev/null; then
            echo "[ DONE ] - $code was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
        else
            echo "[ ERROR ] - Sorry, could not install $code!\n" 2>&1 | tee -a "$log" &>/dev/null
        fi
    done
fi

# updating vs code themes
common_scripts="$parent_dir/common"
"$common_scripts/vs_code_theme.sh"

sleep 1 && clear
