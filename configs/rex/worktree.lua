-- Git worktrees under a shared root, the ignored files they carry over, and the Rex session each one runs in.
local M = {}

local terminal = "com.superlogical.terminal"
local home = os.getenv("HOME")

local function trim(s) return (s:gsub("%s+$", "")) end

local function expand(path)
  if path:sub(1, 2) == "~/" then return home .. path:sub(2) end
  return path
end

local function dirname(path) return path:match("^(.*)/[^/]*$") or "." end
local function basename(path) return path:match("([^/]+)/*$") end

local function run(argv, opts)
  local result, err = rex.exec(argv, opts)
  if result == nil then error(err, 0) end
  return result
end

local function git(dir, ...)
  return run({ "git", "-C", dir, ... }, { timeout = 120 })
end

local function git_ok(dir, ...)
  local result = git(dir, ...)
  if not result.ok then error(trim(result.stderr ~= "" and result.stderr or result.stdout), 0) end
  return trim(result.stdout)
end

local function exists(path) return run({ "test", "-e", path }).ok end

--- Loads settings from a Lua file returning { root?, repos? = { [path] = { carry = {...} } } }. A missing file yields defaults.
function M.load_settings(path)
  local config = {}
  if io.open(path, "r") ~= nil then config = dofile(path) or {} end
  local repos = {}
  for repo, entry in pairs(config.repos or {}) do
    repos[expand(repo):lower()] = entry
  end
  return { root = expand(config.root or "~/.rex-worktrees"), repos = repos }
end

--- Returns the main checkout of the repository containing dir, even when dir is inside a linked worktree.
function M.main_checkout(dir)
  local common = git(dir, "rev-parse", "--path-format=absolute", "--git-common-dir")
  if not common.ok then error("not in a git repository: " .. dir, 0) end
  local main = trim(common.stdout):gsub("/%.git/?$", "")
  if main == trim(common.stdout) then error("unsupported repository layout: " .. trim(common.stdout), 0) end
  return main
end

local function carry_list(settings, main)
  -- Keys compare case-insensitively because macOS paths reach Rex as both ~/Dev and ~/dev.
  local entry = settings.repos[main:lower()]
  return entry and entry.carry or {}
end

local function carry_path_escapes(rel)
  if rel:sub(1, 1) == "/" then return true end
  for part in rel:gmatch("[^/]+") do
    if part == ".." then return true end
  end
  return false
end

--- Copies each carry path from main into worktree. Returns { carried = {paths}, skipped = {{ name, reason }} }.
function M.carry(main, worktree, paths)
  local carried, skipped = {}, {}
  for _, rel in ipairs(paths) do
    local src, dst = main .. "/" .. rel, worktree .. "/" .. rel
    if carry_path_escapes(rel) then
      skipped[#skipped + 1] = { name = rel, reason = "leaves the repository" }
    elseif not exists(src) then
    elseif git_ok(main, "ls-files", "--", rel) ~= "" then
      skipped[#skipped + 1] = { name = rel, reason = "is tracked by git" }
    elseif exists(dst) then
      skipped[#skipped + 1] = { name = rel, reason = "already in the worktree" }
    else
      run({ "mkdir", "-p", dirname(dst) })
      -- cp -c clones on APFS; other volumes need a real copy.
      if run({ "cp", "-cR", src, dst }).ok or run({ "cp", "-R", src, dst }).ok then
        carried[#carried + 1] = rel
      else
        skipped[#skipped + 1] = { name = rel, reason = "copy failed" }
      end
    end
  end
  return { carried = carried, skipped = skipped }
end

local function default_base(main)
  local origin = git(main, "rev-parse", "--abbrev-ref", "origin/HEAD")
  if origin.ok then return trim(origin.stdout) end
  return "HEAD"
end

--- Creates a worktree for branch under settings.root and carries the repo's configured files into it.
--- Checks out branch if it exists locally or on origin, else cuts it from base (origin/HEAD, then HEAD).
function M.create(settings, main, branch, base)
  git_ok(main, "check-ref-format", "--branch", branch)
  local repo = basename(main)
  local name = branch:gsub("/", "-")
  local path = settings.root .. "/" .. repo .. "/" .. name
  if exists(path) then error("worktree path already exists: " .. path, 0) end
  run({ "mkdir", "-p", dirname(path) })

  if git(main, "show-ref", "--verify", "--quiet", "refs/heads/" .. branch).ok then
    git_ok(main, "worktree", "add", path, branch)
  elseif base == nil and git(main, "show-ref", "--verify", "--quiet", "refs/remotes/origin/" .. branch).ok then
    git_ok(main, "worktree", "add", "--track", "-b", branch, path, "origin/" .. branch)
  else
    git_ok(main, "worktree", "add", "-b", branch, path, base or default_base(main))
  end

  return {
    repo = repo, name = name, path = path, branch = branch, main = main,
    carry = M.carry(main, path, carry_list(settings, main)),
  }
end

local function parse_porcelain(text)
  local entries, current = {}, nil
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local key, value = line:match("^(%S+) ?(.*)$")
    if key == "worktree" then
      current = { path = value }
      entries[#entries + 1] = current
    elseif key == "branch" and current then
      current.branch = value:gsub("^refs/heads/", "")
    elseif key == "prunable" and current then
      current.prunable = true
    end
  end
  return entries
end

local function repo_worktrees(settings, main)
  local repo = basename(main)
  local prefix = settings.root .. "/" .. repo .. "/"
  local list = {}
  for _, entry in ipairs(parse_porcelain(git_ok(main, "worktree", "list", "--porcelain"))) do
    if not entry.prunable and entry.path:lower():sub(1, #prefix) == prefix:lower() then
      list[#list + 1] = {
        repo = repo, name = basename(entry.path), path = entry.path, branch = entry.branch, main = main,
      }
    end
  end
  return list
end

local function children(dir)
  local result = run({ "find", dir, "-mindepth", "1", "-maxdepth", "1", "-type", "d" })
  local list = {}
  for line in result.stdout:gmatch("[^\n]+") do
    if basename(line):sub(1, 1) ~= "." then list[#list + 1] = line end
  end
  table.sort(list)
  return list
end

--- Lists worktrees under settings.root for main, or for every repo there when main is nil.
function M.list(settings, main)
  if main ~= nil then return repo_worktrees(settings, main) end
  local list = {}
  for _, repo_dir in ipairs(children(settings.root)) do
    for _, worktree in ipairs(children(repo_dir)) do
      local ok, repo_main = pcall(M.main_checkout, worktree)
      if ok then
        for _, entry in ipairs(repo_worktrees(settings, repo_main)) do list[#list + 1] = entry end
        break
      end
    end
  end
  return list
end

--- Finds one worktree by path or branch, among main's worktrees or all of them. Errors when none matches.
function M.find(settings, main, query)
  for _, entry in ipairs(M.list(settings, main)) do
    if (query.path and expand(query.path):lower() == entry.path:lower())
      or (query.branch and query.branch == entry.branch) then
      return entry
    end
  end
  error("no worktree matches " .. (query.path or query.branch or "nothing"), 0)
end

--- Removes a worktree; git refuses a dirty one unless force. The branch is kept.
function M.remove(entry, force)
  if force then
    git_ok(entry.main, "worktree", "remove", "--force", entry.path)
  else
    git_ok(entry.main, "worktree", "remove", entry.path)
  end
end

local function state_path(settings) return settings.root .. "/.sessions.json" end

local function live_sessions()
  local list, err = rex.session.list{}
  if err ~= nil then error(err, 0) end
  local live = {}
  for _, session in ipairs(list.sessions) do live[session.session_id] = true end
  return live
end

local function read_state(settings)
  local file = io.open(state_path(settings), "r")
  if file == nil then return {} end
  local text = file:read("*a")
  file:close()
  local ok, state = pcall(rex.json.decode, text)
  if not ok or type(state) ~= "table" then return {} end
  local live = live_sessions()
  for path, session_id in pairs(state) do
    if not live[session_id] then state[path] = nil end
  end
  return state
end

local function write_state(settings, state)
  run({ "mkdir", "-p", settings.root })
  local file = assert(io.open(state_path(settings), "w"))
  file:write(rex.json.encode(state))
  file:close()
end

--- Returns the live session id recorded for a worktree path, or nil.
function M.session_of(settings, path)
  return read_state(settings)[path]
end

--- Returns the worktree's live session, creating one with a terminal at its root when it has none.
function M.open(settings, entry)
  local state = read_state(settings)
  if state[entry.path] ~= nil then return state[entry.path], false end
  local result, err = rex.session.create{
    label = entry.repo .. "/" .. entry.name,
    initial_windows = {
      { layout = rex.layout.block{ flavor = terminal .. ".shell", options = { cwd = entry.path } } },
    },
  }
  if err ~= nil then error(err, 0) end
  state[entry.path] = result.session_id
  write_state(settings, state)
  return result.session_id, true
end

--- Destroys the worktree's session, if it has a live one, and forgets it.
function M.close(settings, path)
  local state = read_state(settings)
  local session_id = state[path]
  if session_id == nil then return end
  local _, err = rex.session.destroy{ session_id = session_id }
  if err ~= nil then error(err, 0) end
  state[path] = nil
  write_state(settings, state)
end

return M
