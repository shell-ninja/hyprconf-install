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
 ________                
/_  __/ /  ___ __ _  ___ 
 / / / _ \/ -_)  ; \/ -_)
/_/ /_//_/\__/_/_/_/\__/ 
                          
                               
'
}

clear && display_text
printf " \n \n"

printf " \n"

###------ Startup ------###

# finding the presend directory and log file
# install script dir
dir="$(dirname "$(realpath "$0")")"

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/themes-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

assets_dir="$parent_dir/assets"
icons_dir="$HOME/.icons"
mkdir -p "$icons_dir"

###------ Cursor Theme: Bibata-Modern-Ice ------###
bibata_archive="$assets_dir/Bibata-Modern-Ice.tar.gz"
if [[ -f "$bibata_archive" ]]; then
    msg act "Installing Bibata-Modern-Ice cursor theme..."
    tar -xzf "$bibata_archive" -C "$icons_dir/" --strip-components=1 &>/dev/null
    if [[ -d "$icons_dir/Bibata-Modern-Ice" ]]; then
        sudo cp -r "$icons_dir/Bibata-Modern-Ice" /usr/share/icons/ &>/dev/null
        msg dn "Bibata-Modern-Ice cursor theme installed."
        echo "[ DONE ] - Bibata-Modern-Ice cursor theme installed." >>"$log"
    else
        msg err "Failed to extract Bibata-Modern-Ice."
        echo "[ ERROR ] - Bibata-Modern-Ice extraction failed." >>"$log"
    fi
else
    msg skp "Bibata-Modern-Ice archive not found in assets, skipping..."
fi

###------ Icon Theme: Kora ------###
kora_archive="$assets_dir/kora-2-0-4.tar.xz"
if [[ -f "$kora_archive" ]]; then
    msg act "Installing Kora icon theme..."
    tar -xJf "$kora_archive" -C "$icons_dir" &>/dev/null
    # Kora archives may extract a versioned subdir; find and copy all kora* dirs
    if ls "$icons_dir"/kora* &>/dev/null 2>&1; then
        sudo cp -r "$icons_dir"/kora* /usr/share/icons/ &>/dev/null
        msg dn "Kora icon theme installed."
        echo "[ DONE ] - Kora icon theme installed." >>"$log"
    else
        msg err "Failed to extract Kora icon theme."
        echo "[ ERROR ] - Kora extraction failed." >>"$log"
    fi
else
    msg skp "Kora archive not found in assets, skipping..."
fi

###------ Icon Theme: Tokyo Night ------###
tokyo_url="https://github.com/ljmill/tokyo-night-icons/releases/download/v0.2.0/TokyoNight-SE.tar.bz2"
tokyo_archive="$parent_dir/.cache/TokyoNight-SE.tar.bz2"
mkdir -p "$parent_dir/.cache"
if [[ ! -d "$icons_dir/TokyoNight-SE" ]]; then
    msg act "Downloading Tokyo Night icon theme..."
    curl -sL "$tokyo_url" -o "$tokyo_archive" 2>>"$log"
    if [[ -f "$tokyo_archive" ]]; then
        tar -xjf "$tokyo_archive" -C "$icons_dir" &>/dev/null
        rm -f "$tokyo_archive"
        if [[ -d "$icons_dir/TokyoNight-SE" ]]; then
            sudo cp -r "$icons_dir/TokyoNight-SE" /usr/share/icons/ &>/dev/null
            msg dn "Tokyo Night icon theme installed."
            echo "[ DONE ] - Tokyo Night icon theme installed." >>"$log"
        else
            msg err "Failed to extract Tokyo Night icons."
            echo "[ ERROR ] - Tokyo Night extraction failed." >>"$log"
        fi
    else
        msg err "Failed to download Tokyo Night icon theme."
        echo "[ ERROR ] - Tokyo Night download failed." >>"$log"
    fi
else
    msg skp "Tokyo Night already installed, skipping..."
fi

###------ adw-gtk3 Theme (required for Noctalia shell) ------###

pkgman_cache="$parent_dir/.cache/pkgman"
pkgman=""
if [[ -f "$pkgman_cache" ]]; then
    source "$pkgman_cache"
fi

install_adw_gtk3() {
    msg act "Installing adw-gtk3 theme (required for Noctalia shell)..."

    case "$pkgman" in
        pacman)
            # Arch: official repos; Manjaro: use pamac if available
            if command -v pamac &>/dev/null; then
                pamac install --no-confirm adw-gtk3 2>&1 | tee -a "$log" &>/dev/null
            else
                aur_helper=$(cat "$parent_dir/.cache/aur" 2>/dev/null | tr -d '[:space:]')
                if command -v "$aur_helper" &>/dev/null; then
                    "$aur_helper" -S --noconfirm adw-gtk-theme 2>&1 | tee -a "$log" &>/dev/null
                else
                    sudo pacman -S --noconfirm adw-gtk-theme 2>&1 | tee -a "$log" &>/dev/null
                fi
            fi
            ;;
        dnf)
            sudo dnf install -y adw-gtk3-theme 2>&1 | tee -a "$log" &>/dev/null
            ;;
        apt)
            msg act "Adding Julian Fairfax's package repo for adw-gtk3 (Debian/Ubuntu)..."
            # Add GPG key
            curl -s https://julianfairfax.gitlab.io/package-repo/pub.gpg \
                | gpg --dearmor \
                | sudo dd of=/usr/share/keyrings/julians-package-repo.gpg 2>/dev/null
            # Add repo source
            echo 'deb [ signed-by=/usr/share/keyrings/julians-package-repo.gpg ] https://julianfairfax.gitlab.io/package-repo/debs packages main' \
                | sudo tee /etc/apt/sources.list.d/julians-package-repo.list >/dev/null
            sudo apt update -qq 2>&1 | tee -a "$log" &>/dev/null
            sudo apt install -y adw-gtk3 2>&1 | tee -a "$log" &>/dev/null
            ;;
        zypper)
            msg act "Adding OBS community repo for adw-gtk3 (openSUSE)..."
            # Detect Tumbleweed vs Leap
            local obs_repo
            if grep -qi "tumbleweed" /etc/os-release 2>/dev/null; then
                obs_repo="https://download.opensuse.org/repositories/home:soupglasses/openSUSE_Tumbleweed/home:soupglasses.repo"
            else
                local leap_ver
                leap_ver=$(grep "^VERSION_ID=" /etc/os-release 2>/dev/null | cut -d'"' -f2)
                obs_repo="https://download.opensuse.org/repositories/home:soupglasses/openSUSE_Leap_${leap_ver}/home:soupglasses.repo"
            fi
            sudo zypper addrepo --refresh "$obs_repo" 2>&1 | tee -a "$log" &>/dev/null
            sudo zypper --gpg-auto-import-keys refresh 2>&1 | tee -a "$log" &>/dev/null
            sudo zypper install -y adw-gtk3 2>&1 | tee -a "$log" &>/dev/null
            ;;
        *)
            msg skp "Unknown package manager '$pkgman'. Skipping adw-gtk3 installation."
            return
            ;;
    esac

    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f -t ~/.local/share/themes/adw-gtk3 &>/dev/null || true
        gtk-update-icon-cache -f -t ~/.local/share/themes/adw-gtk3-dark &>/dev/null || true
    fi

    msg dn "adw-gtk3 theme installed successfully."
    echo "[ DONE ] - adw-gtk3 theme installed." >>"$log"
}

install_adw_gtk3

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' &> /dev/null
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" &> /dev/null

sleep 1 && clear
