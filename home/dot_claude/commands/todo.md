---
description: Append an unchecked task to Ian's todo file
argument-hint: <short instruction, e.g. "verify the last task">
---

`$ARGUMENTS` is a short instruction, not literal task text to paste verbatim.
Interpret it against this conversation and write the task out in your own
words. For example, "verify the last task" means: look at what you and Ian
just did (or discussed) in this conversation and write a short, self-contained
description of what needs verifying — one line, specific enough to act on
without re-reading the whole conversation (name the files/commands/behavior
involved), but not a play-by-play. Don't just echo `$ARGUMENTS` as the task
text.

If `$ARGUMENTS` is empty, or there's no clear task to expand on (e.g. a fresh
conversation with nothing relevant yet), ask what the task should be about
instead of guessing.

Append an entry to the end of this file (create it if missing, but it should
already exist):

`/Users/ian/Library/Mobile Documents/com~apple~CloudDocs/1-Programming/claude_todos/claude_todo`

Each entry is two lines plus a trailing blank line to separate it from the
next entry:

```
resume command: `cd <cwd> && claude --resume <uuid>`
- [ ] <expanded task description, one concise line>

```

Get `<cwd>`/`<uuid>` the same way the `CLI` skill does (session transcript
UUID under `~/.claude/projects/<cwd-encoded>/`, not any app-level id; invoke
that skill if unsure how).

If the file doesn't already end with a blank line before this append, add one
first so entries stay visually separated.

After appending, show the exact entry you added. No other output.
