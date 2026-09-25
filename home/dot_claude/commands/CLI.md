---
description: Show the `claude --resume` command for this session and copy it to the clipboard
---

cwd = "Primary working directory" from your environment context (already
known — no tool call to look it up). Do NOT use any app-level session id
(e.g. `local_afc63fd1-...`) as the `--resume` UUID; it's the desktop app's own
id, not the CLI transcript's, and fails with "No conversation found".

Run this ONE Bash call, no other tool calls, no preamble reasoning
(`<cwd-enc>` = cwd with `/` and `.` replaced by `-`, e.g. `/Users/ian/.chezmoi`
→ `-Users-ian--chezmoi`):

```
uuid=$(ls -t ~/.claude/projects/<cwd-enc>/*.jsonl | head -1 | xargs basename -s .jsonl); cmd="cd <cwd> && claude --resume $uuid"; printf '%s' "$cmd" | pbcopy; printf '%s\n' "$cmd"
```

Then reply with only: the printed command in a `bash`-tagged code block, and
"Copied to clipboard." Nothing else.
