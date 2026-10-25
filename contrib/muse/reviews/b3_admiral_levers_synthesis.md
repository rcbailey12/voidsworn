# B3 admiral levers synthesis: sector 1 boss spread (chair, TWO LEGS)

Legs: contrib/deepseek/reviews/b3_admiral_levers_deepseek_2026_10_25.md (DeepSeek, pack uploaded, DeepThink + Search ON, Oct 25, 3:30-3:38 PM CDT) and contrib/qwen/reviews/b3_admiral_levers_qwen_2026_10_25.md (Qwen, Qwen3.8-Max two-gate verified, Thinking + Web search ON, Oct 25, 3:30-3:37 PM CDT). Both ran blind from the same Job B evidence pack. Screenings: hidden_files/b3_admiral_levers_deepseek_screening.md (CLEAN, notes only) and hidden_files/b3_admiral_levers_qwen_screening.md (CLEAN, with one material error corrected here, never in the filed leg).

Chair verdict: GO WITH CONDITIONS. Both legs agree on the shape of the answer for all four out-of-band admirals: a single perk-number change tested first, an escalation ladder behind it, fleet changes only as larger-feel backups, and measure the pending rerun before applying any high-side nerf. The step sizes differ on three of the four admirals; the synthesis resolves those differences as test-smallest-first ladders (stated as chair recommendations, not leg agreement) rather than averaging them. Nothing in this synthesis is a ruling, and no lever-to-points mapping exists in either leg, so every number below is a proposal for Opus to test in the sim, not a predicted win percentage.

## Matrix note and scope (both legs agree, chair confirms)

All levers are tuned against the Opus B0 bossmatrix baseline (contrib/opus/compute/bossmatrix_admirals.csv, start fleets only). Target band: no sector 1 admiral below 50% or above 90% against a sector 1 flagship. Out of band on that baseline, exactly four: grax 36% (low), vesh 94%, mending 93%, voice 94% (high). Every other sector 1 admiral is inside 54% to 84%. Sector 2 rows (7% to 48%) and sector 3 rows (0% to 6%) are NOT targets, and neither leg tunes to them.

Staleness warning, carried from FINDINGS S5 and both legs: the B2 sector 1 boss matrix before the escort fix fell about 20 points (23% to 76%), the escort budget was cut from 0.5 to 0.3 (f86f04a), and the post-fix rerun is pending on the PC. The 23% to 76% range is NOT the baseline and is NOT averaged with B0 anywhere in this synthesis. Every lever below is a proposal for Opus to test against the rerun.

## The one correction the synthesis makes (Qwen leg error, fixed here only)

The Qwen leg states that none of the four admirals is carrier flagged, and specifically that vesh is "not carrier flagged". That is WRONG. bossmatrix_admirals.csv, sector 1 row for vesh, reads carrier_fleet yes, and the DeepSeek leg correctly records carrier yes. Correct values for the four: grax carrier no, vesh carrier YES, mending carrier no, voice carrier no. The Qwen leg's filed copy is preserved verbatim with the error; the correction lives in its screening note and here. Two consequences follow, and both are applied below:

- The synthesis uses carrier=yes for vesh everywhere.
- The Qwen leg's grax lever 3 argument ("c_raider to c_hulk does not make Grax a carrier, because vesh starts with c_hulk and is not carrier flagged") does NOT hold as stated, because its premise is false. The c_hulk swap for grax stays on the table as a proposal, but its carrier-flag consequence is UNSURE, not cleared by the vesh example. How the CSV carrier flag is set (fleet composition, perk, or something else) is UNSURE from this evidence; neither leg settles it, and both legs flag the hull-to-flag mapping as inference where they touch it.

## Agreement table: test-first levers

| Admiral | B0 | DeepSeek test-first | Qwen test-first | Synthesis test-first (chair) |
|---|---|---|---|---|
| grax (Corsair, low) | 36% | dmgPct .1 to .15 | +10% to +15% (same change) | dmgPct .1 to .15. Full agreement. |
| vesh (Corsair, high) | 94% | hullRegenPct .05 to .04 | patch 5% to 3% | hullRegenPct .05 to .04, then .03 if short (ladder, see below). |
| mending (Chorus, high) | 93% | hullRegenPct .06 to .05 | regrowth 6% to 4% | hullRegenPct .06 to .05, then .04 if short (ladder, see below). |
| voice (Chorus, high) | 94% | dmgPct .15 to .12 | +15% to +10% | dmgPct .15 to .12, then .10 if short (ladder, see below). |

Every test-first lever in both legs is a perk-number change. Neither leg proposes a cost change (cost is not a listed lever type), and neither leg proposes a Command edit. Whether a Command number counts as a "perk number" under the brief's lever types is an open scope question from the Qwen leg (flagged UNSURE there); the synthesis does not resolve it and does not need to, since no lever below touches a Command.

## Grax (Corsair), 36%, LOW: test dmgPct .1 to .15 first

Current state (pack, both legs agree): fleet [c_marauder, c_reaver, c_raider]; perk Ram and board, +1 speed for every ship and +10% damage (speed 1, dmgPct .1); Command Full burn; rounds 8.3; carrier no; cost 0. FINDINGS S6 calls Grax the weakest start. Cause is UNSURE in both legs: the pack does not tie Grax's row to the Hegemony boss row (hardest opener, 47% player wins), and hull stats are absent. Qwen's inference (a three-hull fleet that must close range under fire, with the lowest visible flat damage perk) and DeepSeek's inference (a short row that may lack staying power) are both labeled inference, not facts.

Escalation ladder, smallest feel change first (chair ranking; the one ranking disagreement is noted below):

1. Perk number: dmgPct .1 to .15. Both legs test-first, full agreement. Keeps Ram and board as speed plus damage, touches no rule, lowest identity cost. Direction: up toward 50.
2. One ship swap: c_raider to c_marauder (Qwen only). Keeps three hulls, smallest composition change, stays inside cheap raid-hull identity. Marauder-versus-raider strength is UNSURE (no hull stats in the pack).
3. Starting fleet change: add one c_raider, making [c_marauder, c_reaver, c_raider, c_raider] (both legs include this shape). Changes fleet size, so it ranks below a same-size swap on feel, even though DeepSeek ranks it second and Qwen ranks it last. That ranking difference is the one grax disagreement; the chair resolves it by feel (swap before add), not by averaging, and records DeepSeek's second-place ranking here so Opus can see it.
4. One ship swap: c_raider to c_hulk (Qwen only). Adds the durable body a boarding fleet needs to survive the approach, but its carrier-flag consequence is UNSURE after the correction above. Do not test this swap until Opus settles how the carrier flag is set.
5. Perk number: speed 1 to 2 (DeepSeek only). One number, but the leg itself calls it a large tactical feel change (every ship +2 speed total), so it ranks last despite being a number change. Rank by feel, not by number size, per the brief.

Overshoot flag (both legs, mild for grax): these are up-levers. Apply only if the rerun still shows grax below 50. If the rerun lifts him inside the band, do not stack levers on top; Qwen notes a single perk step is unlikely to blow past 90 from 36 on B0, but that is inference, not a measured effect.

## Vesh (Corsair), 94%, HIGH: test hullRegenPct .05 to .04 first, then .03

Current state (pack, both legs agree except the corrected flag): fleet [c_hulk, c_marauder]; perk Scrap armor, ships patch 5% of hull each round and +10% armor (hullRegenPct .05, armor .1); Command Patch and pray (25% hull repair, patches destroyed sections); rounds 10.5; carrier YES (see correction above); cost 80. Cause is UNSURE in both legs: the sustain package (per-round patching plus armor plus a section-healing Command) is the visible difference from same-faction sable (58%) and mott (64%), who have no sustain perk, but the pack does not isolate the cause and hull stats are absent.

Escalation ladder, smallest feel change first (chair ladder; step sizes differ between legs, resolved as smallest first):

1. Perk number: hullRegenPct .05 to .04 (DeepSeek test-first). Scrap armor still patches hull each round, just slower. Lowest identity cost. Direction: down toward 90.
2. Perk number: hullRegenPct .05 to .03 (Qwen test-first). Same perk, one more point down, only if step 1 lands short. Do not jump straight to .03; the legs disagree on the first step size, and testing smallest first is what lets Opus measure the step.
3. Perk number: armor .1 to .05 (both legs, as second lever). Alternate one-number cut on the same perk if the regen steps undershoot. Both legs rank it below the regen cut; Qwen notes heavy armor reads closer to the Deathless identity (highest armor) than to Corsair raid feel, which is a further reason to cut regen before armor.
4. One ship swap: c_hulk to c_reaver (both legs, ranked last/highest cost by both). Removes the presumed anchor tank and leaves a two-hull cheap raider fleet. Carrier-flag consequence is UNSURE: DeepSeek infers from the carrier yes flag that c_hulk is the carrier here, but labels that inference, and its "Not checked" section repeats that the hull mapping is inference. Do not test this swap until Opus settles how the carrier flag is set.

Overshoot flag (both legs, strong for vesh): vesh is only 4 points over the ceiling on B0, and if the rerun drops the matrix as the B2 record suggests, vesh could land in band or below it with no lever at all. Measure the rerun first; a nerf applied blind risks pushing under 50.

## Mending (Chorus), 93%, HIGH: test hullRegenPct .06 to .05 first, then .04

Current state (pack, both legs agree): fleet [b_razor, b_razor]; perk Regrowth, ships regrow 6% of hull each round (hullRegenPct .06); Command Regrowth tide (25% regrow, heals destroyed sections); rounds 9.6; carrier no; cost 45. Cause is UNSURE in both legs: the highest per-round regen number in the evidence, on only two hulls, plus the approved feed mechanic (nearby kills restore hull) and a section-healing Command, against same-faction matriarch (68%, no regen perk) and razormaw (74%). The pack does not isolate the cause and hull stats are absent.

Escalation ladder, smallest feel change first (chair ladder):

1. Perk number: hullRegenPct .06 to .05 (DeepSeek test-first). Regrowth remains; Chorus regeneration identity is intact. Direction: down toward 90.
2. Perk number: hullRegenPct .06 to .04 (Qwen test-first, DeepSeek second). Same perk, one more point down, only if step 1 lands short.
3. One ship swap: one b_razor to b_drone (Qwen only). Stays inside "massive cheap bodies" identity while cutting healed mass and damage output. Razor-versus-drone stats are UNSURE (role inference only).
4. Starting fleet change: drop to a single b_razor (DeepSeek only, ranked last/highest cost). A one-ship Chorus fleet is a large identity change, and both legs' logic agrees a fleet-size cut is the biggest feel change for a swarm admiral. Real undershoot risk past the 50 floor; test only if the perk steps land short.

Overshoot flag (both legs): same as vesh. If the rerun lands mending in band on its own, the nerf risks pushing under 50; measure the rerun first. Qwen's rejected swap is carried as a guard, not a lever: b_razor to b_brood would be buff-shaped and could entangle the carrier-flag question (matriarch runs b_brood and is carrier flagged), so it is not proposed.

## Voice (Chorus), 94%, HIGH: test dmgPct .15 to .12 first, then .10

Current state (pack, both legs agree): fleet [b_razor, b_spitter, b_drone, b_drone]; perk Acid chorus, +15% damage with every weapon (dmgPct .15); Command Discordant volley (every ship spits a free volley immediately); rounds 7.0, the fastest sector 1 row in the pack (DeepSeek verified this against the CSV; next lowest is sable at 7.7); carrier no; cost 80. Cause is UNSURE in both legs: a four-hull start (joint-largest in the pack, with malek, vorn, sable, and anuket; the Qwen leg's "largest" wording is corrected here to joint-largest) plus an unconditional +15% to every weapon, where razormaw's +15% is rear-arc only and sits at 74%, plus a free-volley Command. Which driver matters more (fleet size or flat damage) is UNSURE in both legs.

Escalation ladder, smallest feel change first (chair ladder):

1. Perk number: dmgPct .15 to .12 (DeepSeek test-first). Acid chorus still boosts every weapon, just less. DeepSeek notes a 1-point cut cannot be supported from the pack as enough to move a 94% row, which is why the ladder starts at 3 points, not 1. Direction: down toward 90.
2. Perk number: dmgPct .15 to .10 (Qwen test-first, DeepSeek second). Same perk, one more step down, only if step 1 lands short.
3. One ship swap: b_spitter to b_drone (Qwen only). Keeps the four-body swarm shape while flattening the fleet toward uniform cheap bodies. Spitter-as-damage-hull is role inference only (from Voice's own Command text); stats UNSURE.
4. Starting fleet change: drop one b_drone, four hulls to three (both legs, ranked last/highest cost by both). Matches the three-hull shape of razormaw (74) and grax, but fleet size is the most visible thing about a swarm admiral, so it ranks last on feel even though it keeps the swarm.

Overshoot flag (both legs, strongest wording for voice): voice is the highest of the three at 94, and if the rerun brings voice inside the band unaided, the perk cut could drop it below 50. Qwen adds the reverse caution: a perk cut alone may prove too small to move a four-hull fleet out of 94, in which case escalate to the swap or the fleet cut rather than stacking a second perk cut beyond .10 without measuring. Both cautions stand; measure between steps.

## Conditions and open items for B3 (Opus tests, Opus decides)

1. Rerun first, especially for the highs. No high-side lever (vesh, mending, voice) is applied until the post-escort-fix rerun measures that admiral. Grax up-levers apply only if the rerun still shows him below 50. This condition comes from both legs and from S5; it is the single most important sentence in this synthesis.
2. Shared-perk code check (DeepSeek guard, adopted). If Opus finds any perk fx above is shared in code rather than admiral-specific, stop and recheck the other admirals in that faction before testing. The pack does not settle this; data.js writes fx per admiral, but fx keys recur across admirals, and that recurrence is not by itself proof of sharing.
3. Carrier-flag mechanism check. Before any swap involving c_hulk (vesh c_hulk to c_reaver, grax c_raider to c_hulk), Opus settles how the CSV carrier flag is set. Until then, both swaps carry carrier-flag consequence UNSURE.
4. Command-scope question open (Qwen leg, UNSURE). Whether a Command number counts as a "perk number" under the brief's lever types is unresolved. Neither leg proposes a Command edit, so B3 can proceed without resolving it, but Opus should rule it before anyone proposes a Command lever in a later job.
5. Effect sizes are UNSURE across the board. No lever-to-points mapping exists in the pack or in either leg. The ladders above are ordered by feel and by smallest step first precisely because the point effect of any step cannot be stated from this evidence. Opus measures each step in the sim; a step that lands short escalates, a step that overshoots stops.
6. Identity constraints respected by every lever above (both legs, chair confirms): Corsair close-range raiders paid in salvage (no lever removes speed, boarding, or salvage feel; armor cuts are ranked below regen cuts partly because heavy armor reads Deathless); Chorus swarm that eats with regeneration and no repair (no lever removes regeneration or bodies first; number cuts come before body cuts); no new rule, no new weapon kind (kinds remain battery, flak, lance, torp, bio, gauss, sq per F23), no new ship, no cost change, no carrier ban (F22: carriers stay, priced up), no difficulty-dial flattening (difficulty ramps by more ships per the Oct 24 ruling).
7. No price-ladder number is used as a settled balance value anywhere in this synthesis (both legs agree; the price drafts predate the Hegemony ruling except the 1.0 row, and the Qwen price leg is two unranked variants).

## Sources

- Evidence pack: workspace/voidsworn-brief25b/job_b_evidence.md (not pushed; chair working file).
- Baseline: contrib/opus/compute/bossmatrix_admirals.csv (sector 1 rows quoted in full in the pack; sector 2 and 3 rows excluded as targets).
- Boss context: contrib/opus/compute/bossmatrix_by_boss.csv (sector 1: hegemony 47, corsair 81, chorus 66, ithar 71, deathless 77, voidsworn 81).
- Admirals and fleets: data.js:201-263 (all 24 admirals; the four outliers' values quoted in the pack).
- Identity and rulings: contrib/muse/reviews/asymmetry_decision.md; FINDINGS S5, S6, F22-F27 (F22 carriers stay priced up; F23 seven weapon kinds only; F24 fleetPower and per-sector budget exist; F25-F27 fixed or already done).
- Price caveats: contrib/muse/reviews/price_ladder_synthesis.md (GO WITH CONDITIONS; Qwen leg two variants, Response 2 Deathless battleship math wrong, Hegemony passages stale except the 1.0 row).
- Legs: contrib/deepseek/reviews/b3_admiral_levers_deepseek_2026_10_25.md (+ raw at contrib/deepseek/b3_admiral_levers_deepseek_raw_2026_10_25.md); contrib/qwen/reviews/b3_admiral_levers_qwen_2026_10_25.md (+ raw at contrib/qwen/b3_admiral_levers_qwen_raw_2026_10_25.md).

## Not checked

- Hull stats, weapon stats, ship prices, and hull roles beyond the hull IDs in the pack. Every hull role claim in either leg (hulk as tank, spitter as damage hull, drone as cheap body, reaver versus raider) is role inference from fleet usage only.
- The actual post-B2 escort-fix rerun values on the PC. Nothing in this synthesis can be confirmed against them.
- The exact win rate movement from any proposed number change. No lever-to-points mapping exists in the evidence.
- Whether any perk fx is admiral-only or shared in code (condition 2 above).
- How the CSV carrier flag is set, and therefore the carrier-flag consequence of any c_hulk swap (condition 3 above).
- Whether Command ability numbers count as "perk numbers" under the lever rules (condition 4 above).
- The true cause of any of the four out-of-band rows. Both legs label their causes as inference; the pack does not isolate a cause for any row, and the boss-faction composition per admiral row is not given.
- Command interactions with the proposed levers (DeepSeek "Not checked"), and the price ladder's settled values (both legs agree: none used).
