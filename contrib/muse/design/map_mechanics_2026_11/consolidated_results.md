# Voidsworn battle design: consolidated results, Nov 17, 2026

Everything measured on Nov 17, 2026 in local copies of the sim (measure_map.js harness, Node 22, mirror fleets unless noted, medians throughout). Sources: issue 1004 study and its speed and range sweeps, the whole-map design round and its probes, the sizing and scaling test, the feel test, the mechanics council round and its test matrix. Battle counts: 1004 options and follow-ups about 500; speed sweep 864; range sweep 1,296; coverage probes 324; sizing and scaling 384; follow-up objective probes 72; feel test 180; mechanics matrix 384 plus 192 asymmetric. Roughly 3,900 battles in total.

## 1. Map size

Verdict: size is not a lever. Coverage falls as the board grows, and expansion to 42x30 is refuted under both objective geometries.

Rout coverage by size (probes): 30x22: 0.174-0.181. 34x24: 0.144-0.160. 38x26: 0.118-0.135. Bigger maps are empty margin around the same meeting point.

Issue 1004 options (belt, station, storm pooled, strip arena, 72 paired battles each):

| Option | Board hexes | First contact | Mean rounds | Move-only |
|---|---|---|---|---|
| Today, 30x22 | 361 | 1 | 10.0 | 13.1% |
| Bigger board only, 38x26 | 609 | 12.5 | 11.6 | 24.2% |
| Bigger board, +1 speed | 609 | 12.0 | 10.4 | 20.4% |
| Bigger board, +2 speed | 609 | 12.0 | 9.8 | 19.2% |
| Corridor shape, today's canvas | 267 | 1 | 10.7 | 12.6% |
| Hourglass shape, today's canvas | 326 | 1 | 10.3 | 13.4% |
| Lanes shape, today's canvas | 361 | 1 | 11.5 | 13.8% |
| Archipelago shape, today's canvas | 330 | 1 | 10.9 | 14.9% |

Sizing test under plural-site hold (384 battles): coverage for 1 relay vs 3 relays at base stats: 30x22: 0.163 vs 0.160. 34x24: 0.128 vs 0.131. 38x26: 0.113 vs 0.110. 42x30: 0.090 vs 0.089. At 42x30, first contact at base stats is activation 24 (a full extra approach phase), move-only reaches 35.8%, coverage across all its configs is 0.080-0.103, the lowest measured anywhere.

Size roles, measured under both geometries: 30x22 is the knife-fight size (contact activation 0-2, best coverage). 34x24 is the sweet spot for objective play. 38x26 is playable but pays an approach tax (first contact 12-13) that only the extreme stat corner relieves. 42x30 is out.

The one bigger-board form that works: 38x26 with fleets deployed inward at today's roughly 16-hex gap (chair follow-up, 72 battles): first contact 0, 9.8 rounds, move-only 5.3%, the best pace numbers in the whole study. The extra room becomes manoeuvre room instead of approach distance. Costs: full canvas change in both rule copies, and an aesthetic risk (empty rim) the sim cannot judge. Needs a human playtest before adoption.

Crowding check: a 7 vs 14 battle on today's canvas gives contact 1 and move-only 27.1%; on the big canvas with edge deployment, contact 23 and move-only 40.3%. Crowding makes the big board worse.

## 2. Shapes, arenas, placement

1004 recommendation, council unanimous: SHAPED FIELDS. Keep the 30x22 canvas, hull speeds and deployment gap; curate shapes and arenas. Hourglass becomes a standard shape (contact 1, rounds 10.3, move-only 13.4%, a focal point and a flank-or-choke decision at zero pace cost). Corridor weighted for routs (lowest move-only, 12.6%). Archipelago weighted for belt and graveyard. Lanes stays rare (longest battles, the study's only 30-round timeout).

Arenas matter more than shapes: a rout rolls strip 30%, square 35%, round 35%. On belt, the square arena's approach is the slowest standard configuration measured (first contact 9, rounds 10.4); round is instant (0). Recommendation: cut square's weight for standard routs, give the share to strip and round.

Baselines by map kind (strip, open, 24 battles each): belt first contact 1, 10.7 rounds, move-only 15.4%. Station 2, 9.8, 14.0%. Planet 1, 9.7, 9.3%. Storm 1, 9.6, 9.9%. Graveyard 0.5, 10.0, 10.0%.

Defend on station (strip): battles end at the 6-round objective clock, first contact 1, move-only 16.4%, the highest measured. The attacker spends its turns crossing to the 19-hex station (R314) and its debris band.

Placement findings inside objectives: the strip arena, not the canvas, limits relay separation in the plural-site prototype (achieved minimum separations 7-8 hexes at 30x22, 10 at 34x24, 11 at 38x26, 12-13 at 42x30). Hunt's degeneracy is a placement bug: line deployment starts the flagship inside weapon reach at activation 0, so its existing flee term never expresses; the hunter won 12 of 12 at both sizes, coverage 0.089 and 0.058, rounds 2-3. The fix is deployment-first (far edge, escorts screening 4-6 hexes ahead, contact tuned to rounds 3-4 inside the round 6 jump-out clock).

## 3. Speed

Dose-response is flat where it matters. On 38x26, first contact stays at activation 12-13 at every speed up to x2.0 tested alone; +0, +1 and +2 flat speed on the big board all land at about 12. The approach round is structural (deployment distance), not a speed problem.

In the sizing test, speed x1.5 shortens battles (rounds 6-8) and does not lift coverage at any size under either geometry. On 42x30 it halves the wait for first contact (activation 24 to 13) without making the map used.

Asymmetric speed (one side faster) buys win rate, 7-8 of 12 in the probes, not map use. Speed expresses itself as a race advantage to the one point of value.

A fleet-wide speed rise on today's canvas is rejected: contact is already 1 activation, and the balance tax (torpedoes, ramming, speed-granting admirals and modules) is paid for no measured gain.

## 4. Range

Range is the stronger of the two stat levers, but it changes fighting distance, not spread. In the range sweep (1,296 battles), range alone to x1.5 does not move first contact on 38x26 (stays 12-13); only speed x2 combined with range x1.5 drops it to 1. Range is the stronger lever against move-only turns; rounds stay flat to slightly up as range grows.

In the sizing test, range x1.5 stretches mean firing range to 4.3-5.0 (from about 3.1) and brings first contact much earlier on 34x24 under plural sites (activation 12 to 2) and on 42x30 (24 to 13). Coverage stays flat. Asymmetric range stretches mean firing range 3.44 to 3.84 at x1.5 and buys almost nothing else.

Falloff form (mechanics matrix, section 7): the shipped accuracy falloff vs a damage-band form (full damage inside optimal range, tapering to 60% at max range, accuracy falloff off). Mirror test null, as expected with identical range profiles. Asymmetric test in section 7.

Combined stat arms (sizing test): speed and range together cut move-only hard on 30x22 and 34x24 (down to 0.8-12.0%) and barely on 42x30 (19.5-21.4%). The extreme corner (speed x2 + range x1.5) is the only arm that moves first contact on 38x26 (13 to 6); coverage there still falls slightly (0.102). No stat arm, at any size, under either geometry, raises coverage. Across 2,160 sweep battles: stats change the walk and the fighting distance, never the spread.

## 5. Objectives

Coverage probes (324 battles): no existing objective beats the rout baseline. Ambush is a knife fight (move-only 1.7-2.8%, first shot activation 0, coverage 0.119 and 0.104 at 34x24 and 38x26). Defend 0.133 and 0.112 (parks at the station). Hold 0.128 and 0.116. Flagship 0.151 and 0.131, baseline-shaped and longer. Break 0.121 and 0.099. Intercept has the highest combined coverage (0.163 and 0.147) but it is one side's forced march: enemy coverage 0.095-0.100 against player 0.063-0.072, move-only 41-43%. Hunt is degenerate (section 2).

Plural sites (build 1 prototype, 384 battles with section 1): misses its pass numbers. On 34x24 the targets were coverage above 0.18 (got 0.131), both sides above 0.09 (got 0.072 and 0.079), shot cluster at most 0.40 (got 0.48); only rounds passed (10.0 in 8-12). Shot clustering unchanged everywhere (3 relays 0.44-0.49 vs 1 relay 0.43-0.48). The council's move-only prediction split (DeepSeek rise, Qwen fall) resolved as neither: movement is unchanged because the fleets do not actually split.

Follow-up probes (72 battles, 34x24 and 38x26):
- Sites plus rent (a held relay fires once per round at the nearest enemy capital within 5 hexes, 12 damage, on the station battery pattern): coverage 0.134 and 0.113 vs controls 0.131 and 0.110; cluster unchanged. Rent does not spread the battle, because nothing in movement scoring knows the battery exists.
- Objective pull cranked (hold weight 1.6 to 4.0): coverage FALLS to 0.123 and 0.088, move-only jumps to 35.8% and 60.6%, cluster rises to 0.59, rounds collapse to 5.0 and 4.0. A louder objective converts firing turns into transit turns and piles the fleets onto relays instead of each other.
- Majority scoring (score only while holding 2+ relays): coverage 0.133 and 0.114, flat; rounds lengthen to 11.0 and 11.5; the scoring rule does not reorganize the bots.

Final state across 456 objective battles: no objective-side variant spreads the battle. The attractor is not the objective hex; it is the enemy fleet itself. In movement scoring, offense against the fleet dominates and the objective term is a tiebreaker that binds only when a ship has no shot. Anything the scoring cannot see does not move ships; anything that shouts over it degrades the fight. Spread, if it ever exists, has to be built inside movement scoring itself.

Design round output (not yet built or tested beyond build 1): pluralize points of value (builds 1-3: hold, then defend, intercept, break), the hunt deployment fix (build 2), reserves as a timed commitment with speed-linked flank entry (build 4), deployment packages as hidden opposed choice (build 5, only after plural sites). Refused unanimously: bigger maps as a fix, global stat buffs as pacing fixes, random events as structure, terrain-only fixes, free deployment without opposed choice, fog of war, new encounter types beyond the eight, speed as activation currency.

## 6. Feel test: 1.25 speed and range, whole numbers (180 battles)

Ryan's frame: not coverage, feel. Fast ships, movement that stays meaningful after shooting starts, options that feel different.

Baseline correction: the standing slugfest is not literal. At base stats, 91-94% of post-contact activations already include a move and 78-88% include move-and-fire. What is small is distance: 2.3-2.8 hexes per move, a shuffle inside the blob.

At 1.25 combined (rout; hold tracks the same): distance per move rises everywhere, 2.75 to 3.24 (30x22), 2.54 to 3.19 (34x24), 2.55 to 2.97 (38x26), about a quarter to a third more travel per activation. Move-only turns fall hard on 30x22 (15.9% to 3.8%) and 38x26 (27.8% to 18.2%), moderately on 34x24 (20.9% to 15.6%). First contact on 34x24 rout: activation 12 to 4 (hold: 12 to 2). On 38x26 barely (13 to 12). Move-and-fire on 38x26 rout rises 78.0% to 93.1%. Rounds shorten about 1 (hold on 30x22 drops 9.0 to 5.5 as the relay race accelerates). Coverage flat.

Against 1.5: 1.25 captures most of the feel change; 1.5 goes clearly further only on distance per move (3.94 vs 3.19 on 34x24 rout). Diminishing returns past 1.25.

Cautions: whole-number rounding is lumpy per hull (speed or range 5 gains 20%, 6 gains 33%), which is also a source of difference between options. And the incentive structure is untouched: bigger budgets make the same repositioning moves bigger; movement still buys nothing new. Chair verdict: 1.25 combined, whole numbers, is a defensible global feel setting as a pacing and texture improvement, not a positional one. Ryan has not formally ruled on adopting it.

## 7. Mechanics and AI behavior (council round + test matrix)

Council framing (five legs: blind Rey, DeepSeek, Qwen, ChatGPT, Flash; Grok parked): the problem is a movement-value problem, not a movement-frequency problem. Consensus: evasion from movement first; multi-bearing attacks should pay; light coordination over independent per-ship optimization; spatial fields late and coarse; objectives closed as a lever, unanimously. The one fork was scoring surgery (multiplicative restructure vs two-pass selection first); the chair sequenced two-pass first, evidence before architecture.

Code facts that reframed the tests: the shipped game already contains first versions of several council ideas. Motion evasion is live (a ship that moved 3+ hexes is -5 to be hit, one that sat still is +10; Ithar -18 after 2+). Broadsides pay for moving (+10% damage after 2+ hexes, +45% for Voidsworn). Rear attacks halve armor and add crit. Weapons have arcs and optimal ranges with accuracy falloff past optimal. Factions have preferred engagement ranges in their AI profiles. And the bot already prices movement evasion per candidate destination (stateView stamps the candidate with its path length, so the evasion gradient is inside the threat estimate); the gap is magnitude, a few points against offense swings of tens.

Test matrix (16 configs, 24 battles each, 34x24 rout mirror, 1.25 baseline; new metrics: netDisp = net displacement per post-contact activation, base 3.08; multiDisp = displacement over a two-activation window, base 3.81; bearDiv = distinct firing bearings per target, base 2.38; base distance per move 3.25, cluster 0.33, coverage 0.15, rounds 9.5, no timeouts anywhere):

- Two-pass selection (pick for movement among destinations within 10% of a volley of the best score): PASS. netDisp 3.73 (+21%), distance per move 3.83 (+18%), multiDisp 4.31 (+13%), cluster 0.29, rounds 10.0. Bot change only, no rules change. The clearest movement-feel win.
- Multiplicative scoring (response-curve restructure): PASS on spread. Coverage 0.17 (only config to move it), cluster 0.22 (biggest drop), mean firing range 3.91, multiDisp 4.46 (+17%), netDisp 3.34 (+8%), rounds 11.0. Ships fight further apart and further out.
- Momentum (straight-line move of 4+ hexes, +15% damage): modest positive. netDisp 3.26 (+6%), multiDisp 4.21 (+10%), bearDiv 2.57.
- Long-gun close weakness (-20 to hit at range 2 or less for range 5+ guns): works as designed. Mean firing range 3.74 (+10%), rest near base. Long guns keep their distance.
- Range falloff, damage-band form: mirror null (expected). Asymmetric test, CP-matched fleets (Hegemony gun line, 16 CP, vs Corsair brawlers, 16 CP), both seats, 48 battles per ruleset: Hegemony wins 33 of 48 under the shipped accuracy falloff, 29 of 48 under the damage band. Both seat directions moved the same way (Hegemony as player 62% to 54%; Corsair as player 25% to 33%). Direction matches the design intent, closing pays more under the band; size is modest and inside noise at this count. Promising, not proven. (An earlier attempt with a 13 CP Corsair fleet swept 48 of 48 and was discarded as mismatched.)
- Evasion strength (evade 5 to 12; also threshold 2 variant): battles stretch (rounds 9.5 to 11.0), movement shape unchanged. A defensive dial, not a feel lever.
- Rear-quarter hit bonus (+10 on top of the existing rear package): null. Bots do not chase rear shots more.
- Deconfliction (destination repulsion between allies): null at tested weights.
- Coarse fields (opportunity minus threat counts, weight 3): weak to null (multiDisp 4.09, rest flat).
- Persistent course (continuity bonus toward last destination): NEGATIVE. netDisp 2.55 (-17%), distance per move 2.77, cluster up. Anchoring shrinks movement. Rejected as implemented.
- Turn-rate limit (one hexside of facing change per activation): null. Large facing changes are rare or cheap to give up.
- Spinal arcs (long turret guns restricted to front arc): null to negative (bearDiv 2.25).
- Torpedo forecasting: UNTESTED, not a null. The mirror fleets launch zero torpedoes, so the flag never engaged. Needs a torpedo-armed fleet.
- Stack (two-pass + evade 12): behavior equals two-pass alone (netDisp 3.70). Evasion strength adds nothing on top.

AI behavior caveats that apply to everything above: mirror win rates are not balance evidence in this harness, because the player seat (botUnit) and the enemy seat (veteran aiUnit) are different implementations and respond asymmetrically to the same change (two-pass alone showed 8% player wins; the stack showed 50%, with near-identical behavior numbers). Behavior metrics (displacement, distance, clustering, coverage, duration) are the readable outputs; balance claims need asymmetric or cross-implementation checks. The veteran AI already has fleet focus with stickiness, a death cliff, faction range profiles and per-site two-ship objective pulls; the player bot is the simpler scorer.

## 8. Status and availability

Delivered to the repo: the issue 1004 package only (branch muse/issue-1004, 14 files, byte-verified): the SHAPED FIELDS verdict, the options table, and the sweep findings. Local only, not on the repo and not seen by the Board: the whole-map design doc with sections 7, 7b and 7c (sizing test, objective follow-ups, feel test), the mechanics council synthesis, and this mechanics test matrix. Working folders: voidsworn-1004job, voidsworn-mapjob, voidsworn-mechjob in the agent workspace.
