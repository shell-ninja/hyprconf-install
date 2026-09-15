#!/usr/bin/env bash
# Hyprconf Interaction Functions & Design System
# Shell Ninja ( https://github.com/shell-ninja )

# ----------------- Shell Ninja Color Palette (Cyber-Purple & Neon Cyan)
red="\e[1;38;2;247;118;142m"       # Crimson error
green="\e[1;38;2;166;227;161m"     # Soft emerald
yellow="\e[1;38;2;224;175;104m"    # Warm gold
blue="\e[1;38;2;122;162;247m"      # Soft azure
magenta="\e[1;38;2;232;121;249m"   # Vibrant violet-magenta
cyan="\e[1;38;2;125;207;255m"      # Neon glacier cyan
purple="\e[1;38;2;189;147;249m"    # Electric neon purple (primary accent)
lavender="\e[1;38;2;203;166;247m" # Soft lavender (secondary accent)
slate="\e[38;2;98;114;164m"        # Tokyo Night slate
muted="\e[38;2;108;112;134m"       # Dim grey
white="\e[1;37m"
bold="\e[1m"
dim="\e[2m"
end="\e[0m"

# Base & Cache directory
parent_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cache_dir="$parent_dir/.cache"
cache_file="$cache_dir/user-cache"
shell_cache="$cache_dir/shell"
pkgman_cache="$cache_dir/pkgman"
aur_cache="$cache_dir/aur"
browser_cache="$cache_dir/browser"
dotfiles_cache="$cache_dir/dotfiles"
log_dir="$parent_dir/Logs"

mkdir -p "$cache_dir"

# ----------------- Functions ----------------- #

fn_welcome() {
    clear
    printf "\n"
    printf "  ${purple}${bold}█░█ █▄█ █▀█ █▀█ █▀▀ █▀█ █▄░█ █▀▀${end}\n"
    printf "  ${lavender}${bold}█▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █░▀█ █▀░${end}\n"
    printf "          ${muted}hyprland rice installer${end}\n\n"
}

fn_ask() {
    gum confirm "$1" \
        --prompt.foreground "#bd93f9" \
        --affirmative "$2" \
        --negative "$3" \
        --selected.background "#bd93f9" \
        --selected.foreground "#11111b"
}

fn_exit() {
    gum spin --spinner line \
        --spinner.foreground "#f7768e" \
        --title "$1" \
        --title.foreground "#f7768e" -- \
        sleep 1
    exit 1
}

# Only for asking legacy prompts if ever needed
fn_ask_prompts() {
    local -A label_to_key
    local labels=()
    for key in "${!options[@]}"; do
        local label=$(echo "$key" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        label_to_key["$label"]="$key"
        labels+=("$label")
    done

    local selected
    selected=$(gum choose \
        --header "Select using the 'space' bar, press Enter to confirm:" \
        --no-limit \
        --cursor.foreground "#bd93f9" \
        --item.foreground "#cdd6f4" \
        --selected.foreground "#a6e3a1" \
        "${labels[@]}")

    for key in "${!options[@]}"; do
        options[$key]="N"
    done

    while IFS= read -r label; do
        if [[ -n "$label" ]]; then
            local key="${label_to_key[$label]}"
            options[$key]="Y"
        fi
    done <<< "$selected"

    > "$cache_file"
    for key in "${!options[@]}"; do
        echo "$key='${options[$key]}'" >> "$cache_file"
    done
}

fn_shell() {
    local -A label_to_key
    local labels=()
    for key in "${!shell_options[@]}"; do
        local label=$(echo "$key" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        label_to_key["$label"]="$key"
        labels+=("$label")
    done

    local selected
    selected=$(gum choose \
        --header "Choose your preferred login shell:" \
        --limit=1 \
        --cursor.foreground "#bd93f9" \
        --item.foreground "#cdd6f4" \
        --selected.foreground "#a6e3a1" \
        "${labels[@]}")

    for key in "${!shell_options[@]}"; do
        shell_options[$key]="N"
    done

    while IFS= read -r label; do
        if [[ -n "$label" ]]; then
            local key="${label_to_key[$label]}"
            shell_options[$key]="Y"
        fi
    done <<< "$selected"

    > "$shell_cache"
    for key in "${!shell_options[@]}"; do
        echo "$key='${shell_options[$key]}'" >> "$shell_cache"
    done
}

msg() {
    local actn="$1"
    local msg="$2"

    case $actn in
        act)
            printf "  ${cyan}→${end} ${msg}\n"
            ;;
        ask)
            printf "  ${purple}?${end} ${msg}\n"
            ;;
        dn)
            printf "  ${green}✓${end} ${msg}\n"
            ;;
        att)
            printf "  ${lavender}✦${end} ${msg}\n"
            ;;
        nt)
            printf "  ${blue}ℹ${end} ${msg}\n"
            ;;
        skp)
            printf "  ${muted}· [SKIP] ${msg}${end}\n"
            ;;
        err)
            printf "  ${red}✗ [ERROR]${end} ${msg}\n"
            ;;
        *)
            printf "  ${msg}\n"
            ;;
    esac
}

# ----------------- Shell Management ----------------- #
set_user_shell() {
    local target_shell="$1"
    local target_user="${SUDO_USER:-$USER}"
    [[ -z "$target_user" ]] && target_user="$(id -un)"

    if [[ -z "$target_shell" || ! -x "$target_shell" ]]; then
        msg err "Invalid or missing shell executable: '$target_shell'"
        return 1
    fi

    # Ensure target shell is listed in /etc/shells so PAM permits login
    if [[ -f /etc/shells ]] && ! grep -qxF "$target_shell" /etc/shells; then
        if [[ $EUID -eq 0 ]]; then
            echo "$target_shell" >> /etc/shells
        else
            echo "$target_shell" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
        fi
    fi

    local current_shell
    current_shell="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f7)"
    [[ -z "$current_shell" ]] && current_shell="$SHELL"

    if [[ "$(basename "$current_shell")" == "$(basename "$target_shell")" ]]; then
        msg dn "Default shell for '$target_user' is already $(basename "$target_shell") ($current_shell)."
        return 0
    fi

    msg att "Current login shell for '$target_user' is: '$current_shell'"
    msg act "Setting '$target_shell' as default login shell..."

    local success=false
    # Use sudo when available to avoid interactive PAM password prompts that fail when stdin is redirected (e.g. TUI)
    if [[ $EUID -eq 0 ]]; then
        if command -v usermod &>/dev/null && usermod -s "$target_shell" "$target_user" 2>/dev/null; then
            success=true
        elif command -v chsh &>/dev/null && chsh -s "$target_shell" "$target_user" 2>/dev/null; then
            success=true
        fi
    else
        if command -v usermod &>/dev/null && sudo usermod -s "$target_shell" "$target_user" 2>/dev/null; then
            success=true
        elif command -v chsh &>/dev/null && sudo chsh -s "$target_shell" "$target_user" 2>/dev/null; then
            success=true
        elif command -v chsh &>/dev/null && chsh -s "$target_shell" 2>/dev/null; then
            success=true
        fi
    fi

    if [[ "$success" == "true" ]]; then
        msg dn "Default shell successfully changed to '$target_shell' for $target_user!"
        return 0
    else
        msg err "Could not set '$target_shell' automatically. Please run: sudo usermod -s $target_shell $target_user"
        return 1
    fi
}
