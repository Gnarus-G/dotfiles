#!/bin/sh
set -eu

style=$(jq -r '.outputStyle // empty' "$HOME/.claude/settings.json")
[ -n "$style" ] || exit 0

for file in "$HOME"/.claude/output-styles/*.md; do
  [ -f "$file" ] || continue
  name=$(awk -F ': ' '/^name: / { print $2; exit }' "$file")
  [ "$name" = "$style" ] || continue
  printf 'Follow this output style in your response:\n'
  awk '/^---$/ { delimiters++; next } delimiters == 2 { print }' "$file"
  exit 0
done
