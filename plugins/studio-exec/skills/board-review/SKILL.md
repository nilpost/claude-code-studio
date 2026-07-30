---
name: board-review
description: Run the studio's weekly board review — triage the inbox, assess gates, review the token budget, surface decisions for the founder, and update portfolio state. Use once a week, or when the portfolio needs a reset after a gap. This is the studio's heartbeat; everything else feeds it.
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit
---

# board-review

The weekly ritual that turns a pile of projects into a governed portfolio. It is the only
scheduled meeting the studio has, and if it stops happening the portfolio state goes stale
and the cockpit starts lying.

Budget it at roughly **15% of the weekly token allocation**. If it is costing more,
delegate less and read less.

## Locating the ops repo

Resolve in order, stop at the first hit:

1. `$STUDIO_OPS_DIR`
2. a `studio-ops` directory beside or above the current working directory
3. ask the human

If it cannot be found, **stop**. Do not reconstruct portfolio state from the filesystem — a
review against imagined state is worse than no review, because it gets believed.

## Steps

### 1. Orient (cheap — read only these)

- `CHARTER.md` — the rules you are about to apply. Re-read, don't recall.
- `portfolio.json` — canonical state.
- `INBOX.md` — untriaged items.
- `TOKENS.md` — allocation and last week's actuals.
- the most recent file in `reviews/`.

Check the gap since the last review. **If two or more reviews were missed, declare the
state untrustworthy** and make step 3 mandatory before anything in step 5 is acted on.

### 2. Sync intake

Run the `portfolio-sync` skill if a Trello board or other capture surface is configured, so
`INBOX.md` is complete before triage. Skip silently if nothing is configured.

### 3. Assurance

Read the most recent `consultant --mode assurance` report — normally produced by CI before
the review, so it costs nothing against the interactive budget.

If there is no recent report, or the state was declared untrustworthy in step 1, run one
now:

> Delegate to `consultant`, mode `assurance`, scoped to ACTIVE and SHIP-BLOCKED projects.

Audits of different projects are independent, so these may run **in parallel**. Nothing
else in this review may.

Carry the findings forward **verbatim**. Do not summarise a finding away.

### 4. Triage and assess

Delegate to `strategy`: triage every `INBOX.md` item to exactly one outcome, assess gates,
and produce kill recommendations against `CHARTER.md` §6.

Delegate to `growth` **only if** a project has a `revenue_status` other than `none`, or a
G2/G5 assessment is due. Otherwise skip it — an empty growth report costs tokens and says
nothing.

These two are independent of each other and may run in parallel.

### 5. Decide (human)

Present, in this order:

1. **Decisions needed** — each with a recommendation and the evidence behind it.
2. **Assurance findings** — verbatim, contradictions first.
3. **Next week's ACTIVE 2** — proposed, with what is being demoted to make room.
4. **Blocked-on-human items** — these need no budget, only a person, and are usually the
   highest-leverage thing on the page.

The human decides kills, gate promotions, and the ACTIVE set. Never record a decision the
human did not actually make.

### 6. Write back

1. Update `portfolio.json`: stages, `gate_next`, blockers, `last_review`, token actuals.
2. Run `node scripts/render-portfolio.mjs`. It validates the WIP limit and that every
   ACTIVE project has a gate. **If it fails, fix the state — never bypass the check.**
3. Write `reviews/YYYY-Www.md` using the template below.
4. Write a `decisions/YYYY-MM-DD-<slug>.md` for each real decision. Decision records are
   immutable; a change of mind is a new record that supersedes the old one.
5. Append the week's actuals to the `TOKENS.md` table.
6. Mark triaged inbox items `[x]` with where they went. Never delete an item.
7. Commit and push. An unpushed ops repo is an unbacked one.

## Review template

```markdown
# Board review — YYYY-Www

**Date:** YYYY-MM-DD · **Weeks since last review:** N

## Position
[stage counts, budget position, what moved since last time]

## Assurance
[consultant findings verbatim, or "no engagement this cycle" — contradictions first]

## Decisions taken
[what the human actually decided → link to the decisions/ record]

## ACTIVE next week
[the 2, and what each is trying to pass]

## Blocked on a human
[items needing a person, not a budget]

## Deferred
[what was considered and deliberately not done — and why]
```

## Rules

- **Never fabricate a decision.** If the human did not answer, it stays open and carries to
  next week. An unanswered question recorded as a decision is the fastest way to make this
  whole system untrustworthy.
- **Serialise within the review; parallelise only across independent projects.** Steps 3
  and 4 each fan out; the steps themselves run in order.
- **Do not read project source code.** Work from portfolio state and agent reports. If a
  decision hangs on a technical fact, delegate that one question.
- **Keep it short.** A review nobody reads is a review that did not happen.
