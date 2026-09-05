# ~/.zsh/alias
source ~/.zsh/functions.zsh

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
alias src='source ~/.zsh/.zshrc'
alias clr='clear'
alias cls='clear'
alias clar='clear'
alias c='clear'
alias q='exit'

## file operations ##
alias rm='fn_removal' # remove file & directory safely
alias cp='fn_copy_paste'

## system info ##
alias du='du -sh'
alias mem='fn_resources __memory'
alias disk='fn_resources __disk'

## fzf search ##
alias find='nvim $(fzf --preview="bat --color=always {}")'

if command -v nvim >/dev/null 2>&1; then
	alias vi='nvim'
	alias vim='nvim'
	alias svi='sudo nvim'
	alias vis='nvim "+set si"'
    alias snv='sudo -E nvim -d'
    alias nvm='nvim .'
elif command -v vim >/dev/null 2>&1; then
	alias vi='vim'
	alias svi='sudo vim'
	alias vis='vim "+set si"'
fi

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
alias style="$HOME/.zsh/change_style.zsh"

## permissions ##
alias exe='chmod +x'

# Alias to launch a document, file, or URL in it's default X application
if command -v xdg-open >/dev/null 2>&1; then
	alias open='runfree xdg-open'
fi

# Alias to launch a document, file, or URL in it's default PDF reader
if command -v evince >/dev/null 2>&1; then
    alias pdf='runfree evince'
fi

# Alias For bat
# Link: https://github.com/sharkdp/bat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style header,snip,changes'
fi

# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi

# Alias for FZF
# Link: https://github.com/junegunn/fzf
if command -v fzf >/dev/null 2>&1; then
    alias fzf='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
fi
