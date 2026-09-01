#!/usr/bin/env bash
# Drives bin/sync-omarchy against a throwaway copy of the working tree, a scratch
# HOME, and stubbed omarchy/pacman binaries that record what they were asked to
# do. Touches nothing real and needs no Omarchy install.
# Run: bash bin/sync-omarchy.test.sh
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

run() {
  PATH="$WORK/stub:/usr/bin:/bin" "$WORK/repo/bin/sync-omarchy" "$@" > "$WORK/out" 2>&1
  rc=$?
  out="$WORK/out"
}

# --- Scratch machine ---------------------------------------------------------

mkdir -p "$WORK/repo" "$WORK/home" "$WORK/config" "$WORK/stub"
tar -C "$REPO" --exclude .git -cf - . | tar -C "$WORK/repo" -xf -
export HOME="$WORK/home"
export XDG_CONFIG_HOME="$WORK/config"
APPS="$HOME/.local/share/applications"
STATE="$HOME/.local/state/omarchy/current"
mkdir -p "$APPS" "$STATE/theme/backgrounds"

# Stubs record every call and read their answers out of the scratch HOME, so a
# test can set up a machine state and then assert on what was asked of it.
cat > "$WORK/stub/omarchy" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/calls.log"
case "$1 $2" in
  "theme current")  cat "$HOME/theme" 2>/dev/null ;;
  "font current")   cat "$HOME/font" 2>/dev/null ;;
  "theme extras")   cat "$HOME/theme-extras" 2>/dev/null ;;
  "theme set")      printf '%s' "$3" > "$HOME/theme" ;;
  "font set")       printf '%s' "$3" > "$HOME/font" ;;
  "theme bg")       ln -sfn "$4" "$HOME/.local/state/omarchy/current/background" ;;
  "webapp install") printf 'webapp\n' > "$HOME/.local/share/applications/$3.desktop" ;;
  "tui install")    printf 'tui\n'    > "$HOME/.local/share/applications/$3.desktop" ;;
  "pkg drop")       shift 2; for p in "$@"; do sed -i "/^$p\$/d" "$HOME/pkgs"; done ;;
  "plugin list")    cat "$HOME/plugins" 2>/dev/null ;;
  "plugin enable")  sed -i "s/^$3 disabled/$3 enabled/" "$HOME/plugins" ;;
  *) exit 0 ;;
esac
STUB

cat > "$WORK/stub/pacman" <<'STUB'
#!/usr/bin/env bash
[ "$1" = "-Qq" ] || exit 0
[ -n "${2:-}" ] || { cat "$HOME/pkgs" 2>/dev/null; exit 0; }
grep -qx "$2" "$HOME/pkgs" 2>/dev/null
STUB

# yay and update-desktop-database only need to record that they were reached.
# Without a yay stub the harness would run real package installs.
for noop in yay update-desktop-database; do
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$0 $*" >> "$HOME/calls.log"\nexit 0\n' > "$WORK/stub/$noop"
done
chmod +x "$WORK/stub"/*

touch "$STATE/theme/btop.theme"
printf 'omarchy.tailscale disabled\n' > "$HOME/plugins"

# A machine with the Archfile satisfied but nothing from the Omarchyfile applied,
# so the checks below speak to Omarchy state rather than re-testing bin/dots.
sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$WORK/repo/Archfile" |
  grep -v '^$' > "$HOME/pkgs"
touch "$STATE/theme/backgrounds/0-winding-road.jpg"

# --- Tests -------------------------------------------------------------------

echo "help"
run -h
check "exits 0"            '[ $rc -eq 0 ]'
check "prints usage"       'grep -q "Usage: bin/sync-omarchy" "$out"'

echo "check — nothing applied yet"
run -c
check "exits 1"                 '[ $rc -eq 1 ]'
check "reports the theme"       'grep -q "manifest says .Tokyo Night." "$out"'
check "reports the font"        'grep -q "JetBrainsMono Nerd Font" "$out"'
check "reports a missing web app" 'grep -q "web app Linear" "$out"'
check "reports the btop theme link" 'grep -q "btop theme link" "$out"'
check "reports the disabled bar plugin" 'grep -q "bar plugin omarchy.tailscale" "$out"'
check "reports the TUI"         'grep -q "TUI Zen Octo" "$out"'
check "changes nothing"         '[ ! -e "$HOME/theme" ] && [ -z "$(ls -A "$APPS")" ]'

echo "dry-run"
run -n
check "creates no launcher"  '[ -z "$(ls -A "$APPS")" ]'
check "sets no theme"        '[ ! -e "$HOME/theme" ]'
check "names the commands"   'grep -q "DRY-RUN" "$out"'

echo "apply"
run
check "exits 0"                  '[ $rc -eq 0 ]'
check "sets the theme"           '[ "$(cat "$HOME/theme")" = "Tokyo Night" ]'
check "sets the font"            '[ "$(cat "$HOME/font")" = "JetBrainsMono Nerd Font" ]'
check "links the background"     '[ "$(basename "$(readlink "$STATE/background")")" = "0-winding-road.jpg" ]'
check "installs the web apps"    '[ -e "$APPS/Linear.desktop" ] && [ -e "$APPS/Superhuman.desktop" ] && [ -e "$APPS/Tailscale.desktop" ]'
check "enables the bar plugin"   'grep -qx "omarchy.tailscale enabled" "$HOME/plugins"'
check "passes a webapp its icon URL" \
  'grep -q "^webapp install Tailscale https://login.tailscale.com/admin/machines https://cdn.jsdelivr.net" "$HOME/calls.log"'
check "installs the TUI"         '[ -e "$APPS/Zen Octo.desktop" ]'
check "writes the font size"     'grep -q "base-size = 14" "$XDG_CONFIG_HOME/omarchy/shell.toml"'
check "relinks btop's theme"     '[ "$XDG_CONFIG_HOME/btop/themes/current.theme" -ef "$STATE/theme/btop.theme" ]'
check "lets the site pick a web app icon" \
  'grep -q "^webapp install Linear https://linear.app  *$" "$HOME/calls.log"'
check "passes the TUI an absolute icon path" \
  'grep -q "tui install Zen Octo zen-octo float $WORK/repo/icons/zen-octo.png" "$HOME/calls.log"'

echo "apply — idempotent"
: > "$HOME/calls.log"
run
check "exits 0"                '[ $rc -eq 0 ]'
check "applies nothing new"    'grep -qE "^  Applied +0$" "$out"'
check "leaves nothing unresolved" 'grep -qE "^  Unresolved +0$" "$out"'
check "installs no launcher"   '! grep -q "webapp install" "$HOME/calls.log"'

echo "check — clean machine"
run -c
check "exits 0"              '[ $rc -eq 0 ]'
check "reports no drift"     'grep -qE "^  Unresolved +0$" "$out"'

echo "removals"
printf 'pinta\nfoot\nneovim\n' > "$HOME/pkgs"  # Archfile now unsatisfied; the removal checks below ignore that
printf 'x\n' > "$APPS/Discord.desktop"
printf 'x\n' > "$APPS/YouTube.desktop"
mkdir -p "$HOME/.local/bin" && printf 'x\n' > "$HOME/.local/bin/opencode"
run -c
check "spots the installed drops"  'grep -q "still installed: foot pinta" "$out"'
check "spots the stale launchers"  'grep -q "still present: Discord YouTube" "$out"'
check "spots the stale mise stub"  'grep -q "still present: opencode" "$out"'
: > "$HOME/calls.log"
run
check "drops only what is installed" 'grep -qx "pkg drop foot pinta" "$HOME/calls.log"'
check "leaves other packages alone"  'grep -qx "neovim" "$HOME/pkgs"'
check "deletes the launchers"        '[ ! -e "$APPS/Discord.desktop" ] && [ ! -e "$APPS/YouTube.desktop" ]'
check "deletes the mise stub"        '[ ! -e "$HOME/.local/bin/opencode" ]'
check "keeps the ones it installed"  '[ -e "$APPS/Linear.desktop" ]'

echo "manifest — a background the theme does not have"
rm -f "$STATE/theme/backgrounds/0-winding-road.jpg"
run -c
check "exits 1"            '[ $rc -eq 1 ]'
check "names the theme dir" 'grep -q "not in the current theme" "$out"'

echo
if [ "$fails" -eq 0 ]; then
  echo "✓ All checks passed."
else
  echo "✖ $fails check(s) failed."
fi
exit $((fails > 0))
