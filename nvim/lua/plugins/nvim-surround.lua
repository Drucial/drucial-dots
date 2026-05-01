return {
  "kylechui/nvim-surround",
  version = "*",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<leader>cea", desc = "Surround motion" },
    { "<leader>ceA", desc = "Surround current line" },
    { "<leader>cel", desc = "Surround motion on new lines" },
    { "<leader>ceL", desc = "Surround current line on new lines" },
    { "<leader>ces", mode = "v", desc = "Visual surround" },
    { "<leader>ceS", mode = "v", desc = "Visual surround with new lines" },
    { "<leader>ced", desc = "Delete surround" },
    { "<leader>cec", desc = "Change surround" },
    { "<leader>ceC", desc = "Change surround with new lines" },
  },
  config = function()
    require("nvim-surround").setup()

    vim.keymap.set("n", "<leader>cea", "<Plug>(nvim-surround-normal)", { desc = "Surround motion" })
    vim.keymap.set("n", "<leader>ceA", "<Plug>(nvim-surround-normal-cur)", { desc = "Surround current line" })
    vim.keymap.set("n", "<leader>cel", "<Plug>(nvim-surround-normal-line)", { desc = "Surround motion on new lines" })
    vim.keymap.set("n", "<leader>ceL", "<Plug>(nvim-surround-normal-cur-line)", { desc = "Surround current line on new lines" })
    vim.keymap.set("x", "<leader>ces", "<Plug>(nvim-surround-visual)", { desc = "Visual surround" })
    vim.keymap.set("x", "<leader>ceS", "<Plug>(nvim-surround-visual-line)", { desc = "Visual surround with new lines" })
    vim.keymap.set("n", "<leader>ced", "<Plug>(nvim-surround-delete)", { desc = "Delete surround" })
    vim.keymap.set("n", "<leader>cec", "<Plug>(nvim-surround-change)", { desc = "Change surround" })
    vim.keymap.set("n", "<leader>ceC", "<Plug>(nvim-surround-change-line)", { desc = "Change surround with new lines" })
  end,
}
