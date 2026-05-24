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

    -- Get rose-pine colors
    local palette = require("rose-pine.palette")

    -- Custom icons (replacing LazyVim.config.icons)
    local icons = {
      git = {
        added = "+",
        modified = "~",
        removed = "-",
      },
    }

    vim.o.laststatus = vim.g.lualine_laststatus

    local opts = {
      options = {
        -- theme = "auto",
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
            -- "terminal",
            -- "snacks_terminal",
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
          {
            function()
              return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            end,
            padding = { left = 1, right = 1 },
            color = { fg = palette.rose },
          },
        },

        lualine_c = {
          {
            function()
              -- Show terminal process in terminal mode
              if vim.bo.buftype == "terminal" then
                local term_name = vim.fn.expand("%:t")
                -- Extract process name from terminal buffer name (e.g., "term://...//12345:/bin/zsh")
                local process = term_name:match(":([^:]+)$") or term_name
                return "~" .. process
              end
              local filepath = vim.fn.expand("%:.:h")
              return filepath == "." and "" or filepath .. "/"
            end,
            padding = { left = 1, right = 1 },
            color = { fg = palette.muted },
          },
          {
            function()
              -- Hide arrow in terminal mode
              if vim.bo.buftype == "terminal" then
                return ""
              end
              return "→"
            end,
            padding = { left = 0, right = 0 },
            color = { fg = palette.muted },
          },
          {
            "filename",
            path = 0, -- Just the filename, no path
            padding = { left = 1, right = 1 },
            color = { fg = palette.muted },
            cond = function()
              -- Hide filename in terminal mode
              return vim.bo.buftype ~= "terminal"
            end,
          },
        },
        lualine_x = {
          {
            "branch",
            icon = { "" },
            fmt = trunc(80, 20, 60, 30), -- Adjust these values as needed
            padding = { left = 1, right = 1 },
            color = { fg = palette.rose },
          },
        },
        lualine_y = {
          {
            function()
              local ok, claudecode = pcall(require, "claudecode")
              if not ok or type(claudecode.is_claude_connected) ~= "function" then
                return ""
              end
              local connected = false
              pcall(function()
                connected = claudecode.is_claude_connected()
              end)
              return connected and "● Claude" or ""
            end,
            padding = { left = 1, right = 1 },
            color = { fg = palette.iris or palette.rose },
          },
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
            color = { fg = palette.muted },
          },
        },
        lualine_z = {
          {
            function()
              return "⌥"
            end,
            padding = { left = 1, right = 1 },
          },
        },
      },
      extensions = { "oil", "lazy", "fzf" },
    }

    return opts
  end,
}
