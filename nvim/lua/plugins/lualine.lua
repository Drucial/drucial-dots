local function trunc(trunc_width, trunc_len, hide_width, max_length, no_ellipsis)
  return function(str)
    local win_width = vim.fn.winwidth(0)

    -- Always honor the max_length constraint
    if #str > max_length then
      return str:sub(1, max_length) .. (no_ellipsis and "" or "...")
    end

    -- Window size-based truncation
    if hide_width and win_width < hide_width then
      return ""
    elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
      return str:sub(1, trunc_len) .. (no_ellipsis and "" or "...")
    end

    return str
  end
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  opts = function()
    -- PERF: we don't need this lualine require madness 🤷
    local lualine_require = require("lualine_require")
    lualine_require.require = require

    local icons = LazyVim.config.icons

    vim.o.laststatus = vim.g.lualine_laststatus

    local opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        separators = {
          left = "",
          right = "",
        },
        component_separators = "",
        section_separators = "",
        disabled_filetypes = {
          statusline = {
            "dashboard",
            "alpha",
            "ministarter",
            "snacks_dashboard",
            "terminal",
            "snacks_terminal",
            "lazy", -- if you're using lazy.nvim
            "", -- this disables lualine for buffers with *no* filetype (like term:// sometimes)
          },
        },
        ignore_focus = {
          "lazy",
          "lazygit",
          "ministarter",
          "snacks_dashboard",
          "snacks_picker_input",
          "oil",
        },
      },

      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_b = {
          -- {
          --   function()
          --     local repo = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
          --     return repo
          --   end,
          --   icon = { "", align = "left" },
          --   fmt = trunc(80, 20, 60, 20),
          --   padding = { left = 1, right = 0 },
          -- },
          {
            "branch",
            fmt = trunc(80, 20, 60, 30), -- Adjust these values as needed
            padding = { left = 1, right = 1 },
          },
        },

        lualine_c = {
          LazyVim.lualine.root_dir(),
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { LazyVim.lualine.pretty_path(), padding = { left = 0, right = 0 }, color = { fg = "muted" } },
          -- {
          --   "filetype",
          --   icon_only = false, -- show full text
          --   colored = false, -- disable color if it's hard to read
          -- },
        },
        lualine_x = {
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },
        lualine_y = {
          -- { "progress", separator = " ", padding = { left = 1, right = 0 } },
          -- { "location", padding = { left = 0, right = 1 } },
        },
        lualine_z = {},
      },
      extensions = { "oil", "lazy", "fzf" },
    }

    return opts
  end,
}
