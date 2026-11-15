vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- GUI launches (Neovide, Finder) never source the shell profile, so binaries
-- here would be missing from anything nvim spawns.
local local_bin = vim.fn.expand("~/.local/bin")
if not vim.env.PATH:find(local_bin, 1, true) then
  vim.env.PATH = local_bin .. ":" .. vim.env.PATH
end

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "no"
opt.fillchars:append({ eob = " " })
opt.breakindent = true
opt.swapfile = false

-- Set here rather than per-plugin so it survives theme switches.
opt.winborder = "rounded"

-- Themes disagree wildly on WinSeparator and several render it near the
-- background -- nord points it at its own background. Following FloatBorder
-- keeps split dividers and float borders the same weight. Note nvim has drawn
-- separators with WinSeparator since 0.7 -- overriding VertSplit does nothing.
local function win_separator()
  vim.api.nvim_set_hl(0, "WinSeparator", { link = "FloatBorder" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("win-separator", { clear = true }),
  callback = win_separator,
})
win_separator()

-- Live :s preview, with a split listing every affected line.
opt.inccommand = "split"

-- Default status bar
opt.laststatus = 3
opt.ruler = false
opt.showmode = false
opt.cmdheight = 0

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true

-- System clipboard
opt.clipboard = "unnamedplus"

-- Vertical context around the cursor. Not 999: a pinned cursor line makes zz,
-- zt and zb inert, so half-page scrolls re-center themselves in keymaps.lua.
opt.scrolloff = 8

-- Better horizontal scroll context
opt.sidescrolloff = 16

-- Silence all bells (no macOS funk sound on unmapped keys in neovide)
opt.belloff = "all"
opt.visualbell = false
