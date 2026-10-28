#!/usr/bin/env bash
# Status line modeled on the oh-my-zsh "sunrise" theme:
#   --- <last 2 path parts> ‹branch*➔ AMRD MD UU ?›
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // empty')
# Context in use = input + cache tokens of the last turn, like ccstatusline's context-length.
ctx=$(echo "$input" | jq -r '.context_window.current_usage
  | if type == "number" then . elif type == "object" then
      (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
    else empty end')
# Remote Control is on when this session's file carries a bridge session id.
session_id=$(echo "$input" | jq -r '.session_id // empty')
rc=$(jq -r --arg id "$session_id" 'select(.sessionId == $id) | .bridgeSessionId // empty' \
  "$HOME"/.claude/sessions/*.json 2>/dev/null)

R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[34m'
C=$'\033[36m'; DIM=$'\033[2m'
BOLD=$'\033[1m'; RESET=$'\033[0m'

# %2~ : last two path components, $HOME shown as ~
dir=${cwd/#$HOME/\~}
if [[ $dir == */*/* ]]; then
  dir=$(printf '%s' "$dir" | awk -F/ '{print $(NF-1) "/" $NF}')
fi

git_part=""
ref=$(git -C "$cwd" --no-optional-locks symbolic-ref HEAD 2>/dev/null)
if [ -n "$ref" ]; then
  branch=${ref#refs/heads/}
  porcelain=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

  dirty=""
  [ -n "$porcelain" ] && dirty="${R}*"

  ahead=""
  n=$(git -C "$cwd" --no-optional-locks rev-list --count '@{upstream}..HEAD' 2>/dev/null)
  [ -n "$n" ] && [ "$n" -gt 0 ] && ahead="${B}➔"

  has() { printf '%s\n' "$porcelain" | grep -q -- "$1"; }
  status=""
  has '^A'    && status+="${G}A"
  has '^M'    && status+="${G}M"
  has '^R'    && status+="${G}R"
  has '^D  '  && status+="${G}D"
  if has '^.M ' || has '^AM ' || has '^ T '; then status+="${R}M"; fi
  has '^ D '  && status+="${R}D"
  has '^UU '  && status+="${R}UU"
  has '^?? '  && status+="${R}?"
  [ -n "$status" ] && status=" $status"

    # (+added,-removed) over staged and unstaged lines, like ccstatusline's git-changes.
  read -r added removed < <(git -C "$cwd" --no-optional-locks diff --numstat HEAD 2>/dev/null \
    | awk '{a+=$1; d+=$2} END {print a+0, d+0}')
  changes=" ${Y}(+${added},-${removed})${RESET}"

  git_part=" ${Y}‹${branch}${dirty}${ahead}${status}${Y}›${RESET}${changes}"
fi

head=""
[ -n "$rc" ] && head+="${G}RC${RESET} "
[ -n "$model" ] && head+="${C}${model}${RESET} "
if [ -n "$ctx" ]; then
  if [ "$ctx" -ge 1000 ]; then ctx_fmt=$(awk -v t="$ctx" 'BEGIN {printf "%.1fk", t/1000}'); else ctx_fmt=$ctx; fi
  head+="${DIM}Ctx: ${ctx_fmt}${RESET} "
fi

printf '%s%s--- %s%s%s' "$head" "$BOLD" "$dir" "$RESET" "$git_part"
