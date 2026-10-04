#!/bin/sh

pkill -x swaybg 2>/dev/null

find "$HOME/.config/hypr/wallpaper" -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0 |
  shuf -z -n 1 |
  xargs -0 -r swaybg -m fit -i
