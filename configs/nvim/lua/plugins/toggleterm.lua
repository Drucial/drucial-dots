return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    init = function()
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        pattern = "term://*",
        callback = function()
          if vim.bo.filetype == "toggleterm" then vim.cmd("startinsert") end
        end,
      })
    end,
    opts = {
      direction = "horizontal",
      size = function() return math.floor(vim.o.lines * 0.30) end,
      shade_terminals = false,
      start_in_insert = true,
      persist_size = true,
      persist_mode = false,
      auto_scroll = true,
      insert_mappings = true,
      terminal_mappings = true,
      on_open = function(term)
        vim.wo[term.window].number = false
        vim.wo[term.window].relativenumber = false
        vim.wo[term.window].signcolumn = "no"
        vim.wo[term.window].statusline = ""
        vim.wo[term.window].winbar = ""
        local opts = { buffer = term.bufnr, silent = true }
        vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], opts)
      end,
    },
    keys = {
      { [[<C-\>]], "<cmd>ToggleTerm<cr>", mode = { "n", "i", "v", "t" }, desc = "Toggle Terminal" },
      {
        "<leader>tn",
        function()
          local count = #require("toggleterm.terminal").get_all() + 1
          vim.cmd(count .. "ToggleTerm direction=horizontal")
        end,
        desc = "New Terminal",
      },
      { "<leader>tl", "<cmd>TermSelect<cr>", desc = "List Terminals" },
      { "<leader>tk", "<cmd>bdelete!<cr>", desc = "Kill Terminal", ft = "toggleterm" },
    },
  },
}
