-- nvim-surround reads its target character with getchar(), which which-key
-- cannot see. Enumerating the targets one level deep puts them in the menu
-- while keeping the underlying keystrokes identical to ds{char} / cs{char}.
local targets = {
  { "(", "( ... )" },
  { ")", "(...)" },
  { "{", "{ ... }" },
  { "}", "{...}" },
  { "[", "[ ... ]" },
  { "]", "[...]" },
  { "<", "< ... >" },
  { ">", "<...>" },
  { '"', '"..."' },
  { "'", "'...'" },
  { "`", "`...`" },
  { "t", "<tag>...</tag>" },
  { "T", "<tag attr>...</tag>" },
  { "f", "function(...)" },
  { "q", "any quote" },
  { "b", "any bracket" },
}

local keys = {
  { "<leader>sa", "<Plug>(nvim-surround-normal)", desc = "Surround motion" },
  { "<leader>sA", "<Plug>(nvim-surround-normal-cur)", desc = "Surround line" },
  { "<leader>sl", "<Plug>(nvim-surround-normal-line)", desc = "Surround motion on new lines" },
  { "<leader>sL", "<Plug>(nvim-surround-normal-cur-line)", desc = "Surround line on new lines" },
  { "<leader>ss", "<Plug>(nvim-surround-visual)", mode = "x", desc = "Surround selection" },
  { "<leader>sS", "<Plug>(nvim-surround-visual-line)", mode = "x", desc = "Surround selection on new lines" },
}

for _, target in ipairs(targets) do
  local char, label = target[1], target[2]
  keys[#keys + 1] = { "<leader>sd" .. char, "ds" .. char, remap = true, desc = label }
  keys[#keys + 1] = { "<leader>sc" .. char, "cs" .. char, remap = true, desc = label }
end

return {
  "kylechui/nvim-surround",
  version = "*",
  event = "VeryLazy",
  opts = {},
  keys = keys,
}
