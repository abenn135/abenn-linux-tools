#!/bin/bash
abenn_init () {
    pushd "$( dirname "${BASH_SOURCE[0]}" )"
    if [ -f ./tmux_init.sh ]; then
        . ./tmux_init.sh
    fi
    if [ -f ./aks_init.sh ]; then
        . ./aks_init.sh
    fi
    popd
}

abenn_init
