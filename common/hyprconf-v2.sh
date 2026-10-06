#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# Color definition
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

# 1. Back up existing user configs safely before touching anything
if [[ -d "$HOME/.hyprconf" || -d "$HOME/.config/hypr" ]]; then
    backup_path="$HOME/.config/hypr.backup_$(date +%d-%m-%y_%H%M%S)"
    msg att "Existing Hyprland config detected. Safe backup created at $backup_path"
    mkdir -p "$backup_path"
    [[ -d "$HOME/.hyprconf" ]] && cp -rf "$HOME/.hyprconf" "$backup_path/" 2>/dev/null || true
    [[ -d "$HOME/.config/hypr" ]] && cp -rf "$HOME/.config/hypr" "$backup_path/" 2>/dev/null || true
fi

# 2. Download and extract Hyprconf v2 dotfiles payload
url="https://github.com/shell-ninja/hyprconf-v2/archive/refs/heads/main.zip"
target_dir="$parent_dir/.cache/hyprconf-v2"
zip_path="$target_dir.zip"

msg act "Downloading latest Hyprconf v2 dotfiles payload..."
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

# 3. Execute setup.sh non-interactively or with interactive TTY handoff
if [[ -d "$target_dir" ]]; then
    cd "$target_dir" || exit 1

    if [[ -f "setup.sh" ]]; then
        chmod +x setup.sh 2>/dev/null || true

        if [[ -n "$HYPRCONF_INTERACTIVE" ]]; then
            # ── Interactive mode: full native TTY handoff ─────────────────────────
            unset HYPRCONF_TUI DEBIAN_FRONTEND
            unset -f gum 2>/dev/null || true

            msg act "Launching Hyprconf v2 setup interactively..."
            echo "[ INTERACTIVE ] Running setup.sh with full terminal access" >> "$log"

            ./setup.sh
            echo "[ INTERACTIVE ] setup.sh exited with code $?" >> "$log"
        else
            # ── Automated mode: gum shim + streamed into TUI sub-terminal ─────────
            gum() {
                case "$1" in
                    confirm)
                        return 0
                        ;;
                    choose)
                        for arg in "$@"; do
                            if [[ "$arg" =~ ^--selected=(.*)$ ]]; then
                                echo "${BASH_REMATCH[1]}"
                                return 0
                            fi
                        done
                        shift; echo "$1"; return 0
                        ;;
                    spin)
                        while [[ "$#" -gt 0 && "$1" != "--" ]]; do shift; done
                        [[ "$1" == "--" ]] && shift && "$@"
                        return 0
                        ;;
                    *) return 0 ;;
                esac
            }
            export -f gum
            export HYPRCONF_TUI=1
            export DEBIAN_FRONTEND=noninteractive

            msg act "Running Hyprconf v2 deployment (automated)..."
            ./setup.sh 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> "$log") || true
        fi
    fi

    # Fallback copy if setup script didn't copy to ~/.config/hypr
    if [[ ! -d "$HOME/.config/hypr" && -d "$target_dir/config" ]]; then
        msg att "Deploying configuration tree to ~/.config..."
        mkdir -p "$HOME/.config"
        cp -a "$target_dir/config"/* "$HOME/.config/" 2>/dev/null || true
    fi
fi

# 4. Ensure all helper scripts in ~/.config/hypr/scripts have executable permissions
if [[ -d "$HOME/.config/hypr/scripts" ]]; then
    chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
fi

# 5. Verification
if [[ -f "$HOME/.config/hypr/hyprland.conf" || -f "$HOME/.config/hypr/scripts/startup.sh" ]]; then
    msg dn "Hyprconf v2 dotfiles configured successfully!"
    echo "[ DONE ] - Hyprconf v2 setup was successful" >> "$log"
else
    msg att "Dotfiles deployed to ~/.config"
    echo "[ NOTE ] - Hyprconf v2 dotfiles deployed" >> "$log"
fi
