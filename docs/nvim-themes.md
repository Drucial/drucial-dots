# Neovim theme switching

Neovim's colorscheme is not set in this repo. An external theme switcher writes
a LazyVim spec, and nvim picks it up — live, without a restart. Today that
switcher is Omarchy; the same contract is open to ZenTerm.

## The contract

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

## Adding ZenTerm

Steps 1 and 2 are the whole job. ZenTerm's catalog is
`Sources/ZenTerm/Themes/*.ghostty`; most entries already have a matching plugin
in `all-themes.lua` — catppuccin, everforest, gruvbox, kanagawa, rose-pine,
tokyonight. Dracula, Nord and Solarized would need adding there.

The one change needed in this repo: `lua/config/lazy.lua` hardcodes the Omarchy
source path. It needs to try ZenTerm's state path first and fall back.
