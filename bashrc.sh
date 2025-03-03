#!/bin/bash
abenn_init () {
    pushd "$( dirname "${BASH_SOURCE[0]}" )"
    . ./tmux_init.sh
    popd
}

abenn_init