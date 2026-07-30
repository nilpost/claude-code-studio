---
description: Assess whether a project passes a stage gate, on evidence (G1–G5).
---

Start by telling me in one sentence what you're about to do, then proceed.

Assess whether a project passes a stage gate. Arguments are `<project> <G1|G2|G3|G4|G5>`;
if the gate is omitted, use the project's `gate_next` from `portfolio.json`.

Read `CHARTER.md` §5 for the gate's definition and owner, then delegate the assessment to
that owner: G1 → `strategy`, G2/G5 → `growth`, G3 → `po`, G4 → `consultant`.

**Assess on evidence, not on assertion.** A document claiming something is done is not
evidence for its own claim — check the commit, the CI run, the real endpoint, the actual
test execution. Return one of PASS, FAIL, or INSUFFICIENT EVIDENCE, and when it is not a
PASS, name the specific missing evidence and the cheapest way to get it.

Report the verdict to me and update `portfolio.json` only after I ratify a promotion —
gate promotions are mine to approve, not yours to record.

$ARGUMENTS
