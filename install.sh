#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"

dir="$(dirname "$(realpath "$0")")"
start="$dir/start.sh"

clear && sleep 1

printf "${cyan}**${end} Pre install script...\n   Need to install some packages first, installing those...\n" && sleep 2

packages=(
    git
    gum
)

for pkg in "${packages[@]}"; do

    if command -v pacman &> /dev/null; then
        if sudo pacman -Q "$pkg" &> /dev/null; then
            printf "${magenta}[ Skip ] ${end} Skipping $pkg, it's already installed...\n"
        else
            printf "${green}=>${end} Installing $pkg...\n"
            if sudo pacman -S --noconfirm "$pkg" &> /dev/null; then
                printf "${cyan}::${end} Successfully installed ${cyan}$pkg${end}...\n"
            fi
        fi
    elif command -v zypper &> /dev/null; then

        if sudo zypper se -i "$pkg" &> /dev/null; then
            printf "${magenta}[ Skip ]${end} Skipping $pkg, it's already installed...\n"
        else
            printf "${green}=>${end} Installing $pkg...\n"
            if sudo zypper in -y "$pkg" &> /dev/null; then
                printf "${cyan}::${end} Successfully installed ${cyan}$pkg${end}...\n"
            fi
        fi
    fi

done


# installing base devel for arch linux
if command -v pacman &> /dev/null; then
    if sudo pacman -Q base-devel &> /dev/null; then
        printf "${magenta}[ Skip ] ${end} Skipping base-devel, it's already installed...\n"
    else
        printf "${green}=>${end} Installing base-devel...\n"
        if sudo pacman -S --noconfirm base-devel &> /dev/null; then
            printf "${cyan}::${end} Successfully installed ${cyan}base-devel${end}...\n"
        fi
    fi
fi

# only for fedora
if command -v dnf &> /dev/null; then

    if rpm -q git &> /dev/null; then
        printf "${magenta}[ Skip ]${end} Skipping git, it's already installed...\n"
    else
        printf "${green}=>${end} Installing git...\n"
        if sudo dnf install -y git; then
            printf "${cyan}::${end} Successfully installed ${cyan}git${end}...\n"
        fi
    fi

    sleep 1

    printf "${green}=>${end} Installing gum...\n"
    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo &> /dev/null

    sudo yum install --assumeyes gum &> /dev/null

    if command -v gum &> /dev/null; then
        printf "${cyan}::${end} Successfully installed ${cyan}gum${end}...\n"
    fi
fi

sleep 1

chmod +x "$start"
"$start"
