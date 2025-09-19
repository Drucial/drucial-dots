-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
-- vim.g.copilot_no_tab_map = true
-- vim.g.copilot_assume_mapped = true
-- vim.g.ai_cmp = true -- enables ghost_text in LazyVim default cmp setup

local opt = vim.opt
-- Show which line your cursor is on
opt.cursorline = true
opt.termguicolors = true -- Enable 24-bit RGB colors in the TUI

-- Minimal number of screen lines to keep above and below the cursor.
opt.scrolloff = 16
