# The studio operating model

A reusable template for running several software projects as a governed portfolio with one
human and a fixed AI budget. `studio-exec` is the agent implementation; this document is
the model it implements, so you can adopt it, argue with it, or adapt it.

Sources for everything borrowed here are in [`PRIOR-ART.md`](PRIOR-ART.md).

---

## The problem it solves

A capable operator with AI assistance accumulates projects faster than they can finish
them. The result is a folder of things that are each "nearly done", none of which reaches
a user, because nothing ever decides which one deserves the next hour.

Three specific failures follow:

1. **No allocation mechanism.** Attention goes to whatever is most interesting today.
2. **No independent check.** "Deployed" means a workflow went green, not that anyone
   fetched the URL. Status documents assert their own truth.
3. **No stopping rule.** Nothing is ever killed, so nothing is ever properly funded.

## The constraint that shapes everything

For a solo operator on a subscription, the scarce resource is **tokens**, not time and not
money. That inverts the usual advice.

Most public multi-agent architectures assume API billing: tokens are money, time is scarce,
so fanning out ten agents is rational. Under a fixed weekly ceiling the reverse holds —
time is nearly free and the ceiling is hard. Same technique, opposite conclusion.

Two consequences run through the whole model:

- **Every agent must earn its context window.** Multi-agent systems cost roughly an order
  of magnitude more tokens than a single agent, and token spend dominates outcome quality.
  So roles that are *judgment* become agents; roles that are *cadence and arithmetic* become
  documents and commands.
- **Parallelism buys wall-clock, never tokens.** Concurrent agents each re-read context.
  Running four sessions in four terminals does not grant four budgets — one account, one
  bucket, drained four times faster.

## The four roles that justify an agent

| Role | Why it needs judgment |
|---|---|
| **chief-of-staff** | Routing and enforcement under a budget; deciding what *not* to do |
| **strategy** | Allocation and kill calls — the decisions most distorted by sunk cost |
| **growth** | Distinguishing interest from intent from commitment |
| **consultant** | Independent verification, which by definition cannot be self-service |

Everything else becomes an artifact: the CFO is a budget file plus a finance engagement,
the COO is a weekly command plus a WIP rule, the CTO is the existing delivery orchestrator,
and the board is a human plus an immutable decision log.

## Three lines of defense

Borrowed directly from risk governance, and the reason the model is trustworthy at all:

| Line | Who | Role |
|---|---|---|
| First | delivery agents | Own the work, operate the controls |
| Second | chief-of-staff, strategy, growth | Set standards and budget, challenge, monitor |
| Third | consultant | Independently verify that the first two are telling the truth |
| Board | the human | Decide |

The load-bearing rule: **the third line cannot be tasked by what it audits.** The delivery
orchestrator may never invoke the consultant, and the chief-of-staff may schedule it but not
scope its findings. Without that, assurance degrades into self-report.

## Stage gates

```
IDEA ──▶ VALIDATE ──▶ BUILD ──▶ SHIP ──▶ MONETIZE ──▶ SCALE
           │            │        │          │
           └────────────┴────────┴──────────┴──▶ PARKED / KILLED
```

| Gate | Passes on | Owner |
|---|---|---|
| G1 | A named user, a named pain, a channel that reaches them | strategy |
| G2 | ≥20 qualified signups, or ≥3 who committed to pay | growth |
| G3 | Builds, tests green, **verified by running**, security pass | delivery |
| G4 | Live URL independently verified — the endpoint, not the CI badge | consultant |
| G5 | First revenue from someone who is not the founder | growth |

**Gates pass on evidence, never on assertion.** G4 exists as a separate gate specifically
because "the deploy workflow is green" and "the product works" are different claims, and
conflating them is the most common way a portfolio starts lying to its owner.

## The WIP limit

**At most two projects active at once.** This is the highest-leverage rule in the model and
the one most likely to be quietly broken.

It is a budget rule, not an ambition rule: switching projects means re-reading project
context, and re-reading context is the largest avoidable token cost. Everything not active
is maintained, parked, or killed. There is no "sort of working on it" state — that state is
what produces fourteen half-projects.

## Killing

A project is a kill candidate when any one of these holds:

1. It duplicates the domain of a more advanced project.
2. It has no named user, and none can be named at review.
3. It has been parked across three reviews with no new evidence.
4. Its next gate costs more than can be allocated this quarter.
5. It is a fork or scaffold never meaningfully modified.

Killing is the mechanism that funds the survivors. A studio's structural advantage over a
solo founder is precisely that it kills early and without attachment — but the decision
belongs to a human, because it is the one most likely to be regretted.

Always name what to **salvage** first. Killing a project should not discard its parts.

## The heartbeat

One weekly ritual. Everything feeds it, and if it stops the portfolio state goes stale and
the cockpit starts lying.

```
Continuous  →  inbox (append-only)  ←  mobile capture
Pre-review  →  assurance pass in CI (off the interactive budget)
Weekly      →  board review  →  decisions + updated portfolio state
```

**If two consecutive reviews are missed, portfolio state must be treated as untrustworthy
until an assurance pass re-verifies it.** A dashboard showing stale data is worse than no
dashboard, because it gets believed.

## Adopting it

1. Create an ops repo — **outside any cloud-synced folder**, with a remote from the first
   commit. Sync clients corrupt git object stores, and with no remote there is no recovery.
2. Write `CHARTER.md`: your WIP limit, decision rights, gates, kill criteria.
3. Seed `portfolio.json` with every project you have, honestly staged.
4. Set `STUDIO_OPS_DIR` and enable `studio-exec`.
5. Run `/board-review`. Expect the first one to be uncomfortable — it is the first time the
   portfolio has been looked at as a whole.

## What this model is not

- **Not a way to build faster.** It is a way to build fewer things, further.
- **Not autonomous.** Agents recommend; a human decides every kill, gate, and spend. An
  organisation that can kill its own projects is not one you want running unattended.
- **Not free.** Four extra agents cost tokens. The WIP limit and the CI-offloaded audit are
  what pay for them. If those slip, this becomes expensive quickly.
- **Not proven.** It is assembled from frameworks that work at larger scale, applied at
  n=1. Treat the model itself as a project at G1.
