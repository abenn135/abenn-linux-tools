#!/bin/bash
abenn_init () {
    pushd "$( dirname "${BASH_SOURCE[0]}" )"
    if [ -f ./tmux_init.sh ]; then
        . ./tmux_init.sh
    fi
    if [ -f ./aks_init.sh ]; then
        echo "yes"
        #. ./aks_init.sh
    fi
    popd
    export GPG_TTY=$(tty)
    if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
        export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
    fi
}

abenn_init
