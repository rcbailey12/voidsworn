Chair synthesis: events audit (Oct 27 program item 5). Four blind legs on the same pack pinned to 68b42ce406286eb95ea7df6aaf3f683c1231b51d: DeepSeek (EVENTS FAIL, BEVENTS PASS WITH CAVEATS), Qwen (CONDITIONAL PASS, one BLOCKER), Argon (FAIL, nine BLOCKER tags on EVENTS), and Rey (this chair's own leg, with direct reads of campaign_run.js and campaign3d.js). Every load-bearing claim below was re-checked against the data tables or the campaign code at the pin; where a leg's severity does not survive that check, the corrected weight is given and the reason stated.

OVERALL VERDICT: FAIL at the campaign option layer, PASS at the battle-event layer. No BLOCKER survives chair review: nothing here breaks or soft-locks a run. What survives is a FIX-led core of five items, three of them found independently by all three external legs, plus a set of NOTEs. The pattern underneath is consistent: the event data is mostly sound, and the defects live where data meets mechanism (flags, splices, gating), which is why the legs that read only the tables understated them and the leg that assumed mechanisms overstated them.

TOP FINDINGS

1. Event flags record the choice, consumers test only presence (FIX, top of the audit). Three-leg convergent (DeepSeek found it in code, Argon stated it accurately, Qwen's leg supports the family) and chair-confirmed: eventFlags (campaign_run.js:240) stores the chosen option's key; needMet and verbFree test non-null only. Five text promises break: Hegemony drill free after selling the defector back, Ithar attune free after any lament outcome, Voidsworn vigil free after choosing Leave at the shrine, Eclipse waken free after stripping the yard, and the saboteur face option opening on a defector the player never questioned. The fix is a comparison change in two consumer functions; the stored data already carries what is needed.

2. The seer event's Glasswright option can never fire (FIX). Three-leg convergent, chair-confirmed: the event excludes Ithar at data.js:293 while its splice-added song option at data.js:327 requires Ithar. One line either way; direction is Opus's call with the design note in the Rey leg (the exclusion may be intentional, the splice the leftover).

3. The beacon event discloses neither of its consequences (FIX). Three-leg convergent, chair-confirmed: 100 credits shown; ambush:true, greed flag and nemClock advance not shown (data.js:282, splice at 325). The bait event in the same table discloses its ambush in words, so the standard exists and beacon misses it.

4. Repair gating across events is inconsistent (FIX, Argon-originated, chair-scoped). Wright, dock and quiet carry repair effects with no chorus gate; quiet is the universal fallback; the shrine event does gate chorus and deathless out, proving intent exists unevenly. Scoped by the kit audit's ruling: the prohibition is shipyard repair; Chorus regrowth and feeding are designed identity, so the spawn option is a NOTE about the shared healAll key (one key serves generic "repairs" text and Chorus regrowth alike), not a violation.

5. Haven can force a fight (FIX, Argon-only, chair-confirmed as data). The only fight-start event with no free exit: raid, a 40-credit tribute that disables below 40, and a corsair-only recruit. The fight is telegraphed, so this is a design outlier rather than a trap; whether it should exist is question 1 for Ryan below.

NOTES CARRIED

- Solved choices: a clean faction-gated core (merc oath, veterans oath, reactor metal, well sails, broker debt, defector enlist, lament join) is genuinely dominant by design; equipment-gated blue options are the intended pattern; wider dominance claims from the legs ignore fight loot and the flag currencies that feed the Corsair verb payout. One price inversion inside the pattern: wright grants upgradeOne free, dock charges 100 credits for the same effect.
- Tombhome's wake option is double-gated (redundant) and its prize, d_scythe, is a small frigate; NOTE weight.
- The loud flag counter is written but never read in the checked campaign files, while the NEM_CLOCK comment promises the clock answers "every loud choice". Comment and code disagree; no secret clock advance exists.
- Derelict's cut option promises "salvage" and pays a module plus 40 credits; post-rename, salvage is a defined term, so the wording is now wrong on its face.
- Crew and commerce events (mutiny, quiet, merc, auction, saboteur) roll for Chorus and Eclipse with human-crew text; voice family, grouped with the text audit's findings.
- Moon's bombard XP (20) exceeds its rescue XP (15); small values, data-accurate.
- Eclipse Nemesis shield weakness and adaptation picks converge with the kit audit's ion dead zone; they belong to that fix family.

WHAT DISSOLVED UNDER CHAIR REVIEW

- Argon's shrine falsy-zero BLOCKER: eventFlags writes o.k || String(i); String(0) is the truthy string "0" and the consumers test non-null, so no falsy trap exists. The real defect underneath is finding 1.
- Argon's flare dead-effect FIX: battle.js:391, past the pack's line-120 cut, zeroes shields at round start on the flare round. Flare works; this also retro-supports the other legs' BEVENTS PASS.
- Argon's mutiny soft-lock BLOCKER: the discipline option has no cost and no need, so it is never disabled; no zero-option state exists. The payXp outcome clamps at the rank floor (a small text-accuracy NOTE: near the floor, discipline costs less than the stated 20).
- Argon's credit-gating FIX: eventOptOk gates every r.cost option on credits; dock frame's need:{cred:100} is redundant, not broken.
- Argon's rollBattleEvent force/boss FIX: no call site in evidence forces a boss-fight reinforcement roll; the exclusion reads as intentional to all three legs. Left as a call-pattern NOTE.

LEG WEIGHTS

DeepSeek produced the audit's sharpest single catch (finding 1, from the code) and the broker/defector solved-choice refinements. Qwen was the most calibrated leg (its CONDITIONAL PASS is closest to the chair verdict) and its BEVENTS PASS was right. Argon contributed two genuine unique FIXes (findings 4 and 5) inside the program's usual pattern of inflated tags and five dissolved claims. The Rey leg's code reads settled the disputes (flare, falsy-zero, soft-lock, payXp) that the pack's line cut had left open.

QUESTIONS FOR RYAN

1. Haven: should every fight-start event guarantee a free way out, or is one telegraphed forced fight per table acceptable as a pressure valve? The data fix is trivial in either direction; the principle is the decision.
2. No other human-direction questions arise from this audit. The seer direction (drop the exclusion or drop the splice) and the flags comparison change are Opus's calls within the recorded design.
