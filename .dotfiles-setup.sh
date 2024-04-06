#!/bin/sh

subcommands() {
	echo "${0} [OPTION]... DOTFILES_PATH"
	echo "${0} [OPTION]... DOTFILES_PATH HOME_PATH ROOT_PATH"
}
help() {
	echo "${0} is a script to setup dotfiles"
	echo ""
	subcommands
	echo ""
	echo "Options"
	echo "	--help        display this message"
	exit 0
}

if [ "${1}" = "--help" ] \
|| [ "${2}" = "--help" ] \
|| [ "${3}" = "--help" ] \
|| [ "${4}" = "--help" ]; then
	help
fi

if [ -z ${1} ]; then
	echo "Please provide path to dotfiles"
	echo ""
	subcommands
	exit 1
fi

home=${HOME}
if [ ! -z ${2} ]; then
	home=${2}
fi

dotfiles=${1}

if [ -z ${PREFIX} ]; then
	root=/
else
	root=${PREFIX}/..
fi
if [ ! -z ${3} ]; then
	root=${3}
fi

clear
echo "==== Starting ===="
echo ""

echo "Path to dotfiles is:"
echo "<<< ${dotfiles}"
cd ${dotfiles}

echo "Path to home is:"
echo "<<< ${home}"

echo "Path to / is:"
echo "<<< ${root}"

echo ""
echo "That is right? (y/N)"
echo -n ">>> "
read user_input
case ${user_input} in
	"y")
		break
		;;
	*)
		echo "Abort"
		exit 1
		;;
esac

clear
echo "==== Checking misc stuff ===="
echo ""

ping -c 1 8.8.8.8 > /dev/null
ping_errorcode=${?}
if [ ${ping_errorcode} -eq 0 ]; then
	echo "You have an internet"
else
	echo "You do not have an internet"
fi

if ! command -v "git"; then
	echo "Git not found"
	git_found=false
else
	echo "Git found"
	git_found=true
fi

if [ -d ${dotfiles} ]; then
	echo "Dotfiles directory exists"
else
	echo "Dotfiles directory does not exist"
	echo -n "Do you want to create it then (y/N): "
	read user_input
	case ${user_input} in
		"y")
			mkdir ${dotfiles}
			;;
		*)
			echo "Abort"
			return 1
			;;
	esac
fi

if [ -z "$(ls -A ${dotfiles})" ]; then
	echo "Directory is empty"
else
	echo "Directory is not empty"
fi

if [ -f ${dotfiles}/.dotfiles-version ]; then
	echo "Dotfiles found"
else
	echo "Dotfiles not found"
	echo -n "Do you want to download them (y/N): "
	read user_input
	case ${user_input} in
		"y")
			if [ ! ${git_found} ]; then
				echo "No git found. Abort"
				return 1
			else
				git clone --depth=1 https://github.com/TwoSpikes/dotfiles.git ${dotfiles}
			fi
			;;
		*)
			echo "Abort"
			return 1
			;;
	esac
fi

echo "Now we are ready to start"

echo "Do you want to copy .bashrc and its dependencies? (y/N/exit): "
echo -n ">>> "
read user_input
case ${user_input} in
	"y")
		cp ${dotfiles}/.zshrc ${home}
		cp ${dotfiles}/.bashrc ${home}
		cp ${dotfiles}/checkhealth.sh ${home}
		cp ${dotfiles}/funcname.sh ${home}
		cp ${dotfiles}/timer.sh ${home}
		cp ${dotfiles}/tsch.sh ${home}
		;;
	"exit")
		echo "Abort"
		return 1
		;;
	*)
		;;
esac

clear
echo "==== Checking if editors exist ===="
echo ""

if ! command -v "nvim"; then
	echo "Neovim not found"
	neovim_found=false
else
	echo "Neovim found"
	neovim_found=true
fi

if ! command -v "vim"; then
	echo "Vim not found"
	vim_found=false
else
	echo "Vim found"
	vim_found=true
fi

if ${vim_found}; then
	if ${neovim_found}; then
		echo "Set editor for:"
		echo "1. Vim"
		echo "2. Neovim"
		echo "Other. Abort"
		echo -n ">>> "
		read user_input
		case "${user_input}" in
			"1")
				setting_editor_for=vim
				;;
			"2")
				setting_editor_for=nvim
				;;
			*)
				echo "Abort"
				return 1
				;;
		esac
	else
		setting_editor_for=vim
	fi
else
	if ${neovim_found}; then
		setting_editor_for=nvim
	else
		echo "Vim/NeoVim not found"
		echo "Abort"
		return 1
	fi
fi

clear
echo "==== Setting config for editor: ${setting_editor_for} ===="
echo ""

echo "That is right? (y/N)"
echo -n ">>> "
read user_input
case "${user_input}" in
	"y")
		echo "Ok"
		;;
	*)
		echo "Abort"
		return 1
		;;
esac

clear
echo "==== Checking if config for editor ${setting_editor_for} exists ===="
echo ""

if [ -d ${dotfiles}/.config/nvim ]; then
	echo "Directory exists"
else
	echo "Directory does not exist"
	echo "Abort"
	return 1
fi

if [ -z "$(ls ${dotfiles}/.config/nvim)" ]; then
	echo "Directory is empty"
	echo "Abort"
	return 1
else
	echo "Directory is not empty"
fi

if [ -f ${dotfiles}/.config/nvim/init.vim ]; then
	echo "Config for ${setting_editor_for} exists"
else
	echo "Config for ${setting_editor_for} does not exist"
	echo "Abort"
	return 1
fi

echo -n "Do you want to copy config for ${setting_editor_for}? (y/N): "
read user_input

case ${user_input} in
	"y")
		clear
		echo "==== Copying ${setting_editor_for} config ===="
		echo ""

set -x
		cp -r ${dotfiles}/.config/${setting_editor_for} ${home}/.config/${setting_editor_for}
		if [ "${setting_editor_for}" = "nvim" ]; then
			cp ${dotfiles}/blueorange.vim ${root}/usr/share/nvim/runtime/colors
		fi
		if [ "${setting_editor_for}" = "vim" ]; then
			cp ${dotfiles}/blueorange.vim ${root}/usr/share/vim/vim90/colors
		fi
set +x

		echo ""
		echo -n "Press ENTER to continue: "
		read user_input

		;;
	*)
		;;
esac
clear

echo "==== Installing packer.nvim ===="
echo ""
if ${neovim_found}; then
	echo -n "Do you want to install packer.nvim to NeoVim (y/N): "
	read user_input

	case ${user_input} in
		"y")
			git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ${root}/usr/share/nvim/site/pack/packer/start/packer.nvim
			;;
		*)
			;;
	esac
else
	echo "Cannot install packer.nvim: NeoVim not found"
fi

echo ""
echo -n "Press ENTER to continue: "
read user_input

echo "Not implemented yet"
return 0
