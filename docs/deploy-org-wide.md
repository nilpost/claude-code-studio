# Deploy studio-core org-wide (always on, local + cloud)

Goal: make `studio-core` (all its agents, skills, and commands) load automatically
in **every** session for **every** member of the organization — local *and* Claude
Code on the web — with no per-repo `.claude/settings.json` edits.

## Why server-managed settings (not `managed-settings.json`)

Device-level `managed-settings.json` / MDM policies **do not reach cloud sessions** —
those run on Anthropic-managed VMs. The org-wide channel that reaches both local and
cloud is **server-managed settings**, delivered from the admin console and fetched at
session start (and polled hourly). It accepts normal `settings.json` keys, including
`extraKnownMarketplaces` and `enabledPlugins`.

Docs: <https://code.claude.com/docs/en/server-managed-settings>

## Requirements

- Claude for **Teams** or **Enterprise** plan.
- **Owner** or **Primary Owner** role in the Claude organization (Admins can't edit).
- Cloud environments must have network access to GitHub to fetch the marketplace —
  the default **Trusted** network level covers this; **None** would block it.
- Not delivered to sessions using a third-party provider (Bedrock / Vertex / Foundry)
  or a custom `ANTHROPIC_BASE_URL`.

## Steps

1. Open **Admin Settings → Claude Code → Managed settings**:
   <https://claude.ai/admin-settings/claude-code>
2. Add (or merge into the existing) JSON:

   ```json
   {
     "extraKnownMarketplaces": {
       "claude-code-studio": {
         "source": { "source": "github", "repo": "nilpost/claude-code-studio" }
       }
     },
     "enabledPlugins": {
       "studio-core@claude-code-studio": true
     }
   }
   ```

3. Save. Clients apply it on next startup and on the hourly poll.

Every member's sessions — local and cloud, every repo — now auto-install and enable
`studio-core`, so `@po`, `/learn`, `/improve-agent`, `/create-agent`, and the skills
are always present.

## Notes

- **Applies uniformly to all org users** — no per-group targeting yet. Use this only
  if the studio is meant for the whole org.
- **`hooks.json` ships empty**, so enabling the plugin should not trigger the
  server-managed-settings security-approval dialog (that fires only for payloads
  delivering hooks, shell commands, custom env vars, or `claudeMd`).
- **MDM-locked machines (optional):** server-managed settings already cover unmanaged
  devices and cloud. If you also want the policy enforced at the OS level on managed
  devices, mirror the same two keys in an endpoint-managed
  `managed-settings.json`/MDM profile.

## Alternatives (when org-wide managed settings don't fit)

- **Per-repo:** commit the block from
  [`templates/consumer-settings.snippet.json`](../templates/consumer-settings.snippet.json)
  into each repo's `.claude/settings.json`. No admin role required; applies to every
  session of repos that carry it.
- **Per cloud environment:** in an organization-shared cloud environment
  (Admin Settings → Cloud environments), add a setup script that runs
  `claude plugin marketplace add nilpost/claude-code-studio` and
  `claude plugin install studio-core@claude-code-studio`. Applies to every session in
  that environment regardless of repo.
- **Per local machine:** `./scripts/install-local.sh` (user-scope install) makes it
  always-on across that one machine's projects.
