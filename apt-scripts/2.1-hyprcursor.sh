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

# building hyprcursor
if ! command -v hyprcursor-util &> /dev/null; then
    msg act "Building hyprcursor..."
    if [[ "$is_debian_13" == true ]]; then
        sudo apt-get install -y -t trixie-backports cmake pkg-config libzip-dev librsvg2-dev libtomlplusplus-dev libcairo2-dev libhyprlang-dev libhyprutils-dev
    else
        sudo apt-get install -y cmake pkg-config libzip-dev librsvg2-dev libtomlplusplus-dev libcairo2-dev libhyprlang-dev libhyprutils-dev
    fi
    git clone --depth=1 https://github.com/hyprwm/hyprcursor.git "$parent_dir/.cache/hyprcursor" 2>&1 | tee -a "$log"
    cd "$parent_dir/.cache/hyprcursor"
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B build 2>&1 | tee -a "$log"
    cmake --build build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)" 2>&1 | tee -a "$log"
    sudo cmake --install build 2>&1 | tee -a "$log"
    cd ~
    rm -rf "$parent_dir/.cache/hyprcursor"

    if command -v hyprcursor-util &> /dev/null; then
        msg dn "hyprcursor was installed successfully!"
    else
        msg err "hyprcursor failed to install..."
    fi
else
    msg dn "hyprcursor is already installed..."
fi
