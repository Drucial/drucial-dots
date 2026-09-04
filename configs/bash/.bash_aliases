# Aliases file — sourced from .bashrc.
# Ported from configs/zsh/.aliases; see that file for the zsh-side originals.
# Anything needing a shell helper function (ghpr) was left behind, as were
# the macOS-only and picker-driven entries.
#
# Several of these deliberately shadow Omarchy's defaults in
# $OMARCHY_PATH/default/bash/aliases, which is sourced earlier by ~/.bashrc:
#   ls, lsa, ff  → Omarchy's eza/fzf variants
#   c            → Omarchy's `opencode --auto`
#   h            → Omarchy's `herdr`

#------
# Appsy
#------

alias ls="eza -a -1 --color=always --icons=always --group-directories-first"                 # Eza: List files (one-per-line, icons)
alias lsa="eza -a -1 -l --color=always --icons=always --group-directories-first"             # Eza: List files (detailed, long format)
alias ff="fzf --bind 'enter:execute(nvim {})'"                                               # Fzf: Pick a file and open it in nvim
alias fs='fzf --ansi --disabled --delimiter : --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case {q}" --bind "change:reload:sleep 0.1; rg --column --line-number --no-heading --color=always --smart-case {q} || true" --preview "bat --style=numbers --color=always --highlight-line {2} {1}" --bind "enter:become(nvim +{2} {1})"'  # Fzf: Live ripgrep search; enter opens file at line in nvim
alias ip='ip -4 -o addr show scope global | awk "{print \$4}" | cut -d/ -f1 | head -1 | tee >(wl-copy)'  # Network: Print and copy local IP
alias notes='zen-notes'                                                                      # Neovim: Open notes directory
alias lzd='lazydocker'                                                                       # Lazydocker: Launch TUI

#------
# Term
#------

alias c='clear'                                                                              # Shell: Clear terminal
alias h='history'                                                                            # Shell: Show command history
alias x='exit'                                                                               # Shell: Exit shell
alias src='source ~/.bashrc'                                                                 # Bash: Reload .bashrc
alias e='nvim'                                                                               # Neovim: Launch (arg: optional file/dir)
alias nvim-bak='NVIM_APPNAME=nvim.bak nvim'                                                  # Neovim: Launch backup config (NVIM_APPNAME=nvim.bak)
alias y="yazi"

alias ~='cd ~'                                                                               # Shell: Go to home directory
alias ..='cd ..'                                                                             # Shell: Up one directory
alias ...='cd ../..'                                                                         # Shell: Up two directories
alias ....='cd ../../..'                                                                     # Shell: Up three directories
alias .....='cd ../../../..'                                                                 # Shell: Up four directories

#-----
# Git
#-----

alias gg='lazygit'                                                                           # Lazygit: Launch TUI
alias gd="gh dash"                                                                           # GitHub: Open gh dash TUI
alias gst='git status'                                                                       # Git: Show working tree status
alias gco='git checkout'                                                                     # Git: Checkout (arg: branch or file)
alias gcom='git checkout main'                                                               # Git: Checkout main
alias gcob='git checkout -b'                                                                 # Git: Create and checkout new branch (arg: branch name)
alias gcm='git commit -m'                                                                    # Git: Commit with message (arg: "message")
alias gcam='git commit --all -m'                                                             # Git: Commit all tracked changes with message (arg: "message")
alias gb='git branch'                                                                        # Git: List or manage branches
alias ga='git add'                                                                           # Git: Stage file(s) (arg: path)
alias gaa='git add -A'                                                                       # Git: Stage all changes
alias gpo='git pull'                                                                         # Git: Pull from remote
alias gpsup='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'                # Git: Push and set upstream to origin/<current-branch>
alias gdc='git diff main | wl-copy && echo "Diff copied to clipboard."'                      # Git: Copy diff vs main to clipboard

#-----
# SSH
#-----

alias omakase-pi="ssh drucial@omakase-pi"                                                    # SSH: Connect to omakase-pi

#-----------
# Worktrunk
#-----------

alias wn='wt switch --create'                                                                # Worktrunk: New branch off default + worktree (arg: branch name)
alias wfix='wt switch --create --base ^'                                                     # Worktrunk: New hotfix branch off main (arg: branch name)
alias ws='wt switch --branches'                                                              # Worktrunk: Switch worktree (arg: name; no arg = picker)
alias wp='wt switch'                                                                         # Worktrunk: Jump to a PR worktree (arg: pr:<number>)
alias wb='wt switch -'                                                                       # Worktrunk: Back to previous worktree
alias wm='wt switch ^'                                                                       # Worktrunk: Jump to default branch worktree
alias wl='wt list'                                                                           # Worktrunk: List all worktrees
alias wrm='wt remove'                                                                        # Worktrunk: Remove current worktree (deletes branch if merged)
