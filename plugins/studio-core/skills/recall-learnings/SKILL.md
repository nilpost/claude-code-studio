---
name: recall-learnings
description: Surface relevant past lessons from the studio knowledge base before starting work. Use at the start of a task or when entering a project/area, to check whether prior sessions already recorded a correction, gotcha, or convention that applies. This is how accumulated learnings actually influence current behavior.
allowed-tools: Read, Grep, Bash(git *)
---

# recall-learnings

This is the **read-at-start** half of the studio's incremental-learning loop. Its
job is to pull *relevant* prior lessons into the current task without dumping the
entire knowledge base into context.

## Where the knowledge base lives

Resolve the first that exists:

1. `knowledge/LEARNINGS.md` walking up from the current working directory.
2. `$STUDIO_LEARNINGS_FILE` if set.
3. `${CLAUDE_PLUGIN_ROOT}/../../knowledge/LEARNINGS.md` (the copy distributed with
   the plugin).

If none exists, say so and continue — recall is best-effort, never a blocker.

## Steps

1. Build a short list of terms describing the current task: the repo/project
   name, files or paths you are about to touch, tool names, key domain words, and
   any error text.
2. Grep the knowledge file for those terms, matching especially against each
   entry's **Trigger** line.
3. For each hit, summarize the **Lesson** in one line and state how it applies
   here. Prefer 3–5 of the most relevant lessons over an exhaustive list.
4. Apply them as you proceed. If a lesson turns out to be wrong or stale, note it
   — that itself is a new lesson for `capture-learnings`.

Keep this fast and quiet: a couple of applicable lessons stated up front, not a
recital of the whole file.
