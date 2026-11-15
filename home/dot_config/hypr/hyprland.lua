dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

require("default.hypr.toggles")

o.window("com\\.mitchellh\\.ghostty", { workspace = "1" })
o.window("herdr-app", { workspace = "1" })
o.window("chromium", { workspace = "2" })
o.window("com\\.anthropic\\.Claude", { workspace = "3" })
o.window("chatgpt", { workspace = "3" })
o.window("chrome-mail\\.superhuman\\.com__.*", { workspace = "4" })
o.window("chrome-calendar\\.notion\\.so__.*", { workspace = "4" })
o.window("chrome-linear\\.app__.*", { workspace = "5" })
o.window("chrome-discord\\.com__.*", { workspace = "6" })
o.window("chrome-x\\.com__.*", { workspace = "6" })
o.window("[Ss]potify", { workspace = "7" })
o.window("chrome-youtube\\.com__.*", { workspace = "8" })

-- Tagged as a terminal so universal copy/paste sends Ctrl+Shift+C/V.
o.window("herdr-app", { tag = "+terminal" })
