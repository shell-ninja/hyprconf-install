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
 ____  ______ __
/_  / / __/ // /
 / /__\ \/ _  / 
/___/___/_//_/  
                
                               
'
}

clear && display_text
printf " \n \n"

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
log="$log_dir/zsh-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# zsh backup dir
BACKUP_DIR="$HOME/.zsh-backup-${USER}"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "zsh" "$log" | awk {'print $2'})
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
    fzf 
    git 
    rsync 
    starship 
    zoxide 
    zsh
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
if [[ "$SHELL" != *"zsh"* ]]; then
    msg act "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)"
    msg dn "Shell changed. (You may need to log out and back in for this to take effect)."
else
    msg skp "zsh is already the default shell."
fi

sleep 1
msg act "Proceeding to configure ZSH environment..."

# --- Backup Existing Configs ---
mkdir -p "$BACKUP_DIR"
timestamp=$(date +%I:%M:%S%p)
for item in "$HOME/.zsh" "$HOME/.zshrc"; do
    if [[ -e $item ]]; then
        msg att "Found existing $(basename "$item"), backing it up to $BACKUP_DIR"
        mv "$item" "$BACKUP_DIR/$(basename "$item")-$timestamp" 2>&1 | tee -a "$log"
    fi
done

sleep 1

# --- Copy New Configs ---
msg act "Copying new configurations..."

if [[ -d "$parent_dir/shell/zsh" ]]; then
    cp -r "$parent_dir/shell/zsh" "$HOME/.zsh"
    ln -sf "$HOME/.zsh/.zshrc" "$HOME/.zshrc"
    msg dn "Installation and configuration of ZSH finished!"
else
    msg err "Could not find .zsh directory. Config copy failed."
fi

# Make scripts executable
if [[ -d "$HOME/.zsh" ]]; then
    chmod +x "$HOME/.zsh"/*.zsh "$HOME/.zsh"/*.sh 2>/dev/null
fi

clear