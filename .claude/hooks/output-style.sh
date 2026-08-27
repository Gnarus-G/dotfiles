#!/bin/sh
set -eu

style=$(jq -r '.outputStyle // empty' "$HOME/.claude/settings.json")
[ -n "$style" ] || exit 0

for file in "$HOME"/.claude/output-styles/*.md; do
  [ -f "$file" ] || continue
  name=$(awk -F ': ' '/^name: / { print $2; exit }' "$file")
  [ "$name" = "$style" ] || continue
  description=$(awk -F ': ' '/^description: / { print $2; exit }' "$file")
  [ -n "$description" ] && printf 'Output style: %s\n' "$description"
  exit 0
done
