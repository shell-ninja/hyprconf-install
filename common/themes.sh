#!/usr/bin/env bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# Color definitions
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
log="$log_dir/themes-$(date +%d-%m-%y).log"
mkdir -p "$log_dir"
touch "$log"

cache_dir="$parent_dir/.cache"
mkdir -p "$cache_dir"

# Determine package manager
pkgman=""
if [[ -f "$cache_dir/pkgman" ]]; then
    source "$cache_dir/pkgman"
fi
if [[ -z "$pkgman" ]]; then
    if command -v pacman &>/dev/null; then
        pkgman="pacman"
    elif command -v dnf &>/dev/null; then
        pkgman="dnf"
    elif command -v zypper &>/dev/null; then
        pkgman="zypper"
    elif command -v apt-get &>/dev/null; then
        pkgman="apt"
    else
        pkgman="pacman"
    fi
fi

# ----------------- 1. Install adw-gtk3 Theme ----------------- #

install_adw_gtk3() {
    msg act "Checking and installing adw-gtk3 theme..."

    # Check if adw-gtk3 or adw-gtk3-dark is already installed
    if [[ -d "/usr/share/themes/adw-gtk3-dark" || -d "$HOME/.themes/adw-gtk3-dark" ]]; then
        msg dn "adw-gtk3 theme is already present."
        echo "[ SKIP ] adw-gtk3 already installed" >> "$log"
        return 0
    fi

    local installed=false
    case "$pkgman" in
        pacman)
            echo "[ ACT ] Installing adw-gtk-theme via pacman" >> "$log"
            sudo pacman -S --needed --noconfirm adw-gtk-theme 2>&1 | tee -a "$log" >/dev/null && installed=true
            ;;
        dnf)
            echo "[ ACT ] Installing adw-gtk3-theme via dnf" >> "$log"
            sudo dnf install -y adw-gtk3-theme 2>&1 | tee -a "$log" >/dev/null && installed=true
            ;;
        zypper)
            echo "[ ACT ] Installing adw-gtk3-theme via zypper" >> "$log"
            (sudo zypper --non-interactive in adw-gtk3-theme 2>&1 || sudo zypper --non-interactive in adw-gtk3 2>&1) | tee -a "$log" >/dev/null && installed=true
            ;;
        apt)
            echo "[ ACT ] Installing adw-gtk3 via apt" >> "$log"
            (sudo apt-get install -y adw-gtk3-theme 2>&1 || sudo apt-get install -y adw-gtk3 2>&1) | tee -a "$log" >/dev/null && installed=true
            ;;
    esac

    # Fallback to direct GitHub release tarball extraction if package was not in distro repos
    if [[ "$installed" != true && ! -d "/usr/share/themes/adw-gtk3-dark" ]]; then
        msg act "Downloading adw-gtk3 release payload directly..."
        local adw_url="https://github.com/lassekongo83/adw-gtk3/releases/download/v6.5/adw-gtk3v6-5.tar.xz"
        local adw_tar="$cache_dir/adw-gtk3.tar.xz"
        curl -sL "$adw_url" -o "$adw_tar"
        if [[ -f "$adw_tar" && -s "$adw_tar" ]]; then
            sudo mkdir -p /usr/share/themes
            sudo tar -xf "$adw_tar" -C /usr/share/themes/ 2>/dev/null || true
            mkdir -p "$HOME/.themes"
            tar -xf "$adw_tar" -C "$HOME/.themes/" 2>/dev/null || true
            rm -f "$adw_tar"
        fi
    fi

    if [[ -d "/usr/share/themes/adw-gtk3-dark" || -d "$HOME/.themes/adw-gtk3-dark" ]]; then
        msg dn "adw-gtk3 theme installed successfully."
        echo "[ DONE ] adw-gtk3 installed successfully" >> "$log"
    else
        msg att "Notice: adw-gtk3 will be managed via user config."
        echo "[ WARN ] adw-gtk3 package could not be verified in system paths" >> "$log"
    fi
}

# ----------------- 2. Extract & Deploy Kora Icon Pack ----------------- #

deploy_kora_icons() {
    local kora_archive="$parent_dir/assets/kora-2-0-5.tar.gz"

    if [[ ! -f "$kora_archive" ]]; then
        msg err "Kora icon archive not found at $kora_archive"
        echo "[ ERROR ] $kora_archive missing" >> "$log"
        return 1
    fi

    msg act "Deploying Kora icon pack from assets..."

    # User XDG icon directory
    mkdir -p "$HOME/.local/share/icons"
    tar -xzf "$kora_archive" -C "$HOME/.local/share/icons/" 2>&1 | tee -a "$log" >/dev/null

    # Compatibility symlink for legacy ~/.icons/kora
    mkdir -p "$HOME/.icons"
    ln -snf "$HOME/.local/share/icons/kora" "$HOME/.icons/kora"

    # System-wide installation for display manager & root daemons
    if [[ -d "/usr/share/icons" ]]; then
        sudo tar -xzf "$kora_archive" -C /usr/share/icons/ 2>/dev/null || true
    fi

    # Update icon caches if utility exists
    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons/kora" 2>/dev/null || true
        sudo gtk-update-icon-cache -f -t /usr/share/icons/kora 2>/dev/null || true
    fi

    msg dn "Kora icon pack deployed successfully."
    echo "[ DONE ] Kora icon pack deployed to ~/.local/share/icons and /usr/share/icons" >> "$log"

    # Optional Bibata cursor pack deployment if present in assets/
    local bibata_archive="$parent_dir/assets/Bibata-Modern-Ice.tar.gz"
    if [[ -f "$bibata_archive" ]]; then
        msg act "Deploying Bibata-Modern-Ice cursor pack from assets..."
        mkdir -p "$HOME/.local/share/icons"
        tar -xzf "$bibata_archive" --strip-components=1 -C "$HOME/.local/share/icons/" 2>&1 | tee -a "$log" >/dev/null || true
        mkdir -p "$HOME/.icons"
        ln -snf "$HOME/.local/share/icons/Bibata-Modern-Ice" "$HOME/.icons/Bibata-Modern-Ice" 2>/dev/null || true
        if [[ -d "/usr/share/icons" ]]; then
            sudo tar -xzf "$bibata_archive" --strip-components=1 -C /usr/share/icons/ 2>/dev/null || true
        fi
        msg dn "Bibata-Modern-Ice cursor pack deployed successfully."
        echo "[ DONE ] Bibata cursor pack deployed" >> "$log"
    fi
}

# ----------------- 3. Configure GTK Settings ----------------- #

configure_gtk() {
    msg act "Configuring GTK theme (adw-gtk3-dark) and icon theme (kora)..."

    # 1. GSettings (live GNOME / Wayland desktop portal state)
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "kora" 2>/dev/null || true
    fi

    # 2. GTK 3 settings.ini
    mkdir -p "$HOME/.config/gtk-3.0"
    if [[ -f "$HOME/.config/gtk-3.0/settings.ini" ]]; then
        sed -i 's/^gtk-theme-name=.*/gtk-theme-name=adw-gtk3-dark/' "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
        sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=kora/' "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
        sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
    else
        cat << 'EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=kora
gtk-font-name=Sans 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
    fi

    # 3. GTK 4 settings.ini
    mkdir -p "$HOME/.config/gtk-4.0"
    if [[ -f "$HOME/.config/gtk-4.0/settings.ini" ]]; then
        sed -i 's/^gtk-theme-name=.*/gtk-theme-name=adw-gtk3-dark/' "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
        sed -i 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=kora/' "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
        sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
    else
        cat << 'EOF' > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=kora
gtk-font-name=Sans 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    fi

    # 4. GTK 2 legacy .gtkrc-2.0
    cat << 'EOF' > "$HOME/.gtkrc-2.0"
gtk-theme-name="adw-gtk3-dark"
gtk-icon-theme-name="kora"
gtk-font-name="Sans 11"
gtk-cursor-theme-name="Bibata-Modern-Ice"
gtk-cursor-theme-size=24
EOF

    # 5. xsettingsd configuration
    mkdir -p "$HOME/.config/xsettingsd"
    cat << 'EOF' > "$HOME/.config/xsettingsd/xsettingsd.conf"
Net/ThemeName "adw-gtk3-dark"
Net/IconThemeName "kora"
Gtk/CursorThemeName "Bibata-Modern-Ice"
Net/EnableEventSounds 1
EnableInputFeedbackSounds 0
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintslight"
Xft/RGBA "rgb"
EOF

    echo "[ DONE ] GTK 2/3/4 and GSettings configured" >> "$log"
}

# ----------------- 4. Configure Qt / KDE Settings ----------------- #

configure_qt() {
    msg act "Configuring Qt platform theme and Kora icon pack..."

    # 1. qt5ct
    mkdir -p "$HOME/.config/qt5ct"
    if [[ -f "$HOME/.config/qt5ct/qt5ct.conf" ]]; then
        if grep -q "^icon_theme=" "$HOME/.config/qt5ct/qt5ct.conf"; then
            sed -i 's/^icon_theme=.*/icon_theme=kora/' "$HOME/.config/qt5ct/qt5ct.conf" 2>/dev/null || true
        elif grep -q "^\[Appearance\]" "$HOME/.config/qt5ct/qt5ct.conf"; then
            sed -i '/^\[Appearance\]/a icon_theme=kora' "$HOME/.config/qt5ct/qt5ct.conf" 2>/dev/null || true
        else
            echo -e "\n[Appearance]\nicon_theme=kora" >> "$HOME/.config/qt5ct/qt5ct.conf"
        fi
    else
        cat << 'EOF' > "$HOME/.config/qt5ct/qt5ct.conf"
[Appearance]
icon_theme=kora
style=kvantum
standard_dialogs=xdgdesktopportal
EOF
    fi

    # 2. qt6ct
    mkdir -p "$HOME/.config/qt6ct"
    if [[ -f "$HOME/.config/qt6ct/qt6ct.conf" ]]; then
        if grep -q "^icon_theme=" "$HOME/.config/qt6ct/qt6ct.conf"; then
            sed -i 's/^icon_theme=.*/icon_theme=kora/' "$HOME/.config/qt6ct/qt6ct.conf" 2>/dev/null || true
        elif grep -q "^\[Appearance\]" "$HOME/.config/qt6ct/qt6ct.conf"; then
            sed -i '/^\[Appearance\]/a icon_theme=kora' "$HOME/.config/qt6ct/qt6ct.conf" 2>/dev/null || true
        else
            echo -e "\n[Appearance]\nicon_theme=kora" >> "$HOME/.config/qt6ct/qt6ct.conf"
        fi
    else
        cat << 'EOF' > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
icon_theme=kora
style=kvantum-dark
standard_dialogs=xdgdesktopportal
EOF
    fi

    # 3. KDE Globals (~/.config/kdeglobals)
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme kora 2>/dev/null || true
    elif command -v kwriteconfig5 &>/dev/null; then
        kwriteconfig5 --file kdeglobals --group Icons --key Theme kora 2>/dev/null || true
    fi

    mkdir -p "$HOME/.config"
    if [[ -f "$HOME/.config/kdeglobals" ]]; then
        if grep -q "^\[Icons\]" "$HOME/.config/kdeglobals"; then
            sed -i '/^\[Icons\]/,/^\[/ s/^Theme=.*/Theme=kora/' "$HOME/.config/kdeglobals" 2>/dev/null || true
        else
            echo -e "\n[Icons]\nTheme=kora" >> "$HOME/.config/kdeglobals"
        fi
    else
        cat << 'EOF' > "$HOME/.config/kdeglobals"
[Icons]
Theme=kora
EOF
    fi

    # 4. Ensure environment variable profile has QT_QPA_PLATFORMTHEME set
    local env_file="$HOME/.config/environment.d/10-qt.conf"
    mkdir -p "$HOME/.config/environment.d"
    if [[ ! -f "$env_file" ]]; then
        cat << 'EOF' > "$env_file"
QT_QPA_PLATFORMTHEME=qt6ct
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
EOF
    fi

    echo "[ DONE ] Qt5ct, Qt6ct, and kdeglobals configured for kora" >> "$log"
}

# ----------------- Execution ----------------- #

install_adw_gtk3
deploy_kora_icons
configure_gtk
configure_qt

msg dn "adw-gtk3 and Kora icons configured for GTK and Qt environments."
echo "[ DONE ] Theme setup completed successfully" >> "$log"

sleep 1 && clear