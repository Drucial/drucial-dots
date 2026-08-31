-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Scaling is per-machine, so it is not committed here. A machine that needs
-- something other than the defaults below drops a table at
-- ~/.local/state/hypr/machine.lua returning { gdk_scale = N, monitor_scale = N }.
-- That path is first on Omarchy's Lua module path and sits outside this repo,
-- so a clone on another machine just gets the defaults.
local require_optional = require("default.hypr.require_optional")
local machine = require_optional.module("hypr.machine") or {}

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
