#!/usr/bin/env bash
# Drives every bin/dots subcommand against a throwaway copy of the working tree
# and a scratch XDG_CONFIG_HOME. Touches nothing real. Run: bash bin/dots.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d)"
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

# Run bin/dots, capturing status and output for the checks that follow.
run() {
  "$WORK/repo/bin/dots" "$@" > "$WORK/out" 2>&1
  rc=$?
  out="$WORK/out"
}

# As run(), with Homebrew off PATH — isolates the section checks from whatever
# this machine happens to have installed.
run_nobrew() {
  PATH=/usr/bin:/bin "$WORK/repo/bin/dots" "$@" > "$WORK/out" 2>&1
  rc=$?
  out="$WORK/out"
}

# Copy the working tree (not HEAD) so the test covers uncommitted changes.
mkdir -p "$WORK/repo" "$WORK/config" "$WORK/home"
tar -C "$REPO" --exclude .git -cf - . | tar -C "$WORK/repo" -xf -
export HOME="$WORK/home"
export XDG_CONFIG_HOME="$WORK/config"
git -C "$WORK/repo" init -q >/dev/null 2>&1
git -C "$WORK/repo" add -A >/dev/null 2>&1
git -C "$WORK/repo" -c user.email=t@example.com -c user.name=t commit -qm init >/dev/null 2>&1

n_configs="$(find "$WORK/repo/configs" -maxdepth 1 -mindepth 1 | wc -l | tr -d ' ')"

echo "install — clean machine"
run install
check "exits 0"            '[ $rc -eq 0 ]'
check "links every config" "[ \$(grep -cE '^  Linked +$((n_configs + 2))\$' \"\$out\") -eq 1 ]"
check "links a directory config" '[ "$XDG_CONFIG_HOME/nvim" -ef "$WORK/repo/configs/nvim" ]'
check "links a loose file config" '[ "$XDG_CONFIG_HOME/starship.toml" -ef "$WORK/repo/configs/starship.toml" ]'
check "~/.zshrc points at the repo, not through ~/.config" \
  '[ "$HOME/.zshrc" -ef "$WORK/repo/configs/zsh/.zshrc" ] && case "$(readlink "$HOME/.zshrc")" in */configs/zsh/.zshrc) true ;; *) false ;; esac'
check "~/.zprofile is linked"      '[ -L "$HOME/.zprofile" ]'

echo "install — idempotent"
run install
check "exits 0"                    '[ $rc -eq 0 ]'
check "links nothing new"          'grep -qE "^  Linked +0$" "$out"'
check "counts them already ok"     "grep -qE '^  Already ok +$((n_configs + 2))\$' \"\$out\""

echo "install -n — read-only"
rm "$XDG_CONFIG_HOME/btop"
before="$(ls -A "$XDG_CONFIG_HOME" | wc -l)"
run install -n
check "creates nothing"  '[ "$(ls -A "$XDG_CONFIG_HOME" | wc -l)" = "$before" ]'
run install

echo "install — conflict is non-blocking"
rm "$XDG_CONFIG_HOME/btop"
mkdir -p "$XDG_CONFIG_HOME/btop" && echo drift > "$XDG_CONFIG_HOME/btop/real.conf"
rm "$XDG_CONFIG_HOME/eza"
run install
check "exits 1"                    '[ $rc -eq 1 ]'
check "reports one unresolved"     'grep -qE "^  Unresolved +1$" "$out"'
check "names the conflict"         'grep -q "btop" "$out"'
check "suggests migrate"           'grep -q "bin/dots migrate btop" "$out"'
check "leaves the real dir alone"  '[ -f "$XDG_CONFIG_HOME/btop/real.conf" ]'
check "still links the others"     '[ "$XDG_CONFIG_HOME/eza" -ef "$WORK/repo/configs/eza" ]'
run install -f
check "-f still refuses a directory" '[ $rc -eq 1 ] && [ -f "$XDG_CONFIG_HOME/btop/real.conf" ]'

echo "add"
run add scratchpad
check "exits 0"                 '[ $rc -eq 0 ]'
check "creates the repo dir"    '[ -d "$WORK/repo/configs/scratchpad" ]'
check "links it out"            '[ "$XDG_CONFIG_HOME/scratchpad" -ef "$WORK/repo/configs/scratchpad" ]'
check "adds a Brewfile section" 'grep -qxF "# --- config: scratchpad ---" "$WORK/repo/Brewfile"'
check "keeps existing sections intact" \
  'grep -qxF "# --- config: yazi ---" "$WORK/repo/Brewfile"'
run add scratchpad
check "refuses to re-add"       '[ $rc -ne 0 ]'
check "points at install"       'grep -q "bin/dots install" "$out"'

echo "migrate"
mkdir -p "$XDG_CONFIG_HOME/adopted" && echo hi > "$XDG_CONFIG_HOME/adopted/x.conf"
run migrate adopted nope
check "exits 1 for the missing name"     '[ $rc -eq 1 ]'
check "moves content into the repo"      '[ "$(cat "$WORK/repo/configs/adopted/x.conf")" = hi ]'
check "links it back"                    '[ "$XDG_CONFIG_HOME/adopted" -ef "$WORK/repo/configs/adopted" ]'
check "adds a Brewfile section"          'grep -qxF "# --- config: adopted ---" "$WORK/repo/Brewfile"'
check "names the bad one"                'grep -q "nope" "$out"'
check "the good one still went through"  'grep -qE "^  Linked +1$" "$out"'
run migrate adopted
check "refuses an existing symlink"      '[ $rc -eq 1 ]'

echo "brew -c"
run_nobrew brew -c
check "exits 0 when sections match configs" '[ $rc -eq 0 ]'
check "omits a config that has a section"   '! grep -qx "    adopted" "$out"'
sed -i.bak '/^# --- config: adopted ---$/d' "$WORK/repo/Brewfile"
run_nobrew brew -c
check "lists a config with no section" 'grep -q "declare no packages" "$out" && grep -qx "    adopted" "$out"'
check "declaring nothing is not a failure" '[ $rc -eq 0 ]'
echo "# --- config: ghost ---" >> "$WORK/repo/Brewfile"
run_nobrew brew -c
check "flags a section with no config"      'grep -q "sections with no config" "$out" && grep -qx "    ghost" "$out"'
check "exits non-zero on an orphan section" '[ $rc -ne 0 ]'
sed -i.bak2 '/^# --- config: ghost ---$/d' "$WORK/repo/Brewfile"
run_nobrew brew
check "brew install is a no-op without Homebrew" '[ $rc -eq 0 ] && grep -q "Homebrew not found" "$out"'

echo "remove"
run remove scratchpad -y
check "exits 0"                  '[ $rc -eq 0 ]'
check "drops the link"           '[ ! -e "$XDG_CONFIG_HOME/scratchpad" ] && [ ! -L "$XDG_CONFIG_HOME/scratchpad" ]'
check "drops the repo dir"       '[ ! -e "$WORK/repo/configs/scratchpad" ]'
check "drops the section"        '! grep -qxF "# --- config: scratchpad ---" "$WORK/repo/Brewfile"'
check "leaves neighbours intact" 'grep -qxF "# --- config: yazi ---" "$WORK/repo/Brewfile" && grep -qxF "# --- config: zsh ---" "$WORK/repo/Brewfile"'
check "keeps yazi packages"      '[ "$(grep -c "^brew \"ffmpeg\"$" "$WORK/repo/Brewfile")" -eq 1 ]'

mkdir -p "$XDG_CONFIG_HOME/foreign"
run remove foreign -y
check "refuses a real directory" '[ $rc -ne 0 ] && [ -d "$XDG_CONFIG_HOME/foreign" ]'

ln -s /tmp "$XDG_CONFIG_HOME/elsewhere"
run remove elsewhere -y
check "refuses a link out of the repo" '[ $rc -ne 0 ] && [ -L "$XDG_CONFIG_HOME/elsewhere" ]'

echo
if [ "$fails" -eq 0 ]; then
  echo "✓ all checks passed"
else
  echo "✖ $fails check(s) failed"
  exit 1
fi
