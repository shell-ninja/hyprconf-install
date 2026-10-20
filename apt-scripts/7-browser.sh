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

# Read browser selection with fallback
browser=$(cat "$parent_dir/.cache/browser" 2>/dev/null || echo "Skip")

case "$browser" in
    "Brave")
        if command -v brave-browser &> /dev/null; then
            msg skp "Brave browser is already installed."
            exit 0
        else
            msg act "Installing Brave Browser..."
            curl -fsS https://dl.brave.com/install.sh | sh
        fi

        if [[ -n "$(command -v brave-browser)" ]]; then
            msg dn "Brave Browser installed successfully."
            echo "[ DONE ] - Brave was installed successfully!" >> "$log"
        else 
            msg err "Failed to install Brave Browser."
            echo "[ ERROR ] - Could not install Brave" >> "$log"
        fi
        ;;
    "Google_Chrome")
        if command -v google-chrome-stable &> /dev/null; then
            msg skp "Google Chrome is already installed."
            exit 0
        else
            msg act "Installing Google Chrome..."
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo apt-get install -y ./google-chrome-stable_current_amd64.deb &> /dev/null
            rm -f google-chrome-stable_current_amd64.deb
        fi

        if [[ -n "$(command -v google-chrome-stable)" ]]; then
            msg dn "Google Chrome installed successfully."
            echo "[ DONE ] - Google Chrome was installed successfully!" >> "$log"
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
            echo "[ DONE ] - Chromium was installed successfully!" >> "$log"
        else 
            msg err "Failed to install Chromium."
            echo "[ ERROR ] - Could not install Chromium" >> "$log"
        fi
        ;;
    "Firefox")
        if command -v firefox-esr &> /dev/null || command -v firefox &> /dev/null; then
            msg skp "Firefox is already installed."
            exit 0
        else
            msg act "Installing Firefox..."
            install_package firefox-esr
        fi

        if [[ -n "$(command -v firefox-esr)" ]] || [[ -n "$(command -v firefox)" ]]; then
            msg dn "Firefox installed successfully."
            echo "[ DONE ] - Firefox was installed successfully!" >> "$log"
        else 
            msg err "Failed to install Firefox."
            echo "[ ERROR ] - Could not install Firefox" >> "$log"
        fi
        ;;
    "Zen Browser")
        if command -v zen-browser &> /dev/null; then
            msg skp "Zen Browser is already installed."
            exit 0
        else
            msg att "Zen Browser is not packaged natively in APT repos. Skipping automated install."
            echo "[ SKIP ] - Zen Browser not in APT repositories" >> "$log"
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
