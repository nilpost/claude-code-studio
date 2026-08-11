# Studio Learnings

The durable, version-controlled memory for `claude-code-studio`. Lessons captured
in any project land here, get committed, and redistribute to every environment on
the next `claude plugin marketplace update`.

- **Newest entries go at the top** (reverse-chronological).
- Each entry follows the template below. Keep `Trigger` keywords concrete — the
  `recall-learnings` skill matches against them to surface a lesson at the right
  moment.
- One lesson per entry. Prefer specific, actionable wording ("do X instead of Y")
  over vague notes.

## Entry template

```
## <YYYY-MM-DD> — <project> — <short title>
- **Context:** what task or area this came from
- **Lesson:** the correction / what to do (or avoid) next time
- **Trigger:** comma-separated keywords or path globs that should recall this
```

---

<!-- Captured entries below. Newest first. -->

## 2026-08-04 — E-Companion — Read the project's own STATUS/BACKLOG before escalating a scanner advisory
- **Context:** A Supabase `list_tables` advisory reported `rls_disabled_in_public` on 16 tables including `health_records`, and it was escalated to the founder as a live critical exposure ("anyone with the anon key can read every row"). The project had already found this on 2026-07-21, escalated it to P0, fixed it the same day with a `revoke_data_api_anon_access` migration, verified 0/16 tables readable by `anon`, and run a forensic pass across gateway logs and `pg_stat_statements` showing zero exploitation. All of that was written down in the repo.
- **Lesson:** A linter/scanner advisory is a *hypothesis about the code*, not a statement about the project's current situation. Before reporting one as a finding, grep the project's own STATUS.md / BACKLOG.md / postmortems for the rule name or the affected object — a mature repo has usually already triaged it, and may have fixed it by a route the lint cannot see. Here the lint keys on the `relrowsecurity` flag alone and is structurally blind to the `REVOKE` that actually closed the hole. Also weigh the sources: the authoritative `get_advisors(security)` returned `{"lints":[]}` (clean) while a generic client-side heuristic fired — when two signals disagree, the specific/authoritative one wins and the disagreement itself is worth reporting. Cost of skipping this: a false P0, plus a proposed "fix" that would have caused real damage.
- **Trigger:** advisor, advisory, linter, rls_disabled_in_public, get_advisors, security scan, false positive, STATUS.md, BACKLOG.md, postmortem, already fixed, escalate finding, critical exposure

## 2026-08-04 — E-Companion — A tool's generic remediation can be specifically wrong for this project
- **Context:** After the RLS advisory above, the offered remediation ("enable RLS on all 16 tables") was proposed as a PR. The app has no `@supabase/supabase-js`, authenticates with Passport + `express-session` against its own `users` table, and connects as the `postgres` role, which carries `BYPASSRLS`. So `auth.uid()` is `NULL` on every policy check and the policies would be inert. Worse, the repo's BACKLOG explicitly ruled out RLS deny-all because it "recreates the exact state the rogue `ensure_rls` trigger produced and the postmortem removed".
- **Lesson:** Before applying a remediation a tool suggests, verify the project's architecture actually matches the tool's assumed model, and check whether a documented decision already rejected that fix. Supabase RLS presumes a Supabase-Auth JWT client; a server-side app using its own sessions over a direct `postgres` connection is a different model where RLS is inert and the real control is disabling the Data API gateway. **When a proposed remediation contradicts a project's own postmortem, the postmortem wins until it is explicitly revisited** — a postmortem encodes an incident someone already paid for. Note tools sometimes flag this themselves (this advisory said "Do not auto-apply the remediation SQL"); take that seriously rather than treating it as boilerplate.
- **Trigger:** remediation SQL, auto-apply, enable row level security, RLS policies, auth.uid, BYPASSRLS, postgres role, Data API, PostgREST, postmortem, documented decision, deny-all

## 2026-08-04 — equis-nexus-website — A dead subdomain is not evidence that something is undeployed
- **Context:** A portfolio sweep found `equis.postiusgroup.com` not resolving, concluded the project had never shipped, and recommended adding a routes block to deploy it there — described as "the cheapest live win in the portfolio". Equis Nexus was in fact live at its own apex domain `equis-nexus.com` on the same Cloudflare account. Deploying as recommended would have stood up a duplicate over a working production site.
- **Lesson:** "Hostname X does not resolve" only means *X* does not resolve. Before concluding something is undeployed, check whether it is deployed *somewhere else*: search the repo and any registry for an apex domain or alternate host, look for a deployed artifact (a Worker/service with a recent `modified_on` matching the repo's last push), and treat a stale `status: planned` in a registry as a claim to verify, not a fact. The failure mode is asymmetric and nasty — concluding "not deployed" when it is leads to duplicating or overwriting production, whereas the reverse just wastes a check. The same registry already recorded this exact error for another project ("the original plan to port this to Workers at ecompanion.* was WRONG — it would have duplicated or broken a working production app"), so the pattern was documented and still repeated.
- **Trigger:** subdomain does not resolve, DNS 000, dead host, not deployed, undeployed, status planned, add routes block, custom domain, apex domain, duplicate deployment, overwrite production

## 2026-08-04 — equis-nexus-website — Infra and CI configured provider-side are invisible to the repo
- **Context:** `equis-nexus.com` was live and served by the `equis-nexus` Worker, but `wrangler.jsonc` contained no `routes` block at all — the custom domain existed only in the Cloudflare dashboard. The repo therefore did not describe its own deployment, which is what let a sweep misread the project twice in one day. **Amended 2026-08-12:** the same trap then caught the fix. `.github/workflows/` was empty, so the repo was reported to the founder as having "no CI at all" and a PR against it as inert — "merging changes nothing, this takes effect only on the next manual `wrangler deploy`". Cloudflare **Workers Builds** was in fact connected straight to the repo and building for `production`; it surfaced only as a PR status check (`Workers Builds: equis-nexus`), never as a file. Merging would have deployed to a live business site under an assurance that it would not.
- **Lesson:** Routes, custom domains, DNS records, env vars and cron triggers set by hand in a provider dashboard are invisible to anyone (human or agent) reading the repo, and invisible to code review. Declare them in the deployment config so they are version-controlled next to the thing they route to. When you find such drift, fix it as a PR rather than a deploy, and state that you could not read the live config if no tool exposes it — infer the value from corroborating evidence, say so explicitly, and ask a human to confirm before the next deploy. Prefer changes whose failure mode is a loud error over a silent takeover (declaring an already-attached custom domain is a no-op; a domain attached to a *different* Worker makes `wrangler deploy` error out rather than hijack it). **An empty `.github/workflows/` does NOT mean a repo has no CI.** Cloudflare Workers Builds, Vercel, Netlify, Render, Railway and Amplify all connect to a repo from the provider's side and deploy on push while leaving nothing in the tree. Before telling anyone a merge is safe or inert, check the provider surface, not just the filesystem: `gh pr view <n> --json statusCheckRollup` lists provider checks, and a `detailsUrl` pointing at a provider dashboard (with a path segment like `/production/`) means merging ships. The general rule: **"I looked and found no file" is evidence about the filesystem, never about behaviour** — and a claim that an action is safe carries a higher burden of proof than a claim that it is risky, because the human relies on it to skip their own check.
- **Trigger:** wrangler.toml, wrangler.jsonc, routes block, custom_domain, dashboard-configured, config drift, not in version control, manual deploy, no CI, infra as code, .github/workflows empty, Workers Builds, provider-side CI, connected repo, deploy on push, statusCheckRollup, is it safe to merge, inert change, Vercel, Netlify, Render, Railway

## 2026-08-04 — studio-ops — Two registries that both assert status will drift, and each reader believes it is complete
- **Context:** `studio-ops/portfolio.json` (strategy: stage, gates, blockers) and `postius-hub/projects.json` (deployment: subdomain, host, build) both tracked the same 15 projects and both carried status claims. They disagreed on three things at once. Most costly: `Invoice_Generator` sat blocked at its G4 gate on "never independently verified" while the *other* file recorded a passing live verification dated 2026-07-31 for exactly that criterion.
- **Lesson:** When two files both answer "is this true / is this done?", they drift, and the failure is silent — whoever reads one believes they have the whole picture, and work stalls on questions already answered elsewhere. Pick one canonical owner for status and demote the other to facts that cannot contradict it (the split that works: *"is this true/finished?"* → source of truth; *"where does it live and how is it built?"* → deployment registry). When you inherit this situation, diff the two before trusting either, and expect the reconciliation to *unblock* something. Cross-check the header comment too — the demoted file here literally claimed to be the "single source of truth", which is what kept the drift invisible.
- **Trigger:** source of truth, canonical, registry, portfolio.json, projects.json, two files disagree, status drift, stale status, gate blocked, already verified, reconcile

## 2026-08-04 — github-dashboard — Verify what *kind* of blocker something is before accepting it
- **Context:** The portfolio recorded `github-dashboard` as "production deploy blocked on human-held credentials: Railway account, Neon URL, Cloudflare zone, GitHub PAT". Inspection showed it was not credential-blocked at all: the repo had no `wrangler.toml` and no deploy workflow, and two mutually exclusive deployment plans were on record (its own `DEPLOYMENT_TODO.md` specified Railway + Neon and the code matched; a separate registry specified a Hono + Neon HTTP port to Workers for which zero code existed). No credential could unblock it, because each plan invalidated the other's remaining work.
- **Lesson:** Treat a recorded blocker as a claim with a *category* — credentials, a decision, engineering, or an external dependency — and verify the category, not just the text. The tell for a miscategorised blocker is work that stays stuck while its stated cause looks satisfiable; and the tell for an undecided-fork blocker is two plans in different files that cannot both be executed. Getting this wrong wastes the human's scarcest input: they are asked for credentials that would not have helped, while the actual decision goes unmade. Related: "production-verified" in a status file may mean CI and tests only — confirm whether anything is actually deployed before repeating the phrase.
- **Trigger:** blocked on credentials, blocked_on_human, blocker, deploy target, undecided, two plans, DEPLOYMENT_TODO, production-verified, stuck project, needs a decision


## 2026-08-02 — claude-code-studio — A stale marketplace clone makes enabled plugins silently unavailable
- **Context:** Diagnosing why studio agents and studio-exec appeared missing in a local session
- **Lesson:** settings.json enabled studio-exec@claude-code-studio and it looked like the plugin did not exist anywhere — but the local marketplace clone at ~/.claude/plugins/marketplaces/<mp> was pinned 30 commits behind on an old feature branch, predating studio-exec. An enabled-but-uninstalled plugin produces no error at all, so the capability is just absent with no signal. Before concluding a plugin is missing, compare the local clone against the remote default branch (git -C ~/.claude/plugins/marketplaces/<mp> log --oneline -1 versus origin/main) and run claude plugin marketplace update <mp>. Also note studio-core ships no MCP server whatsoever, so "the plugin MCP connection dropped" is never a valid explanation for its agents being unavailable — check plugin installation state instead.
- **Trigger:** marketplace update, stale clone, enabledPlugins, studio-exec, plugin not found, installed_plugins.json, agents missing, marketplaces path, studio-core MCP, plugin silently unavailable

## 2026-08-02 — claude-code-studio — append_learning.sh was not portable — awk -v cannot take a multi-line value
- **Context:** Running /studio-core:learn on macOS to capture session lessons
- **Lesson:** The script built a multi-line entry and passed it as awk -v entry="$entry". GNU awk tolerates a literal newline in a -v assignment; the BWK awk shipped as /usr/bin/awk on macOS rejects it with "awk: newline in string ... at source line 1". set -e then aborted the script, so the entry was never written — it failed loudly rather than silently, but every capture on macOS was a no-op until fixed. Pass multi-line content to awk through a temp file and a getline loop, never through -v. General rule: -v is for short single-line scalars only. Fixed in this commit; also added an empty-output guard so a failed rewrite can never truncate the knowledge base.
- **Trigger:** append_learning.sh, capture-learnings, awk newline in string, awk -v, macOS awk, BWK awk, gawk, learning not saved, shell portability

## 2026-08-02 — claude-code-studio — recall-learnings cannot find LEARNINGS.md from an installed plugin
- **Context:** Running /studio-core:recall-learnings from a project that is not a studio checkout
- **Lesson:** All three documented lookup paths miss, so recall silently falls back to nothing. The CLAUDE_PLUGIN_ROOT/../../knowledge/LEARNINGS.md fallback is written for the repo layout (plugins/studio-core/../../knowledge resolves to the repo root), but the installed layout is cache/<marketplace>/<plugin>/<version>/, whose ../../ contains no knowledge/ dir — and knowledge/ is not packaged into the plugin. The only local copy is the marketplace clone at ~/.claude/plugins/marketplaces/<mp>/knowledge/LEARNINGS.md, which is itself stale unless the marketplace has been updated. Workaround: pass --file or export STUDIO_LEARNINGS_FILE. Real fix: package knowledge/ with the plugin, or add a documented, freshness-checked marketplace-clone fallback to both the recall-learnings SKILL.md and append_learning.sh.
- **Trigger:** recall-learnings, LEARNINGS.md, knowledge base not found, STUDIO_LEARNINGS_FILE, append_learning.sh, CLAUDE_PLUGIN_ROOT, marketplaces path, capture-learnings

## 2026-07-30 — dev-workspace — npm install fails inside cloud-synced folders; clone to local disk to build
- **Context:** A Node project living in a Google-Drive-synced directory; npm install ran for 20+ minutes then aborted, and no toolchain binary could be resolved afterwards
- **Lesson:** npm install does not work inside Drive/OneDrive/Dropbox-synced folders: it fails partway with 'EBADF: bad file descriptor, write', rolls back, and leaves a node_modules/ that exists but has an empty .bin/ and no resolvable packages. The tell is 'tsc is not recognized' or "Cannot find module 'typescript/package.json'" while node_modules/typescript visibly exists on disk. Critically, 'npm install | tail' or any piped form reports success because the exit status comes from the last pipe stage, not from npm — check the log text, never the exit code. Do not retry in place; git clone the repo to a path off the synced drive and install there (seconds-to-minutes instead of failing outright). Same root cause as cloud sync corrupting git object stores: the sync client does not preserve the file semantics these tools require.
- **Trigger:** npm install, EBADF, bad file descriptor, node_modules, .bin empty, tsc is not recognized, Cannot find module, google drive, onedrive, dropbox, cloud sync, exit code, pipe, build fails

## 2026-07-29 — sheets-sync-webapp — Plan multi-system integrations before touching any dashboard
- **Context:** Wiring a static frontend + a sync-proxy Worker + Google Sheets auth, done by jumping straight into browser provisioning
- **Lesson:** For any task spanning more than one external system (hosting + data source + auth + CI), write a short plan FIRST that answers: (1) what is the real shape of the source data, (2) which auth methods the org actually permits, (3) what tooling exists in this sandbox, (4) the full set of API scopes/permissions needed, (5) what triggers each deploy. Discovering these serially mid-build causes a rework cycle per discovery and burns very large amounts of tokens and wall-clock. The cost of a 15-minute planning pass is far below the cost of one rework.
- **Trigger:** integration, provisioning, multi-system, third-party API, oauth, dashboard setup, plan first, rework, token spend, scope creep

## 2026-07-29 — sheets-sync-webapp — Read the actual data source before writing a parser against it
- **Context:** A reference worker assumed a long Month | Category | Amount table; the real spreadsheet was a wide category-rows x month-columns grid with bold subtotal rows and nested line items
- **Lesson:** Never write or commit a parser based on a reference implementation's assumed schema. Open the real source first and confirm: orientation (long vs wide), where the header row actually starts (real sheets have title/metadata rows above it), which rows are subtotals vs already-summed children (double-counting risk), sentinel/total rows that end the table, and how numbers are formatted (currency symbols and thousands separators make Number() return NaN). Locate the header by label rather than assuming row 1, and map columns by name so column order does not matter.
- **Trigger:** parser, spreadsheet, google sheets, schema assumption, wide format, long format, header row, currency parsing, NaN, subtotal, double count

## 2026-07-29 — sheets-sync-webapp — Verify org policy permits an auth method before building on it
- **Context:** Created a GCP project, enabled the API, and created a service account — only then hit a Workspace org policy blocking service-account key creation
- **Lesson:** Google Workspace orgs commonly enforce iam.disableServiceAccountKeyCreation, which blocks exporting service-account keys entirely. Confirm the intended auth method is actually permitted before building the project/service-account/API scaffolding around it. When keys are blocked and no admin exception is available, the working fallback for server-to-server access is an OAuth client + one-time consent + a stored refresh token (grant_type=refresh_token), authenticating as a real user account that has its own access to the resource. Note the trade-off: access is then tied to that human account rather than a dedicated bot identity.
- **Trigger:** service account, iam.disableServiceAccountKeyCreation, org policy, workspace, oauth, refresh token, google api, auth blocked, jwt bearer

## 2026-07-29 — sheets-sync-webapp — Provision all required API token scopes before the first deploy
- **Context:** A Cloudflare deploy token was created with only account-level Workers Scripts:Edit; deploy then failed with Authentication error [code: 10000] on /zones/<id>/workers/routes
- **Lesson:** Deploying a Worker that owns a custom domain/route needs TWO permissions, not one: account-level Workers Scripts: Edit AND zone-level Workers Routes: Edit scoped to that domain. More generally, before creating a deploy token, list every API endpoint the deploy tool will touch and map each to its scope — a token that works for the code upload can still fail at the routing step. Discovering this late costs a token recreation plus a secret rotation plus a re-run.
- **Trigger:** cloudflare, api token, wrangler deploy, workers routes, workers scripts, authentication error 10000, zone scope, permissions, custom domain

## 2026-07-29 — sheets-sync-webapp — Check for the runtime toolchain before planning local execution
- **Context:** Planned to run node --test and npx wrangler deploy locally; neither node, npm, nor npx existed in the session sandbox
- **Lesson:** Verify the required runtime/CLI is actually present (which node npm npx) before designing a workflow around running it locally. When it is absent and installing is not warranted, route execution through CI instead — commit a workflow and trigger it — rather than improvising. Also be explicit with the user about what could NOT be verified locally: unit tests that never ran are not passing tests, and saying so plainly matters more than appearing complete.
- **Trigger:** node not found, npx, npm, wrangler, sandbox toolchain, which node, ci fallback, tests not run, unverified

## 2026-07-29 — sheets-sync-webapp — Use ref-based clicks; cross-origin editors cannot be automated
- **Context:** Provisioning Cloudflare Workers, KV, and secrets by driving the dashboard in a browser session
- **Lesson:** (1) Coordinate-based clicking is unreliable when the screenshot's pixel space does not match the page's CSS pixel space (observed ~0.625 scale), and the scale CHANGES when a tab is fronted/backgrounded — many clicks silently hit the wrong element or nothing. Prefer read_page -> ref -> click-by-ref, and form_input by ref for fields. If coordinates are unavoidable, front the tab first and take a fresh screenshot immediately before each click. (2) Some dashboard code editors (e.g. Monaco in a cross-origin iframe) cannot be typed into at all by page automation — do not burn turns retrying; deliver the code by another path such as a CI deploy. (3) Always pass the explicit tabId on multi-tab work: an un-targeted action goes to whichever tab is fronted and can land input in the wrong page.
- **Trigger:** browser automation, coordinate click, screenshot scale, ref, read_page, form_input, monaco, cross-origin iframe, tabId, wrong tab

## 2026-07-29 — sheets-sync-webapp — Extract secret values programmatically, never read them off a screenshot
- **Context:** An OAuth refresh token and an API token were read visually from dashboard screenshots and retyped
- **Lesson:** Visually transcribing a credential is unreliable and expensive to debug — two separate transcription errors occurred (a dropped -, and an O/0 swap), surfacing only later as an opaque Token endpoint returned 400 and a failed deploy, each costing a credential roll plus a re-run. Always extract the exact value programmatically (e.g. a regex match against page text) and verify its length before use. Handle it inside the automated surface; never print a live credential into a chat transcript, which is stored. Related: a credential shown once and dismissed without copying must be rolled — build the copy step into the flow before clicking away.
- **Trigger:** secret, api token, refresh token, transcription, screenshot, credential, token endpoint 400, roll token, do not print secrets

## 2026-07-29 — sheets-sync-webapp — A separate-origin backend Worker needs CORS headers on every response
- **Context:** A static frontend on one subdomain calling a sync-proxy Worker on a different origin
- **Lesson:** When the frontend and its backend Worker are separate origins, every response — including the OPTIONS preflight and all error responses — must carry Access-Control-Allow-Origin / -Methods / -Headers, or the browser fetch fails before it ever sees the body. Handle OPTIONS explicitly and early, and spread the CORS headers into the error-response helper too, not just the success path. Note also: when an automated code review flags something like this on a PR, fix it before merge — this exact issue was flagged by a review bot and left unfixed, then had to be corrected later.
- **Trigger:** cors, preflight, OPTIONS, access-control-allow-origin, cloudflare worker, separate origin, fetch failed, review bot finding

## 2026-07-29 — sheets-sync-webapp — Add paths: filters when a repo deploys more than one artifact
- **Context:** A repo holding both a static site and an example Worker; merging a Worker-only PR also fired the site's deploy workflow, which then failed
- **Lesson:** In a repo with more than one deployable, give each deploy workflow a paths: filter so unrelated merges do not trigger it. Without one, every merge runs every deploy — producing confusing red runs that are unrelated to the change, and masking whether a genuine deploy regression exists.
- **Trigger:** github actions, paths filter, deploy workflow, monorepo, multiple deployables, spurious failure, on push

## 2026-07-29 — dev-workspace — Cloud-sync folders corrupt git object stores; always configure a remote
- **Context:** A workspace repo living in a Google-Drive-synced directory had .git/HEAD pointing at a commit object missing from .git/objects; a nested repo in the same tree had the identical corruption independently
- **Lesson:** Git repos inside Drive/Dropbox/OneDrive-synced folders corrupt: the sync client does not preserve git's atomic loose-object write semantics, so objects go missing and git status/log fail with fatal: bad object HEAD. Keep repos outside synced folders. A configured remote, pushed to frequently, is the reliable recovery path — without one, don't assume the history is unrecoverable before checking every other source: another machine or clone that still has the object, the sync provider's own file-version history, filesystem-level backups/snapshots, and `git fsck --unreachable`/reflog on the corrupted copy itself (a missing object from a bad write doesn't necessarily mean every relevant object is gone). Only if all of those come up empty is the history actually lost. When recovering, move the broken .git aside as a backup rather than deleting it, gitignore that backup, and re-init; also check nested repos, which corrupt independently.
- **Trigger:** bad object HEAD, git corruption, google drive, onedrive, dropbox, cloud sync, git fsck, invalid sha1 pointer, no remote, git init recovery

## 2026-07-28 — claude-code-studio — git diff two-dot vs three-dot gives different, misleading results when verifying a PR branch
- **Context:** Writing/running a local verification script to check a PR branch's actual diff (e.g. before a GO/NO-GO merge call), where the base branch (main) had moved since the PR branch was cut
- **Lesson:** git diff branchA branchB (two-dot) compares tip-to-tip, so it includes commits that landed on branchA AFTER branchB diverged from it — those show up as spurious additions/deletions that are not part of the PR at all. git diff branchA...branchB (three-dot) diffs from the merge-base instead, which is what GitHub's own PR 'Files changed' view uses. Reproduced directly in this repo: git diff main fix-learn-self-narration showed knowledge/LEARNINGS.md losing 5 lines (an entry a later, unrelated PR had added to main after this branch was cut) while git diff main...fix-learn-self-narration correctly showed nothing PR-specific. Always use three-dot (or diff against `git merge-base`) when verifying 'what does this PR actually change' against a moving base branch; two-dot answers a different question (what differs between these two tips right now) and will misattribute the other branch's independent history as part of the PR.
- **Trigger:** git diff, two-dot diff, three-dot diff, merge-base, PR verification, GO/NO-GO, verify a PR branch, moving base branch, files changed

## 2026-07-28 — claude-code-studio — GitHub heading-anchor slugs preserve double hyphens; don't collapse whitespace when computing them
- **Context:** Writing a throwaway script to verify every relative markdown link and in-page heading anchor resolves, across several PR branches (a recurring bug class this session)
- **Lesson:** GitHub's real heading-slug algorithm removes punctuation characters (the ASCII punctuation set plus the U+2000-U+206F general-punctuation Unicode block, which includes em/en dashes) but does NOT collapse the whitespace left behind before turning each remaining space into a hyphen. A heading like "Local machine (Pro) \u2014 one time" slugs to `local-machine-pro--one-time` (double hyphen), not `local-machine-pro-one-time`. A naive slugify that does `re.sub(r'\s+', '-', s)` collapses that gap and flags every such anchor as broken -- false positives on docs that were already correct. Replace each whitespace character individually (`re.sub(r'\s', '-', s)`), never the whole run, and remember `&` is in the removed ASCII set too (so "Versioning & release" -> `versioning--release`).
- **Trigger:** markdown anchor, heading slug, github-slugger, broken link checker, anchor resolves, em dash, double hyphen, ampersand slug

## 2026-07-27 — JP_Invoice_Generator / Invoice_Generator — git reset --hard deletes tracked-then-ignored files; mirror-clone from remote, not local
- **Context:** Rewriting git history with git filter-repo to scrub leaked PII, then syncing a local branch to the rewritten remote
- **Lesson:** (1) Before git reset --hard or a checkout across a commit boundary, check whether any path is tracked in the source commit but gitignored in the target commit (e.g. a config-split fix that does git rm --cached). The working-tree file gets deleted in that transition regardless of .gitignore, since .gitignore only blocks future git add, not removal on a tracked-to-untracked transition — back up such files first. (2) When mirror-cloning a repo for a history rewrite (git filter-repo/BFG), always clone from the actual remote URL (git remote get-url origin), never from a local working copy. A --mirror clone of a local copy only sees that copy's last-fetched refs/heads/*, silently missing true origin/* state (e.g. a squash-merge that happened on GitHub after the last local fetch) — the rewrite and force-push then look successful but leave the real live branch untouched.
- **Trigger:** git reset --hard, git filter-repo, git checkout, mirror clone, history rewrite, gitignore, tracked file deleted, force-push, BFG

## 2026-07-22 — github-dashboard — Guard NaN in hand-rolled semver comparison
- **Context:** compareVersions in dependency.service.ts; edge-case tests exposed a real bug
- **Lesson:** The idiom part = arr[i] || 0 coerces NaN to 0, so a non-registry version spec (workspace star, file path, git URL) parsed to 0.0.0 and was falsely flagged outdated against any real release. Bail to a safe default when a version is not a bare x.y.z. Also: writing edge-case tests is what surfaced this — tests are not just verification, they find bugs.
- **Trigger:** semver, compareVersions, NaN coercion, workspace, outdated dependency, version parse, edge-case tests

## 2026-07-22 — github-dashboard — Railway custom domains 404 without in-service registration
- **Context:** Planning a Cloudflare subdomain go-live pointing at a Railway app
- **Lesson:** A bare Cloudflare CNAME to the default up.railway.app host returns 404 for a custom domain. First register the custom domain IN the Railway service (railway domain <host>, or Settings/Networking), then point DNS at the CNAME target Railway provides. If the record is proxied and Railway's cert will not issue, grey-cloud it until verified then re-proxy; keep SSL/TLS mode Full.
- **Trigger:** railway, custom domain, up.railway.app, cloudflare CNAME, 404, DNS, proxied, SSL Full

## 2026-07-22 — github-dashboard — Audit ALL client fetch sites when adding CSRF/auth headers
- **Context:** Wiring double-submit-cookie CSRF into a React cookie-session SPA
- **Lesson:** When a change requires a header on every mutation (CSRF token, auth), do not assume all requests go through the shared api helper. This SPA had 6 scattered direct fetch calls (login, register, logout, settings x2, sync) outside the helper. Grep every fetch call site and wire each mutating one, or the change silently misses paths.
- **Trigger:** csrf, x-csrf-token, fetch, apiRequest, cookie session, SPA mutation, double-submit

## 2026-07-22 — github-dashboard — Never cast an external SDK method with 'as any'
- **Context:** Fixing Dependabot detection: octokit.repos.listDependabotAlerts (a non-existent method) was called behind an 'as any' cast
- **Lesson:** An 'as any' cast on a third-party SDK method defeats the type-checker: a non-existent method compiles clean, throws at runtime, gets swallowed by the surrounding catch, and returns empty — shipping a silently-broken feature. Never cast an external SDK method to any; let tsc verify the name. Cover the path with an integration test using a mocked SDK, since untested code is how this class of bug ships through green CI.
- **Trigger:** octokit, as any, SDK, third-party client, listDependabotAlerts, dependabot, swallowed catch, mocked SDK test

## 2026-07-21 — claude-code-studio — plugin CLI rewrites repo .claude/settings.json on cleanup
- **Context:** Uninstalling the test plugin / removing the marketplace after verification
- **Lesson:** 'claude plugin uninstall' and 'marketplace remove' can rewrite the repo's .claude/settings.json and empty your intended enabledPlugins/extraKnownMarketplaces. After CLI cleanup, re-check and restore that file to its intended committed content.
- **Trigger:** settings.json, plugin uninstall, marketplace remove, enabledPlugins

## 2026-07-21 — claude-code-studio — marketplace add needs ./ prefix for local dir
- **Context:** Adding the local marketplace during verification
- **Lesson:** 'claude plugin marketplace add .' is rejected as an invalid source format. Use './' (or owner/repo, or an https URL). Bare '.' does not count as a path.
- **Trigger:** marketplace add, directory source, local path, ./

## 2026-07-21 — claude-code-studio — Plugin hooks.json schema rejects non-event keys
- **Context:** claude plugin validate failed on the studio-core plugin
- **Lesson:** Under hooks.json 'hooks', only real event names (SessionStart, SessionEnd, PreToolUse, ...) are valid keys. Placeholder/disabled keys like '_disabled_SessionEnd' fail 'claude plugin validate'. Ship hooks.json empty ({"hooks":{}}) and put opt-in examples in a separate hooks.example.json that the loader ignores.
- **Trigger:** hooks.json, plugin validate, SessionEnd, PreToolUse, plugin hooks

## 2026-07-21 — claude-code-studio — Cloud ~/.claude does not persist — distribute via marketplace
- **Context:** Deciding how to share agents/skills between local and Claude Code on the web
- **Lesson:** In cloud sessions the container is ephemeral and clones the repo fresh; user-level ~/.claude is absent. Do NOT rely on ~/.claude/skills or ~/.claude/agents for cross-environment sharing. Distribute via a git-hosted plugin marketplace referenced from a repo's committed .claude/settings.json (extraKnownMarketplaces + enabledPlugins), or commit assets into the repo.
- **Trigger:** cloud, ephemeral, ~/.claude, multi-environment, marketplace, distribution, claude code on the web

## 2026-07-17 — web-app — Verify by running, not just by compiling
- **Context:** Reviewing a 'done' full-stack app for deploy-readiness.
- **Lesson:** A green tsc/build proves it compiles, not that it works. Boot the app against real dependencies (e.g. a throwaway Postgres) and exercise the actual flows — health, register, login, session — before calling it done. The most serious bugs (broken health check, login, secret leaks) are invisible to the compiler and only surface at runtime. Test both DB-up and DB-down paths.
- **Trigger:** deploy-readiness, verify by running, tsc passes but, looks done, boot the app, smoke test, happy path, failure path

## 2026-07-17 — web-app — Health check must hit a real endpoint, not the SPA fallback
- **Context:** Express app with an app.get('*') SPA fallback and a container HEALTHCHECK on /api/health.
- **Lesson:** A catch-all SPA route serves index.html (HTTP 200) for /api/health and every unknown /api/* path, so the health check passes even when the backend/DB is down and client fetches to bad API paths get HTML. Add a real health route that verifies the DB and returns 200/503 JSON, and register a JSON 404 for unknown /api/* BEFORE the SPA fallback.
- **Trigger:** /api/health, health check, SPA fallback, app.get('*'), catch-all, JSON 404, express static, healthcheck passes when down

## 2026-07-17 — web-app — Secure session cookies need trust proxy behind a TLS-terminating proxy
- **Context:** Session-cookie login on Express behind Railway/Cloudflare; login silently failed only in production.
- **Lesson:** When a platform terminates TLS and forwards plain HTTP (Railway, Cloudflare, most PaaS), express-session with cookie.secure=true refuses to set the cookie unless the app sets app.set('trust proxy', 1). Without it the Set-Cookie is dropped and login silently fails in production only. Enable trust proxy in production and verify the session cookie is actually issued and persists across requests.
- **Trigger:** trust proxy, secure cookie, express-session, login fails in production, Railway, Cloudflare, TLS termination, X-Forwarded-Proto, session not persisting, connect.sid

## 2026-07-17 — web-app — Never return password hashes — sanitize user objects before serializing
- **Context:** An Express app where /register, /login and /user could serialize the full user row, including the password hash.
- **Lesson:** Route every user object through an allowlist/sanitize step (drop password/hash and internal fields) before res.json. Passport serialize/deserialize rehydrates the full row, so /user leaks too — sanitize at the response boundary, not just at user creation.
- **Trigger:** password hash leak, sanitizeUser, res.json(user), passport deserializeUser, /api/user, register response, sensitive fields

## 2026-07-17 — web-app — Match the container start command to the bundler's actual output path
- **Context:** esbuild bundled the server to dist/index.js but Dockerfile/railway.json ran dist/server/index.js — the container crashed on boot.
- **Lesson:** Confirm the start command points at the file the bundler actually emits; a wrong path crashes on boot despite a green build. Prefer npm start in Docker/CI so the path lives in one place (package.json) instead of being duplicated across Dockerfile and platform config where it can drift.
- **Trigger:** dist/index.js, start command, esbuild outdir, Dockerfile CMD, railway.json startCommand, crash on boot, module not found

## 2026-07-17 — web-app — npm ci needs a committed lockfile — gitignored lock breaks CI/Docker
- **Context:** Dockerfile/CI used npm ci, but package-lock.json was gitignored.
- **Lesson:** npm ci hard-fails without a committed package-lock.json. If the lockfile is gitignored, either commit it or use npm install in the Dockerfile and CI. Check .gitignore before writing npm ci into any build.
- **Trigger:** npm ci, package-lock.json, gitignored lockfile, Dockerfile install, CI install, lockfile missing

## 2026-07-17 — web-app — .env in .gitignore does not cover .env.production
- **Context:** .gitignore had a bare .env line but real secrets sat in an untracked .env.production at risk of being committed.
- **Lesson:** A gitignore '.env' line matches only the file literally named .env, not .env.production or .env.staging. Ignore each real env file explicitly (or use .env* with a negation like !.env.example / !*.template) and commit only placeholder templates. Verify with git check-ignore .env.production.
- **Trigger:** .env.production, gitignore secrets, git check-ignore, env not ignored, env template, secret committed

## 2026-07-17 — web-app — In ESM projects, standalone Node scripts using require() must be .cjs
- **Context:** A package.json with type: module and helper scripts (validate-env.js etc.) using require().
- **Lesson:** In a type: module package, a .js file using require()/module.exports throws 'require is not defined in ES module scope' and crashes immediately. Name CommonJS helper scripts .cjs (and update every reference), or rewrite them as ESM. Run the script once to confirm.
- **Trigger:** type module, require is not defined, ESM, .cjs, ERR_REQUIRE_ESM, standalone node script, package.json type

## 2026-07-17 — web-app — Sandboxed/cloud sessions can't reach production URLs or hosting dashboards
- **Context:** Asked to verify a PaaS-hosted deploy went live by curling the production URL and via WebFetch.
- **Lesson:** Claude Code web/agent sessions commonly run behind an outbound proxy with a fixed allowlist that does not include arbitrary production domains or third-party dashboards/APIs (hosting platform, DB provider, CDN), and the session usually has no credentials for them either. Both curl and WebFetch will fail (e.g. a 403 at the proxy's CONNECT step) — that failure happens at the sandbox's network layer, not the application, so never report a live site as "down" or a deploy as "confirmed live" on that basis. Say plainly that live verification isn't possible from the current session, and point to the actual fix: the human checks the dashboard directly, or the session's environment network policy gets widened (see https://code.claude.com/docs/en/claude-code-on-the-web).
- **Trigger:** curl 403, WebFetch 403, CONNECT tunnel failed, proxy, network policy, production URL, verify deploy, cannot reach, dashboard credentials, sandboxed network

## 2026-07-17 — web-app — Unguarded async callbacks crash the whole process, not just one request
- **Context:** A register/login failure pattern (500/502/401) traced to an async callback in a passport-local LocalStrategy verify / passport.deserializeUser. The failure class is general to any async callback a library invokes without awaiting/catching it.
- **Lesson:** An async callback whose rejection nothing awaits or catches becomes an unhandled promise rejection, and Node exits on that by default. If the host platform auto-restarts on failure (e.g. Railway's ON_FAILURE policy), the symptom looks like intermittent 502s for ALL users, not a clean error for the one request that failed — that mismatch (one bad request, everyone affected) is the tell. Fix: wrap every async Express/framework route handler and every async callback passed to a library that doesn't await it (passport strategies, event emitters, etc.) in try/catch, resolving errors through the framework's normal error channel (next(err), done(err)) instead of letting them throw uncaught. A small asyncHandler(fn) => (req,res,next) => fn(req,res,next).catch(next) wrapper applied to all routes closes this for an entire Express app in one pass.
- **Trigger:** unhandled promise rejection, unhandled rejection, passport, passport-local, async callback, express route handler, node process crash, 502, asyncHandler, deserializeUser, done(err), next(err)
