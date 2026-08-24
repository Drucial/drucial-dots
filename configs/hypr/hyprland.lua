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

-- Pin Chromium to workspace 2. Matched in full, so Omarchy web apps
-- (class: chrome-<site>-Default) are not affected.
o.window("(google-)?[cC]hrom(e|ium)", { workspace = "2" })

-- Pin the ChatGPT desktop app (openai-codex-desktop) to workspace 3.
o.window("chatgpt", { workspace = "3" })
