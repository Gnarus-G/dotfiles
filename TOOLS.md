# Workstation tools

This is the desired tool inventory for new machines, not an installation script. Install the equivalents available on the machine's distribution, then run `./dev` to link the configurations. Package names and setup commands may vary.

## Required

| Purpose                   | Tools                                                                                                | Notes                                                                                                                                                                      |
| ------------------------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Core CLI                  | `git`, `curl`, `wget`, `unzip`, `fd`, `fzf`, `jq`, `uv`, build tools                                 | Used by the shell setup and local scripts.                                                                                                                                 |
| Desktop                   | `hyprland`, `waybar`, `rofi`, `dunst`, `hyprlock`                                                    | Use a Waybar version that supports Hyprland Lua workspace clicks; Arch's `waybar-git` does, whereas 0.15.0 did not. Locking is manual.                                     |
| Wallpaper                 | `swaybg`                                                                                             | `.config/hypr/random-wallpaper.sh` picks a wallpaper on login.                                                                                                             |
| Screenshots and clipboard | `grim`, `slurp`, `wl-clipboard`                                                                      | Hyprland binds screenshot shortcuts and copies the result with `wl-copy`.                                                                                                  |
| Brightness                | `brightnessctl`                                                                                      | Used by the brightness keys.                                                                                                                                               |
| Audio and screen sharing  | `pipewire`, `pipewire-pulse`, `wireplumber`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` | Waybar's audio module uses PulseAudio-compatible commands.                                                                                                                 |
| Native Qt apps            | `qt5-wayland`, `qt6-wayland`                                                                         | Package names vary by distribution.                                                                                                                                        |
| Fonts                     | a Nerd Font, Noto fonts (including emoji and CJK), Atkinson Hyperlegible Mono                        | Arch examples: `ttf-firacode-nerd`, `noto-fonts-emoji`, `noto-fonts-cjk`, `noto-fonts-extra`; `.local/bin/getfonts.sh` installs the additional fonts used by the dotfiles. |
| Shell                     | `zsh`, Oh My Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting`                                   | The two plugins go in the Oh My Zsh custom plugins directory.                                                                                                              |
| Terminal workflow         | `tmux`, gpakosz's `.tmux` config                                                                     | Link its `.tmux.conf` as `~/.tmux.conf` before `./dev` links `.tmux.conf.local`.                                                                                           |
| CLI extras                | `x-cmd`                                                                                              | Loaded lazily by `.zshrc` when installed.                                                                                                                                 |

## Optional — wanted

These are chosen additions, not prerequisites for `./dev`; install and set up the ones wanted on each machine.

| Purpose               | Tools             | Setup/use                                                                                            |
| --------------------- | ----------------- | ---------------------------------------------------------------------------------------------------- | ----------- | --------------- | --------- |
| Clipboard history     | `cliphist`        | Watch clipboard changes with `wl-paste --watch cliphist store`; select an entry using `cliphist list | rofi -dmenu | cliphist decode | wl-copy`. |
| Persistent clipboard  | `wl-clip-persist` | Start it in the Wayland session to retain clipboard contents after the source app closes.            |
| Screen recording      | `wl-screenrec`    | Record video of a region or monitor when needed; screenshots already use `grim` and `slurp`.         |
| Warmer evening colors | `hyprsunset`      | Start it in the Wayland session with the desired temperature/schedule.                               |
| Terminal file manager | `yazi`            | Launch on demand.                                                                                    |
| Removable drives      | `udiskie`         | Start it in the Wayland session for automatic mounting.                                              |
| Android mirroring     | `scrcpy`          | Launch on demand with an Android device connected over USB.                                          |

## Other optional setups

| Purpose                 | Tools                                          | Notes                                                                                                                                |
| ----------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Mouse acceleration      | `maccel`, matching kernel headers, build tools | Follow the installer at [maccel.org](https://www.maccel.org/).                                                                       |
| Virtual machines        | QEMU, libvirt, OVMF, virt-manager, dnsmasq     | Set up the libvirt services/network and user permissions for the host distribution.                                                  |
| Stable Diffusion        | AUTOMATIC1111 Stable Diffusion Web UI          | Clone under `~/d`, install its compatible Python version, then run `webui.sh`; Forge is an optional remote/branch for that checkout. |
| OpenCode browser plugin | Chrome extension and broker                    | See [browser plugin setup](.config/opencode/browser-plugin-setup.md).                                                                |
