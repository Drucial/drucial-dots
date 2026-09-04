-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Omarchy rewrites its theme spec on every `omarchy theme set`. Link it into
-- lua/plugins/ so lazy imports it and its change detector fires LazyReload on a
-- switch. Created here rather than committed: the target is absent off Omarchy,
-- where a dangling link breaks the `plugins` import.
local omarchy = require("config.omarchy_theme")
local uv = vim.uv or vim.loop
local theme_link = vim.fn.stdpath("config") .. "/lua/plugins/theme.lua"
if uv.fs_stat(omarchy.path) and not uv.fs_lstat(theme_link) then
  uv.fs_symlink(omarchy.path, theme_link)
end

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})

-- Off Omarchy nothing names a colorscheme at startup, so fall back. zen-theme.nvim
-- still gets the last word on VimEnter when ZenTerm publishes one.
local _, colorscheme = omarchy.read()
if not (colorscheme and pcall(vim.cmd.colorscheme, colorscheme)) then
  pcall(vim.cmd.colorscheme, "rose-pine-moon")
end
