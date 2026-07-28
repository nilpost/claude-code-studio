---
name: improve-agent
description: Bake a behavioral lesson into a specific studio agent's definition after it makes a mistake or gets corrected, so the corrected behavior travels in that agent's own prompt. Use when a named studio agent (po, code-review, qa, security, devops, backlog, feature-planning, infra-admin, docs) did something wrong or suboptimal and the fix is a durable change to how THAT agent should behave. For general, agent-agnostic lessons, use capture-learnings instead.
allowed-tools: Read, Edit, Bash(git *), Bash(*/append_agent_lesson.sh *), Bash(*/push_to_studio.sh *)
---

# improve-agent

This is the agent-level half of the studio's learning loop: it writes a lesson
**into the offending agent's own definition** so the behavior change is baked into
its prompt everywhere the plugin is installed — not just parked in a notes file the
agent might not read.

## When to use this vs capture-learnings

- **This skill** — the lesson is about *one specific agent's behavior* ("`po`
  should have run the tests before declaring done", "`security` keeps missing
  IDOR checks"). It edits that agent's `.md`.
- **capture-learnings** — the lesson is general and agent-agnostic (a stack gotcha,
  an environment quirk). It goes to the shared `knowledge/LEARNINGS.md`.
- Some lessons deserve **both**: bake the behavioral directive into the agent AND
  record the general fact in the shared KB.

## Steps

1. **Identify the agent.** Which studio agent misbehaved? (Its file is
   `plugins/studio-core/agents/<name>.md`.)
2. **Phrase the lesson as a terse behavioral directive** — imperative, specific,
   and durable. Good: "Before reporting a task done, run the project's test command
   and paste the result." Bad: vague or one-off notes.
3. **Bake it in:**

   ```
   ${CLAUDE_PLUGIN_ROOT}/skills/improve-agent/scripts/append_agent_lesson.sh \
     --agent "<agent-name>" \
     --lesson "<terse behavioral directive>"
   ```

   The script inserts the bullet under that agent's `## Lessons learned` section
   (creating the section if absent), newest first.
4. **If the lesson is also general**, additionally run `capture-learnings` so every
   project benefits.
5. **Review and commit.** Read the edited agent file to confirm the directive is
   accurate and the prompt still reads coherently; keep the section short — prune
   stale or superseded bullets rather than letting it grow unbounded. Then
   `git add` the agent file and commit with a message like
   `improve(<agent>): <summary>`. Distribution happens on the normal push/PR + the
   consumers' next `claude plugin marketplace update`.

Keep edits small and behavioral. The goal is a sharper agent, not a longer one.

## Outside the studio checkout (another project, or a cloud session)

The steps above assume you're inside a checkout of the `claude-code-studio` repo. When
the plugin is installed but the repo isn't checked out — the agent files live in the
read-only plugin cache (`${CLAUDE_PLUGIN_ROOT}/agents/`), and editing those is pointless
(overwritten on the next update, never pushed). Route the fix to the repo over GitHub
instead:

```
${CLAUDE_PLUGIN_ROOT}/scripts/push_to_studio.sh agent-lesson \
  --agent "<agent-name>" --lesson "<terse behavioral directive>"
```

It clones the public studio repo, appends the lesson under that agent's
`## Lessons learned` section, pushes a branch, and opens a draft PR. Add `--dry-run` to
preview. If the push fails for lack of write access here, it preserves the prepared
commit and tells you where.
