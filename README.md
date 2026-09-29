# .dotfiles

Wayland-first dotfiles for my Arch workstation.

## Bootstrap

```sh
git clone <this repo> ~/d/dotfiles
cd ~/d/dotfiles
.local/bin/required-tools
./dev
```

Log out, select Hyprland if needed, then log back in.

## Optional tools

```sh
optional-tools
```

Use Tab to choose extras such as the mouse driver, VirtManager, Stable Diffusion, or OpenCode browser-plugin notes.

## Daily sync

```sh
./dev
```

`./dev` reconciles the home-directory symlinks listed in `AGENTS.md`.

## References

- [OpenCode browser plugin setup](.config/opencode/browser-plugin-setup.md)
- [Hyprland](https://wiki.hypr.land/)
- [Waybar](https://github.com/Alexays/Waybar/wiki)
- [How to version control dotfiles](https://stackoverflow.com/questions/46534290/symlink-dotfiles)
