hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.config({
  gestures = {
    workspace_swipe_invert = false,
    workspace_swipe_create_new = false,
    workspace_swipe_cancel_ratio = 0.3,
    workspace_swipe_direction_lock = false,
  },
})

hl.config({
  input = {
    kb_options = "ctrl:nocaps",
    follow_mouse = 0,
    touchpad = {
      tap_to_click = false,
    },
  },
})
