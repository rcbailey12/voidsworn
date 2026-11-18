# Map evaluation on 30 × 22

**Playtest 30 × 22 with the new shape weights, x1.25 speed and range rounded to whole numbers, retuned Hunt, split Ambush banks and screened bosses. Keep today's starts for Engagement, Defend, Intercept, Breakthrough, Relay and Decapitation.** Engagement moves get longer and the quarry escapes 31% of the time, up from 9%. Hunt's first hull-to-hull shot lands in median round 3. Breakthrough and Decapitation are easier for the Hegemony mirror, by 28 and 16 points respectively.

| Encounter | First gun act | Hexes per move | Move only | Player win / quarry kill |
|---|---:|---:|---:|---:|
| Engagement | 1 → 0 | 2.90 → 3.52 | 11.1% → 4.0% | 41% → 37% |
| Ambush | 0 → 0 | 2.83 → 3.57 | 2.6% → 1.9% | 55% → 61% |
| Hold the station | 6 → 0 | 3.04 → 3.68 | 21.2% → 6.0% | 38% → 30% |
| Hunt | 0 → 13 | 3.41 → 4.57 | 7.5% → 15.7% | 91% → 69% |
| Intercept | 2 → 0 | 2.98 → 3.76 | 30.8% → 21.7% | 73% → 87% |
| Breakthrough | 0 → 0 | 3.23 → 3.91 | 5.7% → 6.8% | 37% → 65% |
| Relay | 0 → 0 | 2.97 → 3.35 | 11.4% → 2.4% | 50% → 59% |
| Decapitation | 2 → 0 | 2.90 → 3.47 | 10.7% → 4.4% | 36% → 52% |

Today → recommended package, with 100 paired seeds per row. Hunt counts quarry kills. Other rows use the game's win flag, which includes partial wins. [All 22,300 comparison rows](results.csv)

## What changed since run 1

- **Hunt has a chase.** Build 2 sent the quarry to its nearest east-edge exit and let it escape in all 100 seeds in both arms. The retune sends it across the board toward a west-side jump bearing and spreads the hunters by how far each ship can move and fire. Escape falls to 44% with placement alone and 31% with the full package. The first ship gun still fires in median round 2 and mostly engages wings at that point. Ship-on-ship fire and the first shot at the quarry both land in median round 3. [Hunt tuning data](hunt_tuning.csv)
- **Defend keeps today's start.** With new shapes held fixed, moving two pickets forward reduced defender wins from 34% to 20%. The original start also gives the defenders 30% wins with x1.25. The 19-hex station stays in every arm.
- **Sector 3 boss difficulty moves.** With shapes and x1.25, boss engagement wins were 54%. Screening the boss raises that to 69%, against 53% today. The test pick includes the screen and gives Ryan a chance to judge the easier approach.
- **The new faction sweep flags six seatings in both arms.** The largest change is Chorus as player against Hegemony Navy, from 50% today to 76% with shapes and x1.25 and 78% with the placement fixes.
- **Muse's feel test agrees on travel and move-only actions.** On 30 × 22, its x1.25 Engagement went from 2.75 to 3.24 hexes per move and from 15.9% to 3.8% move-only activations. With new shapes held fixed here, Engagement went from 2.90 to 3.52 and from 11.7% to 4.0%. Relay pace differed across the fixtures. Muse's length fell from 9.0 to 5.5 rounds, while this fixture averaged 7.9 → 8.1. Breakthrough was the exception to the move-only drop, rising from 5.0% to 6.8% at x1.25. Muse reported flat coverage with x1.25. This harness measured distance and activations, so there is no coverage comparison. [Muse feel test, section 6](../../muse/design/map_mechanics_2026_11/consolidated_results.md#6-feel-test-125-speed-and-range-whole-numbers-180-battles)
- **The retests narrow the AI claims.** Muse measured more displacement and a combat cost for two-pass, and Hegemony wins of 66/96 → 63/96 with the damage-band falloff, inside paired noise. Multiplicative scoring widened the fight and cost about 1.5 rounds when used by both controllers, with wins flat at 5/24. Its veteran-only arm raised player wins from 5/24 to 13/24. Our Engagement moved farther and ended sooner with the stat preset. Those results measure different levers, and the present tests use the ordinary scoring and accuracy falloff throughout. [Two-pass and falloff retest](../../muse/design/map_mechanics_2026_11/retest_results.md) · [Multiplicative retest](../../muse/design/map_mechanics_2026_11/mult_retest_results.md) · [Muse status](../../muse/design/map_mechanics_2026_11/STATUS.md)
- **DeepSeek's larger board showed a longer approach.** Its unchanged 30 × 22 Engagement fired on median activation 1, the same here. On 38 × 26, adding two speed still left its median first shot at activation 12. Its 19-hex Defend benchmark was 37.5% wins and 6.5 mean rounds, close to 38% and 6.5 here. Its no-shot metric counts more than move-only. [DeepSeek issue 1019](../../deepseek/map_pace_1117/README.md)

## Hunt settings

The quarry deploys one column in from the east edge. Its bearing is the nearest open hex to a point on the west edge, 45% of the way down the board. Two escorts start behind the quarry with a target separation of five hexes and are scored to hold their opening posts through round 2. The quarry adds 1 point per hex from the nearest hunter up to a distance of 9 and subtracts 10 points per hex from the jump bearing. It can move and fight from round 1. The jump still occurs at the end of round 6.

Each hunter's target starting gap is its longest non-flak gun range plus its movement allowance times the approach value below. The same rule recalculates the gap with each arm's actual stats, so the x1.25 arm starts the hunters farther back. Terrain and occupied cells can move ships off their target hexes. Each arm uses 100 paired seeds. The four neighbours vary only the approach value.

| Hunt approach value | Quarry escape, placement | Quarry escape, full | Hull contact in R3-4, placement / full |
|---:|---:|---:|---:|
| 3.5 | 34% | 19% | 88 / 56 |
| 3.75 | 42% | 29% | 98 / 65 |
| **4** | **44%** | **31%** | **94 / 72** |
| 4.25 | 69% | 39% | 100 / 69 |
| 4.5 | 78% | 40% | 100 / 73 |

At 4, the median initial gap from the closest hunter to the quarry is 18 hexes in the placement arm and 24 with x1.25. The two screen escorts land 4 to 6 hexes from the quarry in both arms. In the separate seed set 1100 to 1199, escape was 44% and 37%, respectively. The first hull-to-hull shot and first quarry shot stayed in median round 3. The earlier ship-gun counter, which includes shots at wings, stayed at round 2.

## Deployment pictures

Each sheet shows today's rules on the left and the test setup on the right, using the same seed. The Hunt sheet shows the retune. The other sheets show the run 1 full trial, including the alternative placements studied for Defend, Intercept, Breakthrough and Decapitation. The cards show the nearest player ship's distance to the goal. The arrows show facing. Gold marks objectives, the quarry or flagship, and the two Hunt screen ships. These diagrams come from the deployment code before the first activation.

| Encounter | Picture | Boss encounter | Picture |
|---|---|---|---|
| Engagement | [ME-ROUT](../../../docs/shots/map_eval_1118/ME-ROUT.png) | Sector 1 engagement | [ME-BOSS1-ROUT](../../../docs/shots/map_eval_1118/ME-BOSS1-ROUT.png) |
| Ambush | [ME-AMBUSH](../../../docs/shots/map_eval_1118/ME-AMBUSH.png) | Sector 1 ambush | [ME-BOSS1-AMBUSH](../../../docs/shots/map_eval_1118/ME-BOSS1-AMBUSH.png) |
| Hold the station | [ME-DEFEND](../../../docs/shots/map_eval_1118/ME-DEFEND.png) | Sector 2 engagement | [ME-BOSS2-ROUT](../../../docs/shots/map_eval_1118/ME-BOSS2-ROUT.png) |
| Hunt | [ME-HUNT](../../../docs/shots/map_eval_1118/ME-HUNT.png) | Sector 2 ambush | [ME-BOSS2-AMBUSH](../../../docs/shots/map_eval_1118/ME-BOSS2-AMBUSH.png) |
| Intercept | [ME-INTERCEPT](../../../docs/shots/map_eval_1118/ME-INTERCEPT.png) | Sector 3 engagement | [ME-BOSS3-ROUT](../../../docs/shots/map_eval_1118/ME-BOSS3-ROUT.png) |
| Breakthrough | [ME-BREAK](../../../docs/shots/map_eval_1118/ME-BREAK.png) | Sector 3 ambush | [ME-BOSS3-AMBUSH](../../../docs/shots/map_eval_1118/ME-BOSS3-AMBUSH.png) |
| Relay | [ME-HOLD](../../../docs/shots/map_eval_1118/ME-HOLD.png) | | |
| Decapitation | [ME-FLAGSHIP](../../../docs/shots/map_eval_1118/ME-FLAGSHIP.png) | | |

## Placement audit

The table measures the closest ship to the encounter goal and to the enemy line. Values are median and observed range in hexes. Opening gun is the share of seeds with a legal shot from the deployment hex. The trial columns use the run 1 placement fixes and new shapes at today's speed and range.

| Encounter | Goal gap today | Goal gap fixed | Line gap today | Line gap fixed | Opening gun today P/E | Opening gun fixed P/E |
|---|---:|---:|---:|---:|---:|---:|
| rout | 15 [7-19] | 15 [7-21] | 15 [7-19] | 15 [7-21] | 0% / 0% | 0% / 0% |
| ambush | 6 [4-9] | 8 [6-11] | 6 [4-9] | 8 [6-11] | 53% / 42% | 3% / 7% |
| defend | 2 [1-3] | 1 [1-1] | 15 [15-16] | 7 [7-8] | 0% / 0% | 0% / 0% |
| hunt | 5 [4-7] | 29 [26-31] | 5 [4-7] | 24 [20-26] | 82% / 86% | 0% / 0% |
| intercept | 11 [9-15] | 12 [10-16] | 15 [15-16] | 15 [12-22] | 0% / 0% | 0% / 0% |
| break | 15 [15-20] | 15 [15-16] | 6.5 [1-8] | 6 [6-8] | 18% / 19% | 18% / 18% |
| hold | 7 [4-10] | 7 [5-11] | 13 [7-20] | 15 [7-20] | 0% / 0% | 0% / 0% |
| flagship | 17 [10-22] | 20 [13-25] | 15 [8-19] | 15 [8-19] | 0% / 0% | 0% / 0% |
| boss1_rout | 14 [13-15] | 21 [14-22] | 14 [13-15] | 15 [14-17] | 0% / 0% | 0% / 0% |
| boss1_ambush | 8 [6-12] | 14 [7-19] | 6 [5-9] | 8 [7-11] | 42% / 32% | 0% / 0% |
| boss2_rout | 14 [13-14] | 21 [20-21] | 14 [13-14] | 15 [15-16] | 0% / 0% | 0% / 0% |
| boss2_ambush | 8 [6-11] | 15 [13-17] | 6 [4-7] | 8 [7-11] | 79% / 34% | 0% / 0% |
| boss3_rout | 14 [13-14] | 21 [19-22] | 14 [13-14] | 15 [15-16] | 0% / 0% | 0% / 0% |
| boss3_ambush | 9 [5-12] | 16 [12-18] | 5 [4-7] | 8 [6-11] | 88% / 35% | 0% / 0% |

- **Hunt.** The quarry starts 4 to 7 hexes away, ahead of its escorts, and 82 of 100 fleets already have a legal shot from spawn. All 100 saw first ship fire in round 1. The Build 2 trial moved the quarry to the far edge and the hunters to the opposite corner. Two screen escorts started 4 to 6 hexes ahead. The quarry scored distance from the nearest hunter and progress toward an exit hex. Escorts held their opening posts through round 2 by movement scoring. The jump still happens after round 6. First ship fire moved to round 2 on placement alone and round 3 with all three. In the full package, 53 of 100 fights opened fire in rounds 3 or 4, and only 19 of 100 fired at the quarry in that window. The quarry escaped in 100 of 100 in both placement arms. Today it escaped in 9 of 100 and was killed in 91. An escape is marked as a partial win by the game, which explains the 100% result in the full package.
- **Ambush.** The ordinary deployment put the enemy on a single bank in 10 of 100 seeds. The fixed split requires both banks and turns both groups toward the player. It produced two banks in all 100 seeds and cut player opening shots from 53% to 3% in the placement arm. The first legal ship gun still fired on activation 0 in the median fight after movement and Commands.
- **Defend.** The station takes up 19 hexes. The defenders start behind it and must come around to the attack side. The station guard-ring gap is a median 2 for the player and 8 for the attacker. The trial puts two fast pickets on the attack-side shoulders, one hex beyond the ring. This gets ships firing from the first activation, but the placement arm cut the defender's win rate from 34% to 20% against the same shapes. The forward start gave the attackers closer targets.
- **Intercept.** The escort line is on the right while the transports travel down the board. The convoy starts a median 11 hexes from the player and 14 from the exit. The baseline escort gap is 5 hexes, with a range of 1 to 8. The trial puts escorts just ahead and east of the convoy. Against the same shapes this narrows the escort gap from 1 to 9 hexes to 3 to 6. The complete convoy-stop rate is 14% today, 6% on shapes alone, 11% with fixed placement, and 28% with all three. The headline game win includes partial wins when too many transports get through.
- **Breakthrough.** The rear group starts facing west while pursuing ships to its east. The original deployment can also fall back into a half-board zone when the intended player band runs out of legal hexes. One baseline seed put opposing ships one hex apart. The trial turns the rear group toward the player and moves any displaced player spawn back toward its band while protecting a five-hex gap from the enemy. It raised the observed minimum separation from one hex to six and turned the rear pursuers toward the fleet in every trial. The Hegemony win rate fell from 35% to 25% with the new starts at the original stats and reached 58% with all three.
- **Decapitation.** An exposed flagship is a rare placement failure. In today's sample 98 of 100 flagships had a closer escort within six hexes. The tested four-hex rear offset increased the median target gap from 17 to 20. Protection was 96% on shapes alone and 97% with the placement change. A blanket move buys little protection in this fixture.
- **Boss engagement, sectors 1 to 3.** The boss starts at the front of its escort line. The boss was unscreened in every baseline seed in each sector. The trial moved it behind the escorts, putting the median gap at 21 hexes in all three sectors, up from 14. Escort protection reached 89% in sector 1 and 100% in sectors 2 and 3. Sector 3 player wins rose by 16 points with the placement, holding the new shapes fixed. The boss behind its screen may still be easier for this player bot to beat.
- **Boss ambush, sectors 1 to 3.** Sector 1 put all ships on one bank in 52 of 100 seeds. A boss can also start ahead of its cover in each sector. The trial splits the two banks and moves the boss behind its own bank's escort when one is available. Every trial had two banks. Protection went from 66/84/88% by sector to 89/100/100%, and opening player fire fell to zero from 42/79/88%.
- **Engagement and Relay.** The ordinary engagement opens a median 15 hexes apart and only reaches gun range after movement. The relay zone in Hold is a median 7 hexes from the player and 6 from the enemy. Neither side could fire from spawn in either fixture. The placement trial retains both starts.

## The five original setups and follow-ups

Each encounter has 100 paired seeds per setup. Shapes is the comparison arm for the two isolated levers. `Shapes + placement` adds the run 1 starts and Hunt movement scoring. `Shapes + x1.25` adds the stat changes. `All three` combines them and is also the recommended setup for Ambush and the six boss fixtures. The other starts use `Shapes + x1.25`, with Hunt using its retune. Gun act and gun round are medians. Rounds is the mean. Win is the game's result and Escape applies to Hunt. Cap gives the runs still active at round 30.

The new weights increased realized Hourglass from 16 to 179 of 800 ordinary battles. Corridor appeared in 15 of 100 engagements, up from zero. Archipelago went from 36 of 244 to 67 of 250 realized belt and graveyard maps. Strip arenas rose from 553 to 627 of 800 ordinary battles, which is part of the shape effect. Shapes alone held median first fire within one activation in every ordinary encounter, with a 22-point decrease in the Hegemony mirror Engagement win rate. Adding tempo increased move distance in every encounter. The tested placements mainly changed what was reachable or screened at the start, and their effect varied by encounter.

<details>
<summary>Every setup by encounter</summary>

| Encounter | Setup | First gun act | First gun round | Rounds | Move only | Hex / move action | Win | Escape | Cap |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| rout | Today | 1 | 1 | 10.8 | 11.1% | 2.90 | 41% | - | 0 |
| rout | Shapes | 1 | 1 | 10.2 | 11.7% | 2.90 | 19% | - | 1 |
| rout | Shapes + placement | 1 | 1 | 10.2 | 11.7% | 2.90 | 19% | - | 1 |
| rout | Shapes + x1.25 | 0 | 1 | 9.0 | 4.0% | 3.52 | 37% | - | 0 |
| rout | All three | 0 | 1 | 9.0 | 4.0% | 3.52 | 37% | - | 0 |
| ambush | Today | 0 | 1 | 9.0 | 2.6% | 2.83 | 55% | - | 1 |
| ambush | Shapes | 0 | 1 | 9.0 | 2.6% | 2.82 | 44% | - | 0 |
| ambush | Shapes + placement | 0 | 1 | 9.1 | 3.6% | 2.93 | 59% | - | 1 |
| ambush | Shapes + x1.25 | 0 | 1 | 7.8 | 1.3% | 3.46 | 61% | - | 0 |
| ambush | All three | 0 | 1 | 8.2 | 1.9% | 3.57 | 61% | - | 1 |
| defend | Today | 6 | 1 | 6.5 | 21.2% | 3.04 | 38% | - | 0 |
| defend | Shapes | 6 | 1 | 6.4 | 20.9% | 3.04 | 34% | - | 0 |
| defend | Shapes + placement | 0 | 1 | 6.2 | 12.9% | 2.93 | 20% | - | 0 |
| defend | Shapes + x1.25 | 0 | 1 | 6.0 | 6.0% | 3.68 | 30% | - | 0 |
| defend | All three | 0 | 1 | 6.2 | 4.4% | 3.39 | 31% | - | 0 |
| hunt | Today | 0 | 1 | 3.3 | 7.5% | 3.41 | 100% | 9% | 0 |
| hunt | Shapes | 0 | 1 | 3.4 | 7.4% | 3.41 | 100% | 14% | 0 |
| hunt | Shapes + placement | 20 | 2 | 7.0 | 30.0% | 3.70 | 100% | 100% | 0 |
| hunt | Shapes + x1.25 | 0 | 1 | 3.8 | 1.6% | 3.99 | 97% | 17% | 0 |
| hunt | All three | 24 | 3 | 7.0 | 18.8% | 4.28 | 100% | 100% | 0 |
| hunt | Shapes + retuned Hunt | 13 | 2 | 5.8 | 20.2% | 3.67 | 100% | 44% | 0 |
| hunt | Recommended | 13 | 2 | 5.4 | 15.7% | 4.57 | 100% | 31% | 0 |
| intercept | Today | 2 | 1 | 7.2 | 30.8% | 2.98 | 73% | - | 0 |
| intercept | Shapes | 1 | 1 | 7.1 | 29.2% | 2.98 | 70% | - | 1 |
| intercept | Shapes + placement | 4 | 1 | 6.6 | 33.5% | 3.00 | 78% | - | 0 |
| intercept | Shapes + x1.25 | 0 | 1 | 4.8 | 21.7% | 3.76 | 87% | - | 0 |
| intercept | All three | 0 | 1 | 5.0 | 26.8% | 3.74 | 87% | - | 0 |
| break | Today | 0 | 1 | 6.4 | 5.7% | 3.23 | 37% | - | 1 |
| break | Shapes | 0 | 1 | 6.3 | 5.0% | 3.19 | 35% | - | 0 |
| break | Shapes + placement | 0 | 1 | 6.2 | 4.9% | 3.23 | 25% | - | 0 |
| break | Shapes + x1.25 | 0 | 1 | 5.3 | 6.8% | 3.91 | 65% | - | 0 |
| break | All three | 0 | 1 | 5.0 | 6.3% | 4.01 | 58% | - | 0 |
| hold | Today | 0 | 1 | 7.7 | 11.4% | 2.97 | 50% | - | 0 |
| hold | Shapes | 1 | 1 | 7.9 | 10.9% | 2.94 | 49% | - | 0 |
| hold | Shapes + placement | 1 | 1 | 7.9 | 10.9% | 2.94 | 49% | - | 0 |
| hold | Shapes + x1.25 | 0 | 1 | 8.1 | 2.4% | 3.35 | 59% | - | 0 |
| hold | All three | 0 | 1 | 8.1 | 2.4% | 3.35 | 59% | - | 0 |
| flagship | Today | 2 | 1 | 10.5 | 10.7% | 2.90 | 36% | - | 0 |
| flagship | Shapes | 2 | 1 | 10.9 | 11.3% | 2.87 | 34% | - | 0 |
| flagship | Shapes + placement | 1 | 1 | 11.3 | 12.1% | 2.84 | 41% | - | 0 |
| flagship | Shapes + x1.25 | 0 | 1 | 9.5 | 4.4% | 3.47 | 52% | - | 0 |
| flagship | All three | 0 | 1 | 10.4 | 4.9% | 3.38 | 51% | - | 0 |
| boss1_rout | Today | 1 | 1 | 5.6 | 12.3% | 3.26 | 100% | - | 0 |
| boss1_rout | Shapes | 1 | 1 | 5.5 | 11.9% | 3.31 | 100% | - | 0 |
| boss1_rout | Shapes + placement | 1 | 1 | 6.0 | 16.1% | 3.33 | 100% | - | 0 |
| boss1_rout | Shapes + x1.25 | 0 | 1 | 4.6 | 3.6% | 4.00 | 100% | - | 0 |
| boss1_rout | All three | 0 | 1 | 5.2 | 7.2% | 4.02 | 100% | - | 0 |
| boss1_ambush | Today | 0 | 1 | 4.3 | 2.3% | 2.91 | 100% | - | 0 |
| boss1_ambush | Shapes | 0 | 1 | 4.5 | 3.9% | 2.99 | 100% | - | 0 |
| boss1_ambush | Shapes + placement | 0 | 1 | 5.5 | 11.8% | 3.05 | 100% | - | 0 |
| boss1_ambush | Shapes + x1.25 | 0 | 1 | 4.0 | 1.1% | 3.53 | 100% | - | 0 |
| boss1_ambush | All three | 0 | 1 | 4.8 | 3.9% | 3.62 | 100% | - | 0 |
| boss2_rout | Today | 1 | 1 | 9.4 | 10.3% | 3.07 | 95% | - | 0 |
| boss2_rout | Shapes | 1 | 1 | 9.3 | 9.8% | 3.05 | 97% | - | 0 |
| boss2_rout | Shapes + placement | 1 | 1 | 9.3 | 13.1% | 3.11 | 98% | - | 1 |
| boss2_rout | Shapes + x1.25 | 0 | 1 | 7.6 | 3.1% | 3.67 | 99% | - | 0 |
| boss2_rout | All three | 0 | 1 | 7.9 | 4.3% | 3.65 | 99% | - | 0 |
| boss2_ambush | Today | 0 | 1 | 7.2 | 2.1% | 2.78 | 100% | - | 0 |
| boss2_ambush | Shapes | 0 | 1 | 7.3 | 2.8% | 2.85 | 97% | - | 0 |
| boss2_ambush | Shapes + placement | 0 | 1 | 7.3 | 6.0% | 2.98 | 100% | - | 0 |
| boss2_ambush | Shapes + x1.25 | 0 | 1 | 6.5 | 1.6% | 3.34 | 98% | - | 0 |
| boss2_ambush | All three | 0 | 1 | 6.8 | 2.2% | 3.47 | 99% | - | 0 |
| boss3_rout | Today | 1 | 1 | 15.1 | 10.3% | 2.99 | 53% | - | 6 |
| boss3_rout | Shapes | 1 | 1 | 14.2 | 10.1% | 3.00 | 53% | - | 2 |
| boss3_rout | Shapes + placement | 1 | 1 | 13.9 | 11.9% | 3.03 | 69% | - | 5 |
| boss3_rout | Shapes + x1.25 | 0 | 1 | 14.4 | 4.1% | 3.49 | 54% | - | 4 |
| boss3_rout | All three | 0 | 1 | 13.1 | 5.0% | 3.50 | 69% | - | 1 |
| boss3_ambush | Today | 0 | 1 | 12.3 | 2.5% | 2.67 | 82% | - | 1 |
| boss3_ambush | Shapes | 0 | 1 | 13.5 | 2.9% | 2.73 | 70% | - | 3 |
| boss3_ambush | Shapes + placement | 0 | 1 | 12.7 | 6.4% | 2.87 | 82% | - | 0 |
| boss3_ambush | Shapes + x1.25 | 0 | 1 | 12.4 | 1.3% | 3.22 | 79% | - | 1 |
| boss3_ambush | All three | 0 | 1 | 12.1 | 2.5% | 3.34 | 88% | - | 1 |

</details>

## Faction check at matched CP

The six factions give 30 ordered non-mirror pairings and six mirrors, with 100 matched seeds and 16 CP on each side. Intercept adds three mission transports. The sweep cycles through eight ordinary encounters, so Hunt and Ambush each contribute 13 seeds per seating. The recommended package reuses the 74 identical battles per seating from shapes + x1.25. Boss starts have their own six paired fixtures above.

Player win rates include partial wins. Both setups flagged the same six seatings strictly more than 10 percentage points from today. The two bot policies differ, and the player has the same fallback Vex Command across factions. [Full matched-CP results](results.csv)

Hunt escape in this sector 1 mix was 41 of 468 (9%) with the recommended package, compared with 35 of 468 (7%) today. The 25% to 50% tuning result applies to the sector 2 Hegemony fixture. The broader faction mix still gives the hunters an easier chase.

| Player | Enemy | Today | Shapes + x1.25 | Recommended |
|---|---|---:|---:|---:|
| Hegemony Navy | Hegemony Navy | 70% | 88% (+18 pp) | 87% (+17 pp) |
| Hegemony Navy | Ashfall Hullbreakers | 69% | 82% (+13 pp) | 83% (+14 pp) |
| Ashfall Hullbreakers | Sunward Crusade | 86% | 69% (-17 pp) | 69% (-17 pp) |
| Chorus | Hegemony Navy | 50% | 76% (+26 pp) | 78% (+28 pp) |
| Chorus | Sunward Crusade | 57% | 42% (-15 pp) | 42% (-15 pp) |
| Eclipse | Hegemony Navy | 82% | 95% (+13 pp) | 94% (+12 pp) |

## What whole-number x1.25 does

The trial follows Muse's feel test. It multiplies actual battle-start speed and maximum weapon range by 1.25 and rounds with `Math.round`. Capital ships already gain 1 speed when `makeUnit` builds them. The table groups every hull by effective speed before bonuses from captains, admirals, modules or relics. Wings use their listed speed. The transport cap of 3 is applied before rounding, making it 4 in the trial.

| Effective base speed | Trial | Gain | Hull ids |
|---:|---:|---:|---|
| 2 | 3 | 50% | `h_boss`, `d_boss` |
| 3 | 4 | 33% | `reliquary`, `cathedral`, `ascendant`, `h_dominion`, `c_hulk`, `c_boss`, `b_brood`, `b_boss`, `d_harvester`, `c_hulk_g`, `d_harvester_t` |
| 4 | 5 | 25% | `penitent`, `h_vanguard`, `i_boss`, `d_jackal`, `vs_penitent_g`, `h_vanguard_g`, `vs_penitent_l`, `h_interdictor_e`, `c_marauder_g`, `b_razor_e`, `i_carrier_a`, `d_jackal_h` |
| 5 | 6 | 20% | `harrow`, `bomber`, `spore`, `h_interdictor`, `c_marauder`, `b_spitter`, `b_razor`, `i_carrier`, `d_scythe`, `vs_harrow_t`, `b_spitter_s`, `d_scythe_s` |
| 6 | 8 | 33% | `warden`, `fighter`, `h_picket`, `c_reaver`, `b_drone`, `i_song`, `h_picket_i`, `c_reaver_t`, `b_razor_s`, `i_song_w` |
| 7 | 9 | 29% | `c_raider`, `i_blade` |
| 8 | 10 | 25% | `i_wisp`, `i_wisp_l` |

Maximum range maps `1 → 1`, `2 → 3`, `3 → 4`, `4 → 5`, `5 → 6`, `6 → 8`, `7 → 9`. The native optimum range stays the aim-falloff threshold, so the extra reach can be low-accuracy fire. Point defense at range 2 gains a hex while wing guns and boarding tendrils stay adjacent. Range perks equipped at deployment are included before rounding. Temporary orders, gravity assist, move abilities, firing arcs and charge costs still use their existing formulas.

- **Torpedoes.** Standard and heavy salvos go from 6 to 8 hexes. Glasswright star torpedoes go from 5 to 6. Impact still comes at the start of the firing side's next turn. A target can slip out of tracking by moving 3 hexes from the aimed cell, so faster ships can also dodge more easily. Point defense gets its longer intercept radius. The CSV counts launches, hits, dodges and launch distances.
- **Ramming.** `ramInfo` limits a straight run-up to the lower of remaining movement and effective speed minus engine damage. A ship at speed 5 can budget one more hex before collision, and speed 6 can budget two. The collision still needs open space ahead and the existing hull, shield, recoil and run-up formulas still set damage. A movement-only boost like Overburn can fill the movement budget without raising its speed cap. The CSV counts completed ram actions.
- **Speed bonuses.** Grax, Razormaw, the Plasma drive, Born helmsman, the Founders' compass, Afterburners and the Aspect of the Ram modify effective speed before the trial rounds it. For a Wrecker, base 5 becomes 6. With one +1 speed source, 6 becomes 8, so the same bonus adds 2 movement to the scaled starting value. A Gutship goes from base 6 to scaled 8, or from 7 to 9 with a +1 source, a gain of 1 on the scaled value. The Surge Command's movement points are added during the fight. The faction matrix used unmodified hulls, so these stacks are a code reading.

In the run 1 full trial, mean torpedo launch range rose from 3.44 to 4.07 hexes. Clean dodges rose from 19.0% to 25.7% of launches, and salvos landing a hit fell from 38.5% to 33.5%. Rams rose from 24.9 to 28.3 per 1,000 ship activations.

## Method and limits

- **Source.** The sim reads the checkout's `data.js`, `core.js`, `battle.js` and the player bot from `sim3d.js`. `trial_rules.js` supplies the proposed rules to a private in-memory copy. The 19-hex station, reach, damage, objectives, veteran enemy AI and alternating round loop run from the browser oracle. Design inputs were issue 1004 at `e60244df`, the Muse map mechanics package at `b7acd353` (STATUS, Build 2 and consolidated results section 6), and DeepSeek's 1019 pace study. [DeepSeek's pace study](../../deepseek/map_pace_1117/README.md)
- **Pairs.** Seeds 1000 to 1099 recur in every cell. The map request, opponent, fleet, deployment-mode draw, shape quantile and `startBattle` seed are paired. There are separate deterministic map and shape draws per encounter. Within a fight, different terrain or decisions can consume different random numbers. The harness resets unit ids per battle so tie-breaks stay stable across worker schedules.
- **Fixtures.** The encounter table uses the earlier 16-CP Hegemony mirror in sector 2 with the same Vex bot policy. Boss rows use that player fleet against the live boss fleet generator at the last column in each sector, with factions drawn from that sector's pool and the fleet fixed across variants. The map request samples belt, graveyard, storm, planet and station, with Defend forced to station. The campaign's line/line/flank draw feeds ordinary encounters. The engine retains the placement overrides for objective encounters and its angled approaches for round and square fields. Teaching encounters, campaign events, Nemeses, compact two-ship starts and built-up campaign fleets are outside these fixtures.
- **Shape weights.** The baseline reads the live encounter lists and boss shape pool. The trial keeps at least two Hourglass entries per encounter, at least two Corridor entries for Rout, and adds two Archipelago entries for belt and graveyard. Hourglass and Corridor use the strip to retain their cuts. Other shapes use the live arena weights and the existing compatibility, connectivity and rollback logic. The CSV records both requested and realized map and shape.
- **Metrics.** First gun act is the number of completed ship activations before the first legal ship gun fires or launches a torpedo. `0` means the first activation. The raw file also records the first gun including wings and the first gun aimed at a flagged target. The Hunt tuning file adds the first shot from one capital hull at another. Nova, station batteries and reaction flak are outside the gun counter. Move-only means a ship travelled and had zero gunfire, ability use, orders, Commands, rams or boarding in that activation. Distance per move counts path hexes per move action, including charges and blink displacement. Each move in a multi-move activation counts separately. Distance to the goal uses the closest player ship and closest valid goal hex or marked enemy. It measures hex geometry, so obstacles can add travel. Battle length is `B.round`. A round-6 jump is recorded at the start of round 7. Capped runs stay in the denominator and count as zero wins.
- **Coverage.** 14 encounter cells per setup include the eight ordinary encounters and both boss encounters in each sector. The faction sweep is a paired screen covering all ordered pairings plus mirrors. The two bot policies differ, and the player can use a Command. Treat win shifts as playtest signals for these fleets and policies. The boss fixture is particularly strong for sector 1.

## Reproduce

Run from the checkout root with Node 22 and Python 3 with Pillow. This uses the saved run 1 data from the Board's base commit. The renderer makes the Hunt sheet on the CPU and verifies its stamp.

```powershell
$job = 'contrib/codex/map_eval_1118'
$out = Join-Path $env:TEMP ('map-eval-1050-' + [guid]::NewGuid().ToString('N'))
[System.IO.Directory]::CreateDirectory($out) | Out-Null
python -B -c "from pathlib import Path; import subprocess, sys; Path(sys.argv[1]).write_bytes(subprocess.check_output(['git', 'show', sys.argv[2]]))" "$out/base.csv" "657ab403:$job/results.csv"
node "$job/sim.js" encounters --setup recommended --enc ambush,boss1_rout,boss1_ambush,boss2_rout,boss2_ambush,boss3_rout,boss3_ambush --out "$out/encounters.csv"
node "$job/sim.js" hunt-sweep --out "$out/hunt_tuning.csv"
node "$job/sim.js" factions --setup tempo --out "$out/tempo.csv"
node "$job/sim.js" factions --setup recommended --enc ambush --out "$out/ambush.csv"
node "$job/sim.js" factions --setup recommended --enc hunt --out "$out/hunt.csv"
python -B "$job/report.py" --base "$out/base.csv" --encounters "$out/encounters.csv" --factions "$out/tempo.csv" --factions "$out/ambush.csv" --factions "$out/hunt.csv" --hunt "$out/hunt_tuning.csv" --out "$out/results.csv" --pictures "$out/picks.json"
node "$job/sim.js" pictures --setup hunt_all --enc hunt --input "$out/picks.json" --out "$out/deployment.json"
python -B "$job/draw_deployment.py" "$out/deployment.json" "$out/shots"
```

To repeat the extra Hunt sample, add `--seed 1100` to `hunt-sweep` with a fresh output filename. The first setting in `hunt_settings.json` is the pick.

## Verification

- The standing checks reported 66 passes, two known baseline rows and a Windows hard-link permission failure. The isolated `gpu_slots_tests` rerun with hard-link permission passed all 12 groups using the suite's Node stub.
- The browser `build.py test` passed in UTF-8 mode from a temporary source copy.
- The final sim replay matched the saved Hunt sample across worker counts and reproduced 72 run 1 rows from Engagement, Defend and Hunt.
- The report checked seeds, both faction seatings, CP and paired map inputs. The 30-round cap applied to 35 of 7,900 encounter rows and 1 of 14,400 faction rows. The Hunt tuning and the two new faction arms had zero caps. The runner's picture checker verified all 14 diagrams and provenance sidecars. This sim-only job used the browser rules and CPU diagrams.
