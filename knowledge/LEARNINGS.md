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

## 2026-07-17 — E-Companion — Sandboxed/cloud sessions can't reach production URLs or hosting dashboards
- **Context:** Asked to verify a Railway-hosted deploy went live by curling the production URL and via WebFetch.
- **Lesson:** Claude Code web/agent sessions commonly run behind an outbound proxy with a fixed allowlist that does not include arbitrary production domains or third-party dashboards/APIs (hosting platform, DB provider, CDN), and the session usually has no credentials for them either. Both curl and WebFetch will fail (e.g. a 403 at the proxy's CONNECT step) — that failure happens at the sandbox's network layer, not the application, so never report a live site as "down" or a deploy as "confirmed live" on that basis. Say plainly that live verification isn't possible from the current session, and point to the actual fix: the human checks the dashboard directly, or the session's environment network policy gets widened (see https://code.claude.com/docs/en/claude-code-on-the-web).
- **Trigger:** curl 403, WebFetch 403, CONNECT tunnel failed, proxy, network policy, production URL, verify deploy, cannot reach, dashboard credentials, sandboxed network

## 2026-07-17 — E-Companion — Unguarded async callbacks crash the whole process, not just one request
- **Context:** Production register/login outage: POST /api/register 500, POST /api/login 502, GET /api/user 401. Root cause was in passport-local's LocalStrategy verify callback and passport.deserializeUser (Node/Express + Passport.js), but the failure class is general to any async callback a library invokes without awaiting/catching it.
- **Lesson:** An async callback whose rejection nothing awaits or catches becomes an unhandled promise rejection, and Node exits on that by default. If the host platform auto-restarts on failure (e.g. Railway's ON_FAILURE policy), the symptom looks like intermittent 502s for ALL users, not a clean error for the one request that failed — that mismatch (one bad request, everyone affected) is the tell. Fix: wrap every async Express/framework route handler and every async callback passed to a library that doesn't await it (passport strategies, event emitters, etc.) in try/catch, resolving errors through the framework's normal error channel (next(err), done(err)) instead of letting them throw uncaught. A small asyncHandler(fn) => (req,res,next) => fn(req,res,next).catch(next) wrapper applied to all routes closes this for an entire Express app in one pass.
- **Trigger:** unhandled promise rejection, unhandled rejection, passport, passport-local, async callback, express route handler, node process crash, 502, asyncHandler, deserializeUser, done(err), next(err)
