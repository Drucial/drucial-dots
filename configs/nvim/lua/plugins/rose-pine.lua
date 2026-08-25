-- Personal tuning for rose-pine. Deliberately does NOT apply a colorscheme:
-- Omarchy owns that via the generated lua/plugins/theme.lua, and these opts only
-- take effect when it selects a Rose Pine theme. `variant` is omitted for the
-- same reason — the colorscheme name (rose-pine-moon / -dawn) picks it.
--
-- Off Omarchy (the mac) that generated spec does not exist, so nothing would
-- select a colorscheme at all and LazyVim would fall back to its own default,
-- tokyonight. Select rose-pine-moon there instead. The check mirrors the
-- symlink lua/config/lazy.lua creates, and runs before lazy resolves specs.
local uv = vim.uv or vim.loop
local omarchy_theme = uv.fs_stat(vim.fn.stdpath("config") .. "/lua/plugins/theme.lua") ~= nil

return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    priority = 1000,
    opts = {
      extend_background_behind_borders = true,
      enable = {
        terminal = true,
        legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
        migrations = true, -- Handle deprecated options automatically
      },

      styles = {
        bold = true,
        italic = true,
        transparency = true,
      },

      groups = {
        border = "muted",
        link = "iris",
        panel = "surface",

        error = "love",
        hint = "iris",
        info = "foam",
        note = "pine",
        todo = "rose",
        warn = "gold",

        git_add = "foam",
        git_change = "rose",
        git_delete = "love",
        git_dirty = "rose",
        git_ignore = "muted",
        git_merge = "iris",
        git_rename = "pine",
        git_stage = "iris",
        git_text = "rose",
        git_untracked = "subtle",

        h1 = "iris",
        h2 = "foam",
        h3 = "rose",
        h4 = "gold",
        h5 = "pine",
        h6 = "foam",
      },
      highlight_groups = {
        Comment = { fg = "muted" },
        VertSplit = { fg = "muted", bg = "muted" },
        SnacksIndent = { fg = "highlight_low" },
        StatusLineTerm = { bg = "none" }, -- hide terminal statusline background
        SnacksDashboardHeader = { fg = "muted" },
        SnacksDashboardFooter = { fg = "muted" },
        SnacksDashboardDesc = { fg = "muted" },
        SnacksDashboardIcon = { fg = "muted" },
        SnacksDashboardKey = { fg = "muted" },
      },
    },
  },

  -- Only when Omarchy is not driving the theme: leaving this spec out entirely
  -- there keeps it from merging with, and overriding, the generated one.
  not omarchy_theme and {
    "LazyVim/LazyVim",
    opts = { colorscheme = "rose-pine-moon" },
  } or nil,
}
