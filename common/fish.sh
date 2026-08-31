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

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

cache_dir="$parent_dir/.cache"
pkgman_cache="$cache_dir/pkgman"
source "$pkgman_cache"

# install script dir
source "$parent_dir/${pkgman}-scripts/1-global_script.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/fish-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "fish" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi

else
    mkdir -p "$log_dir"
    touch "$log"
fi

# --- Packages Lists ---
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

installble_pkg=($(printf "%s\n" "${common_packages[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

for _pkgs in "${installble_pkg[@]}"; do
    install_package "$_pkgs"
    if command -v "$_pkgs" &>/dev/null; then
        echo -e "[ DONE ] - $_pkgs was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo -e "[ ERROR ] - Sorry, could not install $_pkgs!" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

# for opensuse only
if [[ "$pkgman" == "zypper" ]]; then
    for _pkgs in "${for_opensuse[@]}"; do
        install_package "$_pkgs"
        if sudo zypper se -i "$_pkgs" &>/dev/null; then
            echo -e "[ DONE ] - $_pkgs was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null
        else
            echo -e "[ ERROR ] - Sorry, could not install $_pkgs!" 2>&1 | tee -a "$log" &>/dev/null
        fi
    done
fi

# --- Change Default Shell ---
if [[ "$SHELL" != *"fish"* ]]; then
    msg act "Changing default shell to fish..."
    chsh -s "$(command -v fish)"
    msg dn "Shell changed. (You may need to log out and back in for this to take effect)."
else
    msg skp "fish is already the default shell."
fi

if [[ -d "$HOME/.config/fish/functions" ]]; then
    chmod +x "$HOME/.config/fish/functions"/* 2>&1 | tee -a "$log"
elif [[ -f "$HOME/.config/fish/functions.fish" ]]; then
    chmod +x "$HOME/.config/fish/functions.fish" 2>&1 | tee -a "$log"
fi


sleep 1 && clear
