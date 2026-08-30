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
