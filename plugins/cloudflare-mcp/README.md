# cloudflare-mcp

A thin dependency pointer, not a bundle of MCP server declarations. Its whole job is one
line in [`plugin.json`](.claude-plugin/plugin.json):

```json
"dependencies": [{ "name": "cloudflare", "marketplace": "cloudflare" }]
```

Enabling `cloudflare-mcp@claude-code-studio` auto-installs and auto-enables Cloudflare's
own official plugin, `cloudflare@cloudflare`, from their official marketplace
([`cloudflare/skills`](https://github.com/cloudflare/skills)) — using the same
local/cloud/org mechanism as `studio-core`. That gets you Cloudflare's actual, actively
maintained servers (MCP + Skills) rather than a hand-copied, easily-stale list. Currently
that's `cloudflare` (unified), `cloudflare-docs`, `cloudflare-bindings`,
`cloudflare-builds`, and `cloudflare-observability` — whatever Cloudflare's own manifest
declares is what you get, so this doesn't need to be updated here when they add or
change servers.

## Why a dependency instead of copying their config

Two ways to reference another vendor's MCP servers: copy the URLs into `.mcp.json` here
(what this plugin did until it started depending on Cloudflare's own plugin instead), or
point at their plugin and let Claude Code resolve it. Copying goes stale the moment
Cloudflare adds, removes, or renames a server — depending on their plugin stays current
automatically, with a trust boundary declared explicitly in this repo's own
[`.claude-plugin/marketplace.json`](../../.claude-plugin/marketplace.json)
(`allowCrossMarketplaceDependenciesOn: ["cloudflare"]` — cross-marketplace dependencies
are refused by default; this repo opts in to trusting only that one).

## Prerequisite — one command, one time

Verified directly: enabling `cloudflare-mcp@claude-code-studio` before the `cloudflare`
marketplace is known fails clearly rather than silently:

```
Dependency "cloudflare@cloudflare" is not installed — run `claude plugin install
cloudflare@cloudflare`, or check that its marketplace is added
```

Run this once, on each machine (or in your cloud environment's setup script, alongside
the studio install):

```bash
claude plugin marketplace add cloudflare/skills
```

That single command resolves the outstanding dependency as a side effect — confirmed:
`√ Successfully added marketplace: cloudflare (declared in user settings) (+ 1
dependency: cloudflare)`. No separate `plugin install` step needed afterward.

## Staying current

Cross-marketplace dependencies don't auto-update by default (same caveat that applies to
any non-Anthropic marketplace) — periodically run `claude plugin update` for the
`cloudflare` marketplace, or enable auto-update for it via `/plugin`.

## Auth

Each Cloudflare server OAuths independently on first tool use — no tokens stored in this
repo, same as before.
