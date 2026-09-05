# ~/.bash/alias.sh
source ~/.bash/functions.sh

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

## list ##
alias ls='eza -T --level=1 --color=always --icons=always --group-directories-first'
alias la='eza -a --icons=always --group-directories-first'
alias ll='eza -l -a --icons=always --no-time --group-directories-first'
alias lst='eza -T --level=2 --color=always --icons=always --group-directories-first'
alias lsf='eza -f -a --color=always --icons=always --group-directories-first'
alias lstd='eza -D -T --level=2 --color=always --icons=always --group-directories-first'
alias tree='eza -T --level=3 --color=always --icons=always --group-directories-first'

alias cat='bat --style header --style snip --style changes --style header'

## grub update ##
alias grubup="sudo update-grub" # Arch, Ubuntu
alias susegrub="sudo grub2-mkconfig -o /boot/grub2/grub.cfg" # openSUSE
alias fedbup="sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg" # Fedora

## navigation ##
alias ..='cd ..'
alias ...='cd ../..'
alias .='cd /'

## system & terminal ##
alias src='source ~/.bash/.bashrc'
alias clr='clear'
alias cls='clear'
alias clar='clear'
alias c='clear'
alias q='exit'
alias nrd='npm run dev'

## file operations ##
alias rm='fn_removal' # remove file & directory safely
alias cp='fn_copy_paste'

## system info ##
alias du='du -sh'
alias mem='fn_resources __memory'
alias disk='fn_resources __disk'

## fzf search ##
alias find='nvim $(fzf --preview="bat --color=always {}")'

## editors & IDEs ##
alias nvm='nvim .'
alias open='nvim .'
alias snv='sudo -E nvim -d'

## package management ##
alias cu='fn_check_updates'
alias dup='sudo zypper dup -y' # openSUSE
alias update='fn_update'
alias in='fn_install'
alias un='fn_uninstall'

## git ##
alias add='git add .'
alias clone='git clone'
alias cloned='git clone --depth=1'
alias branch='git branch -M main'
alias commit='git commit -m'
alias pushm='git push -u origin main'
alias pusho='git push origin'
alias pull='git pull'
alias info='git_info'

## misc ##
alias nc='clr && neofetch'
alias neofetch='clr && neofetch'
alias ff='clr && fastfetch'
alias sys='btop'
alias clock='tty-clock -c -t -D -s'
alias mat='cmatrix'
alias sddt='sddm-greeter-qt6 --test-mode --theme'

## customizations ##
alias prompt="~/.bash/change_prompt.sh"
alias style="~/.bash/change_style.sh"

## permissions ##
alias exe='chmod +x'
