# drucial-dots

My personal dotfiles. Each top-level directory is a config that gets symlinked into `~/.config` (or `$XDG_CONFIG_HOME`).

## What's in here

| Config         | App           |
| -------------- | ------------- |
| `atuin/`       | shell history |
| `btop/`        | system monitor |
| `claude/`      | Claude Code config |
| `diffnav/`     | git diff TUI |
| `eza/`         | `ls` replacement theme |
| `gh-dash/`     | GitHub TUI |
| `git/`         | git config + ignore |
| `kitty/`       | terminal |
| `lazygit/`     | git TUI |
| `nvim/`        | editor (LazyVim) |
| `posting/`     | API client |
| `yabai/`       | window manager |
| `yazi/`        | file manager |
| `zsh/`         | shell |
| `starship.toml`| prompt |

Plus `wallpapers/` and `bin/link` (the symlink helper below).

## Bootstrap

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
cd ~/Dev/drucial-dots
bin/link nvim zsh kitty git   # link whatever you need
```

### `bin/link`

Symlinks a config from this repo into `~/.config`.

```sh
bin/link <name> [<name>...]   # link one or more
bin/link -f nvim              # force-replace existing
bin/link -n nvim              # dry-run
bin/link -v zsh kitty         # verbose
```

The script resolves the repo root from its own location, so it works whether you clone to `~/Dev`, `~/dotfiles`, or anywhere else.

## Convention

Configs live in this repo and are symlinked out — never copied. To make a change, edit the file under its real path (e.g. `nvim/lua/...`) and commit. The symlink in `~/.config/nvim` picks it up automatically.
