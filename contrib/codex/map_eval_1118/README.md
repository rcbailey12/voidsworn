# Map evaluation on 30 × 22

**Pick Shapes + x1.25 speed and range for the next side-by-side playtest on 30 × 22, with today's deployments.** Ships travelled farther on each move in all 14 encounter fixtures. In the standard engagement, they went from 2.90 to 3.52 hexes per move, spent 4.0% of activations only moving, down from 11.1%, and fired one activation sooner. The proposed Hunt starts bought the intended approach time with the full package. They also let the quarry escape in every Hegemony trial, up from 9%, which rules out that package for this playtest.

Breakthrough deserves particular attention in the playtest. The speed and range preset raised its Hegemony win rate from 37% to 65%. Decapitation rose from 36% to 52%. The faction sweep below compares the full package with today, so the exact faction effect of the playtest pick is still open.

| Encounter | First gun act | Hexes per move | Move only | Player win |
|---|---:|---:|---:|---:|
| Engagement | 1 → 0 | 2.90 → 3.52 | 11.1% → 4.0% | 41% → 37% |
| Ambush | 0 → 0 | 2.83 → 3.46 | 2.6% → 1.3% | 55% → 61% |
| Hold the station | 6 → 0 | 3.04 → 3.68 | 21.2% → 6.0% | 38% → 30% |
| Hunt | 0 → 0 | 3.41 → 3.99 | 7.5% → 1.6% | 91% → 80% quarry kills |
| Intercept | 2 → 0 | 2.98 → 3.76 | 30.8% → 21.7% | 73% → 87% |
| Breakthrough | 0 → 0 | 3.23 → 3.91 | 5.7% → 6.8% | 37% → 65% |
| Relay | 0 → 0 | 2.97 → 3.35 | 11.4% → 2.4% | 50% → 59% |
| Decapitation | 2 → 0 | 2.90 → 3.47 | 10.7% → 4.4% | 36% → 52% |

The short table compares today with the playtest pick using 100 paired seeds per row. [All 14,200 battle rows](results.csv)

## Deployment pictures

Each sheet shows the same seed on the left and right. The left is today's rules. The right is the full test package, so Ryan can see the placement and shape changes together. The cards show the nearest player ship's distance to the goal. The arrows show facing. Gold marks objectives, the quarry or flagship, and the two Hunt screen ships. These diagrams come from the deployment code before the first activation.

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

The table measures the closest ship to the encounter goal and to the enemy line. Values are median and observed range in hexes. Opening gun is the share of seeds with a legal shot from the deployment hex. The trial columns use new shapes and fixed placement at today's speed and range.

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

## The five setups

Each encounter has 100 paired seeds per setup. Shapes is the comparison arm for the two isolated levers. `Shapes + placement` adds only the tested starts and Hunt movement scoring. `Shapes + x1.25` adds only the stat changes. `All three` combines them. Gun act and gun round are medians. Rounds is the mean. Win is the game's result and Escape applies to Hunt. Cap gives the runs still active at round 30.

The new weights increased realized Hourglass from 16 to 179 of 800 ordinary battles. Corridor appeared in 15 of 100 engagements, up from zero. Archipelago went from 36 of 244 to 67 of 250 realized belt and graveyard maps. Strip arenas rose from 553 to 627 of 800 ordinary battles, which is part of the shape effect. Shapes alone held median first fire within one activation in every ordinary encounter, with a 22-point decrease in the Hegemony mirror Engagement win rate. Adding tempo increased move distance in every encounter. The tested placements mainly changed what was reachable or screened at the start, and their effect varied by encounter.

<details>
<summary>All five setups for every encounter</summary>

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

Six factions across both seats give 30 ordered non-mirror cells and six mirrors. Each cell has 100 paired seeds per setup, with 12 or 13 seeds per ordinary encounter. Both fleets start at 16 CP. Intercept adds three mission transports to the enemy side. The player has the same fallback Vex Command across factions and neither fleet uses fitted speed items. The table reports shifts strictly greater than 10 percentage points. Paired wins up/down counts seeds that flipped outcome in either direction. Ranges are approximate paired 95% intervals with no adjustment across the 36 comparisons. Faction ids match the CSV.

| Player | Enemy | Today | All three | Change | Paired wins up/down | Approx. 95% range |
|---|---|---:|---:|---:|---:|---:|
| voidsworn | deathless | 72% | 83% | +11 pp | 16 / 5 | +2 to +20 pp |
| corsair | voidsworn | 86% | 68% | -18 pp | 8 / 26 | -29 to -7 pp |
| chorus | hegemony | 50% | 73% | +23 pp | 29 / 6 | +12 to +34 pp |
| chorus | voidsworn | 57% | 39% | -18 pp | 12 / 30 | -30 to -6 pp |
| deathless | hegemony | 82% | 96% | +14 pp | 15 / 1 | +7 to +21 pp |
| deathless | corsair | 68% | 79% | +11 pp | 21 / 10 | +0 to +22 pp |

Six of 36 seatings crossed the threshold.

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

In the faction sweep, mean torpedo launch range rose from 3.44 to 4.07 hexes. Clean dodges rose from 19.0% to 25.7% of launches, and salvos landing a hit fell from 38.5% to 33.5%. Rams rose from 24.9 to 28.3 per 1,000 ship activations. These are effects of the combined package in the mixed encounter sweep.

## Method and limits

- **Source.** The sim reads the checkout's `data.js`, `core.js`, `battle.js` and the player bot from `sim3d.js`. `trial_rules.js` supplies the proposed rules to a private in-memory copy. The 19-hex station, reach, damage, objectives, veteran enemy AI and alternating round loop run from the browser oracle. Design inputs were issue 1004 at `e60244df`, the Muse map mechanics package at `b7acd353` (STATUS, Build 2 and consolidated results section 6), and DeepSeek's 1019 pace study. [DeepSeek's pace study](../../deepseek/map_pace_1117/README.md)
- **Pairs.** Seeds 1000 to 1099 recur in every cell. The map request, opponent, fleet, deployment-mode draw, shape quantile and `startBattle` seed are paired. There are separate deterministic map and shape draws per encounter. Within a fight, different terrain or decisions can consume different random numbers. The harness resets unit ids per battle so tie-breaks stay stable across worker schedules.
- **Fixtures.** The encounter table uses the earlier 16-CP Hegemony mirror in sector 2 with the same Vex bot policy. Boss rows use that player fleet against the live boss fleet generator at the last column in each sector, with factions drawn from that sector's pool and the fleet fixed across variants. The map request samples belt, graveyard, storm, planet and station, with Defend forced to station. The campaign's line/line/flank draw feeds ordinary encounters. The engine retains the placement overrides for objective encounters and its angled approaches for round and square fields. Teaching encounters, campaign events, Nemeses, compact two-ship starts and built-up campaign fleets are outside these fixtures.
- **Shape weights.** The baseline reads the live encounter lists and boss shape pool. The trial keeps at least two Hourglass entries per encounter, at least two Corridor entries for Rout, and adds two Archipelago entries for belt and graveyard. Hourglass and Corridor use the strip to retain their cuts. Other shapes use the live arena weights and the existing compatibility, connectivity and rollback logic. The CSV records both requested and realized map and shape.
- **Metrics.** First gun act is the number of completed ship activations before the first legal ship gun fires or launches a torpedo. `0` means the first activation. The raw file also records the first gun including wings and the first gun aimed at a flagged target. Nova, station batteries and reaction flak are outside the gun counter. Move-only means a ship travelled and had zero gunfire, ability use, orders, Commands, rams or boarding in that activation. Distance per move counts path hexes per move action, including charges and blink displacement. Each move in a multi-move activation counts separately. Distance to the goal uses the closest player ship and closest valid goal hex or marked enemy. It measures hex geometry, so obstacles can add travel. Battle length is `B.round`. A round-6 jump is recorded at the start of round 7. Capped runs stay in the denominator and count as zero wins.
- **Coverage.** 14 encounter cells per setup include the eight ordinary encounters and both boss encounters in each sector. The faction sweep is a paired screen covering all ordered pairings plus mirrors. The two bot policies differ, and the player can use a Command. Treat win shifts as playtest signals for these fleets and policies. The boss fixture is particularly strong for sector 1.

## Reproduce

Run from the checkout root with Node 22 and Python with Pillow. Use fresh output paths. The renderer makes review diagrams on the CPU and verifies every provenance stamp.

```powershell
$job = 'contrib/codex/map_eval_1118'
$out = Join-Path $env:TEMP 'map-eval-1050'
[System.IO.Directory]::CreateDirectory($out) | Out-Null
node "$job/sim.js" encounters --sims 100 --out "$out/encounters.csv"
node "$job/sim.js" factions --sims 100 --out "$out/factions.csv"
python -B "$job/report.py" --encounters "$out/encounters.csv" --factions "$out/factions.csv" --out "$out/results.csv" --pictures "$out/picks.json"
node "$job/sim.js" pictures --input "$out/picks.json" --out "$out/deployment.json"
python -B "$job/draw_deployment.py" "$out/deployment.json" "$out/shots"
```

## Verification

- `node contrib/opus/tools/run_all_checks.js` finished with the two existing baseline rows and one Windows hard-link permission failure. The isolated `gpu_slots_tests` rerun with that permission passed all 12 groups. It used the suite's Node stub.
- The browser `build.py test` passed with UTF-8 mode from a temporary source copy. Node syntax checks passed. Replaying the same Hunt and Relay cases with one and three workers produced byte-identical CSVs.
- The data script checked every seed, both faction seatings, CP, and corresponding map inputs. The 30-round cap accounted for 32 of 7,000 encounter runs and 1 of 7,200 faction runs. The 14 diagrams and their provenance stamps were verified. Godot runs and captures were outside this sim-only job.
