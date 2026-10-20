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

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/others-$(date +%d-%m-%y).log"

# log directory
if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "yazi" "$log" | awk '{print $2}')
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "System utility packages already installed. Skipping..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

main_packages=(
    quickshell
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
    less
    libX11-devel
    libXext-devel
    make
    network-manager-applet
    NetworkManager-tui
    nodejs
    nodejs-npm
    neovim
    nvtop
    pamixer
    parallel
    pciutils
    pavucontrol
    pipewire-alsa
    pipewire-utils
    pipewire-pulse
    playerctl
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
)

# other necessary packages
other_packages=(
    btop
    cava
    cliphist
    kde-partitionmanager
    mpv
    mpv-mpris
    nwg-look
    awww
)

dolphin=(
    ark
    crudini
    dolphin
    gwenview
    okular
)

# url to install grimblast
grimblast_url=https://github.com/hyprwm/contrib.git

# checking already installed packages 
for skipable in "${main_packages[@]}" "${other_packages[@]}" "${dolphin[@]}"; do
    skip_installed "$skipable"
done

installble_main_pkg=($(printf "%s\n" "${main_packages[@]}" | grep -vxFf "$installed_cache"))
installble_other_pkg=($(printf "%s\n" "${other_packages[@]}" | grep -vxFf "$installed_cache"))
installble_dolphin_pkg=($(printf "%s\n" "${dolphin[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# installing necessary packages
for packages in "${installble_main_pkg[@]}" "${installble_other_pkg[@]}" "${installble_dolphin_pkg[@]}"; do
  install_package "$packages"
  if rpm -q "$packages" &> /dev/null; then
    echo "[ DONE ] - $packages was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
  else
    echo "[ ERROR ] - Failed to install '$packages'" >> "$log"
  fi
done

# installing grimblast
if [ -f '/usr/local/bin/grimblast' ]; then
  msg dn "Grimblast is already installed."
else
  msg act "Building and installing Grimblast..."
  git clone --depth=1 "$grimblast_url" "$parent_dir/.cache/grimblast/" 2>&1 | tee -a "$log" &> /dev/null
  cd "$parent_dir/.cache/grimblast/grimblast"
  make 2>&1 | tee -a "$log" &> /dev/null
  sudo make install 2>&1 | tee -a "$log" &> /dev/null

  sleep 1
  rm -rf "$parent_dir/.cache/grimblast" 2>&1 | tee -a "$log"
fi

if [ -f '/usr/local/bin/grimblast' ]; then
  msg dn "Grimblast installed successfully."
  echo "[ DONE ] - Grimblast was installed successfully." >> "$log"
fi

sleep 1 && clear
