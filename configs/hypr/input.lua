-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

-- Caps Lock acts as an extra Control. Omarchy's default puts Compose on Caps,
-- so that goes away; both Shifts together still toggles real Caps Lock (and a
-- lone Shift cancels it, so an accidental trigger clears itself).
hl.config({
  input = {
    kb_options = "ctrl:nocaps,shift:both_capslock_cancel",
  },
})

-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Workspace swipe feel. Defaults noted; uncomment to tune.
hl.config({
  gestures = {
    -- Follow the fingers the way macOS does (Hyprland default: true).
    workspace_swipe_invert = false,

    -- Overshooting the last workspace shouldn't strand you on a new empty one
    -- (default: true).
    workspace_swipe_create_new = false,

    -- Travel in px for a full workspace (default: 300). Lower = more sensitive.
    -- workspace_swipe_distance = 300,

    -- Fraction of that travel needed to commit rather than snap back
    -- (default: 0.5). Lower = commits more eagerly.
    workspace_swipe_cancel_ratio = 0.3,

    -- Flick speed that commits regardless of distance (default: 30).
    -- 0 disables flicks, so distance alone decides.
    -- workspace_swipe_min_speed_to_force = 30,
  },
})

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })
