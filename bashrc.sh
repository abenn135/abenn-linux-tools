#!/bin/bash
falcon_init () {
    # krew
    if [ -d ${KREW_ROOT:-$HOME/.krew}/bin ]; then
    	export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    fi
    alias kc1="kubectl --context=cw_condor1"
    alias kc2="kubectl --context=cw_condor2"
    alias kcf="kubectl --context=falcon-phx-ga"
    alias kcfc="kubectl --context=falcon-test-cpu"
    alias kcfs="kubectl --context=falcon-phx-ga-staging"
    alias kch="kubectl --context=cw_hawk"
    alias kcm="kubectl --context=mango-pdx -n mechavarria"
    alias kc1s="kubectl --context=cw_condor1 -n tenant-slurm-staging"
    alias kc2s="kubectl --context=cw_condor2 -n tenant-slurm-staging"
}

abenn_init () {
    pushd "$( dirname "${BASH_SOURCE[0]}" )"
    if [ -f ./tmux_init.sh ]; then
        . ./tmux_init.sh
    fi
    if [ -f ./aks_init.sh ]; then
        echo "skipping aks init"
        #. ./aks_init.sh
    fi
    popd
    export GPG_TTY=$(tty)
    if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
        export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
    fi
    alias k="kubectl"
    falcon_init
}

kubebuilder_completion () {
    # kubebuilder autocompletion
    if [ -f /usr/local/share/bash-completion/bash_completion ]; then
        . /usr/local/share/bash-completion/bash_completion
    else
        . <(kubebuilder completion bash)
    fi
}

abenn_init
kubebuilder_completion
