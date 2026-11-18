#!/bin/bash
# Claude Code status line.
# Left:  [repo] [branch] [state] [status]
# Right: [context tokens] [model] [5h / 7d usage limits with reset times] (right-aligned to the terminal width)
# Git segments (branch/state/status) keep the glyphs/colors originally
# translated from ~/.config/starship.toml's [git_branch]/[git_state]/[git_status].

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd')
if [ -z "$cwd" ] || [ "$cwd" = "null" ]; then
  cwd="$PWD"
fi

RESET=$'\033[0m'
BOLD=$'\033[1m'
ITALIC=$'\033[3m'
BR_BLUE=$'\033[94m'
BLUE=$'\033[34m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
BR_YELLOW=$'\033[93m'
BR_CYAN=$'\033[96m'
BR_MAGENTA=$'\033[95m'
BR_BLACK=$'\033[90m'
BR_GREEN=$'\033[92m'

# --- repo name (basename of the git root; falls back to the cwd's basename
#     when not in a repo), styled like the directory segment it replaces ---
repo_name() {
  local full="$1" repo_root
  repo_root=$(git -C "$full" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$repo_root" ]; then
    basename "$repo_root"
  else
    basename "$full"
  fi
}

out="${BOLD}${BR_BLUE}$(repo_name "$cwd")${RESET} ${BR_GREEN}"

# --- git branch ([git_branch]: green symbol (empty here) + muted branch) ---
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
  branch_max=24
  if [ "${#branch}" -gt "$branch_max" ]; then
    branch="${branch:0:$((branch_max - 1))}…"
  fi
  if [ -n "$branch" ]; then
    out+=" ${BR_BLACK}${branch}${RESET} "
  fi

  # --- git state ([git_state]: bright-black "(state)" while mid-operation) ---
  gitdir=$(git -C "$cwd" --no-optional-locks rev-parse --git-dir 2>/dev/null)
  state=""
  if [ -n "$gitdir" ]; then
    case "$gitdir" in /*) ;; *) gitdir="$cwd/$gitdir" ;; esac
    if [ -f "$gitdir/MERGE_HEAD" ]; then
      state="MERGING"
    elif [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ]; then
      state="REBASING"
    elif [ -f "$gitdir/CHERRY_PICK_HEAD" ]; then
      state="CHERRY-PICKING"
    elif [ -f "$gitdir/REVERT_HEAD" ]; then
      state="REVERTING"
    elif [ -f "$gitdir/BISECT_LOG" ]; then
      state="BISECTING"
    fi
  fi
  [ -n "$state" ] && out+="${BR_BLACK}(${state})${RESET} "

  # --- git status ([git_status]: ahead/behind, staged, modified, untracked,
  #     renamed, deleted, conflicted, stashed) ---
  ahead=0
  behind=0
  staged=0
  modified=0
  deleted=0
  renamed=0
  untracked=0
  conflicted=0
  status_output=$(git -C "$cwd" --no-optional-locks status --porcelain=2 --branch 2>/dev/null)
  while IFS= read -r line; do
    case "$line" in
    "# branch.ab "*)
      ab="${line#"# branch.ab "}"
      a="${ab%% *}"
      b="${ab##* }"
      ahead="${a#+}"
      behind="${b#-}"
      ;;
    "1 "*)
      xy="${line:2:2}"
      x="${xy:0:1}"
      y="${xy:1:1}"
      [ "$x" != "." ] && staged=$((staged + 1))
      case "$y" in
      M) modified=$((modified + 1)) ;;
      D) deleted=$((deleted + 1)) ;;
      esac
      ;;
    "2 "*)
      renamed=$((renamed + 1))
      xy="${line:2:2}"
      x="${xy:0:1}"
      [ "$x" != "." ] && staged=$((staged + 1))
      ;;
    "u "*)
      conflicted=$((conflicted + 1))
      ;;
    "? "*)
      untracked=$((untracked + 1))
      ;;
    esac
  done <<<"$status_output"
  stashed=$(git -C "$cwd" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')

  if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then
    out+="${BR_MAGENTA}⇕ ⇡${ahead} ⇣${behind}${RESET} "
  elif [ "${ahead:-0}" -gt 0 ]; then
    out+="${ITALIC}${BLUE}⇡${ahead}${RESET} "
  elif [ "${behind:-0}" -gt 0 ]; then
    out+="${ITALIC}${RED}⇣${behind}${RESET} "
  fi
  [ "$staged" -gt 0 ] && out+="${BR_CYAN}+${staged}${RESET} "
  [ "$modified" -gt 0 ] && out+="${YELLOW}~${modified}${RESET} "
  [ "$untracked" -gt 0 ] && out+="${BR_YELLOW}?${untracked}${RESET} "
  [ "$renamed" -gt 0 ] && out+="${BLUE}»${RESET} "
  [ "$deleted" -gt 0 ] && out+="${ITALIC}${RED}-${deleted}${RESET} "
  [ "$conflicted" -gt 0 ] && out+="${ITALIC}${BR_MAGENTA}≠${RESET} "
  [ "${stashed:-0}" -gt 0 ] && out+="${BR_GREEN}󰏢${RESET} "
fi

# --- context tokens + model, right-aligned to the terminal width ---
strip_ansi() {
  printf '%s' "$1" | sed -E $'s/\x1b\\[[0-9;]*m//g'
}

# trim trailing spaces left over from the last segment
while [[ "$out" == *" " ]]; do out="${out% }"; done

STATUS_INSET=4 # Claude Code pads the status row inside $COLUMNS and clips anything past it

format_tokens() {
  local n="$1"
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fM", n / 1000000 }'
  elif [ "$n" -ge 1000 ]; then
    printf '%dk' $(((n + 500) / 1000))
  else
    printf '%d' "$n"
  fi
}

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
context_tokens=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
tokens=""
[ "$context_tokens" -gt 0 ] 2>/dev/null && tokens="$(format_tokens "$context_tokens")"
limits=$(printf '%s' "$input" | jq -r '
  def clock: strflocaltime("%-I:%M%p") | ascii_downcase | sub(":00"; "");
  def window($label; resets):
    select(.used_percentage != null)
    | "\(.used_percentage | round)% " + (if .resets_at then "↻" + (.resets_at | resets) else $label end);
  [(.rate_limits.five_hour // empty | window("5h"; clock)),
   (.rate_limits.seven_day // empty | window("7d"; strflocaltime("%a ") + clock))]
  | join(" · ")')

right=""
right_visible=""
if [ -n "$tokens" ]; then
  right="${BR_BLACK}${tokens}${RESET}"
  right_visible="$tokens"
fi
if [ -n "$model" ]; then
  [ -n "$right" ] && right+=" ${BR_BLACK}·${RESET} " && right_visible+=" · "
  right+="${BOLD}${BR_BLACK}${model}${RESET}"
  right_visible+="$model"
fi
if [ -n "$limits" ]; then
  [ -n "$right" ] && right+=" ${BR_BLACK}|${RESET} " && right_visible+=" | "
  right+="${BR_BLACK}${limits}${RESET}"
  right_visible+="$limits"
fi

cols="${COLUMNS:-}"
if [ -z "$cols" ]; then
  cols=$(tput cols 2>/dev/null)
fi
[ -z "$cols" ] && cols=80
cols=$((cols - STATUS_INSET))

if [ -n "$right" ]; then
  left_visible=$(strip_ansi "$out")
  left_len=${#left_visible}
  right_len=${#right_visible}
  short_model="${model% (*}"
  if [ $((left_len + 1 + right_len)) -gt "$cols" ] && [ "$short_model" != "$model" ]; then
    short_styled="${short_model}${RESET}"
    right="${right/"${model}${RESET}"/$short_styled}"
    right_len=$((right_len - ${#model} + ${#short_model}))
  fi
  pad=$((cols - left_len - right_len))
  [ "$pad" -lt 1 ] && pad=1

  out+="$(printf '%*s' "$pad" '')${right}"
fi

printf '%s\n' "$out"
