# Qwen leg (writer) - AI stack review, Nov 7, 2026

- Chat: https://chat.qwen.ai/c/70ff991a-4665-4795-aa6a-d97a7cacb961
- Gates (confirmed by the runner): selector showed Qwen3.8-Max before sending; chat header still showed Qwen3.8-Max after generation. Single response generated (no parallel pair offered). No CAPTCHA.
- Chair note: the leg's own header dates itself "8 Nov 2026"; the run happened Nov 7, 2026 (Chicago). Date slip only; content tracks the pack.
- Filed verbatim below (dash-normalized by the chair).

---

Qwen Leg Report - PACK Review, 8 Nov 2026

Q1 - Workhorse Configuration

Recommendation: Endorse the chair's pick. OpenCode (harness) + Kimi Code Pro key ($39/mo, primary endurance model) + DeepSeek V4.1 Flash API direct (pay-as-you-go, secondary/bulk model).

Reasoning drawn from the pack:

OpenCode is MIT, ships a Windows desktop app plus headless and server modes, supports 75+ providers and subagents, and can accept both Anthropic-format and OpenAI-format endpoints. This is the only harness in the pack that satisfies all three constraints simultaneously: (a) programmatic dispatch for fire-and-forget, (b) native Windows presence for Ryan's no-terminal preference, and (c) multi-provider so the same seat runs Kimi and DeepSeek without a second installation.

Kimi Code Pro at $39/mo ($31 billed annually) offers a rolling 5-hour limit with no weekly limit on new plans, 1M context, and a specialization in long-horizon endurance work (SWE Marathon leader at 51.7 vs Opus 46.3). The subscription key is officially usable in third-party harnesses; OpenCode ships a built-in "Kimi For Coding" provider. This removes integration risk.

DeepSeek V4.1 Flash at $0.30/$1.20 per 1M tokens (halved off-peak) is the cheapest credible coder in the pack. The Artificial Analysis cost-per-task anchor is ~$0.60/task. A typical solo-dev month is estimated $3.60-$7.95. This absorbs the volume of standard and bulk jobs so the Kimi credit pool is reserved for jobs that actually need endurance or 1M context.

The arXiv 2610.04433 study shows same-model score differences across Claude Code, OpenCode, and mini-SWE-agent are mostly within rerun noise (~13% flip rate). Harness choice is therefore a secondary factor; the primary lever is model-and-key economics.

Strongest argument against my own pick: OpenCode showed the one above-noise trailing effect in the arXiv study - up to 9 points behind on the large SWE-bench Verified pool. If Voidsworn's Godot/GDScript tasks correlate with the conditions that produced that trailing (large multi-file patches, deep repo context), the workhorse could systematically underperform and inflate Opus's review burden, which is the exact metric the trial is supposed to catch. No Godot-specific benchmark exists to rule this out in advance. The pack is explicit that the project's own trial job is the only direct evidence available, so this risk is real and unresolvable until the trial runs.

Rejected alternatives and why, per the pack: Kimi's own CLI is a Kimi-only seat (no DeepSeek fallback in the same harness); Cursor and Windsurf/Devin Desktop are editors built for a human who codes, with usage pools and daily/weekly quotas that conflict with Ryan's no-editor, fire-and-forget workflow; ClinePass carries 5-hour + weekly + monthly limits (poor fit); Crush has the best native PowerShell story but is FSL-licensed and adds no multi-provider advantage over OpenCode; Goose is viable but the pack provides less evidence of its headless dispatch maturity; DeepSeek Harness (dsh) is MIT but explicitly a developer preview with promised breaking changes, no security audit, and unsandboxed plugins - its models are equally available inside OpenCode without the preview risk.

Q2 - Claude Max: Keep or Downgrade?

Keep the $100 Max through the settlement queue. Do not downgrade now.

The deciding factor is the reviewer bottleneck. Opus is the sole reviewer of every PR in the R75 workflow. The pack records one observed cap event on the $100 Max plan during the Nov 5 sprint week, and that occurred while Opus was already double-hatted (board orchestration + absorbing Codex's absent jobs). Pro is roughly one-fifth of Max's 5× allowance. If Opus caps on Pro, every seat behind it stalls - the workhorse pushes branches, but nothing merges, and Ryan's board freezes. The settlement queue is live and heavy: five audit settlement programs, a benchmark, and a build comparison. Downgrading into that queue is downgrading into the highest-demand window for the reviewer.

The pack's own sequencing rule supports this: "Claude downgrade last, only on evidence." The evidence required is (a) the settlement queue drained, and (b) Codex returned (removing the double-hat pressure that triggered the only observed cap). Neither condition is met as of Nov 8. The $80/month delta between Max and Pro buys insurance against a board stall that would cost more in lost sprint time than the subscription saving.

Q3 - Sequence and Trial Design

The chair's sequence is correct. (a) Kimi Pro trial first, because the workhorse vacancy is the operational gap; (b) the Muse free-plan test on Nov 26/27 is already scheduled and costs nothing to run; (c) the Claude downgrade decision comes last, after the queue drains and after the trial produces data. Reordering any of these would either delay filling the vacancy or force the downgrade decision on incomplete evidence.

Trial job design:

The job must discriminate between the Kimi endurance path and the DeepSeek bulk path, and must stress the exact failure mode the pack flags (review burden from a weak workhorse PR).

Job: A bounded, multi-file Godot 4.7 feature ticket on the Voidsworn repo. Concretely: add one new fleet-tactics mechanic (e.g., a new ship module with a stat, a UI panel, a save/load integration, and a unit test). This touches GDScript, a .tscn scene, the project.godot resource file, and at least one autoload singleton - four-plus files across different subsystems. It is the shape of job Codex was doing before it went down.

Why this discriminates: A single-file or single-function job would not test endurance or 1M context. A full new game mode would be too large for a bounded trial. A four-file cross-subsystem feature is the minimum scope that exercises multi-file coherence, GDScript-specific patterns, and the Godot scene/resource pipeline. If the workhorse produces a PR that Opus can merge with minor comments, the configuration passes. If Opus must rewrite or reject, the review-burden metric flags it.

Run each configuration once: (i) OpenCode + Kimi Code Pro key; (ii) OpenCode + DeepSeek V4.1 Flash API. Same issue text, same branch naming, same PR template.

Measure exactly four things:

Review burden: number of Opus review passes to merge, and whether Opus's comments are "nit" or "structural rewrite." This is the primary metric per the pack.

Cost actually logged: the real token/credit charge on the Kimi account and the DeepSeek account for this one job. The pack is explicit that vendor figures are unmeasured until a real transaction logs them.

Wall time: elapsed from issue dispatch to PR opened. This tests the endurance claim and the rolling 5-hour window.

Defect count: issues opened against the merged PR within 48 hours (build failures, runtime errors in Godot, save/load corruption). Ryan judges by PRs and screenshots; a screenshot of the new module running in-engine is the acceptance gate.

Q4 - Dispatch Architecture

Endorse the fire-and-forget board-to-OpenCode-to-PR pattern. Do not add an in-the-loop supervisor.

The pack's logic is sound: Opus's allowance is the scarcest resource in the stack. If Opus (or Rey) sits in the loop supervising steps, every workhorse job burns reviewer tokens on babysitting, reproducing the exact double-hat condition that caused the Nov 5 cap. The R75 issue format (Owner, Brief, Deliver to, Branch, Models, Done when) already provides the contract; the workhorse executes, pushes, and opens a PR; Opus reviews the diff once. No intermediate checkpoints.

T3 Code: adopt later as a free supervision layer, not now. It is MIT, free, adds no model capacity and no caps, and provides a worktree-per-thread view with one-click PR. Its value is giving Ryan a visual "what is the agent doing" surface without requiring him to open a terminal. But it adds no dispatch capability the headless OpenCode + GitHub Actions PR workflow does not already provide, and introducing it simultaneously with the new workhorse and new model keys would confound the trial. Layer it after the trial confirms the base pattern works. INFERRED: T3 Code's value is primarily Ryan's peace of mind as a non-coder watching agents, not a functional improvement to the pipeline.

The one alternative I considered and reject: a two-pass dispatch where a cheap model (DeepSeek Flash) drafts the PR and Opus rewrites it. This doubles the compute per job, inflates cost, and makes the cheap model's output quality irrelevant because Opus replaces it. The whole point of the workhorse is to produce a mergeable PR, not a rough draft.

Q5 - Missed Risks (up to three)

Kimi's shared monthly credit pool is opaque and non-rolling. The pack states Moonshot publishes no absolute token count per tier, the pool is shared across all Kimi features on the account, there is no rollover, and overflow hits pay-as-you-go Extra Usage. This means the $39 Pro tier's real capacity is unknown until Ryan burns through it. If the pool is tight, Kimi could exhaust mid-month during the settlement queue, silently shifting all workhorse load to DeepSeek Flash (which may not handle endurance jobs) or stalling the board. Falsifiable: the trial job's logged credit draw, extrapolated against the queue's remaining job count, will show whether the pool survives a full month. If it does not, the Kimi Pro tier is insufficient and the chair's pick fails on capacity, not quality.

Single-workhorse dependency with no hot spare. Codex is down. The new OpenCode + Kimi/DeepSeek seat is the only local execution path. If Kimi's API has an outage, or OpenCode hits a Windows-specific bug (the pack notes the GLM-5.2 harness-model fit variance as evidence that harness-model interactions can matter), Ryan has zero local coding capacity until the issue resolves. The pack does not name a fallback workhorse. Falsifiable: if the trial job cannot complete due to an OpenCode or Kimi API failure, this risk is confirmed. Mitigation would be keeping Crush or Cline installed as a cold spare at zero marginal cost.

The arXiv 3× cost variance between harnesses is uncontrolled. The study found cost per task differed up to 3× between harnesses for the same model, driven by context overhead per step. The pack cites this but the chair's lean does not specify a token-budget or step-cap policy for OpenCode. If OpenCode's context overhead is on the high side, Kimi's opaque credit pool will drain faster than the SWE Marathon benchmark suggests, and DeepSeek's pay-as-you-go bill will exceed the $3.60-$7.95 solo-dev-month estimate. Falsifiable: the trial's logged cost vs. the Artificial Analysis cost-per-task anchor ($3.68 for Kimi, $0.60 for Flash) will reveal the harness overhead multiplier. If actual cost exceeds 2× the anchor, the harness is adding unacceptable overhead.

Closing: Final Recommended Stack

| Seat | Product | Monthly Cost |
|---|---|---|
| Reviewer / board owner / code truth | Claude Max (Opus 5.5) | $100 |
| Workhorse harness | OpenCode (free, MIT) | $0 |
| Workhorse primary model | Kimi Code Pro key | $39 |
| Workhorse secondary model | DeepSeek V4.1 Flash API (pay-as-you-go) | ~$4-$8 (est.) |
| Cross-model checker | ChatGPT Plus | $20 |
| Synthesis / audit / personal agent | Muse Power (through Nov 26; free test after) | $20 |
| Free council legs | Qwen, DeepSeek chat, Gemini | $0 |
| Supervision layer (later) | T3 Code (free, MIT) | $0 |
| Total |  | ~$183-$187/mo |

The ~$43-$47/mo increase over the current $140 is the Kimi Pro subscription plus the estimated DeepSeek API spend, filling the Codex vacancy. The ChatGPT Plus and Muse Power lines are unchanged and were already in the current stack.

Confidence: Medium.

The one observation that would most change my answer: the trial job's logged Kimi credit draw. If a single bounded four-file Godot job consumes more than ~8-10% of the monthly credit pool, the pool will not survive a full month of the settlement queue at current job volume, and the Kimi Pro tier is wrong for this workload - at which point the workhorse should shift to DeepSeek V4 Pro API (pay-as-you-go, $1.32/$3.96 peak, ~$1.77/task) as primary, with Kimi demoted or dropped, and the total monthly cost drops closer to $150. Conversely, if the draw is under 5%, the chair's configuration is confirmed and my confidence moves to high.
