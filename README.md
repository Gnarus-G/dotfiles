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

Utils
```sh
sudo pacman -S fd fzf jq
```

Screenshots
```sh
sudo pacman -S shotgun satty
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
sudo pacman -S ttf-firacode-nerd noto-fonts-emoji noto-fonts-cjk noto-fonts-extra

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

## Stable Diffusion Web UI
```sh
set -e
cd ~/d
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
cd stable-diffusion-webui
rm -r venv
sed 's/#\s*python_cmd=".*"/python_cmd="python3.11"/' -i webui-user.sh
paru -S python311
./webui.sh
```
[Usage Guide](https://stable-diffusion-art.com/models/)

### Forge
```sh
cd ~/d/stable-diffusion-webui
git remote add forge https://github.com/lllyasviel/stable-diffusion-webui-forge
git branch lllyasviel/main
git checkout lllyasviel/main
git fetch forge
git branch -u forge/main
git pull
```

## References
[How to version control them dotfiles](https://stackoverflow.com/questions/46534290/symlink-dotfiles)  
[Nvim from scratch](https://github.com/LunarVim/Neovim-from-scratch)  
[Lsp Server Configurations](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
[leftwm](https://github.com/leftwm/leftwm)
[eww](https://elkowar.github.io/eww/#building)
[Using a NTFS disk with Linux and Windows](https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows)
