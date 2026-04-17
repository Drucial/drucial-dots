# Delta Integration for Git and LazyGit

**Date:** 2026-04-17
**Status:** Approved

## Goal

Add [delta](https://github.com/dandavison/delta) as the default pager for Git with a custom Rosé Pine Moon theme, and wire it into LazyGit's full-page diff view while keeping LazyGit's native inline hunk-staging intact.

## Motivation

- Terminal `git diff` / `git log -p` / `git show` output is currently unstyled — hard to scan large changesets.
- LazyGit's full-page diff view (opened with `enter` on a file) inherits the raw git pager output; delta renders this with syntax highlighting.
- Tracking the config in `dots_v2` keeps it portable across machines and consistent with the existing dotfiles pattern.

## Non-Goals

- Replacing LazyGit's inline staging view. Delta cannot drive interactive line/hunk selection, so that stays native.
- Changing `~/.gitconfig` (user name/email). Delta config lives in a separate tracked file.
- Community theme packages. Custom feature block only, matching the user's existing Rosé Pine Moon palette.

## Design

### File Layout

```
dots_v2/git/config          → ~/.config/git/config   (new symlink)
dots_v2/lazygit/config.yml  → ~/.config/lazygit/config.yml   (already symlinked)
```

Git reads `~/.config/git/config` automatically. It layers *under* `~/.gitconfig`, so existing user identity is preserved.

### Install Prerequisite

`brew install git-delta` — delta binary is `delta`, not `git-delta`, on PATH after install.

### Git Config (`dots_v2/git/config`)

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    features = rose-pine-moon
    navigate = true
    side-by-side = true
    line-numbers = true
    syntax-theme = base16
    hyperlinks = true

[delta "rose-pine-moon"]
    # File + hunk headers
    file-style = "#c4a7e7 bold"
    file-decoration-style = "#393552 ul"
    hunk-header-style = "#908caa"
    hunk-header-decoration-style = "#393552 box"
    hunk-header-file-style = "#c4a7e7"
    hunk-header-line-number-style = "#f6c177"

    # Diff line colors
    minus-style = "#eb6f92 #3d2436"
    minus-emph-style = "syntax #6a2e4a"
    plus-style = "#9ccfd8 #1f3640"
    plus-emph-style = "syntax #2a5260"
    zero-style = "syntax"

    # Line numbers
    line-numbers-left-style = "#6e6a86"
    line-numbers-right-style = "#6e6a86"
    line-numbers-minus-style = "#eb6f92"
    line-numbers-plus-style = "#9ccfd8"
    line-numbers-zero-style = "#44415a"

    # Blame
    blame-code-style = syntax
    blame-format = "{author:<14} {timestamp:<13} {commit:<8}"
    blame-palette = "#232136 #2a273f #393552 #44415a"

[merge]
    conflictStyle = zdiff3
```

### LazyGit Config (`dots_v2/lazygit/config.yml`)

Append a top-level `git` block:

```yaml
git:
  paging:
    colorArg: always
    pager: delta --paging=never --side-by-side=false
    useConfig: false
```

- `--side-by-side=false` overrides the terminal default — inline is better inside LazyGit's narrower diff pane.
- `useConfig: false` makes LazyGit pass flags directly to delta instead of routing through git's pager config (avoids double-pagination).

## Palette Mapping (Rosé Pine Moon → Delta)

| Role | Palette token | Hex | Delta usage |
|------|--------------|-----|-------------|
| File headers | Iris | `#c4a7e7` | `file-style`, `hunk-header-file-style` |
| Header decoration | Overlay | `#393552` | `file-decoration-style`, `hunk-header-decoration-style` |
| Hunk header text | Subtle | `#908caa` | `hunk-header-style` |
| Line-number accent | Gold | `#f6c177` | `hunk-header-line-number-style` |
| Deletions (fg) | Love | `#eb6f92` | `minus-style`, `line-numbers-minus-style` |
| Deletion bg (subtle) | synthesized | `#3d2436` | `minus-style` bg (Base × Love) |
| Deletion bg (emph) | synthesized | `#6a2e4a` | `minus-emph-style` bg |
| Additions (fg) | Foam | `#9ccfd8` | `plus-style`, `line-numbers-plus-style` |
| Addition bg (subtle) | synthesized | `#1f3640` | `plus-style` bg (Base × Foam) |
| Addition bg (emph) | synthesized | `#2a5260` | `plus-emph-style` bg |
| Line number gutter | Muted | `#6e6a86` | `line-numbers-*-style` |
| Zero line numbers | Highlight Med | `#44415a` | `line-numbers-zero-style` |
| Blame palette | Base/Surface/Overlay/Highlight Med | — | `blame-palette` rotation |

Synthesized backgrounds are darkened mixes that read as "changed" without overpowering the Base (`#232136`).

## Verification

After implementation:

1. `delta --version` — confirms install.
2. Run `git diff HEAD~1` in a repo with recent changes — expect side-by-side, colored, line-numbered output.
3. Run `git log -p --max-count=1` — expect commit header in Iris, file headers boxed.
4. Run `git blame` on a file — expect alternating palette rows.
5. Open LazyGit, press `enter` on a changed file — expect inline (not side-by-side) delta-rendered diff.
6. In LazyGit, press `space`/`a` on individual lines in the *inline* view to confirm staging still works.

## Rollback

Remove the symlink `~/.config/git/config` and revert `lazygit/config.yml`. Git falls back to the default pager; LazyGit falls back to its built-in diff rendering.
