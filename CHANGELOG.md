# Changelog

Every entry here corresponds to a plugin `version` bump — see
[`CONTRIBUTING.md`](CONTRIBUTING.md#versioning--release) for the bump criteria
(PATCH/MINOR/MAJOR) and why a bump is required, not optional. CI enforces that a PR
changing `plugins/<name>/` includes a matching entry here (see
[`.github/scripts/check-plugin-versions.sh`](.github/scripts/check-plugin-versions.sh)).

Entries are grouped by date, newest first. Each names the plugin and its new version.

## 2026-07-28

### studio-core 0.2.0

- **Fixed**: version had never been bumped since the initial release, despite several
  notable additions since (see below) — meaning `claude plugin update` had been
  fetching nothing new for any local install, silently, this whole time. This release
  is the catch-up bump; verified directly by reproducing the stale-cache behavior
  before fixing it.
- Accounts for, retroactively: the incremental-learning loop's `improve-agent` /
  `create-agent` flows, and destructive-git-operations lessons baked into `po`.

### Tooling (no version bump — not part of what installs)

- `scripts/enable-in-repo.sh`: added `--push` (commit + push in one step) and a
  fallback for machines without `python3` (macOS without Xcode Command Line Tools).
- `scripts/update-studio.sh`, `scripts/mirror-local.sh` (new): update an installed
  local copy; symlink the plugin into `~/.claude/skills/` for authors who want their
  working tree loaded directly, no install/update step.
- `.github/workflows/plugin-version-check.yml` (new): the CI enforcement mentioned
  above, plus a check that any `plugins/` version bump includes a matching entry here.

## 2026-07-15

### studio-core 0.1.0 — initial release

- `po` orchestrator plus 8 specialist agents: `feature-planning`, `code-review`,
  `security`, `qa`, `backlog`, `devops`, `infra-admin`, `docs`.
- Incremental-learning loop: `capture-learnings` (`/learn`), `improve-agent`
  (`/improve-agent`), `create-agent` (`/create-agent`).
- `recall-learnings` skill; shared `knowledge/LEARNINGS.md`.

### cloudflare-mcp 0.1.0 — initial release

- Cloudflare remote MCP servers (docs + Workers bindings) via a hand-copied
  `.mcp.json`.

<!--
  cloudflare-mcp 0.2.0 (dependency-based rework, replacing the hand-copied .mcp.json
  above) is on a separate, independent PR (#17) that branched before this file
  existed. Whichever of that PR and this one merges second will hit a trivial merge
  conflict on this file — resolve by keeping both sides' entries, then delete this
  comment. Do not resolve by dropping either plugin's entry.
-->
