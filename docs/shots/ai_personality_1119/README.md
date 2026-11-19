# Enemy AI: faction personality at Standard, and a harder Veteran (issue 1160)

**Result.** Veteran's player win rate now sits 9.5 points under Standard's (55.5% against 65.0%), inside the 8 to 12 point target. Before
this change the gap was 2.0 points (58.4% against 60.4%). Standard enemies now fight in their faction's style; that made them a little
easier for the bot (+4.6 points, inside the 5 point limit). Medians held at 6 rounds on both levels.

**Flag.** Standard battles past round 12 rose from 57 to 68 of 3,600 (1.6% to 1.9%). That is about one standard deviation of noise
(counts of this size wander by about 11), but the gate asks for no rise, so it is called out here. Veteran fell from 65 to 60.

## What changed (browser `battle.js` and Godot `godot/rules/rules.gd` together, in the shared scorers every faction uses)

1. Personality at both levels (was Veteran only), read from the faction tables (`FACTION_AI`, `NEM_PERSONA`): range bands, ram setup,
   the hurt curve (`aiHurtW`) and the relay and convoy role splits in `aiObjScore`. Veteran keeps the fleet focus, the death cliff, the
   full threat model, the smart activation order, objective urgency, escort spacing and the break-lane block.
2. Ion storm cost in both threat models (`evalThreat`, `evalThreatVet` / `_ai_threat_cell`): a shielded hull that would end its move in
   a storm counts the 10 shield it will lose at its next turn start. Because the threat models are shared, this reaches every enemy at
   both levels, wing launch hexes, the Glasswright fade, brace checks and the player bot in the sims.
3. The Cunning Nemesis `rear` flag is read (`nemProf` passes it on): its ships score hexes behind or beside your ships that a ready gun
   reaches (`aiRearScore`), and its volleys favour targets it hits from behind or the side (`nemTargetBonus`). Any persona given `rear`
   in `NEM_PERSONA` gets the same behaviour.
4. Two fixes found by the harness, both levels:
   - Ram setup only counts the movement left after the move (the ram `tacticRam` makes after the volley). A ram lined up for next round
     meets a target that has moved; scoring it pulled ships nose first into point blank range for nothing. With the old scoring,
     turning ram setup on at Standard cost the AI about 4 points (Hullbreakers 65% to 77% player wins).
   - Convoy escort split, like the relay's: only the two escorts nearest the convoy screen it, the rest fight. With every escort
     hanging back, Standard intercept fights past round 12 rose from 28 to about 40 (per 720) in the first run.
5. Veteran tuning (one number, no extra hull, shields, damage or budget): in Veteran's threat model a gun that can move into range and
   fire before the ship acts again now counts 0.8 of a gun already bearing (was 0.2, `AI_REACH_W`). Veteran ships stop stepping just
   inside reach of guns that strike first. Tried and dropped, each within 1.5 points of no change on 1,800 battles: stronger focus fire
   (1.6x and +25), the ram setup safety check, no death cliff, the flat Standard caution, the simple threat model, no smart activation
   order, half and 1.7x caution. A 10% and 20% bigger Veteran budget moved it 1.8 and 3.6 points, so even fleet size moves this
   harness slowly.

Systems that pick these up: every enemy ship in skirmish, campaign battles (all objectives), elites, boss fleets and the Nemesis
(same `aiUnit`, `aiObjScore` and threat models), in the browser game and in Godot. The storm cost also reaches the player-side
helpers that read `evalThreat` (the sim bot, the fade move).

## Method

`node tools/ai_pair_1160.js run <out.json> 200 4` (test: `node tools/test_ai_pair_1160.js`), then
`node tools/ai_pair_1160.js table <before.json> <after.json>`. Battles run in `sim3d.js` mode `aipair`: issue 1062's headless player
bot and alternating activations, widened to all six enemy factions, sectors 1 to 3 and both levels, 200 battles per row, 7,200 per run.
Battle i of a row always has the same seed (1160000 + sector x 10000 + faction x 1000 + i) and objective (rout, rout, flagship, hold,
intercept), so before and after are true pairs; the test checks that sharding never changes a battle. The player flies the campaign
mode's Sunward reference fleet for the sector; the enemy is drawn by the game's own generator, including its hull thinning and
Standard's 10% smaller budget. At the game's own budget the bot wins 96 to 98% at both levels (first baseline run), so no gap can
show; the harness scales the enemy budget by 2.1, 1.95 and 2.5 for sectors 1 to 3 (`AIPAIR_K`) so fights are contested.
Before: origin/main cd6d4f59. Noise: one row of 200 is about plus or minus 3.5 points (one standard deviation); a level total over
3,600 is about plus or minus 0.8. Paired, 773 Standard and 858 Veteran battles changed winner.

Per objective, player wins before and after: Standard rout 61.2 to 64.5, flagship 67.2 to 70.4, relay 46.5 to 54.3, convoy 65.8 to
71.1; Veteran rout 57.4 to 53.5, flagship 65.4 to 61.5, relay 50.3 to 47.6, convoy 61.3 to 61.3.

Rows under 40% after: Veteran against Sunward in every sector (27.5%, 39.5%, 37.5%; before 32%, 43%, 40%). Veteran against
Hegemony in sector 1 sits at exactly 40%. Sunward and Hegemony were the hardest enemies before too. The level totals stay well above 40%.

## Checks (cloud, Godot 4.7.2 headless, Node 22)

- Rules parity: all 284 seeded battles match browser and Godot, every action. Saved Godot results refreshed: 183 battles and the s4 and
  s23 threat maps changed, listed in `godot/rules/test/saved/changes.txt`; the check against the saved run passes.
- Campaign parity (30 seeded runs), the Nemesis scenarios, the tree hand-off and the Godot-only safety net pass.
- Standing checks: the same 4 fail on origin/main in this cloud box (report_paths, runner_cleanup, runner_job, smoke_safety: PC runner
  tests); nothing new fails.
- Tests updated: AI-1 (r1_tests and findings_tests) and AI-3 (findings_tests) pin the old 0.2 reach weight while they probe the brace
  path and the death cliff alone; with 0.8 the Veteran no longer steps into the trap they build, which is the point of the change.
- Ten tree-skill fixtures got new seeds (the nearest seed where the skill still fires; issue 1062 did the same): t_oathwings,
  t_ecl_copiedbehind, t_ecl_iterationkill, t_hb_everyknife, t_hb_retasked, t_heg_formation, t_heg_columnendures, t_heg_standinggroup,
  t7b_ecl_triage, t529_nostop. The tree effect and last-rows checks pass.

## Table: faction by sector by level, before and after

| Level | Sector | Enemy | Battles | Player wins before | after | change | Median rounds before / after | Past round 12 before / after |
|---|---|---|---:|---:|---:|---:|---:|---:|
| **Standard** | all | all | 3600 | 60.4% | **65.0%** | +4.6 | 6 / 6 | 57 / 68 |
| Standard | all | Sunward Crusade | 600 | 43.7% | 45.7% | +2.0 | 7 / 7 | 15 / 17 |
| Standard | all | Hegemony Navy | 600 | 48.3% | 53.2% | +4.9 | 7 / 7 | 4 / 10 |
| Standard | all | Ashfall Hullbreakers | 600 | 62.3% | 73.0% | +10.7 | 6 / 6 | 5 / 3 |
| Standard | all | the Chorus | 600 | 65.2% | 72.7% | +7.5 | 6 / 6 | 10 / 17 |
| Standard | all | the Glasswrights | 600 | 77.3% | 79.8% | +2.5 | 6 / 6 | 9 / 12 |
| Standard | all | Eclipse | 600 | 65.5% | 65.5% | +0.0 | 6 / 7 | 14 / 9 |
| Standard | 1 | all | 1200 | 60.0% | 64.0% | +4.0 | 6 / 6 | 13 / 13 |
| Standard | 1 | Sunward Crusade | 200 | 50.5% | 46.5% | -4.0 | 7 / 6.5 | 5 / 6 |
| Standard | 1 | Hegemony Navy | 200 | 51.5% | 55.0% | +3.5 | 6 / 6.5 | 0 / 3 |
| Standard | 1 | Ashfall Hullbreakers | 200 | 62.0% | 70.0% | +8.0 | 6 / 6 | 1 / 0 |
| Standard | 1 | the Chorus | 200 | 65.0% | 77.5% | +12.5 | 5 / 5 | 1 / 0 |
| Standard | 1 | the Glasswrights | 200 | 69.5% | 75.5% | +6.0 | 6 / 6 | 5 / 2 |
| Standard | 1 | Eclipse | 200 | 61.5% | 59.5% | -2.0 | 7 / 6 | 1 / 2 |
| Standard | 2 | all | 1200 | 63.2% | 67.1% | +3.9 | 6 / 6 | 18 / 19 |
| Standard | 2 | Sunward Crusade | 200 | 41.5% | 47.0% | +5.5 | 7 / 7 | 4 / 6 |
| Standard | 2 | Hegemony Navy | 200 | 53.5% | 53.5% | +0.0 | 7 / 7 | 2 / 0 |
| Standard | 2 | Ashfall Hullbreakers | 200 | 66.5% | 76.5% | +10.0 | 6 / 6 | 0 / 1 |
| Standard | 2 | the Chorus | 200 | 66.0% | 69.0% | +3.0 | 6 / 6 | 2 / 5 |
| Standard | 2 | the Glasswrights | 200 | 82.5% | 83.0% | +0.5 | 6 / 6 | 3 / 3 |
| Standard | 2 | Eclipse | 200 | 69.0% | 73.5% | +4.5 | 6 / 7 | 7 / 4 |
| Standard | 3 | all | 1200 | 58.0% | 63.8% | +5.8 | 7 / 7 | 26 / 36 |
| Standard | 3 | Sunward Crusade | 200 | 39.0% | 43.5% | +4.5 | 8 / 8 | 6 / 5 |
| Standard | 3 | Hegemony Navy | 200 | 40.0% | 51.0% | +11.0 | 7.5 / 7 | 2 / 7 |
| Standard | 3 | Ashfall Hullbreakers | 200 | 58.5% | 72.5% | +14.0 | 6 / 6 | 4 / 2 |
| Standard | 3 | the Chorus | 200 | 64.5% | 71.5% | +7.0 | 7 / 7 | 7 / 12 |
| Standard | 3 | the Glasswrights | 200 | 80.0% | 81.0% | +1.0 | 6 / 6 | 1 / 7 |
| Standard | 3 | Eclipse | 200 | 66.0% | 63.5% | -2.5 | 6 / 7 | 6 / 3 |
| **Veteran** | all | all | 3600 | 58.4% | **55.5%** | -2.9 | 6 / 6 | 65 / 60 |
| Veteran | all | Sunward Crusade | 600 | 38.3% | 34.8% | -3.5 | 7 / 7 | 21 / 22 |
| Veteran | all | Hegemony Navy | 600 | 43.2% | 40.8% | -2.4 | 7 / 7 | 10 / 12 |
| Veteran | all | Ashfall Hullbreakers | 600 | 69.7% | 64.3% | -5.4 | 6 / 6 | 8 / 0 |
| Veteran | all | the Chorus | 600 | 63.3% | 59.3% | -4.0 | 6 / 6 | 5 / 9 |
| Veteran | all | the Glasswrights | 600 | 73.3% | 71.8% | -1.5 | 6 / 6 | 15 / 11 |
| Veteran | all | Eclipse | 600 | 62.3% | 61.7% | -0.6 | 7 / 7 | 6 / 6 |
| Veteran | 1 | all | 1200 | 47.5% | 44.8% | -2.7 | 6 / 6 | 24 / 21 |
| Veteran | 1 | Sunward Crusade | 200 | 32.0% | 27.5% | -4.5 | 7 / 7 | 9 / 4 |
| Veteran | 1 | Hegemony Navy | 200 | 39.5% | 40.0% | +0.5 | 7 / 7 | 3 / 6 |
| Veteran | 1 | Ashfall Hullbreakers | 200 | 57.5% | 54.5% | -3.0 | 6 / 6 | 2 / 0 |
| Veteran | 1 | the Chorus | 200 | 53.5% | 46.5% | -7.0 | 6 / 6 | 1 / 1 |
| Veteran | 1 | the Glasswrights | 200 | 59.5% | 58.5% | -1.0 | 6 / 6 | 6 / 7 |
| Veteran | 1 | Eclipse | 200 | 43.0% | 41.5% | -1.5 | 7 / 7 | 3 / 3 |
| Veteran | 2 | all | 1200 | 62.7% | 60.9% | -1.8 | 6 / 6 | 12 / 15 |
| Veteran | 2 | Sunward Crusade | 200 | 43.0% | 39.5% | -3.5 | 7 / 7 | 2 / 6 |
| Veteran | 2 | Hegemony Navy | 200 | 45.0% | 41.0% | -4.0 | 7 / 7 | 0 / 3 |
| Veteran | 2 | Ashfall Hullbreakers | 200 | 73.5% | 69.0% | -4.5 | 6 / 6 | 3 / 0 |
| Veteran | 2 | the Chorus | 200 | 64.0% | 65.5% | +1.5 | 6 / 6 | 0 / 1 |
| Veteran | 2 | the Glasswrights | 200 | 79.0% | 78.0% | -1.0 | 6 / 6 | 5 / 3 |
| Veteran | 2 | Eclipse | 200 | 72.0% | 72.5% | +0.5 | 6 / 6 | 2 / 2 |
| Veteran | 3 | all | 1200 | 64.8% | 60.8% | -4.0 | 7 / 7 | 29 / 24 |
| Veteran | 3 | Sunward Crusade | 200 | 40.0% | 37.5% | -2.5 | 8 / 8 | 10 / 12 |
| Veteran | 3 | Hegemony Navy | 200 | 45.0% | 41.5% | -3.5 | 8 / 8 | 7 / 3 |
| Veteran | 3 | Ashfall Hullbreakers | 200 | 78.0% | 69.5% | -8.5 | 6 / 7 | 3 / 0 |
| Veteran | 3 | the Chorus | 200 | 72.5% | 66.0% | -6.5 | 7 / 7 | 4 / 7 |
| Veteran | 3 | the Glasswrights | 200 | 81.5% | 79.0% | -2.5 | 6 / 6 | 4 / 1 |
| Veteran | 3 | Eclipse | 200 | 72.0% | 71.0% | -1.0 | 7 / 7 | 1 / 1 |

