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
log="$log_dir/bash-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# bash backup dir
BACKUP_DIR="$HOME/.bash-backup-${USER}"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "pv" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi

else
    mkdir -p "$log_dir"
    touch "$log"
fi

# Required packages
common_packages=(
    bash-completion
    bat
    curl
    eza
    fastfetch
    figlet
    fzf
    git
    less
    rsync
    starship
    zoxide
    pv
)

for_opensuse=(
    python311
    python311-pip
    python311-pipx
)

# checking already installed packages 
for skipable in "${common_packages[@]}"; do
    skip_installed "$skipable"
done

installble_pkg=($(printf "%s\n" "${common_packages[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

for _pkgs in "${installble_pkg[@]}"; do
    install_package "$_pkgs"
    if command -v "$_pkgs" &>/dev/null || [[ "$_pkgs" == "bash-completion" && ( -f /usr/share/bash-completion/bash_completion || -f /etc/bash_completion || -d /usr/share/bash-completion ) ]]; then
        echo -e "[ DONE ] - $_pkgs was installed successfully!" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo -e "[ ERROR ] - Could not install $_pkgs!" 2>&1 | tee -a "$log" &>/dev/null
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

msg act "Installing bash files..." && sleep 0.5

# Backup existing files
for item in "$HOME/.bash" "$HOME/.bashrc"; do
    if [[ -d $item ]] || [[ -f $item ]]; then
        mkdir -p "$BACKUP_DIR"
        timestamp=$(date +%I:%M:%S%p)
        if [[ -d $item ]]; then
            msg att "A ${green}.bash${end} directory is available. Backing it up..." 
            mv "$item" "$BACKUP_DIR/.bash-$timestamp" 2>&1 | tee -a "$log"
        elif [[ -f $item ]]; then
            msg att "A ${cyan}.bashrc${end} file is available. Backing it up..." 
            mv "$item" "$BACKUP_DIR/.bashrc-$timestamp" 2>&1 | tee -a "$log"
        fi
    fi
done

# Copy custom .bash directory
if [[ -d "$parent_dir/shell/bash" ]]; then
    cp -r "$parent_dir/shell/bash" ~/.bash 2>&1 | tee -a "$log"
    [[ -f "$HOME/.bash/.bashrc" ]] && ln -sf ~/.bash/.bashrc ~/.bashrc 2>&1 | tee -a "$log"
else
    msg err "Could not find $parent_dir/shell/bash to copy!"
fi

# Update scripts and install ble.sh
if [ -d ~/.bash ]; then
    msg act "Installing ble.sh (nightly)..." && sleep 1

    TMP_BLE=$(mktemp -d)
    if curl -sL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$TMP_BLE" 2>&1 | tee -a "$log" > /dev/null; then
        bash "$TMP_BLE/ble-nightly/ble.sh" --install ~/.local/share 2>&1 | tee -a "$log" > /dev/null
    else
        msg err "Failed to download or extract ble.sh"
    fi
    rm -rf "$TMP_BLE"

    if [ -f ~/.blerc ]; then
        msg act "Backing up ~/.blerc file..."
        mkdir -p "$BACKUP_DIR"
        mv ~/.blerc "$BACKUP_DIR/.blerc-$(date +%I:%M:%S%p)" 2>&1 | tee -a "$log"
    fi
    # Link the new .blerc if it exists in .bash
    [[ -f ~/.bash/.blerc ]] && ln -sf ~/.bash/.blerc ~/.blerc 2>&1 | tee -a "$log"

fi

# Make scripts executable
if [[ -d "$HOME/.bash" ]]; then
    if chmod +x "$HOME/.bash"/* 2>/dev/null; then
        msg dn "Bash configuration has been completed! Close the terminal and open it again." && sleep 2
        exit 0
    else
        msg err "Could not make all the scripts executable."
        printf " Run: \n \"chmod +x ~/.bash/*\" in your terminal\n"
    fi
fi

clear
