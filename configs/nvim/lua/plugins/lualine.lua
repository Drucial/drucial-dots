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

-- Pull a foreground color off the first highlight group that defines one.
-- Returns a function so lualine re-resolves it on every draw: Omarchy theme
-- switches then repaint the statusline without a restart, which a fixed palette
-- table (rose-pine's, previously) could not do.
local function hl_fg(...)
  local names = { ... }
  return function()
    for _, name in ipairs(names) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
      if ok and hl.fg then
        return { fg = string.format("#%06x", hl.fg) }
      end
    end
    return {}
  end
end

local accent = hl_fg("Function", "Identifier", "Special")
local alt_accent = hl_fg("Statement", "Keyword", "Function")
local muted = hl_fg("Comment", "NonText")

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
            color = accent,
          },
        },

        lualine_c = {
          {
            function()
              return "●"
            end,
            cond = function()
              local ok, claudecode = pcall(require, "claudecode")
              if not ok or type(claudecode.is_claude_connected) ~= "function" then
                return false
              end
              local connected = false
              pcall(function()
                connected = claudecode.is_claude_connected()
              end)
              return connected
            end,
            padding = { left = 1, right = 0 },
            color = alt_accent,
          },
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
            color = muted,
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
            color = muted,
          },
          {
            "filename",
            path = 0, -- Just the filename, no path
            padding = { left = 1, right = 1 },
            color = muted,
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
            color = accent,
          },
        },
        lualine_y = {
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
            color = muted,
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
