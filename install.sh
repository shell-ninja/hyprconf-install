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
log_dir="$dir/Logs"
mkdir -p "$log_dir"
log="$log_dir/install-$(date +%d-%m-%y).log"

clear
printf "\n"
printf "  ${purple}${bold}█░█ █▄█ █▀█ █▀█ █▀▀ █▀█ █▄░█ █▀▀${end}\n"
printf "  ${lavender}${bold}█▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █░▀█ █▀░${end}\n"
printf "          ${muted}hyprland rice installer${end}\n\n"

# ----------------- Fallback CLI & Helper Functions ----------------- #
if [[ -f "$dir/interaction_fn.sh" ]]; then
    source "$dir/interaction_fn.sh"
else
    printf "${red}Error:${end} interaction_fn.sh not found in %s\n" "$dir" >&2
    exit 1
fi

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    msg act "Preparing repositories for ${cyan}${NAME:-Linux}${end}..." && sleep 1
else
    msg act "Preparing repositories..." && sleep 1
fi

run_script() {
    local script="$1"
    if [[ ! -f "$script" ]]; then
        msg err "Script not found: $script"
        echo "[ ERROR ] Script not found: $script" >> "$log"
        return 1
    fi

    [[ ! -x "$script" ]] && chmod +x "$script"
    "$script" 2>&1 | tee -a >(sed -r 's/\x1B\[[0-9;?]*[a-zA-Z]//g' >> "$log")
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

    scripts_dir="$dir/${pkgman}-scripts"
}

check_pkgman

printf "  ${cyan}✦${end} ${bold}Initializing prerequisites...${end}\n\n"


packages=(
    curl
    git
    gum
    python3
    unzip
)

for pkg in "${packages[@]}"; do
    if command -v pacman &> /dev/null; then
        if sudo pacman -Q "$pkg" base-devel &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            sudo pacman -S --needed --noconfirm "$pkg" base-devel &> /dev/null
            if sudo pacman -Q "$pkg" base-devel &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    elif command -v zypper &> /dev/null; then
        if sudo zypper se -i "$pkg" &>/dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            sudo zypper in -y "$pkg" &> /dev/null
            if sudo zypper se -i "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    elif command -v dnf &> /dev/null; then
        if rpm -q "$pkg" &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            sudo dnf install -y "$pkg" &> /dev/null
            if rpm -q "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    fi
done

# Debian/Ubuntu
if command -v apt-get &> /dev/null; then
    for pkg in git python3 unzip wget curl; do
        if dpkg -s "$pkg" &> /dev/null; then
            printf "  ${muted}· [SKIP] $pkg is already installed${end}\n"
        else
            printf "  ${purple}→${end} Installing $pkg...\n"
            sudo apt-get install -y "$pkg" &> /dev/null
            if dpkg -s "$pkg" &> /dev/null; then
                printf "  ${green}✓${end} Successfully installed ${green}$pkg${end}\n"
            fi
        fi
    done
fi

sleep 1

# ----------------- Execute 00-repo.sh before TUI ----------------- #

if [[ "$pkgman" == "pacman" ]]; then
    aur=$(command -v yay 2>/dev/null || command -v paru 2>/dev/null)
    if [[ -n "$aur" ]]; then
        msg dn "AUR helper $aur was located... Moving on"
        echo "$(basename "$aur")" > "$aur_cache"
        sleep 1
    else
        msg ask "Which AUR helper would you like to install?"
        choice=$(gum choose \
            --cursor.foreground "#bd93f9" \
            --item.foreground "#c0caf5" \
            --selected.foreground "#a6e3a1" \
            "yay-bin" "yay" "paru-bin" "paru" "Skip"
        )
        echo "${choice:-yay-bin}" > "$aur_cache"
        sleep 1
        run_script "$scripts_dir/00-repo.sh" || msg err "Failed to install AUR helper"
        if [[ $? -ne 0 ]]; then
            fn_exit "Exiting"
        fi  
    fi
else
    run_script "$scripts_dir/00-repo.sh" || msg err "Failed to update repository"
    if [[ $? -ne 0 ]]; then
        fn_exit "Exiting"
    fi  
fi


tui_script="$dir/tui_installer.py"

chmod +x "$dir"/*-scripts/*.sh "$dir"/common/*.sh "$tui_script" 2>/dev/null || true

if [[ -f "$tui_script" ]]; then
    exec python3 "$tui_script" "$@"
else
    printf "  ${red}✗ [ERROR]${end} TUI installer not found: %s\n" "$tui_script" >&2
    exit 1
fi