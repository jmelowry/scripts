#!/bin/bash

[ -z "$TMUX" ] && echo "not in tmux" && exit 1

session=$(tmux list-sessions -F '#S' | fzf --prompt='switch to session: ') || exit 1

current=$(tmux display-message -p '#S')
[ "$session" = "$current" ] && tmux display-message "already in session: $session" && exit 0

tmux switch-client -t "$session" || {
  tmux display-message "failed to switch to session: $session"
  exit 1
}
