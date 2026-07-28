# Contributing

Thanks for improving `claude-code-studio`. This repo is a Claude Code plugin
marketplace, so "contributing" mostly means adding or refining **agents**, **skills**,
and **commands** under `plugins/studio-core/`, then validating and opening a PR.

The catalog also publishes `plugins/cloudflare-mcp/`, an optional add-on. Adding a
plugin means a new directory under `plugins/` with its own `.claude-plugin/plugin.json`,
plus an entry in `.claude-plugin/marketplace.json` whose `name` and `version` match that
manifest.

### Depending on a plugin from another marketplace

`cloudflare-mcp` doesn't declare MCP servers itself — it has a `dependencies` entry in
`plugin.json` pointing at Cloudflare's own official plugin, so enabling it here pulls in
their actual, maintained servers instead of a copy that goes stale. Prefer this pattern
over hand-copying another vendor's config whenever they publish their own plugin.

Two things this requires: the target marketplace name must be listed in this repo's own
`allowCrossMarketplaceDependenciesOn` (`.claude-plugin/marketplace.json`) — Claude Code
refuses cross-marketplace dependencies otherwise — and the consumer must have that
target marketplace added (`claude plugin marketplace add <owner>/<repo>`) for the
dependency to resolve; it is not added automatically. See
[`plugins/cloudflare-mcp/README.md`](plugins/cloudflare-mcp/README.md) for the verified
failure and resolution behavior, and the [plugin-dependencies docs](https://code.claude.com/docs/en/plugin-dependencies)
for the full mechanism.

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

Bump `version` in both `plugins/studio-core/.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json` for a notable change. Because the marketplace source
is the GitHub repo, consumers get updates via `claude plugin marketplace update
claude-code-studio` (local) or a fresh session (cloud) — see
[`docs/updating.md`](docs/updating.md).

## Commit & PR conventions

- Conventional-style commit subjects: `feat(agent): …`, `fix: …`, `docs: …`,
  `learn: …`, `improve(<agent>): …`.
- Open PRs as **draft** first; keep the description focused on what changed and why.
