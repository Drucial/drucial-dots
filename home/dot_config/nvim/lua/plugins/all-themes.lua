-- Every colorscheme plugin an Omarchy theme names, installed up front so a theme
-- switch never waits on a network clone.
return {
  -- Name and branch must match Omarchy's generated spec
  -- (default/themed/neovim.lua.tpl), or lazy builds a second copy under a
  -- different directory and the theme falls back until nvim restarts.
  {
    "omacom/aether.nvim",
    branch = "v3",
    name = "aether",
    lazy = true,
  },
  {
    "bjarneo/hackerman.nvim",
    lazy = true,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
  },
  {
    "neanias/everforest-nvim",
    lazy = true,
  },
  {
    "kepano/flexoki-neovim",
    lazy = true,
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
  },
  {
    "tahayvr/matteblack.nvim",
    lazy = true,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
  },
  {
    "ficcdaf/ashen.nvim",
    lazy = true,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
  },
  {
    "OldJobobo/retro-82.nvim",
    lazy = true,
  },
  {
    "omacom-io/lumon.nvim",
    lazy = true,
  },
}
