#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# ----------------- Exit on interrupt trap
trap 'tput cnorm 2>/dev/null || printf "\e[?25h"; printf "\n\e[1;31m[!] Installation cancelled by user. Exiting...\e[0m\n"; exit 130' SIGINT SIGTERM

# ----------------- Color definitions (ANSI)
red="\e[1;38;2;247;118;142m"
green="\e[1;38;2;166;227;161m"
yellow="\e[1;38;2;224;175;104m"
blue="\e[1;38;2;122;162;247m"
magenta="\e[1;38;2;187;154;247m"
cyan="\e[1;38;2;125;207;255m"
purple="\e[1;38;2;189;147;249m"   # Electric neon purple
lavender="\e[1;38;2;203;166;247m" # Soft lavender
muted="\e[38;2;108;112;134m"
bold="\e[1m"
end="\e[0m"

# ----------------- Base directories
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
log_dir="$dir/Logs"
cache_dir="$dir/.cache"

cache_file="$cache_dir/user-cache"
shell_cache="$cache_dir/shell"
pkgman_cache="$cache_dir/pkgman"
aur_cache="$cache_dir/aur"
browser_cache="$cache_dir/browser"
dotfiles_cache="$cache_dir/dotfiles"

mkdir -p "$log_dir" "$cache_dir"
log="$log_dir/1-install-$(date +%d-%m-%y).log"
touch "$log"

# ----------------- Modern TUI Launcher
# If python3 is available and not in legacy mode, launch the Ryoku-style interactive TUI
if command -v python3 &>/dev/null && [[ "$1" != "--legacy" ]]; then
    if [[ -f "$dir/tui_installer.py" ]]; then
        exec python3 "$dir/tui_installer.py" "$@"
    fi
fi

# ----------------- Fallback CLI Mode ----------------- #
if [[ -f "$dir/interaction_fn.sh" ]]; then
    source "$dir/interaction_fn.sh"
else
    printf "${red}Error:${end} interaction_fn.sh not found in %s\n" "$dir" >&2
    exit 1
fi

run_script() {
    local script="$1"
    if [[ ! -f "$script" ]]; then
        msg err "Script not found: $script"
        echo "[ ERROR ] Script not found: $script" >> "$log"
        return 1
    fi

    [[ ! -x "$script" ]] && chmod +x "$script"
    "$script" 2>&1 | tee >(sed -r 's/\x1B\[[0-9;?]*[a-zA-Z]//g' >> "$log")
    local exit_code="${PIPESTATUS[0]}"
    return "$exit_code"
}

check_pkgman() {
    if command -v pacman &> /dev/null; then
        pkgman="pacman"
    elif command -v dnf &> /dev/null; then
        pkgman="dnf"
    elif command -v zypper &> /dev/null; then
        pkgman="zypper"
    elif command -v apt-get &> /dev/null; then
        pkgman="apt"
    else
        fn_exit "Sorry, the script won't work with your package manager for now..."
    fi

    echo "pkgman=$pkgman" > "$pkgman_cache"
    echo "Detected package manager: $pkgman" >> "$log"
}

check_pkgman
clear && fn_welcome && sleep 0.3

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    msg act "Starting the main scripts for ${cyan}${NAME:-Linux}${end}..." && sleep 1
else
    msg act "Starting the main scripts..." && sleep 1
fi
clear

if [[ -f "$cache_file" ]]; then
    source "$cache_file"
    if [[ -z "$have_nvidia" ]]; then
        msg err "User prompt was not given properly. Please run the script again..."
        fn_ask "Would you like to run the script again?" "Yes, sure." "No, close it."
        if [[ $? -eq 0 ]]; then
            rm -f "$cache_file" "$shell_cache" "$aur_cache" "$browser_cache" "$dotfiles_cache"
            exec "$dir/start.sh"
        else
            fn_exit "Exiting the script here. Goodbye."
        fi
    else
        msg skp "Cache file exists. Skipping prompts..." && sleep 1
    fi
else
    touch "$cache_file"
    declare -A options=(
        ["setup_for_bluetooth"]=""
        ["install_vs_code"]=""
        ["install_browser"]=""
        ["have_nvidia"]=""
    )

    initialize_cache_file() {
        > "$cache_file"
        for key in "${!options[@]}"; do
            echo "$key=''" >> "$cache_file"
        done
    }
    initialize_cache_file

    msg att "Choose prompts. Press 'ESC' to skip"
    fn_ask_prompts

    echo
    echo

    touch "$shell_cache"
    declare -A shell_options=(
        ["install_fish"]=""
        ["install_zsh"]=""
        ["setup_bash"]=""
    )

    initialize_shell_cache() {
        > "$shell_cache"
        for key in "${!shell_options[@]}"; do
            echo "$key=''" >> "$shell_cache"
        done
    }
    initialize_shell_cache

    msg att "Choose prompts. Press 'ESC' to skip"
    fn_shell
fi

[[ -f "$cache_file" ]] && source "$cache_file"
[[ -f "$shell_cache" ]] && source "$shell_cache"

scripts_dir="$dir/${pkgman}-scripts"
common_scripts="$dir/common"

if [[ ! -d "$scripts_dir" ]]; then
    fn_exit "Scripts directory for $pkgman ($scripts_dir) does not exist."
fi

chmod +x "$scripts_dir"/*.sh "$common_scripts"/*.sh 2>/dev/null || true
clear

# Execute Repo setup
if [[ "$pkgman" == "pacman" ]]; then
    aur=$(command -v yay 2>/dev/null || command -v paru 2>/dev/null)
    if [[ -n "$aur" ]]; then
        msg dn "AUR helper $aur was located... Moving on"
        # Write to cache so 00-repo.sh can detect it too
        echo "$(basename "$aur")" > "$aur_cache"
        sleep 1
    else
        is_vm=false
        if command -v systemd-detect-virt &>/dev/null && systemd-detect-virt -q; then
            is_vm=true
        elif hostnamectl status 2>/dev/null | grep -qiE 'chassis:\s*vm|virtualization'; then
            is_vm=true
        fi

        if [[ "$is_vm" == true ]]; then
            msg att "Virtual machine was detected, 'yay' will be installed."
            echo "yay" > "$aur_cache"
        else
            msg ask "Which AUR helper would you like to install?"
            choice=$(gum choose \
                --cursor.foreground "#bd93f9" \
                --item.foreground "#c0caf5" \
                --selected.foreground "#a6e3a1" \
                "yay" "paru" "Skip"
            )
            echo "${choice:-yay}" > "$aur_cache"
        fi
        run_script "$scripts_dir/00-repo.sh"
    fi
else
    run_script "$scripts_dir/00-repo.sh"
fi

# Hyprland and tools
run_script "$scripts_dir/2-hyprland.sh"

if [[ "$pkgman" == "zypper" && -f "$scripts_dir/2.1-hyprsunset.sh" ]]; then
    run_script "$scripts_dir/2.1-hyprsunset.sh"
fi

if [[ "$pkgman" == "apt" ]]; then
    [[ -f "$scripts_dir/2.1-hyprcursor.sh" ]] && run_script "$scripts_dir/2.1-hyprcursor.sh"
    [[ -f "$scripts_dir/2.2-hyprsunset.sh" ]] && run_script "$scripts_dir/2.2-hyprsunset.sh"
fi

run_script "$scripts_dir/3-other_packages.sh"
run_script "$scripts_dir/6-fonts.sh"

if [[ "$install_browser" =~ ^[Yy]$ ]]; then
    msg ask "Choose a browser: "
    if [[ "$pkgman" == "pacman" || "$pkgman" == "zypper" ]]; then
        choice=$(gum choose \
            --cursor.foreground "#bd93f9" \
            --item.foreground "#c0caf5" \
            --selected.foreground "#a6e3a1" \
            "Brave" "Google_Chrome" "Zen Browser" "Firefox" "Chromium" "Vivaldi" "Skip"
        )
    else
        choice=$(gum choose \
            --cursor.foreground "#bd93f9" \
            --item.foreground "#c0caf5" \
            --selected.foreground "#a6e3a1" \
            "Brave" "Google_Chrome" "Zen Browser" "Firefox" "Chromium" "Skip"
        )
    fi
    echo "${choice:-Skip}" > "$browser_cache"

    if [[ "$choice" != "Skip" && -n "$choice" ]]; then
        run_script "$scripts_dir/7-browser.sh"
    else
        msg skp "Skipping browser installation..."
    fi
else
    msg skp "Skipping browser installation..."
fi

run_script "$scripts_dir/9-sddm.sh"

# Run SDDM theme installer (SilentSDDM) unless explicitly disabled
if [[ ! "$install_sddm_theme" =~ ^[Nn]$ ]]; then
    run_script "$common_scripts/sddm_theme.sh"
fi

run_script "$scripts_dir/10-xdg_dp.sh"

if [[ "$install_vs_code" =~ ^[Yy]$ ]]; then
    run_script "$scripts_dir/8-vs_code.sh"
fi

if [[ "$have_nvidia" =~ ^[Yy]$ ]]; then
    run_script "$scripts_dir/nvidia.sh"
fi

if [[ "$setup_for_bluetooth" =~ ^[Yy]$ ]]; then
    run_script "$common_scripts/bluetooth.sh"
fi

if [[ "$install_zsh" =~ ^[Yy]$ ]]; then
    run_script "$common_scripts/zsh.sh"
fi

if [[ "$setup_bash" =~ ^[Yy]$ ]]; then
    run_script "$common_scripts/bash.sh"
fi

if [[ "$install_fish" =~ ^[Yy]$ ]]; then
    run_script "$common_scripts/fish.sh"
fi

run_script "$scripts_dir/11-uninstall.sh"

clear
run_script "$common_scripts/themes.sh"
run_script "$common_scripts/hyprconf.sh"

# Keyboard layout
keyboardLayout=$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout|VC Keymap/ {print $2; exit}' | tr -d ' ')
[[ -z "$keyboardLayout" || "$keyboardLayout" == "n/a" ]] && keyboardLayout="us"

msg att "Your current keyboard layout is set to '$keyboardLayout'"
fn_ask "Is it ok for you?" "Yes! Set" "No! Change"

if [[ $? -eq 1 ]]; then
    layout=$(localectl list-x11-keymap-layouts 2>/dev/null \
        | gum filter \
        --height 15 \
        --prompt="<> " \
        --cursor-text.foreground "#bd93f9" \
        --indicator.foreground "#bd93f9" \
        --placeholder "Search keyboard layout..."
    )
    layout="${layout:-$keyboardLayout}"
else
    layout="$keyboardLayout"
fi

msg att "Selected Layout: $layout"

kbd_config=""
if [[ -f "$HOME/.config/hypr/confs/settings.conf" ]]; then
    kbd_config="$HOME/.config/hypr/confs/settings.conf"
elif [[ -f "$HOME/.config/hypr/configs/settings.conf" ]]; then
    kbd_config="$HOME/.config/hypr/configs/settings.conf"
fi

if [[ -n "$kbd_config" && -f "$kbd_config" ]]; then
    sed -i "s/kb_layout = .*/kb_layout = $layout/g" "$kbd_config"
    msg dn "Keyboard layout configured in $kbd_config"
else
    msg nt "Keyboard layout set to '$layout'"
fi

sleep 1 && clear

system="desktop"
if compgen -G "/sys/class/power_supply/BAT*" > /dev/null 2>&1 || [[ -d "/sys/class/power_supply/BAT0" ]]; then
    system="laptop"
fi

run_script "$common_scripts/${system}.sh"
sleep 1 && clear

run_script "$scripts_dir/12-final.sh"

msg dn "Congratulations! The script completes here." && sleep 1
msg att "Need to reboot the system."

fn_ask "Would you like to reboot now?" "Reboot" "No, skip"
if [[ $? -eq 0 ]]; then
    clear
    for sec in 5 4 3 2 1; do
        clear
        printf "\n\n  ${purple}✦${end} ${bold}SYSTEM REBOOT INITIATED${end}\n\n"
        printf "  ${cyan}Rebooting in %ss...${end}\n" "$sec"
        sleep 1
    done
    systemctl reboot --now 2>/dev/null || sudo reboot
else
    msg nt "Ok, but make sure to reboot the system." && sleep 1
    msg dn "Happy to use your new rice!"
    exit 0
fi
