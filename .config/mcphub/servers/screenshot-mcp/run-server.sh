#!/bin/bash
set -euo pipefail

get_x_env() {
    local display="${DISPLAY:-}"
    local xauthority="${XAUTHORITY:-}"

    if [[ -n "$display" && -n "$xauthority" && -f "$xauthority" ]]; then
        echo "$display|$xauthority"
        return 0
    fi

    if command -v xauth &>/dev/null && [[ -n "$display" ]]; then
        local xauth_info
        xauth_info=$(xauth list "$display" 2>/dev/null | head -1) || true
        if [[ -n "$xauth_info" ]]; then
            local xauth_file
            xauth_file=$(xauth info 2>/dev/null | grep "Authority file" | awk '{print $NF}') || true
            if [[ -n "$xauth_file" && -f "$xauth_file" ]]; then
                echo "$display|$xauth_file"
                return 0
            fi
        fi
    fi

    if [[ -f ~/.Xauthority ]]; then
        echo ":0|$HOME/.Xauthority"
        return 0
    fi

    local tmp_xauth
    tmp_xauth=$(ls -t /tmp/xauth_* 2>/dev/null | head -1) || true
    if [[ -n "$tmp_xauth" && -f "$tmp_xauth" ]]; then
        echo ":0|$tmp_xauth"
        return 0
    fi

    echo "Could not determine X11 environment" >&2
    return 1
}

main() {
    local x_env
    x_env=$(get_x_env) || exit 1

    export DISPLAY="${x_env%|*}"
    export XAUTHORITY="${x_env#*|}"

    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"

    "$script_dir/.venv/bin/python" "$script_dir/server.py"
}

main