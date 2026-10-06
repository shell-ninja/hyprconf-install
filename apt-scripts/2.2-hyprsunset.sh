#!/usr/bin/env bash

dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/hyprland-$(date +%d-%m-%y).log"

is_debian_13=false
if grep -qiE 'trixie|version_id="?13"?' /etc/os-release 2>/dev/null; then
    is_debian_13=true
fi

# building hyprsunset
if ! command -v hyprsunset &> /dev/null; then
    msg act "Building hyprsunset..."
    if [[ "$is_debian_13" == true ]]; then
        sudo apt-get install -y -t trixie-backports cmake pkg-config libwayland-dev wayland-protocols libxkbcommon-dev hyprland-protocols hyprwayland-scanner libhyprlang-dev libhyprutils-dev
    else
        sudo apt-get install -y cmake pkg-config libwayland-dev wayland-protocols libxkbcommon-dev hyprland-protocols hyprwayland-scanner libhyprlang-dev libhyprutils-dev
    fi
    git clone --depth=1 https://github.com/hyprwm/hyprsunset.git "$parent_dir/.cache/hyprsunset" 2>&1 | tee -a "$log"
    cd "$parent_dir/.cache/hyprsunset"
    
    if [ -f CMakeLists.txt ]; then
        cmake -S . -B build -DCMAKE_BUILD_TYPE=Release 2>&1 | tee -a "$log"
        cmake --build build -j "$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)" 2>&1 | tee -a "$log"
        sudo cmake --install build 2>&1 | tee -a "$log"
    elif [ -f meson.build ]; then
        sudo apt-get install -y meson ninja-build
        meson setup build --buildtype=release 2>&1 | tee -a "$log"
        meson compile -C build 2>&1 | tee -a "$log"
        sudo meson install -C build 2>&1 | tee -a "$log"
    fi
    cd ~
    rm -rf "$parent_dir/.cache/hyprsunset"

    if command -v hyprsunset &> /dev/null; then
        msg dn "hyprsunset was installed successfully!"
    else
        msg err "hyprsunset failed to install..."
    fi
else
    msg dn "hyprsunset is already installed..."
fi
