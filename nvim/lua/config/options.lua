-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

local local_bin = vim.fn.expand("~/.local/bin")
if not vim.env.PATH:find(local_bin, 1, true) then
  vim.env.PATH = local_bin .. ":" .. vim.env.PATH
end

-- Centered cursor (keeps cursor in middle of screen)
opt.scrolloff = 999

-- Better horizontal scroll context
opt.sidescrolloff = 16

-- Show substitution preview in split window
opt.inccommand = "split"

-- Hide command line when not in use (cleaner UI with Noice)
opt.cmdheight = 0

-- Better treesitter-based folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99 -- Start with all folds open

-- Disable swapfiles (optional - remove if you prefer swapfiles)
opt.swapfile = false

-- Better wrapped line indentation
opt.breakindent = true

-- Silence all bells (no macOS funk sound on unmapped keys in neovide)
opt.belloff = "all"
opt.visualbell = false
