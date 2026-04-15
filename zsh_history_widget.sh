skim-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  local awk_filter='{ cmd=$0; sub(/^\s*[0-9]+\**\s+/, "", cmd); if (!seen[cmd]++) print $0 }'  # filter out duplicates
  local n=1 fc_opts=''
  if [[ -o extended_history ]]; then
    awk_filter='
{
  ts = int($2)
  delta = systime() - ts
  delta_days = int(delta / 86400)
  if (delta < 0) { $2="+" (-delta_days) "d" }
  else if (delta_days < 1 && delta < 72000) { $2=strftime("%H:%M", ts) }
  else if (delta_days == 0) { $2="1d" }
  else { $2=delta_days "d" }
  line=$0; $1=""; $2=""
  if (!seen[$0]++) print line
}'
    fc_opts='-i'
    n=2
  fi
  selected=( $(fc -rl $fc_opts -t '%s' 1 | sed -E "s/^ *//" | gawk "$awk_filter" |
    SKIM_DEFAULT_OPTIONS="--height ${SKIM_TMUX_HEIGHT:-40%} $SKIM_DEFAULT_OPTIONS --with-nth $n.. --bind=ctrl-r:toggle-sort $SKIM_CTRL_R_OPTS --query=${(qqq)LBUFFER} --no-multi" sk) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
}
zle     -N   skim-history-widget
bindkey '^R' skim-history-widget
