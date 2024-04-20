#!/bin/sh

set +xe

subcommands() {
	echo "SUBCOMMANDS:"
	echo "	[OPTION]... DOTFILES_PATH"
	echo "	[OPTION]... DOTFILES_PATH HOME_PATH ROOT_PATH"
}
options() {
	echo "OPTIONS:"
	echo "	--help		Display this message"
}
envvars() {
	echo "ENVIRONMENT VARIABLES:"
	echo "	DO_NOT_STOP_AT_FIRST_ERROR"
	echo "			If not empty, set +e"
}
help() {
	echo "${0} is a script to setup dotfiles"
	echo ""
	subcommands
	echo ""
	options
	echo ""
	envvars
	exit 0
}
press_enter() {
	echo ""
	echo -n "Press ENTER to continue: "
	read user_input
}
install_package() {
	if  test -z "${PACKAGE_COMMAND}"  && test -z "${package_manager_is_winget}"; then
		echo "Please run determine_package_manager"
		return 1
	fi
	stdpkg=${1}
	wingetpkg=${2}
	if test -z ${stdpkg} && test -z ${wingetpkg}; then
		echo "Too few cmdline arguments"
		return 1
	fi
	if ! $package_manager_is_winget; then
		${PACKAGE_COMMAND} ${stdpkg}
	else
		winget install ${wingetpkg}
	fi
}

if [ "${1}" = "--help" ] \
|| [ "${2}" = "--help" ] \
|| [ "${3}" = "--help" ] \
|| [ "${4}" = "--help" ]; then
	help
fi

if [ $DO_NOT_STOP_AT_FIRST_ERROR ]; then
	set +e
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

echo "Path to home is:"
echo "<<< ${home}"

echo "Path to / is:"
echo "<<< ${root}"

echo ""
echo -n "That is right? (y/N): "
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
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

if [ ! -z ${TERMUX_VERSION} ]; then
	OS=Termux
	VER=${TERMUX_VERSION}
elif [ -f ${root}/etc/os-release ]; then
	. ${root}/etc/os-release
	OS=${NAME}
	VER=${VERSION}
else
    OS=$(uname -s)
    VER=$(uname -r)
fi
echo "Current system: ${OS}"
echo "Current system version: ${VER}"

determine_package_manager() {
	package_manager_is_winget=false
	if command -v "pkg" > /dev/null; then
		PACKAGE_COMMAND="pkg install"
	elif command -v "apt" > /dev/null; then
		PACKAGE_COMMAND="apt install"
	elif command -v "apt-get" > /dev/null; then
		PACKAGE_COMMAND="apt-get install"
	elif command -v "winget" > /dev/null; then
		package_manager_is_winget=true
	elif command -v "pacman" > /dev/null; then
		PACKAGE_COMMAND="pacman -Suy"
	elif command -v "zypper" > /dev/null; then
		PACKAGE_COMMAND="zypper install"
	elif command -v "xbps-install" > /dev/null; then
		PACKAGE_COMMAND="xbps-install"
	elif command -v "yum" > /dev/null; then
		PACKAGE_COMMAND="yum install"
	elif command -v "aptitude" > /dev/null; then
		PACKAGE_COMMAND="aptitude install"
	elif command -v "dnf" > /dev/null; then
		PACKAGE_COMMAND="dnf install"
	elif command -v "emerge" > /dev/null; then
		PACKAGE_COMMAND="emerge --ask --verbose"
	elif command -v "up2date" > /dev/null; then
		PACKAGE_COMMAND="up2date"
	elif command -v "urpmi" > /dev/null; then
		PACKAGE_COMMAND="urpmi"
	elif command -v "flatpak" > /dev/null; then
		PACKAGE_COMMAND="flatpak install"
	elif command -v "snap" > /dev/null; then
		PACKAGE_COMMAND="snap install"
	fi
	if $package_manager_is_winget; then
		echo "Package manager is winget"
	else
		echo "Package command is: ${PACKAGE_COMMAND}"
	fi
	export PACKAGE_COMMAND
	export package_manager_is_winget
}
determine_package_manager

echo ""

ping -c 1 8.8.8.8 > /dev/null
ping_errorcode=${?}
if [ ${ping_errorcode} -eq 0 ]; then
	echo "You have an internet"
else
	echo "You do not have an internet"
fi

if ! command -v "git" > /dev/null; then
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
	echo -n "Do you want to create it? (y/N): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
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
	echo -n "Do you want to download them? (y/N): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case ${user_input} in
		"y")
			if [ ! ${git_found} ]; then
				echo "Abort: No Git found"
				return 1
			else
set -x
				git clone --depth=1 https://github.com/TwoSpikes/dotfiles.git ${dotfiles}
set +x
			fi
			;;
		*)
			echo "Abort"
			return 1
			;;
	esac
fi

echo "Now we are ready to start"

press_enter

clear
echo "==== Setupping shell ===="
echo ""
echo -n "Do you want to copy .bashrc and its dependencies? (y/N/exit): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		cp ${dotfiles}/.zshrc ${home}
		cp ${dotfiles}/.dotfiles-script.sh ${home}
		cp ${dotfiles}/tsch.sh ${dotfiles}/.fr.sh ${dotfiles}/inverting.sh ${home}
		cp -r ${dotfiles}/.shlibs/ ${home}
		cp ${dotfiles}/.profile ${dotfiles}/.zprofile ${home}
		;;
	"exit"|"x"|"e"|"q")
		echo "Abort"
		return 1
		;;
	*)
		;;
esac

press_enter

clear
echo "==== Installing Zsh ===="
echo ""

if ! command -v zsh > /dev/null; then
	echo -n "Do you want to install Zsh? (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case ${user_input} in
		"n")
			;;
		*)
			install_package zsh
			;;
	esac
fi

press_enter

clear
echo "==== Making Zsh your default shell ===="
echo ""

echo -n "Do you want to make Zsh your default shell? (Y/n): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		chsh
		;;
esac

press_enter

clear
echo "==== Installing zsh4humans ===="
echo ""

echo -n "Do you want to install zsh4humans? (Y/n): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		#if command -v curl >/dev/null 2>&1; then
		#	sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
		#else
		#	sh -c "$(wget -O- https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
		#fi

		echo -n "Fetching zsh4humans... "
		TMPFILE_DOWNLOADED=mktemp
		wget -O TMPFILE_DOWNLOADED https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install
		chmod +x TMPFILE_DOWNLOADED
		echo "OK"

		echo -n "Changing zsh4humans... "
		TMPFILE_EDITED=mktemp
		head -n -1 TMPFILE_DOWNLOADED > TMPFILE_EDITED
		echo "OK"

		echo "Running zsh4humans..."
		sh TMPFILE_EDITED
		z4h_errcode=${?}
		echo "zsh4humans: exit code: ${z4h_errcode}"

		echo -n "Deleting tmp files... "
		rm TMPFILE_EDITED
		rm TMPFILE_DOWNLOADED
		echo "OK"
		;;
esac

press_enter

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

if test "${setting_editor_for}" = "vim"; then
	VIMRUNTIME=${root}/share/vim/vim*
else
	VIMRUNTIME=${root}/share/nvim/runtime
fi

echo -n "That is right? (y/N): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
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
	echo "Abort: Directory does not exist"
	return 1
fi

if [ -z "$(ls ${dotfiles}/.config/nvim)" ]; then
	echo "Abort: Directory is empty"
	return 1
else
	echo "Directory is not empty"
fi

if [ -f ${dotfiles}/.config/nvim/init.vim ]; then
	echo "Config for ${setting_editor_for} exists"
else
	echo "Abort: Config for ${setting_editor_for} does not exist"
	return 1
fi

echo -n "Do you want to copy config for ${setting_editor_for}? (y/N): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		clear
		echo "==== Copying ${setting_editor_for} config ===="
		echo ""

set -x
		if [ ! -d ${home}/.config ]; then
			mkdir ${home}/.config
		fi
		cp -r ${dotfiles}/.config/nvim ${home}/.config/${setting_editor_for}
		cp ${dotfiles}/blueorange.vim ${VIMRUNTIME}/colors
		if [ "${setting_editor_for}" = "vim" ]; then
			echo 'exec printf("source %s/.config/vim/init.vim", $HOME)' > ${home}/.vimrc
		fi
		if [ ! -d ${home}/bin ]; then
			mkdir ${home}/bin
		fi
		cp ${dotfiles}/viman ${home}/bin/
set +x

	press_enter

		;;
	*)
		;;
esac
clear

echo "==== Installing packer.nvim ===="
echo ""

# FIXME: make work for Vim with Lua or change Plugin Manager
echo -n "Checking if packer.nvim is installed: "
if [ -e ${root}/usr/share/nvim/site/pack/packer/start/packer.nvim ]; then
	echo "YES"
else
	echo "NO"
	if ${neovim_found}; then
		echo -n "Do you want to install packer.nvim to NeoVim (y/N): "
		read user_input
		user_input=$(echo ${user_input}|awk '{print tolower($0)}')
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
fi

press_enter

clear
echo "==== Configuring ${setting_editor_for} configuration"
echo ""

echo -n "Checking if directory for configuration exists: "
if [ -d ${home}/.config/${setting_editor_for}/options ]; then
	echo "YES"
else
	echo "NO"
	echo -n "Making a directory for configuration: "
	mkdir ${home}/.config/${setting_editor_for}/options
	echo "OK"
fi
echo ""

echo -n "Do you want ${setting_editor_for} to install LSP (recommended)? (Y/n): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		touch ${home}/.config/nvim/options/do_not_setup_lsp.null
		;;
	*)
		if [ -e ${home}/.config/${setting_editor_for}/options/do_not_setup_lsp.null ]; then
			rm ${home}/.config/${setting_editor_for}/options/do_not_setup_lsp.null
		fi
		;;
esac

press_enter

clear
echo "==== Miscellaneous stuff ===="
echo ""

echo -n "Do you want to copy xterm-color-table.vim (recommended)? (Y/n): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		cp ${dotfiles}/xterm-color-table.vim ${home}
		;;
esac

clear
echo "==== Setting up git ===="
echo ""

echo -n "Checking if Git is installed: "
if $git_found; then
	echo "YES"
	echo ""

	echo -n "Do you want to setup Git? (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case ${user_input} in
		"n")
			;;
		*)
			cp ${dotfiles}/.gitconfig-default ${home}
			cp ${home}/.gitconfig-default ${home}/.gitconfig
			cp ${dotfiles}/.gitmessage ${home}
			
			echo -n "Your Name: "
			read user_input
			git config --global user.name "${user_input}"
			echo -n "Your email: "
			read user_input
			git config --global user.email "${user_input}"

			echo "Git setup done"
	esac
else
	echo "NO"
	echo "Error: Git not found"
fi

press_enter

if [ ${OS} = "Termux" ]; then
clear
echo "==== Setupping termux ===="
echo ""

echo -n "Do you want to setup Termux? (Y/n): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		cp -r ${dotfiles}/.termux/ ${home}/
		if [ -e ${home}/.termux/colors.properties ]; then
			rm ${home}/.termux/colors.properties
		fi
		;;
esac

echo -n "Do you want to install my Termux colorscheme? (y/N): "
read user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		if [ ! -d ${home}/.termux ]; then
			mkdir ${home}/.termux
		fi
		cp ${dotfiles}/.termux/colors.properties ${home}/.termux/
		;;
	*)
		;;
esac
fi

echo -n "Reloading Termux settings... "
termux-reload-settings
echo "OK"

echo "Dotfiles setup ended successfully"
echo "It is recommended to restart your shell"
return 0
