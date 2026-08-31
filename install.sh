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

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
start="$dir/start.sh"

clear
printf "\n"
printf "  ${purple}${bold}█░█ █▄█ █▀█ █▀█ █▀▀ █▀█ █▄░█ █▀▀${end}\n"
printf "  ${lavender}${bold}█▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █░▀█ █▀░${end}\n"
printf "          ${muted}hyprland rice installer${end}\n\n"

printf "  ${cyan}✦${end} ${bold}Initializing prerequisites...${end}\n\n"

packages=(
    git
    gum
    python3
    curl
    unzip
)

for pkg in "${packages[@]}"; do
    if command -v pacman &> /dev/null; then
        if sudo pacman -Q "$pkg" &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            if sudo pacman -S --noconfirm "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    elif command -v zypper &> /dev/null; then
        if sudo zypper se -i "$pkg" &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            if sudo zypper in -y "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    fi
done

# Base devel for arch
if command -v pacman &> /dev/null; then
    if sudo pacman -Q base-devel &> /dev/null; then
        printf "  ${muted}· [SKIP] base-devel is already installed${end}\n"
    else
        printf "  ${purple}→${end} Installing base-devel...\n"
        if sudo pacman -S --noconfirm base-devel &> /dev/null; then
            printf "  ${green}✓${end} Successfully installed ${green}base-devel${end}\n"
        fi
    fi
fi

# Fedora
if command -v dnf &> /dev/null; then
    for pkg in git python3; do
        if rpm -q "$pkg" &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            if sudo dnf install -y "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    done
fi

# Debian/Ubuntu
if command -v apt-get &> /dev/null; then
    pkgs=(git python3 curl)
    for pkg in "${pkgs[@]}"; do
        if dpkg -s "$pkg" &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            if sudo apt-get install -y "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    done
fi

sleep 1
chmod +x "$start"
exec "$start"
