local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Save file with cmd-s
-- map({ "n", "v", "i" }, "<D-s>", function()
--   vim.cmd("w")
-- end, { desc = "Save file" })
--
-- -- Close current buffer with cmd-w
-- map("n", "<D-w>", function()
--   if vim.bo.filetype == "qf" then
--     vim.cmd("cclose")
--   elseif vim.bo.filetype == "help" then
--     vim.cmd("quit")
--   else
--     vim.cmd("bd")
--   end
-- end, { desc = "Close Buffer" })
--
-- -- Cmd+p → Find files from root dir
-- map("n", "<D-p>", function()
--   require("snacks.picker").files({ cwd = require("lazyvim.util").root() })
-- end, { desc = "Find Files (Project Root)" })
--
-- -- Cmd+Shift+p → Find config files in ~/.config/nvim
-- map("n", "<D-P>", function()
--   require("snacks.picker").files({ cwd = vim.fn.stdpath("config") })
-- end, { desc = "Find Config Files" })
--
-- -- Cmd+f → Find string in current file
-- map("n", "<D-f>", function()
--   require("snacks.picker").lines()
-- end, { desc = "Find String in Current File" })
--
-- -- Cmd+Shift+f → Find string in project
-- map("n", "<D-F>", function()
--   require("snacks.picker").grep({ cwd = require("lazyvim.util").root() })
-- end, { desc = "Find String in Project" })
--
-- -- Cmd+b → Toggle file browser
-- map("n", "<D-b>", "<CMD>Oil<CR>", { desc = "Toggle File Browser (Oil)" })
--
-- -- Leader+e → Open Oil at project root
-- map("n", "<leader>e", function()
--   require("oil").open(require("lazyvim.util").root())
-- end, { desc = "Explorer (root dir)" })
--
-- -- Leader+E → Open Oil at current working directory
-- map("n", "<leader>E", function()
--   require("oil").open(vim.fn.getcwd())
-- end, { desc = "Explorer (cwd)" })

-- Buffer Navigation
local function next_buffer()
  vim.cmd("silent! bnext")
end

local function prev_buffer()
  vim.cmd("silent! bprevious")
end

-- Cmd +[ and Cmd +] to navigate buffers
-- map("n", "<D-]>", next_buffer, { desc = "Next Buffer" })
-- map("n", "<D-[>", prev_buffer, { desc = "Previous Buffer" })

map("n", "<leader>]", next_buffer, { desc = "Next Buffer" })
map("n", "<leader>[", prev_buffer, { desc = "Previous Buffer" })
map("n", "<leader>bn", next_buffer, { desc = "Next Buffer" })
map("n", "<leader>bp", prev_buffer, { desc = "Previous Buffer" })

map("n", "<A-down>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-up>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-down>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-up>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- duplicate line or selection movements
map("n", "<A-s-down>", "yyp", { desc = "duplicate line below" })
map("v", "<A-s-down>", "y`>pgv", { desc = "duplicate selection below" })

map("n", "<A-s-up>", "yyp", { desc = "duplicate line above" })
map("v", "<A-s-up>", "y`<pgv", { desc = "duplicate selection above" })

-- centered page up and page down
map("n", "<c-u>", "<c-u>zz", { desc = "scroll up half a page" })
map("n", "<c-up>", "<c-u>zz", { desc = "scroll up half a page" })
map("n", "<c-d>", "<c-d>zz", { desc = "scroll down half a page" })
map("n", "<c-down>", "<c-d>zz", { desc = "scroll down half a page" })

-- centered page for n resulats from search
map("n", "n", "nzzzv", { desc = "neext search result in centered page" })

map("n", "<C-h>", "<cmd>KittyNavigateLeft<cr>", { desc = "Kitty Navigate Left" })
map("n", "<C-j>", "<cmd>KittyNavigateDown<cr>", { desc = "Kitty Navigate Down" })
map("n", "<C-k>", "<cmd>KittyNavigateUp<cr>", { desc = "Kitty Navigate Up" })
map("n", "<C-l>", "<cmd>KittyNavigateRight<cr>", { desc = "Kitty Navigate Right" })
