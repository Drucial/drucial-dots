local map = vim.keymap.set

-- Config
map("n", "<leader>R", "<cmd>restart +confirm\\ qall<CR>", { desc = "Reload Nvim" })

-- Navigation
-- zen-navigator binds <C-hjkl> in normal mode itself; terminal mode has to leave
-- terminal mode first, so those are set here.
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  local nav = ([[<C-\><C-n><cmd>lua require("zen-navigator").navigate("%s")<cr>]]):format(key)
  map("t", "<C-" .. key .. ">", nav, { silent = true, desc = "ZenNavigator: move " .. dir })
end

-- Half-page scrolls land centered.
map({ "n", "x" }, "<C-d>", "<C-d>zz", { desc = "Half page down" })
map({ "n", "x" }, "<C-u>", "<C-u>zz", { desc = "Half page up" })

-- Buffer Management
local function show_dashboard()
  Snacks.dashboard.open({ win = 0 })
end

-- A "real" buffer is listed and either named on disk or holds unsaved work.
-- Excludes the empty scratch buffer left behind after the last delete, plus
-- help, terminal and quickfix.
local function has_real_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == ""
      and (vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified)
    then
      return true
    end
  end
  return false
end

local function delete_all_buffers()
  Snacks.bufdelete.all()
  vim.schedule(function()
    if not has_real_buffer() then
      show_dashboard()
    end
  end)
end

map("n", "<leader>bd", function()
  Snacks.bufdelete()
  vim.schedule(function()
    if not has_real_buffer() then
      show_dashboard()
    end
  end)
end, { desc = "Delete buffer" })
map("n", "<leader>bD", delete_all_buffers, { desc = "Delete all buffers" })
map("n", "<leader>bh", show_dashboard, { desc = "Show dashboard" })

vim.api.nvim_create_user_command("Bdall", delete_all_buffers, { desc = "Delete all buffers" })

-- Code
map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
map("n", "<leader>cR", function()
  Snacks.rename.rename_file()
end, { desc = "Rename file" })

-- Files
map("n", "<leader>e", function()
  Snacks.picker.explorer()
end, { desc = "Explorer" })

map("n", "<leader>z", function()
  Snacks.zen()
end, { desc = "Zen mode" })
map("n", "<leader>Z", function()
  Snacks.zen.zoom()
end, { desc = "Zoom window" })

-- Find
map("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Files" })
map("n", "<leader>fg", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
map({ "n", "x" }, "<leader>fw", function()
  Snacks.picker.grep_word()
end, { desc = "Grep word under cursor" })
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>fr", function()
  Snacks.picker.recent()
end, { desc = "Recent files" })
map("n", "<leader>fh", function()
  Snacks.picker.help()
end, { desc = "Help pages" })
map("n", "<leader>fk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>fR", function()
  Snacks.picker.resume()
end, { desc = "Resume last picker" })

-- Git
map("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "Lazygit" })
map("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Status" })
map("n", "<leader>gl", function()
  Snacks.picker.git_log()
end, { desc = "Log" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Current file history" })
map("n", "<leader>gB", function()
  Snacks.picker.git_branches()
end, { desc = "Branches" })
map("n", "<leader>gd", function()
  Snacks.picker.git_diff()
end, { desc = "Diff hunks" })
map("n", "<leader>gb", function()
  Snacks.git.blame_line()
end, { desc = "Blame line" })
map({ "n", "x" }, "<leader>go", function()
  Snacks.gitbrowse()
end, { desc = "Open in browser" })

-- Diagnostics
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>db", function()
  Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics" })
map("n", "<leader>dw", function()
  Snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })
map("n", "<leader>de", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next error" })
map("n", "<leader>dE", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Previous error" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "<leader>dt", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
