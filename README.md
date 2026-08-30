# drucial-dots

My personal dotfiles. App configs live under `configs/` and get symlinked into
`~/.config` (or `$XDG_CONFIG_HOME`). Packages come from two curated manifests at
the repo root — `Brewfile` on macOS, `Archfile` on Omarchy. `bin/dots` is the
only script.

## Layout

```
configs/      app configs, symlinked into ~/.config
desktop-entries/  overrides that hide junk from the Linux apps menu
docs/         notes on anything a config file cannot explain itself
Brewfile      curated package manifest for macOS, one section per config
Archfile      the same for Omarchy, installed with yay
bin/dots      install / add / migrate / remove / brew / pac
bin/dots.test.sh   drives every subcommand against a throwaway copy
```

Neovim's colorscheme comes from an external theme switcher rather than from
this repo — see [docs/nvim-themes.md](docs/nvim-themes.md).

`desktop-entries/` holds `.desktop` files that shadow the ones in
`/usr/share/applications`, setting `NoDisplay=true` to keep menu clutter out of
the launcher. They exist because the owning packages — avahi, hwloc, v4l-utils —
are dependencies of half the desktop and cannot be uninstalled. Each one links
into `~/.local/share/applications` individually rather than the directory being
symlinked whole, because Omarchy writes its own web app launchers there. Drop a
new file in and `bin/dots install` picks it up.

Display scaling is per-machine, so `hypr/monitors.lua` reads it from
`~/.local/state/hypr/machine.lua` when that file exists and falls back to
committed defaults when it doesn't. Nothing else in `configs/` is
machine-specific.

### `configs/`

| Config          | App                    |
| --------------- | ---------------------- |
| `atuin/`        | shell history          |
| `bash/`         | bash rc + aliases      |
| `btop/`         | system monitor         |
| `diffnav/`      | git diff TUI           |
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
| `worktrunk/`    | git worktree manager   |
| `yabai/`        | window manager (macOS) |
| `yazi/`         | file manager           |
| `zen-linear/`   | Linear TUI             |
| `zen-term/`     | terminal               |
| `zsh/`          | shell                  |

## Bootstrap

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
cd ~/Dev/drucial-dots
bin/dots install    # symlink every config, plus the home-level dotfiles
bin/dots brew       # macOS: install the packages
bin/dots pac        # Omarchy: install the packages
```

`install` also links `~/.zshrc`, `~/.zprofile`, `~/.bashrc`, and
`~/.bash_aliases`. `~/.bashrc` is tracked because it is a one-time `/etc/skel`
seed that Omarchy never updates again — without it, nothing sources the
aliases.

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
bin/dots pac                # install the Archfile with yay
bin/dots pac -c             # check it instead
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

`add` and `migrate` create a config's section in **both** manifests and seed
whichever one the current machine can resolve the name against — Homebrew for
the Brewfile, pacman's sync db for the Archfile. `remove` shows what each owns
and drops both on one confirmation. Keeping them in step means a config added on
the mac is still addressable from the Arch box, and the reverse.

`bin/dots brew -c` fails on a section naming a config that doesn't exist, and
lists configs that declare no packages without failing — `gh-dash`, `tuicr`,
`zen-linear`, and `zen-term` install nothing through Homebrew. An unfamiliar
name on that list means a section is missing. It then asks Homebrew whether the
manifest is satisfied.

`gh-dash` is a `gh` extension rather than a formula:
`gh extension install dlvhdr/gh-dash`.

## Archfile

Same section grammar, one bare package name per line, installed with
`yay -S --needed` so the official repos and the AUR are covered alike:

```
# --- shared ---
1password
zen-browser-bin

# --- config: yazi ---
yazi
chafa
```

It assumes an Omarchy base install and does not restate the ~200 packages in
`/usr/share/omarchy/install/*.packages`. That is why `bin/dots pac -c` lists many
more configs as declaring no packages than the Brewfile does — most of them are
already covered by that base.

`pac -c` then asks pacman which of the names the Archfile lists are missing, and
exits non-zero if any are.

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
