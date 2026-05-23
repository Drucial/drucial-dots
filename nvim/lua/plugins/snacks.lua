return {
  {
    "folke/snacks.nvim",
    opts = {
      -- bigfile = { enabled = true },
      -- gitbrowse = { enabled = true },
      indent = {
        enabled = true,
        only_scope = true, -- only show indent guides of the scope
        only_current = true, -- only show indent guides in the current window
      },
      -- scroll = { enabled = true },
      -- image = { enabled = true },
      picker = {
        enabled = true,
        hidden = true,
        sources = {
          files = {
            hidden = true,
            ignored = true,
            exclude = {
              "**/.git/*",
              "**/node_modules/*",
              "**/dist/*",
              "**/build/*",
              "**/.next/*",
            },
          },
        },
      },
      terminal = {
        enabled = true,
        win = {
          position = "bottom",
          height = 0.30,
          wo = {
            statusline = "",
            winbar = "",
          },
        },
      },
      zen = {
        enabled = true,
        toggles = {
          dim = false, -- don't dim inactive windows
          git_signs = true, -- hide git signs
          diagnostics = true, -- hide diagnostics
          inlay_hints = true, -- hide inlay hints
        },
        show = {
          statusline = false, -- hide statusline
          tabline = false, -- hide tabline
        },
        win = {
          width = 110, -- width in columns (or use 0.8 for 80% of screen)
          height = 0, -- 0 = full height
        },
        on_open = function()
          -- Save current line number settings
          vim.b.zen_number = vim.wo.number
          vim.b.zen_relativenumber = vim.wo.relativenumber
          -- Disable line numbers
          vim.wo.number = false
          vim.wo.relativenumber = false
        end,
        on_close = function()
          -- Restore line number settings
          vim.wo.number = vim.b.zen_number
          vim.wo.relativenumber = vim.b.zen_relativenumber
        end,
      },
      dashboard = {
        enabled = true,
        preset = {
          --styula:ignore start
          header = [[
┏┓┏┓┳┓┓┏┳┳┳┓
┏┛┣ ┃┃┃┃┃┃┃┃
┗┛┗┛┛┗┗┛┻┛ ┗

01011010 01000101 01001110 01010110 01001001 01001101
]],
          -- styula:ignore end
          -- keys = {
          --   {
          --     icon = " ",
          --     key = "f",
          --     desc = "Find File",
          --     action = ":lua Snacks.dashboard.pick('files')",
          --   },
          --   { icon = "", key = "y", desc = "File Browser", action = "<CMD>Oil<CR>" },
          --   { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          --   {
          --     icon = " ",
          --     key = "g",
          --     desc = "Find Text",
          --     action = ":lua Snacks.dashboard.pick('live_grep')",
          --   },
          --   {
          --     icon = " ",
          --     key = "r",
          --     desc = "Recent Files",
          --     action = ":lua Snacks.dashboard.pick('oldfiles')",
          --   },
          --   {
          --     icon = " ",
          --     key = "c",
          --     desc = "Config",
          --     action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          --   },
          --   { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          --   -- { icon = ' ', key = 'x', desc = 'Lazy Extras', action = ':LazyExtras' },
          --   { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          --   { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          -- },
        },
      },
    },
    -- keys = {
    -- 	-- Find commands
    -- 	{
    -- 		"<leader>ff",
    -- 		function()
    -- 			Snacks.picker.files()
    -- 		end,
    -- 		desc = "Find Files",
    -- 	},
    -- 	{
    -- 		"<leader>fs",
    -- 		function()
    -- 			Snacks.picker.grep()
    -- 		end,
    -- 		desc = "Find String (Live Grep)",
    -- 	},
    -- 	{
    -- 		"<leader>fh",
    -- 		function()
    -- 			Snacks.picker.help()
    -- 		end,
    -- 		desc = "Find Help",
    -- 	},
    -- 	{
    -- 		"<leader>fr",
    -- 		function()
    -- 			Snacks.picker.recent()
    -- 		end,
    -- 		desc = "Find Recent Files",
    -- 	},
    -- 	{
    -- 		"<leader>fw",
    -- 		function()
    -- 			Snacks.picker.grep_word()
    -- 		end,
    -- 		desc = "Find Word under cursor",
    -- 	},
    -- 	{
    -- 		"<leader>fd",
    -- 		function()
    -- 			Snacks.picker.diagnostics()
    -- 		end,
    -- 		desc = "Find Diagnostics",
    -- 	},
    -- 	{
    -- 		"<leader>fc",
    -- 		function()
    -- 			Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
    -- 		end,
    -- 		desc = "Find Config Files",
    -- 	},
    -- 	{
    -- 		"<leader>fp",
    -- 		function()
    -- 			-- Find projects in ~/Dev directory
    -- 			Snacks.picker.files({
    -- 				cwd = "~/Dev",
    -- 				-- Show only directories at depth 1
    -- 				find_command = { "fd", "--type", "d", "--max-depth", "1" },
    -- 			})
    -- 		end,
    -- 		desc = "Find Projects",
    -- 	},
    -- 	{
    -- 		"<leader>fC",
    -- 		function()
    -- 			Snacks.picker.commands()
    -- 		end,
    -- 		desc = "Find Commands",
    -- 	},
    -- 	{
    -- 		"<leader>fk",
    -- 		function()
    -- 			Snacks.picker.keymaps()
    -- 		end,
    -- 		desc = "Find Keymaps",
    -- 	},
    -- 	{
    -- 		"<leader>/",
    -- 		function()
    -- 			Snacks.picker.lines()
    -- 		end,
    -- 		desc = "Fuzzy search in current buffer",
    -- 	},
    --
    -- 	-- Buffer commands
    -- 	{
    -- 		"<leader><leader>",
    -- 		function()
    -- 			Snacks.picker.buffers()
    -- 		end,
    -- 		desc = "List Buffers",
    -- 	},
    -- 	{
    -- 		"<leader>bb",
    -- 		function()
    -- 			Snacks.picker.buffers()
    -- 		end,
    -- 		desc = "List Buffers",
    -- 	},
    -- 	{
    -- 		"<leader>bd",
    -- 		function()
    -- 			require("mini.bufremove").delete()
    -- 		end,
    -- 		desc = "Delete Buffer",
    -- 	},
    -- 	{ "<leader>bn", "<cmd>bnext<CR>", desc = "Next Buffer" },
    -- 	{ "<leader>bp", "<cmd>bprevious<CR>", desc = "Previous Buffer" },
    -- 	{ "<leader>bw", "<cmd>write<CR>", desc = "Write Buffer" },
    --
    -- 	-- Search commands (like LazyVim)
    -- 	-- Note: <leader>s group is defined in which-key.lua
    -- 	{
    -- 		"<leader>sa",
    -- 		function()
    -- 			Snacks.picker.autocmds()
    -- 		end,
    -- 		desc = "Search Autocmds",
    -- 	},
    -- 	{
    -- 		"<leader>sb",
    -- 		function()
    -- 			Snacks.picker.lines()
    -- 		end,
    -- 		desc = "Search Buffer Lines",
    -- 	},
    -- 	{
    -- 		"<leader>sB",
    -- 		function()
    -- 			Snacks.picker.grep_buffers()
    -- 		end,
    -- 		desc = "Search Open Buffers",
    -- 	},
    -- 	{
    -- 		"<leader>sc",
    -- 		function()
    -- 			Snacks.picker.command_history()
    -- 		end,
    -- 		desc = "Search Command History",
    -- 	},
    -- 	{
    -- 		"<leader>sC",
    -- 		function()
    -- 			Snacks.picker.commands()
    -- 		end,
    -- 		desc = "Search Commands",
    -- 	},
    -- 	{
    -- 		"<leader>sd",
    -- 		function()
    -- 			Snacks.picker.diagnostics()
    -- 		end,
    -- 		desc = "Search Diagnostics",
    -- 	},
    -- 	{
    -- 		"<leader>sD",
    -- 		function()
    -- 			Snacks.picker.diagnostics({ buf = 0 })
    -- 		end,
    -- 		desc = "Search Buffer Diagnostics",
    -- 	},
    -- 	{
    -- 		"<leader>sg",
    -- 		function()
    -- 			Snacks.picker.grep()
    -- 		end,
    -- 		desc = "Search Grep",
    -- 	},
    -- 	{
    -- 		"<leader>sh",
    -- 		function()
    -- 			Snacks.picker.help()
    -- 		end,
    -- 		desc = "Search Help Pages",
    -- 	},
    -- 	{
    -- 		"<leader>sH",
    -- 		function()
    -- 			Snacks.picker.highlights()
    -- 		end,
    -- 		desc = "Search Highlight Groups",
    -- 	},
    -- 	{
    -- 		"<leader>si",
    -- 		function()
    -- 			Snacks.picker.icons()
    -- 		end,
    -- 		desc = "Search Icons",
    -- 	},
    -- 	{
    -- 		"<leader>sj",
    -- 		function()
    -- 			Snacks.picker.jumps()
    -- 		end,
    -- 		desc = "Search Jumps",
    -- 	},
    -- 	{
    -- 		"<leader>sk",
    -- 		function()
    -- 			Snacks.picker.keymaps()
    -- 		end,
    -- 		desc = "Search Keymaps",
    -- 	},
    -- 	{
    -- 		"<leader>sl",
    -- 		function()
    -- 			Snacks.picker.loclist()
    -- 		end,
    -- 		desc = "Search Location List",
    -- 	},
    -- 	{
    -- 		"<leader>sm",
    -- 		function()
    -- 			Snacks.picker.marks()
    -- 		end,
    -- 		desc = "Search Marks",
    -- 	},
    -- 	{
    -- 		"<leader>sM",
    -- 		function()
    -- 			Snacks.picker.man()
    -- 		end,
    -- 		desc = "Search Man Pages",
    -- 	},
    -- 	{
    -- 		"<leader>sq",
    -- 		function()
    -- 			Snacks.picker.qflist()
    -- 		end,
    -- 		desc = "Search Quickfix List",
    -- 	},
    -- 	{
    -- 		"<leader>sR",
    -- 		function()
    -- 			Snacks.picker.resume()
    -- 		end,
    -- 		desc = "Resume Last Search",
    -- 	},
    -- 	{
    -- 		"<leader>ss",
    -- 		function()
    -- 			Snacks.picker.lsp_symbols()
    -- 		end,
    -- 		desc = "Search Buffer Symbols (LSP)",
    -- 	},
    -- 	{
    -- 		"<leader>sS",
    -- 		function()
    -- 			Snacks.picker.lsp_workspace_symbols()
    -- 		end,
    -- 		desc = "Search Workspace Symbols (LSP)",
    -- 	},
    -- 	{
    -- 		"<leader>s/",
    -- 		function()
    -- 			Snacks.picker.search_history()
    -- 		end,
    -- 		desc = "Search History",
    -- 	},
    -- 	{
    -- 		'<leader>s"',
    -- 		function()
    -- 			Snacks.picker.registers()
    -- 		end,
    -- 		desc = "Search Registers",
    -- 	},
    -- 	{
    -- 		"<leader>sw",
    -- 		function()
    -- 			Snacks.picker.grep_word()
    -- 		end,
    -- 		desc = "Search Word under Cursor",
    -- 		mode = { "n", "x" },
    -- 	},
    --
    -- 	-- Git commands (LazyGit is now in lua/plugins/lazygit.lua)
    -- 	{
    -- 		"<leader>gb",
    -- 		function()
    -- 			Snacks.gitbrowse()
    -- 		end,
    -- 		desc = "Git Browse (open)",
    -- 	},
    -- 	{
    -- 		"<leader>gB",
    -- 		function()
    -- 			Snacks.gitbrowse({
    -- 				open = function(url)
    -- 					vim.fn.setreg("+", url)
    -- 					Snacks.notify.info("URL copied to clipboard:\n" .. url)
    -- 				end,
    -- 			})
    -- 		end,
    -- 		desc = "Git Browse (copy)",
    -- 	},
    -- 	{
    -- 		"<leader>gf",
    -- 		function()
    -- 			Snacks.lazygit.log_file()
    -- 		end,
    -- 		desc = "Git Current File History",
    -- 	},
    -- 	{
    -- 		"<leader>gl",
    -- 		function()
    -- 			Snacks.lazygit.log()
    -- 		end,
    -- 		desc = "Git Log",
    -- 	},
    -- 	{
    -- 		"<leader>gc",
    -- 		function()
    -- 			Snacks.lazygit({ cwd = vim.fn.getcwd() })
    -- 		end,
    -- 		desc = "Lazygit (cwd)",
    -- 	},
    -- },
  },
}
