# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles for macOS. There is no build, no package manager, no test framework — the "product" is a set of symlinks. Everything under `configs/`, `claude/`, and `codex/` is the **real file**; `~/.config`, `~/.claude`, and `~/.codex` hold symlinks pointing back here.

The load-bearing consequence: **editing a tracked file takes effect immediately, with no sync step.** Whole directories are linked, so `configs/nvim/lua/plugins/foo.lua` is live the moment you save it. `bin/sync` is only needed when a *new* top-level config directory, a new Brewfile entry, or a new item in an install script's `ITEMS` list appears.

Never copy a config into `~/.config` and never edit through the symlink path — edit the repo path.

## Commands

```sh
bin/sync              # install packages + link everything (idempotent)
bin/sync -n           # dry-run, incl. `brew bundle check` — changes nothing
bin/sync -f           # force-replace existing files/links at destinations
bin/sync -v           # verbose (link_path is silent on success without this)

claude/install        # link only ~/.claude items
codex/install         # link only ~/.codex + ~/.agents items

claude/hooks/tests/run-all.sh          # all Claude hook tests
codex/hooks/tests/run-all.sh           # all Codex hook tests
claude/hooks/tests/check-primitives.test.sh   # a single test file
```

Without `-f`, an installer **refuses** to overwrite an existing destination and exits non-zero. `codex/install -f` moves the displaced file to `~/.codex-config-backups/<timestamp>/` first; `claude/install -f` and `bin/sync -f` overwrite outright.

The test runners are plain bash — each `*.test.sh` is executable and self-contained, with fixtures in `tests/fixtures/`.

## Architecture

### `bin/sync` — five ordered phases

1. **Packages** — concatenates `bin/Brewfile` with every `configs/*/Brewfile` and pipes the stream to `brew bundle install --file=- --no-upgrade`. Missing Homebrew is a warning, not a failure; linking still runs.
2. **Configs** — links every `configs/*` entry into `$XDG_CONFIG_HOME` (default `~/.config`), skipping a top-level `Brewfile`.
3. **Claude** — delegates to `claude/install`, forwarding `-f/-n/-v`.
4. **Codex** — delegates to `codex/install`, same forwarding.
5. **Home symlinks** — the `pairs` array in `sync_home()` (`~/.zshrc` → `~/.config/zsh/.zshrc`).

All three scripts resolve their own directory by walking `readlink` in a loop, so the repo can live at any path and the scripts work when invoked through a symlink.

Phases 2–5 use `|| true` per item: one bad link logs and the rest continue. Adding a new config directory needs no code change; adding a new home-level symlink means editing `pairs`, and adding a new `~/.claude` or `~/.codex` item means editing that installer's `ITEMS` array.

### Brewfile ownership

Dependencies are split by who owns them. A package a single config needs goes in `configs/<tool>/Brewfile` (e.g. `configs/yazi/Brewfile` carries `yazi` plus its preview deps). Taps, fonts, shared CLIs, and configless tooling go in `bin/Brewfile`, which also holds a commented `REVIEW` block of experimental packages. A config's own Brewfile is metadata — it rides along inside the linked directory rather than being linked out.

### `claude/` and `codex/` — one source, two harnesses

`claude/` is canonical. `codex/` re-exports it via in-repo symlinks rather than duplicating:

- `codex/AGENTS.md` → `../claude/CLAUDE.md`
- `codex/rules` → `../claude/rules`
- `codex/hooks/session-start.sh` → `../../claude/hooks/session-start.sh`
- most of `codex/skills/*` → `../../claude/skills/*`

Only genuinely Codex-shaped things are real files under `codex/`: `config.toml`, `hooks.json`, the hook scripts that must speak Codex's protocol, `agents/*.toml` (the Claude equivalents are `claude/agents/*.md`), and the few skills needing an adapter (`sanity-check`, `ship-feature`, `project-vetting`, `brandkit`).

When adding shared behavior, write it under `claude/` and symlink from `codex/`. Only fork when the harnesses genuinely differ.

Codex parity is deliberately partial — it covers instructions, rules, agent prompts, and portable skills, not either product's plugin ecosystem. `codex/install` manages exactly `~/.codex/{config.toml,AGENTS.md,rules,hooks.json,hooks,agents}` plus `~/.agents/skills`, and never touches auth, sessions, history, databases, caches, or plugins.

### Hooks

Both harnesses run the same conceptual guards, wired in `claude/settings.json` (`hooks` key) and `codex/hooks.json`. Each hook is a bash script that reads a JSON event on **stdin** and parses it with `jq`:

- `PreToolUse` on `Edit|Write` — `protect-files.sh`, `warn-large-files.sh`, `scan-secrets.sh`, `check-primitives.sh`
- `PreToolUse` on `Bash` — `block-dangerous-commands.sh`
- `PostToolUse` on `Edit|Write` — `format-on-save.sh`, `nudge-duplication.sh`
- Lifecycle — `session-start.sh`, `kitty-agent-state.sh` (fires on nearly every event to drive kitty tab state)

Output conventions differ by intent. A **nudge** writes to stderr and exits 0 — it surfaces in the tool result without blocking (`check-primitives.sh`, `nudge-duplication.sh`). A **decision** prints a `hookSpecificOutput.permissionDecision` JSON object of `deny` or `ask`. Exit code varies by script and isn't the mechanism: `protect-files.sh` emits and exits 0, `block-dangerous-commands.sh` and `scan-secrets.sh` emit and exit 2. `scan-secrets.sh` uses `ask` rather than `deny` on purpose, since a match may be a test fixture.

Codex hooks build the same JSON through `codex_deny()` in `codex/hooks/hook-lib.sh`, which also provides `codex_hook_input`, `codex_patch_paths`, and `codex_absolute_path` for parsing Codex's patch-format tool input. Claude has no equivalent lib — its hooks each inline their own `jq` parsing.

`block-dangerous-commands.sh` denies pushes to a protected branch (by refspec, or a bare `git push` while checked out on one), bare force pushes, and recursive force-deletes on unsafe targets. The branch list is `CLAUDE_PROTECTED_BRANCHES` (default includes `main`), so work here lands on a feature branch and goes through a PR.

`format-on-save.sh` deliberately swallows all formatter stdout/stderr so the common path costs zero tokens. It auto-detects the project's formatter (biome → prettier → language-native) and only runs one that the project actually configures.

Timeouts differ by unit: Claude's `settings.json` uses **milliseconds** (`5000`), Codex's `hooks.json` uses **seconds** (`5`).

Hook scripts target bash 3.2 (macOS system bash) — no associative arrays.

## Gotchas

**`codex/config.toml` drifts on its own.** Codex writes runtime state back through the symlink into the tracked file — `[hooks.state]` trust hashes, `[tui.model_availability_nux]`, `[projects.*] trust_level`. A dirty `codex/config.toml` you didn't edit is usually this. Review the diff before committing and don't assume it's yours.

**Secrets are gitignored, not absent.** `configs/zsh/.secrets` and `configs/rainfrog/rainfrog_config.toml` hold real credentials on disk and are excluded in `.gitignore`; `.secrets.example` and the rainfrog `.example` are the tracked stand-ins. Update the example when the real file gains a key.

**`configs/nvim/` is a LazyVim distribution** with its own `README.md`, `.gitignore`, and `lazy-lock.json`. Plugin specs go in `lua/plugins/<name>.lua`, editor settings in `lua/config/`. Lua is formatted by stylua (`configs/nvim/stylua.toml`).

**Casks are macOS-only.** On Linux-with-Homebrew `brew bundle` skips them, and `bin/sync` prints a notice and skips package install entirely when `brew` is absent.

## Conventions

Commit subjects are `scope: lowercase description`, where scope is the config or subsystem touched — `nvim:`, `btop:`, `zsh:`, `bin:`, `claude:`, or a skill name like `ship-feature:`. Repo-wide changes drop the prefix.

Shell scripts open with `#!/usr/bin/env bash` and `set -euo pipefail`, take `-f/-n/-v/-h` via `getopts`, and print usage from a `usage()` heredoc.

Skills live at `claude/skills/<kebab-name>/SKILL.md` with YAML frontmatter (`name`, `description`); agents at `claude/agents/<kebab-name>.md`. Design docs and plans are dated: `claude/docs/{specs,plans}/YYYY-MM-DD-<slug>.md`.
