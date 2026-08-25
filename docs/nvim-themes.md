# Neovim theme switching

Neovim's colorscheme is not set in this repo. Something outside it decides, and
nvim picks the choice up live, without a restart. Two things do, by different
routes: Omarchy on Linux writes a LazyVim spec, and ZenTerm on the mac publishes
a theme file that a plugin reads.

## Omarchy: the generated-spec contract

Three steps. Only the first two belong to the switcher.

1. **Write a spec file.** A normal LazyVim plugin spec: the colorscheme plugin
   with its `opts`, plus a `LazyVim/LazyVim` entry naming the colorscheme.

   ```lua
   return {
     { "bjarneo/aether.nvim", branch = "v3", name = "aether", priority = 1000,
       opts = { colors = { bg = "#0c0b0c", fg = "#FAFCFB", --[[ ... ]] } } },
     { "LazyVim/LazyVim", opts = { colorscheme = "aether" } },
   }
   ```

   Omarchy regenerates this at `~/.local/state/omarchy/current/theme/neovim.lua`
   on every `omarchy theme set`.

2. **Symlink it to `lua/plugins/theme.lua`.** `lua/config/lazy.lua` does this on
   startup if the source exists. lazy then imports it as an ordinary spec.
   The link is gitignored — it is machine-local and its target is not portable.

3. **Rewriting the target hot-reloads it.** lazy's change detection follows the
   link and fires `LazyReload`; `lua/plugins/omarchy-theme-hotreload.lua` clears
   the highlight groups, reloads the theme plugin, applies the new colorscheme
   and re-sources `plugin/after/transparency.lua`. The switcher does not need to
   participate — the autocmd does not care who wrote the file.

## What the repo does to support it

| File | Role |
| ---- | ---- |
| `lua/config/lazy.lua` | Creates the symlink; `change_detection.notify = false` so a theme swap does not pop a "Config Change Detected" prompt |
| `lua/plugins/all-themes.lua` | Declares every theme plugin the switcher might name, all `lazy = true`, so a swap never has to clone mid-session |
| `lua/plugins/omarchy-theme-hotreload.lua` | The `LazyReload` handler in step 3 |
| `lua/plugins/rose-pine.lua` | Personal rose-pine tuning, plus the fallback below |
| `lua/plugins/lualine.lua` | Resolves its colors from live highlight groups per draw, so the statusline repaints on a swap |
| `lua/config/options.lua` | Holds `winborder`, which would otherwise be lost on every swap |

## Machines with no switcher

`rose-pine.lua` checks whether `lua/plugins/theme.lua` exists. If it does not,
nothing else would select a colorscheme and LazyVim would fall back to its own
default, tokyonight — so it adds a `LazyVim/LazyVim` spec naming
`rose-pine-moon`. When a switcher is present that spec is omitted entirely,
rather than merged, so it cannot override the generated one.

The check is on the link, not on Omarchy. Any switcher that writes
`lua/plugins/theme.lua` takes over automatically, with no edit here.

## ZenTerm: the published-theme contract

ZenTerm does not write a lua spec. It publishes the theme it resolved to
`~/Library/Application Support/ZenTerm/theme.json`, and
[zen-theme.nvim](https://github.com/praxis-labs-io/zen-theme.nvim) reads it, watches
it, and applies a colorscheme to match. Nothing is symlinked and
`lua/plugins/theme.lua` is not involved.

Each ZenTerm theme names its colorscheme in its own `.ghostty` file:

```
nvim-colorscheme = kanagawa-dragon
```

Every bundled theme carries one, so the mapping lives with the theme rather than
here. A theme of my own in `~/.config/zen-term/themes/` takes one line and is mapped
too. The full payload is documented in `docs/nvim-theme-protocol.md` in the zen-term
repo.

| File | Role |
| ---- | ---- |
| `lua/plugins/zen-theme.lua` | The plugin spec. `event = "VimEnter"` so it applies after LazyVim has selected its own colorscheme, rather than racing it |
| `lua/plugins/all-themes.lua` | Also declares nord, dracula and solarized, which ZenTerm's catalog names and Omarchy never did |
| `lua/plugins/rose-pine.lua` | Its fallback still seeds a colorscheme at startup, which zen-theme then overrides |

The two switchers coexist. There is no Omarchy on the mac, so no `theme.lua`
symlink is made and `rose-pine.lua` seeds rose-pine-moon; zen-theme replaces it at
VimEnter with whatever ZenTerm is wearing. On Linux there is no ZenTerm, the plugin
spec skips itself, and Omarchy's path is untouched.

The spec points at a local clone at `~/Dev/zen-theme.nvim` and skips itself when that
is absent. Point it at `zen-term/zen-theme.nvim` once the repo is public.
