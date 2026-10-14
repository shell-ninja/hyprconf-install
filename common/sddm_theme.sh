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

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/sddm_theme-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

# Paths
theme_name="prohori"
theme_dir="/usr/share/sddm/themes"
sddm_conf_dir="/etc/sddm.conf.d"
cache_dir="$parent_dir/.cache"
target_dir="$cache_dir/$theme_name"

# Ensure sddm theme directory exists
[ ! -d "$theme_dir" ] && sudo mkdir -p "$theme_dir"
[ ! -d "$sddm_conf_dir" ] && sudo mkdir -p "$sddm_conf_dir"

# ── Download Theme ──────────────────────────────────────────────────────── #
msg act "Downloading 'Prohori' SDDM theme..."

# Clean any previous cached download
sudo rm -rf "$target_dir"
mkdir -p "$cache_dir"

# Primary: git clone (no unzip needed, reliable)
if command -v git &>/dev/null; then
    git clone --depth=1 "https://github.com/shell-ninja/prohori.git" "$target_dir" 2>&1 | tee -a "$log"
fi

# Fallback: curl + unzip
if [[ ! -d "$target_dir" || -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
    msg att "git clone failed, trying curl fallback..."
    zip_path="$cache_dir/${theme_name}.zip"
    url="https://github.com/shell-ninja/prohori/archive/refs/heads/main.zip"
    curl -L "$url" -o "$zip_path" 2>&1 | tee -a "$log"

    if [[ -f "$zip_path" ]]; then
        rm -rf "$target_dir"
        mkdir -p "$target_dir"
        if command -v unzip &>/dev/null; then
            unzip -q "$zip_path" "prohori-main/*" -d "$target_dir" > /dev/null 2>&1
            # Flatten the nested directory
            if [[ -d "$target_dir/prohori-main" ]]; then
                mv "$target_dir/prohori-main/"* "$target_dir/" 2>/dev/null || true
                rmdir "$target_dir/prohori-main" 2>/dev/null || true
            fi
        else
            # Python fallback if unzip is unavailable
            python3 -c "
import zipfile, os, shutil
zf = zipfile.ZipFile('$zip_path')
zf.extractall('$target_dir')
inner = os.path.join('$target_dir', 'prohori-main')
if os.path.isdir(inner):
    for item in os.listdir(inner):
        shutil.move(os.path.join(inner, item), '$target_dir')
    os.rmdir(inner)
" 2>&1 | tee -a "$log"
        fi
        rm -f "$zip_path"
    fi
fi

# Fallback: check local repository if network download failed
if [[ ! -d "$target_dir" || -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
    for local_repo in "$parent_dir/../prohori" "/main/Code/shell-ninja/prohori"; do
        if [[ -d "$local_repo" && -f "$local_repo/install.sh" ]]; then
            msg att "Network download failed, copying from local repository ($local_repo)..."
            mkdir -p "$target_dir"
            cp -rf "$local_repo/"* "$target_dir/" 2>/dev/null || true
            break
        fi
    done
fi

# Verify download succeeded
if [[ ! -d "$target_dir" || -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
    msg err "Failed to download prohori theme. Check your internet connection."
    echo "[ ERROR ] - prohori download failed" >> "$log"
    exit 1
fi

echo "[ DONE ] - prohori downloaded successfully" >> "$log"

# ── Run Prohori Installation Script ────────────────────────────────────── #
msg act "Running Prohori installation script..."

if [[ -f "$target_dir/install.sh" ]]; then
    chmod +x "$target_dir/install.sh"
    sudo bash "$target_dir/install.sh" 2>&1 | tee -a "$log"
    install_exit=${PIPESTATUS[0]}
else
    msg err "Installer script (install.sh) not found in $target_dir."
    echo "[ ERROR ] - install.sh missing in $target_dir" >> "$log"
    install_exit=1
fi

# ── Verify ──────────────────────────────────────────────────────────────── #
if [[ $install_exit -eq 0 && -d "$theme_dir/$theme_name" ]]; then
    msg dn "Prohori SDDM theme installed successfully!"
    echo "[ DONE ] - SDDM theme set to $theme_name" >> "$log"
else
    msg err "SDDM theme installation may have failed. Check $log"
    echo "[ ERROR ] - Theme installation failed" >> "$log"
fi

sleep 1 && clear
