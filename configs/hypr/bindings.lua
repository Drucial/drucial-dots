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

-- ChatGPT desktop app (openai-codex-desktop). Omarchy's default binds the same
-- key to chatgpt.com as a chromium web app, and Hyprland fires the first bind
-- that matches, so this needs the unbind to win.
-- Pinned to workspace 3 in hyprland.lua.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "ChatGPT", { launch = "chatgpt", focus = "^chatgpt$" })

-- Claude desktop app. One key over from ChatGPT, sharing workspace 3 with it
-- (pinned in hyprland.lua). Takes the key Omarchy's "Calendar" (HEY) webapp had
-- before that webapp was removed, so it still needs the unbind to win.
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Claude",
  { launch = "claude-desktop", focus = "^com\\.anthropic\\.Claude$" })

-- Slack desktop app (was: Omarchy's default "Google Maps" webapp).
-- Pinned to workspace 6 in hyprland.lua.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Slack", { launch = "slack", focus = "^slack$" })

-- Superhuman, run as a chromium web app (was: Omarchy's default "Email"
-- webapp on app.hey.com). Pinned to workspace 4 in hyprland.lua.
-- Raw command string rather than { webapp = ..., focus = true }: that form uses
-- the description as the focus pattern, and "Superhuman" also matches the title
-- of an ordinary browser window with Superhuman open in a tab.
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Superhuman",
  "omarchy-launch-or-focus 'chrome-mail\\.superhuman\\.com.*-Default' 'omarchy-launch-webapp https://mail.superhuman.com'")

-- Linear web app (was: Omarchy's own binding on the same key, which always
-- opened a new window). Pinned to workspace 5 in hyprland.lua. Raw command
-- string rather than { webapp = ..., focus = true }: that form uses the
-- description as the focus pattern, and "Linear" also matches the title of an
-- ordinary browser window with Linear open in a tab.
hl.unbind("SUPER + SHIFT + L")
o.bind("SUPER + SHIFT + L", "Linear",
  "omarchy-launch-or-focus 'chrome-linear\\.app.*-Default' 'omarchy-launch-webapp https://linear.app'")

-- Web apps removed with `omarchy webapp remove`. Their launchers are gone, but
-- the bindings launch the URL directly, so they need unbinding too.
hl.unbind("SUPER + SHIFT + ALT + A") -- Grok
hl.unbind("SUPER + SHIFT + ALT + E") -- New email (HEY)
hl.unbind("SUPER + SHIFT + Y")       -- YouTube
hl.unbind("SUPER + SHIFT + ALT + G") -- WhatsApp
hl.unbind("SUPER + SHIFT + CTRL + G")-- Google Messages
hl.unbind("SUPER + SHIFT + P")       -- Google Photos
hl.unbind("SUPER + SHIFT + X")       -- X
hl.unbind("SUPER + SHIFT + ALT + X") -- X Post

-- Preinstalled apps uninstalled with `omarchy pkg drop`.
hl.unbind("SUPER + SHIFT + ALT + M") -- Music TUI (cliamp)
hl.unbind("SUPER + SHIFT + W")       -- Omawrite

-- zen-octo, a GitHub PR/issue TUI (was: Obsidian, uninstalled with
-- `omarchy pkg drop`). Left tiled rather than floated: it's a work surface you
-- sit in, not a panel you glance at. Its app-id is org.omarchy.zen-octo, so the
-- Ghostty workspace-1 rule in hyprland.lua doesn't pin it.
hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "GitHub TUI", { tui = "zen-octo", focus = true })

-- btop (was: SUPER + CTRL + T, Omarchy's "Activity"). Moved onto the same
-- SUPER + SHIFT + <letter> row as the other TUIs. Resized in hyprland.lua.
hl.unbind("SUPER + CTRL + T")
o.bind("SUPER + SHIFT + T", "Activity",
  "omarchy-launch-or-focus-tui --app-id=TUI.btop btop")

-- zen-linear, a Linear TUI. One modifier off the Linear web app above, rather
-- than on the SUPER + SHIFT + <letter> row the other TUIs share: SUPER + SHIFT
-- + L belongs to the web app. Floated in hyprland.lua.
o.bind("SUPER + SHIFT + ALT + L", "Linear TUI", { tui = "zen-linear", focus = true })

-- zen-notes, a notes TUI (was: Omarchy's "Editor", i.e. `omarchy-launch-editor`
-- with no path -- it always opened nvim in ~, never the cwd, so nothing is lost
-- by taking the key). Floated in hyprland.lua.
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Notes TUI", { tui = "zen-notes", focus = true })

-- Docker TUI (was: the same lazydocker launcher, tiled). Given its own app-id
-- rather than Omarchy's shared TUI.float: this binding focuses by app-id, and a
-- shared one would cross-match any other floating TUI. Floated in hyprland.lua.
-- Raw command string rather than { tui = ... }: that form shell-quotes the whole
-- value as one argument, which would swallow the --app-id flag.
hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Docker",
  "omarchy-launch-or-focus-tui --app-id=TUI.docker omarchy-launch-docker-tui")

-- Spotify (was: Omarchy's default "Music", which launches spotify but does
-- not focus an existing window). Pinned to workspace 10 in hyprland.lua.
-- The focus pattern is matched case-insensitively, so the capitalized class
-- still resolves.
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Spotify", { launch = "spotify", focus = "^spotify$" })
