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

-- Browser (was: omarchy-launch-browser, which always opened a new window)
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Browser", { launch = "chromium", focus = "^chromium$" })

hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + SHIFT + B", "Browser", { launch = "chromium", focus = "^chromium$" })

-- File manager (was: omarchy-launch-nautilus, i.e. `nautilus --new-window`)
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "nautilus", focus = "^org\\.gnome\\.Nautilus$" })

-- ChatGPT desktop app. SUPER+SHIFT+A is Omarchy's default key for ChatGPT, but
-- as a web app -- that binding is inactive here since preinstalls were removed,
-- so no unbind is needed. Pinned to workspace 3 in hyprland.lua.
o.bind("SUPER + SHIFT + A", "ChatGPT", { launch = "chatgpt", focus = "^chatgpt$" })
