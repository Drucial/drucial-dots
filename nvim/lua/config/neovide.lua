if not vim.g.neovide then return end

vim.g.neovide_opacity = 0.90
vim.g.neovide_window_blurred = true
vim.g.neovide_floating_shadow = false
vim.g.neovide_floating_blur_amount_x = 2.0
vim.g.neovide_floating_blur_amount_y = 2.0

local bg = "#191724"

local function set_bg()
  vim.api.nvim_set_hl(0, "Normal", { bg = bg })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = bg })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = bg })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = bg })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = set_bg })
set_bg()

vim.cmd([[cnoreabbrev <expr> q getcmdtype() ==# ':' && getcmdline() ==# 'q' ? 'bd' : 'q']])
vim.cmd([[cnoreabbrev <expr> q! getcmdtype() ==# ':' && getcmdline() ==# 'q!' ? 'bd!' : 'q!']])
vim.cmd([[cnoreabbrev <expr> qa getcmdtype() ==# ':' && getcmdline() ==# 'qa' ? 'Bdall' : 'qa']])
vim.cmd([[cnoreabbrev <expr> qa! getcmdtype() ==# ':' && getcmdline() ==# 'qa!' ? 'Bdall' : 'qa!']])

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.argc() > 0 then return end
    vim.schedule(function()
      Snacks.picker.projects({
        layout = {
          preset = "select",
          layout = { width = 0.4, min_width = 30, max_width = 100, height = 0.6, min_height = 10 },
        },
        transform = function(item)
          item.text = vim.fn.fnamemodify(item.file, ":t")
          return item
        end,
        format = function(item)
          local icon, hl = Snacks.util.icon(item.file, "directory")
          return {
            { icon .. " ", hl },
            { item.text, "SnacksPickerDir" },
          }
        end,
        confirm = function(picker, item)
          picker:close()
          if not item then return end
          vim.fn.chdir(item.file)
        end,
      })
    end)
  end,
})
