# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt notify
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/gnarus/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

autoload -Uz vcs_info # enable vcs_info
precmd () { vcs_info } # always load before displaying the prompt
zstyle ':vcs_info:*' formats ' %s(%F{green}%b%f)' # git(main)
setopt PROMPT_SUBST
PROMPT='%F{blue}%n%f in %F{yellow}%/%f$vcs_info_msg_0_ > '

path=($HOME/.local/bin $path)

export EDITOR=nvim

alias vim=nvim
