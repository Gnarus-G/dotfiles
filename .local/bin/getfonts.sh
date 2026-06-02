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

# Atkinson Hyperlegible Mono — not a Nerd Font, comes from Google Fonts.
# Used as the system-wide UI/monospace family (see .config/fontconfig).
# Variable fonts (wght axis); fontconfig resolves Medium/Bold from it.
echo "Downloading Atkinson Hyperlegible Mono"
atkinson_dir="$fonts_dir/AtkinsonHyperlegibleMono"
atkinson_base="https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegiblemono"
mkdir -p "$atkinson_dir"
wget -O "$atkinson_dir/AtkinsonHyperlegibleMono[wght].ttf" \
    "$atkinson_base/AtkinsonHyperlegibleMono%5Bwght%5D.ttf"
wget -O "$atkinson_dir/AtkinsonHyperlegibleMono-Italic[wght].ttf" \
    "$atkinson_base/AtkinsonHyperlegibleMono-Italic%5Bwght%5D.ttf"

fc-cache -fv
