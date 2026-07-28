---
name: capture-learnings
description: Capture lessons from the current session into the studio's durable, cross-project knowledge base. Use at the end of a task, after the user corrects you, or when you notice a repeated mistake or inefficiency — anything worth remembering next time. Also runs via the /learn command.
allowed-tools: Read, Edit, Bash(git *), Bash(*/append_learning.sh *), Bash(*/push_to_studio.sh *)
---

# capture-learnings

This is the **write-back** half of the studio's incremental-learning loop. It
distills what was learned in this session into structured entries in the studio
knowledge base (`knowledge/LEARNINGS.md`), so the lesson survives beyond this
session and propagates to every environment.

## When to capture

Look back over the recent conversation for signals worth remembering:

- **Corrections** — the user said "use X instead of Y", "don't do Z", "actually…".
  These are the highest-value lessons.
- **Repeated mistakes or dead ends** — something you had to redo, a wrong
  assumption, a tool call that wasn't needed.
- **Non-obvious project facts** — a build quirk, a convention, a gotcha that cost
  time to discover.
- **Explicit approvals** — "yes, perfect" confirming a good pattern worth
  reusing.

If nothing meets that bar, say so and stop — do not invent filler entries.

## How to write a good entry

Keep each entry to a single lesson. Make it actionable and specific:

- **Context** — the task/area it came from.
- **Lesson** — what to do (or avoid) next time, phrased as guidance.
- **Trigger** — concrete keywords or path globs that should surface this lesson
  later. These are what `recall-learnings` matches on, so choose words that will
  actually recur (file names, tool names, error strings, domain terms).

## Steps

1. Identify 1–N distinct lessons from the session using the criteria above.
2. For each, run the helper script (it inserts the entry newest-first and finds
   the knowledge file automatically):

   ```
   ${CLAUDE_PLUGIN_ROOT}/skills/capture-learnings/scripts/append_learning.sh \
     --project "<repo or project name>" \
     --title   "<short title>" \
     --context "<what task/area>" \
     --lesson  "<what to do or avoid next time>" \
     --trigger "<comma-separated keywords/globs>"
   ```

   To target a specific knowledge file, pass `--file <path>` or set
   `STUDIO_LEARNINGS_FILE`.

3. Show the user the entries you added and confirm they are accurate.
4. Persist them: from the studio repo, commit the change
   (`git add knowledge/LEARNINGS.md && git commit -m "learn: <summary>"`). To push
   and distribute in one step, use `scripts/sync-learnings.sh`. If the studio repo
   is not the current working tree, tell the user which file was updated so they
   can sync it.

Lessons only compound once committed and pushed — an uncommitted entry helps this
session but no other.

## Outside the studio checkout (another project, or a cloud session)

Steps 2 and 4 above assume you are working *inside* a checkout of the
`claude-code-studio` repo (so `knowledge/LEARNINGS.md` exists and you can commit and
push it). When the plugin is installed but the repo is **not** checked out — i.e. no
`knowledge/LEARNINGS.md` is found walking up from the current directory — do not try to
write a local file. Instead route the entry to the repo over GitHub:

```
${CLAUDE_PLUGIN_ROOT}/scripts/push_to_studio.sh learning \
  --project "<project>" --title "<short title>" \
  --context "<what task/area>" --lesson "<what to do next time>" \
  --trigger "<keywords>"
```

It clones the public studio repo to a temp dir, appends the entry (newest-first),
pushes a branch, and opens a draft PR (via `gh` if present, otherwise it prints the
compare URL for you to open). Add `--dry-run` to preview without pushing. If the push
fails for lack of write access in this environment, it keeps the prepared commit and
tells you where, so nothing is lost.
