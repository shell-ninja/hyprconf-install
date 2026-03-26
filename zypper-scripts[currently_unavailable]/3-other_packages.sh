#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

display_text() {
    gum style \
        --border rounded \
        --align center \
        --width 40 \
        --margin "1" \
        --padding "1" \
'
  ____  __  __             
 / __ \/ /_/ /  ___ _______
/ /_/ / __/ _ \/ -_) __(_-<
\____/\__/_//_/\__/_/ /___/
                             
'
}

clear && display_text
printf " \n \n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/hyprland-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

mkdir -p "$log_dir"
touch "$log"

# packages neeeded
hypr_package=( 
  curl
  ffmpeg
  fastfetch
  git
  gnome-disk-utility
  go1.23
  grim
  ImageMagick
  jq
  kitty
  kvantum-qt5
  kvantum-qt6
  kvantum-themes
  kvantum-manager
  less
  libnotify-tools
  lxappearance
  make
  neovim
  pamixer
  pavucontrol
  pciutils
  pipewire-alsa
  python312-requests
  qt5ct
  qt6ct
  qt6-svg-devel
  ripgrep
  libqt5-qtquickcontrols
  libqt5-qtquickcontrols2
  libqt5-qtgraphicaleffects
  nwg-look
  rofi-wayland
  slurp
  SwayNotificationCenter
  swappy
  awww
  tar
  unzip
  wayland-protocols-devel
  wget
  wl-clipboard
  xdg-utils
  xwayland
  yazi
)

other_packages=(
  btop
  cava
  mpv
  mpv-mpris
  nvtop
)

# no recommands
no_recommands=(
  eog
  NetworkManager-applet
  waybar
)

# thunar
thunar=(
ffmpegthumbnailer
file-roller
thunar 
thunar-volman 
tumbler 
thunar-plugin-archive
)

grimblast_url=https://github.com/hyprwm/contrib.git


# checking already installed packages 
for skipable in "${hypr_package[@]}" "${other_packages[@]}" "${no_recommands[@]}" "${thunar[@]}"; do
    skip_installed "$skipable"
done

to_install_hypr=($(printf "%s\n" "${hypr_package[@]}" | grep -vxFf "$installed_cache"))
to_install_others=($(printf "%s\n" "${other_packages[@]}" | grep -vxFf "$installed_cache"))
to_install_no_recommands=($(printf "%s\n" "${no_recommands[@]}" | grep -vxFf "$installed_cache"))
to_install_thunar=($(printf "%s\n" "${thunar[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# installing necessary packages
for packages in "${to_install_hypr[@]}" "${to_install_others[@]}"; do
  install_package "$packages"
    if sudo zypper se -i "$packages" &> /dev/null ; then
        echo "[ DONE ] - $packages was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $packages..." 2>&1 | tee -a "$log" &> /dev/null
    fi
done

# installing thunar
for pkgs in "${to_install_no_recommands[@]}" "${to_install_thunar[@]}"; do
  install_package_no_recommands "$pkgs"
    if sudo zypper se -i "$pkgs" &> /dev/null ; then
        echo "[ DONE ] - $pkgs was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $pkgs..." 2>&1 | tee -a "$log" &> /dev/null
    fi
done

# installing grimblast
if [ -f '/usr/local/bin/grimblast' ]; then
  msg skp "Skipping grimblast, it was already installed.."
  echo "[ DONE ] - Grimblast is already installed" 2>&1 | tee -a  "$log" &> /dev/null
else

  msg act "Installing grimblast..."
  git clone --depth=1 "$grimblast_url" ~/grimblast &> /dev/null
  cd "$HOME/grimblast/grimblast"
  make &> /dev/null
  sudo make install &> /dev/null

  sleep 1
  rm -rf ~/grimblast
  msg dn "Grimblast was installed successfully!"
  echo "[ DONE ] - Grimblast was installed successfully!" 2>&1 | tee -a  "$log" &> /dev/null
fi

sleep 2 && clear

# Install cliphist using go
if command -v go &> /dev/null; then
  msg act "Installing cliphist..."
  export PATH=$PATH:/usr/local/bin

  if go install go.senan.xyz/cliphist@latest 2>&1 | tee -a "$log" &> /dev/null; then
    # copy cliphist into /usr/local/bin for some reason it is installing in ~/go/bin
    sudo cp -r "$HOME/go/bin/cliphist" "/usr/local/bin/" 2>&1 | tee -a "$log" &> /dev/null
    msg dn "Cliphist was installed successfully!"
    echo "[ DONE ] - Cliphist was installed successfully!" 2>&1 | tee -a  "$log" &> /dev/null

    sudo rm -rf "$HOME/go"
  else
    msg err "Cliphist failed to install. Maybe there was an issue..."
    echo "[ ERROR ] - Could not install cliphist. (╥﹏╥)" 2>&1 | tee -a "$log" &> /dev/null
  fi
fi

sleep 2 && clear

chmod +x "$dir/pywal.sh"
"$dir/pywal.sh"

