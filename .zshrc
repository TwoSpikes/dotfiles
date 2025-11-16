# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install

autoload -U compinit
compinit
compdef _directories md
compdef _directories nd

[[ -o login ]] || . ~/.dotfiles-script.sh
