# ~/.bash/functions.sh

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
    local destination="${!#}"
    # Remove a trailing slash to normalise the path (we will later add it back for directory mode)
    destination="${destination%/}"
    local items=("${@:1:$(($#-1))}")

    # ---- Determine mode: directory vs. single file copy ----
    local mode="dir"
    if [[ ${#items[@]} -eq 1 && ! -d "$destination" ]]; then
        # Only one source and the destination does NOT exist as a directory -> rename
        mode="file"
    fi
    # If destination ended with a trailing slash in the original call, force directory mode
    if [[ "${!#}" == */ ]]; then
        mode="dir"
    fi

    # ---- Decide whether sudo is required (only when necessary) ----
    local SUDO=""
    if [[ $EUID -ne 0 ]]; then
        # Check destination / parent writability
        if [[ "$mode" == "dir" ]]; then
            if [[ -d "$destination" ]]; then
                # Existing directory: must be writable and traversable
                [[ -w "$destination" && -x "$destination" ]] || SUDO="sudo"
            else
                # Directory does not exist – check parent directory
                local parent; parent=$(dirname "$destination")
                [[ -w "$parent" && -x "$parent" ]] || SUDO="sudo"
            fi
        else
            # File mode: check the directory that will contain the destination file
            local dest_dir; dest_dir=$(dirname "$destination")
            if [[ -e "$destination" ]]; then
                # Existing file: need write permission on it (can be overwritten)
                [[ -w "$destination" ]] || SUDO="sudo"
            else
                # File doesn't exist: need write+execute on parent
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

    # ---- Create destination if it does not exist (directory mode only) ----
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
        # File mode: ensure the parent directory exists
        local dest_dir; dest_dir=$(dirname "$destination")
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
        local name="${item##*/}"

        if [[ -f "$item" ]]; then
            # ---- File ----
            if [[ "$mode" == "file" ]]; then
                # Single file rename: copy directly to destination path
                printf "\n:: Copying file %s → %s\n" "$name" "$destination"
                if [[ "$name" == *.iso ]]; then
                    pv "$item" | $SUDO dd of="$destination" bs=4M status=none
                else
                    if [[ -n $SUDO ]]; then
                        pv "$item" | sudo tee "$destination" > /dev/null
                    else
                        pv "$item" > "$destination"
                    fi
                fi
            else
                # Directory mode: copy file into the destination directory
                printf "\n:: Copying file %s → %s\n" "$name" "$destination"
                if [[ "$name" == *.iso ]]; then
                    pv "$item" | $SUDO dd of="$destination/$name" bs=4M status=none
                else
                    if [[ -n $SUDO ]]; then
                        pv "$item" | sudo tee "$destination/$name" > /dev/null
                    else
                        pv "$item" > "$destination/$name"
                    fi
                fi
            fi

            # Sync after ISO copy (only if dd succeeded)
            if [[ "$name" == *.iso && $? -eq 0 ]]; then
                printf "\n:: Syncing to disk (this may take a while)...\n"
                $SUDO sync &
                local sync_pid=$!
                local spinstr='|/-\'
                while kill -0 $sync_pid 2>/dev/null; do
                    for ((i=0; i<${#spinstr}; i++)); do
                        printf "\r[%c] Syncing... " "${spinstr:$i:1}"
                        sleep 0.1
                    done
                done
                wait $sync_pid
                printf "\r\e[KSync complete.\n"
            fi

        elif [[ -d "$item" ]]; then
            # ---- Directory ----
            if [[ "$mode" == "file" ]]; then
                # Rename a single directory: copy contents into the new directory
                printf "\n:: Copying directory %s → %s (renamed)\n" "$name" "$destination"
                # Ensure the new directory exists (already created above, but double-check)
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

                # Copy the *contents* of the source into the new directory
                if [[ -n $SUDO ]]; then
                    $SUDO tar -C "$item" -cf - . |
                        pv -N "$name" |
                        $SUDO tar -xf - -C "$destination"
                else
                    tar -C "$item" -cf - . |
                        pv -N "$name" |
                        tar -xf - -C "$destination"
                fi
            else
                # Normal mode: copy the directory into an existing destination
                printf "\n:: Copying directory %s → %s\n" "$name" "$destination"
                local parent; parent="$(dirname "$item")"

                if [[ -n $SUDO ]]; then
                    sudo tar -C "$parent" -cf - "$name" |
                        pv -N "$name" |
                        sudo tar -xf - -C "$destination"
                else
                    tar -C "$parent" -cf - "$name" |
                        pv -N "$name" |
                        tar -xf - -C "$destination"
                fi
            fi
        else
            printf "!! Skipping unknown type: %s\n" "$item"
        fi
    done
}

# remove files and directories (safer, verbose, smart sudo)
fn_removal() {
    if [[ $# -eq 0 ]]; then
        printf "Usage: fn_removal <file|dir> ...\n"
        return 1
    fi

    # ---- decide if sudo is needed (check parent writability) ----
    local SUDO=""
    if [[ $EUID -ne 0 ]]; then
        for item in "$@"; do
            local parent
            parent=$(dirname "$item")
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

    for item in "$@"; do
        if [[ -f "$item" ]]; then
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

# internal: detect package manager (cached)
_detect_pkg_manager() {
    [[ -n "$PKG_MANAGER" ]] && return
    if command -v pacman &>/dev/null; then
        export PKG_MANAGER="pacman"
        local aur
        aur=$(command -v yay 2>/dev/null || command -v paru 2>/dev/null)
        export AUR_HELPER="${aur:-}"
    elif command -v dnf &>/dev/null; then
        export PKG_MANAGER="dnf"
    elif command -v zypper &>/dev/null; then
        export PKG_MANAGER="zypper"
    elif command -v apt-get &>/dev/null; then
        export PKG_MANAGER="apt"
    else
        export PKG_MANAGER="unknown"
    fi
}

# check updates (improved fallback for Arch)
fn_check_updates() {
    _detect_pkg_manager
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        local ofc aur=0
        if command -v checkupdates &>/dev/null; then
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
        printf "\e[1;31m Unsupported package manager for now, please let us know in the github repository...\e[1;0m \n https://github.com/me-js-bro/Bash\n"
        return 1
    fi
}

# package updates (fixed apt command)
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
        printf "\e[1;31m Unsupported package manager for now, please let us know in the github repository...\e[1;0m \n https://github.com/me-js-bro/Bash\n"
        return 1
    fi
}

# Install software (non‑interactive, requires arguments)
fn_install() {
    if [[ $# -eq 0 ]]; then
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
        printf "\e[1;31m Unsupported package manager for now, please let us know in the GitHub repository...\e[1;0m \n https://github.com/me-js-bro/Bash\n"
        return 1
    fi
}

# package uninstall (non‑interactive, requires arguments)
fn_uninstall() {
    if [[ $# -eq 0 ]]; then
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
        printf "\e[1;31m Unsupported package manager for now, please let us know in the github repository...\e[1;0m \n https://github.com/me-js-bro/Bash\n"
        return 1
    fi
}

# compile cpp file with g++ (with sanity checks)
fn_compile_cpp() {
    if ! command -v g++ &>/dev/null; then
        printf "\e[1;91m[  ] - g++ not found. Please install g++ first.\e[0m\n"
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

        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local x="${line:0:1}" y="${line:1:1}"
            if [[ "$x" == "?" && "$y" == "?" ]]; then
                ((untracked_count++))
            else
                [[ "$x" != " " && "$x" != "?" ]] && ((staged_count++))
                [[ "$y" != " " && "$y" != "?" ]] && ((unstaged_count++))
            fi
        done < <(git status --porcelain 2>/dev/null)

        printf "on \e[1;34m\e[1;32m %s\e[1;0m " "$branch_name"

        [[ "$untracked_count" -gt 0 ]] && printf "\e[1;31m?%d \e[3;0m" "$untracked_count"
        [[ "$staged_count" -gt 0 ]] && printf "\e[1;32m%d \e[3;0m" "$staged_count"
        [[ "$unstaged_count" -gt 0 ]] && printf "\e[1;33m!%d \e[3;0m" "$unstaged_count"

        if [[ "$untracked_count" -eq 0 && "$staged_count" -eq 0 && "$unstaged_count" -eq 0 ]]; then
            printf "\e[1;32m✓ \e[3;0m"
        fi
        printf "\n"
    fi
}

# fn to push git commits easily (fixed push logic, audio fallback)
push() {
    local branch_name
    branch_name=$(git branch --show-current 2>/dev/null) || {
        printf "!! Not inside a Git repository.\n"
        return 1
    }

    local untracked_count=0 unstaged_count=0 staged_count=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local x="${line:0:1}" y="${line:1:1}"
        if [[ "$x" == "?" && "$y" == "?" ]]; then ((untracked_count++))
        else
            [[ "$x" != " " && "$x" != "?" ]] && ((staged_count++))
            [[ "$y" != " " && "$y" != "?" ]] && ((unstaged_count++))
        fi
    done < <(git status --porcelain 2>/dev/null)

    if [[ "$untracked_count" -gt 0 ]]; then printf "=> %s untracked files\n" "$untracked_count"; fi
    if [[ "$unstaged_count" -gt 0 ]]; then printf "=> %s uncommitted changes\n" "$unstaged_count"; fi
    if [[ "$staged_count" -gt 0 ]]; then printf "=> %s staged changes\n" "$staged_count"; fi

    if [[ "$untracked_count" -eq 0 && "$unstaged_count" -eq 0 && "$staged_count" -eq 0 ]]; then
        printf "✓ Nothing to push.\n"
        return 0
    fi

    printf "=> %s branch\n\nWrite the commit message\n" "$branch_name"

    local msg
    if command -v gum &>/dev/null; then
        msg="$(gum input --placeholder "Write your commit message")"
    else
        read -r -p "=> " msg
    fi

    [[ -z "$msg" ]] && { printf "!! Aborting due to empty commit message.\n"; return 1; }

    git add .
    if ! git commit -m "$msg"; then
        printf "!! Commit failed.\n"
        return 1
    fi

    # Always push to origin with the current branch name
    git push origin "$branch_name"
    local status=$?

    if [[ $status -eq 0 ]]; then
        # Play success sound if audio file exists
        local sound="$HOME/.local/share/bash/fah.mp3"   # adjust path if needed
        if [[ -f "$sound" ]]; then
            if   command -v pw-play  &>/dev/null; then pw-play  "$sound" &>/dev/null &
            elif command -v paplay   &>/dev/null; then paplay   "$sound" &>/dev/null &
            elif command -v aplay    &>/dev/null; then aplay    "$sound" &>/dev/null &
            elif command -v ffplay   &>/dev/null; then ffplay -nodisp -autoexit "$sound" &>/dev/null &
            fi
        fi
        printf ":: Pushed successfully!\n"
    else
        printf "!! Sorry, push failed. Please check for errors.\n"
    fi
}

# fn for yazi (file manager cd on exit)
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ---- Bash-native command timing (replaces broken PS0/preexec) ----
_command_start_time=$EPOCHSECONDS

# Run before every command (DEBUG trap is the only reliable way in bash)
trap '_command_start_time=$EPOCHSECONDS' DEBUG

# Run after each command (PROMPT_COMMAND)
_precmd() {
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

# Backward compatibility for old precmd calls
precmd() { _precmd; }

# Append to existing PROMPT_COMMAND to not break anything else
PROMPT_COMMAND="_precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Function to show current time (for prompt)
current_time() {
    printf "\e[90m %s\e[0m" "$(date +'%I:%M %p')"
}
# ----------------------------------------------------------------

# Fastfetch wrapper that uses ffconfig when invoked with no arguments
fastfetch() {
    if [[ $# -eq 0 && -n "${ffconfig:-}" && -d "$HOME/.local/share/fastfetch" ]]; then
        command fastfetch --config "$ffconfig"
    else
        command fastfetch "$@"
    fi
}

# Interactive fastfetch style switcher
ffstyle() {
    local presetDir="$HOME/.local/share/fastfetch/presets"
    local bash_config="$HOME/.bash/.bashrc"

    # Check preset directory
    if [[ ! -d "$presetDir" ]]; then
        printf "Preset directory not found: %s\n" "$presetDir"
        return 1
    fi

    # Check bashrc
    if [[ ! -f "$bash_config" ]]; then
        printf "Bash config not found: %s\n" "$bash_config"
        return 1
    fi

    # Find presets
    local -a presets=()
    local preset

    for preset in "$presetDir"/*.jsonc; do
        [[ -f "$preset" ]] || continue
        presets+=("${preset##*/}")
    done

    # Remove .jsonc extension
    presets=("${presets[@]%.jsonc}")

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
    read -r -p "Select: " choice

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#presets[@]} )); then
        printf "Invalid selection.\n"
        return 1
    fi

    local selected="${presets[$((choice - 1))]}"

    printf "\nSetting Fastfetch style to: %s\n" "$selected"

    # Make a backup before modifying .bashrc
    cp -- "$bash_config" "$bash_config.bak"

    # Replace ANY existing ffconfig definition
    if grep -Eq '^[[:space:]]*export[[:space:]]+ffconfig[[:space:]]*=' "$bash_config"; then
        sed -i -E \
            "s|^[[:space:]]*export[[:space:]]+ffconfig[[:space:]]*=.*$|export ffconfig=\"$selected\"|" \
            "$bash_config"
    else
        printf '\nexport ffconfig="%s"\n' "$selected" >> "$bash_config"
    fi

    # Update current shell
    export ffconfig="$selected"

    printf "Updated: %s\n" "$bash_config"
    printf "ffconfig=%s\n\n" "$ffconfig"

    # Show the actual line written to .bashrc
    printf -- "--- .bashrc ---\n"
    grep -n 'ffconfig' "$bash_config"
    printf -- "----------------\n\n"

    # Run selected preset immediately
    command fastfetch --config "$presetDir/${selected}.jsonc"
}

ffimg() {
    local preferredDir="$HOME/.local/share/fastfetch/images"
    local bash_config="$HOME/.bash/.bashrc"
    local config="$HOME/.local/share/fastfetch/presets/minimal.jsonc"

    # ------------------------------------------------------------
    # Check required paths
    # ------------------------------------------------------------
    if [[ ! -d "$preferredDir" ]]; then
        printf "Image directory not found: %s\n" "$preferredDir"
        return 1
    fi

    if [[ ! -f "$bash_config" ]]; then
        printf "Bash config not found: %s\n" "$bash_config"
        return 1
    fi

    if [[ ! -f "$config" ]]; then
        printf "Config file not found: %s\n" "$config"
        return 1
    fi

    # ------------------------------------------------------------
    # Read ffconfig from .bashrc
    # ------------------------------------------------------------
    local current_style

    current_style="$(
        sed -nE \
            's/^[[:space:]]*export[[:space:]]+ffconfig[[:space:]]*=[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' \
            "$bash_config" |
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
    if ! command -v fzf &>/dev/null; then
        printf "fzf is required for image preview.\n"
        printf "Install it with: sudo pacman -S fzf\n"
        return 1
    fi

    if ! command -v chafa &>/dev/null; then
        printf "chafa is required for image preview.\n"
        printf "Install it with: sudo pacman -S chafa\n"
        return 1
    fi

    # ------------------------------------------------------------
    # Find images
    # ------------------------------------------------------------
    local -a images=()
    local img

    for img in "$preferredDir"/*; do
        [[ -f "$img" ]] || continue
        images+=("${img##*/}")
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
    if command -v pacman &>/dev/null; then
        local aur
        aur=$(command -v yay 2>/dev/null || command -v paru 2>/dev/null)
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
        local pkg
        pkg=$(command -v apt 2>/dev/null || command -v dnf 2>/dev/null || command -v zypper 2>/dev/null)
        if [[ -n "$pkg" ]]; then
            case "$pkg" in
                *apt) apt search "$1" ;;
                *dnf) dnf search "$1" ;;
                *zypper) zypper search "$1" ;;
            esac
        else
            printf "!! Unsupported package manager.\n"
            return 1
        fi
    fi
}

# Play success sound (with robust player detection)
play() {
    local sound
    sound="$(dirname "${BASH_SOURCE[0]}")/fah.mp3"
    if [[ -f "$sound" ]]; then
        if   command -v pw-play  &>/dev/null; then pw-play  "$sound"
        elif command -v paplay   &>/dev/null; then paplay   "$sound"
        elif command -v aplay    &>/dev/null; then aplay    "$sound"
        elif command -v ffplay   &>/dev/null; then ffplay -nodisp -autoexit "$sound"
        else printf "No audio player found to play %s\n" "$sound"
        fi
    else
        printf "Sound file not found: %s\n" "$sound" >&2
    fi
}

# Create a Vite React project (fixed: no more shell exit, gum fallback)
vite() {
    # ---- gum fallback ----
    local get_input
    if command -v gum &>/dev/null; then
        get_input() { gum input --placeholder "$1"; }
    else
        get_input() { local x; read -r -p "$1: " x; printf "%s" "$x"; }
    fi

    printf "Project name: \n"
    local PROJ_NAME
    PROJ_NAME=$(get_input "my-app")
    [[ -z "$PROJ_NAME" ]] && { printf "❌ Missing project name\n"; return 1; }

    # Detect package manager
    local PKG_MANAGER=""
    for pm in npm pnpm yarn bun; do
        if command -v "$pm" &>/dev/null; then
            PKG_MANAGER="$pm"
            break
        fi
    done
    [[ -z "$PKG_MANAGER" ]] && { printf "❌ No package manager found\n"; return 1; }
    printf "🚀 Using %s\n" "$PKG_MANAGER"

    # Create project (non-interactive)
    case $PKG_MANAGER in
        npm)  npm  create vite@latest "$PROJ_NAME" -y -- --template react --no-interactive ;;
        pnpm) pnpm create vite "$PROJ_NAME" --template react --no-interactive ;;
        yarn) yarn create vite "$PROJ_NAME" --template react --no-interactive ;;
        bun)  bun  create vite "$PROJ_NAME" --template react --no-interactive ;;
    esac || { printf "❌ Project creation failed\n"; return 1; }

    cd "$PROJ_NAME" || return 1
    printf "📦 Installing dependencies...\n"
    $PKG_MANAGER install || { printf "❌ Install failed\n"; return 1; }

    # Setup VS Code auto‑run task
    mkdir -p .vscode
    cat > .vscode/tasks.json << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "dev",
      "type": "shell",
      "command": "npm run dev",
      "isBackground": true,
      "runOptions": {
        "runOn": "folderOpen"
      },
      "problemMatcher": []
    }
  ]
}
EOF

    printf "🧠 Opening in VS Code...\n"
    command -v code &>/dev/null && code .

    printf "🌐 Dev server will auto-start inside VS Code terminal\n"
    printf "✅ Done!\n"
}

