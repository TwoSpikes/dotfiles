#!/bin/env sh
shopt -q login_shell
if test "${?}" -eq 0
then
	is_login_shell="--login-shell"
else
	is_login_shell="++login-shell"
fi
export PATH=$PATH:$HOME/elixir/bin
alias q="exit"
alias :q="exit"
alias :x="exit"
md(){
	test $# -eq 1 && mkdir -p -- "$1" && chdir -- "$1"
}
nd(){
	test $# -eq 1 && mkdir -p -- "$1" && chdir -- "$1" && nvim ./
}
up(){
	chdir ..
}
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
	export PATH="${HOME}/.cargo/bin:${PATH}"
fi

echo "[INFO] dotfiles script loaded"

if command -v 'dotfiles' > /dev/null 2>&1
then
	dotfiles init "${is_login_shell}"
	errorcode="${?}"
	if test "${errorcode}" -eq 20
	then
		exec zsh
	fi
	if test "${errorcode}" -eq 21
	then
		exec nvim
	fi
fi
