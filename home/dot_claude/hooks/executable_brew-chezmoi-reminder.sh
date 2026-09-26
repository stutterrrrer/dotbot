#!/bin/bash
# Claude Code PostToolUse hook (Bash): after a brew command that adds,
# removes, or (un)taps a package runs, remind the assistant to ask Ian
# whether the change should also be tracked in ~/.chezmoi -- add/remove the
# package in Brewfile, and for a cask with GUI settings, add or update its
# entry in APPLICATION-MIGRATION-CHECKLIST.md. Silent for every other Bash
# command (brew list/info/search/update/upgrade/bundle, non-brew commands),
# so it stays cheap to run on every tool call.
hook_json=$(cat)
command=$(jq -r '.tool_input.command // ""' <<<"$hook_json")

if grep -qE '\bbrew[[:space:]]+(install|uninstall|remove|rm|reinstall|tap|untap)\b' <<<"$command"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: "This brew command changed installed packages/taps. Ask Ian whether he wants a corresponding change tracked in ~/.chezmoi: add or remove the package in Brewfile, and if it is a cask with GUI settings, add or update its entry in APPLICATION-MIGRATION-CHECKLIST.md."
    }
  }'
fi
