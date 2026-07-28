# Updating & refreshing the studio

How to pull the latest agents, skills, and commands into a session — and why some
changes need a fresh session. Applies to both published plugins (`studio-core` and the
optional `cloudflare-mcp`); the examples use `studio-core`.

## The one rule that explains everything

Claude Code registers **agents and slash-commands only at session start**. **Skills**
can refresh live (SKILL.md edits are picked up mid-session), but a *new* agent, a
changed agent prompt, or a new `/command` will not appear in a session that is already
running. So "get the latest agents" almost always means: update, then **start a new
session**.

## Local — update an installed session

```bash
./scripts/update-studio.sh                    # refetch marketplace + update studio-core
./scripts/update-studio.sh --with-cloudflare  # also update the cloudflare-mcp add-on
```

Equivalent by hand:

```bash
claude plugin marketplace update claude-code-studio    # refetch marketplace from GitHub main
claude plugin update studio-core@claude-code-studio    # update the installed plugin
```

Then **start a new session** for agents/commands to re-register. Skills are current
immediately. Check what you have with `claude plugin list`.

To avoid remembering this at all, enable the opt-in `SessionStart` hook in
[`plugins/studio-core/hooks/hooks.example.json`](../plugins/studio-core/hooks/hooks.example.json):
it refetches the marketplace in the background at session start, so each new session
you open is current. It can't update the session it runs in — agents and commands
register before hooks fire.

The marketplace source is the GitHub repo with no pinned ref, so `marketplace update`
always pulls the latest `main`; a `version` bump in `plugin.json` / `marketplace.json`
isn't required for updates to flow, though bumping it per release is good hygiene.

## Turn it on where it isn't loaded yet

You can't retro-inject agents/commands into a running session. Enable the plugin, then
open a fresh session:

- CLI: manage plugins in-session with the **`/plugin`** menu (add marketplace,
  enable/disable, update) — but still **start a new session** for `@po` and the
  commands to register.

## Cloud (Claude Code on the web) — updating = start a new session

Cloud sessions clone fresh and **install the plugin from the marketplace at session
start**, so a brand-new cloud session is automatically on the latest `main`. There is no
"update a running cloud session" — start a new one.

- **Per-repo (`.claude/settings.json`, Option A):** installs fresh every session, so
  it's always current.
- **Environment setup-script (Option B):** the environment snapshot is **cached**, so
  the `plugin install` from the setup script can be stale. It rebuilds when you change
  the setup script or after ~7 days. To force-refresh now, make any edit to that
  environment's setup script (re-save) to trigger a cache rebuild.

## Quick reference

| Situation | What to do |
| --- | --- |
| Local, want latest agents/skills | `./scripts/update-studio.sh` → **new session** |
| Local, never want to think about it | Enable the opt-in `SessionStart` hook (see above) |
| A repo where the studio isn't loaded at all | `./scripts/enable-in-repo.sh /path/to/repo`, commit, **new session** |
| Session already running, plugin not loaded | Enable it, then **start a new session** |
| Cloud, want latest | **Start a new cloud session** (auto-pulls `main`) |
| Cloud Option B feels stale | Re-save the environment **setup script** to rebuild the cache |
| Check what's installed | `claude plugin list` |

## Publishing an update (maintainer side)

Changes reach consumers only after they're on `main`:

1. Edit agents/skills/commands, commit, open a PR, merge to `main`.
2. Optionally bump `version` in `plugins/studio-core/.claude-plugin/plugin.json` and
   `.claude-plugin/marketplace.json`.
3. Consumers then get it via the steps above (local: `marketplace update`; cloud: new
   session).

The `capture-learnings` / `improve-agent` / `create-agent` flows are just special cases
of this: they change files under `plugins/studio-core/` (or `knowledge/`), which
propagate the same way once merged.
