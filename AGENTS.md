# drucial-dots

Dotfiles for two Omarchy machines and two Macs, managed by [chezmoi](https://chezmoi.io).
The repo lives at `~/Dev/drucial-dots`. `.chezmoiroot` points chezmoi at `home/`,
which mirrors `$HOME` (`home/dot_config/hypr` → `~/.config/hypr`).

## Rules

- Track only what differs from the defaults. Omarchy owns everything it ships;
  a tracked file holds only my overrides.
- Track what to add, never what to remove. Each machine uninstalls by hand.
- Nothing per-machine is tracked: themes, monitors, display scale, hardware files.
- Packages on Omarchy come from the official and Omarchy repos via
  `omarchy pkg add`. No AUR. Packages on the Macs come from Homebrew.
- Nothing project-specific. A project's tools go in that project's `mise.toml`.
- Secrets never go in the repo. Shell secrets (API keys) live in the untracked
  `~/.config/shell/secrets`, which both shells source when it exists.

## Layout

| Path | What |
| --- | --- |
| `home/dot_config/...` | Configs, copied to `~/.config/...` |
| `home/.chezmoidata/omarchy.yaml` | Omarchy packages and web apps to install |
| `home/dot_local/share/icons/...` | Web app icons |
| `home/.chezmoidata/brew.yaml` | Homebrew formulae and casks for the Macs |
| `home/run_onchange_after_*.sh.tmpl` | Install packages (10), render the herdr theme (20), then mise tools and yazi plugins (30). Each re-runs when its rendered text changes, including the hashes of the files it reads |
| `home/dot_claude/` | Claude Code: global `CLAUDE.md`, skills, agents, hooks, themes, status line; `settings.json` is a `modify_` script |
| `home/dot_config/shell/` | Env, aliases and functions shared by bash and zsh; aliases live only here |
| `home/dot_bashrc`, `home/dot_config/bash/` | Linux: Omarchy's bash defaults, then the shared files and bash-only functions |
| `home/dot_zshrc`, `home/dot_zprofile` | Macs: zsh setup and Homebrew, then the shared files |
| `home/.chezmoiignore` | Paths skipped per OS |
| `home/.chezmoi.toml.tmpl` | Per-machine chezmoi config, generated on `init` |

## New machine

### Omarchy

Install Omarchy, then:

```sh
sudo pacman -S chezmoi
chezmoi init --apply --source ~/Dev/drucial-dots Drucial/drucial-dots   # prompts for git name and email; sudo for packages
gh auth login                                                           # git's credential helper calls gh
```

Then delete what `chezmoi unmanaged ~/.config/nvim` lists, except Omarchy's
`lua/plugins/theme.lua` link. That is Omarchy's stock nvim config, which chezmoi
never removes.

### Mac

Install [Homebrew](https://brew.sh), then:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"   # this shell only; chezmoi writes ~/.zprofile
brew install chezmoi
chezmoi init --apply --source ~/Dev/drucial-dots Drucial/drucial-dots   # prompts for git name and email
gh auth login                                                           # git's credential helper calls gh
```

Then open OrbStack once, and install any apps only this machine needs.

### Both

- herdr's keys land on the first `chezmoi apply` or `update` after herdr's first
  launch, since the keys script edits the `keys.json` herdr writes then.
- Put API keys in `~/.config/shell/secrets`.
- Run `claude plugin install zen-review@praxis-labs`. Claude installs the other
  enabled plugins on first launch, but not ones from third-party marketplaces.

Per-machine values (git identity) live in `~/.config/chezmoi/chezmoi.toml`, never
in the repo.

## Day to day

chezmoi copies files; it does not symlink. Edit either side, then sync:

```sh
chezmoi edit ~/.config/hypr/bindings.lua   # edit the source, then: chezmoi apply
chezmoi re-add <path>                      # or edit the live file, then pull it back
```

Commit and push from `~/Dev/drucial-dots`. On the other machines:

```sh
chezmoi update --init   # git pull, regenerate the config if its template changed, apply
```

`chezmoi diff` shows any drift between the repo and the machine; check it before
applying. Some files are rewritten by their apps or edited in place — herdr-app's
mods, the font line `omarchy font set` writes into ghostty's config. `re-add`
pulls those back, but it only updates files already tracked, and never `.tmpl`
or `modify_` sources: edit those in the repo, and `chezmoi add` new files.

herdr-app's keys, settings and layouts are `modify_` scripts, because herdr
writes to them while it runs. They set only my keys and settings, per OS, on top
of herdr's. The layouts live in `home/.chezmoitemplates/herdr-layouts/`; applying
one keeps the live file's panel widths, shown panels, focus border color and
picked theme. Claude Code's `settings.json` works the same way: its `modify_`
script sets my settings on top of what Claude writes. nvim's `lazy-lock.json` is untracked: each machine keeps its own
plugin versions.

## Adding

- **Config:** `chezmoi add ~/.config/<app>`, then strip the source copy down to
  the settings that differ from the app's defaults.
- **App that rewrites its whole config on exit** (btop): track a `modify_` script
  that sets only your keys, like `home/dot_config/btop/modify_btop.conf`.
- **Linux- or macOS-only config:** also list it under the other OS in
  `home/.chezmoiignore`.
- **Omarchy package:** add it to `packages` in `home/.chezmoidata/omarchy.yaml`,
  then `chezmoi apply`.
- **Mac package:** add it to `formulae` or `casks` in `home/.chezmoidata/brew.yaml`,
  then `chezmoi apply`.
- **Web app:** add `name`, `url` and `icon` to `webapps` in the same file, and
  put a 256px PNG named `<icon>.png` in
  `home/dot_local/share/icons/hicolor/256x256/apps/`.

## Removing

- **Config:** `chezmoi forget ~/.config/<app>` stops tracking it and leaves the
  live file alone. Delete the live file by hand if it should go too.
- **Package or web app:** delete its line. Uninstall it on each machine by hand
  (`omarchy pkg drop <pkg>`, `omarchy webapp remove <name>`, `brew uninstall <pkg>`).
