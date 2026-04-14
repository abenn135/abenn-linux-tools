#!/bin/zsh

setopt errexit

export PATH="$HOME/bin:$PATH"

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
