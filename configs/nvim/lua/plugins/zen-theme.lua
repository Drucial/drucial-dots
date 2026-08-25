-- Follow ZenTerm's theme: picking one in ZenTerm recolors nvim to match.
--
-- Applied on VimEnter rather than by priority. LazyVim selects its colorscheme during
-- startup (rose-pine.lua's spec on this machine), and only VimEnter is reliably after
-- that, so this gets the last word instead of racing it.
--
-- Pointed at the local clone and skipped when it is absent, so a machine without it
-- starts clean rather than failing to clone. Swap to "zen-term/zen-theme.nvim" once the
-- repo is public.
local uv = vim.uv or vim.loop
local dir = vim.env.HOME .. "/Dev/zen-theme.nvim"

if not uv.fs_stat(dir) then
  return {}
end

return {
  {
    "zen-theme.nvim",
    dir = dir,
    event = "VimEnter",
    opts = {},
  },
}
