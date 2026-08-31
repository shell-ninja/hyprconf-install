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
log="$log_dir/hyprland-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    last_installed=$(grep "hypridle" "$log" | awk {'print $2'})
    if [[ -z "$errors" && "$last_installed" == "DONE" ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi
else
    mkdir -p "$log_dir"
    touch "$log"
fi

hypr_pkgs=(
    hyprland
    hyprcursor
    hyprland-protocols-devel
    wayland-protocols-devel
    hyprutils-devel
    hyprwayland-scanner
    hypridle
)

hypr_python=(
  python314-aiofiles
  python314-pip
  python314-pipx
  python-base
)

# checking already installed packages 
for skipable in "${hypr_pkgs[@]}" "${hypr_python[@]}"; do
    skip_installed "$skipable"
done

to_install=($(printf "%s\n" "${hypr_pkgs[@]}" | grep -vxFf "$installed_cache"))
to_install_python=($(printf "%s\n" "${hypr_python[@]}" | grep -vxFf "$installed_cache"))

printf "\n\n"

# Hyprland and related packages
for packages in "${to_install[@]}"; do
  install_package "$packages"

    if sudo zypper se -i "$packages" &> /dev/null ; then
        echo "[ DONE ] - $packages was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $packages..." 2>&1 | tee -a "$log" &> /dev/null
    fi
done

# Python helpers
for others in "${to_install_python[@]}"; do
  install_package "$others"

    if sudo zypper se -i "$others" &> /dev/null ; then
        echo "[ DONE ] - $others was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        echo "[ ERROR ] - Could not install $others..." 2>&1 | tee -a "$log" &> /dev/null
    fi
done

# Hyprland Plugins
# pyprland https://github.com/hyprland-community/pyprland
# Install via pipx if available (installed via python312-pipx above)
if ! command -v pypr &> /dev/null && [ ! -x "$HOME/.local/bin/pypr" ]; then
    msg act "Installing pyprland..."

    if command -v pipx &> /dev/null; then
        pipx install pyprland 2>&1 | tee -a "$log"
    else
        msg err "pipx not found. Cannot install pyprland automatically."
        echo "[ ERROR ] - pipx not found, skipping pyprland install" 2>&1 | tee -a "$log" &> /dev/null
    fi

    if command -v pypr &> /dev/null || [ -x "$HOME/.local/bin/pypr" ]; then
        msg dn "pyprland was installed successfully!"
        echo "[ DONE ] - pyprland was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    else
        msg err "pyprland failed to install..."
        echo "[ ERROR ] - pyprland failed to install" 2>&1 | tee -a "$log" &> /dev/null
    fi
else
    msg skp "pyprland is already installed. Skipping..."
fi

sleep 1 && clear
