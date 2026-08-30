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
        --width 60 \
        --margin "1" \
        --padding "1" \
'
   _______  ___  __  ___  ________                
  / __/ _ \/ _ \/  |/  / /_  __/ /  ___ __ _  ___ 
 _\ \/ // / // / /|_/ /   / / / _ \/ -_)  ; \/ -_)
/___/____/____/_/  /_/   /_/ /_//_/\__/_/_/_/\__/ 
                                                   
'
}

clear && display_text
printf " \n \n"

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
theme_name="SilentSDDM"
theme_dir="/usr/share/sddm/themes"
sddm_conf_dir="/etc/sddm.conf.d"
cache_dir="$parent_dir/.cache"
target_dir="$cache_dir/$theme_name"

# Ensure sddm theme directory exists
[ ! -d "$theme_dir" ] && sudo mkdir -p "$theme_dir"
[ ! -d "$sddm_conf_dir" ] && sudo mkdir -p "$sddm_conf_dir"

# ── Download Theme ──────────────────────────────────────────────────────── #
msg act "Downloading SilentSDDM theme..."

# Clean any previous cached download
sudo rm -rf "$target_dir"
mkdir -p "$cache_dir"

# Primary: git clone (no unzip needed, reliable)
if command -v git &>/dev/null; then
    git clone --depth=1 "https://github.com/shell-ninja/SilentSDDM.git" "$target_dir" 2>&1 | tee -a "$log"
fi

# Fallback: curl + unzip
if [[ ! -d "$target_dir" || -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
    msg att "git clone failed, trying curl fallback..."
    zip_path="$cache_dir/${theme_name}.zip"
    url="https://github.com/shell-ninja/SilentSDDM/archive/refs/heads/main.zip"
    curl -L "$url" -o "$zip_path" 2>&1 | tee -a "$log"

    if [[ -f "$zip_path" ]]; then
        rm -rf "$target_dir"
        mkdir -p "$target_dir"
        if command -v unzip &>/dev/null; then
            unzip -q "$zip_path" "SilentSDDM-main/*" -d "$target_dir" > /dev/null 2>&1
            # Flatten the nested directory
            if [[ -d "$target_dir/SilentSDDM-main" ]]; then
                mv "$target_dir/SilentSDDM-main/"* "$target_dir/" 2>/dev/null || true
                rmdir "$target_dir/SilentSDDM-main" 2>/dev/null || true
            fi
        else
            # Python fallback if unzip is unavailable
            python3 -c "
import zipfile, os, shutil
zf = zipfile.ZipFile('$zip_path')
zf.extractall('$target_dir')
inner = os.path.join('$target_dir', 'SilentSDDM-main')
if os.path.isdir(inner):
    for item in os.listdir(inner):
        shutil.move(os.path.join(inner, item), '$target_dir')
    os.rmdir(inner)
" 2>&1 | tee -a "$log"
        fi
        rm -f "$zip_path"
    fi
fi

# Verify download succeeded
if [[ ! -d "$target_dir" || -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
    msg err "Failed to download SilentSDDM theme. Check your internet connection."
    echo "[ ERROR ] - SilentSDDM download failed" >> "$log"
    exit 1
fi

echo "[ DONE ] - SilentSDDM downloaded successfully" >> "$log"

# ── Deploy Theme ────────────────────────────────────────────────────────── #
msg act "Installing SilentSDDM theme..."

# Remove old installation to prevent directory nesting
sudo rm -rf "${theme_dir:?}/$theme_name"

# Copy theme to system themes directory
sudo cp -r "$target_dir" "$theme_dir/$theme_name" 2>&1 | tee -a "$log"

# ── Deploy Fonts ────────────────────────────────────────────────────────── #
font_src="$theme_dir/$theme_name/fonts"
if [[ -d "$font_src" ]]; then
    msg act "Installing SDDM theme fonts..."

    # Deploy to user fonts with correct permissions (not via sudo mv)
    user_font_dir="$HOME/.local/share/fonts/sddm-fonts"
    mkdir -p "$user_font_dir"
    cp -r "$font_src/." "$user_font_dir/" 2>&1 | tee -a "$log"

    # Also deploy system-wide so SDDM can access them before login
    sudo mkdir -p "/usr/share/fonts/$theme_name"
    sudo cp -r "$font_src/." "/usr/share/fonts/$theme_name/" 2>&1 | tee -a "$log"

    # Update font caches
    fc-cache -f "$user_font_dir" 2>/dev/null || true
    sudo fc-cache -f "/usr/share/fonts/$theme_name" 2>/dev/null || true
fi

# ── Configure SDDM ──────────────────────────────────────────────────────── #
msg act "Configuring SDDM to use $theme_name..."

# Write primary theme config (used by modern SDDM)
echo -e "[Theme]\nCurrent=$theme_name" | sudo tee "$sddm_conf_dir/theme.conf" &>/dev/null
echo -e "[Theme]\nCurrent=$theme_name" | sudo tee "$sddm_conf_dir/theme.conf.user" &>/dev/null

# Virtual keyboard config
echo -e "[General]\nInputMethod=qtvirtualkeyboard" | sudo tee "$sddm_conf_dir/virtualkbd.conf" &>/dev/null

# Also update /etc/sddm.conf if it exists and has a [Theme] section
if [[ -f "/etc/sddm.conf" ]]; then
    if grep -q "^\[Theme\]" /etc/sddm.conf; then
        sudo sed -i "s|^Current=.*|Current=$theme_name|" /etc/sddm.conf
    else
        echo -e "\n[Theme]\nCurrent=$theme_name" | sudo tee -a /etc/sddm.conf &>/dev/null
    fi
fi

# ── Verify ──────────────────────────────────────────────────────────────── #
if [[ -d "$theme_dir/$theme_name" ]]; then
    msg dn "SilentSDDM theme installed successfully!"
    echo "[ DONE ] - SDDM theme set to $theme_name" >> "$log"
else
    msg err "SDDM theme installation may have failed. Check $log"
    echo "[ ERROR ] - Theme directory not found after install" >> "$log"
fi

sleep 1 && clear
