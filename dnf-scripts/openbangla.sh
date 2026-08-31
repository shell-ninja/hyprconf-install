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
log="$log_dir/openbangla-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

mkdir -p "$log_dir" "$cache_dir"
touch "$log"

# Dependencies
openbangla_pkgs=(
    @development-tools
    rust
    cargo
    cmake
    qt5-qtdeclarative-devel
    libzstd-devel
    fcitx5
    fcitx5-configtool
    fcitx5-devel
    fcitx5-qt5
    git
)

msg act "Checking dependencies for Fcitx5 and OpenBangla Keyboard..."

# checking already installed packages
for pkg in "${openbangla_pkgs[@]}"; do
    skip_installed "$pkg"
done

to_install=($(printf "%s\n" "${openbangla_pkgs[@]}" | grep -vxFf "$installed_cache"))

if [[ ${#to_install[@]} -gt 0 ]]; then
    for pkg in "${to_install[@]}"; do
        install_package "$pkg" 2>&1 | tee -a "$log"
    done
fi

msg act "Building OpenBangla Keyboard from source (develop branch)..."

build_dir="$cache_dir/openbangla-keyboard"
if [[ -d "$build_dir" ]]; then
    msg nt "Removing existing OpenBangla build directory in cache..."
    rm -rf "$build_dir"
fi

git clone --recursive https://github.com/OpenBangla/OpenBangla-Keyboard.git "$build_dir" 2>&1 | tee -a "$log" || {
    msg err "Could not clone OpenBangla Keyboard repository"
    echo "[ ERROR ] - Could not clone OpenBangla Keyboard repository" >> "$log"
    exit 1
}

cd "$build_dir" || {
    msg err "Unable to change directory to $build_dir"
    exit 1
}

git checkout develop 2>&1 | tee -a "$log" || {
    msg err "Unable to checkout develop branch"
    echo "[ ERROR ] - Unable to checkout develop branch" >> "$log"
    exit 1
}

git submodule update --init --recursive 2>&1 | tee -a "$log" || {
    msg err "Unable to update git submodules"
    echo "[ ERROR ] - Unable to update git submodules" >> "$log"
    exit 1
}

mkdir -p build && cd build || {
    msg err "Unable to create and change to build directory"
    exit 1
}

cmake .. -DCMAKE_INSTALL_PREFIX="/usr" -DENABLE_FCITX=ON 2>&1 | tee -a "$log" || {
    msg err "CMake configuration failed for OpenBangla Keyboard"
    echo "[ ERROR ] - CMake configuration failed" >> "$log"
    exit 1
}

make -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF || echo 2)" 2>&1 | tee -a "$log" || {
    msg err "Build failed for OpenBangla Keyboard"
    echo "[ ERROR ] - Build failed" >> "$log"
    exit 1
}

sudo make install 2>&1 | tee -a "$log" || {
    msg err "Installation failed for OpenBangla Keyboard"
    echo "[ ERROR ] - Installation failed" >> "$log"
    exit 1
}

# Cleanup build directory
cd "$parent_dir" || cd ~
rm -rf "$build_dir"

msg dn "OpenBangla Keyboard and Fcitx5 installed successfully!"
echo "[ DONE ] - OpenBangla Keyboard and Fcitx5 installed successfully!" >> "$log"

sleep 1 && clear
