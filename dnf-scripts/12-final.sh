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
    hyprsunset
    pyprland
    curl
    fastfetch
    ffmpeg-free
    git
    grim
    ImageMagick
    jq
    kitty
    kvantum
    kvantum-qt5
    libX11-devel
    libXext-devel
    make
    network-manager-applet
    NetworkManager-tui
    neovim
    nvtop
    pamixer
    playerctl
    pciutils
    pavucontrol
    pipewire-alsa
    pipewire-utils
    pipewire-pulse
    power-profiles-daemon
    pulseaudio-utils
    python3-requests
    python3-devel
    python3-gobject
    python3-pip
    python3-pillow
    python3-pyquery
    python3-dbus
    qt5ct
    qt6ct-kde
    qt6-qtsvg
    qt6-qtdeclarative
    qt6-qtimageformats
    qt6-qtmultimedia
    qt6-qt5compat
    ripgrep
    slurp
    satty
    tar
    unzip
    vte291
    wget2
    wl-clipboard
    xdg-utils
    yazi
    btop
    cava
    cliphist
    kde-partitionmanager
    mpv
    mpv-mpris
    nwg-look
    awww
    ark
    crudini
    dolphin
    gwenview
    okular
    fontawesome-fonts-all
    google-noto-sans-cjk-fonts
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    jetbrains-mono-fonts
    qt5-qtgraphicaleffects
    qt5-qtquickcontrols
    sddm
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-kde
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
    sudo dnf install -y "$_pkgs"

    if rpm -q "$_pkgs" &> /dev/null; then
        msg dn "Package $_pkgs installed successfully."
        echo "[ DONE ] - $_pkgs was installed successfully!" >> "$log"
    else
        msg err "Failed to install $_pkgs (see $log)"
        echo "[ ERROR ] - Failed to install $_pkgs" >> "$log"
    fi
done

sleep 1 && clear
