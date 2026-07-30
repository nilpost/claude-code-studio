# Prior art and attribution

Almost nothing in this studio is original. This file records where the ideas came from, so
credit sits with the people who did the work.

Where a figure came to us through secondary reporting rather than a primary source, that is
marked **[secondary]** — those numbers should be re-verified before anyone leans on them.

---

## 1. Agent catalogues

| Source | License | What we took |
|---|---|---|
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | MIT | The category taxonomy for a large agent library — 154+ agents across 10 categories, including *Business & Product* (16) and *Meta & Orchestration* (13). We took the idea of separating business-layer agents from delivery agents. Notably it contains **no CEO, CTO, or finance agent** — that absence is the gap `studio-exec` fills, and confirming it was worth doing. |
| [haddock-development/claude-reflect-system](https://github.com/haddock-development/claude-reflect-system) | — | The "learnings file → feedback → write-back" loop that `capture-learnings` / `recall-learnings` implement. |
| [wshobson/agents](https://github.com/wshobson/agents) | — | Ready-made agent catalogue, referenced for role coverage. |
| [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) | — | Plugin + skill packaging patterns. |
| [claude-market/marketplace](https://github.com/claude-market/marketplace) | — | Marketplace distribution patterns. |

## 2. Architecture — the multi-agent debate

We deliberately read both sides, and the design takes from each. This disagreement is the
single biggest influence on why `studio-exec` has four agents instead of eighteen.

**[Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)**
- The **orchestrator-worker pattern**: a lead agent coordinates while specialised subagents
  operate in parallel and return condensed findings. This is the shape of `chief-of-staff`
  → `strategy`/`growth`/`po`, and of `po` → its own specialists.
- Multi-agent systems use on the order of **15× the tokens** of a single chat interaction,
  and **token usage explains ~80% of performance variance**. This is why every agent in
  `studio-exec` has to justify its context window, and why CFO/COO/CTO became documents.
- Architecture should follow task structure: multi-agent wins only when work genuinely
  decomposes into independent parallel threads. Directly encoded as the independence test
  in `TOKENS.md` §4.

**[Cognition — Don't Build Multi-Agents](https://cognition.com/blog/dont-build-multi-agents)**
- Two principles: *share context, and share full agent traces, not just individual
  messages*; and *actions carry implicit decisions, and conflicting decisions carry bad
  results*.
- The failure mode: parallel subagents cannot see each other's work, so they make
  conflicting implicit decisions the orchestrator cannot reconcile afterwards. This is why
  `studio-exec` serialises within a feature and restricts the `Agent` tool to two agents.
- **Context engineering** as the primary discipline, over adding more agents.

**[Cognition — Multi-Agents: What's Actually Working](https://cognition.com/blog/multi-agents-working)** ·
**[LangChain — How and when to build multi-agent systems](https://www.langchain.com/blog/how-and-when-to-build-multi-agent-systems)**
- The more nuanced follow-ups: manager-with-children patterns work when coordination is
  invested in explicitly.

## 3. Org-simulation frameworks — studied, not adopted

These model a company as agents. We borrowed ideas and rejected the runtimes, because each
would add a stack alongside Claude Code and multiply token spend.

| Framework | Idea | Why not adopted |
|---|---|---|
| [ChatDev](https://github.com/OpenBMB/ChatDev) | A virtual software company: CEO, CTO, programmer, designer, tester, reviewer, driven through an SDLC by inception prompting | Fixed waterfall roles, one context window each, and no portfolio concept. The full-C-suite design we rejected. |
| [MetaGPT](https://github.com/geekan/MetaGPT) | Role-based SOPs with a **shared message pool** so agents publish structured output others can read | The shared message pool is the good idea, and we took it — `portfolio.json` is exactly that, minus the runtime. |
| [CrewAI](https://github.com/crewAIInc/crewAI) | Hierarchical process mode with an auto-generated manager agent delegating to specialists | `chief-of-staff` covers this natively in Claude Code. |

## 4. Governance

**[Three Lines of Defense Against Risks from AI — GovAI](https://www.governance.ai/research-paper/three-lines-of-defense-against-risks-from-ai)**
([journal version](https://link.springer.com/article/10.1007/s00146-023-01811-0))
The risk-governance model — first line owns and operates controls, second line sets
standards and challenges, third line provides independent assurance to the board. This is
the entire justification for `consultant` sitting outside the delegation chain, and for the
rule that `po` may never invoke it.

**Stage-Gate and the venture studio model** —
[Stage-Gate innovation process](https://umbrex.com/resources/frameworks/strategy-frameworks/stage-gate-innovation-process/) ·
[Venture Studio Forum](https://newsletter.venturestudioforum.org/) ·
[Venture studios beyond the hype (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S0007681325001417)
Evidence-based Go/Kill gates with quantitative thresholds, and the argument that a studio's
structural advantage is acting as a quality filter that kills weak ideas before they
launch. This is `CHARTER.md` §5 and §6. **[secondary]** Commonly cited studio outcome
figures (Series A rates and time-to-Series-A) come from studio-industry sources and should
be treated as advocacy until independently checked.

## 5. Validation and monetization

**MicroConf / Rob Walling's five criteria** — product, price, market, marketing channel,
monetization potential; and the validate-before-build sequence (landing page → signups →
past-behaviour interviews → paid beta). Encoded in `growth.md`'s G2 definition.

**Pricing-model shift, 2026 [secondary]** — seat-based pricing reported falling from ~21%
to ~15% of SaaS companies within twelve months while hybrid rose from ~27% to ~41%, with
outcome-based billing emerging (e.g. per-resolution pricing in customer support). Sourced
from vendor and analyst blogs, not primary research; the *direction* informed `growth.md`'s
pricing table, and the specific percentages should be re-verified before external use.

**Micro-SaaS base rates [secondary]** — commonly reported that a large majority of
micro-SaaS products earn under $1k/month and that meaningful revenue takes 12–18 months.
Used as a sober prior in `growth.md`, not as a precise figure.

## 6. Operational mechanics

- [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — separate context
  windows per subagent; the mechanism behind "delegate for context isolation".
- [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) ·
  [plugins](https://code.claude.com/docs/en/plugins) ·
  [skills](https://code.claude.com/docs/en/skills) — how this repo distributes.
- [OpenTelemetry observability](https://code.claude.com/docs/en/agent-sdk/observability) —
  Claude Code emits token, cost, and session metrics natively. Evaluated for the cockpit and
  deferred: it shows spend, not project health.
- **Token limits and the non-interactive credit pool [secondary]** — the 5-hour rolling
  window and weekly cap, shared across Claude Code, claude.ai and Cowork; and the reported
  2026-06-15 change routing non-interactive usage (`claude -p`, GitHub Actions, Agent SDK)
  to a separate monthly credit pool. `TOKENS.md` §5 depends on the latter and flags it as
  requiring verification against the actual subscription.

---

## Adding to this file

If you bring in an idea, a framework, a figure, or code that you did not originate, add it
here in the same commit. Mark anything that reached you through secondary reporting. An
attribution file that is merely *mostly* complete is not an attribution file.
