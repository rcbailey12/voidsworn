# Battle 2 on Battle 1's open strip (issue 1393, R366)

Ryan, Nov 20 2026 19:45 UTC: "Give it Battle 1's open strip". On a first run (teaching gate on), Battle 2 now opens like Battle 1:
`shape:'open', arena:'strip', dep:'line', edgeFeature:true` (campaign3d.js `teachingBattle`, campaign.gd `teachingBattle`). The
Corsairs and the forced round 3 to 4 enemy reinforcements stay. Deployment is `line`, the same as Battle 1: both fleets start
facing each other across open space, which is the fair read for a fight that teaches reinforcements.

## Picture

`B2_1393_before_after.png`: seed 121, fresh profile, Standard, the start of teaching Battle 2 in the browser rules (rules-state
diagram drawn from the battle state, not an in-game render). Before: the node's own archipelago with 82 terrain hexes. After:
the open strip with 3 edge rocks. Remake: `node tools/teaching_1393/dump.js <repo> <game checkout> 121 out.json`, then
`draw.js` (see the scripts).

## Measured: fresh-profile Sunward, 240 paired seeds

`node tools/teaching_1393/sim_fresh_1393.js <checkout> <standard|veteran> 240 1 <out.json>`: the sim_1178 Monte Carlo driver
plus what a new profile really gets (teaching gate on, every battle through `teachingBattle` as battleScreen does). Before = main
69955313, after = this branch. Browser rules copy. 0 driver errors.

| AI | Battle 2 not won (before / after) | Ships lost in Battle 2 | Avg Battle 2 rounds | Seeds losing more / fewer ships there | Runs won | Run flips win to loss / loss to win |
| --- | --- | --- | --- | --- | --- | --- |
| Standard | 3 / 0 | 39 / 34 | 3.79 / 3.26 | 22 / 24 | 175 / 167 | 37 / 29 |
| Veteran | 3 / 4 | 68 / 83 | 4.16 / 3.77 | 48 / 36 | 80 / 87 | 38 / 45 |

- All 240 after-runs fight Battle 2 on the open strip against the Corsairs with the round 3 to 4 reinforcements (checked per run).
- **The bot does not see Battle 2 as a spike, before or after**: it wins it in 98% or more of runs both ways. The human loss on
  seed 121 (council playtest) does not reproduce with the bot; on seed 121 the bot wins Battle 2 in both arms (Standard: 0 ships
  lost before, 1 after).
- Standard: slightly easier Battle 2 (no losses there, fewer ships lost, shorter). Veteran: Battle 2 ends sooner but costs a bit
  more (83 ships lost against 68 over 240 runs; open space gives the Corsair rockets clear lines). Whole-run win rates move by
  about 3 points either way, inside paired-seed noise (flips 37/29 and 38/45).
- So the change mostly changes what Battle 2 looks like and how readable it is (Ryan's pick), not the bot's odds. A human
  playtest of the first run is the real check.
