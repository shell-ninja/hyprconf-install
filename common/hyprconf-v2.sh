#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;38;2;247;118;142m"
green="\e[1;38;2;166;227;161m"
yellow="\e[1;38;2;224;175;104m"
blue="\e[1;38;2;122;162;247m"
cyan="\e[1;38;2;125;207;255m"
purple="\e[1;38;2;189;147;249m"   # Electric neon purple
lavender="\e[1;38;2;203;166;247m" # Soft lavender
muted="\e[38;2;108;112;134m"
end="\e[0m"

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/hyprconf-v2-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

# Suppress repetitive screen clears if running under TUI
if [[ -n "$HYPRCONF_TUI" || ! -t 1 ]]; then
    clear() { :; }
fi

# 1. Back up existing user configs safely before touching anything
if [[ -d "$HOME/.config/hypr" ]]; then
    backup_path="$HOME/.config/hypr.backup_$(date +%d-%m-%y_%H%M%S)"
    msg att "Existing Hyprland config detected. Backing up to $backup_path"
    cp -rf "$HOME/.config/hypr" "$backup_path" 2>/dev/null || true
fi

# 2. Download and extract Hyprconf v2 dotfiles payload
url="https://github.com/shell-ninja/hyprconf-v2/archive/refs/heads/main.zip"
target_dir="$parent_dir/.cache/hyprconf-v2"
zip_path="$target_dir.zip"

msg act "Downloading latest Hyprconf-v2 dotfiles..."
mkdir -p "$parent_dir/.cache"
curl -sL "$url" -o "$zip_path"

if [[ -f "$zip_path" ]]; then
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    unzip -q "$zip_path" "hyprconf-v2-main/*" -d "$target_dir" 2>/dev/null || unzip -q "$zip_path" -d "$target_dir"
    if [[ -d "$target_dir/hyprconf-v2-main" ]]; then
        mv "$target_dir/hyprconf-v2-main/"* "$target_dir/" 2>/dev/null || true
        rmdir "$target_dir/hyprconf-v2-main" 2>/dev/null || true
    fi
    rm -f "$zip_path"
fi

# 3. Execute hyprconf-v2.sh non-interactively or fallback to direct copy
if [[ -d "$target_dir" ]]; then
    cd "$target_dir" || exit 1
    
    if [[ -f "hyprconf-v2.sh" ]]; then
        chmod +x hyprconf-v2.sh 2>/dev/null || true
        msg act "Running Hyprconf-v2 dotfiles setup script..."
        HYPRCONF_TUI=1 DEBIAN_FRONTEND=noninteractive yes '' 2>/dev/null | ./hyprconf-v2.sh 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") || true
    fi

    # Fallback copy if setup script didn't deploy everything
    if [[ ! -d "$HOME/.config/hypr" && -d "$target_dir/.config/hypr" ]]; then
        msg att "Deploying .config directory directly..."
        cp -rf "$target_dir/.config/"* "$HOME/.config/" 2>/dev/null || true
    fi
fi

# 4. Ensure all scripts have executable permissions
if [[ -d "$HOME/.config/hypr/scripts" ]]; then
    chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
fi

# 5. Verification
if [[ -f "$HOME/.config/hypr/hyprland.conf" || -f "$HOME/.config/hypr/scripts/startup.sh" ]]; then
    msg dn "Hyprconf-v2 dotfiles configured successfully!"
    echo "[ DONE ] - Dotfiles setup was successful" >> "$log"
else
    msg att "Dotfiles extracted. Please check ~/.config/hypr"
    echo "[ NOTE ] - Dotfiles deployed to ~/.config" >> "$log"
fi
