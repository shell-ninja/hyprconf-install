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

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/others-$(date +%d-%m-%y).log"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "thunar-plugin-archive" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

# packages neeeded
hypr_package=( 
  curl
  ffmpeg
  fastfetch
  git
  gnome-disk-utility
  go
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
  python313-requests
  qt5ct
  qt6ct
  qt6-svg-devel
  ripgrep
  libqt5-qtquickcontrols
  libqt5-qtquickcontrols2
  libqt5-qtgraphicaleffects
  nwg-look
  slurp
  swappy
  tar
  unzip
  wayland-protocols-devel
  wget
  wl-clipboard
  xdg-utils
  xwayland
)

other_packages=(
  btop
  cava
  mpv
  mpv-mpris
  nvtop
  awww
  # noctalia: not in official openSUSE repos yet.
  # Install manually from https://github.com/linkfrg/noctalia
)

# no recommands
no_recommands=(
  eog
  NetworkManager-applet
)

# dolphin
dolphin=(
    ark
    crudini
    dolphin
    gwenview
    okular
)

grimblast_url=https://github.com/hyprwm/contrib.git


# checking already installed packages 
for skipable in "${hypr_package[@]}" "${other_packages[@]}" "${no_recommands[@]}" "${dolphin[@]}"; do
    skip_installed "$skipable"
done

to_install_hypr=($(printf "%s\n" "${hypr_package[@]}" | grep -vxFf "$installed_cache"))
to_install_others=($(printf "%s\n" "${other_packages[@]}" | grep -vxFf "$installed_cache"))
to_install_no_recommands=($(printf "%s\n" "${no_recommands[@]}" | grep -vxFf "$installed_cache"))
to_install_dolphin=($(printf "%s\n" "${dolphin[@]}" | grep -vxFf "$installed_cache"))

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

# installing dolphin
for pkgs in "${to_install_no_recommands[@]}" "${to_install_dolphin[@]}"; do
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
  git clone --depth=1 "$grimblast_url" "$parent_dir/.cache/grimblast/" &> /dev/null
  cd "$parent_dir/.cache/grimblast/grimblast"
  make &> /dev/null
  sudo make install &> /dev/null

  sleep 1
  rm -rf "$parent_dir/.cache/grimblast"
  msg dn "Grimblast was installed successfully!"
  echo "[ DONE ] - Grimblast was installed successfully!" 2>&1 | tee -a  "$log" &> /dev/null
fi

sleep 2 && clear

# Install cliphist using go
if command -v go &> /dev/null; then
  msg act "Installing cliphist..."
  export PATH=$PATH:/usr/local/bin

  if go install go.senan.xyz/cliphist@latest 2>&1 | tee -a "$log" &> /dev/null; then
    # copy cliphist into /usr/local/bin (go installs to ~/go/bin by default)
    sudo cp -r "$HOME/go/bin/cliphist" "/usr/local/bin/" 2>&1 | tee -a "$log" &> /dev/null
    msg dn "Cliphist was installed successfully!"
    echo "[ DONE ] - Cliphist was installed successfully!" 2>&1 | tee -a  "$log" &> /dev/null

    # only remove the cliphist binary from ~/go/bin, not the whole go directory
    rm -f "$HOME/go/bin/cliphist"
  else
    msg err "Cliphist failed to install. Maybe there was an issue..."
    echo "[ ERROR ] - Could not install cliphist. (╥﹏╥)" 2>&1 | tee -a "$log" &> /dev/null
  fi
fi

sleep 2 && clear
