# Measurements addendum: review adjudication and the high-power rerun (Oct 29, 2026)

Chair document amending contrib/muse/reviews/measurements_2026_10_29.md after the DeepSeek and Qwen review legs (filed under contrib/deepseek/reviews/ and contrib/qwen/reviews/), the powered Nemesis rerun (contrib/muse/reviews/measurements_nemesis_rerun_2026_10_29.md, 3,930 battles), and the six-level favour sweep (contrib/muse/reviews/boon_favour_sweep_2026_10_29.md, 237,600 offers). The Argon review leg is still outstanding; if it lands anything new, this addendum gets a dated extension rather than a rewrite.

## What changes in the filed record

Three filed claims do not survive at power and are corrected here. Everything else in the measurements document stands.

## 1. Nemesis snowball: the verdict holds, the numbers shrink, one exception appears

The rerun confirms the direction of the original verdict and corrects its magnitudes. Per-claim:

- Base premium flat at about 1.3x: CONFIRMED, now with spread (live-battle ratios 1.36 / 1.33 / 1.27 across sectors, standard deviations 0.15 / 0.19 / 0.08). The base fleet is power-indexed and cannot run away.
- Sector 1 growth cost of 0 points: WEAKENED. The trait package alone costs +8.5pp of player win rate, and the full sector 1 package costs a significant +12.3pp [+1.7, +22.9]. The first meeting is not free.
- Sector 2 first-adaptation step of 35pp: WEAKENED. The step is real and significant at +14.6pp [+3.2, +26.0], but 35pp is outside the interval, and the step decomposes into the trait package (about 8.5pp) plus one adaptation (about 2 to 7pp). It is a slope, not a cliff.
- Sector 3 growth cost of 25pp: size CONFIRMED at +27.7pp [+16.4, +39.0]. The "no widening versus sector 2" rider is WEAKENED: the change is +13.1pp with an interval that includes flat but effectively rules out narrowing.
- Weakness value of +20pp (sector 2) and +10pp (sector 3): sector 2 REFUTED (rerun +3.8pp, interval excludes 20), sector 3 WEAKENED (+3.8pp, interval includes both 10 and 0). At this power no sector shows a significant weakness value. The honest claim is: weaknesses help a little, plausibly, and the size is unmeasured. The original document's payback figures are withdrawn.
- Full-Nemesis win rates of 60 / 65 / 45: CONFIRMED (rerun 67.7 / 62.3 / 52.3, originals inside all intervals).
- Nemesis fights run long: CONFIRMED, modestly (means +0.5 to 1.0 rounds by sector 3, medians 8 vs 6 at sector 3).

Adaptation isolation (new): against a no-adaptation baseline, armor is the largest single adaptation at +12.5pp and only borderline significant; aim +10.8pp; evasion, point defense, and shields nonsignificant; pooled faction specials about zero. No single adaptation drives the step, so there is no one-line tuning fix.

Battered arrivals (new, from Qwen's accepted objection): the growth cost widens sharply for degraded fleets in sector 2, from +14.6pp at full strength to +28.1pp at 65% hull and +38.1pp at 40%. Sector 3 stays flat because fleetPower indexing collapses the enemy CP ratio for battered fleets (1.27 down to 0.92 at 40%): the compensation works at sector 3 scale and barely at sector 2. Given the ruled loss rate, battered arrivals are the typical case, so the sector 2 numbers are the ones to tune against.

The Chorus exception (new, and the one genuinely snowball-shaped channel): on its fast adaptation cadence, Chorus costs +19.2pp [+6.9, +31.4] at sector 2 and +30.8pp [+19.8, +41.9] at sector 3 over Chorus at the standard cadence, and the sector 3 fast-cadence meeting sits at a 15.8% bot win rate. The headline is therefore amended: KEEPING PACE for the standard cadence, with the Chorus fast cadence named as a tuning target.

Still unresolved, stated plainly: the second adaptation's cost (two arms disagree, bounded at about 12pp); whether the sector 3 widening is real and what drives it; and the true three-meeting trajectory, which the current tooling cannot simulate (the campaign runner never spawns the campaign Nemesis), so the rerun substitutes full-strength snapshots, three battered levels, adaptation-count arms, and the cadence arms.

Framing caveat (Qwen, accepted): all win rates are bot-piloted. An informed human likely sits above the bot at full strength and below it when battered and improvising; treat the absolute rates as a bracket, not a prediction.

## 2. Boon offer tax: the distribution stands, the gloss is demoted, the duo is a separate defect

The distribution measurement was near-exact enumeration, not sampled battles, and both review legs leave it standing: backfill is 0.0% while the patron fields 3 or more useful boons, then exactly 1 filler per offer at 4 held and 2 at 5 held; kit coverage is a second, graded trigger (a gun-only fleet under Hunger starts with 2 fillers from the first node). "Cliff" describes only the pool-exhaustion trigger; the kit trigger is a gradient. The original text now reads that way.

Three qualifications:

- The "about 17% less expected effect per filler pick" gloss is demoted from a finding to an estimate. It leans on mean rarity multipliers, including the Legendary multiplier of 1 at data.js:620, and on uniform favour. The rarity distribution gap is the finding; the effect-size translation is approximate.
- The tax's shape across favour is now measured (sweep, filed alongside): a two-step staircase. Favour 0 and 2 (tier 0): no tax, gaps of 0.2 to 0.5pp. Favour 4, 8, and 15 (tiers 1 and 2): an identical flat step of about 15pp in every cell; the three levels return literally identical distributions, because rollRarity (core.js:177) tests only tier 1 or higher and tier 3, and tier 2's perk is a starting protocol, not rarity. Favour 25 (tier 3): the gap jumps to about 52pp (on-patron 100.0% Rare-or-better versus about 48% for fillers). Backfill incidence is favour-independent at every level; favour changes only what a filler rolls, never how often one appears. The sweep reproduces the original shared cell within noise (63.0% versus 62.9% at favour 4), so the two runs agree. Design consequence: the tax is worst exactly at full sync, where it silently breaks the tier 3 "never Common" promise inside the synced patron's own offers, and there is no mid-favour slope to tune, only the two steps.
- The duo-at-Common observation is reclassified (Qwen's sharper read, accepted): it is a separate defect kind, not part of the tax. The tax is a missing-argument bug (rollBoonOffer rolls fillers without the patron, so rollRarity never sees the favour). The duo picks are a skipped roll entirely (they enter at hardcoded Common, r:0). Different root cause, different fix. The Q7 fix spec in contrib/muse/reviews/ruled_fixes_spec_2026_10_29.md must name the duo case separately or a patch will fix one and leave the other; the chair flags that as a required amendment to the spec when Opus picks it up.

## 3. What the review legs changed

DeepSeek's verdict was MEASUREMENTS OVERREACH; its noise objections stand and are the reason the rerun exists. Qwen's verdict line said MEASUREMENTS HOLD while its body raised eight objections; the chair reads the body, and most of them are accepted above (noise intervals, battered arrivals, the duo reclassification, the cliff-versus-gradient wording, the favour mid-range, now swept). The original chair headline to the designer stated the Nemesis pattern more firmly than n=20 supports; that overstatement is owned here, and the corrected figures in section 1 replace it.

Net for Opus: the Q6 answer is measure-first satisfied. Standard cadence needs no tuning. Two tuning candidates, in order: the Chorus fast cadence (sector 3 meeting at 15.8%), and the sector 2 battered-arrival width. The Q7 answer is unchanged in substance: the tax is real, conditional, and worst for the most invested players; its fix spec needs the duo named separately.
