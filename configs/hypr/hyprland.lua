-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Pin Ghostty terminals to workspace 1.
-- Omarchy's TUI wrappers use their own app-ids (org.omarchy.*, TUI.*), so
-- floating tools like btop are unaffected by this.
o.window("com\\.mitchellh\\.ghostty", { workspace = "1" })

-- Pin browsers to workspace 2. Matched in full, so Omarchy web apps
-- (class: chrome-<site>-Default) are not affected.
o.window("zen", { workspace = "2" })
o.window("(google-)?[cC]hrom(e|ium)", { workspace = "2" })

-- Pin the ChatGPT desktop app (openai-codex-desktop) to workspace 3.
-- Reports a lowercase app-id, despite its .desktop declaring no StartupWMClass.
o.window("chatgpt", { workspace = "3" })

-- Pin the Claude desktop app to workspace 3 as well, alongside ChatGPT.
-- Reports the app-id its .desktop declares as StartupWMClass, unlike ChatGPT.
o.window("com\\.anthropic\\.Claude", { workspace = "3" })

-- Pin the Superhuman web app to workspace 4. Chromium derives the app-id from
-- the URL, so a compose/mailto window gets a different suffix than the inbox
-- one -- match any of them.
o.window("chrome-mail\\.superhuman\\.com.*-Default", { workspace = "4" })

-- Pin the Slack desktop app to workspace 6. The Wayland app-id is lowercase
-- "slack", not the "Slack" its .desktop declares as StartupWMClass.
o.window("slack", { workspace = "6" })

-- Pin Spotify to workspace 10. Reports a capitalized class, unlike the other
-- desktop apps here.
o.window("[sS]potify", { workspace = "10" })

-- Pin the Linear web app to workspace 5.
o.window("chrome-linear\\.app.*-Default", { workspace = "5" })

-- Float the zen TUIs (SUPER + SHIFT + O, N, and L).
-- Spelled out rather than tagged "+floating-window": this file loads after the
-- default rules that consume that tag, so tagging here would never match. They
-- also can't reuse the TUI.float app-id the Docker TUI uses -- their bindings
-- focus an existing window by app-id, and a shared one would cross-match.
o.window("org\\.omarchy\\.zen-(octo|notes|linear)", { float = true })
o.window("org\\.omarchy\\.zen-(octo|notes|linear)", { center = true })
o.window("org\\.omarchy\\.zen-(octo|notes|linear)", { size = { 1100, 750 } })

-- Bigger btop (SUPER + SHIFT + T). Its binding gives it the app-id TUI.btop
-- rather than the default org.omarchy.btop, so Omarchy's floating-window rules
-- no longer match it and its 875x600 stops winning -- that size held whether
-- this rule was declared before or after the defaults. Screen is 1536x960
-- logical, so this leaves a margin for the bar.
o.window("TUI\\.btop", { float = true })
o.window("TUI\\.btop", { center = true })
o.window("TUI\\.btop", { size = { 1400, 860 } })

-- Docker TUI (SUPER + SHIFT + D). Moved off Omarchy's shared TUI.float app-id so
-- its binding can focus by app-id without cross-matching, which also means the
-- TUI.float float rules no longer cover it. Same 875x600 those rules gave it.
o.window("TUI\\.docker", { float = true })
o.window("TUI\\.docker", { center = true })
o.window("TUI\\.docker", { size = { 875, 600 } })
