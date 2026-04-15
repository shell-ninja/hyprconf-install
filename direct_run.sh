#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# this script will be a curl of wget link. by running this script, it will clone the repository and execute the main script.

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

clear && sleep 1

printf "${orange}=>${end} Starting the script...\n" && sleep 2

packages=(
    git
    gum
    unzip
    wget
)

for pkg in "${packages[@]}"; do

    if command -v pacman &> /dev/null; then
        if sudo pacman -Q "$pkg" &> /dev/null; then
            printf "${magenta}[ SKIP ]${end} Skipping $pkg, it was already installed..\n"
        else
            printf "${green}=>${end} Installing $pkg...\n"
            sudo pacman -S --noconfirm "$pkg" &> /dev/null

            if sudo pacman -Q "$pkg" &> /dev/null; then
                printf "${cyan}::${end} $pkg was installed successfully!\n"
            fi
        fi
    elif command -v zypper &> /dev/null; then

        if sudo zypper se -i "$pkg" &>/dev/null; then
            printf "${magenta}[ SKIP ]${end} Skipping $pkg, it was already installed..\n"
        else
            printf "${green}=>${end} Installing $pkg...\n"
            sudo zypper in -y "$pkg";

            if sudo zypper se -i "$pkg" &> /dev/null; then
                printf "${cyan}::${end} $pkg was installed sucessfully!\n"
            fi
        fi
    fi

done

# install base-devel for arch linux
if command -v pacman &> /dev/null; then
    if sudo pacman -Q base-devel &> /dev/null; then
        printf "${magenta}[ SKIP ]${end} Skipping base-devel, it was already installed..\n"
    else
        sudo pacman -S --needed base-devel --noconfirm &> /dev/null
        if sudo pacman -Q base-devel &> /dev/null; then
            printf "${cyan}::${end} base-devel was installed successfully!\n"
        fi
    fi
fi

# only for fedora
if command -v dnf &> /dev/null; then

    for _pkg in git unzip wget; do

        if rpm -q $_pkg &> /dev/null; then
            printf "${magenta}[ SKIP ]${end} Skipping $_pkg, it was already installed..\n"
        else
            printf "${green}=>${end} Installing $_pkg...\n"
            sudo dnf install -y $_pkg
            
            if rpm -q $_pkg; then
                printf "${cyan}::${end} $_pkg was installed successfully!\n"
            fi
        fi
        
    done

    sleep 1

    if rpm -q gum &> /dev/null; then
        printf "${magenta}[ SKIP ]${end} Skipping gum, it was already installed..\n"
    else
        printf "${green}=>${end} Installing gum...\n"
    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo &>/dev/null

        sudo yum install --assumeyes gum
    fi

    if rpm -q gum &> /dev/null; then
        printf "${cyan}::${end} Gum was installed successfully!\n"
    fi
fi

sleep 1 && clear
 
[[ ! "$(pwd)" == "$HOME" ]] && cd "$HOME"

printf "${green}=>${end} Preparing the installation scripts...\n" && echo

curl -L https://github.com/shell-ninja/hyprconf-install/archive/refs/heads/main.zip -o hyprconf-install.zip && sleep 1

if [[ -f "$HOME/hyprconf-install.zip" ]]; then
    mkdir hyprconf-install &> /dev/null
    unzip hyprconf-install.zip 'hyprconf-install-main/*' -d hyprconf-install &> /dev/null
    cd hyprconf-install &> /dev/null
    mv hyprconf-install-main/* . && rmdir hyprconf-install-main &> /dev/null
    rm "$HOME/hyprconf-install.zip"
fi

clear

if [[ -d "$HOME/hyprconf-install" ]]; then
    printf "${cyan}::${end} Starting the main script..\n" && sleep 1 && clear

    cd "$HOME/hyprconf-install"
    chmod +x start.sh
    ./start.sh
fi
