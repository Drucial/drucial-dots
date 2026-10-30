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
        options = { command = command, cwd = root or dir },
      }
      layout.block.label = label
      local _, new_err = rex.session.new_layer{
        window_id = window.window_id,
        bounds    = { 0.03, 0.03, 0.94, 0.94 },
        layout    = layout,
        focus     = true,
      }
      if new_err ~= nil then error(new_err, 0) end
    end,
  }
end

float_action("lazygit_float", "Toggle Lazygit Float", "lazygit", { "lazygit" }, true)
float_action("zen_octo_float", "Toggle Zen Octo Float", "zen-octo", { user_bin .. "zen-octo" }, false)
float_action("zen_linear_float", "Toggle Zen Linear Float", "zen-linear", { user_bin .. "zen-linear" }, false)
float_action("zen_review_float", "Toggle Zen Review Float", "zen-review", { user_bin .. "zen-review" }, true)

rex.bind("cmd+g", "lazygit_float")
rex.bind("cmd+o", "zen_octo_float")
rex.bind("cmd+l", "zen_linear_float")
rex.bind("cmd+r", "zen_review_float")
rex.bind("shift+cmd+r", "session.refresh")
