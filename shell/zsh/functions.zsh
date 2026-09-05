#!/usr/bin/env zsh

# ~/.zsh/functions.zsh
#==============================================================================
# ███████╗██╗  ██╗███████╗██╗     ██╗     
# ██╔════╝██║  ██║██╔════╝██║     ██║     
# ███████╗███████║█████╗  ██║     ██║     
# ╚════██║██╔══██║██╔══╝  ██║     ██║     
# ███████║██║  ██║███████╗███████╗███████╗
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
#                                         
# ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗  
# ████╗  ██║██║████╗  ██║     ██║██╔══██╗ 
# ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║ 
# ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║ 
# ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║ 
# ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝ 
#==============================================================================

# --- copy-paste with automatic sudo elevation ---
fn_copy_paste() {
    local -a opts=()
    local -a args=()
    local parse_opts=1

    for arg in "$@"; do
        if [[ "$parse_opts" -eq 1 && "$arg" == "--" ]]; then
            parse_opts=0
            continue
        fi
        if [[ "$parse_opts" -eq 1 && "$arg" == -* ]]; then
            opts+=("$arg")
        else
            args+=("$arg")
        fi
    done

    if (( ${#args[@]} < 2 )); then
        printf "Usage: cp [options] <source...> <destination>\n"
        return 1
    fi

    local destination="${args[-1]}"
    local raw_destination="$destination"
    destination="${destination%/}"
    local -a items=("${(@)args[1,-2]}")

    # ---- Determine mode: directory vs. single file copy ----
    local mode="dir"
    if (( ${#items[@]} == 1 )) && [[ ! -d "$destination" ]]; then
        # Only one source and destination does not exist as a directory -> rename / single file copy
        mode="file"
    fi
    if [[ "$raw_destination" == */ ]]; then
        mode="dir"
    fi

    # ---- Decide whether sudo is required (only when necessary) ----
    local SUDO=""
    if (( EUID != 0 )); then
        if [[ "$mode" == "dir" ]]; then
            if [[ -d "$destination" ]]; then
                [[ -w "$destination" && -x "$destination" ]] || SUDO="sudo"
            else
                local parent="${destination:h}"
                [[ -w "$parent" && -x "$parent" ]] || SUDO="sudo"
            fi
        else
            local dest_dir="${destination:h}"
            if [[ -e "$destination" ]]; then
                [[ -w "$destination" ]] || SUDO="sudo"
            else
                [[ -w "$dest_dir" && -x "$dest_dir" ]] || SUDO="sudo"
            fi
        fi

        # Also check readability of every source item
        for item in "${items[@]}"; do
            if [[ ! -r "$item" ]]; then
                SUDO="sudo"
                break
            fi
        done
    fi

    # ---- Refresh sudo credentials early if needed ----
    if [[ -n $SUDO ]]; then
        sudo -v 2>/dev/null || true
    fi

    # ---- Create destination if it does not exist ----
    if [[ "$mode" == "dir" ]]; then
        if [[ ! -d "$destination" ]]; then
            if ! mkdir -p "$destination" 2>/dev/null; then
                if [[ -n $SUDO ]]; then
                    $SUDO mkdir -p "$destination" || {
                        printf "!! Failed to create destination directory: %s\n" "$destination"
                        return 1
                    }
                else
                    printf "!! Failed to create destination directory: %s\n" "$destination"
                    return 1
                fi
            fi
        fi
    else
        local dest_dir="${destination:h}"
        if [[ ! -d "$dest_dir" ]]; then
            if ! mkdir -p "$dest_dir" 2>/dev/null; then
                if [[ -n $SUDO ]]; then
                    $SUDO mkdir -p "$dest_dir" || {
                        printf "!! Failed to create parent directory: %s\n" "$dest_dir"
                        return 1
                    }
                else
                    printf "!! Failed to create parent directory: %s\n" "$dest_dir"
                    return 1
                fi
            fi
        fi
    fi

    # ---- Copy each item ----
    for item in "${items[@]}"; do
        item="${item%/}"
        local name="${item:t}"

        if [[ -f "$item" ]]; then
            local target_file=""
            if [[ "$mode" == "file" ]]; then
                target_file="$destination"
            else
                target_file="$destination/$name"
            fi

            printf "\n:: Copying file %s → %s\n" "$name" "$target_file"
            if [[ "$name" == *.iso ]]; then
                if (( $+commands[pv] )); then
                    pv "$item" | $SUDO dd of="$target_file" bs=4M status=none
                else
                    $SUDO dd if="$item" of="$target_file" bs=4M status=progress
                fi

                if (( pipestatus[-1] == 0 )); then
                    printf "\n:: Syncing to disk (this may take a while)...\n"
                    $SUDO sync &
                    local sync_pid=$!
                    local spinstr='|/-\'
                    while kill -0 $sync_pid 2>/dev/null; do
                        for ((i=1; i<=${#spinstr}; i++)); do
                            printf "\r[%c] Syncing... " "${spinstr[i]}"
                            sleep 0.1
                        done
                    done
                    wait $sync_pid 2>/dev/null
                    printf "\r\e[KSync complete.\n"
                fi
            else
                if (( $+commands[pv] )); then
                    if [[ -n $SUDO ]]; then
                        pv "$item" | sudo tee "$target_file" > /dev/null
                    else
                        pv "$item" > "$target_file"
                    fi
                else
                    if [[ -n $SUDO ]]; then
                        $SUDO cp "$item" "$target_file"
                    else
                        cp "$item" "$target_file"
                    fi
                fi
                chmod --reference="$item" "$target_file" 2>/dev/null || $SUDO chmod --reference="$item" "$target_file" 2>/dev/null || true
            fi

        elif [[ -d "$item" ]]; then
            if [[ "$mode" == "file" ]]; then
                printf "\n:: Copying directory %s → %s (renamed)\n" "$name" "$destination"
                if ! mkdir -p "$destination" 2>/dev/null; then
                    if [[ -n $SUDO ]]; then
                        $SUDO mkdir -p "$destination" || {
                            printf "!! Failed to create destination directory: %s\n" "$destination"
                            return 1
                        }
                    else
                        printf "!! Failed to create destination directory: %s\n" "$destination"
                        return 1
                    fi
                fi

                if (( $+commands[pv] )); then
                    if [[ -n $SUDO ]]; then
                        $SUDO tar -C "$item" -cf - . | pv -N "$name" | $SUDO tar -xf - -C "$destination"
                    else
                        tar -C "$item" -cf - . | pv -N "$name" | tar -xf - -C "$destination"
                    fi
                else
                    if [[ -n $SUDO ]]; then
                        $SUDO cp -r "$item"/. "$destination"
                    else
                        cp -r "$item"/. "$destination"
                    fi
                fi
            else
                printf "\n:: Copying directory %s → %s\n" "$name" "$destination"
                local parent="${item:h}"

                if (( $+commands[pv] )); then
                    if [[ -n $SUDO ]]; then
                        $SUDO tar -C "$parent" -cf - "$name" | pv -N "$name" | $SUDO tar -xf - -C "$destination"
                    else
                        tar -C "$parent" -cf - "$name" | pv -N "$name" | tar -xf - -C "$destination"
                    fi
                else
                    if [[ -n $SUDO ]]; then
                        $SUDO cp -r "$item" "$destination"
                    else
                        cp -r "$item" "$destination"
                    fi
                fi
            fi
        else
            printf "!! Skipping unknown type: %s\n" "$item"
        fi
    done
}
unalias copy_paste 2>/dev/null || true
function copy_paste { fn_copy_paste "$@"; }

# remove files and directories (safer, verbose, smart sudo)
fn_removal() {
    local -a items=()
    local parse_opts=1

    for arg in "$@"; do
        if [[ "$parse_opts" -eq 1 && "$arg" == "--" ]]; then
            parse_opts=0
            continue
        fi
        if [[ "$parse_opts" -eq 1 && "$arg" == -* ]]; then
            continue
        fi
        items+=("$arg")
    done

    if (( ${#items[@]} == 0 )); then
        printf "Usage: rm <file|dir> ...\n"
        return 1
    fi

    # ---- decide if sudo is needed (check parent writability) ----
    local SUDO=""
    if (( EUID != 0 )); then
        for item in "${items[@]}"; do
            local parent="${item:h}"
            if [[ ! -w "$parent" ]]; then
                SUDO="sudo"
                break
            fi
        done
    fi

    # refresh sudo credentials early (avoid mid-operation prompts)
    if [[ -n $SUDO ]]; then
        sudo -v 2>/dev/null || true
    fi

    for item in "${items[@]}"; do
        if [[ -f "$item" || -L "$item" ]]; then
            printf ":: Removing file: %s\n" "$item"
            $SUDO rm -v "$item"
        elif [[ -d "$item" ]]; then
            printf ":: Removing directory: %s\n" "$item"
            $SUDO rm -rfv "$item"
        else
            printf "[ !! ] %s does not exist or is neither a regular file nor a directory\n" "$item"
        fi
    done
}
unalias removal 2>/dev/null || true
function removal { fn_removal "$@"; }

# disk and memory resources (with fallback and usage)
fn_resources() {
    case "${1:-}" in
        disk|__disk)
            df -h / | awk 'NR==2 {printf "Total: %s\nUsed: %s\nFree: %s\n", $2, $3, $4}'
            ;;
        memory|__memory)
            free -h | awk '/^Mem:/ {printf "Total: %s\nUsed: %s\nFree: %s\n", $2, $3, $7}'
            ;;
        *)
            printf "Usage: fn_resources <disk|memory>\n"
            return 1
            ;;
    esac
}
unalias resources 2>/dev/null || true
function resources { fn_resources "$@"; }

# internal: detect package manager (cached)
_detect_pkg_manager() {
    [[ -n "$PKG_MANAGER" ]] && return
    if (( $+commands[pacman] )); then
        export PKG_MANAGER="pacman"
        local aur="${commands[yay]:-${commands[paru]}}"
        export AUR_HELPER="${aur:-}"
    elif (( $+commands[dnf] )); then
        export PKG_MANAGER="dnf"
    elif (( $+commands[zypper] )); then
        export PKG_MANAGER="zypper"
    elif (( $+commands[apt-get] )); then
        export PKG_MANAGER="apt"
    else
        export PKG_MANAGER="unknown"
    fi
}

# check updates (improved fallback for Arch)
fn_check_updates() {
    _detect_pkg_manager
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        local ofc=0 aur=0
        if (( $+commands[checkupdates] )); then
            ofc=$(checkupdates 2>/dev/null | wc -l)
        else
            ofc=$(pacman -Qu 2>/dev/null | wc -l)
        fi
        if [[ -n "$AUR_HELPER" ]]; then
            aur=$("$AUR_HELPER" -Qua 2>/dev/null | wc -l)
        fi
        local upd=$(( ofc + aur ))
        printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available.\n:: Main: %d\n:: AUR: %d\n" "$upd" "$ofc" "$aur"
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        local upd
        upd=$(dnf check-update -q 2>/dev/null | grep -cv '^$')
        printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available\n" "$upd"
    elif [[ "$PKG_MANAGER" == "zypper" ]]; then
        local upd
        upd=$(zypper lu --best-effort 2>/dev/null | grep -c 'v  |')
        printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available\n" "$upd"
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        local upd
        upd=$(apt list --upgradable 2>/dev/null | grep -c '\[upgradable from')
        printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available\n" "$upd"
    else
        printf "\e[1;31m Unsupported package manager.\e[0m\n"
        return 1
    fi
}
unalias check_updates 2>/dev/null || true
function check_updates { fn_check_updates "$@"; }

# package updates
fn_update() {
    _detect_pkg_manager
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        if [[ -n "$AUR_HELPER" ]]; then
            "$AUR_HELPER" -Syyu --noconfirm
        else
            sudo pacman -Syyu --noconfirm
        fi
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        sudo dnf upgrade -y
    elif [[ "$PKG_MANAGER" == "zypper" ]]; then
        sudo zypper ref && sudo zypper up -y
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt update && sudo apt upgrade -y
    else
        printf "\e[1;31m Unsupported package manager.\e[0m\n"
        return 1
    fi
}

# Install software (non-interactive, requires arguments)
fn_install() {
    if (( $# == 0 )); then
        printf "Usage: fn_install <package...>\n"
        return 1
    fi
    _detect_pkg_manager
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        if [[ -n "$AUR_HELPER" ]]; then
            "$AUR_HELPER" -S --noconfirm "$@"
        else
            sudo pacman -S --noconfirm "$@"
        fi
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        sudo dnf install -y "$@"
    elif [[ "$PKG_MANAGER" == "zypper" ]]; then
        sudo zypper in -y "$@"
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt install -y "$@"
    else
        printf "\e[1;31m Unsupported package manager.\e[0m\n"
        return 1
    fi
}

# package uninstall (non-interactive, requires arguments)
fn_uninstall() {
    if (( $# == 0 )); then
        printf "Usage: fn_uninstall <package...>\n"
        return 1
    fi
    _detect_pkg_manager
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        if [[ -n "$AUR_HELPER" ]]; then
            "$AUR_HELPER" -Rns --noconfirm "$@"
        else
            sudo pacman -Rns --noconfirm "$@"
        fi
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        sudo dnf remove -y "$@"
    elif [[ "$PKG_MANAGER" == "zypper" ]]; then
        sudo zypper rm -y "$@"
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt remove -y "$@"
    else
        printf "\e[1;31m Unsupported package manager.\e[0m\n"
        return 1
    fi
}

# compile cpp file with g++ (with sanity checks)
fn_compile_cpp() {
    if (( ! $+commands[g++] )); then
        printf "\e[1;91m[  ] - g++ not found. Please install g++ first.\e[0m\n"
        return 1
    fi
    if [[ -z "$1" ]]; then
        printf "Usage: fn_compile_cpp <file_without_cpp_extension> [-o]\n"
        return 1
    fi
    local source="${1}.cpp"
    if [[ ! -f "$source" ]]; then
        printf "\e[1;91m[  ] - Source file %s not found.\e[0m\n" "$source"
        return 1
    fi
    local output="${1}"
    printf "\e[0;36m[ * ] - Compiling...!\e[0m\n"
    if g++ -std=c++20 "$source" -o "$output"; then
        printf "\e[1;92m[ ✓ ] - Successfully compiled.\e[0m\n"
        if [[ "${2:-}" == "-o" ]]; then
            printf "\e[1;92m        Output: \e[0m\n\n" 
            "./$output"
        fi
    else
        printf "\n\e[1;91m[  ] - Compilation failed.\e[0m\n"
        return 1
    fi
}

# git info (branch and status)
git_info() {
    local branch_name
    branch_name=$(git branch --show-current 2>/dev/null) || return 0

    if [[ -n "$branch_name" ]]; then
        local untracked_count=0 unstaged_count=0 staged_count=0
        local line

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local x="${line[1]}" y="${line[2]}"
            if [[ "$x" == "?" && "$y" == "?" ]]; then
                ((untracked_count++))
            else
                [[ "$x" != " " && "$x" != "?" ]] && ((staged_count++))
                [[ "$y" != " " && "$y" != "?" ]] && ((unstaged_count++))
            fi
        done < <(git status --porcelain 2>/dev/null)

        printf "on \e[1;34m\e[1;32m %s\e[1;0m " "$branch_name"

        (( untracked_count > 0 )) && printf "\e[1;31m?%d \e[3;0m" "$untracked_count"
        (( staged_count > 0 )) && printf "\e[1;32m%d \e[3;0m" "$staged_count"
        (( unstaged_count > 0 )) && printf "\e[1;33m!%d \e[3;0m" "$unstaged_count"

        if (( untracked_count == 0 && staged_count == 0 && unstaged_count == 0 )); then
            printf "\e[1;32m✓ \e[3;0m"
        fi
        printf "\n"
    fi
}

# fn to push git commits easily
push() {
    local branch_name
    branch_name=$(git branch --show-current 2>/dev/null) || {
        printf "!! Not inside a Git repository.\n"
        return 1
    }

    local untracked_count=0 unstaged_count=0 staged_count=0
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local x="${line[1]}" y="${line[2]}"
        if [[ "$x" == "?" && "$y" == "?" ]]; then
            ((untracked_count++))
        else
            [[ "$x" != " " && "$x" != "?" ]] && ((staged_count++))
            [[ "$y" != " " && "$y" != "?" ]] && ((unstaged_count++))
        fi
    done < <(git status --porcelain 2>/dev/null)

    if (( untracked_count > 0 )); then printf "=> %s untracked files\n" "$untracked_count"; fi
    if (( unstaged_count > 0 )); then printf "=> %s uncommitted changes\n" "$unstaged_count"; fi
    if (( staged_count > 0 )); then printf "=> %s staged changes\n" "$staged_count"; fi

    if (( untracked_count == 0 && unstaged_count == 0 && staged_count == 0 )); then
        printf "✓ Nothing to push.\n"
        return 0
    fi

    printf "=> %s branch\n\nWrite the commit message\n" "$branch_name"

    local msg
    if [[ -t 0 ]] && (( $+commands[gum] )); then
        msg="$(gum input --placeholder "Write your commit message")"
    else
        read -r "msg?=> "
    fi

    [[ -z "$msg" ]] && { printf "!! Aborting due to empty commit message.\n"; return 1; }

    git add .
    if ! git commit -m "$msg"; then
        printf "!! Commit failed.\n"
        return 1
    fi

    git push origin "$branch_name"
    local exit_code=$?

    if (( exit_code == 0 )); then
        printf ":: Pushed successfully!\n"
    else
        printf "!! Sorry, push failed. Please check for errors.\n"
    fi
}

# fn for yazi (file manager cd on exit)
function y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    local cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ---- Command timing and prompt utilities (zsh-native) ----
typeset -g _command_start_time=$EPOCHSECONDS
typeset -g elapsed_time_display=""

_timing_preexec() {
    _command_start_time=$EPOCHSECONDS
}

_timing_precmd() {
    local end_time=$EPOCHSECONDS
    local elapsed=$(( end_time - _command_start_time ))
    if (( elapsed > 0 )); then
        local minutes=$(( elapsed / 60 ))
        local seconds=$(( elapsed % 60 ))
        if (( minutes > 0 )); then
            elapsed_time_display=$(printf "\e[90m  %dm %ds\e[0m" $minutes $seconds)
        elif (( seconds > 3 )); then
            elapsed_time_display=$(printf "\e[90m  %ds\e[0m" $seconds)
        else
            elapsed_time_display=""
        fi
    else
        elapsed_time_display=""
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _timing_preexec
add-zsh-hook precmd _timing_precmd

# Function to show current time (for prompt)
current_time() {
    printf "\e[90m %s\e[0m" "$(date +'%I:%M %p')"
}

# Fastfetch wrapper that uses ffconfig when invoked with no arguments
fastfetch() {
    local preset_file="$HOME/.local/share/fastfetch/presets/${ffconfig}.jsonc"
    if (( $# == 0 )) && [[ -n "${ffconfig:-}" ]]; then
        if [[ -f "$preset_file" ]]; then
            command fastfetch --config "$preset_file"
        else
            command fastfetch --config "$ffconfig"
        fi
    else
        command fastfetch "$@"
    fi
}

# Interactive fastfetch style switcher
ffstyle() {
    local presetDir="$HOME/.local/share/fastfetch/presets"
    local zsh_config="$HOME/.zsh/.zshrc"

    # Check preset directory
    if [[ ! -d "$presetDir" ]]; then
        printf "Preset directory not found: %s\n" "$presetDir"
        return 1
    fi

    # Check zshrc
    if [[ ! -f "$zsh_config" ]]; then
        printf "Zsh config not found: %s\n" "$zsh_config"
        return 1
    fi

    # Find presets
    local -a presets=()
    local preset

    for preset in "$presetDir"/*.jsonc(N); do
        [[ -f "$preset" ]] || continue
        presets+=("${preset:t:r}")
    done

    if (( ${#presets[@]} == 0 )); then
        printf "No presets found in %s\n" "$presetDir"
        return 1
    fi

    # Display menu
    printf -- "-> Choose Fastfetch style\n"

    local i=1
    for preset in "${presets[@]}"; do
        printf "%d. %s\n" "$i" "$preset"
        ((i++))
    done

    # Read selection
    local choice
    read -r "choice?Select: "

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#presets[@]} )); then
        printf "Invalid selection.\n"
        return 1
    fi

    local selected="${presets[choice]}"

    printf "\nSetting Fastfetch style to: %s\n" "$selected"

    # Make a backup before modifying .zshrc
    command cp -- "$zsh_config" "$zsh_config.bak"

    # Replace ANY existing ffconfig definition
    if grep -Eq '^[[:space:]]*export[[:space:]]+ffconfig[[:space:]]*=' "$zsh_config"; then
        sed -i -E \
            "s|^[[:space:]]*export[[:space:]]+ffconfig[[:space:]]*=.*$|export ffconfig=\"$selected\"|" \
            "$zsh_config"
    else
        printf '\nexport ffconfig="%s"\n' "$selected" >> "$zsh_config"
    fi

    # Update current shell
    export ffconfig="$selected"

    printf "Updated: %s\n" "$zsh_config"
    printf "ffconfig=%s\n\n" "$ffconfig"

    # Show the actual line written to .zshrc
    printf -- "--- .zshrc ---\n"
    grep -n 'ffconfig' "$zsh_config"
    printf -- "----------------\n\n"

    # Run selected preset immediately
    command fastfetch --config "$presetDir/${selected}.jsonc"
}

ffimg() {
    local preferredDir="$HOME/.local/share/fastfetch/images"
    local zsh_config="$HOME/.zsh/.zshrc"
    local config="$HOME/.local/share/fastfetch/presets/minimal.jsonc"

    # ------------------------------------------------------------
    # Check required paths
    # ------------------------------------------------------------
    if [[ ! -d "$preferredDir" ]]; then
        printf "Image directory not found: %s\n" "$preferredDir"
        return 1
    fi

    if [[ ! -f "$zsh_config" ]]; then
        printf "Zsh config not found: %s\n" "$zsh_config"
        return 1
    fi

    if [[ ! -f "$config" ]]; then
        printf "Config file not found: %s\n" "$config"
        return 1
    fi

    # ------------------------------------------------------------
    # Read ffconfig from .zshrc
    # ------------------------------------------------------------
    local current_style

    current_style="$(
        sed -nE \
            's/^[[:space:]]*export[[:space:]]+ffconfig[[:space:]]*=[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' \
            "$zsh_config" |
            tail -n 1
    )"

    current_style="${current_style:-${ffconfig:-}}"

    if [[ "$current_style" != "minimal" ]]; then
        printf "minimal style is not selected (current: %s).\n" \
            "${current_style:-none}"
        return 0
    fi

    # ------------------------------------------------------------
    # Check dependencies
    # ------------------------------------------------------------
    if (( ! $+commands[fzf] )); then
        printf "fzf is required for image preview.\n"
        printf "Install it with: sudo pacman -S fzf\n"
        return 1
    fi

    if (( ! $+commands[chafa] )); then
        printf "chafa is required for image preview.\n"
        printf "Install it with: sudo pacman -S chafa\n"
        return 1
    fi

    # ------------------------------------------------------------
    # Find images
    # ------------------------------------------------------------
    local -a images=()
    local img

    for img in "$preferredDir"/*(N); do
        [[ -f "$img" ]] || continue
        images+=("${img:t}")
    done

    if (( ${#images[@]} == 0 )); then
        printf "No images found in %s\n" "$preferredDir"
        return 1
    fi

    # ------------------------------------------------------------
    # Interactive image picker + live preview
    # ------------------------------------------------------------
    local selected

    selected="$(
        printf '%s\n' "${images[@]}" |
        fzf \
            --height=80% \
            --layout=reverse \
            --border \
            --prompt="Image > " \
            --header="↑↓ Browse • Enter Select • Esc Cancel" \
            --preview="chafa --clear --format=symbols --size=45x20 --animate=off --polite on -- \"$preferredDir\"/{}" \
            --preview-window='right:55%:wrap'
    )"

    # Cancelled
    if [[ -z "$selected" ]]; then
        printf "Selection cancelled.\n"
        return 0
    fi

    printf "\nSetting %s as Fastfetch image...\n" "$selected"

    # ------------------------------------------------------------
    # Escape filename for sed
    # ------------------------------------------------------------
    local escaped
    escaped="$(printf '%s' "$selected" | sed 's/[\/&]/\\&/g')"

    # ------------------------------------------------------------
    # Update minimal.jsonc
    # ------------------------------------------------------------
    if grep -qE 'fastfetch/images/[^"]+' "$config"; then
        sed -i -E \
            "s|(fastfetch/images/)[^\"/]+|\1$escaped|" \
            "$config"
    else
        printf "Could not find an image path in %s\n" "$config"
        return 1
    fi

    printf "Fastfetch image updated successfully.\n"
    printf "Image : %s\n" "$selected"
    printf "Config: %s\n" "$config"

    # ------------------------------------------------------------
    # Show Fastfetch immediately
    # ------------------------------------------------------------
    printf "\n"
    command fastfetch --config "$config"
}

# Software search (Arch: interactive install via fzf; others: simple search)
ss() {
    if (( $+commands[pacman] )); then
        local aur="${commands[yay]:-${commands[paru]}}"
        if [[ -n "$aur" ]]; then
            "$aur" -Slq | fzf --multi --preview "$aur -Sii {1}" --preview-window=down:75% | xargs -ro "$aur" -S --noconfirm
        else
            printf "No AUR helper found. Install yay or paru for interactive search.\n"
            return 1
        fi
    else
        # Non-Arch: simple search (requires package name)
        if [[ -z "$1" ]]; then
            printf "Usage: ss <package_name>\n"
            return 1
        fi
        local pkg="${commands[apt]:-${commands[dnf]:-${commands[zypper]}}}"
        if [[ -n "$pkg" ]]; then
            case "${pkg:t}" in
                apt) apt search "$1" ;;
                dnf) dnf search "$1" ;;
                zypper) zypper search "$1" ;;
            esac
        else
            printf "!! Unsupported package manager.\n"
            return 1
        fi
    fi
}

# Launch a GUI application detached from the terminal
runfree() {
    if (( $# == 0 )); then
        printf "Usage: runfree <command> [args...]\n"
        return 1
    fi
    ("$@" &>/dev/null &)
}

# Preview files with fzf and open in editor/viewer
preview() {
    local file
    file="$(fzf --info=inline --query="$*")" || return 0
    [[ -z "$file" ]] && return 0
    if (( $+commands[xdg-open] )); then
        runfree xdg-open "$file"
    else
        ${EDITOR:-nvim} "$file"
    fi
}
