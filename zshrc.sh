#!/bin/zsh

setopt errexit

export PATH="$HOME/bin:$PATH"

# History (ctrl-R) stuff
setopt EXTENDED_HISTORY
setopt inc_append_history_time

if [ -d "$HOME/.zfunc" ]; then
  fpath+="$HOME/.zfunc"
fi

source "$(dirname "${(%):-%x}")/zsh_history_widget.sh"

if [ -f "$HOME/.cloud-tools/ct_setup_shell.sh" ]; then
  . "${HOME}/.cloud-tools/ct_setup_shell.sh"
fi

GPG_TTY=$(tty)
export GPG_TTY

autoload -U colors && colors
setopt PROMPT_SUBST
PROMPT=$'\n%{$fg[yellow]%}%~%{$reset_color%}$(git-prompt-string)\n%{$fg[green]%}zsh %{$fg[cyan]%}%#%{$reset_color%} '
export PROMPT

if [ -f "/opt/homebrew/bin/mise" ]; then
  eval "$(/opt/homebrew/bin/mise activate zsh)"
fi

alias k="kubectl"

# Leave at the end.
#
# Don't leave errexit on during normal shell usage, otherwise your shell will exit on any command error!!
unsetopt errexit
