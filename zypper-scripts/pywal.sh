#!/bin/bash

#### Advanced Hyprland Installation Script by ####
#### Shell Ninja ( https://github.com/shell-ninja ) ####

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
purple="\e[1;38;2;189;147;249m"  # Electric neon purple
end="\e[1;0m"

printf " \n \n"

###------ Startup ------###

# install script dir
dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

# log directory
parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

# skip installed cache
cache_dir="$parent_dir/.cache"
installed_cache="$cache_dir/installed_packages"

# log dir
log_dir="$parent_dir/Logs"
log="$log_dir/pywal-$(date +%d-%m-%y).log"

mkdir -p "$log_dir"
touch "$log"

if command -v pipx &> /dev/null; then
  msg att "Pywal will be installed using pipx.."

  pipx install pywal

  if command -v wal &> /dev/null; then
    msg dn "Pywal was installed successfully!"
    echo "[ DONE ] - pywal was installed successfully!" 2>&1 | tee -a "$log" &> /dev/null
    sleep 1 && clear
  else
    msg err "Could not install pywal. Maybe there was an issue."
    echo "[ ERROR ] - Sorry, could not install pywal" 2>&1 | tee -a "$log" &> /dev/null
  fi
fi

sleep 1 && clear
