---
name: create-agent
description: Scaffold a NEW specialist agent for the studio when a recurring capability gap is found that no existing agent covers. Use when a type of task keeps coming up and none of the current agents (po, backlog, code-review, qa, devops, feature-planning, infra-admin, docs, security) is the right fit. Creates the agent file and opens a draft PR for review — it never lands on main unreviewed.
allowed-tools: Read, Write, Edit, Bash(git *), Bash(*/scaffold_agent.sh *)
---

# create-agent

Fills a real, recurring capability gap by scaffolding a new studio agent. Autonomy
with a guardrail: the agent is created on a branch and surfaced as a **draft PR**,
never merged to `main` automatically.

## Gate before creating (do not skip)

Only proceed if all hold; otherwise stop and explain why:

1. **Recurring**, not a one-off — the gap has shown up more than once, or is clearly
   going to.
2. **Uncovered** — re-read the descriptions of the existing agents and confirm none
   of them is the right home (extending an existing agent via `improve-agent` is
   preferred when it's a near fit).
3. **Broadly useful** — it helps projects beyond the current one. If it's truly
   specific to this one repo, create it in that repo's local `.claude/agents/`
   instead of the shared studio.

## Steps

1. **Define it:** pick a kebab-case `name`, a trigger-rich `description` (when to use
   AND when not to), the minimum `tools`, and a `model` (haiku for mechanical work,
   sonnet for judgment-heavy work — match the tiering the `po` agent uses).
2. **Scaffold:**

   ```
   ${CLAUDE_PLUGIN_ROOT}/skills/create-agent/scripts/scaffold_agent.sh \
     --name "<name>" \
     --description "<when to use / when not to>" \
     --tools "Read, Glob, Grep" \
     --model "claude-sonnet-5"
   ```

   It writes `plugins/studio-core/agents/<name>.md` from a template (with a seeded
   `## Lessons learned` section) and refuses to overwrite an existing agent.
3. **Fill in the body** — replace the `## Instructions` placeholder with the agent's
   real responsibilities, method, and output format.
4. **Register it with `po`** — add a one-line entry under `## Agents available` in
   `plugins/studio-core/agents/po.md` so the orchestrator knows to delegate to it.
5. **Open a draft PR:** create/switch to the studio's working branch, commit
   (`feat(agent): add <name>`), push with `-u origin`, and open a **draft** PR
   against `main`. Do not merge it yourself — leave it for human review.

Prefer improving an existing agent over creating a near-duplicate. A new agent is
warranted only when the responsibility is genuinely distinct.
