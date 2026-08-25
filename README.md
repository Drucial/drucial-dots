# drucial-dots

My personal dotfiles. App configs live under `configs/` and get symlinked into
`~/.config` (or `$XDG_CONFIG_HOME`). Packages come from one curated `Brewfile`
at the repo root. `bin/dots` is the only script.

## Layout

```
configs/      app configs, symlinked into ~/.config
docs/         notes on anything a config file cannot explain itself
Brewfile      curated package manifest, one section per config
bin/dots      install / add / migrate / remove / brew
bin/dots.test.sh   drives every subcommand against a throwaway copy
```

Neovim's colorscheme comes from an external theme switcher rather than from
this repo — see [docs/nvim-themes.md](docs/nvim-themes.md).

### `configs/`

| Config          | App                    |
| --------------- | ---------------------- |
| `atuin/`        | shell history          |
| `btop/`         | system monitor         |
| `diffnav/`      | git diff TUI           |
| `eza/`          | `ls` replacement theme |
| `gh-dash/`      | GitHub TUI             |
| `git/`          | git config + ignore    |
| `hypr/`         | Hyprland (Linux only)  |
| `kitty/`        | terminal               |
| `lazygit/`      | git TUI                |
| `mise/`         | tool versions          |
| `nvim/`         | editor (LazyVim)       |
| `posting/`      | API client             |
| `rainfrog/`     | database TUI           |
| `slk/`          | Slack TUI              |
| `starship.toml` | prompt                 |
| `tuicr/`        | TUI code review        |
| `yabai/`        | window manager (macOS) |
| `yazi/`         | file manager           |
| `zen-linear/`   | Linear TUI             |
| `zen-term/`     | terminal               |
| `zsh/`          | shell                  |

## Bootstrap

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
cd ~/Dev/drucial-dots
bin/dots install    # symlink every config, plus ~/.zshrc and ~/.zprofile
bin/dots brew       # install the packages
```

`install` never stops on the first problem. It works through every config, then
prints a summary and exits non-zero if anything was left unresolved:

```
▶ Summary
  Linked       19
  Already ok    0
  Unresolved    1

  Unresolved — nothing at these paths was changed:

    ✖ ~/.config/ghostty
      a real directory, not a link
      bin/dots migrate ghostty   adopt it into the repo
```

A real directory in the way is never overwritten, with or without `-f`. Adopt it
with `migrate`, or move it aside. `-f` replaces symlinks and drifted files only,
and there is no backup.

The script resolves the repo root from its own location, so the clone can live
anywhere. Without Homebrew, `bin/dots brew` prints a notice and does nothing;
configs still link.

## Commands

```sh
bin/dots install            # link everything
bin/dots add <name>         # scaffold a new config in the repo, link it out
bin/dots migrate <name>...  # adopt ~/.config/<name> into the repo, link it back
bin/dots remove <name>      # unlink, delete from the repo, offer to drop packages
bin/dots brew               # install the Brewfile
bin/dots brew -c            # check it instead
```

Options go anywhere: `-n` dry-run, `-f` force, `-v` verbose, `-y` skip
`remove`'s confirmation prompt.

`add` is for a tool you're configuring from scratch. If `~/.config/<name>`
already exists, use `migrate` — it moves the real files into the repo and links
them back, so nothing is lost. `remove` refuses anything that isn't a symlink
into this repo, and never runs `brew uninstall`.

## Brewfile

One file at the repo root, in `brew bundle` syntax, grouped by owner:

```
# --- shared ---
brew "fzf"
brew "ripgrep"

# --- config: yazi ---
brew "yazi"
brew "ffmpeg"
```

`add` and `migrate` create a config's section and seed it if the name resolves
to a formula or cask. `remove` offers to drop it.

`bin/dots brew -c` fails on a section naming a config that doesn't exist, and
lists configs that declare no packages without failing — `gh-dash`, `tuicr`,
`zen-linear`, and `zen-term` install nothing through Homebrew. An unfamiliar
name on that list means a section is missing. It then asks Homebrew whether the
manifest is satisfied.

`gh-dash` is a `gh` extension rather than a formula:
`gh extension install dlvhdr/gh-dash`.

## Convention

Configs are symlinked out, never copied. Edit the file under its real path
(`configs/nvim/lua/...`) and commit — the symlink picks it up.

## Tests

```sh
bash bin/dots.test.sh
```

Copies the working tree to a temp dir, points `HOME` and `XDG_CONFIG_HOME` at
scratch dirs, and drives all five subcommands through the real CLI. Touches
nothing on the machine.
