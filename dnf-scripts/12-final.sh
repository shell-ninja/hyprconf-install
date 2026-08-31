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
    lxappearance
    make
    network-manager-applet
    NetworkManager-tui
    neovim
    nvtop
    pamixer
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
    python3-devel
    python3-pip
    python3-pillow
    python3-pyquery
    qt5ct
    qt6ct-kde
    qt6-qtsvg
    ripgrep
    slurp
    satty
    tar
    unzip
    wget2
    wl-clipboard
    xdg-utils
    btop
    cava
    cliphist
    kde-partitionmanager
    mpv
    mpv-mpris
    nwg-look
    pamixer
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
    qt6-qt5compat 
    qt6-qtdeclarative 
    qt6-qtsvg
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-kde
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
    sudo dnf install -y "$_pkgs"

    if rpm -q "$_pkgs" &> /dev/null; then

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
