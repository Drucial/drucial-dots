local map = vim.keymap.set
-- local opts = { noremap = true, silent = true }

-- Move lines up and down
map("n", "<A-S-Down>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-S-Up>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-S-Down>", ":m '>+1<CR>gv=gv", { desc = "Move lines down" })
map("v", "<A-S-Up>", ":m '<-2<CR>gv=gv", { desc = "Move lines up" })

-- Duplicate lines up and down
map("n", "<C-A-Down>", ":t.<CR>==", { desc = "Duplicate line below" })
map("n", "<C-A-Up>", ":t.-1<CR>==", { desc = "Duplicate line above" })
map("v", "<C-A-Down>", ":t'><CR>gv=gv", { desc = "Duplicate lines below" })
map("v", "<C-A-Up>", ":t'<-1<CR>gv=gv", { desc = "Duplicate lines above" })

-- Paging with arrows
map("n", "<C-Down>", "<C-d>", { desc = "Scroll down and center" })
map("n", "<C-Up>", "<C-u>", { desc = "Scroll up and center" })
-- Keep cursor centered
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- Paste without yanking
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Change without yanking
map({ "n", "v" }, "c", [["_c]], { desc = "Change without yanking" })
map({ "n", "v" }, "C", [["_C]], { desc = "Change to end of line without yanking" })

map({ "n", "t" }, [[<C-\>]], function() Snacks.terminal() end, { desc = "Toggle Terminal" })

map({ "n", "t" }, "<D-j>", function()
  Snacks.terminal(nil, {
    win = {
      position = "float",
      relative = "editor",
      width = 0.96,
      height = 0.30,
      row = -1,
      col = function() return math.floor(vim.o.columns * 0.02) end,
      border = "rounded",
      wo = { statusline = "", winbar = "" },
    },
  })
end, { desc = "Toggle Floating Terminal" })

map("n", "<C-h>", "<cmd>KittyNavigateLeft<cr>", { desc = "Kitty Navigate Left" })
map("n", "<C-j>", "<cmd>KittyNavigateDown<cr>", { desc = "Kitty Navigate Down" })
map("n", "<C-k>", "<cmd>KittyNavigateUp<cr>", { desc = "Kitty Navigate Up" })
map("n", "<C-l>", "<cmd>KittyNavigateRight<cr>", { desc = "Kitty Navigate Right" })

-- Buffer Management
map("n", "<leader>bn", ":bnext<CR>", { desc = "Cycle to next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Cycle to previous buffer" })

-- Dashboard
local function show_dashboard()
  Snacks.dashboard.open({ win = 0 })
end

-- A "real" buffer is listed and has a name on disk. Excludes the unnamed
-- scratch buffer nvim/Snacks leaves behind after the last delete, plus
-- help/terminal/quickfix and other transient buffers.
local function has_real_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buflisted
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      return true
    end
  end
  return false
end

map("n", "<leader>uh", show_dashboard, { desc = "Show Dashboard" })

map("n", "<leader>bd", function()
  Snacks.bufdelete()
  vim.schedule(function()
    if not has_real_buffer() then
      show_dashboard()
    end
  end)
end, { desc = "Delete Buffer (dashboard if last)" })

local function delete_all_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      Snacks.bufdelete(buf)
    end
  end
  vim.schedule(show_dashboard)
end

vim.api.nvim_create_user_command("Bdall", delete_all_buffers, { desc = "Delete all buffers + dashboard" })

map("n", "<leader>bD", delete_all_buffers, { desc = "Delete All Buffers + Dashboard" })
