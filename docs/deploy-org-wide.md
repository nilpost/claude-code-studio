# Make studio-core always-on (Pro, and org-wide)

Goal: have `studio-core` (all its agents, skills, and commands) load automatically in
your sessions — local and Claude Code on the web — with as little per-session setup as
possible.

Pick the row that matches your account:

| Your account | Best "always-on" method | Needs admin? |
| --- | --- | --- |
| **Pro / Max** (individual) | [Local install](#local-machine-pro-one-time) + [cloud env setup script](#cloud-option-b--all-repos-personal-environment-setup-script) or [per-repo snippet](#cloud-option-a--per-repo-guaranteed) | No |
| **Teams / Enterprise** (whole org) | [Server-managed settings](#org-wide-teams--enterprise-only) | Owner role |

---

## Pro / Max (individual accounts)

Server-managed settings (the admin-console "Managed settings" page) is a
Teams/Enterprise feature and **does not exist on a Pro or Max account** — there is no
JSON page to paste into. Use these instead; none require an admin console.

### Local machine (Pro) — one time

```bash
claude plugin marketplace add nilpost/claude-code-studio
claude plugin install studio-core@claude-code-studio --scope user
# or simply: ./scripts/install-local.sh
```

This writes to your own `~/.claude/`, so the studio is always on in every local
project on that machine. Nothing to hand-edit.

### Cloud (Claude Code on the web)

Cloud containers are ephemeral and don't keep `~/.claude`, so "always on" has to come
from a committed file or your environment config. Both are available on Pro.

#### Cloud, Option A — per repo (guaranteed)

Add these two keys to the repo's **`.claude/settings.json`** (create the file if
needed) and commit. Every cloud session of that repo then auto-installs and enables the
plugin at session start. This is the block in
[`../templates/consumer-settings.snippet.json`](../templates/consumer-settings.snippet.json):

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

#### Cloud, Option B — all repos (personal environment setup script)

To avoid editing every repo, put the install in your personal cloud environment's
**setup script** (web UI → environment selector → edit the environment → **Setup
script**):

```bash
claude plugin marketplace add nilpost/claude-code-studio
claude plugin install studio-core@claude-code-studio --scope user
```

The setup script runs before every session in that environment and its output is
cached, so `studio-core` is present in every cloud session there, regardless of which
repo you open. This is the closest to "always everywhere" without an org Owner role.
Requires the environment's network level to allow GitHub (the default **Trusted** level
does; **None** would block the marketplace fetch).

---

## Org-wide (Teams / Enterprise only)

If you have a Teams or Enterprise plan and the **Owner** or **Primary Owner** role, you
can enable the studio for every member's sessions — local and cloud, every repo, no
per-repo edits — through **server-managed settings**. Device-level
`managed-settings.json` / MDM policies **do not reach cloud sessions** (those run on
Anthropic-managed VMs), so server-managed settings is the channel that covers both.

Docs: <https://code.claude.com/docs/en/server-managed-settings>

**Requirements:** Teams or Enterprise plan; Owner/Primary Owner role; cloud
environments with network access to GitHub; not delivered to sessions on a third-party
provider (Bedrock / Vertex / Foundry) or a custom `ANTHROPIC_BASE_URL`.

**Steps:**

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

**Notes:**

- Applies uniformly to all org users — no per-group targeting yet.
- `hooks.json` ships empty, so enabling the plugin should not trigger the
  server-managed-settings security-approval dialog (that fires only for payloads
  delivering hooks, shell commands, custom env vars, or `claudeMd`).
- MDM-locked machines (optional): server-managed settings already cover unmanaged
  devices and cloud; mirror the same two keys in an endpoint-managed
  `managed-settings.json`/MDM profile if you also want OS-level enforcement.
