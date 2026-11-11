#!/usr/bin/env bash
# Drives configs/rex/worktree.lua through `rex do` against a throwaway repo and worktree root.
# Sessions are not touched. Run: bash configs/rex/worktree.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -r -f -- "$WORK"' EXIT

fails=0
rc=0
out=""

check() {
  if eval "$2"; then
    echo "  ok    $1"
  else
    echo "  FAIL  $1"
    fails=$((fails + 1))
  fi
}

cat > "$WORK/driver.lua" <<'LUA'
local W = dofile(rex.args.module)
local settings = W.load_settings(rex.args.config)
local a = rex.args
local main = a.dir ~= "" and W.main_checkout(a.dir) or nil
if a.op == "main" then return { main = main } end
if a.op == "create" then return W.create(settings, main, a.branch, a.base) end
if a.op == "list" then return W.list(settings, main) end
if a.op == "carry" then return W.carry(main, a.worktree, a.paths) end
if a.op == "remove" then
  local entry = W.find(settings, main, { branch = a.branch })
  W.remove(entry, a.force)
  return { removed = entry.path }
end
error("unknown op " .. tostring(a.op), 0)
LUA

# Run one driver op with a JSON args object merged over the defaults.
op() {
  local args
  args="$(jq -cn --arg module "$HERE/worktree.lua" --arg config "$WORK/worktrees.lua" --arg dir "$REPO" \
    --argjson extra "$1" '{module: $module, config: $config, dir: $dir} + $extra')"
  rex do "$WORK/driver.lua" --args "$args" --json > "$WORK/out" 2>&1
  rc=$?
  out="$WORK/out"
}

REPO="$WORK/sample-repo"
ROOT="$WORK/worktrees"
mkdir -p "$REPO/config" "$REPO/node_modules/pkg" "$REPO/nested/deep"
git -C "$REPO" init -q -b main
printf '.env\nnode_modules/\nconfig/secret.key\nnested/\n' > "$REPO/.gitignore"
echo tracked > "$REPO/tracked.txt"
echo app > "$REPO/config/app.yml"
git -C "$REPO" add -A
git -C "$REPO" -c user.name=t -c user.email=t@t commit -q -m init
echo SECRET=1 > "$REPO/.env"
echo 'module.exports = 1' > "$REPO/node_modules/pkg/index.js"
echo key > "$REPO/config/secret.key"
echo deep > "$REPO/nested/deep/x.key"

upper_repo="$(printf '%s' "$REPO" | tr '[:lower:]' '[:upper:]')"
cat > "$WORK/worktrees.lua" <<LUA
return {
  root = "$ROOT",
  repos = {
    ["$upper_repo"] = {
      carry = { ".env", "node_modules", "config/secret.key", "nested/deep/x.key",
                "tracked.txt", "config", "missing.env", "../escape" },
    },
  },
}
LUA

echo "create"
op '{"op":"create","branch":"feat/one"}'
WT="$ROOT/sample-repo/feat-one"
check "succeeds" '[ $rc -eq 0 ]'
check "path is root/repo/name" '[ "$(jq -r .path "$out")" = "$WT" ]'
check "branch checked out" '[ "$(git -C "$WT" branch --show-current)" = "feat/one" ]'
check "carries ignored files, case-insensitive repo key" \
  '[ "$(jq -c ".carry.carried" "$out")" = "[\".env\",\"node_modules\",\"config/secret.key\",\"nested/deep/x.key\"]" ]'
check "copied contents arrive" '[ "$(cat "$WT/nested/deep/x.key")" = deep ] && [ -f "$WT/node_modules/pkg/index.js" ]'
check "skips tracked file" 'jq -e ".carry.skipped[] | select(.name==\"tracked.txt\" and .reason==\"is tracked by git\")" "$out" > /dev/null'
check "skips folder holding tracked files" 'jq -e ".carry.skipped[] | select(.name==\"config\")" "$out" > /dev/null'
check "skips path leaving repo" 'jq -e ".carry.skipped[] | select(.name==\"../escape\" and .reason==\"leaves the repository\")" "$out" > /dev/null'
check "missing path is silent" '! grep -q missing.env "$out"'
check "worktree is clean" '[ -z "$(git -C "$WT" status --porcelain)" ]'

echo "carry again"
op "$(jq -cn --arg wt "$WT" '{op:"carry",worktree:$wt,paths:[".env"]}')"
check "leaves existing path alone" 'jq -e ".skipped[0].reason==\"already in the worktree\"" "$out" > /dev/null'

echo "main checkout"
REPO="$WT" op '{"op":"main"}'
check "resolves from inside a worktree" '[ "$(jq -r .main "$out")" = "$REPO" ]'

echo "create refusals"
op '{"op":"create","branch":"feat/one"}'
check "refuses existing path" '[ $rc -ne 0 ] && grep -q "already exists" "$out"'
op '{"op":"create","branch":"bad..name"}'
check "refuses invalid branch" '[ $rc -ne 0 ]'

echo "existing branch"
git -C "$REPO" branch existing
op '{"op":"create","branch":"existing"}'
check "checks out existing branch" '[ $rc -eq 0 ] && [ "$(git -C "$ROOT/sample-repo/existing" branch --show-current)" = existing ]'

echo "list"
op '{"op":"list"}'
check "lists repo worktrees, not main" '[ "$(jq -r "[.[].branch] | sort | join(\",\")" "$out")" = "existing,feat/one" ]'
REPO="" op '{"op":"list"}'
check "lists all repos under root" '[ "$(jq length "$out")" = 2 ]'

echo "remove"
op '{"op":"remove","branch":"existing"}'
check "removes clean worktree" '[ $rc -eq 0 ] && [ ! -e "$ROOT/sample-repo/existing" ]'
check "keeps branch" 'git -C "$REPO" show-ref --verify --quiet refs/heads/existing'
echo dirty >> "$WT/tracked.txt"
op '{"op":"remove","branch":"feat/one"}'
check "refuses dirty worktree" '[ $rc -ne 0 ] && [ -e "$WT" ]'
op '{"op":"remove","branch":"feat/one","force":true}'
check "force removes dirty worktree" '[ $rc -eq 0 ] && [ ! -e "$WT" ]'
op '{"op":"remove","branch":"nope"}'
check "unknown worktree errors" '[ $rc -ne 0 ] && grep -q "no worktree matches" "$out"'

if [ "$fails" -eq 0 ]; then
  echo "all passed"
else
  echo "$fails failed"
  exit 1
fi
