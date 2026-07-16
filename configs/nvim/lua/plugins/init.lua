-- init.lua
return {
  -- Replaced by zen-navigator.nvim (ZenTerm-native seamless nav).
  -- {
  --   "knubie/vim-kitty-navigator",
  -- },
  {
    "Drucial/zen-navigator.nvim",
    event = "VeryLazy",
    -- Keymaps live in lua/config/keymaps.lua (normal + terminal), so the plugin only
    -- wires the VimEnter/VimLeave "is-vim" autocmds here.
    opts = { default_mappings = false },
  },
}
