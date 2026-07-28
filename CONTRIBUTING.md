# Contributing

Thanks for improving `claude-code-studio`. This repo is a Claude Code plugin
marketplace, so "contributing" mostly means adding or refining **agents**, **skills**,
and **commands** under `plugins/studio-core/`, then validating and opening a PR.

The catalog also publishes `plugins/cloudflare-mcp/`, an optional add-on that carries
only MCP server declarations. Adding a plugin means a new directory under `plugins/`
with its own `.claude-plugin/plugin.json`, plus an entry in `.claude-plugin/marketplace.json`
whose `name` and `version` match that manifest.

## Ground rules

- **No secrets, no PII, no confidential detail.** This is a public marketplace. Agents,
  skills, and `knowledge/LEARNINGS.md` must contain only generic, shareable content —
  never credentials, internal hostnames, private URLs, or lessons attributable to a
  named private project. Generalize before you commit.
- **Small, reviewable changes.** One concern per PR.
- **Everything ships through a PR** — including agent self-improvements and new agents.

## Add or change an agent

Agents live in `plugins/studio-core/agents/<name>.md` as Markdown with YAML frontmatter:

```yaml
---
name: my-agent
description: When Claude should delegate to this agent (be specific — this is what it matches on).
model: claude-sonnet-5      # or a haiku-tier id for mechanical work
tools: [Read, Glob, Grep]
---

You are `my-agent` …
```

If it's a specialist `po` should delegate to, add a line under `## Agents available` in
`agents/po.md`. Prefer the `create-agent` skill to scaffold a new one — it seeds the
right structure and opens a draft PR.

## Add or change a skill

Skills live in `plugins/studio-core/skills/<name>/SKILL.md`:

```yaml
---
name: my-skill
description: When to invoke this skill (trigger-rich; this drives auto-invocation).
allowed-tools: Read, Edit, Bash(git *)
---

# my-skill
Instructions Claude should follow …
```

Put helper scripts in a `scripts/` subdirectory and reference them with
`${CLAUDE_PLUGIN_ROOT}`.

## Validate before you push

```bash
claude plugin validate ./plugins/studio-core --strict
claude plugin validate ./plugins/cloudflare-mcp --strict   # if you touched it
```

If you touched a helper script, exercise it on a throwaway target (see the existing
scripts' tests in commit history for examples). For a quick end-to-end check, add the
marketplace locally and confirm the plugin loads:

```bash
claude plugin marketplace add ./
claude plugin install studio-core@claude-code-studio --scope user
claude plugin list
```

## Versioning & release

**Required, not optional:** any PR that changes files under `plugins/<name>/` must bump
that plugin's `version` in both `plugins/<name>/.claude-plugin/plugin.json` and its
entry in `.claude-plugin/marketplace.json` (the two must always match). This is enforced
by CI — see [`.github/workflows/plugin-version-check.yml`](.github/workflows/plugin-version-check.yml).

Why it's mandatory: `version` is Claude Code's update cache key. If it's unchanged,
`claude plugin update` fetches nothing new, no matter how many commits landed — an
un-bumped change is invisible to every already-installed consumer, silently. New
plugins and changes outside `plugins/` (docs, `scripts/`, CI) don't need a bump; they
aren't part of what installs.

Follow [semver](https://semver.org):

- **PATCH** — wording/prompt tweaks inside an existing agent or skill, a lesson baked
  in via `improve-agent`, a bug fix
- **MINOR** — a new agent, skill, or command; a new plugin
- **MAJOR** — a rename or removal that breaks an existing `@agent` or `/command`
  reference

Because the marketplace source is the GitHub repo, consumers get the update via
`claude plugin marketplace update claude-code-studio` (local) or a fresh session
(cloud) — see [`docs/updating.md`](docs/updating.md).

## Commit & PR conventions

- Conventional-style commit subjects: `feat(agent): …`, `fix: …`, `docs: …`,
  `learn: …`, `improve(<agent>): …`.
- Open PRs as **draft** first; keep the description focused on what changed and why.
