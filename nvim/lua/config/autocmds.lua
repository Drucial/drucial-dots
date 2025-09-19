-- Auto commands for Neovim configuration

vim.api.nvim_create_autocmd({ "TermOpen", "TermEnter" }, {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.statuscolumn = ""
    vim.opt_local.winbar = nil
    if vim.fn.mode() ~= "i" then
      vim.cmd("startinsert")
    end
  end,
})

-- Disable line numbers in terminal buffers
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.cmd([[
      highlight NormalFloat  guibg=NONE ctermbg=NONE
      highlight FloatBorder  guibg=NONE ctermbg=NONE
    ]])
  end,
})

-- Show diagnostic float on hover
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local opts = {
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = "rounded",
      source = "always",
      prefix = " ",
      scope = "cursor",
    }
    vim.diagnostic.open_float(nil, opts)
  end,
})

-- Faster update time for hover diagnostics
vim.opt.updatetime = 250
