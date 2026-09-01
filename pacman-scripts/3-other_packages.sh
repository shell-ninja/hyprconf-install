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
log="$log_dir/others-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "thunar-archive-plugin" "$log" | awk {'print $2'})
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


# any other packages will be installed from here
other_packages=(
    awww
    btop
    cliphist
    curl
    gtk-layer-shell
    fastfetch
    ffmpeg
    hyprland-guiutils
    partitionmanager
    imagemagick
    jq
    kitty
    kvantum
    kvantum-qt5
    less
    lxappearance
    mpv-mpris
    network-manager-applet
    networkmanager
    neovim
    nodejs
    npm
    ntfs-3g
    nvtop
    nwg-look
    os-prober
    pacman-contrib
    pamixer
    pavucontrol
    parallel
    pciutils
    power-profiles-daemon
    python-gobject
    qt5ct
    qt5-svg
    qt6ct-kde
    qt6-svg
    qt5-graphicaleffects
    qt5-quickcontrols2
    ripgrep
    satty
    unzip
    vte3
    vte4
    wget
    wl-clipboard
    xorg-xrandr
    zip
)

aur_packages=(
    cava
    grimblast-git
    noctalia
    tty-clock
    pyprland
)

dolphin=(
    ark
    dolphin
    gwenview
    okular
)

crunini_pkg=(
    crudini
    python-iniparse
)

# checking already installed packages 
for skipable in "${other_packages[@]}" "${aur_packages[@]}" "${dolphin[@]}" "${crunini_pkg[@]}"; do
    skip_installed "$skipable"
done

installble_pkg=($(printf "%s\n" "${other_packages[@]}" | grep -vxFf "$installed_cache"))
installble_aur_pkg=($(printf "%s\n" "${aur_packages[@]}" | grep -vxFf "$installed_cache"))
installble_dolphin_pkg=($(printf "%s\n" "${dolphin[@]}" | grep -vxFf "$installed_cache"))
installble_crunini_pkg=($(printf "%s\n" "${crunini_pkg[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

for _pkgs in "${installble_pkg[@]}" "${installble_aur_pkg[@]}" "${installble_dolphin_pkg[@]}"; do
    install_package "$_pkgs"
    if sudo pacman -Q "$_pkgs" &>/dev/null; then
        echo "[ DONE ] - $_pkgs was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $_pkgs!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done

for _pkgs in "${installble_crunini_pkg[@]}"; do
    install_package_nocheck "$_pkgs"
    if sudo pacman -Q "$_pkgs" &>/dev/null; then
        echo "[ DONE ] - $_pkgs was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $_pkgs!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done


sleep 1 && clear
