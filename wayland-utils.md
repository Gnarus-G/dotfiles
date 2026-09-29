# Useful Wayland Utilities — for my Hyprland setup

Based on the [Hyprland wiki](https://wiki.hypr.land/useful-utilities/), checked against what's already installed.

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
