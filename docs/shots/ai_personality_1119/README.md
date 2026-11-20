# Enemy AI: faction personality at Standard, and a harder Veteran (issue 1160)

**Result.** Veteran's player win rate is now 8.4 points under Standard's (53.6% against 62.0%; before 58.4% against 60.5%).
Veteran got harder by itself (-4.8), and Standard moved +1.5, with every faction inside 5 points of its old Standard rate
(largest: the Hullbreakers +4.2). Medians held at 6 rounds on both levels. Veteran fights at the same range as before (3.5 hexes
to the nearest player ship, 83% of its activations fire), so the new reach weight does not make it hover.

**Long fights on Standard: accepted by Board decision (Nov 19, 23:01 UTC), range bands kept.** Battles past round 12 on Standard rose from 56 to 63 of 3,600 (1.6% to 1.75%). Veteran fell
from 65 to 53. The rise is in the kiting and gun-line factions now that their range bands run at Standard: Hegemony 3 to 11,
Sunward 15 to 19, Glasswrights 9 to 12; the Hullbreakers and Eclipse fell (5 to 1, 14 to 9). Counts this small wander by
about 11 run to run. The Board ruled it small and in character (range-band factions dragging fights out a little) and said not
to weaken the range bands.

## Per faction (all sectors, 600 battles each per level)

| Enemy | Standard before | Standard after | change | Veteran before | Veteran after | change | Gap after (Standard minus Veteran) | Gap from decisions alone (same fleets) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| All | 60.5% | 62% | +1.5 | 58.4% | 53.6% | -4.8 | 8.4 | 2.7 |
| Sunward Crusade | 43.7% | 43.8% | +0.1 | 38.3% | 32.5% | -5.8 | 11.3 | 4.0 |
| Hegemony Navy | 48.8% | 50.5% | +1.7 | 43.2% | 40.7% | -2.5 | 9.8 | 1.3 |
| Ashfall Hullbreakers | 62.3% | 66.5% | +4.2 | 69.7% | 59.2% | -10.5 | 7.3 | 4.5 |
| the Chorus | 65.2% | 65.5% | +0.3 | 63.3% | 58.5% | -4.8 | 7.0 | 0.3 |
| the Glasswrights | 77.3% | 80.2% | +2.9 | 73.3% | 70.7% | -2.6 | 9.5 | 3.0 |
| Eclipse | 65.5% | 65.7% | +0.2 | 62.3% | 60% | -2.3 | 5.7 | 3.0 |

"Gap from decisions alone" reruns both levels with the same fleets (no Standard cut, no Veteran edge). Before this change that
gap was -2.8 (Veteran's decisions were weaker than Standard's: 58.4% against 55.6%). The rest of the 8.4 point gap is fleet
size: Standard's 10% smaller fleet is about 5 points, Veteran's new 10% larger fleet about 1.

## What changed (browser `battle.js` and Godot `godot/rules/rules.gd` together, in the shared scorers every faction uses)

1. Personality at both levels (was Veteran only), read from the faction tables (`FACTION_AI`, `NEM_PERSONA`): range bands, ram
   setup, the hurt curve (`aiHurtW`) and the relay and convoy role splits in `aiObjScore`. Veteran keeps the fleet focus, the death
   cliff, the full threat model, the smart activation order, objective urgency, escort spacing and the break-lane block.
2. Ion storm cost in both threat models (`evalThreat`, `evalThreatVet` / `_ai_threat_cell`): a shielded hull that would end its move
   in a storm counts the shield it will lose at its next turn start (up to 10, only what it still has), priced like shield damage
   (0.2 a point). Because the threat models are shared, this reaches every enemy at both levels, wing launch hexes, the Glasswright
   fade, brace checks and the player bot in the sims.
3. The Cunning Nemesis `rear` flag is read (`nemProf` passes it on): its ships score hexes behind or beside your ships that a ready
   gun reaches (`aiRearScore`), and its volleys favour targets hit from behind or the side (`nemTargetBonus`). Any persona given
   `rear` in `NEM_PERSONA` gets the same behaviour.
4. Fixes the harness found, both levels:
   - Ram setup only counts the movement left after the move (the ram `tacticRam` makes after the volley); a ram lined up for next
     round meets a target that has moved. Its weight is now a faction table entry (`FACTION_AI.rs`, the ramming factions), cut
     from .35 to .15: at .35 the Hullbreakers and the Chorus were 7 to 11 points easier once it ran at Standard, and weaker at
     Veteran too.
   - Convoy escort split, like the relay's: only the two escorts nearest the convoy screen it, the rest fight.
   - Hegemony's gun-line weight (`FACTION_AI.hegemony.rw`) 1.2 to .6: at 1.2 Standard Hegemony was 5.2 points easier.
5. Veteran (decisions): in Veteran's threat model a gun that can move into range and fire before the ship acts again counts 0.8
   of a gun already bearing (was 0.2, `AI_REACH_W`). Tried and dropped, each within 1.5 points: stronger focus fire, a ram safety
   check, no death cliff, the flat Standard caution, the simple threat model, no smart activation order, half and 1.7x caution.
6. Veteran fleet budget edge (Ryan via the Board, Nov 19: fleet size is the main difficulty lever): `RAMP.vet` = 1.1, one shared
   table entry both twins read (`genEnemyFleet`), beside Standard's `RAMP.std` = .9. Issue 1178 tunes it with the Sector 3 work.

Systems that pick these up: every enemy ship in skirmish, campaign battles (all objectives), elites, boss fleets and the Nemesis
(same `aiUnit`, `aiObjScore`, threat models and fleet generator), in the browser game and in Godot.

## Method

`node tools/ai_pair_1160.js run <out.json> 200 4` (test: `node tools/test_ai_pair_1160.js`), then
`node tools/ai_pair_1160.js table <before.json> <after.json>`. `EQUAL=1` gives both levels the same fleets; `AIFAC` and `RAMP` try
table values without editing the rules. Battles run in `sim3d.js` mode `aipair`: issue 1062's headless player bot and alternating
activations, widened to all six enemy factions, sectors 1 to 3 and both levels, 200 battles per row, 7,200 per run. Battle i of a
row always has the same seed (1160000 + sector x 10000 + faction x 1000 + i) and objective (rout, rout, flagship, hold,
intercept), so before and after are true pairs; the test checks that sharding never changes a battle. The player flies the
campaign mode's Sunward reference fleet for the sector; the enemy comes from the game's own generator. At the game's own budget
the bot wins 96 to 98% at both levels, so no gap can show; the harness scales the enemy budget by 2.1, 1.95 and 2.5 for sectors
1 to 3 (`AIPAIR_K`) so fights are contested. Before: origin/main 977b7af5 (truth pass 2 included); after: this branch with
main merged. Noise: one row of 200 is about plus or minus 3.5 points; a faction total of 600 about 2; a level total of 3,600
about 0.8.

Rows under 40% after: Veteran against Sunward in every sector and Hegemony in sector 1 (see the table). Sunward and Hegemony were
the hardest enemies before too (Veteran Sunward 32 to 40% before). Level totals stay well above 40%.

## Checks

See the PR body for the run on the final head (parity, saved results, campaign parity, safety net, standing checks).
AI-1 (both test files) now starts the enemy line 6 hexes off (was 8), and AI-3 starts the probe ship 2 hexes out with speed 2
(guard speed 1): at the old spacing a Veteran that prices guns that can move into range at 0.8 rightly waits outside them, so the
scenarios no longer reached the brace and death-cliff decisions they test. No weight is pinned.

## Table: faction by sector by level, before and after (real fleets)

| Level | Sector | Enemy | Battles | Player wins before | after | change | Median rounds before / after | Past round 12 before / after |
|---|---|---|---:|---:|---:|---:|---:|---:|
| **Standard** | all | all | 3600 | 60.5% | **62.0%** | +1.5 | 6 / 6 | 56 / 63 |
| Standard | all | Sunward Crusade | 600 | 43.7% | 43.8% | +0.1 | 7 / 7 | 15 / 19 |
| Standard | all | Hegemony Navy | 600 | 48.8% | 50.5% | +1.7 | 7 / 7 | 3 / 11 |
| Standard | all | Ashfall Hullbreakers | 600 | 62.3% | 66.5% | +4.2 | 6 / 6 | 5 / 1 |
| Standard | all | the Chorus | 600 | 65.2% | 65.5% | +0.3 | 6 / 6 | 10 / 11 |
| Standard | all | the Glasswrights | 600 | 77.3% | 80.2% | +2.9 | 6 / 6 | 9 / 12 |
| Standard | all | Eclipse | 600 | 65.5% | 65.7% | +0.2 | 6 / 6.5 | 14 / 9 |
| Standard | 1 | all | 1200 | 59.9% | 61.1% | +1.2 | 6 / 6 | 13 / 15 |
| Standard | 1 | Sunward Crusade | 200 | 50.5% | 46.5% | -4.0 | 7 / 6 | 5 / 6 |
| Standard | 1 | Hegemony Navy | 200 | 51.0% | 54.5% | +3.5 | 6 / 6.5 | 0 / 3 |
| Standard | 1 | Ashfall Hullbreakers | 200 | 62.0% | 63.0% | +1.0 | 6 / 6 | 1 / 1 |
| Standard | 1 | the Chorus | 200 | 65.0% | 68.5% | +3.5 | 5 / 5 | 1 / 1 |
| Standard | 1 | the Glasswrights | 200 | 69.5% | 74.0% | +4.5 | 6 / 6 | 5 / 2 |
| Standard | 1 | Eclipse | 200 | 61.5% | 60.0% | -1.5 | 7 / 6 | 1 / 2 |
| Standard | 2 | all | 1200 | 63.3% | 64.5% | +1.2 | 6 / 6 | 17 / 16 |
| Standard | 2 | Sunward Crusade | 200 | 41.5% | 46.0% | +4.5 | 7 / 7 | 4 / 3 |
| Standard | 2 | Hegemony Navy | 200 | 54.5% | 51.5% | -3.0 | 7 / 7 | 1 / 2 |
| Standard | 2 | Ashfall Hullbreakers | 200 | 66.5% | 67.5% | +1.0 | 6 / 6 | 0 / 0 |
| Standard | 2 | the Chorus | 200 | 66.0% | 64.0% | -2.0 | 6 / 6 | 2 / 4 |
| Standard | 2 | the Glasswrights | 200 | 82.5% | 84.5% | +2.0 | 6 / 6 | 3 / 3 |
| Standard | 2 | Eclipse | 200 | 69.0% | 73.5% | +4.5 | 6 / 7 | 7 / 4 |
| Standard | 3 | all | 1200 | 58.2% | 60.5% | +2.3 | 7 / 7 | 26 / 32 |
| Standard | 3 | Sunward Crusade | 200 | 39.0% | 39.0% | +0.0 | 8 / 8 | 6 / 10 |
| Standard | 3 | Hegemony Navy | 200 | 41.0% | 45.5% | +4.5 | 7.5 / 7 | 2 / 6 |
| Standard | 3 | Ashfall Hullbreakers | 200 | 58.5% | 69.0% | +10.5 | 6 / 6 | 4 / 0 |
| Standard | 3 | the Chorus | 200 | 64.5% | 64.0% | -0.5 | 7 / 7 | 7 / 6 |
| Standard | 3 | the Glasswrights | 200 | 80.0% | 82.0% | +2.0 | 6 / 6 | 1 / 7 |
| Standard | 3 | Eclipse | 200 | 66.0% | 63.5% | -2.5 | 6 / 7 | 6 / 3 |
| **Veteran** | all | all | 3600 | 58.4% | **53.6%** | -4.8 | 6 / 6 | 65 / 53 |
| Veteran | all | Sunward Crusade | 600 | 38.3% | 32.5% | -5.8 | 7 / 7 | 21 / 12 |
| Veteran | all | Hegemony Navy | 600 | 43.2% | 40.7% | -2.5 | 7 / 7 | 10 / 6 |
| Veteran | all | Ashfall Hullbreakers | 600 | 69.7% | 59.2% | -10.5 | 6 / 6 | 8 / 6 |
| Veteran | all | the Chorus | 600 | 63.3% | 58.5% | -4.8 | 6 / 6 | 5 / 11 |
| Veteran | all | the Glasswrights | 600 | 73.3% | 70.7% | -2.6 | 6 / 6 | 15 / 12 |
| Veteran | all | Eclipse | 600 | 62.3% | 60.0% | -2.3 | 7 / 7 | 6 / 6 |
| Veteran | 1 | all | 1200 | 47.6% | 42.0% | -5.6 | 6 / 6 | 24 / 24 |
| Veteran | 1 | Sunward Crusade | 200 | 32.0% | 27.0% | -5.0 | 7 / 6 | 9 / 3 |
| Veteran | 1 | Hegemony Navy | 200 | 40.0% | 40.5% | +0.5 | 7 / 7 | 3 / 3 |
| Veteran | 1 | Ashfall Hullbreakers | 200 | 57.5% | 46.5% | -11.0 | 6 / 6 | 2 / 4 |
| Veteran | 1 | the Chorus | 200 | 53.5% | 47.0% | -6.5 | 6 / 6 | 1 / 3 |
| Veteran | 1 | the Glasswrights | 200 | 59.5% | 54.0% | -5.5 | 6 / 6 | 6 / 8 |
| Veteran | 1 | Eclipse | 200 | 43.0% | 37.0% | -6.0 | 7 / 7 | 3 / 3 |
| Veteran | 2 | all | 1200 | 62.9% | 59.0% | -3.9 | 6 / 6 | 12 / 8 |
| Veteran | 2 | Sunward Crusade | 200 | 43.0% | 34.5% | -8.5 | 7 / 7 | 2 / 2 |
| Veteran | 2 | Hegemony Navy | 200 | 46.0% | 43.5% | -2.5 | 7 / 7 | 0 / 0 |
| Veteran | 2 | Ashfall Hullbreakers | 200 | 73.5% | 65.5% | -8.0 | 6 / 6 | 3 / 0 |
| Veteran | 2 | the Chorus | 200 | 64.0% | 60.5% | -3.5 | 6 / 6 | 0 / 2 |
| Veteran | 2 | the Glasswrights | 200 | 79.0% | 78.0% | -1.0 | 6 / 6 | 5 / 2 |
| Veteran | 2 | Eclipse | 200 | 72.0% | 72.0% | +0.0 | 6 / 6 | 2 / 2 |
| Veteran | 3 | all | 1200 | 64.6% | 59.8% | -4.8 | 7 / 7 | 29 / 21 |
| Veteran | 3 | Sunward Crusade | 200 | 40.0% | 36.0% | -4.0 | 8 / 8 | 10 / 7 |
| Veteran | 3 | Hegemony Navy | 200 | 43.5% | 38.0% | -5.5 | 8 / 8 | 7 / 3 |
| Veteran | 3 | Ashfall Hullbreakers | 200 | 78.0% | 65.5% | -12.5 | 6 / 7 | 3 / 2 |
| Veteran | 3 | the Chorus | 200 | 72.5% | 68.0% | -4.5 | 7 / 7 | 4 / 6 |
| Veteran | 3 | the Glasswrights | 200 | 81.5% | 80.0% | -1.5 | 6 / 6 | 4 / 2 |
| Veteran | 3 | Eclipse | 200 | 72.0% | 71.0% | -1.0 | 7 / 7 | 1 / 1 |


## Table: same fleets at both levels (decisions alone), before and after

| Level | Sector | Enemy | Battles | Player wins before | after | change | Median rounds before / after | Past round 12 before / after |
|---|---|---|---:|---:|---:|---:|---:|---:|
| **Standard** | all | all | 3600 | 55.6% | **57.9%** | +2.3 | 6 / 6 | 56 / 63 |
| Standard | all | Sunward Crusade | 600 | 38.5% | 38.7% | +0.2 | 7 / 7 | 13 / 19 |
| Standard | all | Hegemony Navy | 600 | 40.8% | 44.3% | +3.5 | 7 / 7 | 4 / 9 |
| Standard | all | Ashfall Hullbreakers | 600 | 58.7% | 64.8% | +6.1 | 6 / 6 | 4 / 1 |
| Standard | all | the Chorus | 600 | 59.2% | 59.5% | +0.3 | 6 / 6 | 12 / 9 |
| Standard | all | the Glasswrights | 600 | 73.8% | 75.8% | +2.0 | 6 / 6 | 9 / 17 |
| Standard | all | Eclipse | 600 | 62.7% | 64.3% | +1.6 | 6 / 7 | 14 / 8 |
| Standard | 1 | all | 1200 | 51.5% | 54.0% | +2.5 | 6 / 6 | 13 / 16 |
| Standard | 1 | Sunward Crusade | 200 | 39.0% | 39.0% | +0.0 | 7 / 6 | 4 / 5 |
| Standard | 1 | Hegemony Navy | 200 | 42.0% | 45.5% | +3.5 | 6 / 6 | 1 / 2 |
| Standard | 1 | Ashfall Hullbreakers | 200 | 54.5% | 58.0% | +3.5 | 6 / 6 | 0 / 1 |
| Standard | 1 | the Chorus | 200 | 52.0% | 54.5% | +2.5 | 6 / 5 | 3 / 0 |
| Standard | 1 | the Glasswrights | 200 | 66.5% | 71.5% | +5.0 | 6 / 6 | 4 / 7 |
| Standard | 1 | Eclipse | 200 | 55.0% | 55.5% | +0.5 | 7 / 6 | 1 / 1 |
| Standard | 2 | all | 1200 | 57.3% | 59.7% | +2.4 | 6 / 6 | 17 / 15 |
| Standard | 2 | Sunward Crusade | 200 | 37.5% | 39.0% | +1.5 | 7 / 7 | 4 / 4 |
| Standard | 2 | Hegemony Navy | 200 | 40.0% | 42.0% | +2.0 | 7 / 7 | 0 / 1 |
| Standard | 2 | Ashfall Hullbreakers | 200 | 63.0% | 67.5% | +4.5 | 6 / 6 | 0 / 0 |
| Standard | 2 | the Chorus | 200 | 61.0% | 60.0% | -1.0 | 6 / 6 | 2 / 3 |
| Standard | 2 | the Glasswrights | 200 | 75.5% | 75.5% | +0.0 | 6 / 6 | 4 / 3 |
| Standard | 2 | Eclipse | 200 | 67.0% | 74.0% | +7.0 | 6 / 7 | 7 / 4 |
| Standard | 3 | all | 1200 | 58.0% | 60.1% | +2.1 | 7 / 7 | 26 / 32 |
| Standard | 3 | Sunward Crusade | 200 | 39.0% | 38.0% | -1.0 | 8 / 8 | 5 / 10 |
| Standard | 3 | Hegemony Navy | 200 | 40.5% | 45.5% | +5.0 | 7.5 / 7 | 3 / 6 |
| Standard | 3 | Ashfall Hullbreakers | 200 | 58.5% | 69.0% | +10.5 | 6 / 6 | 4 / 0 |
| Standard | 3 | the Chorus | 200 | 64.5% | 64.0% | -0.5 | 7 / 7 | 7 / 6 |
| Standard | 3 | the Glasswrights | 200 | 79.5% | 80.5% | +1.0 | 6 / 6 | 1 / 7 |
| Standard | 3 | Eclipse | 200 | 66.0% | 63.5% | -2.5 | 6 / 7 | 6 / 3 |
| **Veteran** | all | all | 3600 | 58.4% | **55.2%** | -3.2 | 6 / 6 | 65 / 55 |
| Veteran | all | Sunward Crusade | 600 | 38.3% | 34.7% | -3.6 | 7 / 7 | 21 / 13 |
| Veteran | all | Hegemony Navy | 600 | 43.2% | 43.0% | -0.2 | 7 / 7 | 10 / 8 |
| Veteran | all | Ashfall Hullbreakers | 600 | 69.7% | 60.3% | -9.4 | 6 / 6 | 8 / 7 |
| Veteran | all | the Chorus | 600 | 63.3% | 59.2% | -4.1 | 6 / 6 | 5 / 10 |
| Veteran | all | the Glasswrights | 600 | 73.3% | 72.8% | -0.5 | 6 / 6 | 15 / 11 |
| Veteran | all | Eclipse | 600 | 62.3% | 61.3% | -1.0 | 7 / 7 | 6 / 6 |
| Veteran | 1 | all | 1200 | 47.6% | 44.6% | -3.0 | 6 / 6 | 24 / 23 |
| Veteran | 1 | Sunward Crusade | 200 | 32.0% | 28.5% | -3.5 | 7 / 6 | 9 / 4 |
| Veteran | 1 | Hegemony Navy | 200 | 40.0% | 44.5% | +4.5 | 7 / 6 | 3 / 4 |
| Veteran | 1 | Ashfall Hullbreakers | 200 | 57.5% | 48.0% | -9.5 | 6 / 6 | 2 / 4 |
| Veteran | 1 | the Chorus | 200 | 53.5% | 47.5% | -6.0 | 6 / 6 | 1 / 2 |
| Veteran | 1 | the Glasswrights | 200 | 59.5% | 58.5% | -1.0 | 6 / 6 | 6 / 6 |
| Veteran | 1 | Eclipse | 200 | 43.0% | 40.5% | -2.5 | 7 / 7 | 3 / 3 |
| Veteran | 2 | all | 1200 | 62.9% | 61.2% | -1.7 | 6 / 6 | 12 / 12 |
| Veteran | 2 | Sunward Crusade | 200 | 43.0% | 40.0% | -3.0 | 7 / 7 | 2 / 3 |
| Veteran | 2 | Hegemony Navy | 200 | 46.0% | 45.5% | -0.5 | 7 / 7 | 0 / 1 |
| Veteran | 2 | Ashfall Hullbreakers | 200 | 73.5% | 67.5% | -6.0 | 6 / 6 | 3 / 1 |
| Veteran | 2 | the Chorus | 200 | 64.0% | 61.5% | -2.5 | 6 / 6 | 0 / 2 |
| Veteran | 2 | the Glasswrights | 200 | 79.0% | 80.0% | +1.0 | 6 / 6 | 5 / 3 |
| Veteran | 2 | Eclipse | 200 | 72.0% | 72.5% | +0.5 | 6 / 6 | 2 / 2 |
| Veteran | 3 | all | 1200 | 64.6% | 59.9% | -4.7 | 7 / 7 | 29 / 20 |
| Veteran | 3 | Sunward Crusade | 200 | 40.0% | 35.5% | -4.5 | 8 / 8 | 10 / 6 |
| Veteran | 3 | Hegemony Navy | 200 | 43.5% | 39.0% | -4.5 | 8 / 8 | 7 / 3 |
| Veteran | 3 | Ashfall Hullbreakers | 200 | 78.0% | 65.5% | -12.5 | 6 / 7 | 3 / 2 |
| Veteran | 3 | the Chorus | 200 | 72.5% | 68.5% | -4.0 | 7 / 7 | 4 / 6 |
| Veteran | 3 | the Glasswrights | 200 | 81.5% | 80.0% | -1.5 | 6 / 6 | 4 / 2 |
| Veteran | 3 | Eclipse | 200 | 72.0% | 71.0% | -1.0 | 7 / 7 | 1 / 1 |

