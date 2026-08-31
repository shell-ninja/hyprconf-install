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

# Ask user for browser selection
browser=$(cat "$parent_dir/.cache/browser")

case $browser in
    "Brave")
        if command -v "brave" &> /dev/null; then
            msg skp "Brave browser is already installed. Skipping"
            exit 0
        else
            curl -fsS https://dl.brave.com/install.sh | sh
        fi
        sleep 1

        if [[ -n "$(command -v brave)" ]]; then
            msg dn "Brave was installed successfully!"
            echo "[ DONE ] - Brave was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null

            msg att "After completting the installation, please make sure to open the browser and follow the steps.\n" && sleep 2 && echo

            printf "[ 1 ] - Open the browser and in the search bar, typr 'chrome://flags' and press enter\n"
            printf "[ 2 ] - Now search for 'Ozone platform'\n"
            printf "[ 3 ] - Choose 'Wayland' from default and restart the browser.\n"
            sleep 5
        else 
            msg err "Could not installed Brave.."
            echo "[ ERROR ] - Could not install Brave" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Google_Chrome")
        if command -v "google-chrome-stable" &> /dev/null; then
            msg skp "Google Chrome is already installed. Skipping"
            exit 0
        else
            install_package google-chrome
        fi
        sleep 1

        if [[ -n "$(command -v google-chrome-stable)" ]]; then
            msg dn "Google Chrome was installed successfully!"
            echo "[ DONE ] - Google Chrome was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null

            msg att "After completting the installation, please make sure to open the browser and follow the steps.\n" && sleep 2 && echo

            printf "[ 1 ] - Open the browser and in the search bar, typr 'chrome://flags' and press enter\n"
            printf "[ 2 ] - Now search for 'Ozone platform'\n"
            printf "[ 3 ] - Choose 'Wayland' from default and restart the browser.\n"
            sleep 5
        else 
            msg err "Could not installed Google Chrome.."
            echo "[ ERROR ] - Could not install Google Chrome" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Chromium")
        if command -v chromium &> /dev/null; then
            msg skp "Chromium is already installed. Skipping"
            exit 0
        else
            install_package chromium
        fi

        sleep 1

        if [[ -n "$(command -v chromium)" ]]; then
            msg dn "Chromium was installed successfully!\n"
            echo "[ DONE ] - Chromium was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null

            msg att "After completting the installation, please make sure to open the browser and follow the steps..." && sleep 2 && echo

            printf "[ 1 ] - Open the browser and in the search bar, typr 'chrome://flags' and press enter\n"
            printf "[ 2 ] - Now search for 'Ozone platform'\n"
            printf "[ 3 ] - Choose 'Wayland' from default and restart the browser.\n"
            sleep 5
        else 
            echo "[ ERROR ] - Could not install Chromium" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Firefox")
        if command -v firefox &> /dev/null; then
            msg skp "Firefox is already installed. Skipping"
            exit 0
        else
            install_package firefox
        fi

        sleep 1

        if [[ -n "$(command -v firefox)" ]]; then
            echo "[ DONE ] - Firefox was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
        else 
            echo "[ ERROR ] - Could not install firefox" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Vivaldi")
        if command -v vivaldi &> /dev/null; then
            msg skp "Vivaldi is already installed. Skipping"
            exit 0
        else
            install_package vivaldi
        fi

        sleep 1

        if [[ -n "$(command -v vivaldi)" ]]; then
            msg dn "Vivaldi was installed successfully!\n"
            echo "[ DONE ] - Vivaldi was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null

            msg att "After completting the installation, please make sure to open the browser and follow the steps..." && sleep 2 && echo

            printf "[ 1 ] - Open the browser and in the search bar, typr 'chrome://flags' and press enter\n"
            printf "[ 2 ] - Now search for 'Ozone platform'\n"
            printf "[ 3 ] - Choose 'Wayland' from default and restart the browser.\n"
            sleep 5
        else 
            echo "[ ERROR ] - Could not install Vivaldi" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Zen Browser")
        if command -v zen-browser &> /dev/null; then
            msg skp "Zen Browser is already installe. Skipping"
            exit 0
        else
            install_package zen-browser
        fi

        sleep 1

        if [[ -n "$(command -v zen-browser)" ]]; then
            echo "[ DONE ] - Zen Browser was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
        else 
            echo "[ ERROR ] - Could not install zen" 2>&1 | tee -a "$log" &> /dev/null
        fi

        ;;
    "Skip")
            msg skp "No browser will be installed.."
            sleep 1
            exit 0
        ;;
    *)
        msg err "Invalid choice: $browser..."
        ;;
esac

sleep 1 && clear
