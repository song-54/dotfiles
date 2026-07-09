. $HOME/.config/dotfiles/common.sh

WORK_FOREST=$HOME/.worktree

gwt() {
	local command=$1
	if [ -n "$command" ]; then
		shift
	fi

	case "$command" in
		br | branch)
			gwt_branch "$@"
			if [ $? -ne 0 ]; then
				echo "gwt: gwt br <branch>"
			fi
			;;
		cd)
			gwt_cd "$@"
			;;
		"")
			git worktree list
			return 1
			;;
		*)
			echo "gwt: unknown command: $command" >&2
			return 2
			;;
	esac
}

gwt_primary_dir() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
	git worktree list --porcelain | sed -n '1s/^worktree //p'
}

gwt_primary_name() {
	local primary=$(gwt_primary_dir)
	echo "${primary##*/}"
}

gwt_cd() {
	local target=$1
	local primary_dir="$(gwt_primary_dir)"
	local primary_name="${primary_dir##*/}"

	if [ -n "$target" ]; then
		exe cd "$WORK_FOREST/$primary_name-$target"
	else
		exe cd "$primary_dir"
	fi
}

# config
# [link]
# node_modules
# .venv

# [copy]
# .env
gwt_config() {
	local config=$1
	local target=$2

	if [ -z "$config" ]; then
		config=.worktree
	fi

	local primary_dir="$(gwt_primary_dir)"
	local primary_name="${primary_dir##*/}"
	local section=""
	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ -z "$line" ]] && continue

		local src="$primary_dir/$line"
		local dst="$target/$line"

		case "$line" in
			"[link]") section="link" ;;
			"[copy]") section="copy" ;;
			"["*"]") section="" ;;   # unknown section: ignore following lines
			*)
				case "$section" in
					link)
						if [ -e "$src" ]; then
							exe ln -s $src $target
						fi
						;;
					copy)
						if [ -e "$src" ]; then
							exe cp -R $src $target
						fi
						;;
				esac
				;;
		esac
	done < "$primary_dir/$config"
}

gwt_branch() {
	local branch=$1
	local name=$2

	if [ -z "$branch" ]; then
		return 1
	fi

	if [ -z "$name" ]; then
		name="$(gwt_primary_name)"
	fi

	local target="$WORK_FOREST/$name-$branch"
	git worktree add -b "$branch" "$target"
	gwt_config .worktree $target
}
