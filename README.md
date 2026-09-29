# .dotfiles

Wayland-first dotfiles for my workstations.

## Bootstrap

```sh
git clone <this repo> ~/d/dotfiles
cd ~/d/dotfiles
```

Install the tools in [TOOLS.md](TOOLS.md) using the machine's package manager, then run `./dev`; log out, select Hyprland if needed, and log back in.

## Optional tools

See [TOOLS.md](TOOLS.md) for wanted additions and other optional setups.

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
