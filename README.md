# .dotfiles
## Zsh
### [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)
```sh
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh install.sh
```
### [autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
```sh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### [syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## [Tmux](https://github.com/gpakosz/.tmux)
```sh
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
```

Get default configs with:
```sh
cp .tmux/.tmux.conf.local .
```

## Misc. Dependencies

```sh
sudo pacman -S fd fzf jq
```

## Window Manager

### LeftWM

```sh
pacman -S leftwm leftwm-theme feh rofi polybar
```

```sh
paru -S stalonetray picom pamixer
```

#### Eww
```sh
mkdir -p ~/d
git clone https://github.com/elkowar/eww ~/d/eww
cd ~/d/eww
cargo build --release --no-default-features --features x11
sudo install -s -Dm755 target/release/eww -t /usr/bin
```

## Theme & Fonts

```sh
sudo pacman -S lxappearance-gtk3 adapta-gtk-theme
```

```sh
sudo pacman -S ttf-firacode-nerd noto-fonts-emoji
fc-cache -f
```

or, after running `./dev` from this dotfiles directory.

```sh
getfonts.sh
```

## Mouse driver

```sh
sudo pacman -S base-devel linux-lts-headers linux-zen-headers
```

```sh
curl -fsSL https://www.maccel.org/install.sh | sudo sh
```

## VirtManager

```sh
sudo pacman -S qemu-desktop libvirt edk2-ovmf virt-manager dnsmasq
sudo usermod -aG libvirt,kvm,input $USER
```

```sh
sudo virsh net-autostart default
sudo virsh net-start default
sudo systemctl enable libvirtd.service --now
sudo systemctl enable virtlogd.socket --now
```

## References
[How to version control them dotfiles](https://stackoverflow.com/questions/46534290/symlink-dotfiles)  
[Nvim from scratch](https://github.com/LunarVim/Neovim-from-scratch)  
[Lsp Server Configurations](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
[leftwm](https://github.com/leftwm/leftwm)
[eww](https://elkowar.github.io/eww/#building)

## Mounting Drives
https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
