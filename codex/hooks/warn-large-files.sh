#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
source "$DIR/hook-lib.sh"
command -v jq >/dev/null 2>&1 || codex_deny "jq is required for generated-file protection hooks but is not installed."
codex_hook_input

while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in
    node_modules/*|*/node_modules/*|vendor/*|*/vendor/*|dist/*|*/dist/*|build/*|*/build/*|.next/*|*/.next/*|__pycache__/*|*/__pycache__/*|.venv/*|*/.venv/*|venv/*|*/venv/*)
      codex_deny "Cannot write dependency, environment, or generated build output: $path" ;;
  esac
  case "$(basename "$path")" in
    *.wasm|*.so|*.dylib|*.dll|*.exe|*.o|*.a|*.zip|*.tar|*.tar.gz|*.tar.bz2|*.tgz|*.rar|*.7z|*.mp4|*.mov|*.avi|*.mkv|*.mp3|*.wav|*.flac|*.pyc|*.pyo|*.class)
      codex_deny "Cannot write binary, archive, media, or compiled output: $path" ;;
  esac
done < <(codex_patch_paths)

exit 0
