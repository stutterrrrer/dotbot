#!/bin/bash
# Claude Code Notification hook: macOS banner + sound when the CLI needs my
# input (permission prompt, or idle waiting for a reply). IntelliJ terminal
# tabs don't make this obvious on their own.
# The desktop app has its own notifications, so stay silent there.
[[ "$CLAUDE_CODE_ENTRYPOINT" == "claude-desktop" ]] && exit 0

hook_json=$(cat)
notification_message=$(jq -r '.message // "Claude Code needs your input"' <<<"$hook_json")
project_name=$(basename "$(jq -r '.cwd // ""' <<<"$hook_json")")

# Pass text as argv so quotes in the message can't break the AppleScript.
osascript - "$notification_message" "Claude Code · $project_name" <<'APPLESCRIPT'
on run argv
  display notification (item 1 of argv) with title (item 2 of argv) sound name "Glass"
end run
APPLESCRIPT
