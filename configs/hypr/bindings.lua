-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Focus an already-open window instead of spawning a second instance.
-- The `focus` pattern is matched against window class and title.
-- Terminal, incognito, and "open at cwd" bindings are deliberately left alone:
-- those should always give you a new window.

-- Terminal (was: omarchy-launch-terminal, which always opened a new window).
-- Ghostty is pinned to ws 1, so spawning from another workspace just stacked a
-- second window there. New windows come from Ghostty itself: Ctrl+Shift+N (and
-- Ctrl+Shift+T for a tab), both of which inherit the cwd the same way
-- omarchy-launch-terminal did -- window-inherit-working-directory is on.
-- Raw command string, not { omarchy = ..., focus = ... }: helpers.lua returns on
-- value.omarchy before it checks focus, so that form silently drops the focus.
hl.unbind("SUPER + RETURN")
o.bind("SUPER + RETURN", "Terminal",
  "omarchy-launch-or-focus '^com\\.mitchellh\\.ghostty$' 'omarchy-launch-terminal'")

-- Browser (was: omarchy-launch-browser, which always opened a new window).
-- Zen is the default browser (xdg-settings), pinned to workspace 2 in hyprland.lua.
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Browser", { launch = "zen-browser", focus = "^zen$" })

hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + SHIFT + B", "Browser", { launch = "zen-browser", focus = "^zen$" })

-- File manager (was: omarchy-launch-nautilus, i.e. `nautilus --new-window`)
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "nautilus", focus = "^org\\.gnome\\.Nautilus$" })

-- ChatGPT desktop app. SUPER+SHIFT+A is Omarchy's default key for ChatGPT, but
-- as a web app -- that binding is inactive here since preinstalls were removed,
-- so no unbind is needed. Pinned to workspace 3 in hyprland.lua.
o.bind("SUPER + SHIFT + A", "ChatGPT", { launch = "chatgpt", focus = "^chatgpt$" })

-- Slack desktop app. Pinned to workspace 6 in hyprland.lua.
o.bind("SUPER + SHIFT + S", "Slack", { launch = "slack", focus = "^slack$" })

-- Superhuman, run as a chromium web app. Pinned to workspace 4 in hyprland.lua.
-- Raw command string rather than { webapp = ..., focus = true }: that form uses
-- the description as the focus pattern, and "Superhuman" also matches the title
-- of an ordinary browser window with Superhuman open in a tab.
o.bind("SUPER + SHIFT + E", "Superhuman",
  "omarchy-launch-or-focus 'chrome-mail\\.superhuman\\.com.*-Default' 'omarchy-launch-webapp https://mail.superhuman.com'")

-- Linear, run as a chromium web app. Pinned to workspace 5 in hyprland.lua.
-- Same raw-command form as Superhuman, for the same reason.
o.bind("SUPER + SHIFT + L", "Linear",
  "omarchy-launch-or-focus 'chrome-linear\\.app.*-Default' 'omarchy-launch-webapp https://linear.app'")
