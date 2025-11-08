#!/bin/env sh

cleanup() {
	stty sane
}
trap cleanup EXIT

# Copyied from StackOverflow: https://stackoverflow.com/questions/8725925/how-to-read-just-a-single-character-in-shell-script
# Archived: https://www.dropbox.com/scl/fi/rzro16efgcqx21e7p8vu4/linux-How-to-read-just-a-single-character-in-shell-script-Stack-Overflow.pdf?rlkey=y7ishp5zajtx7fqvpgitdc8b7&st=xtd970a8&dl=0
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
	if ${package_manager_not_found}
	then
		>2& echo "error: package manager not found"
		>2& "Abort"
		return 1
	fi
	if  test -z "${PACKAGE_COMMAND}" || test -z "${package_manager_is_winget}"
	then
		>2& echo "Please run determine_package_manager"
		>2& echo "Abort"
		return 1
	fi
	stdpkg=${1}
	wingetpkg=${2}
	if test -z ${stdpkg} && test -z ${wingetpkg}
	then
		>2& echo "Too few cmdline arguments"
		>2& echo "Abort"
		return 1
	fi
	if ! ${package_manager_is_winget}
	then
		if test -z ${stdpkg}
		then
			>2& echo "Package to install is not defined"
			>2& echo "Abort"
			return 1
		fi
		install_package_command="${PACKAGE_COMMAND} ${stdpkg}"
		run_as_superuser_if_needed "${install_package_command}"
	else
		if test -z ${wingetpkg}
		then
			>2& echo "Package to install with winget is not defined"
			>2& echo "Abort"
			return 1
		fi
		winget install ${wingetpkg}
	fi
}
run_as_superuser_if_needed() {
	needed_command="${@}"
	
	if ${run_as_yes}
	then
		needed_command="yes | ${needed_command}"
	fi

	if test ${need_to_run_as_superuser} = "no"
	then
		${needed_command}
		return ${?}
	elif test ${need_to_run_as_superuser} = "yes"
	then
		${run_as_superuser} ${needed_command}
		return ${?}
	elif test ${need_to_run_as_superuser} = "not found"
	then
		>2& echo "Error: superuser command not found"
		>2& echo "Abort"
		return 1
	else
		>2& echo "run_as_superuser_if_needed: internal error"
		>2& echo "Abort"
		return 1
	fi
}

for arg in "${@}"
do
	if test "${arg}" = "--help"
	then
		help
	fi
done

if test "${STOP_AT_FIRST_ERROR}" = "true"
then
	set -e
fi
if test "${NO_INTERNET}" = "true"; then
	presume_no_internet=true
else
	presume_no_internet=false
fi
if test "${NO_PACKAGE_MANAGER}" = "true"
then
	presume_no_package_manager=true
else
	presume_no_package_manager=false
fi

if test -z ${1}
then
	>2& echo "Please provide path to dotfiles"
	>2& echo ""
	short_help
	exit 1
fi

home=${HOME}
if ! test -z ${2}
then
	home=${2}
fi

dotfiles=$(realpath ${1})

if test -z ${PREFIX}
then
	root=/
else
	root=${PREFIX}/..
fi
if ! test -z ${3}
then
	root=${3}
fi

show_header() {
	clear
	echo "====" ${1} "===="
	echo ""
}

if ! test $(whoami) = "root" && test -z ${TERMUX_VERSION}
then
	if command -v "sudo" > /dev/null 2>&1
	then
		run_as_superuser="sudo"
		need_to_run_as_superuser="yes"
	elif command -v "doas" > /dev/null 2>&1
	then
		run_as_superuser="doas"
		need_to_run_as_superuser="yes"
	else
		>2& echo "Warning: sudo or doas command not found"
		run_as_superuser=""
		need_to_run_as_superuser="not found"
	fi
else
	need_to_run_as_superuser="no"
fi

show_basic_paths() {
	echo "Path to dotfiles is:"
	echo "<<< ${dotfiles}"

	echo "Path to home is:"
	echo "<<< ${home}"

	echo "Path to / is:"
	echo "<<< ${root}"

	echo "Need to run as superuser:"
	echo "<<< ${need_to_run_as_superuser}"

	echo "Superuser command is:"
	echo "<<< ${run_as_superuser}"
}

while true
do
	show_header "Starting"
	show_basic_paths
	echo ""
	echo -n "That is right? (y/N): "
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	read_char user_input
	case ${user_input} in
		"y")
			break
			;;
		*)
			show_header "Changing basic paths"
			echo "What path would you like to change?"
			echo "1. Path to dotfiles"
			echo "2. Path to home"
			echo "3. Path to root"
			echo "4. Need to run as superuser"
			echo "5. Superuser command"
			echo "6. Back"
			echo "7. Exit"
			echo -n ">>> "
			read_char user_input
			if test "${user_input}" = "7"
			then
				>2& echo "Abort"
				exit 1
			fi
			if ! test "${user_input}" = "6"
			then
				if test "${user_input}" = "4"
				then
					case "${need_to_run_as_superuser}" in
						"no")
							echo "1. Change \"no\" to \"yes\""
							echo "2. Change to \"not found\""
							;;
						"yes")
							echo "1. Change \"yes\" to \"no\""
							echo "2. Change to \"not found\""
							;;
						"not found")
							echo "1. Change to \"no\""
							echo "2. Change to \"yes\""
							;;
						*)
							>2& echo "Internal error"
							>2& echo "Abort"
							return 1
							;;
					esac
					echo "3. Back"
					echo "4. Exit"
					read_char option
					if test "${option}" = "4"
					then
						>2& echo "Abort"
						exit 1
					fi
					case "${need_to_run_as_superuser}" in
						"no")
							case "${option}" in
								"1")
									need_to_run_as_superuser="yes"
									;;
								"2")
									need_to_run_as_superuser="not found"
									;;
								"3")
									;;
								*)
									>2& echo "Wrong value"
									;;
							esac
							;;
						"yes")
							case "${option}" in
								"1")
									need_to_run_as_superuser="no"
									;;
								"2")
									need_to_run_as_superuser="not found"
									;;
								"3")
									;;
								*)
									>2& echo "Wrong value"
									;;
							esac
							;;
						"not found")
							case "${option}" in
								"1")
									need_to_run_as_superuser="no"
									;;
								"2")
									need_to_run_as_superuser="yes"
									;;
								"3")
									;;
								*)
									>2& echo "Wrong value"
									;;
							esac
							;;
						*)
							>2& echo "Internal error"
							;;
					esac
				else
					echo -n "New value: "
					read -r option
					case "${user_input}" in
						"1")
							dotfiles="${option}"
							;;
						"2")
							home="${option}"
							;;
						"3")
							root="${option}"
							;;
						"5")
							run_as_superuser="${option}"
							;;
						*)
							>2& echo "Wrong value"
							;;
					esac
				fi
			fi
			press_enter
			;;
	esac
done

show_header "Checking misc stuff"

if ! test -z ${TERMUX_VERSION}
then
	OS=Termux
	VER=${TERMUX_VERSION}
elif test -f ${root}/etc/os-release
then
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
	if ${presume_no_package_manager}
	then
		package_manager_not_found=true
	else
		if command -v "pkg" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="pkg install -y"
		elif command -v "apt" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="apt install -y"
		elif command -v "apt-get" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="apt-get install -y"
		elif command -v "winget" > /dev/null 2>&1
		then
			package_manager_is_winget=true
		elif command -v "pacman" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="pacman -Suy --noconfirm"
		elif command -v "zypper" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="zypper install -y"
		elif command -v "xbps-install" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="xbps-install -Sy"
		elif command -v "yum" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="yum install -y"
		elif command -v "aptitude" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="aptitude install -y"
		elif command -v "opkg" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="opkg install"
		elif command -v "dnf" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="dnf install -y"
		elif command -v "emerge" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="emerge --ask --verbose"
		elif command -v "up2date" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="up2date"
		elif command -v "urpmi" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="urpmi --force"
		elif command -v "slackpkg" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="slackpkg install"
		elif command -v "apk" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="apk add"
		elif command -v "brew" > /dev/null 2>&1
		then
			run_as_yes=true
			PACKAGE_COMMAND="brew install"
		elif command -v "flatpak" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="flatpak install"
		elif command -v "snap" > /dev/null 2>&1
		then
			PACKAGE_COMMAND="snap install"
		else
			package_manager_not_found=true
		fi
	fi
	if ! ${package_manager_not_found}
	then
		if ${package_manager_is_winget}
		then
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

echo "Checking for internet..."
if ! "${presume_no_internet}"
then
	ping -c 1 8.8.8.8 > /dev/null
	ping_errorcode=${?}
	if test ${ping_errorcode} -eq 0
	then
		echo "You have internet"
		have_internet=true
	else
		echo "You do not have internet"
		have_internet=false
	fi
else
	have_internet=false
fi

if ! command -v "git" > /dev/null 2>&1
then
	echo "Git not found"
	git_found=false
else
	echo "Git found"
	git_found=true
fi

if test -d ${dotfiles}
then
	echo "Dotfiles directory exists"
else
	echo "Dotfiles directory does not exist"
	echo -n "Do you want to create it? (y/N): "
	read_char user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case ${user_input} in
		"y")
			mkdir ${dotfiles} -vp
			;;
		*)
			>2& echo "Abort"
			return 1
			;;
	esac
fi

if test -z "$(ls -A ${dotfiles})"
then
	echo "Directory is empty"
else
	echo "Directory is not empty"
fi

if test "${have_internet}" = "true"
then
	if test "${package_manager_not_found}" = "false"
	then
		if ! command -v curl >/dev/null 2>&1
		then
			if ! command -v wget >/dev/null 2>&1
			then
				echo "Neither curl nor wget is installed"
				echo "Do you want to install it?"
				echo "1) wget"
				echo "2) curl"
				echo "*) none of them"
				read_char user_input
				user_input=$(echo ${user_input}|awk '{print tolower($0)}')
				case ${user_input} in
					"1")
						install_package wget
						errorcode=${?}
						if test ${errorcode} -ne 0
						then
							return ${errorcode}
						fi
						;;
					"2")
						install_package curl
						errorcode=${?}
						if test ${errorcode} -ne 0
						then
							return ${errorcode}
						fi
						;;
					*)
						;;
				esac
			fi
			press_enter
		fi
	fi
fi

if "${have_internet}"
then
	TMPFILE=$(mktemp -u)
	if command -v curl >/dev/null 2>&1
	then
		curl -fsSLo "${TMPFILE}" https://raw.githubusercontent.com/TwoSpikes/dotfiles/master/.dotfiles-version
	elif command -v wget >/dev/null 2>&1
	then
		wget -O "${TMPFILE}" https://raw.githubusercontent.com/TwoSpikes/dotfiles/master/.dotfiles-version
	else
		>2& echo "There is neither \`wget\` nor \`curl\` nor the opportunity to install any of them"
		>2& echo "Abort"
		return 1
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

if test -f ${dotfiles}/.dotfiles-version
then
	local_dotfiles_version=$(cat ${dotfiles}/.dotfiles-version)
	have_local_dotfiles=true
else
	have_local_dotfiles=false
fi
if "${have_local_dotfiles}"
then
	if "${latest_dotfiles_version_known}"
	then
		if test "${local_dotfiles_version}" = "${latest_dotfiles_version}"
		then
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

if "${have_latest_dotfiles}"
then
	echo "Dotfiles found"
	echo -n "Local dotfiles version: "
	cat ${dotfiles}/.dotfiles-version
else
	if ! test -f ${dotfiles}/.dotfiles-version
	then
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
				if ! test ${git_found}
				then
					>2& echo "No Git found"
					>2& echo "Abort"
					return 1
				else
	set -x
					git clone --depth=1 https://github.com/TwoSpikes/dotfiles.git ${dotfiles}
	set +x
				fi
				;;
			*)
				if ! "${have_local_dotfiles}"
				then
					>2& echo "No dotfiles and you rejected to download them"
					>2& echo "Abort"
					return 1
				fi
				;;
		esac
	else
		if ! "${have_local_dotfiles}"
		then
			>2& echo "You need internet to download them"
			>2& echo "Maybe you handed the wrong path to dotfiles?"
			>2& echo "Abort"
			return 1
		fi
	fi
fi

echo "Now we are ready to start"
press_enter

download_rustup(){
	set -x
	curl --proto '=https' --tlsv1.4 https://sh.rustup.rs -sSf | sh
	set +x
}

if ! test -d ${home}/bin
then
	mkdir -pv ${home}/bin
fi

show_header "Setting up dotfiles"

if ! command -v "cargo" > /dev/null 2>&1
then
	case "${OS}" in
		"Termux" | "Void" | "FreeBSD")
			install_package rust
			;;
		"Arch Linux" | "Arch Linux 32")
			install_package rustc
			;;
		"openSUSE Leap" | "openSUSE Tumbleweed")
			install_package rustup
			;;
		"Alpine Linux")
			if ! command -v curl >/dev/null 2>&1
			then
				install_package curl
			fi
			if true\
			&& ! command -v ld.lld >/dev/null 2>&1\
			&& ! command -v ld64.lld >/dev/null 2>&1\
			&& ! command -v lld-link >/dev/null 2>&1\
			&& ! command -v wasm-ld >/dev/null 2>&1
			then
				install_package gcc
			fi
			download_rustup
			;;
		*)
			if ! command -v curl >/dev/null 2>&1
			then
				install_package curl
			fi
			download_rustup
			;;
	esac
fi
cd ${dotfiles}/util/dotfiles
echo "Building..."
cargo build --release
echo "Installing..."
run_as_superuser_if_needed install ${dotfiles}/util/dotfiles/target/release/dotfiles ${root}/usr/bin
cd -
press_enter

clear
echo "Loading..."

selected_shell="None"
select_shell() {
show_header "Selecting shell"

echo "Please select the shell"
echo "1. bash"
echo "2. zsh"
echo ""
echo -n ">>> "

read_char user_input

case "${user_input}" in
	"1")
		selected_shell="bash"
		;;
	"2")
		selected_shell="zsh"
		;;
	*)
		>2& echo "Wrong input value"
		selected_shell="None"
		;;
esac
press_enter
}

setup_shell() {
	ask_what_to_start
	if ! test -d "${home}"/.config/dotfiles
	then
		mkdir -pv "${home}"/.config/dotfiles
	fi
	echo "autorun_program = \"${autorun_program}\"" > ~/.config/dotfiles/config.cfg
	echo "shell = \"${selected_shell}\""

	case "${selected_shell}" in
		"bash")
			setup_bash
			;;
		"zsh")
			setup_zsh
			;;
		*)
			>2& echo "Internal error"
			return 1
	esac
	if test "${selected_shell}" = "zsh"
	then
		setup_bd
		setup_z4h
	fi
	shell_is_set_up="true"
}

ask_what_to_start() {
echo "What program would you like to run when the shell starts?"
echo "1. Neovim"
echo "2. None"
echo ""
echo -n ">>> "

read_char user_input

case "${user_input}" in
	"1")
		autorun_program="Neovim"
		;;
	"2")
		autorun_program="None"
		;;
	*)
		>2& echo "Incorrect input."
		autorun_program="None"
		;;
esac
}

setup_zsh() {
show_header "Installing Zsh"

if ! command -v zsh > /dev/null 2>&1
then
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

show_header "Setting up zsh"

echo -n "Do you want to copy zsh scripts and its dependencies? (y/N/exit): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		cp ${dotfiles}/.dotfiles-script.zsh ${home}
		cp -r ${dotfiles}/shscripts/ ${home}
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
}


setup_bash() {
show_header "Setting up bash"

echo -n "Do you want to copy bash scripts and its dependencies? (y/N/exit): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		cp ${dotfiles}/.dotfiles-script.bash ${home}
		cp -r ${dotfiles}/shscripts/ ${home}
		cp ${dotfiles}/.bash_profile ${home}
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
}

setup_common_lisp() {
show_header "Setting up Common Lisp"
cp ${dotfiles}/.eclrc ${home}
cp ${dotfiles}/sbclrc ${home}
common_lisp_is_set_up="true"
}

setup_emacs() {
show_header "Setting up emacs"

echo -n "Checking if emacs is installed: "
if command -v "emacs" > /dev/null 2>&1
then
	echo "YES"
else
	echo "NO"
	
	echo -n "Do you want to install emacs? (Y/n): "
	read_char user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
		"n")
			;;
		*)
			install_package emacs
			;;
	esac
fi
press_enter

if command -v "emacs" > /dev/null 2>&1
then
	errorcode=0
	if ! test -d "${home}"/.emacs.d
	then
		echo "Making emacs config directory..."
		mkdir -pv "${home}"/.emacs.d
		errorcode="${?}"
	fi
	if test "${errorcode}" -eq 0
	then
		echo -n "Installing emacs config: "
		cp -r "${dotfiles}"/.emacs.d "${home}"/
		echo "OK"
	else
		>2& echo "error: could not make directory, skipping"
	fi
fi
press_enter
emacs_is_set_up="true"
}

setup_bd() {
show_header "Setting up bd"

echo -n "Checking if bd is installed: "
if test -f "${HOME}/.zsh/plugins/bd/bd.zsh"
then
	echo "YES"
else
	echo "NO"

	echo -n "Do you want to install bd? (Y/n): "
	read_char user_input
	user_input=$(echo ${user_input}|awk '{print tolower($0)}')
	case "${user_input}" in
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
}

select_default_shell() {
show_header "Selecting your default shell"

case "${selected_shell}" in
	"bash")
		echo "Please, select bash"
		;;
	"zsh")
		echo "Please, select bash for technical reasons"
		;;
	*)
		>2& echo "Internal error"
		;;
esac
chsh
press_enter
}

setup_z4h() {
show_header "Installing zsh4humans"

echo -n "Do you want to install zsh4humans? (Y/n): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"n")
		;;
	*)
		echo -n "Fetching zsh4humans... "
		TMPFILE_DOWNLOADED=mktemp
		if command -v curl >/dev/null 2>&1
		then
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
}

setup_helix() {
show_header "Setting up helix"

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
helix_is_set_up="true"
}

setup_vim_or_neovim() {
show_header "Checking if editors exist"

if ! command -v "nvim" 2>&1
then
	echo "Neovim not found"
	neovim_found=false
else
	echo "Neovim found"
	neovim_found=true
fi

if ! command -v "vim" 2>&1
then
	echo "Vim not found"
	vim_found=false
else
	echo "Vim found"
	vim_found=true
fi

if ${vim_found}
then
	if ${neovim_found}
	then
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
	if ${neovim_found}
	then
		setting_editor_for=nvim
	else
		>&2 echo "Vim/NeoVim not found"
		>&2 echo "Abort"
		return 1
	fi
fi

show_header "Setting up ${setting_editor_for}"

echo -n "Do you want to install config for ${setting_editor_for}? (y/N): "
read_char user_input
user_input=$(echo ${user_input}|awk '{print tolower($0)}')
case ${user_input} in
	"y")
		show_header "Installing ${setting_editor_for} config"

		if ! test -d ${home}/.config
		then
			mkdir -pv ${home}/.config
		fi
		git clone --depth=1 https://github.com/TwoSpikes/extra.nvim ~/extra.nvim
		cd ~/extra.nvim/util/exnvim
		cargo run -- install
		cd -
		press_enter
		;;
	*)
		;;
esac
vim_or_neovim_is_set_up="true"
}

setup_git() {
show_header "Setting up git"

echo -n "Checking if Git is installed: "
if $git_found
then
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
git_is_set_up="true"
}

setup_termux() {
show_header "Setting up termux"

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
termux_is_set_up="true"
}

setup_tmux() {
show_header "Setting up Tmux"

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
		if command -v "tmux" > /dev/null 2>&1
		then
			echo -n "Copying config for Tmux... "
			cp ${dotfiles}/.tmux.conf ${home}/
			echo "OK"
		fi
		;;
esac
press_enter
tmux_is_set_up="true"
}

setup_nano() {
show_header "Setting up Nano"

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
nano_is_set_up="true"
}

setup_alacritty() {
show_header "Setting up Alacritty"

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
alacritty_is_set_up="true"
}

setup_ctags() {
show_header "Setting up ctags"

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
			errorcode=${?}
			if test ${errorcode} -ne 0
			then
				>2& echo "An error ocurred while installing ctags"
			fi
			;;
		*)
			;;
	esac
fi
press_enter
ctags_are_set_up="true"
}

setup_nodejs() {
show_header "Setting up nodejs"

echo -n "Checking if nodejs installed: "
if command -v "node" > /dev/null 2>&1
then
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
nodejs_is_set_up="true"
}

setup_pnpm() {
show_header "Setting up pnpm"

echo -n "Checking if pnpm is installed: "
if command -v "pnpm" > /dev/null 2>&1
then
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
pnpm_is_set_up="true"
}

setup_mc_or_far() {
show_header "Setting up mc/far"

echo "Do you want to install mc/far?"
echo -n "1) mc (Midnight commander): "
if command -v "mc" > /dev/null 2>&1
then
	echo "installed"
else
	echo "not installed"
fi
echo -n "2) far: "
if command -v "far" > /dev/null 2>&1
then
	echo "installed"
else
	echo "not installed"
fi
echo -n "3) far2l (Far to Linux): "
if command -v "far2l" > /dev/null 2>&1
then
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
mc_or_far_is_set_up="true"
}

setup_python() {
show_header "Setting up Python"

echo -n "Checking if python is installed: "
if command -v "python" > /dev/null 2>&1
then
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
python_is_set_up="true"
}

setup_pip() {
show_header "Setting up pip"

echo -n "Checking if pip is installed: "
if command -v "pip" > /dev/null 2>&1
then
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
}

setup_pipx() {
show_header "Setting up pipx"

echo -n "Checking if pipx already installed: "
if command -v "pipx" > /dev/null 2>&1
then
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
}

setup_golang() {
show_header "Setting up golang"

echo -n "Checking if golang is installed: "
if command -v "go" > /dev/null 2>&1
then
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
golang_is_set_up="true"
}

setup_delve() {
show_header "Setting up delve"

echo -n "Checking if delve is installed: "
if test -e ${GOBIN}/dlv
then
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
press_enter
}

setup_java() {
show_header "Setting up Java"

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
java_is_set_up="true"
}

setup_coursier() {
show_header "Setting up Coursier"

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
}

setup_xkb_switch() {
show_header "Setting up xkb-switch"

echo -n "Checking if xkb-switch is installed: "
if command -v "xkb-switch" > /dev/null 2>&1
then
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
xkb_switch_is_set_up="true"
}

echo "Loaded"

privius_menu_item=0
next_menu_item=1

shell_is_set_up="false"
common_lisp_is_set_up="false"
emacs_is_set_up="false"
helix_is_set_up="false"
vim_or_neovim_is_set_up="false"
git_is_set_up="false"
termux_is_set_up="false"
tmux_is_set_up="false"
nano_is_set_up="false"
alacritty_is_set_up="false"
ctags_are_set_up="false"
nodejs_is_set_up="false"
pnpm_is_set_up="false"
mc_or_far_is_set_up="false"
python_is_set_up="false"
golang_is_set_up="false"
java_is_set_up="false"
xkb_switch_is_set_up="false"

enter_is_selected=0

while true
do
	clear

	if test ${enter_is_selected} -eq 1
	then
		current_menu_item="$(expr ${privius_menu_item} + 1)"
		enter_is_selected=0
	else
		echo "What would you like to do?"
		echo ""
		echo "enter) Next menu item: $(expr ${privius_menu_item} + 1)"
		echo "1) Select shell (selected: ${selected_shell})"
		echo "2) Setup shell (done: ${shell_is_set_up})"
		echo "3) Setup Common Lisp (done: ${common_lisp_is_set_up})"
		echo "4) Setup Emacs (done: ${emacs_is_set_up})"
		echo "5) Setup Helix (done: ${helix_is_set_up})"
		echo "6) Setup Vim or Neovim (done: ${vim_or_neovim_is_set_up})"
		echo "7) Setup Git (done: ${git_is_set_up})"
		if ! test -z "${TERMUX_VERSION}"
		then
			echo "8) Setup Termux (done: ${termux_is_set_up})"
		fi
		echo "9) Setup Tmux (done: ${tmux_is_set_up})"
		echo "10) Setup Nano (done: ${nano_is_set_up})"
		echo "11) Setup Alacritty (done: ${alacritty_is_set_up})"
		echo "12) Setup Ctags (done: ${ctags_are_set_up})"
		echo "13) Setup Nodejs (done: ${nodejs_is_set_up})"
		echo "14) Setup PNPM (done: ${pnpm_is_set_up})"
		echo "15) Setup MC or FAR (done: ${mc_or_far_is_set_up})"
		echo "16) Setup Python (done: ${python_is_set_up})"
		echo "17) Setup Go (done: ${golang_is_set_up})"
		echo "18) Setup Java (done: ${java_is_set_up})"
		echo "19) Setup xkb_switch (done: ${xkb_switch_is_set_up})"
		echo "20) Exit"
		echo ""
		echo -n ">>> "

		read -r current_menu_item
	fi
	
	case "${current_menu_item}" in
		"1")
			select_shell
			;;
		"2")
			while test "${selected_shell}" = "None"
			do
				select_shell
			done

			setup_shell
			;;
		"3")
			setup_common_lisp
			;;
		"4")
			setup_emacs
			;;
		"5")
			setup_helix
			;;
		"6")
			setup_vim_or_neovim
			;;
		"7")
			setup_git
			;;
		"8")
			if test -z "${TERMUX_VERSION}"
			then
				while true
				do
					echo "You're not in Termux."
					echo "Do you want to do this anyway?"
					echo "1) Yes"
					echo "2) No"
					echo -n ">>> "
					read_char user_input
					case "${user_input}" in
						"1")
							setup_termux
							break
							;;
						"2")
							break
							;;
						*)
							;;
					esac
				done
			else
				setup_termux
			fi
			;;
		"9")
			setup_tmux
			;;
		"10")
			setup_nano
			;;
		"11")
			setup_alacritty
			;;
		"12")
			setup_ctags
			;;
		"13")
			setup_nodejs
			;;
		"14")
			setup_pnpm
			;;
		"15")
			setup_mc_or_far
			;;
		"16")
			setup_python
			setup_pip
			setup_pipx
			;;
		"17")
			setup_golang
			setup_delve
			;;
		"18")
			setup_java
			setup_coursier
			;;
		"19")
			setup_xkb_switch
			;;
		"20")
			echo ""
			break
			;;
		"")
			enter_is_selected=1
			continue
			;;
		*)
			continue
			;;
	esac
	privius_menu_item="${current_menu_item}"
	press_enter
done

echo "Dotfiles setup ended successfully"
echo "Restart your shell"
exit 0
