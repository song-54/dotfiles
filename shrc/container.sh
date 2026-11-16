# vi: ft=bash
# docker#
alias dk=docker
alias dkr='docker run -it --rm'
alias dkup='docker run -it --name'
alias dke='docker exec -it'
alias dksh='docker exec -it'
alias dkc='docker container'
alias dkcrm='docker container ls -a --format "{{.ID}} {{.Names}}\t{{.Image}}\t{{.Command}}\t{{.Status}}" | fzf -m | awk "{print \$1}" | xargs -r docker rm'
alias dki='docker image'
alias dkirm='docker images --format "{{.Repository}}:{{.Tag}} ({{.ID}})" | fzf -m | awk "{print $NF}" | tr -d "()" | xargs -r docker rmi'
alias dkic='docker rmi $(docker images -f "dangling=true" -q)'
# run --mount type=bind,source=$SRC,target=/$TARGET

# kubernetes
#alias ku=kubectl
function ku() {
    export KUCTX= # enable starship
	cmd() {
        if test $? -eq 0; then
            if [ "$#" -eq 3 ]; then
                exe kubectl config use-context $3
            else
                exe kubectl --context "$3" "${@:4}"
            fi
        else
            # default alias
            exe kubectl $@
        fi
	}
	# kube list
	if [ -f $KULST ]; then
		# arg match: name cluster -> context namespace cluster
		argm 2 cmd $@ < $KULST
	else
		kubectl $@
	fi
}
alias kuls='kubectl get pod,deploy,svc,statefulset'
alias kua='kubectl apply'
alias kuc='kubectl create'
alias kud='kubectl delete'
alias kucat='kubectl describe'
alias kush='kubectl exec -it'
alias kucfg='kubectl config use-context'
alias kuport='kubectl port-foward'

## merge kubeconfig
function kucfgm() {
	local config="$HOME/.kube/config"
	# merge
	echo "[>] KUBECONFIG=$1:$config kubectl config view --merge --flatten"
	KUBECONFIG=$1:$config kubectl config view --merge --flatten > "$config.merge"

	# backup current config
	local backup="$config.bak"
	local counter=1

	while [ -f "$backup" ]; do
		backup="$config.bak.$counter"
		((counter++))
	done
	mv "$config" "$backup"
	echo "Backup: $config -> $backup"
	mv "$config.merge" "$config"
}

## ku auto complete
function kucomp() {
	if [ -n "$ZSH_VERSION" ]; then
		autoload -Uz compinit
		compinit
		source <(kubectl completion zsh)
	elif [ -n "$BASH_VERSION" ]; then
		source <(kubectl completion bash)
		complete -o default -F __start_kubectl ku
	fi
}
