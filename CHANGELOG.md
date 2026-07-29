# Changelog

Every entry here corresponds to a plugin `version` bump — see
[`CONTRIBUTING.md`](CONTRIBUTING.md#versioning--release) for the bump criteria
(PATCH/MINOR/MAJOR) and why a bump is required, not optional. CI enforces that a PR
changing `plugins/<name>/` includes a matching entry here (see
[`.github/scripts/check-plugin-versions.sh`](.github/scripts/check-plugin-versions.sh)).

Entries are grouped by date, newest first. Each names the plugin and its new version.

## 2026-07-29

### studio-core 0.4.0

- **Added**: a new `cloud-provisioner` agent (via `create-agent`), proposed in the
  `Invoice_Generator` studio-learning handoff. Fills a genuine gap: `infra-admin` and
  `devops` are explicitly read-only advisors that never touch credentials or modify
  production, but the handoff session had live browser access and provisioned real
  infrastructure (Workers, a custom domain, a KV namespace, secrets, a GCP project, an
  OAuth client) by driving dashboards directly — no existing agent covered *doing*
  that. Encodes the runbook from the handoff: plan before provisioning, prefer
  CLI/API/CI over the dashboard, click by ref not coordinate, strict secret-handling
  rules (never transcribe by eye, never print a live credential, roll anything shown
  once and not copied), confirm before irreversible actions, and verify by hitting the
  real endpoint rather than trusting a dashboard success toast. Registered with `po`.
  MINOR bump: new agent.

### studio-core 0.3.0

- **Changed**: the `SessionStart` hook (background `claude plugin marketplace update`,
  refreshes a local install so the *next* session is current) now ships **enabled by
  default** in `hooks.json`, instead of living opt-in in `hooks.example.json`. It only
  ever reads — no writes, same as before. `hooks.example.json` now documents just the
  remaining opt-in extra (`SessionEnd`, a nudge to run `/learn`). MINOR bump: this
  changes default runtime behavior for every consumer, not a wording tweak.
- Docs updated to match everywhere the old "hooks ship empty" claim appeared:
  `README.md`, `docs/architecture.md`, `docs/updating.md`, `docs/deploy-org-wide.md`
  (including a corrected note on what the server-managed-settings security-approval
  dialog does — the previous claim that enabling the plugin "should not trigger" it no
  longer holds now that a hook ships by default).

## 2026-07-28 (3)

### studio-core 0.2.2

- **Added**: a `po` (Product Owner orchestrator) Lessons-learned bullet: when acting
  as an independent reviewer and an explicitly-requested verification step cannot
  actually be performed (a required tool/MCP server unavailable in context), state
  that as an explicit gap in the final verdict itself rather than folding a partial
  check into an overall "GO".

## 2026-07-28 (2)

### studio-core 0.2.1

- **Fixed**: `/learn`, `/improve-agent`, and `/create-agent` gave no visible
  indication of what they were doing when invoked — no narration before the work
  started. Each command now opens with an explicit instruction to state in one
  sentence what it's about to do before proceeding.

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
  `.mcp.json`. Superseded by the dependency-based 0.2.0 above.
