#---------
# Files
#---------

if [ -f ~/.config/zsh/.zsh_functions ]; then
  source $HOME/.config/zsh/.zsh_functions
fi

if [ -f ~/.config/zsh/.secrets ]; then
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

#---------
# Helpers
#
git_branch_name() {
  git rev-parse --abbrev-ref HEAD
}

lst() {
  local depth=2
  if [[ -n $1 ]]; then
    depth=${1#-}
  fi
  eza -a --tree --level=$depth --color=always --icons=always --group-directories-first
}

#----------
# Aliases
#----------

# Apps
alias ask="chatgpt"
# alias cd="z"
alias y="yazi"
alias gg="lazygit"
alias ls="eza -a -1 --color=always --icons=always --group-directories-first"
alias lsa="eza -a -1 -l --color=always --icons=always --group-directories-first"
alias f="spf"
alias ff="fzf --bind 'enter:execute(nvim {})'"
alias configs="custom_picker"
alias fp="custom_picker ~/Dev --cd"
alias ip='ipconfig getifaddr en0 | tee >(pbcopy)'
alias notes='nvim ~/notes'

# Term
alias c='clear'
alias h='history'
alias x='exit'
alias src='source ~/.zshrc'
alias e='nvim'
alias v='vim'
alias nvim-bak='NVIM_APPNAME=nvim.bak nvim'

alias zshrc='nvim ~/.zshrc'

alias ~='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git
alias gg='lazygit'
alias gst='git status'
alias gco='git checkout'
alias gcom='git checkout main'
alias gcob='git checkout -b'
alias gcm='git commit -m'
alias gcam='git commit --all -m'
alias gb='git branch'
alias ga='git add'
alias gaa='git add -A'
alias gpo='git pull'
alias gpsup='git push --set-upstream origin $(git_branch_name)'
alias ghpr='open_github_pr'
alias gdc='git diff main | pbcopy && echo "Diff copied to clipboard."'

# SSH
alias omakase-pi="ssh drucial@omakase-pi"

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
export FZF_DEFAULT_OPTS="
  --style=full
  --layout=reverse
  --color=16
  --height=100%
  --margin='1,2'
  --preview='bat --style=numbers --color=always {} | head -100'
	--color=fg:#908caa,bg:#191724,hl:#ebbcba
	--color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
	--color=border:#403d52,header:#31748f,gutter:#191724
	--color=spinner:#f6c177,info:#9ccfd8
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa
"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --no-ignore --exclude .git --exclude node_modules --exclude build --exclude dist --exclude .next --exclude coverage'
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

eval "$(atuin init zsh)"
