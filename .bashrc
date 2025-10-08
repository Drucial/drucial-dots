# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
alias y="yazi"
alias gg="lazygit"
# alias lsa="lsd -la --group-dirs first"
# alias ls="lsd --tree --depth 1"
alias f="spf"
alias ff="fzf --bind 'enter:execute(nvim {})'"
alias fc="custom_picker"
alias fp="custom_picker ~/Dev --cd"

# Term
alias c='clear'
alias h='history'
alias x='exit'
alias src='source ~/.bashrc'
alias e='nvim'
alias v='vim'

alias bashrc='nvim ~/.bashrc'

alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

export FZF_DEFAULT_OPTS="--style=full --layout=reverse --color=16 --height=100% --margin="1,2" --preview='bat --style=numbers --color=always {} | head -100'"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
