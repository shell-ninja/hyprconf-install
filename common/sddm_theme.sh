#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;38;2;247;118;142m"
green="\e[1;38;2;166;227;161m"
yellow="\e[1;38;2;224;175;104m"
blue="\e[1;38;2;122;162;247m"
magenta="\e[1;38;2;232;121;249m"
cyan="\e[1;38;2;125;207;255m"
purple="\e[1;38;2;189;147;249m"
muted="\e[38;2;108;112;134m"
bold="\e[1m"
end="\e[0m"

###------ Startup ------###

dir="$(dirname "$(realpath "$0")")"
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/sddm_theme-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

cache_dir="$parent_dir/.cache"
mkdir -p "$cache_dir"

theme_base_dir="/usr/share/sddm/themes"
[ ! -d "$theme_base_dir" ] && sudo mkdir -p "$theme_base_dir"

sddm_conf_dir="/etc/sddm.conf.d"
[ ! -d "$sddm_conf_dir" ] && sudo mkdir -p "$sddm_conf_dir"

# ----------------- Theme Installation Functions ----------------- #

install_prohori() {
    local theme_name="prohori"
    local theme_dest="${theme_base_dir}/${theme_name}"
    local target_dir="$cache_dir/prohori"
    local zip_path="$target_dir.zip"
    local url="https://github.com/shell-ninja/prohori/archive/refs/heads/main.zip"

    msg act "Fetching Prohori SDDM theme payload..."
    rm -rf "$target_dir" "$zip_path" "$cache_dir/prohori-main" 2>/dev/null || true
    curl -sL "$url" -o "$zip_path"

    if [[ -f "$zip_path" && -s "$zip_path" ]]; then
        unzip -q -o "$zip_path" -d "$cache_dir" 2>/dev/null || true
        if [[ -d "$cache_dir/prohori-main" ]]; then
            mv "$cache_dir/prohori-main" "$target_dir"
        fi
        rm -f "$zip_path"
    fi

    # Fallback to git clone if curl/unzip payload was incomplete
    if [[ ! -f "$target_dir/Main.qml" ]]; then
        msg act "Cloning Prohori repository directly..."
        rm -rf "$target_dir" 2>/dev/null || true
        git clone --depth=1 https://github.com/shell-ninja/prohori.git "$target_dir" 2>&1 | tee -a "$log"
    fi

    if [[ ! -f "$target_dir/Main.qml" ]]; then
        msg err "Failed to acquire Prohori SDDM theme files!"
        echo "[ ERROR ] Prohori payload could not be retrieved" >> "$log"
        return 1
    fi

    msg act "Deploying Prohori theme to ${theme_dest}..."
    sudo rm -rf "$theme_dest" 2>/dev/null || true
    sudo mkdir -p "$theme_dest"
    sudo cp -rf "$target_dir"/* "$theme_dest/"

    # Copy bundled Outfit fonts system-wide and to user font directory
    if [[ -d "$target_dir/fonts" ]]; then
        msg act "Installing bundled Outfit fonts for SDDM..."
        sudo mkdir -p /usr/share/fonts/prohori
        sudo cp -rf "$target_dir/fonts/"*.ttf /usr/share/fonts/prohori/ 2>/dev/null || true
        mkdir -p ~/.local/share/fonts/prohori
        cp -rf "$target_dir/fonts/"*.ttf ~/.local/share/fonts/prohori/ 2>/dev/null || true
        if command -v fc-cache &>/dev/null; then
            sudo fc-cache -f /usr/share/fonts/prohori 2>/dev/null || true
            fc-cache -f ~/.local/share/fonts/prohori 2>/dev/null || true
        fi
    fi

    sudo chmod -R 755 "$theme_dest"

    # Configure SDDM drop-ins
    msg act "Activating Prohori theme in SDDM configuration..."
    cat <<EOF | sudo tee "$sddm_conf_dir/theme.conf" >/dev/null
[Theme]
Current=${theme_name}

[General]
InputMethod=
EOF

    cat <<EOF | sudo tee "$sddm_conf_dir/theme.conf.user" >/dev/null
[Theme]
Current=${theme_name}

[General]
InputMethod=
EOF

    # Prevent virtual keyboard from opening automatically by default
    if [[ -f "$sddm_conf_dir/virtualkbd.conf" ]]; then
        sudo sed -i 's/^InputMethod=.*/InputMethod=/' "$sddm_conf_dir/virtualkbd.conf" 2>/dev/null || true
    fi

    cat <<EOF | sudo tee "$sddm_conf_dir/zz-prohori-virtualkbd.conf" >/dev/null
[General]
InputMethod=
EOF

    # Legacy fallback /etc/sddm.conf if present
    if [[ -f /etc/sddm.conf ]]; then
        if grep -q "^\[Theme\]" /etc/sddm.conf; then
            if grep -q "^Current=" /etc/sddm.conf; then
                sudo sed -i "s/^Current=.*/Current=${theme_name}/" /etc/sddm.conf
            else
                sudo sed -i "/^\[Theme\]/a Current=${theme_name}" /etc/sddm.conf
            fi
        else
            echo -e "\n[Theme]\nCurrent=${theme_name}" | sudo tee -a /etc/sddm.conf >/dev/null
        fi

        if grep -q "^\[General\]" /etc/sddm.conf; then
            if grep -q "^InputMethod=" /etc/sddm.conf; then
                sudo sed -i "s/^InputMethod=.*/InputMethod=/" /etc/sddm.conf
            else
                sudo sed -i "/^\[General\]/a InputMethod=" /etc/sddm.conf
            fi
        fi
    fi

    # Link theme switcher CLI utility
    if [[ -f "${theme_dest}/switch-theme.sh" ]]; then
        sudo ln -sf "${theme_dest}/switch-theme.sh" /usr/local/bin/prohori-theme 2>/dev/null || true
    fi

    if [[ -d "$theme_dest" ]]; then
        msg dn "Prohori SDDM theme installed and activated successfully!"
        echo "[ DONE ] Prohori theme installed successfully" >> "$log"
    fi
}

install_silentsddm() {
    local theme_name="SilentSDDM"
    local theme_dest="${theme_base_dir}/${theme_name}"
    local target_dir="$cache_dir/SilentSDDM"
    local zip_path="$target_dir.zip"
    local url="https://github.com/shell-ninja/SilentSDDM/archive/refs/heads/main.zip"

    msg act "Fetching SilentSDDM theme payload..."
    rm -rf "$target_dir" "$zip_path" "$cache_dir/SilentSDDM-main" 2>/dev/null || true
    curl -sL "$url" -o "$zip_path"

    if [[ -f "$zip_path" && -s "$zip_path" ]]; then
        unzip -q -o "$zip_path" -d "$cache_dir" 2>/dev/null || true
        if [[ -d "$cache_dir/SilentSDDM-main" ]]; then
            mv "$cache_dir/SilentSDDM-main" "$target_dir"
        fi
        rm -f "$zip_path"
    fi

    if [[ ! -f "$target_dir/Main.qml" ]]; then
        msg act "Cloning SilentSDDM repository directly..."
        rm -rf "$target_dir" 2>/dev/null || true
        git clone --depth=1 https://github.com/shell-ninja/SilentSDDM.git "$target_dir" 2>&1 | tee -a "$log"
    fi

    if [[ ! -f "$target_dir/Main.qml" ]]; then
        msg err "Failed to acquire SilentSDDM theme files!"
        echo "[ ERROR ] SilentSDDM payload could not be retrieved" >> "$log"
        return 1
    fi

    msg act "Deploying SilentSDDM theme to ${theme_dest}..."
    sudo rm -rf "$theme_dest" 2>/dev/null || true
    sudo mkdir -p "$theme_dest"
    sudo cp -rf "$target_dir"/* "$theme_dest/"

    if [[ -d "$theme_dest/fonts" ]]; then
        mkdir -p ~/.local/share/fonts/sddm-fonts
        cp -rf "$theme_dest/fonts/"* ~/.local/share/fonts/sddm-fonts/ 2>/dev/null || true
        sudo mkdir -p /usr/share/fonts/sddm-fonts
        sudo cp -rf "$theme_dest/fonts/"* /usr/share/fonts/sddm-fonts/ 2>/dev/null || true
        if command -v fc-cache &>/dev/null; then
            sudo fc-cache -f /usr/share/fonts/sddm-fonts 2>/dev/null || true
            fc-cache -f ~/.local/share/fonts/sddm-fonts 2>/dev/null || true
        fi
    fi

    sudo chmod -R 755 "$theme_dest"

    msg act "Activating SilentSDDM theme in SDDM configuration..."
    cat <<EOF | sudo tee "$sddm_conf_dir/theme.conf.user" >/dev/null
[Theme]
Current=${theme_name}
EOF

    cat <<EOF | sudo tee "$sddm_conf_dir/virtualkbd.conf" >/dev/null
[General]
InputMethod=qtvirtualkeyboard
EOF

    if [[ -d "$theme_dest" ]]; then
        msg dn "SilentSDDM theme installed and activated successfully!"
        echo "[ DONE ] SilentSDDM theme installed successfully" >> "$log"
    fi
}

# ----------------- Theme Determination ----------------- #

choice="${1:-}"

# 1. Check dedicated sddm_theme cache
if [[ -z "$choice" && -f "$cache_dir/sddm_theme" ]]; then
    choice="$(cat "$cache_dir/sddm_theme" | tr -d '\r\n')"
fi

# 2. Check user-cache
if [[ -z "$choice" && -f "$cache_dir/user-cache" ]]; then
    source "$cache_dir/user-cache"
    if [[ "${install_sddm_theme:-}" == "N" ]]; then
        choice="Skip"
    elif [[ -n "${sddm_theme_name:-}" ]]; then
        choice="$sddm_theme_name"
    fi
fi

# 3. Interactive fallback if running standalone in terminal without cache
if [[ -z "$choice" ]]; then
    if [[ -t 0 || -c /dev/tty ]]; then
        msg ask "Select your preferred SDDM greeter theme:"
        if command -v gum &>/dev/null; then
            choice=$(gum choose \
                --cursor.foreground "#bd93f9" \
                --item.foreground "#c0caf5" \
                --selected.foreground "#a6e3a1" \
                "Prohori" "SilentSDDM" "Skip"
            )
        else
            echo "  1) Prohori (Modern minimalist SDDM greeter with dials & monolithic clock)"
            echo "  2) SilentSDDM (Minimalist dark blurred greeter)"
            echo "  3) Skip"
            read -r -p "Enter choice [1-3]: " num_choice
            case "$num_choice" in
                1) choice="Prohori" ;;
                2) choice="SilentSDDM" ;;
                3) choice="Skip" ;;
                *) choice="Prohori" ;;
            esac
        fi
    else
        choice="Prohori"
    fi
fi

# ----------------- Execution ----------------- #

case "${choice,,}" in
    prohori)
        install_prohori
        ;;
    silentsddm)
        install_silentsddm
        ;;
    skip|none|n)
        msg skp "Skipping SDDM greeter theme installation as requested."
        echo "[ SKIP ] SDDM theme skipped by user" >> "$log"
        exit 0
        ;;
    *)
        msg att "Unrecognized theme '$choice'. Defaulting to Prohori..."
        install_prohori
        ;;
esac

sleep 1 && clear
