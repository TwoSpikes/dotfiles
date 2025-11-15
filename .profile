#!/bin/env sh
export IS_LOGIN_SHELL=1
if ! test $(basename $0) = "dash"
then
	. ./.dotfiles-script.sh
fi
