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
orange="\e[1;38;5;214m"
end="\e[1;0m"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# log directory
log_dir="$parent_dir/Logs"
log="$log_dir/browser-$(date +%d-%m-%y).log"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

if [[ -f "$log" ]]; then
    errors=$(grep "ERROR" "$log")
    finished=$(grep -c "DONE" "$log")
    if [[ -z "$errors" && "$finished" -gt 0 ]]; then
        msg skp "Skipping this script. No need to run it again..."
        sleep 1
        exit 0
    fi

else
    mkdir -p "$log_dir"
    touch "$log"
fi

# finding the aur helper
aur_helper=$(command -v yay || command -v paru)

# Read browser selection with fallback
browser=$(cat "$parent_dir/.cache/browser" 2>/dev/null || echo "Skip")

case "$browser" in
    "Brave")
        if command -v "brave" &> /dev/null; then
            msg skp "Brave browser is already installed."
            exit 0
        else
            msg act "Installing Brave Browser..."
            curl -fsS https://dl.brave.com/install.sh | sh
        fi

        if [[ -n "$(command -v brave)" ]]; then
            msg dn "Brave Browser installed successfully."
            echo "[ DONE ] - Brave installed successfully." >> "$log"
        else 
            msg err "Failed to install Brave Browser."
            echo "[ ERROR ] - Could not install Brave" >> "$log"
        fi
        ;;
    "Google_Chrome")
        if command -v "google-chrome-stable" &> /dev/null; then
            msg skp "Google Chrome is already installed."
            exit 0
        else
            msg act "Installing Google Chrome..."
            install_package google-chrome
        fi

        if [[ -n "$(command -v google-chrome-stable)" ]]; then
            msg dn "Google Chrome installed successfully."
            echo "[ DONE ] - Google Chrome installed successfully." >> "$log"
        else 
            msg err "Failed to install Google Chrome."
            echo "[ ERROR ] - Could not install Google Chrome" >> "$log"
        fi
        ;;
    "Chromium")
        if command -v chromium &> /dev/null; then
            msg skp "Chromium is already installed."
            exit 0
        else
            msg act "Installing Chromium..."
            install_package chromium
        fi

        if [[ -n "$(command -v chromium)" ]]; then
            msg dn "Chromium installed successfully."
            echo "[ DONE ] - Chromium installed successfully." >> "$log"
        else 
            msg err "Failed to install Chromium."
            echo "[ ERROR ] - Could not install Chromium" >> "$log"
        fi
        ;;
    "Firefox")
        if command -v firefox &> /dev/null; then
            msg skp "Firefox is already installed."
            exit 0
        else
            msg act "Installing Firefox..."
            install_package firefox
        fi

        if [[ -n "$(command -v firefox)" ]]; then
            msg dn "Firefox installed successfully."
            echo "[ DONE ] - Firefox installed successfully." >> "$log"
        else 
            msg err "Failed to install Firefox."
            echo "[ ERROR ] - Could not install Firefox" >> "$log"
        fi
        ;;
    "Vivaldi")
        if command -v vivaldi &> /dev/null; then
            msg skp "Vivaldi is already installed."
            exit 0
        else
            msg act "Installing Vivaldi..."
            install_package vivaldi
        fi

        if [[ -n "$(command -v vivaldi)" ]]; then
            msg dn "Vivaldi installed successfully."
            echo "[ DONE ] - Vivaldi installed successfully." >> "$log"
        else 
            msg err "Failed to install Vivaldi."
            echo "[ ERROR ] - Could not install Vivaldi" >> "$log"
        fi
        ;;
    "Zen Browser")
        if command -v zen-browser-bin &> /dev/null; then
            msg skp "Zen Browser is already installed."
            exit 0
        else
            msg act "Installing Zen Browser..."
            install_package zen-browser-bin
        fi

        if [[ -n "$(command -v zen-browser-bin)" ]]; then
            msg dn "Zen Browser installed successfully."
            echo "[ DONE ] - Zen Browser installed successfully." >> "$log"
        else 
            msg err "Failed to install Zen Browser."
            echo "[ ERROR ] - Could not install Zen Browser" >> "$log"
        fi
        ;;
    "Skip")
        msg skp "Skipping web browser installation."
        exit 0
        ;;
    *)
        msg err "Unrecognized browser choice: $browser"
        ;;
esac

sleep 1 && clear
