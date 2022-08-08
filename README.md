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

## References
[How to version control them dotfiles](https://stackoverflow.com/questions/46534290/symlink-dotfiles)  
[Nvim from scratch](https://github.com/LunarVim/Neovim-from-scratch)  
[Lsp Server Configurations](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
