return {
  -- Load all theme plugins but don't apply them
  -- This ensures all colorschemes are available for hot-reloading
  --
  -- Omarchy 4 generates most theme specs from default/themed/neovim.lua.tpl on
  -- top of aether, so the single-theme plugins below (ethereal, vantablack,
  -- white, monokai-pro, miasma) are only reached by Omarchy 3.8, which ships a
  -- neovim.lua per theme. Keep them until 3.8 is out of support.
  {
    "ribru17/bamboo.nvim",
    lazy = true,
  },
  -- Name and branch must match Omarchy 4's generated theme spec
  -- (default/themed/neovim.lua.tpl). lazy merges specs by url and lets an
  -- explicit name rename the merged plugin, so a bare "bjarneo/aether.nvim"
  -- here builds the cache into lazy/aether.nvim while every aether-themed
  -- Omarchy 4 install renames it to lazy/aether at runtime -- a directory the
  -- package never shipped. That cost a network clone on first launch, and the
  -- theme fell back to tokyonight until nvim was restarted.
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    lazy = true,
  },
  {
    "bjarneo/ethereal.nvim",
    lazy = true,
  },
  {
    "bjarneo/hackerman.nvim",
    lazy = true,
  },
  {
    "bjarneo/vantablack.nvim",
    lazy = true,
  },
  {
    "bjarneo/white.nvim",
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
    "gthelding/monokai-pro.nvim",
    lazy = true,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
  },
  -- ZenTerm's catalog names these three and Omarchy never did, so they arrive with
  -- zen-theme.nvim rather than with a theme switcher.
  {
    "shaunsingh/nord.nvim",
    lazy = true,
  },
  {
    "Mofiqul/dracula.nvim",
    lazy = true,
  },
  {
    "maxmx03/solarized.nvim",
    lazy = true,
  },
  -- Families ZenTerm's catalog added alongside zen-theme.nvim.
  -- Zenbones is Lush-based, but lush.nvim is optional: compat mode uses the precompiled
  -- colorschemes instead, which is all we need since ZenTerm names them directly.
  {
    "zenbones-theme/zenbones.nvim",
    lazy = true,
    init = function()
      vim.g.zenbones_compat = 1
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = true,
  },
  {
    "webhooked/kanso.nvim",
    lazy = true,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
  },
  {
    "cocopon/iceberg.vim",
    lazy = true,
  },
  {
    "nanotech/jellybeans.vim",
    lazy = true,
  },
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = true,
  },
  {
    "savq/melange-nvim",
    name = "melange",
    lazy = true,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    -- Its rockspec pulls fennel to compile fnl/, but the repo ships the
    -- built lua/ and colors/. Skip the luarocks build lazy infers from it.
    build = false,
    lazy = true,
  },
  {
    "datsfilipe/vesper.nvim",
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
    "OldJobobo/miasma.nvim",
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
