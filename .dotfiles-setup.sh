#!/bin/env sh

# Copyied from StackOverflow: https://stackoverflow.com/questions/8725925/how-to-read-just-a-single-character-in-shell-script
read_char() {
  stty -icanon -echo
  eval "$1=\$(dd bs=1 count=1 2>/dev/null)"
  stty icanon echo
  echo
}

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
	echo "	STOP_AT_FIRST_ERROR"
	echo "			set +e"
	echo "	NO_INTERNET"
	echo "			Presume you do not have internet"
	echo "	NO_PACKAGE_MANAGER"
	echo "			Presume you do not have package manager"
	echo "Example: ENVVAR=true ${0}"
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
short_help() {
	subcommands
	echo ""
	echo "To see full help, run:"
	echo "	${0} --help"
}
press_enter() {
	echo ""
	echo -n "Press ENTER to continue: "
	read user_input
}
install_package() {
	if ${package_manager_not_found}; then
		echo "erorr: package manager not found"
		return 1
	fi
	if  test -z "${PACKAGE_COMMAND}" || test -z "${package_manager_is_winget}"; then
		echo "Please run determine_package_manager"
		return 1
	fi
	stdpkg=${1}
	wingetpkg=${2}
	if test -z ${stdpkg} && test -z ${wingetpkg}; then
		echo "Too few cmdline arguments"
		return 1
	fi
	if ! ${package_manager_is_winget}; then
		if test -z ${stdpkg}; then
			echo "Package to install is not defined"
			return 1
		fi
		install_package_command="${PACKAGE_COMMAND} ${stdpkg}"
		run_as_superuser_if_needed "${install_package_command}"
	else
		if test -z ${wingetpkg}; then
			echo "Package to install with winget is not defined"
			return 1
		fi
		winget install ${wingetpkg}
	fi
}
run_as_superuser_if_needed() {
	needed_command="${@}"
	
	if ${run_as_yes}; then
		needed_command="yes | ${needed_command}"
	fi

	if test ${need_to_run_as_superuser} = "no"; then
		${needed_command}
	elif test ${need_to_run_as_superuser} = "yes"; then
		${run_as_superuser} ${needed_command}
	elif test ${need_to_run_as_superuser} = "not found"; then
		echo "Error: superuser command not found"
		return 1
	else
		echo "run_as_superuser_if_needed: internal error"
		return 1
	fi
}

if test "${1}" = "--help" \
|| test "${2}" = "--help"  \
|| test "${3}" = "--help"  \
|| test "${4}" = "--help" ; then
	help
fi

if test "${STOP_AT_FIRST_ERROR}" = "true"; then
	set -e
fi
if test "${NO_INTERNET}" = "true"; then
	presume_no_internet=true
else
	presume_no_internet=false
fi
if test "${NO_PACKAGE_MANAGER}" = "true"; then
	presume_no_package_manager=true
else
	presume_no_package_manager=false
fi

if test -z ${1}; then
	echo "Please provide path to dotfiles"
	echo ""
	short_help
	exit 1
fi

home=${HOME}
if ! test -z ${2}; then
	home=${2}
fi

dotfiles=$(realpath ${1})

if test -z ${PREFIX}; then
	root=/
else
	root=${PREFIX}/..
fi
if ! test -z ${3}; then
	root=${3}
fi

clear
echo "==== Starting ===="
echo ""
if ! test $(whoami) = "root" && test -z ${TERMUX_VERSION}; then
	if command -v "sudo" > /dev/null 2>&1; then
		run_as_superuser="sudo"
		need_to_run_as_superuser="yes"
	elif command -v "doas" > /dev/null 2>&1; then
		run_as_superuser="doas"
		need_to_run_as_superuser="yes"
	else
		echo "Warning: sudo or doas command not found"
		echo ""
		run_as_superuser=""
		need_to_run_as_superuser="not found"
	fi
else
	need_to_run_as_superuser="no"
fi

echo "Path to dotfiles is:"
echo "<<< ${dotfiles}"

echo "Path to home is:"
echo "<<< ${home}"

echo "Path to / is:"
echo "<<< ${root}"

echo ""
echo -n "That is right? (y/N): "
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
read_char user_input
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

if ! test -z ${TERMUX_VERSION}; then
	OS=Termux
	VER=${TERMUX_VERSION}
elif test -f ${root}/etc/os-release; then
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
	run_as_yes=false
	package_manager_is_winget=false
	package_manager_not_found=false
	if ${presume_no_package_manager}; then
		package_manager_not_found=true
	else
		if command -v "pkg" > /dev/null 2>&1; then
			PACKAGE_COMMAND="pkg install -y"
		elif command -v "apt" > /dev/null 2>&1; then
			PACKAGE_COMMAND="apt install -y"
		elif command -v "apt-get" > /dev/null 2>&1; then
			PACKAGE_COMMAND="apt-get install -y"
		elif command -v "winget" > /dev/null 2>&1; then
			package_manager_is_winget=true
		elif command -v "pacman" > /dev/null 2>&1; then
			PACKAGE_COMMAND="pacman -Suy --noconfirm"
		elif command -v "zypper" > /dev/null 2>&1; then
			PACKAGE_COMMAND="zypper install -y"
		elif command -v "xbps-install" > /dev/null 2>&1; then
			PACKAGE_COMMAND="xbps-install -Sy"
		elif command -v "yum" > /dev/null 2>&1; then
			PACKAGE_COMMAND="yum install -y"
		elif command -v "aptitude" > /dev/null 2>&1; then
			PACKAGE_COMMAND="aptitude install -y"
		elif command -v "dnf" > /dev/null 2>&1; then
			PACKAGE_COMMAND="dnf install -y"
		elif command -v "emerge" > /dev/null 2>&1; then
			PACKAGE_COMMAND="emerge --ask --verbose"
		elif command -v "up2date" > /dev/null 2>&1; then
			PACKAGE_COMMAND="up2date"
		elif command -v "urpmi" > /dev/null 2>&1; then
			PACKAGE_COMMAND="urpmi --force"
		elif command -v "slackpkg" > /dev/null 2>&1; then
			PACKAGE_COMMAND="slackpkg install"
		elif command -v "apk" > /dev/null 2>&1; then
			PACKAGE_COMMAND="apk add"
		elif command -v "brew" > /dev/null 2>&1; then
			run_as_yes=true
			PACKAGE_COMMAND="brew install"
		elif command -v "flatpak" > /dev/null 2>&1; then
			PACKAGE_COMMAND="flatpak install"
		elif command -v "snap" > /dev/null 2>&1; then
			PACKAGE_COMMAND="snap install"
		else
			package_manager_not_found=true
		fi
	fi
	if ! ${package_manager_not_found}; then
		if ${package_manager_is_winget}; then
			echo "Package manager is winget"
		else
			echo "Package command is: ${PACKAGE_COMMAND}"
		fi
	else
		echo "Package manager not found"
	fi
	export PACKAGE_COMMAND
	export package_manager_is_winget
	export package_manager_not_found
}
determine_package_manager

echo ""

if ! "${presume_no_internet}"; then
	ping -c 1 8.8.8.8 > /dev/null
	ping_errorcode=${?}
	if test ${ping_errorcode} -eq 0; then
		echo "You have an internet"
		have_internet=true
	else
		echo "You do not have an internet"
		have_internet=false
	fi
else
	have_internet=false
fi

if ! command -v "git" > /dev/null 2>&1; then
	echo "Git not found"
	git_found=false
else
	echo "Git found"
	git_found=true
fi

if test -d ${dotfiles}; then
	echo "Dotfiles directory exists"
else
	echo "Dotfiles directory does not exist"
	echo -n "Do you want to create it? (y/N): "
	read_char user_input
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

if test -z "$(ls -A ${dotfiles})"; then
	echo "Directory is empty"
else
	echo "Directory is not empty"
fi

if "${have_internet}"; then
	TMPFILE=$(mktemp -u)
	if command -v curl >/dev/null 2>&1; then
		curl -fsSLo "${TMPFILE}" https://raw.githubusercontent.com/TwoSpikes/dotfiles/master/.dotfiles-version
	else
		wget -O "${TMPFILE}" https://raw.githubusercontent.com/TwoSpikes/dotfiles/master/.dotfiles-version
	fi
	latest_dotfiles_version=$(cat "${TMPFILE}")
	echo "Latest dotfiles version: ${latest_dotfiles_version}"
	rm "${TMPFILE}"
	unset TMPFILE
	latest_dotfiles_version_known=true
else
	echo "warning: you need internet to check latest dotfiles version"
	latest_dotfiles_version_known=false
fi

if test -f ${dotfiles}/.dotfiles-version; then
	local_dotfiles_version=$(cat ${dotfiles}/.dotfiles-version)
	have_local_dotfiles=true
else
	have_local_dotfiles=false
fi
if "${have_local_dotfiles}"; then
	if "${latest_dotfiles_version_known}"; then
		if test "${local_dotfiles_version}" = "${latest_dotfiles_version}"; then
			have_latest_dotfiles=true
		else
			have_latest_dotfiles=false
		fi
	else
		have_latest_dotfiles=true
	fi
else
	have_latest_dotfiles=false
fi

if "${have_latest_dotfiles}"; then
	echo "Dotfiles found"
	echo -n "Local dotfiles version: "
	cat ${dotfiles}/.dotfiles-version
else
	if ! test -f ${dotfiles}/.dotfiles-version; then
		echo "Dotfiles not found"
	else
		echo "Dotfiles is old, new version if aviable"
	fi
	if "${have_internet}"; then
		echo -n "Do you want to download it? (y/N): "
		read_char user_input
		user_input=$(echo ${user_input}|awk '{print tolower($0)}')
		case ${user_input} in
			"y")
				if ! test ${git_found}; then
					echo "Abort: No Git found"
					return 1
				else
	set -x
					git clone --depth=1 https://github.com/TwoSpikes/dotfiles.git ${dotfiles}
	set +x
				fi
				;;
			*)
				if ! "${have_local_dotfiles}"; then
					echo "fatal: no dotfiles and you rejected to download them"
					return 1
				fi
				;;
		esac
	else
		if ! "${have_local_dotfiles}"; then
			echo "fatal: you need internet to download them"
			echo "maybe you handed the wrong path to dotfiles?"
			return 1
		fi
	fi
fi

echo "Now we are ready to start"
press_enter

clear
echo "==== Setting up dotfiles ===="
echo ""
if ! command -v "cargo" > /dev/null 2>&1; then
	install_package rust
fi
cd ${dotfiles}/util/dotfiles
echo "Building..."
cargo build --release
echo "Installing..."
run_as_superuser_if_needed install ${dotfiles}/util/dotfiles/target/release/dotfiles ${root}/usr/bin
cd -
press_enter

clear
echo "==== Setting up shell ===="
echo ""

echo -n "Do you want to copy shell scripts and its dependencies? (y/N/exit): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		cp ${dotfiles}/.zshrc ${home}
		cp ${dotfiles}/.dotfiles-script.sh ${home}
		cp -r ${dotfiles}/shscripts/ ${home}
		cp ${dotfiles}/.bash_profile ${home}
		cp ${dotfiles}/.eclrc ${home}
		cp ${dotfiles}/sbclrc ${home}
		cp -v ${dotfiles}/bin/* ${home}/bin/
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
echo "==== Setting up bd ===="
echo ""

echo -n "Checking if bd is installed: "
if test -f "${HOME}/.zsh/plugins/bd/bd.zsh"
then
	echo "YES"
else
	echo "NO"

	echo -n "Do you want to install bd? (Y/n): "
	read_char user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case ${user_input} in
		"n")
			;;
		*)
			test -d ${home}/.zsh/plugins/bd || mkdir -pv ${home}/.zsh/plugins/bd
			curl https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh > ${home}/.zsh/plugins/bd/bd.zsh
			echo "\n# zsh-bd\n. \$HOME/.zsh/plugins/bd/bd.zsh" >> $HOME/.zshrc
			;;
	esac
fi
press_enter

clear
echo "==== Installing Zsh ===="
echo ""

if ! command -v zsh > /dev/null 2>&1; then
	echo -n "Do you want to install Zsh? (Y/n): "
	read_char user_input
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
read_char user_input
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
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		echo -n "Fetching zsh4humans... "
		TMPFILE_DOWNLOADED=mktemp
		if command -v curl >/dev/null 2>&1; then
			curl -fsSLo "${TMPFILE_DOWNLOADED}" https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install
		else
			wget -O "${TMPFILE_DOWNLOADED}" https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install
		fi
		chmod +x "${TMPFILE_DOWNLOADED}"
		echo "OK"

		echo -n "Changing zsh4humans... "
		TMPFILE_EDITED=$(mktemp)
		head -n -1 "${TMPFILE_DOWNLOADED}" > "${TMPFILE_EDITED}"
		echo "OK"

		echo "Running zsh4humans..."
		sh "${TMPFILE_EDITED}"
		z4h_errcode=${?}
		echo "zsh4humans: exit code: ${z4h_errcode}"

		echo -n "Deleting tmp files... "
		rm "${TMPFILE_EDITED}"
		rm "${TMPFILE_DOWNLOADED}"
		unset TMPFILE_EDITED
		unset TMPFILE_DOWNLOADED
		echo "OK"
		;;
esac
press_enter

clear
echo "==== Setting up helix ===="
echo ""

echo -n "Checking if Helix is installed: "
if command -v "hx" > /dev/null 2>&1
then
	echo "YES"
else
	echo "NO"

	echo -n "Do you want to install Helix (Y/n): "
	read_char user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case ${user_input} in
		"n")
			;;
		*)
			install_package helix
			;;
	esac
fi

echo -n "Installing config for Helix: "
if ! test -d ${home}/.config/helix
then
	mkdir -pv ${home}/.config/helix
fi
cp -r ${dotfiles}/.config/helix ${home}/.config/
echo "OK"
press_enter

clear
echo "==== Checking if editors exist ===="
echo ""

if ! command -v "nvim" 2>&1; then
	echo "Neovim not found"
	neovim_found=false
else
	echo "Neovim found"
	neovim_found=true
fi

if ! command -v "vim" 2>&1; then
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
		read_char user_input
		case "${user_input}" in
			"1")
				setting_editor_for=vim
				;;
			"2")
				setting_editor_for=nvim
				;;
			*)
				>&2 echo "Abort"
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
		>&2 echo "Vim/NeoVim not found"
		>&2 echo "Abort"
		return 1
	fi
fi

clear
echo "==== Setting up ${setting_editor_for} ===="
echo ""

echo -n "Do you want to install config for ${setting_editor_for}? (y/N): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		clear
		echo "==== Installing ${setting_editor_for} config ===="
		echo ""

		if ! test -d ${home}/.config; then
			mkdir -pv ${home}/.config
		fi
		git clone --depth=1 https://github.com/TwoSpikes/extra.nvim ~/extra.nvim
		cd ~/extra.nvim/util/installer
		cargo run --
		cd -
		press_enter
		;;
	*)
		;;
esac
clear

if ! test -d ${home}/bin; then
	mkdir -pv ${home}/bin
fi

echo "==== Installing packer.nvim ===="
echo ""

case "${OS}" in
	MINGW*)
		>&2 echo "Cannot install packer.nvim to NeoVim: not implemented for Mingw"
		;;
	*)
		# FIXME: make work for Vim with Lua or change Plugin Manager
		echo -n "Checking if packer.nvim is installed: "
		if test -e ${home}/.local/share/nvim/site/pack/packer/start/packer.nvim; then
			echo "YES"
		else
			echo "NO"
			if ${neovim_found}; then
				echo -n "Do you want to install packer.nvim to NeoVim (y/N): "
				read_char user_input
				user_input=$(echo ${user_input}|awk '{print tolower($0)}')
				case ${user_input} in
					"y")
						run_as_superuser_if_needed git clone --depth 1 https://github.com/wbthomason/packer.nvim ${home}/.local/share/nvim/site/pack/packer/start/packer.nvim
						;;
					*)
						;;
				esac
			else
				>&2 echo "Cannot install packer.nvim: NeoVim not found"
			fi
		fi
esac
press_enter

clear
echo "==== Setting up git ===="
echo ""

echo -n "Checking if Git is installed: "
if $git_found; then
	echo "YES"
	echo ""

	echo -n "Do you want to setup Git? (Y/n): "
	read_char user_input
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
	>&2 echo "Error: Git not found"
fi
press_enter

if test ${OS} = "Termux"
then
clear
echo "==== Setting up termux ===="
echo ""

echo -n "Do you want to setup Termux? (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		termux-setup-storage
		cp -r ${dotfiles}/.termux/ ${home}/
		if test -e ${home}/.termux/colors.properties
		then
			rm ${home}/.termux/colors.properties
		fi
		if test -e ${home}/.termux/termux.properties
		then
			rm ${home}/.termux/termux.properties
		fi

		echo -n "Do you want to install my Termux colorscheme? (Y/n): "
		read_char user_input
		user_input=$(echo ${user_input}|awk '{print tolower($0)}')
		case ${user_input} in
			"n")
				;;
			*)
				if ! test -d ${home}/.termux
				then
					mkdir ${home}/.termux
				fi
				cp ${dotfiles}/.termux/colors.properties ${home}/.termux/
				;;
		esac

		echo -n "Do you want to install my Termux settings? (Y/n): "
		read_char user_input
		user_input=$(echo ${user_input}|awk '{print tolower($0)}')
		case ${user_input} in
			"n")
				;;
			*)
				if ! test -d ${home}/.termux
				then
					mkdir ${home}/.termux
				fi
				cp ${dotfiles}/.termux/termux.properties ${home}/.termux/
				;;
		esac

		echo -n "Reloading Termux settings... "
		termux-reload-settings
		echo "OK"
		;;
esac
fi

clear
echo "==== Setting up Tmux ===="
echo ""

echo -n "Do you want to setup Tmux? (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		if ! command -v "tmux" > /dev/null 2>&1
		then
			>&2 echo "Tmux is not installed"
			echo -n "Do you want to install it? (Y/n): "
			read_char user_input
			user_input=$(echo ${user_input}|awk '{print tolower($0)}')
			case "${user_input}" in
				n)
					;;
				*)
					install_package tmux
					;;
			esac
		fi
		if command -v "tmux" > /dev/null 2>&1; then
			echo -n "Copying config for Tmux... "
			cp ${dotfiles}/.tmux.conf ${home}/
			echo "OK"
		fi
		;;
esac
press_enter

clear
echo "==== Setting up Nano ===="
echo ""

echo -n "Do you want to setup Nano? (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		if ! command -v "nano" > /dev/null 2>&1
		then
			echo "Nano is not installed"
			echo -n "Do you want to install it? (Y/n): "
			read_char user_input
			user_input=$(echo ${user_input}|awk '{print tolower($0)}')
			case "${user_input}" in
				n)
					;;
				*)
					install_package nano
					;;
			esac
		fi
		if command -v "nano" > /dev/null 2>&1
		then
			echo -n "Copying config for Nano... "
			cp ${dotfiles}/.nanorc ${home}/
			echo "OK"
		fi
		;;
esac
press_enter

clear
echo "==== Setting up Alacritty ===="
echo ""

echo -n "Do you want to setup Alacritty? (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		if ! command -v "alacritty" > /dev/null 2>&1
		then
			>&2 echo "Alacritty is not installed"
			echo -n "Do you want to install it? (Y/n): "
			read user_input
			user_input=$(echo ${user_input}|awk '{print tolower($0)}')
			case "${user_input}" in
				n)
					;;
				*)
					install_package alacritty
					;;
			esac
		fi
		if command -v "alacritty" > /dev/null 2>&1
		then
			echo -n "Copying config for Alacritty... "
			cp -r ${dotfiles}/.config/alacritty/ ${home}/.config/
			echo "OK"
		fi
		;;
esac
press_enter

clear
echo "==== Setting up ctags ===="
echo ""

echo -n "Checking if ctags are installed: "
if command -v "ctags" > /dev/null 2>&1
then
	echo "YES"
else
	echo "NO"
	echo "Do you want to install ctags?"
	echo "1) Exuberant ctags"
	echo "2) Universal ctags"
	echo "*) No"
	echo -n "Your choice: "
	read_char user_input
	case "${user_input}" in
		"1")
			install_package exuberant-ctags
			;;
		"2")
			git clone --depth=1 https://github.com/universal-ctags/ctags.git
			cd ctags/
			./autogen.sh
			./configure
			make
			${run_as_superuser_if_needed} make install
			;;
		*)
			;;
	esac
fi
press_enter

clear
echo "==== Setting up npm ===="
echo ""

echo -n "Checking if npm installed: "
if command -v "npm" > /dev/null 2>&1; then
	echo "YES"
else
	echo "NO"
	echo -n "Do you want to install nodejs? (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"n")
			;;
		*)
			install_package nodejs
			;;
	esac
fi
press_enter

clear
echo "==== Setting up pnpm ==="
echo ""

echo -n "Checking if pnpm is installed: "
if command -v "pnpm" > /dev/null 2>&1; then
	echo "YES"
else
	echo "NO"
	echo -n "Do you want to install pnpm? (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"n")
			;;
		*)
			if ! command -v "getconf" > /dev/null 2>&1; then
				echo "Installing getconf..."
				install_package getconf
			fi
			echo "Downloading install script..."
			wget -qO- https://get.pnpm.io/install.sh | sh -
			;;
	esac
fi
press_enter

clear
echo "==== Setting up mc/far ===="
echo ""

echo "Do you want to install mc/far?"
echo -n "1) mc (Midnight commander): "
if command -v "mc" > /dev/null 2>&1; then
	echo "installed"
else
	echo "not installed"
fi
echo -n "2) far: "
if command -v "far" > /dev/null 2>&1; then
	echo "installed"
else
	echo "not installed"
fi
echo -n "3) far2l (Far to Linux): "
if command -v "far2l" > /dev/null 2>&1; then
	echo "installed"
else
	echo "not installed"
fi
echo "*) No"
read_char user_input
case "${user_input}" in
	"1")
		install_package mc
		;;
	"2")
		install_package far
		;;
	"3")
		install_package far2l
		;;
	*)
		;;
esac
press_enter
clear

clear
echo "==== Setting up Python ===="
echo ""

echo -n "Checking if python is installed: "
if command -v "python" > /dev/null 2>&1; then
	echo "YES"
else
	echo "NO"

	echo -n "Do you want to install Python (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"n")
			;;
		*)
			install_package python
			;;
	esac
fi

if command -v "python" > /dev/null 2>&1; then
	echo ""
	echo -n "Do you want to install things related to Python (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"n")
			to_install_python=false
			;;
		*)
			to_install_python=true
			;;
	esac
fi

press_enter

if ${to_install_python}; then
	clear
	echo "==== Setting up pip ===="
	echo ""

	echo -n "Checking if pip is installed: "
	if command -v "pip" > /dev/null 2>&1; then
		echo "YES"
		echo ""
		to_install_pipx=true
	else
		echo "NO"
		echo ""
		echo -n "Do you want to install pip (Y/n): "
		read user_input
		user_input=$(echo ${user_input}|awk '{print tolower($0)}')
		case "${user_input}" in
			"n")
				to_install_pipx=false
				;;
			*)
				to_install_pipx=true
				install_package python-pip
				press_enter
				;;
		esac
	fi
	press_enter

	if ${to_install_pipx}; then
		clear
		echo "==== Setting up pipx ===="
		echo ""

		echo -n "Checking if pipx already installed: "
		if command -v "pipx" > /dev/null 2>&1; then
			echo "YES"
		else
			echo "NO"
			echo ""
			echo -n "Do you want to install pipx (Y/n): "
			read user_input
			user_input=$(echo ${user_input}|awk '{print tolower($0)}')
			case "${user_input}" in
				"n")
					;;
				*)
					pip install pipx
					;;
			esac
		fi
		press_enter
	fi
fi

clear
echo "==== Setting up golang ===="
echo ""

echo -n "Checking if golang is installed: "
if command -v "go" > /dev/null 2>&1; then
	echo "YES"
else
	echo "NO"
	echo ""

	echo -n "Do you want to install golang (y/N): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"y")
			install_package golang
			;;
		*)
			;;
	esac
fi
press_enter

if command -v "go" > /dev/null 2>&1; then
	GOPATH=${GOPATH:="${HOME}/go"}
	GOBIN=${GOBIN:="${GOPATH}/bin"}

	echo ""
	echo -n "Do you want to install things related to golang (Y/n): "
	read user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"n")
			to_install_golang_related=false
			;;
		*)
			to_install_golang_related=true
			;;
	esac

	if ${to_install_golang_related}; then
		clear
		echo "==== Setting up delve ===="
		echo ""

		echo -n "Checking if delve is installed: "
		if test -e ${GOBIN}/dlv; then
			echo "YES"
		else
			echo "NO"
			echo ""
			echo -n "Do you want to install delve (Y/n): "
			read user_input
			case "${user_input}" in
				"n")
					;;
				*)
					go install github.com/go-delve/delve/cmd/dlv@latest
					;;
			esac
		fi
	fi
fi
press_enter

clear
echo "==== Setting up Java ===="
echo ""

echo -n "Do you want to install Java (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		if test -z "${TERMUX_VERSION}"
		then
			install_package default-jre
		else
			wget https://raw.githubusercontent.com/MasterDevX/java/master/installjava && bash installjava
		fi
		;;
esac
press_enter

clear
echo "==== Setting up Coursier ===="
echo ""

echo -n "Checking if Coursier is installed: "
echo "NO"

echo -n "Do you want to install Coursier (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		curl -fL "https://github.com/VirtusLab/coursier-m1/releases/latest/download/cs-aarch64-pc-linux.gz" | gzip -d > cs
		chmod -v +x ./cs
		./cs setup
		;;
esac
press_enter

clear
echo "==== Setting up xkb-switch ===="
echo ""

echo -n "Checking if xkb-switch is installed: "
if command -v "xkb-switch" > /dev/null 2>&1; then
	echo "YES"
else
	echo "NO"
fi
echo -n "Do you want to install xkb-switch (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		install_package xkb-switch
		;;
esac
press_enter

clear
echo "==== Setting up broken lua syntax workaround ===="
echo ""

echo -n "Do you want to install lua syntax workaround? (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case "${user_input}" in
	"n")
		;;
	*)
		curl -sS https://raw.githubusercontent.com/neovim/neovim/v0.7.2/runtime/syntax/lua.vim > ${VIMRUNTIME}/syntax/lua.vim
		;;
esac
press_enter

echo "Dotfiles setup ended successfully"
echo "It is recommended to restart your shell"
exit 0
