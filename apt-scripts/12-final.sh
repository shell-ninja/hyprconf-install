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
    hyprland
    hyprlock
    hypridle
    hyprland-guiutils
    hyprcursor-util
    hyprsunset
    pypr
    curl
    fastfetch
    ffmpeg
    git
    grim
    imagemagick
    jq
    kitty
    qt5-style-kvantum
    libx11-dev
    libxext-dev
    lxappearance
    make
    network-manager-gnome
    network-manager
    neovim
    nvtop
    pamixer
    pciutils
    pavucontrol
    pipewire-alsa
    pipewire-bin
    pipewire-pulse
    power-profiles-daemon
    pulseaudio-utils
    python3-requests
    python3-dev
    python3-gi
    python3-pip
    python3-pil
    python3-pyquery
    qt5ct
    qt6ct
    libqt6svg6
    ripgrep
    slurp
    tar
    unzip
    wget
    wl-clipboard
    xdg-utils
    btop
    cava
    cliphist
    gnome-disk-utility
    mpv
    mpv-mpris
    nwg-look
    pamixer
    awww
    crudini
    thunar
    thunar-archive-plugin
    file-roller
    fonts-font-awesome
    fonts-noto-cjk
    fonts-noto-color-emoji
    fonts-noto-core
    fonts-jetbrains-mono
    qml-module-qtgraphicaleffects
    qml-module-qtquick-controls2
    sddm
    qt6-qt5compat 
    qt6-qtdeclarative 
    libqt6svg6
    xdg-desktop-portal-hyprland
)


# checking already installed packages 
for skipable in "${checkup[@]}"; do
    skip_installed "$skipable" &> /dev/null
done

to_install=($(printf "%s\n" "${hypr_packages[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Instlling main packages...
for _pkgs in "${to_install[@]}"; do
    msg act "Somehow $_pkgs could not be installed before. Installing it now..."
    sudo apt-get install -y "$_pkgs"

    if dpkg -s "$_pkgs" &> /dev/null; then

        msg dn "Finally $_pkgs was installed successfully!"
        echo

        echo "[ DONE ] - $_pkgs was installed successfully!\n" 2>&1 | tee -a "$log" &> /dev/null
    else

        msg err "Sorry, this time also could not install $_pkgs.."
        echo

        echo "[ ERROR ] - Sorry, could not install $_pkgs!\n" 2>&1 | tee -a "$log" &> /dev/null
    fi
done

sleep 1 && clear
