#!/bin/bash
# Claude Code CLI status line, two rows (each echo is one row):
#   1: model · effort (· fast) | 5-hour % ↻reset, weekly % ↻reset
#      (no "5h"/"wk" labels: the reset time format tells them apart —
#       time only = 5-hour window, weekday + time = weekly window)
#   2: 🐍 conda env | branch ●changed ↑ahead ↓behind | +added −removed | ctx % |
#      ⏱ session duration | IDE ✓/✗        (row 2 = this session's own state)
# The session title is already shown above the prompt, and the vim mode by
# Claude Code's own instant "-- INSERT --" indicator, so neither is repeated.
# Claude Code passes session data as JSON on stdin (see
# https://code.claude.com/docs/en/statusline); whatever we print is shown.

# Speed matters: this re-runs on every vim mode change, and each extra process
# (jq, date, git, ps…) costs ~7 ms on this Mac. So ONE jq call extracts every
# field, formats the reset times, and returns the current time. Fields are
# joined by the ASCII unit separator so empty values survive `read`.
IFS=$'\x1f' read -r model_name current_dir context_percent effort_level \
  fast_mode_enabled lines_added lines_removed session_minutes \
  five_hour_percent five_hour_reset weekly_percent weekly_reset current_epoch < <(
  jq -r '[
      .model.display_name // "?",
      .workspace.current_dir // .cwd // "",
      (.context_window.used_percentage // 0 | floor),
      .effort.level // "",                      # low … max
      .fast_mode // false,
      .cost.total_lines_added // 0,
      .cost.total_lines_removed // 0,
      (.cost.total_duration_ms // 0 | . / 60000 | floor),
      (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
      (.rate_limits.five_hour.resets_at // "" | if . == "" then . else strflocaltime("%H:%M") end),
      (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor end),
      (.rate_limits.seven_day.resets_at // "" | if . == "" then . else strflocaltime("%a %H:%M") end),
      (now | floor)
    ] | map(tostring) | join("\u001f")')   # reads the session JSON from our stdin

# Git branch without launching git: find the nearest .git/HEAD and read it.
# Falls back to `git` for worktrees/submodules, where .git is a file.
git_branch=""
search_dir="$current_dir"
while [[ -n "$search_dir" && "$search_dir" != "/" ]]; do
  if [[ -f "$search_dir/.git/HEAD" ]]; then
    read -r head_ref < "$search_dir/.git/HEAD"
    if [[ "$head_ref" == "ref: refs/heads/"* ]]; then
      git_branch="${head_ref#ref: refs/heads/}"
    else
      git_branch="${head_ref:0:7}"   # detached HEAD: short commit hash
    fi
    break
  elif [[ -f "$search_dir/.git" ]]; then
    git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
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
    (( changed_file_count > 0 )) && git_state+=" ●$changed_file_count"
    (( commits_ahead > 0 )) && git_state+=" ↑$commits_ahead"
    (( commits_behind > 0 )) && git_state+=" ↓$commits_behind"
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
    ide_status="IDE ✗"
    claude_pid=$(find_claude_pid)
    if [[ -n "$claude_pid" ]]; then
      established_ports=$(lsof -a -p "$claude_pid" -iTCP -sTCP:ESTABLISHED -nP 2>/dev/null \
        | awk 'NR>1 {split($9, ends, "->"); n=split(ends[2], hostport, ":"); print hostport[n]}')
      for lock_file in "${ide_lock_files[@]}"; do
        ide_port="${lock_file##*/}"; ide_port="${ide_port%.lock}"
        if grep -qx "$ide_port" <<<"$established_ports"; then
          ide_status="IDE ✓"   # the lock file's ideName says which IDE (IntelliJ IDEA)
          break
        fi
      done
    fi
    printf '%s %s' "$current_epoch" "$ide_status" > "$ide_cache_file"
  fi
fi

# --- Subscription usage (claude.ai Pro/Max; absent until the first reply) ---
# jq already formatted the reset times ("00:40", "Thu 02:13").
five_hour_usage=""
[[ -n "$five_hour_percent" ]] && five_hour_usage="${five_hour_percent}%${five_hour_reset:+ ↻$five_hour_reset}"
weekly_usage=""
[[ -n "$weekly_percent" ]] && weekly_usage="${weekly_percent}%${weekly_reset:+ ↻$weekly_reset}"

# Session duration: "42m", "1h12m".
if (( session_minutes >= 60 )); then
  session_duration="$(( session_minutes / 60 ))h$(( session_minutes % 60 ))m"
else
  session_duration="${session_minutes}m"
fi

# Row 2: conda env | branch + dirty state | lines changed | ctx | duration | IDE.
# Empty parts are skipped. CONDA_DEFAULT_ENV is inherited from the shell that
# started claude, so it shows the env that session's commands run in.
row_parts=()
[[ -n "$CONDA_DEFAULT_ENV" ]] && row_parts+=("🐍 $CONDA_DEFAULT_ENV")
[[ -n "$git_branch" ]] && row_parts+=("${git_branch}${git_state}")
(( lines_added + lines_removed > 0 )) && row_parts+=("+${lines_added} −${lines_removed}")
row_parts+=("ctx ${context_percent}%")
row_parts+=("⏱ $session_duration")
[[ -n "$ide_status" ]] && row_parts+=("$ide_status")
editing_row=""
for row_part in "${row_parts[@]}"; do
  [[ -n "$editing_row" ]] && editing_row+=" | "
  editing_row+="$row_part"
done

# Row 1: model · effort, then the two quota windows joined by a comma
# ("53% ↻00:40, 8% ↻Thu 02:13").
model_text="$model_name"
[[ -n "$effort_level" ]] && model_text+=" · $effort_level"
[[ "$fast_mode_enabled" == "true" ]] && model_text+=" · fast"

quota_text="$five_hour_usage"
[[ -n "$quota_text" && -n "$weekly_usage" ]] && quota_text+=", "
quota_text+="$weekly_usage"

usage_row="$model_text"
[[ -n "$quota_text" ]] && usage_row+=" | $quota_text"

echo "$usage_row"
[[ -n "$editing_row" ]] && echo "$editing_row"
