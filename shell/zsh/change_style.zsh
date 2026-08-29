#!/bin/zsh

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

# change starship style.
zsh_config="$HOME/.zsh/.zshrc"
starship_dir="$HOME/.zsh/starship"

styles=()
for file in "$starship_dir"/*.toml; do
    [ -e "$file" ] || continue
    name=$(basename "$file" .toml)
    styles+=("$name")
done

print_box_header() {
    printf "\e[1;36m╭────────────────────────────────────────╮\e[0m\n"
    printf "\e[1;36m│ \e[1;37m        Choose a Starship Style        \e[1;36m│\e[0m\n"
    printf "\e[1;36m├────────────────────────────────────────┤\e[0m\n"
}

print_box_footer() {
    printf "\e[1;36m╰────────────────────────────────────────╯\e[0m\n"
}

print_box_header
# Iterate using standard Zsh 1-based indexing
for (( i=1; i<=${#styles[@]}; i++ )); do
    printf "\e[1;36m│\e[0m \e[1;33m%2d.\e[0m \e[1;32m%-34s\e[0m \e[1;36m│\e[0m\n" "$i" "${styles[$i]}"
done
print_box_footer

echo
printf "\e[1;35m❯\e[0m \e[1;37mChoose a number (1-${#styles[@]}):\e[0m "
read -r stl

if [[ "$stl" =~ ^[0-9]+$ ]] && (( stl > 0 && stl <= ${#styles[@]} )); then
    # Grab the selected style directly using the 1-based input
    selected="${styles[$stl]}"
    prompt_file="$starship_dir/${selected}.toml"
    
    echo
    printf "  \e[1;34m[*]\e[0m Setting prompt to: \e[1;32m%s\e[0m\n" "$selected"

    # Safely replace the exact line exporting STARSHIP_CONFIG
    sed -i "s|^export STARSHIP_CONFIG=.*|export STARSHIP_CONFIG=\"$prompt_file\"|g" "$zsh_config"

    # Ensure Starship is enabled
    sed -i 's|^# *eval "$(starship init zsh)"|eval "$(starship init zsh)"|g' "$zsh_config"

    printf "  \e[1;34m[*]\e[0m Applying changes immediately...\n"
    sleep 1 && clear
    exec zsh
else
    echo
    printf "\e[1;31m  [!] Invalid choice. Exiting.\e[0m\n"
fi
