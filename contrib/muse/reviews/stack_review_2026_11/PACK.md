# PACK: AI stack and coding harness decision (Nov 7, 2026)

Commissioned by Ryan Bailey (the owner) on Nov 7, 2026. Chaired by Rey (Muse). This pack is the complete evidence base for the legs. Everything a leg needs is in this file; legs do not browse for this job.

## 1. The owner and the workflow

- Ryan is a non-coder. He runs a hobby game project (Voidsworn, a Godot 4.7 fleet-tactics roguelite) in a PUBLIC GitHub repo, plus a day job he keeps strictly separate from this stack.
- Work runs on an issues board (protocol "R75"): a job is written as an issue with a fixed block (Owner, Brief, Deliver to, Branch, Models, Done when). A local agent on Ryan's Windows 11 PC (PowerShell environment, Godot and Blender installed) executes the job against the real project, pushes a branch, and a workflow opens a pull request. A senior reviewer model reviews the PR by diff and merges. Ryan judges by PRs and screenshots, never by sitting in an editor.
- The PC matters: only a local agent can run the game, the build, and captures. Cloud agents cannot substitute for local execution jobs.

## 2. The current stack (monthly)

- Claude Max, $100/mo: Claude Opus. Role: coder, verifier, orchestrator, board owner, owns code truth. As of Nov 7, 2026 evening it also returns from a weekly usage cap.
- ChatGPT Plus, $20/mo: the cross-model checker seat. Currently down until about Nov 10, 2026 (weekly reset).
- Muse Power, $20/mo: Rey, the chair of this review (synthesis, audits, personal agent work). Paid through Nov 26, 2026.
- Qwen (chat), DeepSeek (chat), Gemini: free tiers, used as council checker legs.
- Codex (via ChatGPT): the local workhorse coding seat on the PC. DOWN for a while as of Nov 6, 2026. This vacancy is the reason for this review.
- Total paid today: $140/mo.

## 3. Established facts (sourced Nov 7, 2026; vendor figures are vendor-stated and unmeasured until a real job logs a charge)

Models and quality anchors:
- Artificial Analysis Intelligence Index: Claude Opus 5.5 = 58 (1st); Claude Sonnet 5.5 and Muse Wonder Full = 56; Kimi K3.1 Pro = 55 (top open-weight model).
- Vendor table (Moonshot, home-team chart, treat with care): SWE Marathon, Kimi K3.1 Pro leads 51.7 vs Opus 46.3; DeepSWE near tie (DeepSeek V4.1 Flash 77.0, K3.1 Pro 75.5, Opus 74.2); Terminal-Bench results vary by who runs them.
- Kimi K3.1 Pro: 1M context at Pro tier and up. Specialization: long-horizon endurance work. K2.7-Code CLOSED to new users Oct 31, 2026 and retires end of Dec 2026; do not plan on it.

Subscription and terms facts:
- Anthropic: subscription OAuth in third-party harnesses was technically blocked Jan 9, 2026 and prohibited in the Consumer Terms Feb 19, 2026. A Claude Max/Pro subscription can only be spent inside Claude Code itself (or wrappers that drive the genuine Claude Code binary). The Max seat therefore cannot be shared into any third-party workhorse harness.
- OpenAI went the other way: Sign in with ChatGPT is officially supported in several third-party harnesses, drawing on a shared Codex allowance with per-app weekly caps.
- Kimi Code (Moonshot's coding membership): Plus $19/mo, Pro $39/mo ($31 billed annually), Max $99, Ultra $199. NEW plans: rolling 5-hour limit, NO weekly limit; legacy plans keep a weekly limit. The real ceiling is a shared monthly credit pool across all Kimi features on the account, no rollover; pay-as-you-go Extra Usage overflow when it runs out. Moonshot publishes no absolute token count per tier. The subscription key is officially usable in other harnesses (endpoints speak Anthropic and OpenAI formats; OpenCode ships a built-in "Kimi For Coding" provider). One key distinction: the coding subscription key draws on the pool; a Moonshot platform API key bills per token instead.
- Opus capped on the $100 Max plan in the Nov 5, 2026 sprint week while doing board orchestration PLUS the absent Codex's jobs. The board stalled and Rey picked it up without a local environment. This is the only observed cap event on Max.
- Muse: Ryan's free account previously had Muse Wonder via rollout (not an entitlement; the documented free-plan default is Muse Spark). A free-plan test is already scheduled: Power lapses Nov 26, 2026, verification and resubscribe decision on Nov 27. Rey's usage at Nov 7 check: 32% of the Power weekly allowance in a week containing a full four-leg audit.

API list prices (per 1M tokens, in/out):
- Kimi K3.1 Pro: $2 / $10 (cached input $0.20)
- DeepSeek V4 Pro: $1.32 / $3.96 peak, half off-peak ($0.66 / $1.98)
- DeepSeek V4.1 Flash: $0.30 / $1.20 peak, half off-peak
- Claude Sonnet 5.5: $2 / $10. Claude Opus 5.5: $4 / $20.
- OpenAI GPT-6.1 Sol: $2 / $10.
- Cost-per-task anchors (Artificial Analysis derived, Nov 2026): Kimi K3.1 Pro about $3.68/task; DeepSeek V4 Pro about $1.77/task; DeepSeek V4.1 Flash about $0.60/task. One July 2026 calculator puts a typical solo-dev month on DeepSeek Flash at $3.60 to $7.95 (conservative; ignores caching). $39 of pay-as-you-go Kimi K3.1 Pro buys about 19.5M uncached input tokens.
- OpenRouter: no per-token markup; 5.5% fee when buying credits by card; it is a routing layer, not a harness.

Harnesses (Nov 2026 state):
- OpenCode: MIT, open source, Windows desktop app plus TUI plus IDE extensions, v2 shipped fall 2026, 75+ providers, subagents, headless and server modes for programmatic dispatch. Its own "Zen" is pay-as-you-go at claimed zero markup. Its "Go" plans ($10/$40) carry per-model 5-hour + WEEKLY + monthly windows: a poor fit for this buyer.
- Kimi Code's own CLI/desktop: MIT CLI, subagents/Swarm, Goal mode at Pro tier and up; a Kimi-only seat.
- Crush (Charm): best native Windows/PowerShell story; license is FSL (not OSI open source).
- Cline and Kilo Code: VS Code agents, fine with BYOK. ClinePass ($9.99) has 5-hour, weekly and monthly limits: a poor fit.
- Goose (Block): Apache-2.0, Windows desktop, can drive Claude Code and Codex via ACP.
- T3 Code: free, MIT, a supervision/control surface over locally installed agents (Claude Code, Codex, OpenCode, others); worktree per thread, one-click PR. Adds no model capacity and no caps.
- DeepSeek Harness (dsh): MIT but a developer preview (breaking changes promised, no security audit, plugins unsandboxed). Its models are equally available inside OpenCode/Cline without the preview risk.
- Cursor ($20/$60/$200 plus usage-pool overages) and Windsurf/Devin Desktop ($20/$200, daily + weekly quotas): polished subscription IDEs built for a human who codes in the editor. Copilot: monthly credit allotments; its cloud agent cannot run the local Godot environment.
- Dead or dormant, do not adopt: Roo Code (archived May 2026), Continue (discontinued Jun 2026), Aider (no release since Feb 2026), Gemini CLI consumer sign-in (ended Jun 2026; successor is a closed CLI with weekly limits).

Harness evidence:
- Best study (arXiv 2610.04433, Oct 2026): same model across Claude Code, OpenCode and mini-SWE-agent on SWE-bench Verified; score differences mostly within rerun noise (about 13% flip rate both ways); OpenCode trailing up to 9 points on the large pool was the one above-noise effect; cost per task differed up to 3x between harnesses (context overhead per step).
- One conflicting measurement: GLM-5.2 scored 23% vs 52% across two harnesses on SWE-bench Pro, so harness-model fit can matter for some open models.
- No Godot/GDScript-specific harness or model benchmark exists. The project's own trial job is the only direct evidence available.

Constraints:
- China-hosted models (Kimi, DeepSeek, Qwen) are fine for the public game repo. They are NEVER used for Ryan's employer's internal material.
- Ryan's standing cost discipline: vendor figures are unmeasured until a real transaction logs them; pacing assumptions are not required costs.
- Ryan prefers no terminal use himself and double-click-style simplicity; agents drive the PC, not him.

## 4. The chair's current lean (legs: attack or confirm this, do not just restate it)

1. Workhorse seat: OpenCode on the PC, Kimi Code Pro key as primary (endurance jobs), DeepSeek API (direct, pay-as-you-go) as the second model for standard and bulk jobs. Kimi's own CLI rejected mainly because it is a Kimi-only seat; Cursor rejected as an editor for a non-coder with a usage pool; Crush is the runner-up if Windows comfort dominates.
2. Claude Max stays at $100 while Opus owns the board and the Nov settlement queue (five audit settlement programs, a benchmark, a build comparison) is live. Downgrading Max to $20 Pro to fund Kimi was considered and provisionally rejected: Pro is roughly a fifth of Max 5x allowance, Opus capped once already on Max while double-hatted, and a capped reviewer stalls every seat behind it. Revisit the downgrade when the queue drains and Codex returns.
3. Sequence: (a) Kimi Pro one-month trial now, one bounded codex-style job, Opus reviews the PR and the review burden is the metric; (b) Muse free test already scheduled Nov 26/27; (c) Claude downgrade last, only on evidence.
4. Dispatch: fire-and-forget. Board issue to local headless OpenCode to branch/PR to one Opus review pass. Nobody (Opus or Rey) sits in the loop supervising steps; that would burn the reviewer's allowance on babysitting. Rey cannot execute on the PC (not paired); Rey dispatches through the board exactly as with Codex. T3 Code optional later as a free supervision layer.

## 5. Questions every leg must answer

- Q1 (workhorse configuration): Recommend ONE configuration for the vacant workhorse seat. Name the strongest argument against your own pick.
- Q2 (Claude Max): Keep $100 Max through the settlement queue, or downgrade to $20 Pro now and shift more volume to the workhorse? Give the deciding factor.
- Q3 (sequence and trial design): Is the chair's sequence right? Design the trial job: what job best discriminates between configurations, and what exactly should be measured (review burden, cost actually logged, wall time, defect count)?
- Q4 (dispatch architecture): Endorse or replace the fire-and-forget board-to-OpenCode-to-PR pattern. Consider T3 Code's supervision layer and any in-the-loop alternative, with costs.
- Q5 (missed risks): Up to three risks or facts the chair's lean underweights. Falsifiable where possible.

Close your report with: your final recommended stack (every seat), its total monthly cost, and your confidence (low/medium/high) with the one observation that would most change your answer.

## Leg prompts

### Blind Rey leg (writer)
You are a blind reviewer. Using ONLY this pack (ignore anything else you know about this project or these products), answer Q1 to Q5 in section 5, then give the closing stack, total monthly cost, and confidence exactly as section 5 specifies. Be specific and take positions. Do not write a preamble or a plan; write the report.

### DeepSeek leg (writer)
One file is attached: PACK.md is the evidence pack. It contains your complete instruction under the heading 'Leg prompts', in the part labeled 'DeepSeek leg (writer)'. Follow that instruction exactly and produce the complete report as your reply. Do not reply with a preamble or a plan.
Instruction for this leg: using only the pack, answer Q1 to Q5 in section 5 of the pack, then give the closing stack, total monthly cost, and confidence exactly as section 5 specifies. Take positions; name the strongest argument against your own Q1 pick. Mark any claim that goes beyond the pack as INFERRED.

### Qwen leg (writer)
One file is attached: PACK.md is the evidence pack. It contains your complete instruction under the heading 'Leg prompts', in the part labeled 'Qwen leg (writer)'. Follow that instruction exactly and produce the complete report as your reply. Do not reply with a preamble or a plan.
Instruction for this leg: using only the pack, answer Q1 to Q5 in section 5 of the pack, then give the closing stack, total monthly cost, and confidence exactly as section 5 specifies. Take positions; name the strongest argument against your own Q1 pick. Mark any claim that goes beyond the pack as INFERRED.

### Flash ideation leg
You are NOT the reviewer for this decision and your claims are not evidence. Your job is ideation: challenges, alternatives, and blind spots. One file is attached: PACK.md is the evidence pack. It contains your instruction under the heading 'Leg prompts', in the part labeled 'Flash ideation leg'. Follow it exactly and produce the complete reply. Do not reply with a preamble or a plan.
Instruction for this leg: using only the pack, attack the chair's lean in section 4. Give: (1) the three strongest challenges to the lean, (2) two alternative configurations the chair did not propose, with their costs, (3) the questions Ryan should ask before spending anything. No verdict is required from you; sharp challenges are the deliverable.
