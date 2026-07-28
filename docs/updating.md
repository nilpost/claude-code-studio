# Updating & refreshing the studio

How to pull the latest agents, skills, and commands into a session — and why some
changes need a fresh session. Applies to both published plugins (`studio-core` and the
optional `cloudflare-mcp`); the examples use `studio-core`.

## The one rule that explains everything

**`SKILL.md` edits apply immediately. Everything else needs `/reload-plugins`.**

Skills refresh live mid-session. A new agent, a changed agent prompt, a new
`/command`, `hooks/`, or `.mcp.json` do not — but you don't need a new session for
them either: [`/reload-plugins`](https://code.claude.com/docs/en/plugins) reloads
plugins, skills, agents, hooks, and plugin MCP/LSP servers in place. Restarting also
works; it's just heavier.

So "get the latest agents" means: fetch the update, then `/reload-plugins`.

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

Then run **`/reload-plugins`** so updated agents and commands take effect. Skills are
current immediately either way. Check what you have with `claude plugin list`.

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
  enable/disable, update), then **`/reload-plugins`** to register `@po` and the
  commands without restarting.

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
| Local, want latest agents/skills | `./scripts/update-studio.sh` → **`/reload-plugins`** |
| Local, never want to think about it | Enable the opt-in `SessionStart` hook (see above) |
| A repo where the studio isn't loaded at all | `./scripts/enable-in-repo.sh /path/to/repo`, commit, **`/reload-plugins`** |
| Session already running, plugin not loaded | Enable it, then **`/reload-plugins`** |
| Cloud, want latest | **Start a new cloud session** (auto-pulls `main`) |
| Cloud Option B feels stale | Re-save the environment **setup script** to rebuild the cache |
| Want the studio to track your working tree | `./scripts/mirror-local.sh` (see below) |
| Check what's installed | `claude plugin list` |

## Mirror your working tree (no install, no update step)

If you're the one *authoring* the studio, the update cycle above is friction you don't
need. Symlink the plugin into your personal skills directory instead:

```bash
./scripts/mirror-local.sh                    # studio-core
./scripts/mirror-local.sh --with-cloudflare  # both plugins
./scripts/mirror-local.sh --undo             # revert
```

Claude Code loads any folder under `~/.claude/skills/` that has a
`.claude-plugin/plugin.json` as `<name>@skills-dir`, and discovers it **in place**
rather than copying it into the plugin cache. The plugin *is* your checkout, so
`git pull` — or an uncommitted local edit — is live on the next `/reload-plugins`. No
marketplace, no `plugin install`, no `plugin update`.

`~/.claude/skills/` is personal scope, so this applies in **every local project**. It
does **not** reach Claude Code on the web (ephemeral containers don't keep
`~/.claude`) — use `enable-in-repo.sh` for those.

> If you *also* have `studio-core` installed from the marketplace, both load side by
> side under different names and every agent appears twice. Keep one:
> `claude plugin uninstall studio-core@claude-code-studio`. The script warns you if it
> detects this.

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
