return {
  "kylechui/nvim-surround",
  version = "*",
  event = "VeryLazy",
  opts = {
    keymaps = {
      insert = "<C-g>s",
      insert_line = "<C-g>S",
      normal = "<leader>cea", -- surround motion
      normal_cur = "<leader>ceA", -- surround current line
      normal_line = "<leader>cel", -- surround motion on new lines
      normal_cur_line = "<leader>ceL", -- surround current line on new lines
      visual = "<leader>ces", -- visual mode surround
      visual_line = "<leader>ceS", -- visual mode surround with new lines
      delete = "<leader>ced", -- delete surround
      change = "<leader>cec", -- change surround
      change_line = "<leader>ceC", -- change surround with new lines
    },
  },
}
