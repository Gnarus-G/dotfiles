#!/usr/bin/sh

# Adapted from:
# https://gist.github.com/matthewjberger/7dd7e079f282f8138a9dc3b045ebefa0?permalink_comment_id=4005789#gistcomment-4005789

set -euo pipefail

FONTS=(
    CodeNewRoman
    FiraCode
    FiraMono
    Hack
    Noto
    RobotoMono
    SourceCodePro
)

fonts_dir="$HOME/.local/share/fonts"
mkdir -p "$fonts_dir"

BASE_URL=https://github.com/ryanoasis/nerd-fonts/releases

VERSION=$(wget -qO- $BASE_URL/latest | grep -oP 'v\d+\.\d+\.\d+' | tail -n 1);

for font in "${FONTS[@]}"; do
    zip_file="${font}.zip"
    download_url="$BASE_URL/download/$VERSION/${zip_file}"
    echo "Downloading $download_url"
    wget "$download_url"
    unzip "$zip_file" -d "$fonts_dir"
    rm "$zip_file"
done

find "$fonts_dir" -name '*Windows Compatible*' -delete

fc-cache -fv
