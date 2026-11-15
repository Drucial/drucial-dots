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
  `omarchy pkg add`. No AUR.
- Secrets never go in the repo.

## Layout

| Path | What |
| --- | --- |
| `home/dot_config/...` | Configs, copied to `~/.config/...` |
| `home/.chezmoidata/omarchy.yaml` | Omarchy packages and web apps to install |
| `home/dot_local/share/icons/...` | Web app icons |
| `home/run_onchange_after_omarchy.sh.tmpl` | Installs the above, sets the bar; re-runs when either changes |
| `home/.chezmoiignore` | Paths skipped per OS |
| `home/.chezmoi.toml.tmpl` | Per-machine chezmoi config, generated on `init` |

## New machine

```sh
git clone https://github.com/Drucial/drucial-dots.git ~/Dev/drucial-dots
sudo pacman -S chezmoi            # macOS: brew install chezmoi
chezmoi init --source ~/Dev/drucial-dots   # prompts once for git name and email
chezmoi diff                      # review before anything changes
chezmoi apply
gh auth login                     # git's credential helper calls gh
```

Per-machine values (git identity) live in `~/.config/chezmoi/chezmoi.toml`, never
in the repo.

## Day to day

chezmoi copies files; it does not symlink. Edit either side, then sync:

```sh
chezmoi edit ~/.config/hypr/bindings.lua   # edit the source, then: chezmoi apply
chezmoi re-add                             # or edit the live file, then pull it back
```

Commit and push from `~/Dev/drucial-dots`. On the other machines:

```sh
chezmoi update        # git pull + apply
```

`chezmoi diff` shows any drift between the repo and the machine; check it before
applying.

## Adding

- **Config:** `chezmoi add ~/.config/<app>`, then strip the source copy down to
  the settings that differ from the app's defaults.
- **Linux- or macOS-only config:** also list it under the other OS in
  `home/.chezmoiignore`.
- **Omarchy package:** add it to `packages` in `home/.chezmoidata/omarchy.yaml`,
  then `chezmoi apply`.
- **Web app:** add `name`, `url` and `icon` to `webapps` in the same file, and
  put a 256px PNG named `<icon>.png` in
  `home/dot_local/share/icons/hicolor/256x256/apps/`.

## Removing

- **Config:** `chezmoi forget ~/.config/<app>` stops tracking it and leaves the
  live file alone. Delete the live file by hand if it should go too.
- **Package or web app:** delete its line. Uninstall it on each machine by hand
  (`omarchy pkg drop <pkg>`, `omarchy webapp remove <name>`).
