# drucial-dots

My personal dotfiles. App configs live under `configs/` and get symlinked into `~/.config` (or `$XDG_CONFIG_HOME`); their package dependencies are declared in Brewfiles. One command, `bin/sync`, installs and links everything.

## Layout

```
configs/     app configs (symlinked into ~/.config) + per-config Brewfiles
claude/      Claude Code config, symlinked into ~/.claude via claude/install
codex/       Codex config, hooks, agents, and shared skills
bin/sync     installs packages + links everything (idempotent)
bin/Brewfile base manifest: taps, fonts, shared/configless tooling
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
| `nvim/`         | editor (LazyVim) |
| `posting/`      | API client |
| `rainfrog/`     | database TUI |
| `tuicr/`        | TUI code review |
| `yabai/`        | window manager |
| `yazi/`         | file manager |
| `zen-term/`     | terminal |
| `zsh/`          | shell |
| `starship.toml` | prompt |

## Bootstrap

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
cd ~/Dev/drucial-dots
bin/sync          # install packages + link every config + agents + ~/.zshrc
```

That's the whole setup. On a machine without Homebrew (Linux, etc.) `bin/sync`
prints a notice and skips package install, still linking every config.

### `bin/sync`

Makes the machine match the repo. Idempotent — re-run any time and only the new
or missing pieces are applied.

```sh
bin/sync        # full sync
bin/sync -n     # dry-run (incl. `brew bundle check`), changes nothing
bin/sync -f     # force-replace existing files/links
bin/sync -v     # verbose
```

It (1) installs packages via `brew bundle`, (2) symlinks every `configs/*` into
`~/.config`, (3) installs the tracked Claude and Codex configuration, and (4)
sets up home-level symlinks (`~/.zshrc`). The script resolves the repo root from
its own location, so it works whether you clone to `~/Dev`, `~/dotfiles`, or
anywhere else.

## Codex parity

`codex/` translates the behavior of this repo's personal Claude setup without
trying to mirror either product's entire plugin ecosystem. Shared instructions,
rules, agent prompts, and portable skills remain canonical under `claude/`.
Codex-only TOML, hooks, and small skill adapters live under `codex/`.

`codex/install` manages only
`~/.codex/{config.toml,AGENTS.md,rules,hooks.json,hooks,agents}` and
`~/.agents/skills`. It does not touch authentication, sessions, history,
databases, caches, or installed plugins. Existing managed destinations require
`-f`; replacements are moved to `~/.codex-config-backups/` first.

## Package manifests (Brewfiles)

Dependencies are declared in `brew bundle` syntax and split by ownership:

- **`configs/<tool>/Brewfile`** — packages a single config owns (e.g.
  `configs/yazi/Brewfile` lists `yazi` + its preview deps `ffmpeg`, `sevenzip`, …).
- **`bin/Brewfile`** — taps, fonts, shared CLIs (`fzf`, `ripgrep`, `fd`, …), and
  configless tooling. Also holds a commented `REVIEW` section of one-off/experimental
  packages — uncomment to include them on a fresh machine.

`bin/sync` concatenates `bin/Brewfile` with every `configs/*/Brewfile` and pipes the
result to `brew bundle`. To add a dependency, drop a line in the owning config's
Brewfile (or `bin/Brewfile`) and re-run `bin/sync`.

Note: casks are macOS-only; on Linux-with-Homebrew `brew bundle` skips them.

## Convention

Configs live in this repo and are symlinked out — never copied. To make a change,
edit the file under its real path (e.g. `configs/nvim/lua/...`) and commit. The
symlink in `~/.config/nvim` picks it up automatically.
