hl.config({
  general = {
    gaps_in = 12,
    gaps_out = 24,
    border_size = 2,
    layout = "scrolling",
  },
})

hl.config({
  decoration = {
    rounding = 12,
    dim_inactive = true,
    dim_strength = 0.15,
  },
})

hl.config({
  scrolling = {
    column_width = 0.97,
  },
})

-- Omarchy ships workspace animation off. In the scrolling layout, off-screen
-- windows can briefly flash into an empty workspace during the slide.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slide" })
