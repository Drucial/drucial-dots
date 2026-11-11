local terminal = "com.superlogical.terminal"

local function window_holding(view, block_id)
  for _, window in ipairs(view.windows) do
    for _, layer in ipairs(window.layers) do
      for _, block in ipairs(layer.blocks) do
        if block.block_id == block_id then return window end
      end
    end
  end
  for _, window in ipairs(view.windows) do
    if window.window_id == view.active_window_id then return window end
  end
end

local function labeled_float(window, label)
  for _, layer in ipairs(window.layers) do
    if layer.kind ~= "tiled" then
      for _, block in ipairs(layer.blocks) do
        if block.label == label then return layer end
      end
    end
  end
end

local function working_directory(block_id)
  if block_id == nil then return nil end
  local process = rex.block.call(terminal, "process", { block_id = block_id })
  return process and process.foreground and process.foreground.cwd
end

local function repo_root(dir)
  if dir == nil then return nil end
  local result = rex.exec({ "git", "rev-parse", "--show-toplevel" }, { cwd = dir, timeout = 5 })
  if result == nil or not result.ok then return nil end
  return (result.stdout:gsub("%s+$", ""))
end

local user_bin = os.getenv("HOME") .. "/.local/bin/"
local tool_bounds = { 0.06, 0.06, 0.88, 0.88 }
local drawer_bounds = { 0.6, 0, 0.4, 1 }

local function float_action(name, title, label, command, requires_repo)
  rex.action{
    name  = name,
    title = title,
    description = "Open " .. label .. " in a floating pane at the focused pane's repo root (or directory), or close it if open.",
    run   = function(ctx, args)
      local view, err = rex.session.view{}
      if err ~= nil then error(err, 0) end
      local window = window_holding(view, ctx.block_id)
      if window == nil then error("no window to float " .. label .. " in", 0) end

      local existing = labeled_float(window, label)
      if existing ~= nil then
        local _, close_err = rex.session.close_layer{ layer_id = existing.layer_id }
        if close_err ~= nil then error(close_err, 0) end
        return
      end

      local dir = working_directory(ctx.block_id)
      local root = repo_root(dir)
      if root == nil and requires_repo then error("not in a git repository: " .. (dir or "unknown directory"), 0) end

      local layout = rex.layout.block{
        flavor  = terminal .. ".shell",
        options = { command = type(command) == "function" and command(ctx) or command, cwd = root or dir },
      }
      layout.block.label = label
      local _, new_err = rex.session.new_layer{
        window_id = window.window_id,
        bounds    = tool_bounds,
        layout    = layout,
        focus     = true,
      }
      if new_err ~= nil then error(new_err, 0) end
    end,
  }
end

float_action("lazygit_float", "Toggle Lazygit Float", "lazygit", { "lazygit" }, true)
float_action("zen_review_float", "Toggle Zen Review Float", "zen-review", { user_bin .. "zen-review" }, true)

local function session_block(label)
  local list, err = rex.session.list_blocks{}
  if err ~= nil then error(err, 0) end
  for _, block in ipairs(list.blocks) do
    if block.label == label then return block end
  end
end

-- float_block only accepts a tiled block, so a detached block is placed beside one first.
local function tiled_anchor(window, preferred)
  for _, layer in ipairs(window.layers) do
    if layer.kind == "tiled" then
      for _, block in ipairs(layer.blocks) do
        if block.block_id == preferred then return preferred end
      end
      return layer.blocks[1] and layer.blocks[1].block_id
    end
  end
end

local function persistent_float_action(name, title, label, bounds, command, at_repo_root)
  rex.action{
    name  = name,
    title = title,
    description = "Show or hide this session's " .. label .. " float. Hiding detaches it, so the program keeps running.",
    run   = function(ctx, args)
      local view, err = rex.session.view{}
      if err ~= nil then error(err, 0) end
      local window = window_holding(view, ctx.block_id)
      if window == nil then error("no window to show " .. label .. " in", 0) end

      local existing = session_block(label)
      if existing == nil then
        local dir = working_directory(ctx.block_id)
        local layout = rex.layout.block{
          flavor  = terminal .. ".shell",
          options = { command = command, cwd = at_repo_root and repo_root(dir) or dir },
        }
        layout.block.label = label
        local _, new_err = rex.session.new_layer{
          window_id = window.window_id,
          bounds    = bounds,
          layout    = layout,
          focus     = true,
        }
        if new_err ~= nil then error(new_err, 0) end
        return
      end

      if existing.placement == "placed" and existing.window_id == window.window_id then
        local _, detach_err = rex.session.detach_block{ block_id = existing.block_id }
        if detach_err ~= nil then error(detach_err, 0) end
        return
      end

      local anchor = tiled_anchor(window, ctx.block_id)
      if anchor == nil then error("no tiled pane to open " .. label .. " beside", 0) end
      local _, move_err = rex.session.move_block{ block_id = existing.block_id, anchor_block_id = anchor }
      if move_err ~= nil then error(move_err, 0) end
      local _, float_err = rex.session.float_block{ block_id = existing.block_id, bounds = bounds }
      if float_err ~= nil then error(float_err, 0) end
      local _, focus_err = rex.session.focus_block{ block_id = existing.block_id }
      if focus_err ~= nil then error(focus_err, 0) end
    end,
  }
end

persistent_float_action("scratch_drawer", "Toggle Scratch Drawer", "scratch", drawer_bounds, nil, false)
persistent_float_action("nvim_float", "Toggle Neovim Float", "nvim", tool_bounds, { "nvim" }, true)
persistent_float_action("zen_octo_float", "Toggle Zen Octo Float", "zen-octo", tool_bounds, { user_bin .. "zen-octo" }, true)
persistent_float_action("zen_linear_float", "Toggle Zen Linear Float", "zen-linear", tool_bounds, { user_bin .. "zen-linear" }, true)

local config_dir = os.getenv("REX_CONFIG") and os.getenv("REX_CONFIG"):match("^(.*)/[^/]*$")
  or (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/rex"
local worktree = dofile(config_dir .. "/worktree.lua")

local function worktree_settings()
  return worktree.load_settings(config_dir .. "/worktrees.lua")
end

local function caller_checkout(ctx, repo)
  local dir = repo or working_directory(ctx.block_id)
  if dir == nil then error("no repo given and no pane directory to find one in", 0) end
  return worktree.main_checkout(dir)
end

local function target_worktree(ctx, args)
  if args.path == nil and args.branch == nil then error("give a path or a branch", 0) end
  local settings = worktree_settings()
  local main = nil
  if args.repo ~= nil or args.path == nil then main = caller_checkout(ctx, args.repo) end
  return settings, worktree.find(settings, main, args)
end

-- A CLI caller is a client too, but only an app can show a session.
local function select_session(ctx, session_id)
  if ctx.client_id ~= nil and ctx.origin ~= "api" then
    rex.client.queue("session.select", { session_id = session_id })
  end
end

rex.action{
  name  = "worktree_create",
  title = "Create Worktree",
  description = "Create a worktree for branch under the worktree root, carry its configured files, and open it in a new session.",
  args  = { branch = "string", base = "string?", repo = "string?" },
  run   = function(ctx, args)
    local settings = worktree_settings()
    local entry = worktree.create(settings, caller_checkout(ctx, args.repo), args.branch, args.base)
    entry.session_id = worktree.open(settings, entry)
    select_session(ctx, entry.session_id)
    return entry
  end,
}

rex.action{
  name  = "worktree_open",
  title = "Open Worktree",
  description = "Return the worktree's session, creating one if it has none.",
  args  = { path = "string?", branch = "string?", repo = "string?" },
  run   = function(ctx, args)
    local settings, entry = target_worktree(ctx, args)
    local session_id, created = worktree.open(settings, entry)
    return { path = entry.path, session_id = session_id, created = created }
  end,
}

rex.action{
  name  = "worktree_switch",
  title = "Switch to Worktree",
  description = "Open the worktree's session and show it in the invoking app.",
  args  = { path = "string?", branch = "string?", repo = "string?" },
  run   = function(ctx, args)
    local settings, entry = target_worktree(ctx, args)
    local session_id = worktree.open(settings, entry)
    select_session(ctx, session_id)
    return { path = entry.path, session_id = session_id }
  end,
}

rex.action{
  name  = "worktree_list",
  title = "List Worktrees",
  description = "List the caller's repo's worktrees under the worktree root, or every repo's with all or outside a repo.",
  args  = { repo = "string?", all = "boolean?" },
  run   = function(ctx, args)
    local settings = worktree_settings()
    local main = nil
    if not args.all then
      local ok, found = pcall(caller_checkout, ctx, args.repo)
      if ok then main = found elseif args.repo ~= nil then error(found, 0) end
    end
    local sessions = worktree.sessions(settings)
    local list = worktree.list(settings, main)
    for _, entry in ipairs(list) do entry.session_id = sessions[entry.path] end
    return list
  end,
}

rex.action{
  name  = "worktree_remove",
  title = "Remove Worktree",
  description = "Remove a worktree and close its session. Git refuses a dirty worktree unless force. The branch is kept.",
  args  = { path = "string?", branch = "string?", repo = "string?", force = "boolean?" },
  run   = function(ctx, args)
    local settings, entry = target_worktree(ctx, args)
    worktree.remove(entry, args.force)
    worktree.close(settings, entry.path)
    return { removed = entry.path }
  end,
}

float_action("worktree_picker", "Toggle Worktree Picker", "worktree-picker", function(ctx)
  return { config_dir .. "/worktree-picker", ctx.client_id or "" }
end, false)

rex.bind("cmd+g", "lazygit_float")
rex.bind("shift+cmd+g", "worktree_picker")
rex.bind("cmd+o", "zen_octo_float")
rex.bind("cmd+l", "zen_linear_float")
rex.bind("cmd+r", "zen_review_float")
rex.bind("cmd+\\", "scratch_drawer")
rex.bind("cmd+e", "nvim_float")
rex.bind("shift+cmd+r", "session.refresh")
