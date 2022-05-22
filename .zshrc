   21 # Lines configured by zsh-newuser-install
   20 HISTFILE=~/.histfile
   19 HISTSIZE=1000
   18 SAVEHIST=1000
   17 setopt notify
   16 unsetopt beep
   15 bindkey -v
   14 # End of lines configured by zsh-newuser-install
   13 # The following lines were added by compinstall
   12 zstyle :compinstall filename '/home/gnarus/.zshrc'
   11 
   10 autoload -Uz compinit
    9 compinit
    8 # End of lines added by compinstall
    7 
    6 autoload -Uz vcs_info # enable vcs_info
    5 precmd () { vcs_info } # always load before displaying the prompt
    4 zstyle ':vcs_info:*' formats ' %s(%F{green}%b%f)' # git(main)
    3 setopt PROMPT_SUBST
    2 PROMPT='%F{blue}%n%f in %F{yellow}%/%f$vcs_info_msg_0_ > '
    1 
    0 path=($HOME/.local/bin $path)
    1 
    2 export EDITOR=nvim
    3 
    4 alias vim=nvim
    
