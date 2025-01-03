#!/bin/env sh
if ! test -z "${TERMUX_VERSION}"
then
	if test -z "${ZSH_VERSION}"
	then
		if command -v "zsh" > /dev/null 2>&1
		then
			if ! shopt -q login_shell
			then
				exec zsh
			fi
		fi
	fi
fi
if command -v 'dotfiles' > /dev/null 2>&1
then
	dotfiles init
fi
export PATH=$PATH:$HOME/elixir/bin
alias q="exit"
alias :q="exit"
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
	exec bash --noprofile --norc
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

if test -d "${HOME}/z88dk/bin"
then
	export PATH="${PATH}:${HOME}/z88dk/bin"
fi

if command -v 'cargo' > /dev/null 2>&1
then
	export PATH="${PATH}:${HOME}/.cargo/bin"
fi

if ! test -z "${TERMUX_VERSION}"
then
	if ! test -z "${BASH_VERSION}"
	then
		if shopt -q login_shell
		then
			exec nvim
		fi
	fi
fi

echo "[INFO] dotfiles scripted loaded"
