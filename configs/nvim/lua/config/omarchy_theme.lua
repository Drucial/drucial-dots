-- Reads Omarchy's published theme spec, which names the colorscheme through a
-- LazyVim marker entry this config does not otherwise use.

local M = {}

M.path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

---@return table plugins, string? colorscheme
function M.read()
  local ok, spec = pcall(dofile, M.path)
  if not ok or type(spec) ~= "table" then
    return {}, nil
  end

  local plugins, colorscheme = {}, nil
  for _, entry in ipairs(spec) do
    if entry[1] == "LazyVim/LazyVim" then
      colorscheme = entry.opts and entry.opts.colorscheme
    else
      plugins[#plugins + 1] = entry
    end
  end
  return plugins, colorscheme
end

return M
