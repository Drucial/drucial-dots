# drucial-dots

My personal dotfiles. App configs live under `configs/` and get symlinked into `~/.config` (or `$XDG_CONFIG_HOME`).

## Layout

```
configs/   app configs, symlinked into ~/.config via bin/link
claude/    Claude Code config, symlinked into ~/.claude via claude/install
bin/link   the symlink helper
```

### `configs/`

| Config          | App           |
| --------------- | ------------- |
| `atuin/`        | shell history |
| `btop/`         | system monitor |
| `diffnav/`      | git diff TUI |
| `eza/`          | `ls` replacement theme |
| `gh-dash/`      | GitHub TUI |
| `git/`          | git config + ignore |
| `kitty/`        | terminal |
| `lazygit/`      | git TUI |
| `neovide/`      | Neovim GUI |
| `nvim/`         | editor (LazyVim) |
| `posting/`      | API client |
| `rainfrog/`     | database TUI |
| `yabai/`        | window manager |
| `yazi/`         | file manager |
| `zsh/`          | shell |
| `starship.toml` | prompt |

## Bootstrap

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
cd ~/Dev/drucial-dots
bin/link nvim zsh kitty git   # link whatever you need
./claude/install              # Claude Code config -> ~/.claude
```

### `bin/link`

Symlinks a config from `configs/` into `~/.config`.

```sh
bin/link <name> [<name>...]   # link one or more
bin/link -f nvim              # force-replace existing
bin/link -n nvim              # dry-run
bin/link -v zsh kitty         # verbose
```

The script resolves the repo root from its own location, so it works whether you clone to `~/Dev`, `~/dotfiles`, or anywhere else.

## Convention

Configs live in this repo and are symlinked out — never copied. To make a change, edit the file under its real path (e.g. `configs/nvim/lua/...`) and commit. The symlink in `~/.config/nvim` picks it up automatically.
