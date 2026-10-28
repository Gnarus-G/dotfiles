#!/usr/bin/env bash
# Status line modeled on the oh-my-zsh "sunrise" theme:
#   --- <last 2 path parts> ‹branch*➔ AMRD MD UU ?›
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; B=$'\033[34m'
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

  git_part=" ${Y}‹${branch}${dirty}${ahead}${status}${Y}›${RESET}"
fi

printf '%s--- %s%s%s' "$BOLD" "$dir" "$RESET" "$git_part"
