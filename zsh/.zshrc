#---------
# Files
#---------

if [ -f ~/.config/zsh/.zsh_functions ]; then
  source $HOME/.config/zsh/.zsh_functions
fi

if [ -f ~/.config/zsh/secrets ]; then
  source ~/.config/zsh/.secrets
fi

#---------
# Exports
#---------

export VISUAL="nvim"
export EDITOR="nvim"
export BAT_THEME="base16"
export XDG_CONFIG_HOME="$HOME/.config"

# -----------------------------
# Environment and Path Settings
# -----------------------------

# Function to add a directory to PATH if it's not already included
add_to_path() {
  if [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Add Postgres binaries
add_to_path "/Applications/Postgres.app/Contents/Versions/latest/bin"
add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"



#----------
# Aliases
#----------

# Apps
alias cd="z"
alias y="yazi"
alias gg="lazygit"
alias lsa="lsd -la --group-dirs first"
alias ls="lsd --tree --depth 1"
alias f="spf"
alias ff="fzf --bind 'enter:execute(nvim {})'"
alias fc="custom_picker"
alias fp="custom_picker ~/Dev --cd"

# Term
alias c='clear'
alias h='history'
alias x='exit'
alias src='source ~/.zshrc'
alias e='nvim'
alias v='vim'

alias zshrc='nvim ~/.zshrc'

alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias fs='~/.config/kitty/session-manager/session-picker'
alias fse='~/.config/kitty/session-manager/session-editor'

#--------
# Evals
#--------

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

#----------
# Plugins
# ---------

source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
export FZF_DEFAULT_OPTS="--style=full --layout=reverse --color=16 --height=100% --margin="1,2" --preview='bat --style=numbers --color=always {} | head -100'"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# pnpm
export PNPM_HOME="/Users/drucial/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

FPATH=~/.rbenv/completions:"$FPATH"

autoload -U compinit
compinit

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

bindkey -e

# Added by `rbenv init` on Tue Sep 23 10:28:24 EDT 2025
eval "$(rbenv init - --no-rehash zsh)"
