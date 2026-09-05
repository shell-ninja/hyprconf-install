# ~/.zsh/.zshrc

#==============================================================================

# ███████╗██╗  ██╗███████╗██╗         ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗ 
# ██╔════╝██║  ██║██╔════╝██║         ████╗  ██║██║████╗  ██║     ██║██╔══██╗
# ███████╗███████║█████╗  ██║         ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║
# ╚════██║██╔══██║██╔══╝  ██║         ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║
# ███████║██║  ██║███████╗███████╗    ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝
                                                                            
#==============================================================================

# ================================= fastfetch ================================= #
if command -v fastfetch &> /dev/null; then
    if [[ -d "$HOME/.local/share/fastfetch" ]]; then
export ffconfig="tokyo-night"
        command fastfetch --config \
        "$HOME/.local/share/fastfetch/presets/${ffconfig}.jsonc"
    else
        command fastfetch
    fi
fi




############################################
# Download Zinit, if it's not there yet
############################################
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"


############################################
# Add in Starship
############################################
export STARSHIP_CONFIG="/home/shell-ninja/.zsh/starship/starship-macchiato_bubbles.toml"
eval "$(starship init zsh)"


############################################
# Add in zsh plugins
############################################
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light jeffreytse/zsh-vi-mode

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
# zinit snippet OMZP::tmuxinator
# zinit snippet OMZP::docker
zinit snippet OMZP::command-not-found

# Disable the cursor style feature
# ZVM_CURSOR_STYLE_ENABLED=false
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q




#######################################################
# ZSH Basic Options
#######################################################
setopt autocd              # change directory just by typing its name
setopt correct             # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt


#######################################################
# Environment Variables
#######################################################
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export FCEDIT=nvim
export BROWSER=com.brave.Browser

if command -v bat >/dev/null 2>&1; then
	export MANPAGER="sh -c 'col -bx | bat -l man -p'"
	export PAGER=bat
fi

if command -v fzf >/dev/null 2>&1; then
	export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
	  --info=inline-right \
	  --ansi \
	  --layout=reverse \
	  --border=rounded \
	  --color=border:#27a1b9 \
	  --color=fg:#c0caf5 \
	  --color=gutter:#16161e \
	  --color=header:#ff9e64 \
	  --color=hl+:#2ac3de \
	  --color=hl:#2ac3de \
	  --color=info:#545c7e \
	  --color=marker:#ff007c \
	  --color=pointer:#ff007c \
	  --color=prompt:#2ac3de \
	  --color=query:#c0caf5:regular \
	  --color=scrollbar:#27a1b9 \
	  --color=separator:#ff9e64 \
	  --color=spinner:#ff007c \
	"
fi


#######################################################
# ZSH Keybindings
#######################################################
bindkey -v
# bindkey '^p' history-search-backward
# bindkey '^n' history-search-forward
# bindkey '^[w' kill-region
# bindkey ' ' magic-space                           # do history expansion on space
bindkey "^[[A" history-beginning-search-backward  # search history with up key
bindkey "^[[B" history-beginning-search-forward   # search history with down key


#######################################################
# History Configuration
#######################################################
HISTSIZE=10000
HISTFILE=~/.zsh/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


#######################################################
# Completion styling
#######################################################
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes


#######################################################
# ZSH Syntax highlighting
#######################################################
# source ~/.zsh/zsh-syntax-highlighting.zsh
# source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh


#######################################################
# eval functions
#######################################################
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)" # fzf
fi

if command -v thefuck >/dev/null 2>&1; then
    eval "$(thefuck --alias)" # thefu*k
    eval "$(thefuck --alias hell)" # thefu*k "hell"
    eval "$(thefuck --alias damn)" # thefu*k "damn"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi


#######################################################
# source alias and functions
#######################################################
source ~/.zsh/alias.zsh
source ~/.zsh/functions.zsh
