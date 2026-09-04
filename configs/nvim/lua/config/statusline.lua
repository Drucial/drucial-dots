local M = {}

local MAX_PATH = 50
local MAX_BRANCH = 20

local MODES = {
  n = { "N", "Directory" },
  i = { "I", "String" },
  v = { "V", "Statement" },
  V = { "V", "Statement" },
  ["\22"] = { "V", "Statement" },
  s = { "S", "Statement" },
  S = { "S", "Statement" },
  R = { "R", "DiagnosticError" },
  c = { "C", "Constant" },
  t = { "T", "Type" },
  no = { "O", "Directory" },
}

local function block_hl(name, source)
  local from = vim.api.nvim_get_hl(0, { name = source, link = false })
  local bg = from.fg
  if not bg then
    return
  end
  vim.api.nvim_set_hl(0, name, {
    bg = bg,
    fg = vim.o.background == "dark" and 0x000000 or 0xffffff,
    bold = true,
  })
end

function M.apply_highlights()
  for _, mode in pairs(MODES) do
    block_hl("StatusMode" .. mode[1], mode[2])
  end
end

local SEVERITIES = {
  { vim.diagnostic.severity.ERROR, "E", "DiagnosticError" },
  { vim.diagnostic.severity.WARN, "W", "DiagnosticWarn" },
  { vim.diagnostic.severity.INFO, "I", "DiagnosticInfo" },
  { vim.diagnostic.severity.HINT, "H", "DiagnosticHint" },
}

local BUF_DIFF = {
  { key = "add", text = "+%d", hl = "MiniDiffSignAdd" },
  { key = "change", text = "~%d", hl = "MiniDiffSignChange" },
  { key = "delete", text = "-%d", hl = "MiniDiffSignDelete" },
}

-- Hunks in this buffer, from mini.diff. The repo-wide counts live on the right.
local function buf_diff(buf)
  local summary = vim.b[buf].minidiff_summary
  if not summary then
    return ""
  end

  local parts = {}
  for _, item in ipairs(BUF_DIFF) do
    local n = summary[item.key]
    if n and n > 0 then
      parts[#parts + 1] = "%#" .. item.hl .. "#" .. item.text:format(n) .. "%*"
    end
  end
  return table.concat(parts, " ")
end

local function diagnostics(buf)
  local counts = {}
  for _, d in ipairs(vim.diagnostic.get(buf)) do
    counts[d.severity] = (counts[d.severity] or 0) + 1
  end

  local parts = {}
  for _, severity in ipairs(SEVERITIES) do
    local n = counts[severity[1]]
    if n then
      parts[#parts + 1] = "%#" .. severity[3] .. "#" .. severity[2] .. n .. "%*"
    end
  end
  return table.concat(parts, " ")
end

local function git_root(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local cached = vim.b[buf].statusline_git_root
  if cached and cached.name == name then
    return cached.root ~= "" and cached.root or nil
  end

  local root = name ~= "" and vim.fs.root(name, ".git") or nil
  vim.b[buf].statusline_git_root = { name = name, root = root or "" }
  return root
end

-- render() is a %! expression, so its result is re-parsed for statusline items.
-- Anything derived from a path or branch name has to escape its percent signs.
local function escape(text)
  return (text:gsub("%%", "%%%%"))
end

local function shorten(path)
  if #path <= MAX_PATH then
    return path
  end
  local parts = vim.split(path, "/")
  local prefix = ""
  if parts[1] == "" then
    prefix = "/"
    table.remove(parts, 1)
  end
  local short = #parts > 2 and (prefix .. parts[1] .. "/…/" .. parts[#parts]) or path
  if #short > MAX_PATH then
    short = "…" .. short:sub(#short - MAX_PATH + 2)
  end
  return short
end

local function path(buf, root)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" then
    return ""
  end
  local rel = root and name:sub(#root + 2) or vim.fn.fnamemodify(name, ":~:.")
  return shorten(rel)
end

local function git_dir(root)
  local git = root .. "/.git"
  local stat = vim.uv.fs_stat(git)
  if stat and stat.type == "file" then
    local link = (vim.fn.readfile(git, "", 1)[1] or ""):match("^gitdir: (.+)$")
    if link then
      git = vim.fs.normalize(link:sub(1, 1) == "/" and link or root .. "/" .. link)
    end
  end
  return git
end

-- Read .git/HEAD directly rather than spawning git, so this stays cheap enough
-- to run on every statusline redraw. Cached per root; cleared on the autocmds
-- in setup().
local branches = {}

-- Shapes and order mirror the git_status module in ~/.config/starship.toml.
-- Starship names ANSI colors; these map to semantic groups instead so the
-- statusline follows a theme switch.
local GIT_STATUS = {
  { key = "ahead", text = "⇡ %d", hl = "Directory" },
  { key = "behind", text = "⇣ %d", hl = "DiagnosticError" },
  { key = "staged", text = "+%d", hl = "DiagnosticInfo" },
  { key = "modified", text = "~%d", hl = "DiagnosticWarn" },
  { key = "untracked", text = "?%d", hl = "WarningMsg" },
  { key = "renamed", text = "»", hl = "Identifier" },
  { key = "deleted", text = "-%d", hl = "DiagnosticError" },
  { key = "conflicted", text = "≠", hl = "Statement" },
  { key = "stashed", text = "󰏢", hl = "String" },
}

-- Unlike branch, this needs `git status`, so it runs off the autocmds in
-- setup() and repaints when the result lands. Never spawned from render().
local statuses = {}

local function tally(lines)
  local counts = {}
  local function bump(key)
    counts[key] = (counts[key] or 0) + 1
  end

  for _, line in ipairs(lines) do
    if line:sub(1, 2) == "##" then
      counts.ahead = tonumber(line:match("ahead (%d+)"))
      counts.behind = tonumber(line:match("behind (%d+)"))
    else
      local x, y = line:sub(1, 1), line:sub(2, 2)
      if x == "?" then
        bump("untracked")
      elseif x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
        bump("conflicted")
      else
        if x == "R" then
          bump("renamed")
        end
        if x == "D" or y == "D" then
          bump("deleted")
        end
        if x ~= " " then
          bump("staged")
        end
        if y == "M" then
          bump("modified")
        end
      end
    end
  end
  return counts
end

local pending = {}

local function refresh(root)
  if pending[root] then
    return
  end
  pending[root] = true

  -- Resolved here, not in on_exit: that callback is a fast event context, where
  -- git_dir's readfile raises E5560 for the .git-as-a-file case (worktrees,
  -- submodules).
  local stash = git_dir(root) .. "/refs/stash"

  vim.system({ "git", "-C", root, "status", "--porcelain=v1", "--branch" }, { text = true }, function(result)
    local counts = {}
    if result.code == 0 then
      counts = tally(vim.split(result.stdout or "", "\n", { trimempty = true }))
    end
    if vim.uv.fs_stat(stash) then
      counts.stashed = 1
    end
    vim.schedule(function()
      pending[root] = nil
      statuses[root] = counts
      vim.cmd("redrawstatus")
    end)
  end)
end

local function git_status(root)
  local counts = statuses[root]
  if not counts then
    return ""
  end

  local parts = {}
  for _, item in ipairs(GIT_STATUS) do
    local n = counts[item.key]
    if n and n > 0 then
      parts[#parts + 1] = "%#" .. item.hl .. "#" .. item.text:format(n) .. "%*"
    end
  end
  return table.concat(parts, " ")
end

local function branch(root)
  local cached = branches[root]
  if cached ~= nil then
    return cached ~= "" and cached or nil
  end

  local git = git_dir(root)
  if not vim.uv.fs_stat(git .. "/HEAD") then
    branches[root] = ""
    return nil
  end

  local head = vim.fn.readfile(git .. "/HEAD", "", 1)[1] or ""
  local name = head:match("^ref: refs/heads/(.+)$") or head:sub(1, 7)
  if #name > MAX_BRANCH then
    name = name:sub(1, MAX_BRANCH - 1) .. "…"
  end

  branches[root] = name
  return name ~= "" and name or nil
end

function M.clear_cache()
  branches = {}
end

function M.render()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "snacks_dashboard" then
    return ""
  end

  local m = vim.api.nvim_get_mode().mode
  local mode = MODES[m] or MODES[m:sub(1, 1)] or MODES.n
  local block = "%#StatusMode" .. mode[1] .. "#"
  local root = git_root(buf)

  local right = ""
  if root then
    local head = branch(root)
    local changes = git_status(root)
    right = (changes ~= "" and changes .. " " or "")
      .. (head and escape(head) .. " " or "")
      .. block
      .. " "
      .. escape(vim.fs.basename(root))
      .. " %*"
  end

  local hunks = buf_diff(buf)
  local diag = diagnostics(buf)

  return table.concat({
    block .. " " .. mode[1] .. " %*",
    " ",
    escape(path(buf, root)),
    hunks ~= "" and " " .. hunks or "",
    diag ~= "" and " " .. diag or "",
    "%=",
    right,
  })
end

function M.setup()
  M.apply_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("statusline-highlights", { clear = true }),
    callback = M.apply_highlights,
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("statusline-git", { clear = true }),
    callback = function()
      M.clear_cache()
      local root = git_root(vim.api.nvim_get_current_buf())
      if root then
        refresh(root)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniDiffUpdated",
    group = vim.api.nvim_create_augroup("statusline-diff", { clear = true }),
    callback = function()
      vim.cmd("redrawstatus")
    end,
  })
  vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
end

return M
