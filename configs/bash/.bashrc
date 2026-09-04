# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# Guarded rather than sourced outright: this file is linked on every machine,
# and OMARCHY_PATH is only set where the bootstrap above found Omarchy.
[[ -r "$OMARCHY_PATH/default/bash/rc" ]] && source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Personal aliases, symlinked from the dotfiles repo by bin/dots.
# Sourced last so it can shadow Omarchy's defaults above.
[[ -r ~/.bash_aliases ]] && source ~/.bash_aliases

# API keys, kept out of git. Lives under configs/zsh/ because zsh claimed it
# first, but it is plain `export` lines and both shells read it -- zen-linear
# reads the LINEAR_API_KEY_* vars, and bash is the only shell on Omarchy.
# Mirrors the zsh copy in configs/zsh/.zshrc.
[[ -r ~/.config/zsh/.secrets ]] && source ~/.config/zsh/.secrets

# Re-derives lazygit's theme from this terminal's colours before handing off.
# Shadows the binary rather than the `gg` alias so both spellings get it; the
# alias resolves to this function. lazygit-theme asks the terminal what its
# background is, which needs a tty, so it has to run from here rather than from
# a theme-change hook. It exits without writing when nothing has changed.
# Mirrors the zsh copy in configs/zsh/.zsh_functions.
lazygit() {
  local theme="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/lazygit-theme"
  [ -x "$theme" ] && "$theme" --quiet
  command lazygit "$@"
}

# Shell history. Guarded because the Archfile installs atuin but a machine
# mid-sync may not have it yet. Mirrors the zsh copy in configs/zsh/.zshrc.
command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"
