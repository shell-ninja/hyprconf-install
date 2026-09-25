#!/usr/bin/env bash

green="\e[1;38;2;166;227;161m"     # Soft emerald
yellow="\e[1;38;2;224;175;104m"    # Warm gold
magenta="\e[1;38;2;232;121;249m"   # Vibrant violet-magenta
cyan="\e[1;38;2;125;207;255m"      # Neon glacier cyan
lavender="\e[1;38;2;203;166;247m" # Soft lavender (secondary accent)

printf "Congratulations! The script completes here.\n" && sleep 1
printf "Need to reboot the system.\n"

printf "Would you like to reboot now? [ y/n ]\n"
read -p "Select: " reboot


if [[ "$reboot" == "y" ]]; then
    # Hide cursor for smooth animation
    tput civis 2>/dev/null || printf "\e[?25l"
    clear

    bold="\e[1m"
    dim="\e[2m"
    white="\e[1;37m"

    anim_frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    anim_colors="$lavender"

    total_steps=30
    bar_len=28

    for (( step=0; step<=total_steps; step++ )); do
        remaining_sec=$(( (total_steps - step + 9) / 10 ))
        pct=$(( step * 100 / total_steps ))
        fill_len=$(( step * bar_len / total_steps ))
        unfill_len=$(( bar_len - fill_len ))

        spinner_char="${anim_frames[step % ${#anim_frames[@]}]}"
        theme_color="${anim_colors[(step / 6) % ${#anim_colors[@]}]}"

        fill_str=""
        for (( i=0; i<fill_len; i++ )); do fill_str="${fill_str}█"; done
        unfill_str=""
        for (( i=0; i<unfill_len; i++ )); do unfill_str="${unfill_str}░"; done

        printf "\e[H\n"
        printf "  ${theme_color}✦${end} ${bold}SYSTEM REBOOT INITIATED${end}\n\n"
        printf "  ${theme_color}${spinner_char}${end} ${bold}Rebooting in ${theme_color}${remaining_sec}s${end}  ${theme_color}[${fill_str}${dim}${unfill_str}${end}${theme_color}]${end} ${bold}%3d%%${end}\n\n" "$pct"
        printf "  ${dim}Happy to use your new rice! 🚀${end}\n"
        sleep 0.1
    done

    # Restore cursor
    tput cnorm 2>/dev/null || printf "\e[?25h"
    clear
    # systemctl reboot --now 2>/dev/null || sudo reboot
else
    printf "Ok, but make sure to reboot the system.\n" && sleep 1
    printf "Happy to use your new rice!\n"
    exit 0
fi
