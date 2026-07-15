# claude-code-studio

One place to author Claude Code **agents and skills** and use them **everywhere** —
every local project *and* every [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)
(cloud) session — plus an **incremental-learning loop** so those agents and skills
accumulate knowledge across projects instead of starting cold each time.

This repo is itself a **Git-hosted plugin marketplace**. It publishes one plugin,
`studio-core`, that bundles the shared agents, the shared skills, and the learning
loop. Distributing to any environment is then just "add the marketplace, enable the
plugin."

## Why a marketplace instead of `~/.claude`?

In cloud sessions the container is **ephemeral** and the repo is **cloned fresh**;
user-level `~/.claude/agents` and `~/.claude/skills` **do not persist**. So the only
reliable cross-environment channels are (a) files committed into a git repo and
(b) a git-hosted plugin marketplace referenced from a repo's `.claude/settings.json`.
Publishing the assets as a plugin covers both local and cloud with a single source of
truth.

## Layout

```
.claude-plugin/marketplace.json      Marketplace catalog (lists studio-core)
plugins/studio-core/                 The distributable plugin
  .claude-plugin/plugin.json         Plugin manifest
  agents/example-reviewer.md         Sample shared agent (template)
  skills/example-skill/              Sample shared skill (template)
  skills/capture-learnings/          Learning loop: write-back (+ append_learning.sh)
  skills/recall-learnings/           Learning loop: read-at-start
  commands/learn.md                  /learn → runs capture-learnings
  hooks/hooks.json                   Opt-in end-of-session auto-capture (disabled)
knowledge/LEARNINGS.md               Durable, version-controlled cross-project memory
.claude/settings.json                Loads studio-core into THIS repo's own sessions
templates/consumer-settings.snippet.json  Copy/paste block for OTHER repos
scripts/install-local.sh             Local install (marketplace add + install, user scope)
scripts/sync-learnings.sh            Commit + push LEARNINGS.md to distribute lessons
```

## Use it across environments

### Local (all your projects at once)

Install `studio-core` once at **user scope**:

```bash
claude plugin marketplace add nilpost/claude-code-studio
claude plugin install studio-core@claude-code-studio --scope user
# or just:  ./scripts/install-local.sh
```

The shared agents and skills are now available in every local project. Pull
updates later with `claude plugin marketplace update claude-code-studio`.

### Cloud / any other repo (per-repo, committed)

A user-scope install does not survive a fresh cloud container, so instead commit the
marketplace reference into each consuming repo. Merge the two keys from
[`templates/consumer-settings.snippet.json`](templates/consumer-settings.snippet.json)
into that repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-code-studio": { "source": { "source": "github", "repo": "nilpost/claude-code-studio" } }
  },
  "enabledPlugins": { "studio-core@claude-code-studio": true }
}
```

Every fresh cloud session of that repo then auto-fetches and enables the plugin — no
`~/.claude` setup required. (This repo's own `.claude/settings.json` uses a local
`directory` source instead, so you can dogfood uncommitted changes here.)

## Incremental learning

A three-part loop that compounds knowledge across projects, centralized in
[`knowledge/LEARNINGS.md`](knowledge/LEARNINGS.md):

1. **Recall (read-at-start)** — the `recall-learnings` skill greps the knowledge base
   for lessons whose `Trigger` keywords match the current task and applies them.
2. **Capture (write-back)** — the `capture-learnings` skill (or the `/learn` command)
   distills corrections, dead ends, and gotchas from a session into structured
   entries and appends them via `append_learning.sh`.
3. **Distribute** — `scripts/sync-learnings.sh` commits and pushes the knowledge base;
   other environments pick it up on the next `claude plugin marketplace update` (or a
   fresh cloud session). Because the studio ships `LEARNINGS.md` inside the plugin,
   recall works even where the studio repo isn't checked out.

End-of-session auto-capture is available but shipped **disabled** in
`plugins/studio-core/hooks/hooks.json` so nothing writes to your knowledge base
without you asking; enable it by following the comment in that file.

### Add your own agents and skills

Copy `plugins/studio-core/agents/example-reviewer.md` or
`plugins/studio-core/skills/example-skill/` as a template, rewrite the frontmatter
`description` (that's what Claude matches on), push, and run
`claude plugin marketplace update claude-code-studio` everywhere else.

## Prior art

The learning loop follows the "learnings file → feedback → write-back" pattern
popularized by [`haddock-development/claude-reflect-system`](https://github.com/haddock-development/claude-reflect-system).
For large ready-made catalogs to draw from, see
[`wshobson/agents`](https://github.com/wshobson/agents),
[`jeremylongshore/claude-code-plugins-plus-skills`](https://github.com/jeremylongshore/claude-code-plugins-plus-skills),
and [`claude-market/marketplace`](https://github.com/claude-market/marketplace).
Mechanism reference: [plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces),
[plugins](https://code.claude.com/docs/en/plugins),
[skills](https://code.claude.com/docs/en/skills),
[subagents](https://code.claude.com/docs/en/sub-agents).
