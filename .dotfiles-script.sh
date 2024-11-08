#!/bin/env sh
dotfiles init
export PATH=$PATH:$HOME/elixir/bin
alias q="exit"
md(){
	test $# -eq 1 && mkdir -p -- "$1" && chdir -- "$1"
}
nd(){
	test $# -eq 1 && mkdir -p -- "$1" && chdir -- "$1" && nvim ./
}
up(){
	chdir ..
}
if ! test -z "${ZSH_VERSION}"
then
	autoload -U compinit
	compinit
	compdef _directories md
	compdef _directories nd
fi
eb(){
	clear
	exec bash --noprofile
}
vnv(){
	if test -z ${1}
	then
		venv_name=venv
	else
		venv_name="${1}"
	fi
	python3 -mvenv "${venv_name}"
}
pyt(){
	python3 -mpytest -v tests
}

if test -z "${GOPATH}"
then
	GOPATH="${HOME}/go"
fi
if test -z "${GOBIN}"
then
	GOBIN="${GOPATH}/bin"
fi
export PATH="${PATH}:${GOBIN}"

export HISTSIZE=5000
export DISPLAY=":0"
if test -f "/data/data/com.termux/files/usr/lib/libtermux-exec.so"
then
	export LD_PRELOAD=/data/data/com.termux/files/usr/lib/libtermux-exec.so
fi

export XDG_CONFIG_HOME="${HOME}/.config/"

if test -z "${PREFIX}"
then
	export PREFIX="/usr/"
fi

JAVA_HOME="${PREFIX}/share/jdk8"

export VISUAL="nvim"
export EDITOR='nvim'

if command -v 'most' > /dev/null 2>&1
then
	export PAGER='most'
elif command -v 'less' > /dev/null 2>&1
then
	export PAGER='less'
else
	export PAGER='more'
fi
