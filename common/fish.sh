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
    _______      __  
   / ____(_)____/ /_ 
  / /_  / / ___/ __ \
 / __/ / (__  ) / / /
/_/   /_/____/_/ /_/ 
                              
'
}

clear && display_text
printf " \n \n"

###------ Startup ------###

dir="$(dirname "$(realpath "$0")")"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

cache_dir="$parent_dir/.cache"
pkgman_cache="$cache_dir/pkgman"
source "$pkgman_cache"

# install script dir
source "$parent_dir/${pkgman}-scripts/1-global_script.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/fish-$(date +%d-%m-%y).log"

# skip installed cache
installed_cache="$parent_dir/.cache/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "thefuck" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

# required packages
common_packages=(
    bat
    curl
    eza
    fastfetch
    figlet
    fish
    fzf
    git
    rsync
    starship
    zoxide
)

for_opensuse=(
    python311
    python311-pip
    python311-pipx
    xclip
)


# checking already installed packages 
for skipable in "${common_packages[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${common_packages[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Instlling main packages...
for shell in "${to_install[@]}"; do
    install_package "$shell"
done

if [[ "$pkgman" == "pacman" || "$pkgman" == "dnf" || "$pkgman" == "apt" ]]; then
    install_package thefuck 2>&1 | tee -a "$log"
elif [[ "$pkgman" == "zypper" ]]; then
    msg att "Some necessary packages will be installed using ${pkgman}..." && sleep 1

    for pkgs in "${for_opensuse[@]}"; do
        install_package "$pkgs" 2>&1 | tee -a "$log"
    done

    # installing thefu*k
    if command -v pipx &> /dev/null; then
        pipx runpip thefuck install setuptools &> /dev/null
        sleep 0.5
        pipx install --python python3.11 thefuck &> /dev/null 2>&1 | tee -a "$log"

        if command -v thefuck &> /dev/null; then
            msg dn "thef*ck was installed successfully!" && sleep 1
        fi
    fi
fi

if command -v thefuck &> /dev/null; then
    echo "[ DONE ] - thefuck was installed successfully!" 2>&1 | tee -a "$log"
else
    echo "[ ERROR ] - Could not install thefuck" 2>&1 | tee -a "$log"
fi

if [[ ! "$SHELL" == "$(which fish)" ]]; then
    msg act "Changing shell to fish.."
    chsh -s "$(which fish)"
fi

sleep 1 && clear
