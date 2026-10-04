#!/bin/sh

pkill -x swaybg 2>/dev/null

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
find "$HOME/.config/hypr/wallpaper" -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0 |
  shuf -z > "$tmp"

# One swaybg instance, one shuffled image per output.
hyprctl monitors -j |
  jq -ej --rawfile walls "$tmp" '
    ($walls | split("\u0000") | map(select(length > 0))) as $walls
    | ([.[].name]) as $outputs
    | [range(0; $outputs | length) as $i
        | "-o", $outputs[$i], "-i", $walls[$i % ($walls | length)], "-m", "fit"]
      | join("\u0000")' |
  xargs -0 -r swaybg