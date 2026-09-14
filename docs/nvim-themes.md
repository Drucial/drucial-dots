# Neovim theme switching

Neovim's colorscheme is not set in this repo. Something outside it decides, and
nvim picks the choice up live, without a restart. Two things do, by different
routes: Omarchy on Linux writes a lua spec, and ZenTerm on the mac publishes a
theme file that a plugin reads.

## Omarchy: the generated-spec contract

1. **Omarchy writes a spec.** A plugin spec naming the colorscheme plugin with
   its `opts`, plus a `LazyVim/LazyVim` entry carrying the colorscheme name.

   ```lua
   return {
     { "EdenEast/nightfox.nvim" },
     { "LazyVim/LazyVim", opts = { colorscheme = "nordfox" } },
   }
   ```

   It regenerates this at `~/.local/state/omarchy/current/theme/neovim.lua` on
   every `omarchy theme set`, and points `current/theme` at the new theme's
   directory.

2. **`lua/config/lazy.lua` links it into `lua/plugins/theme.lua`** on startup, if
   the target exists and the link does not. The link is gitignored — its target
   is absent off Omarchy, where a dangling link would break the `plugins` import.

3. **lazy's change detector fires the reload.** It polls the spec files every two
   seconds and stats them through the symlink, so pointing `current/theme` at a
   different theme registers as a change and fires `LazyReload`.
   `lua/plugins/omarchy-theme-hotreload.lua` handles it: clear the highlight
   groups, reload the theme plugin so its `setup()` reruns with the new `opts`,
   apply the colorscheme, re-source `plugin/after/transparency.lua`, and re-fire
   `ColorScheme` so anything deriving from live highlight groups repaints.

The switcher does not participate in step 3 — the autocmd does not care who
wrote the file.

This config is not LazyVim. The `LazyVim/LazyVim` entry is only how Omarchy
names its colorscheme, so `lua/plugins/lazyvim-disable.lua` disables the distro
while leaving the spec imported, and `lua/config/omarchy_theme.lua` reads the
name out of the marker.

| File | Role |
| ---- | ---- |
| `lua/config/lazy.lua` | Creates the symlink; applies Omarchy's colorscheme at startup, else falls back to `rose-pine-moon` |
| `lua/config/omarchy_theme.lua` | Parses the generated spec into plugins plus the colorscheme name |
| `lua/plugins/lazyvim-disable.lua` | Disables the distro the marker entry would otherwise pull in |
| `lua/plugins/omarchy-theme-hotreload.lua` | The `LazyReload` handler in step 3 |
| `lua/plugins/all-themes.lua` | Declares every theme plugin either switcher might name, all `lazy = true`, so a swap never has to clone mid-session |
| `lua/config/statusline.lua` | Rebuilds its highlight groups from live ones on `ColorScheme` |
| `lua/config/opts.lua` | Holds `winborder`, which would otherwise be lost on every swap |
| `plugin/after/transparency.lua` | Reapplies transparency on `ColorScheme` rather than once at startup |

## Machines with no switcher

`lua/config/lazy.lua` falls back to `rose-pine-moon` when nothing names a
colorscheme, rather than leaving lazy's `habamax` install fallback in place. Any
switcher that writes `lua/plugins/theme.lua` takes over automatically, with no
edit here.

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

`lua/plugins/zen-theme.lua` loads on `VimEnter` so it applies after startup has
settled on a colorscheme, rather than racing it.

The two switchers coexist. There is no Omarchy on the mac, so no `theme.lua`
symlink is made and the `rose-pine-moon` fallback seeds a colorscheme; zen-theme
replaces it at VimEnter with whatever ZenTerm is wearing. On Linux there is no
ZenTerm, the plugin skips itself, and Omarchy's path is untouched.

## Testing a switch

lazy only starts its change detector when there is a UI, so `nvim --headless`
never reloads no matter what the spec does. Drive a real nvim (a pty is enough),
swap `~/.local/state/omarchy/current/theme`, and give it a few seconds.
