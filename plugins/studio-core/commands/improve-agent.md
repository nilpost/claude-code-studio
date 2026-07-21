---
description: Bake a behavioral lesson into a specific studio agent's definition (runs improve-agent).
---

A studio agent made a mistake or was corrected. Using the `improve-agent` skill,
turn that into a terse behavioral directive and bake it into that agent's own
definition file so the corrected behavior sticks.

Identify which agent it was, phrase the fix as an imperative directive, append it
under that agent's `## Lessons learned` section, and commit. If the lesson is also
general (not tied to one agent), additionally capture it in the shared knowledge
base via `capture-learnings`.

$ARGUMENTS
