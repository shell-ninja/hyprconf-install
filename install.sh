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

# scripts runner function
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

printf "  ${cyan}${end} ${bold}Initializing prerequisites...${end}\n\n"


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
    python3 "$tui_script" "$@"
    tui_exit_code=$?
    if [[ $tui_exit_code -eq 130 ]]; then
        printf "\n  ${red}[!] Installation aborted by user.${end}\n\n"
        exit 130
    fi
else
    printf "  ${red}✗ [ERROR]${end} TUI installer not found: %s\n" "$tui_script" >&2
    exit 1
fi

# ----------------- Check for Errors in Logs ----------------- #
shopt -s nullglob
log_files=("$log_dir"/*.log "$dir"/Log/*.log)
shopt -u nullglob

error_list=""
error_count=0

if [[ ${#log_files[@]} -gt 0 ]]; then
    error_list=$(grep -hF "[ ERROR ]" "${log_files[@]}" 2>/dev/null \
        | sed -r 's/\x1B\[[0-9;?]*[a-zA-Z]//g' \
        | sed -E 's/.*\[ ERROR \]\s*-?\s*//' \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        | grep -v '^$' \
        | sort -u)

    if [[ -n "$error_list" ]]; then
        error_count=$(echo "$error_list" | wc -l)
    fi
fi

if [[ $error_count -gt 0 ]]; then
    printf "\n"
    printf "  ${red}✗${end} ${bold}INSTALLATION ISSUES DETECTED${end} ${dim}[ ${red}${error_count} error(s)${end}${dim} ]${end}\n"
    printf "  ${muted}────────────────────────────────────────────────────────────${end}\n"
    while IFS= read -r err_item; do
        [[ -z "$err_item" ]] && continue
        printf "  ${red}✗${end}  ${white}%s${end}\n" "$err_item"
    done <<< "$error_list"
    printf "  ${muted}────────────────────────────────────────────────────────────${end}\n"
    printf "  ${muted}Please check logs in: ${cyan}%s${end}\n\n" "$log_dir"
else
    printf "\n"
    printf "  ${green}✓${end} ${bold}All installation tasks finished with ${green}0 errors${end}${bold}!${end}\n\n"
fi

# ----------------- Reboot Box & Prompt ----------------- #
box_content="$(printf "  ${green}${bold}HYPRLAND & HYPRCONF INSTALLED SUCCESSFULLY${end}\n\n  ${white}All selected packages, dotfiles, themes, and services are configured.${end}\n  ${muted}A system reboot is required to start your new Hyprland session.${end}\n\n  ${lavender}${bold}r${end} ${white}reboot now${end}   ·   ${muted}${bold}q${end} ${dim}quit to terminal${end}")"

if command -v gum &>/dev/null; then
    gum style \
        --border rounded \
        --border-foreground "#bd93f9" \
        --padding "1 2" \
        --margin "1 1" \
        "$box_content"
else
    printf "\n"
    printf "  ${lavender}╭───────────────────────────────────────────────────────────────────────────╮${end}\n"
    printf "  ${lavender}│${end}                                                                           ${lavender}│${end}\n"
    printf "  ${lavender}│${end}   ${green}${bold}HYPRLAND & HYPRCONF INSTALLED SUCCESSFULLY${end}                          ${lavender}│${end}\n"
    printf "  ${lavender}│${end}                                                                           ${lavender}│${end}\n"
    printf "  ${lavender}│${end}   ${white}All selected packages, dotfiles, themes, and services are configured.${end}   ${lavender}│${end}\n"
    printf "  ${lavender}│${end}   ${muted}A system reboot is required to start your new Hyprland session.${end}         ${lavender}│${end}\n"
    printf "  ${lavender}│${end}                                                                           ${lavender}│${end}\n"
    printf "  ${lavender}│${end}   ${lavender}${bold}r${end} ${white}reboot now${end}   ·   ${muted}${bold}q${end} ${dim}quit to terminal${end}                                   ${lavender}│${end}\n"
    printf "  ${lavender}│${end}                                                                           ${lavender}│${end}\n"
    printf "  ${lavender}╰───────────────────────────────────────────────────────────────────────────╯${end}\n\n"
fi

printf "  ${cyan}Select:${end} ${bold}[r/q]${end} "
action=""
while true; do
    read -r -s -n 1 key
    case "$key" in
        [rR]|"")
            action="reboot"
            printf "${lavender}reboot${end}\n\n"
            break
            ;;
        [qQ]|$'\e')
            action="quit"
            printf "${muted}quit${end}\n"
            break
            ;;
    esac
done

if [[ "$action" == "reboot" ]]; then
    # Hide cursor for smooth animation
    tput civis 2>/dev/null || printf "\e[?25l"
    clear

    anim_frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    anim_colors=("$lavender" "$purple" "$cyan")

    total_steps=30
    bar_len=28

    for (( step=0; step<=total_steps; step++ )); do
        remaining_sec=$(( (total_steps - step + 9) / 10 ))
        pct=$(( step * 100 / total_steps ))
        fill_len=$(( step * bar_len / total_steps ))
        unfill_len=$(( bar_len - fill_len ))

        spinner_char="${anim_frames[step % ${#anim_frames[@]}]}"
        theme_color="${anim_colors[(step / 10) % ${#anim_colors[@]}]}"

        fill_str=""
        for (( i=0; i<fill_len; i++ )); do fill_str="${fill_str}█"; done
        unfill_str=""
        for (( i=0; i<unfill_len; i++ )); do unfill_str="${unfill_str}░"; done

        printf "\e[H\n"
        printf "  ${theme_color}${end} ${bold}SYSTEM REBOOT INITIATED${end}\n\n"
        printf "  ${theme_color}${spinner_char}${end} ${bold}Rebooting in ${theme_color}${remaining_sec}s${end}  ${theme_color}[${fill_str}${dim}${unfill_str}${end}${theme_color}]${end} ${bold}%3d%%${end}\n\n" "$pct"
        printf "  ${dim}Happy to use your new rice! ${end}\n"
        sleep 0.1
    done

    # Restore cursor
    tput cnorm 2>/dev/null || printf "\e[?25h"
    clear
    systemctl reboot --now 2>/dev/null || sudo reboot
else
    printf "\n  ${lavender}${end} ${bold}Ok, but make sure to reboot the system.${end}\n" && sleep 1
    printf "  ${dim}Happy to use your new rice! ${end}\n\n"
    if [[ $error_count -gt 0 ]]; then
        printf "  ${red}⚠${end} ${muted}Remember to check ${red}%d${end} ${muted}error(s) in:${end} ${cyan}%s${end}\n\n" "$error_count" "$log_dir"
    fi
    exit 0
fi
