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
# Function to display the menu
display_menu() {
    clear
    echo -e "\e[1;36m╭────────────────────────────────────────╮\e[0m"
    echo -e "\e[1;36m│\e[0m \e[1;37m        Select a prompt style         \e[0m \e[1;36m│\e[0m"
    echo -e "\e[1;36m╰────────────────────────────────────────╯\e[0m"
    echo -e "  \e[1;35m1)\e[0m Classic Minimal \e[90m(Original 1)\e[0m"
    echo -e "  \e[1;32m2)\e[0m Inline Path     \e[90m(Original 2)\e[0m"
    echo -e "  \e[1;34m3)\e[0m Classic 2-Line  \e[90m(Original 3)\e[0m"
    echo -e "  \e[1;35m4)\e[0m Detailed 2-Line \e[90m(Original 4)\e[0m"
    echo -e "  \e[1;33m5)\e[0m Bracket Layout  \e[90m(Original 5)\e[0m"
    echo -e "  \e[1;36m6)\e[0m Flow            \e[90m(Clean Two-Line)\e[0m"
    echo -e "  \e[1;32m7)\e[0m Aesthetic Neon  \e[90m(Vibrant Vibes)\e[0m"
    echo -e "  \e[1;35m8)\e[0m Crystal Block   \e[90m(Modern Horizon)\e[0m"
    echo -e "  \e[1;31mq)\e[0m Quit"
    echo ""
}

display_menu
read -r -n 1 -p "Choose Your style: " style

# case to choose the PS1 variable
# everything you see "\e[..." are just colors...
case $style in
    1)
        PS1='$(if [[ "$PWD" = "$HOME" ]]; then echo "\e[1;36m\e[1;0m"; elif [[ "$PWD" = "/" ]]; then echo " \e[1;0m"; elif [[ ! "$PWD" == "$HOME" ]]; then echo "\n\w"; fi)\n\e[1;32m❯\e[1;0m '
        ;;
    2)
        PS1='\n$(if [[ "$PWD" = "$HOME" ]]; then echo "\e[1;36m \e[1;0m"; elif [[ "$PWD" = "/" ]]; then echo "\e[1;36m\e[1;0m"; else echo "\w"; fi) \e[1;32m\e[1;0m ' 
        ;;
    3)
        PS1='\n\e[1;36m╭─\e[1;0m $(if [[ "$PWD" = "/" ]]; then echo "\e[1;36m\e[1;0m"; else echo "\e[1;33m\w"; fi)\n\e[1;36m╰──\e[1;32m❯\e[1;0m '
        ;;
    4)
        PS1='\n\e[1;36m╭─ \e[1;37m\u\e[1;34m@\e[1;37m\h\e[1;0m in $(if [[ "$PWD" = "$HOME" ]]; then echo "\e[1;36m󰜥"; elif [[ "$PWD" = "/" ]]; then echo "\e[1;36m\e[1;0m"; else echo "\e[1;33m\w"; fi)\n\e[1;36m╰──\e[1;32m󰘧\e[1;0m '
        ;;
    5)
        PS1='\n╭( \u )─[$(if [[ "$PWD" = "$HOME" ]]; then echo " \e[1;36m \e[1;0m"; elif [[ "$PWD" = "/" ]]; then echo " \e[1;32m \e[1;0m"; else echo "\e[1;33m \w\e[1;0m"; fi) ]─( $(current_time) )\n╰─\e[1;32m❯\e[1;0m '
        ;;
    6)
        # Flow: Two-line subtle
        PS1='\n\[\e[38;5;238m\]╭ \[\e[1;34m\]$(if [[ "$PWD" == "$HOME" ]]; then echo -n ""; elif [[ "$PWD" == "/" ]]; then echo -n ""; else echo -n ""; fi)  \w\[\e[0m\]\n\[\e[38;5;238m\]╰ \[\e[1;32m\]❯\[\e[0m\] '
        ;;
    7)
        # Sleek vibrant neon vibes
        PS1='\n\[\e[1;35m\]$(if [[ "$PWD" == "$HOME" ]]; then echo -n ""; elif [[ "$PWD" == "/" ]]; then echo -n ""; else echo -n "󰉋"; fi)\[\e[0m\] \[\e[1;36m\]\w\[\e[0m\] \[\e[1;32m\]\[\e[0m\] '
        ;;
    8)
        # Horizon Block / Modern Crystal layout
        PS1='\n\[\e[38;5;238m\][ \[\e[1;36m\]$(if [[ "$PWD" == "$HOME" ]]; then echo -n ""; elif [[ "$PWD" == "/" ]]; then echo -n ""; else echo -n "󰉋"; fi) \[\e[38;5;253m\]\w \[\e[38;5;238m\]] \[\e[1;33m\]➜\[\e[0m\] '
        ;;
    q)
        echo "Quitting..."
        exit 0
        ;;
    *)
        echo "Invalid option. Please try again."
        exit 1
        ;;
esac

# Escape backslashes, forward slashes, and newlines in PS1 for sed
escaped_PS1=$(printf '%s\n' "$PS1" | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e ':a;N;$!ba;s/\n/\\n/g')

# bash file
bashrc=~/.bash/.bashrc

# Update the PS1 line in the specified file whether it's commented or not
sed -i --follow-symlinks -E "s/^[# ]*PS1=.*/PS1='$escaped_PS1'/g" "$bashrc"

# Disable Starship so the native PS1 applies correctly
sed -i --follow-symlinks 's/^source "$STARSHIP_CACHE"/# source "$STARSHIP_CACHE"/g' "$bashrc"

printf "\n  \e[1;34m[*]\e[0m Setting prompt to style: \e[1;32m$style\e[0m\n"
printf "  \e[1;34m[*]\e[0m Applying changes immediately...\n"
sleep 0.5
exec bash

