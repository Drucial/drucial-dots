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
icons/        launcher icons for anything with no website to fetch one from
Brewfile      curated package manifest for macOS, one section per config
Archfile      the same for Omarchy, installed with yay
Omarchyfile   everything else that makes an Omarchy box mine
bin/dots      install / add / migrate / remove / brew / pac
bin/sync-omarchy   one command: configs, packages, and the Omarchyfile
bin/lazygit-theme  regenerates lazygit's colours from the current theme
bin/dots.test.sh, bin/sync-omarchy.test.sh   drive both against throwaway copies
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

On Omarchy, after a stock install of the same version, one command does all of it:

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
cd ~/Dev/drucial-dots
bin/sync-omarchy
```

On macOS the pieces are still separate:

```sh
bin/dots install    # symlink every config, plus the home-level dotfiles
bin/dots brew       # install the packages
```

Neither carries secrets or app data. 1Password, SSH keys, `gh auth login`, the
atuin key, and Tailscale are all still done by hand on a new machine.

Configs that only make sense on one platform are skipped rather than linked --
`yabai` on Linux, `hypr` on macOS. Both keep their sections in both manifests, so
a config stays addressable from either machine.

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
  Skipped       1
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

## Omarchyfile

`bin/sync-omarchy` runs `bin/dots install`, then `bin/dots pac`, then applies the
`Omarchyfile` — the part of an Omarchy machine that is neither a config file nor
a package:

```
# --- theme ---
Tokyo Night

# --- webapps ---
Linear|https://linear.app|

# --- removed packages ---
pinta
xournalpp
```

Sections use the same `# --- <name> ---` grammar as the package manifests. Like
the Archfile it assumes an Omarchy base install and states only the delta from
it — the launchers added on top of the shipped ones, and the packages and
launchers taken away.

Removals are the half a fresh install gets wrong on its own: Omarchy puts
`Basecamp`, `Discord`, `HEY`, `WhatsApp` and the rest back on every
`omarchy refresh applications`, so what was deleted has to be written down to
stay deleted. The same call recreates the `~/.local/bin` mise wrappers, and each
of those reinstalls its tool when run, which is why removed stubs are named too.
Package removals go through `omarchy pkg drop`, which ignores anything already
absent.

An empty icon field lets Omarchy fetch the site's own apple-touch-icon, so most
web apps need nothing in the repo. A TUI has no site to fetch from, which is
what `icons/` is for.

`bar plugins` names the widgets enabled on top of the bar's default layout.
Enabling one needs no sudo, so the bar is reproduced without running an
interactive service installer -- `omarchy install service tailscale` also enables
a daemon and authenticates a browser session, and that half stays a manual step
alongside the other logins.

Two apps need more than a config file to follow the theme. btop resolves
`color_theme = "current"` through a symlink Omarchy writes once at install and
never recreates, so `sync-omarchy` recreates it. lazygit has no Omarchy theme
file at all -- `bin/lazygit-theme` derives one from the palette in the theme's
`colors.toml`, which every theme ships, and a `theme-set` hook reruns it on each
switch. Its tracked file is `configs/lazygit/settings.yml`; `config.yml` is
generated from it and gitignored, so lazygit needs no wrapper or flag to be
themed. With no Omarchy palette present -- macOS, or before the first theme is
set -- the generator writes the settings alone and leaves lazygit's own colours
in place.

`~/.config/omarchy/` itself is deliberately **not** symlinked in. Everything in
it — `shell.json`, `extensions/`, the hooks — is byte-identical to what Omarchy
ships, and adopting the directory would put `omarchy refresh` and the update
migrations on a collision course with this repo. The one value that is really
mine is the shell font size, so the Omarchyfile carries that and writes the key
directly.

Every step is idempotent. `bin/sync-omarchy -c` reports what differs without
changing anything, `-n` prints the commands, `-v` names what is already correct.

## Convention

Configs are symlinked out, never copied. Edit the file under its real path
(`configs/nvim/lua/...`) and commit — the symlink picks it up.

## Tests

```sh
bash bin/dots.test.sh
bash bin/sync-omarchy.test.sh
```

Both copy the working tree to a temp dir and point `HOME` and `XDG_CONFIG_HOME`
at scratch dirs. The first drives all five `dots` subcommands through the real
CLI. The second stubs `omarchy`, `pacman`, and `yay` so it can assert on what
`sync-omarchy` asked them to do without a real Omarchy install, and without ever
reaching real package management. Neither touches anything on the machine.
