# studio-exec

An **executive layer** above `studio-core`'s delivery agents, for running several projects
as a governed studio rather than a folder of side projects.

`studio-core` answers *how do we build this*. `studio-exec` answers *should we, which one,
and is it actually working*.

## The shape

```
HUMAN — founder / board .............. decides. Holds credentials. Kills projects.
  │
  ├─ chief-of-staff .................. single entry point; weekly ritual, routing,
  │    │                               WIP limit and budget enforcement
  │    ├─ strategy ................... portfolio gates, kill calls, ideation      (G1)
  │    ├─ growth ..................... validation, pricing, distribution      (G2, G5)
  │    └─ po  (studio-core) .......... delivery — unchanged                       (G3)
  │
  └─ consultant ...................... independent assurance, reports to the human (G4)
```

`consultant` deliberately sits **outside** the chain. It is the third line of defense: `po`
may never invoke it, and `chief-of-staff` may schedule it but not scope its findings. An
auditor that can be tasked by the thing it audits is not an auditor.

## Why only four agents

Multi-agent systems cost roughly an order of magnitude more tokens than a single agent, and
token spend is the dominant driver of both cost and quality. For a studio whose binding
constraint is a fixed weekly ceiling, every agent has to earn its context window.

So the roles that are **judgment** became agents, and the roles that are **cadence and
arithmetic** became documents and commands:

| Traditional role | Realized as |
|---|---|
| CEO | `strategy` agent |
| CMO / Revenue | `growth` agent |
| CTO | `po` (already in studio-core) |
| Chief Audit Executive | `consultant` agent |
| CFO | `TOKENS.md` budget policy + `consultant --mode finance` |
| COO | `/board-review` + the WIP limit rule |
| Board | the human + an immutable `decisions/` log |

## Contents

| | |
|---|---|
| `agents/chief-of-staff.md` | Orchestrator. The only agent here with the `Agent` tool. |
| `agents/strategy.md` | Allocation, gates, kill recommendations, opportunity scan. |
| `agents/growth.md` | Validation experiments, pricing, distribution. |
| `agents/consultant.md` | Independent assurance in four engagement modes. |
| `skills/board-review/` | The weekly ritual — the studio's heartbeat. |
| `skills/portfolio-sync/` | Intake surfaces (e.g. Trello) ⇄ inbox ⇄ portfolio state. |
| `commands/board-review.md` | `/board-review` |
| `commands/gate.md` | `/gate <project> <G1..G5>` |

## The ops repo

These agents read and write **business state that does not live here**: the portfolio, the
charter, decisions, and the token budget. That state belongs in a separate repo — usually
private — because the methodology is shareable and the portfolio is not.

Point the agents at it with:

```bash
export STUDIO_OPS_DIR=/path/to/your-ops-repo
```

Otherwise they look for a `studio-ops` directory beside or above the working directory, and
if they cannot find one they **stop and ask** rather than inventing state.

Minimum contents:

| File | Purpose |
|---|---|
| `CHARTER.md` | WIP limit, decision rights, stage-gate definitions, kill criteria |
| `portfolio.json` | Canonical machine state, one entry per project |
| `TOKENS.md` | Budget allocation and weekly actuals |
| `INBOX.md` | Append-only intake |
| `decisions/` | Immutable decision records |
| `reviews/` | Weekly board review output |

## Using it

```
@chief-of-staff  what should we work on this week?
/board-review
/gate Invoice_Generator G4
```

Use `po` directly for work inside one project — routing single-project delivery through the
exec layer just adds a context window for no benefit.

## Design constraints worth knowing

1. **Parallelism buys wall-clock, never tokens.** Concurrent agents each re-read context.
   Parallelise across independent projects and read-only audits; serialise within a feature,
   where agents share an API contract and will otherwise invent conflicting versions of it.
2. **Only `chief-of-staff` and `po` can fan out.** Fan-out is a priced operation, kept where
   the independence test is explicitly applied.
3. **Agents recommend; the human decides.** No agent may kill a project, spend money,
   use credentials, or publish anything.
4. **Gates pass on evidence.** A green CI run proves a workflow ran. G4 requires that
   someone fetched the real URL.

See [`docs/ORG-CHARTER.md`](../../docs/ORG-CHARTER.md) for the full model and
[`docs/PRIOR-ART.md`](../../docs/PRIOR-ART.md) for sources — most of the ideas here are
borrowed, and credited there.
