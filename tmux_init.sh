#!/bin/bash

SESSIONNAME="happy-session"
WINDOWNAME="happy-window"
tmux has-session -t $SESSIONNAME &> /dev/null

if [ $? != 0 ]
then
    tmux new-session -s $SESSIONNAME -n $WINDOWNAME -c $HOME -d
    tmux set-option -t $SESSIONNAME visual-bell both
fi

tmux attach -t $SESSIONNAME
