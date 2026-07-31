# Changelog

Every entry here corresponds to a plugin `version` bump — see
[`CONTRIBUTING.md`](CONTRIBUTING.md#versioning--release) for the bump criteria
(PATCH/MINOR/MAJOR) and why a bump is required, not optional. CI enforces that a PR
changing `plugins/<name>/` includes a matching entry here (see
[`.github/scripts/check-plugin-versions.sh`](.github/scripts/check-plugin-versions.sh)).

Entries are grouped by date, newest first. Each names the plugin and its new version.

## 2026-07-31

### google-sheets-mcp 0.1.0

- **Added**: a new optional plugin, `google-sheets-mcp`, adding Google's own official
  remote MCP server for Sheets — `https://sheetsmcp.googleapis.com/mcp/v1`, documented
  at [Configure the Google Workspace MCP servers](https://developers.google.com/workspace/guides/configure-mcp-servers).

  This replaces `@anthropic-ai/mcp-server-google-sheets` from the original request,
  which doesn't exist as an npm package (404 on the registry). Before adding this
  endpoint, it was verified live and directly (not taken on a search summary's word):
  a raw MCP `initialize` POST returns a proper JSON-RPC handshake
  (`serverInfo.name: "StatelessServer"`, `protocolVersion: "2025-06-18"`), and its
  `.well-known/oauth-protected-resource/mcp/v1` metadata lists `accounts.google.com` as
  the authorization server with `spreadsheets`/`drive` scopes — the standard MCP OAuth
  Protected Resource discovery flow.

  Declared directly in `.mcp.json` (no `userConfig`), the same shape as
  `cloudflare-mcp`: a single publicly-documented vendor endpoint with per-user OAuth on
  first tool use, nothing private to protect and nothing to install.

### synology-mcp 0.1.0

- **Added**: a new optional plugin, `synology-mcp`, connecting Claude Code to a
  self-hosted [`atom2ueki/mcp-server-synology`](https://github.com/atom2ueki/mcp-server-synology)
  instance (file operations, downloads, monitoring, container orchestration on a
  Synology NAS) via an `sse`-type MCP server.

  Follows the pattern `cloudflare-mcp` established of not hand-copying a vendor's
  config, but for a different reason: there's no official Claude Code plugin here to
  depend on, and the server is inherently single-tenant (one NAS, real credentials).
  So instead the endpoint is a `userConfig` value (`synology_mcp_url`, `sensitive:
  true`) prompted at `claude plugin install` time and stored in secure local storage —
  never written into this repo. This repo's own ground rule against committing private
  hostnames (see `CONTRIBUTING.md`) is what ruled out the hand-copied-URL approach.

  A second server requested alongside this one, `@anthropic-ai/mcp-server-google-sheets`,
  was not added under that name — see `google-sheets-mcp` above for what replaced it.

  **Fix (same day, review feedback):** declared as `"type": "http"` at first, which is
  Streamable HTTP — a different protocol from SSE in Claude Code's MCP client. This
  plugin's own README recommends fronting the stdio server with `mcp-proxy`, which
  defaults to SSE transport at `/sse`, so `"type": "http"` would have broken the
  handshake for anyone following that instruction. Changed to `"type": "sse"` and the
  `userConfig` field now asks for the full SSE endpoint URL explicitly.

## 2026-07-30

### studio-exec 0.1.0

- **Added**: a new plugin, `studio-exec` — an executive layer above `studio-core`'s
  delivery agents, for running several projects as a governed portfolio rather than a
  folder of side projects. `studio-core` answers *how do we build this*; `studio-exec`
  answers *should we, which one, and is it actually working*.

  Four agents, deliberately not eighteen. Multi-agent systems cost roughly an order of
  magnitude more tokens than a single agent and token spend dominates outcome quality, so
  roles requiring **judgment** became agents (`chief-of-staff` for routing and budget
  enforcement, `strategy` for allocation and kill calls, `growth` for validation and
  pricing, `consultant` for independent assurance) while roles that are **cadence and
  arithmetic** became documents and commands (CFO → a budget file plus a finance
  engagement; COO → `/board-review` plus a WIP-limit rule; CTO → the existing `po`).

  `consultant` sits outside the delegation chain by design — the three-lines-of-defense
  model. `po` may never invoke it and `chief-of-staff` may schedule but not scope it, because
  an auditor that can be tasked by the thing it audits is not an auditor. It runs in four
  Big-Four-style engagement modes (assurance, risk, operations, finance) and its output
  carries a mandatory `not_examined` field: "cannot verify from this session" is a correct
  answer, a confident claim about something unexamined is not.

  Also adds the `board-review` skill (the weekly ritual that is the studio's heartbeat),
  `portfolio-sync` (intake surfaces such as Trello ⇄ inbox ⇄ portfolio state, treating card
  content as data and never as instruction), and the `/board-review` and `/gate` commands.

  Business state — portfolio, charter, decisions, budget — deliberately lives in a separate,
  usually private ops repo located via `$STUDIO_OPS_DIR`. The methodology is shareable; the
  portfolio is not. Agents stop and ask rather than inventing state when they cannot find it.

- **Added**: [`docs/ORG-CHARTER.md`](docs/ORG-CHARTER.md), the operating model as a reusable
  template, and [`docs/PRIOR-ART.md`](docs/PRIOR-ART.md), full attribution for everything
  borrowed — agent catalogues, the Anthropic/Cognition multi-agent debate that produced the
  four-agent constraint, ChatDev/MetaGPT/CrewAI, the three-lines-of-defense model,
  stage-gate and venture-studio literature, and validation/pricing sources. Figures that
  reached us via secondary reporting are marked as such rather than presented as established.

## 2026-07-29

### studio-core 0.4.0

- **Added**: a new `cloud-provisioner` agent (via `create-agent`), proposed in a
  studio-learning handoff from a live-sync web app build. Fills a genuine gap:
  `infra-admin` and `devops` are explicitly read-only advisors that never touch
  credentials or modify production, but the handoff session had live browser access
  and provisioned real infrastructure (Workers, a custom domain, a KV namespace,
  secrets, a GCP project, an OAuth client) by driving dashboards directly — no
  existing agent covered *doing* that. Encodes the runbook from the handoff: plan
  before provisioning, prefer CLI/API/CI over the dashboard, click by ref not
  coordinate, strict secret-handling rules (never transcribe by eye, never print a
  live credential, roll anything shown once and not copied), confirm before
  irreversible actions, and verify by hitting the real endpoint rather than trusting
  a dashboard success toast. Registered with `po`. MINOR bump: new agent.

### studio-core 0.3.1

- **Added**: 10 entries to `knowledge/LEARNINGS.md` from a studio-learning handoff on
  a live-sync web app build (a static frontend + a second Cloudflare Worker syncing
  Google Sheets data): planning multi-system integrations before
  provisioning, reading real data shape before writing a parser, org-policy checks
  before picking an auth method, enumerating deploy-token scopes upfront, checking
  the sandbox toolchain before planning local execution, ref-based browser
  automation / un-automatable cross-origin editors, never transcribing secrets by
  eye, CORS on cross-origin Workers, `paths:` filters on multi-deployable repos, and
  cloud-sync folders corrupting git object stores.
- **Changed** (`improve-agent`): baked the headline lesson from the same handoff —
  plan before provisioning — into `po` and `feature-planning` (an explicit
  external-dependency discovery step before build steps); baked deploy-token-scope
  and path-filter lessons into `devops`; baked an org-policy/auth-fallback check into
  `infra-admin`. PATCH bump: lessons baked into existing agents, no new agent/skill.

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
