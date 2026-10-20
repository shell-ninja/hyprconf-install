#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/final_checkup-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ ! -f "$log" ]]; then
    mkdir -p "$log_dir"
    touch "$log"
fi

checkup=(
    quickshell
    hyprland
    hyprlock
    hypridle
    hyprcursor
    curl
    fastfetch
    ffmpeg
    git
    grim
    ImageMagick
    jq
    kitty
    kvantum-qt5
    kvantum-qt6
    kvantum-manager
    make
    neovim
    NetworkManager-applet
    nvtop
    pamixer
    playerctl
    pciutils
    pavucontrol
    pipewire-alsa
    python3-requests
    python3-Pillow
    python3-dbus-python
    qt5ct
    qt6ct
    qt6-declarative
    qt6-svg
    qt6-imageformats
    qt6-multimedia
    qt6-declarative-tools
    ripgrep
    satty
    slurp
    swappy
    awww
    tar
    unzip
    wget
    wl-clipboard
    xdg-utils
    yazi
    btop
    cava
    mpv
    mpv-mpris
    nwg-look
    fira-code-fonts
    fontawesome-fonts
    google-noto-sans-cjk-fonts
    google-noto-coloremoji-fonts
    liberation-fonts
    symbols-only-nerd-fonts
    libqt5-qtgraphicaleffects
    libqt5-qtquickcontrols
    libqt5-qtquickcontrols2
    sddm-qt6
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
)


# checking already installed packages 
for skipable in "${checkup[@]}"; do
    skip_installed "$skipable" &> /dev/null
done

to_install=($(printf "%s\n" "${checkup[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Verifying and installing any remaining packages
for _pkgs in "${to_install[@]}"; do
    msg act "Resolving missing package: $_pkgs..."
    sudo zypper in -y "$_pkgs"

    if sudo zypper se -i "$_pkgs" &> /dev/null; then
        msg dn "Package $_pkgs installed successfully."
        echo "[ DONE ] - $_pkgs was installed successfully!" >> "$log"
    else
        msg err "Failed to install $_pkgs (see $log)"
        echo "[ ERROR ] - Failed to install $_pkgs" >> "$log"
    fi
done

sleep 1 && clear
