# DeepSeek leg (writer) - AI stack review, Nov 7, 2026

- Chat: https://chat.deepseek.com/a/chat/s/2867b82b-3603-4db3-89ba-94c055daf4ab
- Gates (confirmed from final screen state by the runner): DeepThink ON, Search OFF.
- Filed raw below (dash-normalized by the chair).

---

## Q1 - Workhorse configuration

**Recommendation:** OpenCode v2 on the Windows 11 PC, with the Kimi Code Pro subscription key as the primary model and DeepSeek direct API pay-as-you-go as the secondary model. Use Kimi K3.1 Pro for endurance/long-horizon jobs; use DeepSeek V4.1 Flash for standard and bulk jobs. Keep Claude Max out of OpenCode entirely: Anthropic's terms prohibit spending a Claude Max/Pro subscription in third-party harnesses, so any attempt to use Max as the workhorse is not a legal option. Use Kimi's own CLI only as a diagnostic fallback, not as the seat, because it is Kimi-only.

**Strongest argument against my own pick:** OpenCode is the one harness with an above-noise quality penalty in the best available study - up to 9 points trailing on the large pool - and cost per task can differ up to 3x between harnesses because of context overhead. Kimi Code Pro also has no published token count, a shared monthly credit pool with no rollover, and a rolling 5-hour limit. So the chair's pick could lose both quality and cost predictability versus a simpler **Crush + DeepSeek V4.1 Flash** seat, especially on Windows/PowerShell where Crush has the best native story. That is the argument I would need the trial to defeat.

## Q2 - Claude Max

**Keep the $100 Claude Max through the settlement queue. Do not downgrade to $20 Pro now.** The deciding factor is reviewer capacity, not model preference: Opus owns code truth and the board, Pro is roughly a fifth of Max 5x allowance, and Opus already capped once on Max while double-hatted during the Codex vacancy. A capped reviewer stalls every seat behind it, including any cheap workhorse. Revisit the downgrade only after the Nov settlement queue drains **and** Codex returns or the workhorse trial proves real offload with lower Opus review burden.

## Q3 - Sequence and trial design

The chair's sequence is directionally right, with one correction: the trial must be controlled, not a single unpaired job. Sequence: Kimi Pro monthly trial now; Muse free test Nov 26/27; Claude downgrade last, only on evidence. Do not buy Kimi annual before the trial and the Muse test.

**Trial design:** Use one bounded R75 issue spec that exercises the real local loop: GDScript edit, Godot 4.7 run/build, one screenshot capture, branch, PR, and a clear "Done when." A medium job is better than a trivial one and better than a giant feature. INFERRED example from the pack's project description: fix one reproducible fleet-movement/collision bug and add a regression check - not a broad feature.

Run it as two OpenCode arms against the same spec:

**Arm A:** Kimi Code Pro primary.

**Arm B:** DeepSeek V4.1 Flash direct API as control.

Opus reviews both PRs blind, one pass each, without Rey or Opus supervising steps.

Measure exactly:

**Review burden:** number of Opus review passes, review comments, rework cycles, diff size, and reviewer wall/token time. This is the primary metric.

**Cost actually logged:** Kimi credit-pool delta and any Extra Usage overflow, DeepSeek invoice for the arm, and OpenCode context/token overhead. Do not use vendor table costs as measured cost.

**Wall time:** dispatch-to-PR and PR-to-merge.

**Defect count:** reviewer-found defects and post-merge defects.

**Pass condition:** Kimi arm clears in one Opus review pass, no credit-pool overflow or 5-hour throttle during a normal trial week, review burden no worse than the DeepSeek control, and logged cost within the chair's assumption. If it fails any of those, switch primary to DeepSeek V4.1 Flash or V4 Pro and reconsider Crush.

## Q4 - Dispatch architecture

**Endorse fire-and-forget:** board issue → local headless OpenCode → branch/PR → one Opus review pass. Do not put Rey or Opus in the step loop. That burns the reviewer's allowance on babysitting and is exactly the failure mode the pack warns about.

**T3 Code:** add it later only as a free asynchronous supervision/control surface, not as an in-loop supervisor. It is MIT/free, adds no model capacity and no caps, and can give worktree-per-thread and one-click PR visibility. It is worth adding if the trial shows stuck runs or unclear status. It is not worth adding before the trial.

**In-the-loop alternative:** reject. Its cost is Opus/Rey review allowance and wall time, both scarce; the pack gives no evidence that step supervision improves outcomes enough to justify it. Crush is the fallback only if Windows/PowerShell friction dominates the OpenCode trial.

## Q5 - Missed risks

**1. Kimi Pro's real ceiling is unpublished and shared.** The credit pool is shared across all Kimi features, has no rollover, and the 5-hour limit is rolling. A one-month trial can look fine on one bounded job and still throttle a normal board week. Falsifiable: log pool delta, overflow charges, and 5-hour throttles per job/week; if a normal week hits either, Kimi fails as endurance primary.

**2. Review burden can migrate to Opus and re-create the Max cap.** A cheaper workhorse that produces larger or harder-to-review diffs shifts cost to the reviewer. Falsifiable: measure Opus review passes/tokens/minutes per PR against a prior Codex/Opus baseline; if review burden does not fall, the workhorse trial has not solved the actual bottleneck.

**3. The Windows/headless dispatch path is not proven.** The pack says OpenCode has Windows desktop, TUI, headless and server modes, but the board-to-headless-OpenCode path on PowerShell is untested in the pack. Crush has the best native Windows/PowerShell story. Falsifiable: count setup failures, stuck runs, and manual retries during the trial; if they are material, Crush becomes the workhorse harness.

## Closing recommended stack

**Board owner / reviewer / code truth:** Claude Max, $100/mo - Opus 5.5, kept through the settlement queue.

**Cross-model checker:** ChatGPT Plus, $20/mo - keep when it returns; free Qwen/DeepSeek/Gemini remain supplemental council legs at $0.

**Chair / synthesis / audits:** Muse Power, $20/mo through Nov 26; free-plan test Nov 27. Budget $20 until the free test verifies; if free Muse Spark is sufficient, this drops to $0.

**Local workhorse coding seat:** OpenCode, $0 license, plus **Kimi Code Pro $39/mo monthly** as primary and DeepSeek direct API pay-as-you-go as secondary. Use DeepSeek V4.1 Flash for bulk/standard; V4 Pro only as an exception if Flash fails a job (INFERRED). Estimated DeepSeek variable cost from the pack's conservative solo-dev anchor: roughly $4-$8/mo measured, not assumed.

**Total monthly cost: $179/mo fixed** ($100 + $20 + $20 + $39), plus **$4-$8/mo** DeepSeek pay-as-you-go, so approximately **$183-$187/mo** now. If the Muse free test passes, subtract $20: approximately $163-$167/mo. If Kimi is taken annually at the $31/mo equivalent, subtract another $8/mo but only after the trial passes.

**Confidence: Medium.** The stack follows the pack's legal and capacity constraints, but the workhorse pick depends on an unrun Godot trial and Kimi's unpublished credit pool.

**One observation that would most change my answer:** The Kimi/OpenCode arm requiring more than one Opus review pass, or hitting a 5-hour/credit-pool ceiling, while the DeepSeek V4.1 Flash control arm clears in one pass at lower logged cost. That would switch the primary workhorse to DeepSeek Flash/V4 Pro and make Crush the leading harness candidate.
