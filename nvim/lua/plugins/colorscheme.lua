return { -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  -- {
  --   'folke/tokyonight.nvim',
  --   priority = 1000, -- Make sure to load this before all the other start plugins.
  --   config = function()
  --     ---@diagnostic disable-next-line: missing-fields
  --     require('tokyonight').setup {
  --       styles = {
  --         comments = { italic = false }, -- Disable italics in comments
  --       },
  --     }
  --
  --     vim.cmd.colorscheme 'tokyonight-night' -- 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
  --   end,
  -- },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        variant = "moon", -- auto, main, moon, or dawn
        dark_variant = "main", -- main, moon, or dawn
        dim_inactive_windows = false,
        extend_background_behind_borders = true,

        enable = {
          terminal = true,
          legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
          migrations = true, -- Handle deprecated options automatically
        },

        styles = {
          italic = false,
        },

        -- NOTE: Highlight groups are extended (merged) by default. Disable this
        -- per group via `inherit = false`
        highlight_groups = {
          VertSplit = { fg = "muted", bg = "muted" },
          HorizSplit = { fg = "muted", bg = "muted" },
          NormalFloat = { bg = "none" },
          FloatBorder = { fg = "muted", bg = "none" },
          AvanteSidebarWinSeparator = { fg = "muted" },
          AvanteSidebarWinHorizontalSeparator = { fg = "muted" },
          SnacksIndent = {
            fg = "highlight_low",
          },

          Pmenu = { fg = "text", bg = "none", inherit = false },
          PmenuSel = { fg = "text", bg = "highlight_med", inherit = false },
          
          -- Blink.cmp specific highlights
          BlinkCmpMenu = { fg = "text", bg = "none" },
          BlinkCmpMenuBorder = { fg = "muted", bg = "none" },
          BlinkCmpMenuSelection = { fg = "text", bg = "highlight_med" },
          BlinkCmpLabel = { fg = "text" },
          BlinkCmpLabelMatch = { fg = "iris", bold = true },
          BlinkCmpKind = { fg = "foam" },
        },

        before_highlight = function(group, highlight, palette)
          -- Disable all undercurls
          -- if highlight.undercurl then
          --     highlight.undercurl = false
          -- end
          --
          -- Change palette colour
          -- if highlight.fg == palette.pine then
          --     highlight.fg = palette.foam
          -- end
        end,
      })

      vim.cmd("colorscheme rose-pine-moon")
    end,
  },
}
