#!/bin/bash
# Claude Code CLI status line, three rows (each echo is one row):
#   1: prompt cache | model effort (fast) | 5-hour % ⏳left, weekly % ⏳left
#      e.g. "🟢cache 47m | Opus 5.5 high | 53% ⏳2h-27m, 8% ⏳6d-4h"
#      Cache state leads because it's the one thing that actually swings the
#      price of the *next* message. A big context is not itself expensive: a
#      warm cache reads back at a small fraction of fresh-input price, however
#      large the conversation is, so size alone never makes one message
#      costlier than the last. The only genuinely expensive event is the cache
#      going cold — a full-price re-read, once, proportional to whatever the
#      context had grown to. Auto-compact (see row 2's ctx%) is a separate,
#      usually-cheap event: while the cache is warm going in, it just re-reads
#      the huge prefix from cache and writes a short summary, i.e. one more
#      normal cached turn, not a full re-read. It's only expensive on the rare
#      case where the cache had *already* gone cold before it fired (a
#      long-idle resume of a huge session).
#      - cache warm: time until it expires; emoji = how urgent it is to send
#        the next message: 🟢 30m+  🟡 10-29m  🔴 under 10m
#      - cache cold: tokens the next reply re-processes at full price; emoji =
#        how much of the window that is: 🧊 under 60%  💰 60-84%  💸 85%+
#      - resumed session, before its first reply: Claude Code has no cache info
#        yet, so it's estimated from the transcript's last reply:
#        🚨cache cold 87k (last reply 1 h+ ago: the next message re-processes
#        everything) or 🟠cache 23m? (maybe still warm, unless CLAUDE.md,
#        settings or tools changed since — the trailing ? flags that this is
#        a guess, not live data, on purpose, so it's not mistaken for a glitch)
#      - brand-new session: 🆕new chat (nothing cached, nothing to reload)
#      - quota: no "5h"/"wk" labels, the time left tells them apart
#        (hours = 5-hour window, days = weekly)
#   2: ctx tokens % | 📁cwd (leaf folder) | branch●changed↑ahead↓behind |
#      edits +added −removed | IDE✓/✗ | ␣=talk (voice mode hint, only if voice is on)
#      (row 2 = this session's own state)
#      % is tokens used ÷ the auto-compact threshold (not ÷ the model's raw
#      window) — i.e. how close to the next compaction, computed from the
#      pinned autoCompactWindow setting and the live model's own window, so
#      it stays correct whatever model the session is on (see
#      compact_threshold below).
#      ctx is informational, not an auto-compact alarm — compaction itself is
#      cheap while the cache is warm (one more ordinary cached turn: the old
#      history reads back at cache rate, only the short new summary is
#      full-price). What ctx's color actually flags is the *running per-message
#      cost* of a warm cache read, which scales with raw tokens in context, not
#      with % of the window (a 200k-window session at 100% is still cheap; a
#      1M-window session at 30% already isn't) — so it's bucketed by absolute
#      token count: 🟢 under 300k (~$0.06/msg)  🟡 300k-699k (~$0.06-0.14/msg)
#      🔴 700k+ (~$0.14+/msg), at Sonnet 5's $0.20/MTok cache-read rate.
#   3: tokens of the current/last question (everything since my last typed
#      prompt, all tool-call round trips summed), each with its $/MTok price
#      for the live model and that part's cost, then Σ = the question's
#      API-equivalent total:
#      e.g. "Q: 📥12k·7.8=$0.09 | 🔁850k·0.2=$0.17 | 📤4.1k·20=$0.08 | Σ$0.35"
#      📥 new input = uncached input + cache writes (the $ is their blended
#         rate: cache writes cost 1.25x input for 5-min, 2x for 1-hour TTL)
#      🔁 cache reads (the whole conversation re-read on every tool call —
#         a big number, but at 1/20 of the input price)
#      📤 output (incl. thinking)
#      Only emoji that are wide on their own (📥🔁📤): ones that need the
#      U+FE0F emoji selector (♻️) are drawn 2 cells wide but counted as 1 by
#      the terminal, so the next character overlaps them. The "·" multiply
#      dot has an ambiguous width (2 cells in some CJK terminal settings), so
#      it's only used inside a part and "|" separates parts; if it ever
#      overlaps, swap it for a plain "*".
#      Prices are Claude Code's own table (model catalog in the claude
#      binary, same as /cost). On a subscription it's what the question
#      would cost on the API, not a bill. Subagent tokens aren't included.
# Icons sit directly against their text, with no space.
# The session title is already shown above the prompt, and the vim mode by
# Claude Code's own instant "-- INSERT --" indicator, so neither is repeated.
# Claude Code passes session data as JSON on stdin (see
# https://code.claude.com/docs/en/statusline); whatever we print is shown.

# Speed matters: this re-runs on every vim mode change, and each extra process
# (jq, date, git, ps…) costs ~7 ms on this Mac. So ONE jq call extracts every
# field, formats the time left until each quota resets, and returns the
# current time. Fields are
# joined by the ASCII unit separator so empty values survive `read`.
IFS=$'\x1f' read -r model_name current_dir context_window_size context_tokens context_tokens_raw effort_level \
  fast_mode_enabled lines_added lines_removed session_minutes \
  five_hour_percent five_hour_reset weekly_percent weekly_reset \
  cache_is_warm cache_time_left cache_minutes_left cache_reload_tokens \
  has_cache_info transcript_path model_id current_epoch < <(
  jq -r '
    # Seconds until a Unix-epoch reset time, as "6d-4h", "2h-27m", "45m" or "<1m"
    # (the dash keeps each duration visually one item).
    def time_left:
      ([. - now, 0] | max | floor) as $seconds_left
      | ($seconds_left / 86400 | floor) as $days
      | ($seconds_left % 86400 / 3600 | floor) as $hours
      | ($seconds_left % 3600 / 60 | floor) as $minutes
      | if $days > 0 then "\($days)d-\($hours)h"
        elif $hours > 0 then "\($hours)h-\($minutes)m"
        elif $minutes > 0 then "\($minutes)m"
        else "<1m" end;
    [
      .model.display_name // "?",
      .workspace.current_dir // .cwd // "",
      (.context_window.context_window_size // 200000 | floor),
      ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)
        | if . >= 1000 then "\(. / 1000 | floor)k" else tostring end),
      ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0) | floor),
      .effort.level // "",                      # low … max
      .fast_mode // false,
      .cost.total_lines_added // 0,
      .cost.total_lines_removed // 0,
      (.cost.total_duration_ms // 0 | . / 60000 | floor),
      (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
      (.rate_limits.five_hour.resets_at // "" | if . == "" then . else time_left end),
      (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor end),
      (.rate_limits.seven_day.resets_at // "" | if . == "" then . else time_left end),
      # Prompt cache (absent until the first reply): warm while expires_at is ahead.
      ((.prompt_cache.warm // false) and ((.prompt_cache.expires_at // 0) > now)),
      (.prompt_cache.expires_at // "" | if . == "" then . else time_left end),
      (.prompt_cache.expires_at // 0 | [. - now, 0] | max / 60 | floor),
      (.prompt_cache.recache_tokens_if_cold // "" | if . == "" then .
        elif . >= 1000 then "\(. / 1000 | floor)k" else tostring end),
      (.prompt_cache != null),
      .transcript_path // "",
      .model.id // "",
      (now | floor)
    ] | map(tostring) | join("\u001f")')   # reads the session JSON from our stdin

# Git branch without launching git: find the nearest .git/HEAD and read it.
# Falls back to `git` for worktrees/submodules, where .git is a file.
# git_root is also reused below for the cwd badge, so a deeply nested cwd
# (e.g. a scratch subfolder several levels under the repo) still shows the
# repo's own name instead of a meaningless leaf directory.
git_branch=""
git_root=""
search_dir="$current_dir"
while [[ -n "$search_dir" && "$search_dir" != "/" ]]; do
  if [[ -f "$search_dir/.git/HEAD" ]]; then
    read -r head_ref < "$search_dir/.git/HEAD"
    if [[ "$head_ref" == "ref: refs/heads/"* ]]; then
      git_branch="${head_ref#ref: refs/heads/}"
    else
      git_branch="${head_ref:0:7}"   # detached HEAD: short commit hash
    fi
    git_root="$search_dir"
    break
  elif [[ -f "$search_dir/.git" ]]; then
    git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    git_root="$search_dir"
    break
  fi
  search_dir="${search_dir%/*}"
done

# Git dirty state after the branch: "master ●3 ↑1 ↓2" = 3 changed/untracked
# files, 1 commit to push, 2 to pull (vs. the upstream as of the last fetch).
# `git status` costs ~15-30 ms, so cache it per claude process for a few
# seconds; the cache also stores the folder so a /cd refreshes it.
git_state=""
git_cache_file="${TMPDIR:-/tmp}/claude-statusline-git-$PPID"
git_cache_seconds=5
if [[ -n "$git_branch" ]]; then
  cached_git_line=""
  [[ -f "$git_cache_file" ]] && IFS= read -r cached_git_line < "$git_cache_file"
  IFS=$'\x1f' read -r cached_epoch cached_dir cached_state <<<"$cached_git_line"
  if [[ "$cached_dir" == "$current_dir" ]] && (( current_epoch - ${cached_epoch:-0} < git_cache_seconds )); then
    git_state="$cached_state"
  else
    changed_file_count=0
    commits_ahead=0
    commits_behind=0
    while IFS= read -r status_line; do
      if [[ "$status_line" == "## "* ]]; then
        # e.g. "## master...origin/master [ahead 1, behind 2]"
        [[ "$status_line" =~ ahead\ ([0-9]+) ]] && commits_ahead=${BASH_REMATCH[1]}
        [[ "$status_line" =~ behind\ ([0-9]+) ]] && commits_behind=${BASH_REMATCH[1]}
      elif [[ -n "$status_line" ]]; then
        (( changed_file_count++ ))
      fi
    done < <(git -C "$current_dir" --no-optional-locks status --porcelain=v1 --branch 2>/dev/null)
    (( changed_file_count > 0 )) && git_state+="●$changed_file_count"
    (( commits_ahead > 0 )) && git_state+="↑$commits_ahead"
    (( commits_behind > 0 )) && git_state+="↓$commits_behind"
    printf '%s\x1f%s\x1f%s\n' "$current_epoch" "$current_dir" "$git_state" > "$git_cache_file"
  fi
fi

# --- IDE connection -------------------------------------------------------
# The JSON has no IDE field. Each running IDE plugin writes
# ~/.claude/ide/<port>.lock; the session is connected when its claude process
# holds an ESTABLISHED socket to one of those ports. Walk up from this script
# to find the claude process (the command may run under an intermediate shell).
find_claude_pid() {
  local candidate_pid=$PPID
  for _ in 1 2 3 4; do
    [[ -z "$candidate_pid" || "$candidate_pid" -le 1 ]] && return 1
    if [[ "$(ps -o comm= -p "$candidate_pid" 2>/dev/null)" == *claude* ]]; then
      echo "$candidate_pid"
      return 0
    fi
    candidate_pid=$(ps -o ppid= -p "$candidate_pid" 2>/dev/null | tr -d ' ')
  done
  return 1
}

# The lsof check costs ~30 ms, so cache its result per claude process for a
# few seconds; vim mode changes re-run this script often.
ide_status=""
shopt -s nullglob
ide_lock_files=("$HOME"/.claude/ide/*.lock)
ide_cache_file="${TMPDIR:-/tmp}/claude-statusline-ide-$PPID"
ide_cache_seconds=10
if (( ${#ide_lock_files[@]} > 0 )); then
  # Cache file content: "<epoch seconds> <status text>"
  cached_line=""
  [[ -f "$ide_cache_file" ]] && read -r cached_line < "$ide_cache_file"
  if [[ -n "$cached_line" ]] && (( current_epoch - ${cached_line%% *} < ide_cache_seconds )); then
    ide_status="${cached_line#* }"
  else
    ide_status="IDE✗"
    claude_pid=$(find_claude_pid)
    if [[ -n "$claude_pid" ]]; then
      established_ports=$(lsof -a -p "$claude_pid" -iTCP -sTCP:ESTABLISHED -nP 2>/dev/null \
        | awk 'NR>1 {split($9, ends, "->"); n=split(ends[2], hostport, ":"); print hostport[n]}')
      for lock_file in "${ide_lock_files[@]}"; do
        ide_port="${lock_file##*/}"; ide_port="${ide_port%.lock}"
        if grep -qx "$ide_port" <<<"$established_ports"; then
          ide_status="IDE✓"   # the lock file's ideName says which IDE (IntelliJ IDEA)
          break
        fi
      done
    fi
    printf '%s %s' "$current_epoch" "$ide_status" > "$ide_cache_file"
  fi
fi

# Voice mode: not in the session JSON, so read the user settings file once
# and cache the result per claude process (it can't change mid-session).
voice_cache_file="${TMPDIR:-/tmp}/claude-statusline-voice-$PPID"
if [[ -f "$voice_cache_file" ]]; then
  read -r voice_enabled < "$voice_cache_file"
else
  voice_enabled=$(jq -r '.voice.enabled // .voiceEnabled // false' "$HOME/.claude/settings.json" 2>/dev/null)
  [[ "$voice_enabled" != "true" ]] && voice_enabled="false"
  echo "$voice_enabled" > "$voice_cache_file"
fi

# autoCompactWindow: also not in the session JSON (only context_window_size,
# the *model's* raw max, is), so read the pinned setting the same way as
# voice above. If it's unset, fall back to Claude Code's own untuned default:
# the full window for a 200k model, or ~96.7% of it for a 1M-window model
# (see model-config docs — 1M-window models compact at ~967k, not at 1M).
compact_window_cache_file="${TMPDIR:-/tmp}/claude-statusline-compactwindow-$PPID"
if [[ -f "$compact_window_cache_file" ]]; then
  read -r auto_compact_window < "$compact_window_cache_file"
else
  auto_compact_window=$(jq -r '.autoCompactWindow // empty' "$HOME/.claude/settings.json" 2>/dev/null)
  echo "$auto_compact_window" > "$compact_window_cache_file"
fi
if [[ "$auto_compact_window" =~ ^[0-9]+$ ]]; then
  compact_threshold=$auto_compact_window
elif (( context_window_size >= 900000 )); then
  compact_threshold=$(( context_window_size * 967 / 1000 ))
else
  compact_threshold=$context_window_size
fi
(( compact_threshold > context_window_size )) && compact_threshold=$context_window_size
(( compact_threshold < 1 )) && compact_threshold=$context_window_size
context_percent=$(( context_tokens_raw * 100 / compact_threshold ))

# --- Subscription usage (claude.ai Pro/Max; absent until the first reply) ---
# jq already formatted the time left ("2h-27m", "6d-4h").
five_hour_usage=""
[[ -n "$five_hour_percent" ]] && five_hour_usage="${five_hour_percent}%${five_hour_reset:+ ⏳$five_hour_reset}"
weekly_usage=""
[[ -n "$weekly_percent" ]] && weekly_usage="${weekly_percent}%${weekly_reset:+ ⏳$weekly_reset}"

# Context badge: leads row 2. Bucketed by raw tokens (see header) — the
# running per-message cache-read cost — not % of window, so it sits with this
# session's own state rather than with the cache badge that predicts the
# next *cold-reload* price.
if (( context_tokens_raw >= 700000 )); then ctx_icon="🔴"
elif (( context_tokens_raw >= 300000 )); then ctx_icon="🟡"
else ctx_icon="🟢"; fi
ctx_text="${ctx_icon}ctx ${context_tokens} ${context_percent}%"

# Row 2: ctx | cwd | branch + dirty state | lines changed | IDE. Empty parts
# are skipped. cwd shows the current directory's own leaf name. Truncated to
# 10 chars so long names don't crowd out whatever comes after it on the row.
row_parts=("$ctx_text")
cwd_label="${current_dir##*/}"
cwd_max_chars=10
(( ${#cwd_label} > cwd_max_chars )) && cwd_label="${cwd_label:0:cwd_max_chars}…"
[[ -n "$cwd_label" ]] && row_parts+=("📁${cwd_label}")
[[ -n "$git_branch" ]] && row_parts+=("${git_branch}${git_state}")
(( lines_added + lines_removed > 0 )) && row_parts+=("edits +${lines_added} −${lines_removed}")
[[ -n "$ide_status" ]] && row_parts+=("$ide_status")
[[ "$voice_enabled" == "true" ]] && row_parts+=("␣=talk")
editing_row=""
for row_part in "${row_parts[@]}"; do
  [[ -n "$editing_row" ]] && editing_row+=" | "
  editing_row+="$row_part"
done

# Row 1: prompt cache first, then model + effort, then the two quota windows
# joined by a comma ("53% ⏳2h-27m, 8% ⏳6d-4h").
model_text="$model_name"
[[ -n "$effort_level" ]] && model_text+=" $effort_level"
[[ "$fast_mode_enabled" == "true" ]] && model_text+=" fast"

quota_text="$five_hour_usage"
[[ -n "$quota_text" && -n "$weekly_usage" ]] && quota_text+=", "
quota_text+="$weekly_usage"

# Prompt cache (absent until the first reply), thresholds in the header.
cache_text=""
if [[ "$cache_is_warm" == "true" ]]; then
  if (( cache_minutes_left >= 30 )); then urgency_icon="🟢"
  elif (( cache_minutes_left >= 10 )); then urgency_icon="🟡"
  else urgency_icon="🔴"; fi
  cache_text="${urgency_icon}cache $cache_time_left"
elif [[ -n "$cache_reload_tokens" ]]; then
  if (( context_percent >= 85 )); then cost_icon="💸"
  elif (( context_percent >= 60 )); then cost_icon="💰"
  else cost_icon="🧊"; fi
  cache_text="${cost_icon}cache cold $cache_reload_tokens"
elif [[ "$has_cache_info" == "false" && -f "$transcript_path" ]]; then
  # A resumed session has no prompt_cache data until its first reply, which is
  # exactly when a cold cache is most likely. Estimate from the last reply in
  # the transcript: its time, and its prompt size (input + cache read + cache
  # write = what the next message will send again). The transcript format is
  # internal to Claude Code, so any parsing failure just shows nothing.
  # Only the tail is read, and only until the first reply, so it stays cheap.
  # Cached per transcript file + modification time: before the first reply
  # the file rarely changes, and parsing it on every refresh would be slow.
  transcript_cache_file="${TMPDIR:-/tmp}/claude-statusline-transcript-$PPID"
  transcript_stamp="$transcript_path:$(stat -f %m "$transcript_path" 2>/dev/null)"
  cached_stamp="" ; last_reply_epoch="" ; last_prompt_tokens=""
  [[ -f "$transcript_cache_file" ]] &&
    IFS=$'\x1f' read -r cached_stamp last_reply_epoch last_prompt_tokens < "$transcript_cache_file"
  if [[ "$cached_stamp" != "$transcript_stamp" ]]; then
    # grep finds the last real assistant line fast; jq then parses only that
    # line. Resuming writes a placeholder assistant entry ("<synthetic>" model,
    # 0 tokens, timestamped now) that must be skipped, or the cache looks warm.
    IFS=$'\x1f' read -r last_reply_epoch last_prompt_tokens < <(
      tail -n 400 "$transcript_path" 2>/dev/null \
        | grep '"type":"assistant"' | grep '"usage"' \
        | grep -v '"model":"<synthetic>"' | tail -n 1 \
        | jq -r '[ (.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601),
                  (.message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0)
                                    + (.cache_creation_input_tokens // 0)) ]
                 | map(tostring) | join("\u001f")' 2>/dev/null)
    printf '%s\x1f%s\x1f%s\n' "$transcript_stamp" "$last_reply_epoch" "$last_prompt_tokens" \
      > "$transcript_cache_file"
  fi
  last_reply_minutes_ago=$(( (current_epoch - ${last_reply_epoch:-$current_epoch}) / 60 ))
  if [[ -n "$last_prompt_tokens" ]]; then
    if (( last_prompt_tokens >= 1000 )); then
      last_prompt_size="$(( last_prompt_tokens / 1000 ))k"
    else
      last_prompt_size="$last_prompt_tokens"
    fi
    if (( last_reply_minutes_ago >= 60 )); then
      cache_text="🚨cache cold $last_prompt_size"
    else
      cache_text="🟠cache $(( 60 - last_reply_minutes_ago ))m?"
    fi
  fi
fi
# No cache info and no earlier reply to reload: say so, instead of a blank.
[[ -z "$cache_text" ]] && cache_text="🆕new chat"

usage_row="$cache_text | $model_text"
[[ -n "$quota_text" ]] && usage_row+=" | $quota_text"

# --- Row 3: this question's tokens and prices (see header) ----------------
# $/MTok as [input, output, 5-min cache write, 1-hour cache write, cache read],
# copied from Claude Code's model catalog (pricing_tiers in the claude
# binary). Most specific ids first: "opus-5-5" must match before "opus-5".
# Fast mode bills Opus 5.5 at 2x. Unknown models: no prices, tokens only.
case "$model_id" in
  *opus-5-5*)
    if [[ "$fast_mode_enabled" == "true" ]]; then model_prices="[8,40,10,16,0.4]"
    else model_prices="[4,20,5,8,0.2]"; fi ;;
  *opus-5*|*opus-4-[5-8]*) model_prices="[5,25,6.25,10,0.5]" ;;
  *opus-4*)               model_prices="[15,75,18.75,30,1.5]" ;;
  *sonnet-5*)             model_prices="[2,10,2.5,4,0.2]" ;;
  *sonnet*)               model_prices="[3,15,3.75,6,0.3]" ;;
  *fable-5-1*|*mythos-5-1*) model_prices="[10,50,12.5,20,0.25]" ;;
  *fable-5*|*mythos-5*)   model_prices="[10,50,12.5,20,1]" ;;
  *haiku-4-5*)            model_prices="[1,5,1.25,2,0.1]" ;;
  *)                      model_prices="null" ;;
esac

# Read the transcript backwards up to my last typed prompt (the only user
# entries with a "promptSource" key; tool results and injected messages lack
# it), keeping this conversation's own assistant replies. Each API reply is
# logged once per content block with the same usage, so jq keeps one per
# message id. Cached per transcript size + mtime, since the status line
# re-runs on every vim mode change.
question_row=""
if [[ -f "$transcript_path" ]]; then
  question_cache_file="${TMPDIR:-/tmp}/claude-statusline-question-$PPID"
  question_stamp="$transcript_path:$(stat -f %z:%m "$transcript_path" 2>/dev/null):$model_prices"
  cached_question_line=""
  [[ -f "$question_cache_file" ]] && IFS= read -r cached_question_line < "$question_cache_file"
  if [[ "${cached_question_line%%$'\x1f'*}" == "$question_stamp" ]]; then
    question_row="${cached_question_line#*$'\x1f'}"
  else
    question_row=$(
      tail -r "$transcript_path" 2>/dev/null \
        | awk '/"promptSource":/ { exit }
               /"type":"assistant"/ && /"usage"/ && !/"isSidechain":true/' \
        | jq -rs --argjson prices "$model_prices" '
          # 950 -> "950", 4130 -> "4.1k", 12400 -> "12k", 1.2e6 -> "1.2M"
          def short_count:
            if . >= 1e6 then "\(. / 1e5 | round / 10)M"
            elif . >= 1e4 then "\(. / 1e3 | round)k"
            elif . >= 1e3 then "\(. / 1e2 | round / 10)k"
            else tostring end;
          # $/MTok without the "$" (the "=$…" cost after it carries it):
          # 0.2 -> "0.2", 7.8125 -> "7.8", 20 -> "20"
          def short_price: "\(if . >= 1 then (. * 10 | round / 10) else (. * 100 | round / 100) end)";
          # Dollar amounts: cents, but a tenth of a cent below $0.10 so small
          # parts do not all read "$0": 0.0063 -> "$0.006", 0.84 -> "$0.84"
          def short_cost: "$\(if . >= 0.1 then (. * 100 | round / 100) else (. * 1000 | round / 1000) end)";
          [ .[] | select(.message.model != "<synthetic>") ]
          | group_by(.message.id) | map(last.message.usage)
          | if length == 0 then "" else
              (map(.input_tokens // 0) | add) as $uncached_input
              | (map(.cache_creation_input_tokens // 0) | add) as $cache_write
              | (map([.cache_creation.ephemeral_1h_input_tokens // 0, .cache_creation_input_tokens // 0] | min) | add) as $cache_write_1h
              | (map(.cache_read_input_tokens // 0) | add) as $cache_read
              | (map(.output_tokens // 0) | add) as $output
              | ($uncached_input + $cache_write) as $new_input
              | if $prices == null then
                  "Q: 📥\($new_input | short_count) | 🔁\($cache_read | short_count) | 📤\($output | short_count)"
                else
                  ($uncached_input * $prices[0] + ($cache_write - $cache_write_1h) * $prices[2]
                    + $cache_write_1h * $prices[3]) as $new_input_cost_micro_dollars
                  | ($new_input_cost_micro_dollars / 1e6) as $new_input_cost
                  | ($cache_read * $prices[4] / 1e6) as $cache_read_cost
                  | ($output * $prices[1] / 1e6) as $output_cost
                  | (if $new_input > 0 then $new_input_cost_micro_dollars / $new_input else $prices[0] end) as $new_input_rate
                  | "Q: 📥\($new_input | short_count)·\($new_input_rate | short_price)=\($new_input_cost | short_cost)"
                    + " | 🔁\($cache_read | short_count)·\($prices[4] | short_price)=\($cache_read_cost | short_cost)"
                    + " | 📤\($output | short_count)·\($prices[1] | short_price)=\($output_cost | short_cost)"
                    + " | Σ\($new_input_cost + $cache_read_cost + $output_cost | short_cost)"
                end
            end' 2>/dev/null
    )
    printf '%s\x1f%s\n' "$question_stamp" "$question_row" > "$question_cache_file"
  fi
fi

echo "$usage_row"
[[ -n "$editing_row" ]] && echo "$editing_row"
[[ -n "$question_row" ]] && echo "$question_row"
