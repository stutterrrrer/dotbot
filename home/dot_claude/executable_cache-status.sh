#!/bin/bash
# Prints just row 1's cache badge from statusline.sh, standalone — for Claude
# to run inside the desktop app (Code tab), which has no status line of its
# own. Usage: cache-status.sh <transcript.jsonl>
#
# The desktop app doesn't hand Claude the live prompt_cache.expires_at field
# the CLI gets on stdin, so this estimates the same way statusline.sh does
# for a just-resumed session: read the last real assistant reply's timestamp
# and total prompt size (input + cache read + cache creation = what the next
# message re-sends) from the transcript, then assume the standard 1-hour
# cache TTL (5 minutes instead only applies once the account is in paid
# overage — this script doesn't check for that).
set -euo pipefail
transcript_path="$1"
current_epoch=$(date +%s)

IFS=$'\x1f' read -r last_reply_epoch last_prompt_tokens <<<"$(
  tail -n 400 "$transcript_path" 2>/dev/null \
    | grep '"type":"assistant"' | grep '"usage"' \
    | grep -v '"model":"<synthetic>"' | tail -n 1 \
    | jq -r '[ (.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601),
              (.message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0)
                                + (.cache_creation_input_tokens // 0)) ]
             | map(tostring) | join("\u001f")' 2>/dev/null
)"

if [[ -z "$last_reply_epoch" ]]; then
  echo "🆕new chat"
  exit 0
fi

elapsed_minutes=$(( (current_epoch - last_reply_epoch) / 60 ))
ttl_minutes=60

if (( elapsed_minutes < ttl_minutes )); then
  minutes_left=$(( ttl_minutes - elapsed_minutes ))
  if (( minutes_left >= 30 )); then icon="🟢"
  elif (( minutes_left >= 10 )); then icon="🟡"
  else icon="🔴"; fi
  # Trailing "?" is deliberate, not a glitch: unlike the CLI, the desktop app
  # never gets live prompt_cache data, so this is always a guess from elapsed
  # time, never a confirmed-warm read.
  echo "${icon}cache ${minutes_left}m? left — next message is cheap"
else
  if (( last_prompt_tokens >= 1000 )); then
    size="$(( last_prompt_tokens / 1000 ))k"
  else
    size="$last_prompt_tokens"
  fi
  echo "🧊cache cold — next message re-reads ${size} tokens at full price"
fi
