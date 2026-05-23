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

-- Custom terminal toggle (split / float) -- disabled; using snacks defaults
-- local function find_term_win(buf)
--   for _, win in ipairs(vim.api.nvim_list_wins()) do
--     if vim.api.nvim_win_get_buf(win) == buf then
--       return win, vim.api.nvim_win_get_config(win).relative ~= ""
--     end
--   end
-- end
--
-- local function open_term_split(buf)
--   vim.cmd("botright " .. math.floor(vim.o.lines * 0.30) .. "split")
--   vim.api.nvim_win_set_buf(0, buf)
--   vim.wo.number = false
--   vim.wo.relativenumber = false
--   vim.wo.signcolumn = "no"
--   vim.wo.statusline = ""
--   vim.wo.winbar = ""
--   vim.cmd("startinsert")
-- end
--
-- local function open_term_float(buf)
--   local width = math.floor(vim.o.columns * 0.90)
--   local height = math.floor(vim.o.lines * 0.80)
--   vim.api.nvim_open_win(buf, true, {
--     relative = "editor",
--     width = width,
--     height = height,
--     row = math.floor((vim.o.lines - height) / 2),
--     col = math.floor((vim.o.columns - width) / 2),
--     border = "rounded",
--     style = "minimal",
--   })
--   vim.cmd("startinsert")
-- end
--
-- local function toggle_term(target_float)
--   local term, created = Snacks.terminal.get(nil)
--   if not term then return end
--   local buf = term.buf
--
--   local win, is_float = find_term_win(buf)
--   if win then
--     vim.api.nvim_win_close(win, true)
--     if not created and is_float == target_float then return end -- toggle off
--   end
--
--   if target_float then open_term_float(buf) else open_term_split(buf) end
-- end
--
-- map({ "n", "i", "v", "t" }, "<D-b>", function() toggle_term(false) end, { desc = "Toggle Terminal (split)" })
-- map({ "n", "i", "v", "t" }, [[<C-\>]], function() toggle_term(true) end, { desc = "Toggle Terminal (float)" })
--
-- vim.api.nvim_create_autocmd("TermClose", {
--   callback = function(ev)
--     vim.schedule(function()
--       for _, win in ipairs(vim.api.nvim_list_wins()) do
--         if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == ev.buf then
--           pcall(vim.api.nvim_win_close, win, true)
--         end
--       end
--       pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
--     end)
--   end,
-- })

map("n", "<C-h>", "<cmd>KittyNavigateLeft<cr>", { desc = "Kitty Navigate Left" })
map("n", "<C-j>", "<cmd>KittyNavigateDown<cr>", { desc = "Kitty Navigate Down" })
map("n", "<C-k>", "<cmd>KittyNavigateUp<cr>", { desc = "Kitty Navigate Up" })
map("n", "<C-l>", "<cmd>KittyNavigateRight<cr>", { desc = "Kitty Navigate Right" })

map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal: normal mode" })

map("t", "<C-h>", [[<C-\><C-n><cmd>KittyNavigateLeft<cr>]], { desc = "Kitty Navigate Left" })
map("t", "<C-j>", [[<C-\><C-n><cmd>KittyNavigateDown<cr>]], { desc = "Kitty Navigate Down" })
map("t", "<C-k>", [[<C-\><C-n><cmd>KittyNavigateUp<cr>]], { desc = "Kitty Navigate Up" })
map("t", "<C-l>", [[<C-\><C-n><cmd>KittyNavigateRight<cr>]], { desc = "Kitty Navigate Right" })

-- Buffer Management
map("n", "<leader>bn", ":bnext<CR>", { desc = "Cycle to next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Cycle to previous buffer" })

-- Dashboard
local function show_dashboard()
  pcall(Snacks.dashboard.open, { win = 0 })
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
