#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# ----------------- Color definitions
red="\e[1;38;2;247;118;142m"
green="\e[1;38;2;166;227;161m"
yellow="\e[1;38;2;224;175;104m"
blue="\e[1;38;2;122;162;247m"
cyan="\e[1;38;2;125;207;255m"
purple="\e[1;38;2;189;147;249m"   # Electric neon purple
lavender="\e[1;38;2;203;166;247m" # Soft lavender
muted="\e[38;2;108;112;134m"
bold="\e[1m"
end="\e[0m"

clear
printf "\n"
printf "  ${purple}${bold}█░█ █▄█ █▀█ █▀█ █▀▀ █▀█ █▄░█ █▀▀${end}\n"
printf "  ${lavender}${bold}█▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █░▀█ █▀░${end}\n"
printf "          ${muted}hyprland rice installer${end}\n\n"

printf "  ${cyan}✦${end} ${bold}Bootstrapping installer environment...${end}\n\n"

[[ ! "$(pwd)" == "$HOME" ]] && cd "$HOME"

# ----------------- Ensure dependencies
if [[ -z $(command -v unzip) ]]; then
    printf "  ${purple}→${end} Installing unzip...\n"
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed --noconfirm unzip &> /dev/null
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y unzip &> /dev/null
    elif command -v zypper &> /dev/null; then
        sudo zypper in -y unzip &> /dev/null
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update -y &> /dev/null
        sudo apt-get install -y unzip &> /dev/null
    fi

    if command -v unzip &> /dev/null; then
        printf "  ${green}✓${end} Successfully installed ${green}unzip${end}\n\n"
    else
        printf "  ${red}✗${end} Failed to install unzip. Please install it manually.\n\n"
        exit 1
    fi
else
    printf "  ${cyan}✓${end} unzip is already installed\n"
fi

# ----------------- Branch selection

printf "\n  ${purple}✦${end} ${bold}Select the variant to install:${end}\n\n"
printf "    ${cyan}1)${end} ${bold}Traditional${end}  ${muted}— Classic Hyprconf setup with Waybar, Rofi, SwayNC, and related utilities${end}\n"
printf "    ${cyan}2)${end} ${bold}Noctalia${end}     ${muted}— Modern desktop experience powered by Noctalia Shell${end}\n\n"

selected_branch=""
while [[ -z "$selected_branch" ]]; do
    printf "  ${yellow}→${end} Enter your choice ${muted}[1/2]${end}: "
    read -r branch_choice
    case "$branch_choice" in
        1) selected_branch="main" ;;
        2) selected_branch="noct" ;;
        *) printf "  ${red}✗${end} Invalid choice. Please enter ${cyan}1${end} or ${cyan}2${end}.\n" ;;
    esac
done

printf "\n  ${green}✓${end} Selected Variant: ${bold}${green}${selected_branch}${end}\n"


printf "\n  ${cyan}→${end} Downloading latest Hyprconf installer payload (${bold}${selected_branch}${end})...\n"
curl -L "https://github.com/shell-ninja/hyprconf-install/archive/refs/heads/${selected_branch}.zip" -o hyprconf-install.zip

if [[ -f "$HOME/hyprconf-install.zip" ]]; then
    mkdir -p hyprconf-install
    unzip -q -o hyprconf-install.zip "hyprconf-install-${selected_branch}/*" -d hyprconf-install
    cd hyprconf-install || exit 1
    mv "hyprconf-install-${selected_branch}/"* . 2>/dev/null || true
    rmdir "hyprconf-install-${selected_branch}" 2>/dev/null || true
    rm "$HOME/hyprconf-install.zip"
fi

if [[ -d "$HOME/hyprconf-install" ]]; then
    cd "$HOME/hyprconf-install" || exit 1
    chmod +x install.sh
    exec ./install.sh
fi

