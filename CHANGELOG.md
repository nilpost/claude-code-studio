# Changelog

Every entry here corresponds to a plugin `version` bump — see
[`CONTRIBUTING.md`](CONTRIBUTING.md#versioning--release) for the bump criteria
(PATCH/MINOR/MAJOR) and why a bump is required, not optional.

Entries are grouped by date, newest first. Each names the plugin and its new version.

## 2026-07-28

### cloudflare-mcp 0.2.0

- **Changed**: now depends on Cloudflare's own official plugin
  (`cloudflare@cloudflare`, from their `cloudflare/skills` marketplace) instead of
  declaring MCP servers in a local `.mcp.json`. Enabling `cloudflare-mcp` now pulls in
  Cloudflare's real, actively maintained servers (5, vs. the 2 this plugin used to
  hand-copy) automatically. Requires `claude plugin marketplace add cloudflare/skills`
  once per machine/environment — see `plugins/cloudflare-mcp/README.md`.
- Introduces this repo's first cross-marketplace plugin dependency, allowed via
  `allowCrossMarketplaceDependenciesOn` in `.claude-plugin/marketplace.json`.

## 2026-07-15

### studio-core 0.1.0 — initial release

- `po` orchestrator plus 8 specialist agents: `feature-planning`, `code-review`,
  `security`, `qa`, `backlog`, `devops`, `infra-admin`, `docs`.
- Incremental-learning loop: `capture-learnings` (`/learn`), `improve-agent`
  (`/improve-agent`), `create-agent` (`/create-agent`).
- `recall-learnings` skill; shared `knowledge/LEARNINGS.md`.

### cloudflare-mcp 0.1.0 — initial release

- Cloudflare remote MCP servers (docs + Workers bindings) via a hand-copied
  `.mcp.json`. Superseded by the dependency-based 0.2.0 above.

<!--
  studio-core 0.2.0 (a version-discipline catch-up bump, unrelated in content to the
  cloudflare-mcp change above) is on a separate, independent PR (#16) that also
  created this file from scratch. Whichever of that PR and this one merges second
  will hit a trivial merge conflict on this file — resolve by keeping both sides'
  entries, then delete this comment. Do not resolve by dropping either plugin's entry.
-->
