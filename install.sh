. common.sh

detect_pkgman() {
	if [[ "$OSTYPE" == "darwin"* ]]; then
		echo "brew install"
	elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
		echo "sudo apt install"
	else
		echo 1>&2 "Unknown OS $OSTYPE"
		exit 1
	fi
}

dot() {
	local EXT_SH=$1
	local EXT_DEFAULT=$2
	local PKGMAN_INSTALL=$(detect_pkgman)

	. $EXT_SH

	# Get directory that this script is in
	pushd . >/dev/null
	cd $(dirname "$0")
	local DOT_DIR=$(pwd)
	local DOT_DIR_R=$(dirs -p | sed -e 's/^~\///;q')
	popd >/dev/null

	# setup dir
	local BIN_DIR=$HOME/.bin
	local INSTALL_DIR=$HOME/.bin/install
	mkdir $BIN_DIR 2>/dev/null
	mkdir $INSTALL_DIR 2>/dev/null

	# list all dot_(*) functions in ext.sh
	local exts=($(grep "^dot_" $EXT_SH | sed 's/^dot_\([a-zA-Z0-9_-]*\)\(\).*/\1/'))
	local extn=${#exts[@]}

	# declare ext iterator
	foreach_ext() {
		local lambda=$1
		local result=0
		for ((i=0; i<extn; i++)); do
			$lambda "${exts[i]}" $i
			if [ $? -ne 0 ]; then
				result=1
			fi
		done
		return $result # 0: all success, 1: some failed
	}

	local SELECT_INSTALLED=0
	local SELECT_TO_INSTALL=1
	local SELECT_NOT_TO_INSTALL=2

	local ext_select=()
	local ext_cmd=()

	available() {
		local ext=$1
		local i=$2

		unset -f check
		unset default
		dot_$ext
		if [[ $(type -t "check") == "function" ]]; then
			w=$(check)
		else
			w=$(command -v "$ext")
		fi

		local check_result=$?

		if [[ -z "$default" ]]; then
			default=$EXT_DEFAULT
		fi

		if [ $check_result -eq 0 ]; then
			ext_select[$i]=$SELECT_INSTALLED
		elif $default; then
			ext_select[$i]=$SELECT_TO_INSTALL
		else
			ext_select[$i]=$SELECT_NOT_TO_INSTALL
		fi
		ext_cmd[$i]="$w"
		return $check_result
	}

	print_select() {
		local ext=$1
		local i=$2
		local n=$((i+1))

		local select=${ext_select[i]}
		if [ $select -eq $SELECT_INSTALLED ]; then
			$ECHO 1>&2 "$n.[${GREEN}+${NC}] $ext: ${ext_cmd[$i]}"
		elif [ $select -eq $SELECT_TO_INSTALL ]; then
			$ECHO 1>&2 "$n.[${YELLOW}v${NC}] $ext: ${ext_cmd[$i]}"
		else
			$ECHO 1>&2 "$n.[${RED}-${NC}] $ext: ${ext_cmd[$i]}"
		fi
	}

	install_ext() {
		local ext=$1
		local i=$2

		if [ ${ext_select[i]} -eq $SELECT_TO_INSTALL ]; then
			unset -f install
			dot_$ext

			if [[ $(type -t "install") == "function" ]]; then
				eval "$(declare -f install)" >/dev/null
				declare -f install | sed '1d'
				install
			else
				$ECHO "[>] $PKGMAN_INSTALL $ext"
				$PKGMAN_INSTALL $ext
			fi
		fi
	}

	$ECHO "--- $EXT_SH ---"
	foreach_ext available
	local all_available=$?

	# toggle select
	while :; do
		foreach_ext print_select
		if [ $all_available -eq 0 ]; then
			return
		fi

		$ECHO "$BLUE? [y/n] or numbers to toggle: $NC\c"
		read -e yn
		case $yn in
			[Nn]) break;;
			[Yy])
				foreach_ext install_ext
				foreach_ext available
				all_available=$?
				;;
			*)
				IFS=", "
				for n in $yn; do
					local index=$((n-1))
					local select=${ext_select[$index]}
					if [ $select -eq $SELECT_TO_INSTALL ]; then
						ext_select[$index]=$SELECT_NOT_TO_INSTALL
					elif [ $select -eq $SELECT_NOT_TO_INSTALL ]; then
						ext_select[$index]=$SELECT_TO_INSTALL
					fi
				done;;
		esac
	done
}

# macro
exist() {
	if [ -e "$1" ]; then
		echo "$1"
		return 0
	else
		return 1
	fi
}

link() {
	local src=$1
	local dst=$2
	eval "check() {
		if [ -h '$dst' ]; then
			echo '$dst'
			return 0
		else
			return 1
		fi
	}"
	eval "install() {
		ln -s '$src' '$dst'
	}"
}

# Declare dot_* functions
# - Configuration
#   - check()
#   - install()
#   - default
#
# - Macro
#   - exist(path)    -> check
#   - link(src, dst) -> check, install
#
# - Env
#   - $DOT_DIR     : dotfiles directory
#   - $DOT_DIR_R   : dotfiles directory relative to home
#   - $BIN_DIR     : directory for executable
#   - $INSTALL_DIR : directory for installation
#   - $PKGMAN_INSTALL : package manager installation command

dot ext/essential.sh true
dot ext/base.sh true
dot ext/dev.sh false
