-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- External file change watcher: detects when files in the project are modified by
-- another process (e.g. Claude in a separate kitty pane) and reloads stale buffers
-- via :checktime, without depending on nvim focus events.
do
  -- Path-segment ignores: any dir/file name in the path matching one of these
  -- means the event is ignored. Anchored, so `node_modules-backup` is NOT
  -- treated as `node_modules`.
  local segment_ignores = {
    ["node_modules"] = true,
    [".git"] = true,
    ["dist"] = true,
    ["build"] = true,
    [".next"] = true,
    [".turbo"] = true,
    ["target"] = true,
    ["__pycache__"] = true,
    [".venv"] = true,
    ["venv"] = true,
    [".cache"] = true,
  }
  -- Suffix matches on the basename (vim swap files).
  local suffix_ignores = { ".swp" }
  -- Exact basename matches (vim's atomic-save sentinel).
  local exact_ignores = { ["4913"] = true }

  local function ignored(fname)
    if not fname or fname == "" then
      return false
    end
    local base = fname:match("([^/]+)$") or fname
    if exact_ignores[base] then
      return true
    end
    for _, suffix in ipairs(suffix_ignores) do
      if #base >= #suffix and base:sub(-#suffix) == suffix then
        return true
      end
    end
    for segment in fname:gmatch("[^/]+") do
      if segment_ignores[segment] then
        return true
      end
    end
    return false
  end

  local watcher
  local debounce_timer
  local notified_nil = false
  local restart_count = 0
  local MAX_RESTARTS = 5

  local start_watcher
  start_watcher = function(root)
    if watcher then
      pcall(function()
        watcher:stop()
      end)
    end
    watcher = vim.uv.new_fs_event()
    if not watcher then
      if not notified_nil then
        notified_nil = true
        vim.schedule(function()
          vim.notify("fs-watcher: vim.uv.new_fs_event() returned nil; external file changes won't auto-reload", vim.log.levels.WARN)
        end)
      end
      return
    end
    local ok = pcall(function()
      watcher:start(root, { recursive = true }, function(err, fname)
        if err then
          if restart_count < MAX_RESTARTS then
            restart_count = restart_count + 1
            vim.schedule(function()
              start_watcher(root)
            end)
          end
          return
        end
        if ignored(fname) then
          return
        end
        vim.schedule(function()
          if debounce_timer then
            debounce_timer:stop()
          end
          debounce_timer = vim.defer_fn(function()
            if vim.fn.mode() ~= "c" then
              pcall(vim.cmd, "checktime")
            end
            debounce_timer = nil
          end, 100)
        end)
      end)
    end)
    if not ok then
      watcher = nil
    end
  end

  start_watcher(vim.fn.getcwd())

  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      restart_count = 0
      start_watcher(vim.fn.getcwd())
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if watcher then
        pcall(function()
          watcher:stop()
        end)
        watcher = nil
      end
    end,
  })
end
