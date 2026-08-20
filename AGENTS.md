# AGENTS.md

This file provides guidance to Codex when working with code in this repository.

## What this repo is

Personal dotfiles for macOS. There is no build, no package manager, no test framework — the "product" is a set of symlinks. Everything under `configs/` is the **real file**; `~/.config` holds symlinks pointing back here.

The load-bearing consequence: **editing a tracked file takes effect immediately, with no sync step.** Whole directories are linked, so `configs/nvim/lua/plugins/foo.lua` is live the moment you save it. `bin/sync` is only needed when a *new* top-level config directory or a new Brewfile entry appears.

Never copy a config into `~/.config` and never edit through the symlink path — edit the repo path.

Claude Code and Codex config are **not** managed here. They live as real files in `~/.claude` and `~/.codex` and are independent of this repo.

## Commands

```sh
bin/sync              # install packages + link everything (idempotent)
bin/sync -n           # dry-run, incl. `brew bundle check` — changes nothing
bin/sync -f           # force-replace existing files/links at destinations
bin/sync -v           # verbose (link_path is silent on success without this)
```

Without `-f`, `bin/sync` **refuses** to overwrite an existing destination and exits non-zero.

## Architecture

### `bin/sync` — three ordered phases

1. **Packages** — concatenates `bin/Brewfile` with every `configs/*/Brewfile` and pipes the stream to `brew bundle install --file=- --no-upgrade`. Missing Homebrew is a warning, not a failure; linking still runs.
2. **Configs** — links every `configs/*` entry into `$XDG_CONFIG_HOME` (default `~/.config`), skipping a top-level `Brewfile`.
3. **Home symlinks** — the `pairs` array in `sync_home()` (`~/.zshrc` → `~/.config/zsh/.zshrc`).

The script resolves its own directory by walking `readlink` in a loop, so the repo can live at any path and works when invoked through a symlink.

Phases 2–3 use `|| true` per item: one bad link logs and the rest continue. Adding a new config directory needs no code change; adding a new home-level symlink means editing `pairs`.

### Brewfile ownership

Dependencies are split by who owns them. A package a single config needs goes in `configs/<tool>/Brewfile` (e.g. `configs/yazi/Brewfile` carries `yazi` plus its preview deps). Taps, fonts, shared CLIs, and configless tooling go in `bin/Brewfile`, which also holds a commented `REVIEW` block of experimental packages. A config's own Brewfile is metadata — it rides along inside the linked directory rather than being linked out.

## Gotchas

**`configs/linear-tui/config.json` drifts visibly.** linear-tui hardcodes `~/.linear-tui/config.json` (no XDG), so `bin/sync` links that path back here via a `sync_home` pair. The app saves settings in place (`os.WriteFile`, no rename), so in-app Settings changes write through the symlink and show up as a repo diff — that's intentional. The binary is a local fork build (`~/Dev/linear-tui`, `drucial/combined` branch) installed to `~/.local/bin`, which shadows the stock brew tap install.

**Secrets are gitignored, not absent.** `configs/zsh/.secrets` and `configs/rainfrog/rainfrog_config.toml` hold real credentials on disk and are excluded in `.gitignore`; `.secrets.example` and the rainfrog `.example` are the tracked stand-ins. Update the example when the real file gains a key.

**`configs/nvim/` is a LazyVim distribution** with its own `README.md`, `.gitignore`, and `lazy-lock.json`. Plugin specs go in `lua/plugins/<name>.lua`, editor settings in `lua/config/`. Lua is formatted by stylua (`configs/nvim/stylua.toml`).

**Casks are macOS-only.** On Linux-with-Homebrew `brew bundle` skips them, and `bin/sync` prints a notice and skips package install entirely when `brew` is absent.

## Conventions

Commit subjects are `scope: lowercase description`, where scope is the config or subsystem touched — `nvim:`, `btop:`, `zsh:`, `bin:`. Repo-wide changes drop the prefix.

Shell scripts open with `#!/usr/bin/env bash` and `set -euo pipefail`, take `-f/-n/-v/-h` via `getopts`, and print usage from a `usage()` heredoc.
