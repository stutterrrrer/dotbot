#!/usr/bin/env zsh

# Show which processes currently own Codex thread-writer lock files.
#
# Codex creates one lock file for each thread that may be modified. A lock file
# can remain on disk after its process exits, so merely finding a .lock file
# does not prove that a thread is still active. `lsof` is used below to check
# whether a live process currently has each lock file open.
#
# The session index maps the short identifier embedded in a lock filename to a
# human-readable thread name. `jq` reads that JSONL index one record at a time.

# Directory containing Codex's thread-writer lock files.
codex_thread_lock_directory="$HOME/.codex/thread-writer-locks"

# JSONL file containing Codex session metadata, including thread names.
codex_session_index_file="$HOME/.codex/session_index.jsonl"

# In Zsh, make an unmatched glob expand to no files rather than failing the
# script before the loop begins.
setopt local_options null_glob

# Inspect every lock file currently present in Codex's lock directory.
codex_lock_status_rows=()

# Convert the ISO-8601 UTC timestamp in session_index.jsonl to local time.
# If a record cannot be parsed, preserve the original timestamp.
codex_format_updated_at() {
  local codex_timestamp="$1"
  local codex_timestamp_without_fraction

  if [[ "$codex_timestamp" == <-> ]]; then
    date -r "$codex_timestamp" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null ||
      printf '%s' "$codex_timestamp"
    return
  fi

  codex_timestamp_without_fraction="${codex_timestamp%%.*}"
  codex_timestamp_without_fraction="${codex_timestamp_without_fraction%Z}"

  date -j -f '%Y-%m-%dT%H:%M:%S%z' \
    "${codex_timestamp_without_fraction}+0000" \
    '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null ||
    printf '%s' "$codex_timestamp"
}

for codex_thread_lock_path in "$codex_thread_lock_directory"/*.lock; do
  # Extract the filename, remove its .lock suffix, then keep the identifier
  # prefix before the first dash. The prefix is enough to query the index.
  codex_thread_lock_filename="${codex_thread_lock_path##*/}"
  codex_thread_lock_identifier="${codex_thread_lock_filename%.lock}"
  codex_thread_identifier_prefix="${codex_thread_lock_identifier%%-*}"

  # Find the first matching session record, including its update timestamp.
  codex_thread_record=$(
    jq -r --arg thread_identifier_prefix "$codex_thread_identifier_prefix" \
      'select(.id | startswith($thread_identifier_prefix)) | [.updated_at, .thread_name] | @tsv' \
      "$codex_session_index_file" |
      head -1
  )

  if [ -n "$codex_thread_record" ]; then
    IFS=$'\t' read -r codex_thread_updated_at codex_thread_name <<< "$codex_thread_record"
  else
    codex_thread_name="unknown task ($codex_thread_identifier_prefix)"
    codex_thread_updated_at=$(stat -f '%m' "$codex_thread_lock_path")
  fi

  # Keep the output useful if an index record has no update timestamp.
  [ -z "$codex_thread_updated_at" ] &&
    codex_thread_updated_at=$(stat -f '%m' "$codex_thread_lock_path")

  # `lsof -t` returns the process IDs of processes that currently have this
  # lock file open. An empty result means the file is stale or unowned.
  codex_lock_owner_process_ids=$(
    lsof -t -- "$codex_thread_lock_path" 2>/dev/null |
      tr '\n' ' '
  )

  if [ -z "$codex_lock_owner_process_ids" ]; then
    codex_lock_status_rows+=(
      "$codex_thread_updated_at"$'\t'"UNOWNED"$'\t'"$codex_thread_name"$'\t'"-"$'\t'"-"
    )
    continue
  fi

  # A lock can be open by more than one process, so classify and print each
  # process separately.
  for codex_lock_owner_process_id in $codex_lock_owner_process_ids; do
    codex_lock_owner_command=$(
      ps -p "$codex_lock_owner_process_id" -o command=
    )

    case "$codex_lock_owner_command" in
      *ChatGPT.app*)
        codex_lock_owner_type="GUI"
        ;;
      *JetBrains*|*codex-acp*|*app-server*)
        codex_lock_owner_type="IntelliJ/CLI"
        ;;
      *)
        codex_lock_owner_type="CLI/other"
        ;;
    esac

    codex_lock_status_rows+=(
      "$codex_thread_updated_at"$'\t'"LOCKED"$'\t'"$codex_thread_name"$'\t'"$codex_lock_owner_type"$'\t'"$codex_lock_owner_process_id"
    )
  done
done

printf 'LAST CHANGE           STATE    TASK                                     OWNER        PID\n'
printf '%s\n' "${codex_lock_status_rows[@]}" |
  sort -r -t $'\t' -k1,1 |
  while IFS=$'\t' read -r \
    codex_sorted_updated_at \
    codex_sorted_state \
    codex_sorted_thread_name \
    codex_sorted_owner \
    codex_sorted_pid; do
    printf '%-21s %-8s %-40s %-12s %s\n' \
      "$(codex_format_updated_at "$codex_sorted_updated_at")" \
      "$codex_sorted_state" \
      "$codex_sorted_thread_name" \
      "$codex_sorted_owner" \
      "$codex_sorted_pid"
  done
