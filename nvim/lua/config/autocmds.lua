-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- External file change watcher: detects when files in the project are modified by
-- another process (e.g. Claude in a separate kitty pane) and reloads stale buffers
-- via :checktime, without depending on nvim focus events.
do
  local ignore_patterns = {
    "node_modules",
    "/.git/",
    "/dist/",
    "/build/",
    "/.next/",
    "/.turbo/",
    "/target/",
    "/__pycache__/",
    "/.venv/",
    "/venv/",
    "/.cache/",
    ".swp",
    "4913", -- vim's atomic-save sentinel
  }

  local function ignored(fname)
    if not fname or fname == "" then
      return false
    end
    for _, p in ipairs(ignore_patterns) do
      if fname:find(p, 1, true) then
        return true
      end
    end
    return false
  end

  local watcher
  local debounce_timer

  local function start_watcher(root)
    if watcher then
      watcher:stop()
    end
    watcher = vim.uv.new_fs_event()
    if not watcher then
      return
    end
    watcher:start(root, { recursive = true }, function(err, fname)
      if err or ignored(fname) then
        return
      end
      vim.schedule(function()
        if debounce_timer then
          debounce_timer:stop()
        end
        debounce_timer = vim.defer_fn(function()
          if vim.fn.mode() ~= "c" then
            vim.cmd("checktime")
          end
          debounce_timer = nil
        end, 100)
      end)
    end)
  end

  start_watcher(vim.fn.getcwd())

  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      start_watcher(vim.fn.getcwd())
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if watcher then
        watcher:stop()
        watcher = nil
      end
    end,
  })
end
