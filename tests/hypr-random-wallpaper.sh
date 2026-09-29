#!/bin/sh
set -eu

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.config/hypr/wallpaper/nsfw" "$tmp/home/.local/bin" "$tmp/runtime"
printf 'image' > "$tmp/home/.config/hypr/wallpaper/nsfw/test image.jpg"
printf 'not an image' > "$tmp/home/.config/hypr/wallpaper/readme.txt"
printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "$XDG_RUNTIME_DIR/invoked"\n' > "$tmp/home/.local/bin/swaybg"
chmod +x "$tmp/home/.local/bin/swaybg"
HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/runtime" sh .config/hypr/random-wallpaper.sh
printf '%s\n' '-m' 'fit' '-i' "$tmp/home/.config/hypr/wallpaper/nsfw/test image.jpg" > "$tmp/runtime/expected"
cmp "$tmp/runtime/expected" "$tmp/runtime/invoked"
