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
        --width 40 \
        --margin "1" \
        --padding "1" \
'
   ___                            
  / _ )_______ _    _____ ___ ____
 / _  / __/ _ \ |/|/ (_-</ -_) __/
/____/_/  \___/__,__/___/\__/_/

'
}

clear && display_text
printf " \n \n"

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

browser=$(cat "$parent_dir/.cache/browser")

# Loop through the selected browsers
case $browser in
    "Brave")
        if command -v brave-browser &> /dev/null; then
            msg skp "Brave browser is already installed. Skipping"
            exit 0
        else
            curl -fsS https://dl.brave.com/install.sh | sh
        fi

        sleep 1

        if [[ -n "$(command -v brave-browser)" ]]; then
            msg dn "Brave was installed successfully!"
            echo "[ DONE ] - Brave was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null

            msg att "After completting the installation, please make sure to open the browser and follow the steps..." && sleep 2 && echo

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
        if command -v google-chrome-stable &> /dev/null; then
            msg skp "Google Chrome is already installed. Skipping"
            exit 0
        else
            msg act "Installing Google Chrome..."
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo apt-get install -y ./google-chrome-stable_current_amd64.deb &> /dev/null
            rm google-chrome-stable_current_amd64.deb
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
            msg dn "Chromium was installed successfully!"
            echo "[ DONE ] - Chromium was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null

            msg att "After completting the installation, please make sure to open the browser and follow the steps..." && sleep 2 && echo

            printf "[ 1 ] - Open the browser and in the search bar, typr 'chrome://flags' and press enter\n"
            printf "[ 2 ] - Now search for 'Ozone platform'\n"
            printf "[ 3 ] - Choose 'Wayland' from default and restart the browser.\n"
            sleep 5
        else 
            msg err "Could not installed Chromium.."
            echo "[ ERROR ] - Could not install Chromium" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Firefox")
        if command -v firefox-esr &> /dev/null || command -v firefox &> /dev/null; then
            msg skp "Firefox is already installed. Skipping"
            exit 0
        else
            install_package firefox-esr
        fi

        sleep 1

        if [[ -n "$(command -v firefox-esr)" ]] || [[ -n "$(command -v firefox)" ]]; then
            msg dn "Firefox was installed successfully!"
            echo "[ DONE ] - Firefox was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
        else 
            msg err "Could not installed firefox.."
            echo "[ ERROR ] - Could not install firefox" 2>&1 | tee -a "$log" &> /dev/null
        fi
        ;;
    "Zen Browser")
        if command -v zen-browser &> /dev/null; then
            msg skp "Zen browser is already installed. Skipping"
            exit 0
        else
            msg err "Zen Browser is not currently available via apt. Skipping..."
            sleep 1
        fi

        sleep 1

        if [[ -n "$(command -v zen-browser)" ]]; then
            msg dn "Zen Browser was installed successfully!"
            echo "[ DONE ] - Zen Browser was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
        else 
            msg err "Could not installed Zen Browser.."
            echo "[ ERROR ] - Could not install Zen Browser" 2>&1 | tee -a "$log" &> /dev/null
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
