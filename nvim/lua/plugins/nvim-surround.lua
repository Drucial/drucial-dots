return {
  "kylechui/nvim-surround",
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({
      keymaps = {
        insert = "<C-g>s",
        insert_line = "<C-g>S",
        normal = "<leader>ya", -- surround motion
        normal_cur = "<leader>yA", -- surround current line
        normal_line = "<leader>yl", -- surround motion on new lines
        normal_cur_line = "<leader>yL", -- surround current line on new lines
        visual = "<leader>ys", -- visual mode surround
        visual_line = "<leader>yS", -- visual mode surround with new lines
        delete = "<leader>yd", -- delete surround
        change = "<leader>yc", -- change surround
        change_line = "<leader>yC", -- change surround with new lines
      },
    })

    local wk = require("which-key")

    wk.add({
      { "<leader>ya", desc = "Surround motion", mode = "n" },
      { "<leader>yA", desc = "Surround current line", mode = "n" },
      { "<leader>yl", desc = "Surround motion on new lines", mode = "n" },
      { "<leader>yL", desc = "Surround current line on new lines", mode = "n" },

      -- Visual surround
      { "<leader>ys", desc = "Visual surround", mode = "v" },
      { "<leader>yS", desc = "Visual surround with new lines", mode = "v" },
      { "<leader>yst", desc = "Surround with tag", mode = "v" },
      { "<leader>ysf", desc = "Surround with function", mode = "v" },
      { "<leader>ySt", desc = "Surround with tag (new lines)", mode = "v" },
      { "<leader>ySf", desc = "Surround with function (new lines)", mode = "v" },

      -- Delete
      { "<leader>yd", desc = "Delete surround", mode = "n" },
      { "<leader>ydt", desc = "Delete tag", mode = "n" },
      { "<leader>ydf", desc = "Delete function call", mode = "n" },

      -- Change
      { "<leader>yc", desc = "Change surround", mode = "n" },
      { "<leader>yC", desc = "Change surround with new lines", mode = "n" },
      { "<leader>yct", desc = "Change tag", mode = "n" },
      { "<leader>ycT", desc = "Change entire tag", mode = "n" },
      { "<leader>ycf", desc = "Change function", mode = "n" },

      -- Group label (only one for <leader>y)
      { "<leader>y", group = "Surround" },
    })
  end,
}
