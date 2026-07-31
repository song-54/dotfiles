. $HOME/.config/dotfiles/common.sh

WORK_FOREST=$HOME/.worktree
WORK_CONFIG=.wtconfig

wt() {
	local command=$1
	if [ -n "$command" ]; then
		shift
	fi

	if ! wt_is_worktree; then
		echo "wt: not a git repository: ${pwd}" >&2
		return 1
	fi

	case "$command" in
		ls | list)
			git worktree list
			;;
		cd)
			wt_cd "$@"
			;;
		add)
			wt_add "$@"
			;;
		del)
			wt_del "$@"
			if [ $? -eq 2 ]; then
				echo "wt: usage: wt del [name] <branch>" >&2
			fi
			;;
		*)
			echo "wt: unknown command: $command" >&2
			return 3
			;;
	esac
}

wt_is_worktree() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

wt_primary_dir() {
	git worktree list --porcelain | sed -n '1s/^worktree //p'
}

wt_primary_name() {
	local primary=$(wt_primary_dir)
	echo "${primary##*/}"
}

# match worktree by name or branch
wt_match() {
	local target=$1
	local primary_name=$(wt_primary_name)

	local wtpath
	if [ "$target" = "-i" ]; then
		# interactive mode
		wtpath="$(git worktree list | awk '{print $1}' | fzf --prompt="Select worktree: " --height=1% --reverse)"
		[ -n "$wtpath" ] || return 2
	else
		# try match with "{name}-{target}"
		wtpath="$(git worktree list | awk '{print $1}' | grep -F -- "${primary_name}-$target" | head -n 1)"

		# if fail, try match with target
		if [ -z "$wtpath" ]; then
			wtpath="$(git worktree list | awk '{print $1}' | grep -F -- "$target" | head -n 1)"
		fi
		if [ -z "$wtpath" ]; then
			echo "wt_match: worktree not for \"$target\"" >&2
			return 1
		fi
	fi

	echo $wtpath
	return 0
}

wt_cd() {
	local target=$1
	local primary_dir="$(wt_primary_dir)"

	# default to primary
	if [ -z "$target" ]; then
		exe cd "$primary_dir"
		return
	fi

	local wtpath=$(wt_match "$target")
	if [ $? -eq 0 ]; then
		exe cd "$wtpath"
	fi
}

wt_del() {
	local wtpath=$(wt_match "$@")
	local _match=$?
	if [ $_match -ne 0 ]; then
		return $_match
	fi

	local answer
	printf 'Remove worktree %s? [y/f/N] ' "$wtpath"
	read -r answer
	case "$answer" in
		y|Y|yes|YES|Yes)
			exe git worktree remove "$wtpath"
			;;
		f|force)
			exe git worktree remove --force "$wtpath"
			;;
		*)
			return 0
			;;
	esac
}

# worktree config: .wtconf
# [link]
# node_modules
# .venv

# [copy]
# .env
wt_config() {
	local primary_dir="$(wt_primary_dir)"
	local src_dir="$(git rev-parse --show-toplevel)"
	local dst_dir=$1
	local config=${2:-$WORK_CONFIG}

	if [[ -r "$primary_dir/$config" ]]; then
		local section=""
		while IFS= read -r line || [[ -n "$line" ]]; do
			[[ -z "$line" ]] && continue
			[[ "$line" = \#* ]] && continue

			local src="$src_dir/$line"
			local dst="$dst_dir/$line"

			case "$line" in
				"[link]") section="link" ;;
				"[copy]") section="copy" ;;
				"["*"]") section="" ;;   # unknown section: ignore following lines
				*)
					case "$section" in
						link)
							if [ -e "$src" ]; then
								exe ln -s $src $dst
							fi
							;;
						copy)
							if [ -e "$src" ]; then
								exe cp -R $src $dst
							fi
							;;
					esac
					;;
			esac
		done < "$primary_dir/$config"
	fi
}

wt_add() {
	if [ "$#" -ge 2 ]; then
		local name=$1
		local branch=$2
	elif [ "$#" -eq 1 ]; then
		local name="$(wt_primary_name)"
		local branch=$1
	else
		local name="$(wt_primary_name)"
		local branch="${head -c 2 /dev/urandom | xxd -p}"
	fi

	local wtpath="$WORK_FOREST/$name-$branch"
	exe git worktree add --detach "$wtpath"
	wt_config "$wtpath"
}
