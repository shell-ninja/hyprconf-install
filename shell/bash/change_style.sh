#!/bin/bash

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
bash_config="$HOME/.bash/.bashrc"
starship_dir="$HOME/.bash/starship"

styles=()
for file in "$starship_dir"/*.toml; do
    [ -e "$file" ] || continue
    name=$(basename "$file" .toml)
    styles+=("$name")
done

print_box_header() {
    echo -e "\e[1;36m╭────────────────────────────────────────╮\e[0m"
    echo -e "\e[1;36m│ \e[1;37m        Choose a Starship Style        \e[1;36m│\e[0m"
    echo -e "\e[1;36m├────────────────────────────────────────┤\e[0m"
}

print_box_footer() {
    echo -e "\e[1;36m╰────────────────────────────────────────╯\e[0m"
}

print_box_header
for i in "${!styles[@]}"; do
    printf "\e[1;36m│\e[0m \e[1;33m%2d.\e[0m \e[1;32m%-34s\e[0m \e[1;36m│\e[0m\n" "$((i + 1))" "${styles[$i]}"
done
print_box_footer

echo
echo -en "\e[1;35m❯\e[0m \e[1;37mChoose a number (1-${#styles[@]}):\e[0m "
read -r stl

if [[ "$stl" =~ ^[0-9]+$ ]] && (( stl > 0 && stl <= ${#styles[@]} )); then
    selected="${styles[$((stl - 1))]}"
    prompt_file="$starship_dir/${selected}.toml"
    
    echo
    echo -e "  \e[1;34m[*]\e[0m Setting prompt to: \e[1;32m$selected\e[0m"

    # Safely replace the exact line exporting STARSHIP_CONFIG
    sed -i --follow-symlinks "s|^export STARSHIP_CONFIG=.*|export STARSHIP_CONFIG=$prompt_file|g" "$bash_config"

    # Re-enable Starship in case it was disabled by change_prompt.sh
    sed -i --follow-symlinks 's/^# *source "$STARSHIP_CACHE"/source "$STARSHIP_CACHE"/g' "$bash_config"

    echo -e "  \e[1;34m[*]\e[0m Applying changes immediately..."
    sleep 1 && clear
    exec bash
else
    echo
    echo -e "\e[1;31m  [!] Invalid choice. Exiting.\e[0m"
fi
