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

# Only match brew in command position: at the start of a line or after a
# shell separator (; & | or a "(" from $(...)), optionally behind sudo/env,
# VAR=value prefixes, or a full path. Plain text like a commit message or
# `echo "brew install x"` mentioning brew mid-line doesn't count.
brew_command_pattern='(^|[;&|(])[[:space:]]*((sudo|env)[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*([^[:space:];&|()]*/)?brew[[:space:]]+(install|uninstall|remove|rm|reinstall|tap|untap)([[:space:]]|$)'

if grep -qE "$brew_command_pattern" <<<"$command"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: "This brew command changed installed packages/taps. Ask Ian whether he wants a corresponding change tracked in ~/.chezmoi: add or remove the package in Brewfile, and if it is a cask with GUI settings, add or update its entry in APPLICATION-MIGRATION-CHECKLIST.md."
    }
  }'
fi
