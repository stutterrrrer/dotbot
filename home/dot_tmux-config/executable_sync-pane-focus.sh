#!/bin/sh
# Run by tmux hooks (after-select-pane, after-split-window, after-select-window,
# after-kill-pane, client-session-changed) whenever the active pane changes.
#
# tmux's own `focus-events` option only forwards focus in/out from the OUTER
# terminal (the whole tmux client gaining/losing OS-level window focus) to
# whichever pane is currently active - it does NOT synthesize a focus event
# when the active pane changes via an internal pane switch (e.g. prefix+arrow,
# `select-pane`), even though `set -g focus-events on` is required for the
# outer-terminal case too. Confirmed empirically: an autocmd logging
# FocusLost/FocusGained never fired on `select-pane`, only on real terminal
# focus changes.
#
# This tmux build also has no pane-focus-in/pane-focus-out hooks (only
# client-focus-in/out, which is the same outer-terminal-only event) despite
# some tmux docs mentioning them - `tmux show-hooks -g` is the source of
# truth for what a given build actually supports.
#
# So: on every pane-switch-shaped event, walk every pane in every window/
# session and push the raw xterm focus escape codes (CSI I / CSI O) directly
# to whichever ones are running vim, matching tmux's own active-pane state.
# `pane_current_command` reports the binary as "Vim" (capital V) on this
# machine, not "vim" - match case-insensitively so it doesn't silently stop
# matching after a vim upgrade/reinstall changes casing again.
tmux list-panes -a -F '#{pane_id} #{?#{&&:#{pane_active},#{window_active}},1,0} #{pane_current_command}' |
while read -r id active cmd; do
  case "$cmd" in
    [Vv]im|[Nn]vim)
      if [ "$active" = 1 ]; then
        tmux send-keys -t "$id" -H 1b 5b 49 # CSI I - FocusGained
      else
        tmux send-keys -t "$id" -H 1b 5b 4f # CSI O - FocusLost
      fi
      ;;
  esac
done
