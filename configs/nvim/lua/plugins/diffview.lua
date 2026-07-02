return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
  keys = {
    {
      "<leader>gd",
      function()
        local file = vim.fn.expand("%")
        if file == "" then
          vim.notify("No file in current buffer", vim.log.levels.WARN)
          return
        end
        vim.cmd("DiffviewOpen -- " .. vim.fn.fnameescape(file))
        vim.cmd("DiffviewToggleFiles")
      end,
      desc = "Diff: current file vs HEAD",
    },
    {
      "<leader>gD",
      function()
        local base = vim.fn.systemlist("git symbolic-ref refs/remotes/origin/HEAD")[1]
        base = base and base:gsub("^refs/remotes/", "") or "origin/main"
        vim.cmd("DiffviewOpen " .. base .. "...HEAD")
      end,
      desc = "Diff: branch vs main",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diff: current file history" },
    { "<leader>gC", "<cmd>DiffviewClose<cr>", desc = "Diff: close" },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      default = { layout = "diff2_horizontal" },
      merge_tool = { layout = "diff3_mixed" },
      file_history = { layout = "diff2_horizontal" },
    },
    file_panel = {
      listing_style = "tree",
      win_config = { position = "left", width = 35 },
    },
  },
}
