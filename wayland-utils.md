# Useful Wayland Utilities — for my Hyprland setup

Based on the [Hyprland wiki](https://wiki.hypr.land/useful-utilities/), checked against what's already installed.

## Installed for this Hyprland setup

- `swaybg` displays the wallpaper selected by `random-wallpaper.sh`.
- `waybar-git` replaces the repository `waybar` 0.15.0 package: that release sends legacy workspace-click commands, which Hyprland's Lua config rejects. `paru -S waybar-git` builds the version with Lua dispatch support; its build also installed `catch2` and `scdoc` as make dependencies.
- `grim`, `slurp`, and `wl-clipboard` (the `wl-copy` command), plus `rofi`, `brightnessctl`, `hyprlock`, and other existing utilities, were already installed. Screenshot and wallpaper commands use the executables on `PATH`.

## Rig selection and monitors

Put just `home` or `work` in the **machine-local**, untracked `~/.config/rig-name` file. On this home machine the file contains `home`; on the work laptop, use `work`. No hostname needs to be recorded. Run `hyprctl reload` after changing the file.

The home profile sets DP-2 to 3440×1440 at 120 Hz above the centered DP-3 at 1920×1200 at 60 Hz, both at scale 1. Without the rig file, the profile is skipped and Hyprland uses its default monitor layout.

Workspace 10 was automatically created by Hyprland as the second monitor's active workspace: the config explicitly makes only workspaces 1–9 persistent. Waybar hides 10, but Hyprland still needs an active workspace for that monitor.

## ✅ Already covered

| Category       | Tool                                                 |
| -------------- | ---------------------------------------------------- |
| Status bar     | waybar                                               |
| Notifications  | dunst                                                |
| Screenshots    | grim + slurp + satty                                 |
| Clipboard      | wl-clipboard                                         |
| Launcher       | rofi (drun)                                          |
| Wallpaper      | hyprpaper                                            |
| Lock           | hyprlock                                             |
| Screen sharing | pipewire + wireplumber + xdg-desktop-portal-hyprland |

## 🔧 Worth adding

### Must-have (per the wiki)

- **hypridle** — idle daemon, the natural pair for hyprlock (you have the lock but not the trigger)
- **hyprpolkitagent** — auth agent; without it apps can't prompt for privilege elevation
- **qt5-wayland / qt6-wayland** — Qt apps run natively instead of through Xwayland
- **noto-fonts + a Nerd Font** — required for text/icons to render correctly

### Clipboard

- **cliphist** — clipboard history (text, images, binary), picked via rofi:
  `wl-paste --watch cliphist store` + `cliphist list | rofi -dmenu | cliphist decode | wl-copy`
- **wl-clip-persist** — clipboard survives the source app closing (a Wayland quirk)

### Screenshots / recording

- **hyprpicker** — first-party color picker, dead simple (click → hex on stdout)
- **wl-screenrec** — high-performance recording with hardware encoding
- **gpu-screen-recorder** — ShadowPlay-style, GPU-only, near-zero impact

### Quality of life

- **hyprsunset** — first-party blue-light filter (or gammastep for location-based scheduling)
- **yazi** — blazing-fast TUI file manager written in Rust 🦀
- **udiskie** — auto-mount USB drives/removable media
- **LocalSend** — local-network file sharing, no SSH/SMB/cloud needed
- **scrcpy** — mirror/control Android over USB
- **HyprLS** — LSP for hyprland config in Neovim (auto-complete + validation)
- **hyprland-rs** — Rust IPC wrapper for scripting Hyprland 🦀

## Skip (already solved or not my style)

- App launchers (fuzzel/tofi/wofi) — rofi works
- Wallpaper managers (swww/waypaper) — hyprpaper is enough
- Desktop shells (Noctalia, DankMaterialShell) — waybar + dunst cover this
- Vesktop/WebCord — only if Discord screen sharing becomes a problem
