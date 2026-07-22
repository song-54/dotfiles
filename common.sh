RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

detect_env() {
	# check backslash escape is enabled
	if [ "$(echo '\040')" = " " ]; then
		ECHO="echo"
	else
		ECHO="echo -e"
	fi
}
detect_env

detect_read() {
	if [ -n "$ZSH_VERSION" ]; then
		READ=(read -r -A)
	else
		READ="read -r -a"
	fi
}

# print and run command
exe() {
	if [ -z $1 ]; then
		while read cmdline;do
			$ECHO 1>&2 "[${YELLOW}>${NC}] $cmdline"
			eval $cmdline
		done
	else
		$ECHO 1>&2 "[${YELLOW}>${NC}] $@"
		eval $@
	fi
}

# info(msg)
info() {
	$ECHO 1>&2 "${BLUE}[info] $1${NC}"
}

check_cmd() {
	local name=$1
	local cmd=${2:-command -v "$name"}

	cmd=$(eval $cmd)
	check_result=$?
	if [ $check_result -eq 0 ]; then
		$ECHO 1>&2 [${GREEN}+${NC}] $name: $cmd
	else
		$ECHO 1>&2 [${RED}-${NC}] $name
	fi
	return $check_result
}

# argument match
# - usage:
#   function my_cmd() {
#     cmd() { test $? -eq 0 && exe command param ${@:3} || exe command $@; }
#     argm 2 cmd $@ < lst
#     argm 3 cmd $@ <<-EOM
#     EOM
#   }
function argm() {
	n=$1
	func=$2
	detect_read
	$READ args <<-ARGS
		${@:3}
	ARGS

	test "$ZSH_VERSION" && z=1 || z=0
	if [ -n "$args" ]; then
		local argm_match=0
		while $READ line; do
			if [ "${line[z]::1}" = "#" ]; then
				continue
			fi

			argm_match=1
			for i in $(seq $n); do
				if [ "${line[z+i-1]}" != "${args[z+i-1]}" ]; then
					argm_match=0
					break
				fi
			done
			if [ $argm_match -eq 1 ]; then
				true
				$func ${line[@]}
				break
			fi
		done
		if [ $argm_match -eq 0 ]; then
			false
			$func ${args[@]}
		fi
	else
		while $READ line; do
			if [ "${line[z]::1}" = "#" ]; then
				$ECHO $BLUE$line$NC
			else
				key=${line[@]::$n}
				desc=${line[@]:$n}
				$ECHO "$GREEN$key\t$YELLOW$desc$NC"
			fi
		done
	fi
}

