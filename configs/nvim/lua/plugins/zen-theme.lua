-- Follow ZenTerm's theme: picking one in ZenTerm recolors nvim to match.
--
-- Applied on VimEnter rather than by priority. LazyVim selects its colorscheme during
-- startup (rose-pine.lua's spec on this machine), and only VimEnter is reliably after
-- that, so this gets the last word instead of racing it.
--
-- Inert off ZenTerm: with no published theme file to read, setup() returns and every
-- colorscheme choice is left alone, so this spec is portable to the Linux machines.
return {
  {
    "praxis-labs-io/zen-theme.nvim",
    event = "VimEnter",
    opts = {},
  },
}
