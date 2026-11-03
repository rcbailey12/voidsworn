Qwen leg, issue #87, run 2026-11-03 from the main chat. Gates: Gate 1 passed (selector showed Qwen3.8-Max before the prompt was submitted); Gate 2 passed (the chat header still showed Qwen3.8-Max after generation). PACK.md was attached to the send message itself. Single response, no preference picker.

---

Qwen Leg -- Balance Re-check, Issue #87
(1) Headline Verdict
Yes, the faction spread is still in shape after the four landed changes.
Five of six factions show exactly zero shift; the sixth moved by a single run (2 percentage points), which is one-fifteenth of the ±13-point 95 % confidence band at n = 50.
Strongest single piece of evidence: the overall spread moved from 12 to 14 points, entirely accounted for by one stochastic Hullbreakers result, while every other faction's win count, death distribution, and confidence interval are unchanged to the decimal.
(2) Shift Table Read
At n = 50 per faction, one run equals 2 percentage points. The pack's standing caution gives the 95 % CI as roughly ±13 points (verified: for p ≈ 0.60, SE = √(0.6 x 0.4 / 50) ≈ 0.069, so 1.96 x SE ≈ 0.136, i.e. ±13.6 points; the pack rounds to ±13).

| Faction | v2 % | Now % | Shift (runs) | Inside ±13 CI? |
| Sunward Crusade | 64.0 | 64.0 | 0 (0 runs) | Yes -- no movement |
| Hegemony Navy | 70.0 | 70.0 | 0 (0 runs) | Yes -- no movement |
| Ashfall Hullbreakers | 60.0 | 58.0 | -2 (1 run) | Yes -- 2 ≪ 13 |
| The Chorus | 64.0 | 64.0 | 0 (0 runs) | Yes -- no movement |
| The Glasswrights | 68.0 | 68.0 | 0 (0 runs) | Yes -- no movement |
| Eclipse | 72.0 | 72.0 | 0 (0 runs) | Yes -- no movement |
| Overall | 66.3 | 66.0 | -0.3 | Yes |

Arithmetic on the only non-zero shift: 58 % - 60 % = -2 percentage points = exactly 1 run out of 50 flipping outcome. The 95 % CI for 58 % is 44.2-70.6; the 95 % CI for 60 % is 46.2-72.4 (approximate, same SE class). These intervals overlap almost completely. No faction's movement is distinguishable from sampling noise. The overall -0.3 is the average of five zeros and one -2, i.e. -2/6 ≈ -0.33, rounding to -0.3. No real movement is detected anywhere in the table.
(3) Attribution by Landed Change
PR #38 -- Effect caps (core.js sumFx). This is the only change that alters battle mathematics. Mechanism: if any faction's typical effect pool under the baseline bot policy exceeds the new caps, that faction's effective combat strength would drop, lowering its win rate. Table signature: none visible. Five factions are bit-identical; the Hullbreakers lost one run, which is consistent with one seed hitting a capped interaction, but is equally consistent with any other source of variance on a changed code path. The caps either do not bind at the bot policy's typical effect magnitudes, or they bind roughly symmetrically across factions. No differential signature in the table.
PR #63 -- Glasswright tree (data.js +320, core.js +41). Only Glasswright admirals have a tree; trunk perks can apply within a single run as the bot earns XP. Mechanism: could raise Glasswright win rate by granting in-run bonuses. Table signature: none. Glasswrights are 68 → 68, deaths 5/10/1 → 5/10/1, identical. INFERRED: at three sectors with the baseline bot policy, the XP earned inside one run is likely insufficient to unlock trunk perks that would change battle outcomes, or the perks that do unlock are too small to shift the rate at n = 50. The pack does not state the XP thresholds, so this mechanism is plausible but unconfirmed from the pack alone.
PR #83 -- Shadow XP and heir naming (campaign_meta.js +42, core.js +1/-1). Shadow XP accrues to benched same-faction admirals across runs in a persistent profile. Mechanism: could compound faction strength over a campaign. Table signature: structurally impossible. The driver calls defaultMeta() before every run, resetting the profile. Cross-run shadow earnings cannot exist in this measurement. The pack states this explicitly. This change is invisible to the measurement by construction.
Teaching gate (R69 playtest switch, per-step gates). The driver does not enable the everything-unlocked state. Mechanism: gated content unreachable by a fresh-profile bot in one run is excluded. Table signature: structurally impossible, same reasoning as shadow XP. Any content behind the gate that would affect balance simply does not appear in these numbers. The pack states this explicitly.
Summary: of the four changes, two (#83, teaching gate) are excluded by the driver's fresh-profile design, one (#63) targets a single faction and shows no effect, and one (#38) is the only plausible source of the single Hullbreakers run-flip but cannot be confirmed at n = 50.
(4) The Hullbreakers One-Run Shift
What can be concluded:
Exactly one of the 50 Hullbreakers seeds changed outcome between v2 and now (30 wins → 29 wins). Because the runner is deterministic per seed on unchanged code paths, this confirms that at least one Hullbreakers seed traversed a code path altered by the landed PRs. The most likely candidate is the effect-cap change in #38, since it is the only PR that touches battle mathematics.
The death distribution shifted by one S1 death (11/5/4 → 12/5/4), consistent with one additional early-sector loss.
What cannot be concluded:
That Hullbreakers are weaker. A 2-point shift at n = 50 is 1/6.5th of the ±13-point CI. It is indistinguishable from noise.
That the shift is caused by any specific PR. The code changed in multiple places; the one affected seed could have interacted with any of them.
That a trend exists. One run is not a direction. The v2 measurement itself was two identical executions, and a single-run difference is within the expected reproduction variance of any stochastic process at this sample size.
That the per-admiral splits (Vesh 83.3 % vs Sable 38.5 %) have changed. The pack notes these match the v2 pattern qualitatively and the chair did not re-derive per-admiral v2 splits. At 12-13 runs per admiral the noise is even larger.
(5) The 15-Point Trigger
The spread is 14 (58 to 72). The trigger is "over 15." Reading the trigger literally, it does not fire. That reading is correct as a procedural matter: the pack defines the threshold, the measurement is below it, and no data.js change proposal is warranted.
However, the trigger is a blunt instrument at this sample size. With ±13-point CIs on each faction, the measured spread of 14 points is almost entirely noise-dominated. The "true" spread could plausibly be anywhere from roughly 0 to 26 points and still produce the observed table. A 14-vs-16 distinction is not resolvable at n = 50. The trigger would be more informative at higher n (INFERRED: at n = 200, the CI shrinks to roughly ±6-7 points, making a 15-point spread detectable; at n = 500, roughly ±4 points).
What I would watch instead of, or as well as, the raw spread:
Per-admiral intra-faction spread. The pack flags Crusade Thale 100 % vs Ashgrove 33.3 % (a 66.7-point gap) and Hullbreakers Vesh 83.3 % vs Sable 38.5 % (a 44.8-point gap). These are far wider than the inter-faction spread, persist across v2 and now, and are qualitatively unchanged. If any admirals are consistently non-viable, that is a balance concern the faction-level average hides. Small samples (12-13 runs) make these noisy, but the qualitative persistence across two measurement rounds is notable.
The Hullbreakers -2 on a future re-run. If the next re-check shows Hullbreakers at 56 or below (two or more additional runs lost), that would be a pattern worth investigating even if still inside the CI. If it snaps back to 60, the one-run shift was noise.
Glasswright tree activation. The tree is new and currently shows zero effect. If future changes lower XP thresholds or extend the tree, the Glasswright rate could move. Worth a specific watch note in the next re-check.
(6) Owner Questions
None are needed. The pack is self-contained, the measurement is unambiguous, the four landed changes are accounted for, and the procedural trigger (spread <= 15) is clear. There is no ambiguity that requires the owner to resolve before this report is filed.
(7) Not Checked
• I did not execute the Monte Carlo runner or inspect its output independently. All numbers are taken verbatim from the pack.
• I did not inspect the source code of PRs #38, #63, #83, or #95. The pack's descriptions of what each PR changes are taken as given.
• I did not verify HEAD 23da027, the runner settings (50 runs, seed 1, veteran AI, baseline bot policy), or the 442-second run time.
• I did not examine the Godot rules or oracle copies mentioned as mirroring the #38 caps.
• I did not verify the teaching-gate / R69 switch behaviour or confirm which content is gated.
• I did not re-derive per-admiral v2 splits (the pack states the chair did not either).
• I did not assess human play rates; all numbers are bot rates under one policy, as the pack cautions.
• I did not and do not propose data.js balance numbers; that is the owner's (Ryan's) call per the pack.
• The Glasswright XP-threshold reasoning in §3 is marked INFERRED; the pack does not state the thresholds.
• The n-scaling estimates in §5 (CI at n = 200, n = 500) are marked INFERRED from the binomial SE formula; they are not in the pack.
