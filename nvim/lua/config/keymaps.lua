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

map("n", "<C-h>", "<cmd>KittyNavigateLeft<cr>", { desc = "Kitty Navigate Left" })
map("n", "<C-j>", "<cmd>KittyNavigateDown<cr>", { desc = "Kitty Navigate Down" })
map("n", "<C-k>", "<cmd>KittyNavigateUp<cr>", { desc = "Kitty Navigate Up" })
map("n", "<C-l>", "<cmd>KittyNavigateRight<cr>", { desc = "Kitty Navigate Right" })

-- Buffer Management
map("n", "<leader>bn", ":bnext<CR>", { desc = "Cycle to next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Cycle to previous buffer" })
