-- Git hunk visualization and staging. The `number` view colors the line number
-- rather than claiming a sign column, so it coexists with `signcolumn = "no"`.
-- Blame stays with snacks; mini.diff has no equivalent.
local function hunks(action)
  return function()
    local from, to = vim.fn.line("v"), vim.fn.line(".")
    require("mini.diff").do_hunks(0, action, {
      line_start = math.min(from, to),
      line_end = math.max(from, to),
    })
  end
end

return {
  "echasnovski/mini.diff",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    view = { style = "number" },
  },
  keys = {
    { "<leader>gh", hunks("apply"), mode = { "n", "x" }, desc = "Stage hunk" },
    { "<leader>gu", hunks("reset"), mode = { "n", "x" }, desc = "Reset hunk" },
    {
      "<leader>gp",
      function()
        require("mini.diff").toggle_overlay(0)
      end,
      desc = "Toggle diff overlay",
    },
  },
}
