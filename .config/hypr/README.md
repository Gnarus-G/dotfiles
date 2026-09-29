# Hyprland setup

Install the desktop tools listed in [TOOLS.md](../../TOOLS.md) and run `./dev` from the repository root to link this directory.

## Machine profile

Write `home` or `work` as the only line of the machine-local `~/.config/rig-name` file, then run `hyprctl reload`. Without that file, no rig-specific profile is applied.

The `home` profile places DP-2 (3440×1440 at 120 Hz) above a centered DP-3 (1920×1200 at 60 Hz), both at scale 1. Workspaces 1–9 are persistent; Hyprland may create workspace 10 for the second monitor.

On login, Hyprland starts Waybar and `random-wallpaper.sh`, which picks an image from `wallpaper/` and displays it with `swaybg`. `hyprpaper.conf` is retained but is not used by this startup path.
