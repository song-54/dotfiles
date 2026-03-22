function sdkman() {
	lst=$HOME/.bin/local/sdk.lst
	# ex) jdk 8 java 8.0.0-dist
	cmd() { test $? -eq 0 && exe sdk use $3 $4 || exe sdk $@; }
	argm 2 cmd $@ < $lst
}

function jdk() {
	# n sdk_java_version
	lst=$HOME/.bin/local/jdk.lst
	cmd() { test $? -eq 0 && exe sdk use java $2; }
	argm 1 cmd $@ < $lst
}

function venv() {
	local dir=${1:-.venv}
	if [ ! -d "$dir" ]; then
		exe python3 -m venv "$dir" --upgrade-deps
	fi
	exe source "$dir/bin/activate"
}

function dotenv() {
	local env=${1:-.env}
	exe "export $(cat $env | xargs)"
}

# Lazy Loading
: <<EXAMPLE
lazy _init_ruby ruby irb rake bundle chruby
lazy _init_fzf fzf
lazy _init_nvm nvm node npm pnpm npx
lazy _init_sdk sdk
lazy_comp kubectl
EXAMPLE

function lazy() {
	local init=$1
	shift
	local cmds=("$@")

	for cmd in "${cmds[@]}"; do
		eval "
			$cmd() {
				unset -f ${cmds[@]} 2>/dev/null
				$init || { lazy $init ${cmds[@]}; return \$?; }
				$cmd \"\$@\"
			}
		"
	done
}

_init_ruby() {
	[[ -s /usr/local/share/chruby/chruby.sh ]] && source /usr/local/share/chruby/chruby.sh && \
	chruby ruby
}

_init_fzf() { [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh ; }

_init_nvm() {
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

_init_sdk() {
	#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
	export SDKMAN_DIR="$HOME/.sdkman"
	[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
}

_comp_kubectl() {
	if [ -n "$ZSH_VERSION" ]; then
		compdef -d kubectl
		source <(kubectl completion zsh)
	elif [ -n "$BASH_VERSION" ]; then
		source <(kubectl completion bash)
	fi
}

# register function "_comp_${app}_$sh"
function lazy_comp() {
	local app=$1

	if [ -n "$ZSH_VERSION" ]; then
		# Ensure compinit is loaded for zsh
		if ! command -v compdef >/dev/null; then
			autoload -Uz compinit && compinit
		fi
		compdef _comp_$app $app
	elif [ -n "$BASH_VERSION" ]; then
		complete -F _comp_$app $app
	fi
}
