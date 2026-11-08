# Chair synthesis: AI stack and coding harness decision (Nov 7, 2026)

Chair: Rey. Legs: blind Rey (pack only, written before the other legs were read), DeepSeek (DeepThink on, Search off, gates confirmed), Qwen (Qwen3.8-Max, both gates confirmed), Flash ideation (Gemini 3.8 Flash, ideation seat; claims treated as leads, not evidence). Pack: PACK.md in this folder. Legs filed in legs/.

## Verdict

**GO WITH ONE AMENDMENT.** The configuration is confirmed by all three writer legs and the blind leg independently: **OpenCode on the PC as the workhorse harness, Kimi as primary model, DeepSeek as the second model, Claude Max kept at $100 through the settlement queue, fire-and-forget dispatch, T3 Code later as a free window.** The amendment is to the purchase order, adopted from the Flash ideation leg's strongest challenge and merged with DeepSeek's trial design: **run the trial on pay-as-you-go API first, both arms, and buy the $39 Kimi subscription only after the Kimi arm passes.** The trial month then costs the current $140 plus a few dollars of API instead of $179 plus on day one.

## Where the legs agree (no chair discretion needed)

- Q1: OpenCode + Kimi + DeepSeek, unanimous across blind Rey, DeepSeek, Qwen. Flash's alternatives also keep OpenCode as the harness.
- Q2: Keep Max at $100 through the settlement queue, unanimous across the three writer legs and the blind leg. Deciding factor, stated the same way by all four: the reviewer is the single point of failure, Pro is roughly a fifth of the allowance, and the only observed cap happened on Max while double-hatted.
- Q4: Fire-and-forget dispatch, unanimous. In-the-loop supervision rejected by every leg on the same cost logic.
- T3 Code: later, free, optional. Unanimous.

## Amendments adopted by the chair

- **A1 (trial funding):** The trial runs two arms in OpenCode against one identical R75 spec: Arm A on Kimi K3.1 Pro via the pay-as-you-go platform API, Arm B on DeepSeek V4.1 Flash via its API as the control. No subscription is bought before the trial. Source: Flash Challenge 1 (a $39 pool with an unpublished cap is a sunk cost if Kimi cannot handle GDScript; a few dollars of API answers the same question), merged with DeepSeek's controlled two-arm design. This also satisfies Ryan's standing rule that costs are logged by real transactions, not vendor pacing.
- **A2 (the subscription decision rule):** If the Kimi arm passes, buy Kimi Code Pro MONTHLY (not annual) and treat the first real job's pool draw as the capacity test, per Qwen's falsifier: a draw under about 5 percent of the monthly pool confirms the tier; over about 8 to 10 percent fails it and Kimi drops to endurance-only or out. If instead the trial's logged pay-as-you-go volume at board pace projects under about $39/mo, never buy the subscription at all; Flash's Alternative A (pure pay-as-you-go) becomes the steady state by measurement, not by argument.
- **A3 (resilience, near-zero cost):** Pre-configure an OpenRouter key inside the same OpenCode install as a cold third route, and keep Crush installed as a cold spare harness. Sources: blind Rey (Kimi and DeepSeek are both China-hosted, so the primary and overflow failure modes are correlated; a config change should not become a procurement exercise) and Qwen (single-workhorse dependency with no hot spare). Cost: a few dollars of OpenRouter credit, 5.5 percent on purchase, no subscription.
- **A4 (fire-and-forget conditions):** From the blind leg: the PR must carry the run's evidence (workflow checks, the local execution output the Done-when required, captures for visual jobs), because nobody watched the run; and jobs stay bounded and discardable, split at the issue stage rather than supervised mid-run.
- **A5 (pass conditions):** From DeepSeek and Qwen: the Kimi arm passes if it merges in ONE Opus review pass, with review burden no worse than the DeepSeek control arm, no throttle event, and a logged cost within about 2x the Artificial Analysis anchor (about $3.68/task); a logged cost over 2x the anchor indicts the harness overhead specifically, per Qwen's third risk.
- **A6 (interaction flagged, no action):** The blind leg notes the Nov 27 Muse free test is not independent of this decision: the trial's results will be synthesized by the chair, and if the free test drops the chair to Muse Spark that week, the synthesis quality caveat applies and resubscribing becomes more attractive. This is recorded as an input to the Nov 27 decision, not a change to it.

## Screened: not adopted, with reasons

- **Flash Alternative B (Opus does the local coding itself in Claude Code under T3):** rejected. It reinstates the exact configuration that produced the Nov 5 cap (Opus double-hatted as orchestrator and coder), which the pack records as observed evidence, not theory. Its supporting premise also conflates two outages: ChatGPT's reset around Nov 10 does not restore Codex, which Ryan has down "for a while" since Nov 6. If Codex does return early, the trial-first sequence already protects the downside: at that point the only spend is a few dollars of API.
- **Flash Challenge 3 (test Claude Pro now because review is cheaper than coding):** not adopted as an action; converted into a measurement. The trial logs Opus review burden per PR (passes, comment severity, reviewer time). The downgrade question is revisited with that number plus the queue state, which is what all three writer legs ruled. Flash's underlying hypothesis (review-only Opus may fit Pro) is recorded here as the thing that measurement tests.
- **Qwen's trial job shape vs DeepSeek's:** merged rather than chosen between. The spec takes Qwen's scope floor (multi-file, cross-subsystem: GDScript plus scene/resource files, local execution evidence, a screenshot as the acceptance gate) and DeepSeek's measurement set (review passes, comments, rework cycles, diff size, logged cost per arm, dispatch-to-PR and PR-to-merge wall time, defects within a week of merge). One job, both arms, same spec text.
- **Leg artifacts:** Qwen's report dates itself Nov 8 (the run was Nov 7 Chicago time); date slip only, content verified against the pack. DeepSeek's leg is the most operationally specific and needed no corrections. The blind leg contributed the two risks nobody else raised (correlated China-hosted failure; the Muse test interaction).

## The trial, as specified (ready to file when Ryan approves)

- One bounded R75 issue on the Voidsworn repo: a multi-file Godot 4.7 job of the shape Codex used to take (a self-contained feature or fix touching several GDScript/data/scene files), with a Done-when that requires local execution evidence and, if visual, a screenshot.
- Two runs in OpenCode on the PC, same spec, same branch discipline: Arm A Kimi K3.1 Pro (pay-as-you-go), Arm B DeepSeek V4.1 Flash (pay-as-you-go).
- Opus reviews both PRs, one pass each, without knowing which arm produced which if that can be arranged cheaply; nobody supervises steps.
- Measured: Opus review passes and comment severity (primary), logged dollar cost per arm against the anchors, wall time dispatch-to-PR and PR-to-merge, defects within a week post-merge, plus any setup failures or stuck runs on the Windows/headless path (DeepSeek's third risk: if PowerShell friction is material, Crush becomes the harness candidate).
- Setup Ryan owns: install OpenCode on the PC (or have Opus do it), open a Moonshot platform API account and a DeepSeek API account with small balances. These are his accounts and his payment steps.

## Costs

- Trial month: $140 (current stack, unchanged) plus trial API spend, expected single digits to roughly $15 total for two bounded jobs.
- Steady state if the trial passes and Pro is bought: $179 fixed (Max $100, ChatGPT $20, Muse $20, Kimi Pro $39) plus about $4 to $8 DeepSeek usage, about $183 to $187/mo.
- Steady state if the trial says stay pay-as-you-go: $140 plus measured usage, plausibly $145 to $160/mo at board volume.

## Confidence

Medium-high on the configuration (four independent legs, one evidence base, no dissent on Q1, Q2 or Q4). Medium on the Kimi pool economics until the first real draw is logged; the amended sequence is designed so that number exists before any subscription does.

## What the chair needs from Ryan

One decision: approve the amended sequence (trial on pay-as-you-go first, subscription only on a pass). On approval, Rey drafts the trial issue spec for Opus to file when it returns, and the setup steps above are Ryan's to run on the PC.
