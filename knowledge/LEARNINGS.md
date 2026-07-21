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

## 2026-07-17 — github-dashboard — Verify by running, not just by compiling
- **Context:** Reviewing a 'done' full-stack app for deploy-readiness.
- **Lesson:** A green tsc/build proves it compiles, not that it works. Boot the app against real dependencies (e.g. a throwaway Postgres) and exercise the actual flows — health, register, login, session — before calling it done. The most serious bugs (broken health check, login, secret leaks) are invisible to the compiler and only surface at runtime. Test both DB-up and DB-down paths.
- **Trigger:** deploy-readiness, verify by running, tsc passes but, looks done, boot the app, smoke test, happy path, failure path

## 2026-07-17 — github-dashboard — Health check must hit a real endpoint, not the SPA fallback
- **Context:** Express app with an app.get('*') SPA fallback and a container HEALTHCHECK on /api/health.
- **Lesson:** A catch-all SPA route serves index.html (HTTP 200) for /api/health and every unknown /api/* path, so the health check passes even when the backend/DB is down and client fetches to bad API paths get HTML. Add a real health route that verifies the DB and returns 200/503 JSON, and register a JSON 404 for unknown /api/* BEFORE the SPA fallback.
- **Trigger:** /api/health, health check, SPA fallback, app.get('*'), catch-all, JSON 404, express static, healthcheck passes when down

## 2026-07-17 — github-dashboard — Secure session cookies need trust proxy behind a TLS-terminating proxy
- **Context:** Session-cookie login on Express behind Railway/Cloudflare; login silently failed only in production.
- **Lesson:** When a platform terminates TLS and forwards plain HTTP (Railway, Cloudflare, most PaaS), express-session with cookie.secure=true refuses to set the cookie unless the app sets app.set('trust proxy', 1). Without it the Set-Cookie is dropped and login silently fails in production only. Enable trust proxy in production and verify the session cookie is actually issued and persists across requests.
- **Trigger:** trust proxy, secure cookie, express-session, login fails in production, Railway, Cloudflare, TLS termination, X-Forwarded-Proto, session not persisting, connect.sid

## 2026-07-17 — github-dashboard — Never return password hashes — sanitize user objects before serializing
- **Context:** /register, /login and /user returned the full user row including the scrypt hash.
- **Lesson:** Route every user object through an allowlist/sanitize step (drop password/hash and internal fields) before res.json. Passport serialize/deserialize rehydrates the full row, so /user leaks too — sanitize at the response boundary, not just at user creation.
- **Trigger:** password hash leak, sanitizeUser, res.json(user), passport deserializeUser, /api/user, register response, sensitive fields

## 2026-07-17 — github-dashboard — Match the container start command to the bundler's actual output path
- **Context:** esbuild bundled the server to dist/index.js but Dockerfile/railway.json ran dist/server/index.js — the container crashed on boot.
- **Lesson:** Confirm the start command points at the file the bundler actually emits; a wrong path crashes on boot despite a green build. Prefer npm start in Docker/CI so the path lives in one place (package.json) instead of being duplicated across Dockerfile and platform config where it can drift.
- **Trigger:** dist/index.js, start command, esbuild outdir, Dockerfile CMD, railway.json startCommand, crash on boot, module not found

## 2026-07-17 — github-dashboard — npm ci needs a committed lockfile — gitignored lock breaks CI/Docker
- **Context:** Dockerfile/CI used npm ci, but package-lock.json was gitignored.
- **Lesson:** npm ci hard-fails without a committed package-lock.json. If the lockfile is gitignored, either commit it or use npm install in the Dockerfile and CI. Check .gitignore before writing npm ci into any build.
- **Trigger:** npm ci, package-lock.json, gitignored lockfile, Dockerfile install, CI install, lockfile missing

## 2026-07-17 — github-dashboard — .env in .gitignore does not cover .env.production
- **Context:** .gitignore had a bare .env line but real secrets sat in an untracked .env.production at risk of being committed.
- **Lesson:** A gitignore '.env' line matches only the file literally named .env, not .env.production or .env.staging. Ignore each real env file explicitly (or use .env* with a negation like !.env.example / !*.template) and commit only placeholder templates. Verify with git check-ignore .env.production.
- **Trigger:** .env.production, gitignore secrets, git check-ignore, env not ignored, env template, secret committed

## 2026-07-17 — github-dashboard — In ESM projects, standalone Node scripts using require() must be .cjs
- **Context:** A package.json with type: module and helper scripts (validate-env.js etc.) using require().
- **Lesson:** In a type: module package, a .js file using require()/module.exports throws 'require is not defined in ES module scope' and crashes immediately. Name CommonJS helper scripts .cjs (and update every reference), or rewrite them as ESM. Run the script once to confirm.
- **Trigger:** type module, require is not defined, ESM, .cjs, ERR_REQUIRE_ESM, standalone node script, package.json type

## 2026-07-17 — E-Companion — Sandboxed/cloud sessions can't reach production URLs or hosting dashboards
- **Context:** Asked to verify a Railway-hosted deploy went live by curling the production URL and via WebFetch.
- **Lesson:** Claude Code web/agent sessions commonly run behind an outbound proxy with a fixed allowlist that does not include arbitrary production domains or third-party dashboards/APIs (hosting platform, DB provider, CDN), and the session usually has no credentials for them either. Both curl and WebFetch will fail (e.g. a 403 at the proxy's CONNECT step) — that failure happens at the sandbox's network layer, not the application, so never report a live site as "down" or a deploy as "confirmed live" on that basis. Say plainly that live verification isn't possible from the current session, and point to the actual fix: the human checks the dashboard directly, or the session's environment network policy gets widened (see https://code.claude.com/docs/en/claude-code-on-the-web).
- **Trigger:** curl 403, WebFetch 403, CONNECT tunnel failed, proxy, network policy, production URL, verify deploy, cannot reach, dashboard credentials, sandboxed network

## 2026-07-17 — E-Companion — Unguarded async callbacks crash the whole process, not just one request
- **Context:** Production register/login outage: POST /api/register 500, POST /api/login 502, GET /api/user 401. Root cause was in passport-local's LocalStrategy verify callback and passport.deserializeUser (Node/Express + Passport.js), but the failure class is general to any async callback a library invokes without awaiting/catching it.
- **Lesson:** An async callback whose rejection nothing awaits or catches becomes an unhandled promise rejection, and Node exits on that by default. If the host platform auto-restarts on failure (e.g. Railway's ON_FAILURE policy), the symptom looks like intermittent 502s for ALL users, not a clean error for the one request that failed — that mismatch (one bad request, everyone affected) is the tell. Fix: wrap every async Express/framework route handler and every async callback passed to a library that doesn't await it (passport strategies, event emitters, etc.) in try/catch, resolving errors through the framework's normal error channel (next(err), done(err)) instead of letting them throw uncaught. A small asyncHandler(fn) => (req,res,next) => fn(req,res,next).catch(next) wrapper applied to all routes closes this for an entire Express app in one pass.
- **Trigger:** unhandled promise rejection, unhandled rejection, passport, passport-local, async callback, express route handler, node process crash, 502, asyncHandler, deserializeUser, done(err), next(err)
