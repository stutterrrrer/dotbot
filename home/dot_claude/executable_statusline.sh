#!/bin/bash
# Claude Code CLI status line: model | folder | git branch | context used.
# Claude Code passes session data as JSON on stdin (see
# https://code.claude.com/docs/en/statusline); whatever we print is shown.
session_json=$(cat)

model_name=$(jq -r '.model.display_name // "?"' <<<"$session_json")
current_dir=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$session_json")
context_percent=$(jq -r '.context_window.used_percentage // 0' <<<"$session_json" | cut -d. -f1)

git_branch=""
if [[ -n "$current_dir" ]]; then
  git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
fi

status_text="$model_name | ${current_dir##*/}"
[[ -n "$git_branch" ]] && status_text+=" | $git_branch"
status_text+=" | ctx ${context_percent}%"
echo "$status_text"
