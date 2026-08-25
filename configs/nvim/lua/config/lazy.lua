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

-- Omarchy regenerates a LazyVim colorscheme spec on every `omarchy theme set`.
-- Link it into lua/plugins/ so lazy imports it as a normal spec: the link is
-- followed by lazy's change detection, so swapping themes fires LazyReload and
-- plugins/omarchy-theme-hotreload.lua applies it without restarting nvim.
-- Absent on non-Omarchy machines, in which case no link is made and the config
-- falls back to install.colorscheme below.
local uv = vim.uv or vim.loop
local omarchy_theme = vim.env.HOME .. "/.local/state/omarchy/current/theme/neovim.lua"
local theme_link = vim.fn.stdpath("config") .. "/lua/plugins/theme.lua"
if uv.fs_stat(omarchy_theme) and not uv.fs_lstat(theme_link) then
  uv.fs_symlink(omarchy_theme, theme_link)
end

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- add Extras
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  ui = {
    border = "rounded",
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- Every `omarchy theme set` rewrites theme.lua, which trips change detection.
  -- Reload, but without popping a "Config Change Detected" notification.
  change_detection = { notify = false },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
