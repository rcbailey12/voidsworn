Difficulty curve evidence pack, Oct 28 program item 4. Chair sim work (Rey). Pinned to main 264f441d. Findings are observations for Opus to confirm, not orders.

## Method

Four fresh-seed full-run simulations in the browser build's sim harness: `node sim3d.js runsim 100` at seeds 7201, 7202, 7203, 7204 (400 runs total), run Oct 28, 2026. Per-seed outputs saved in the program working folder (runsim_7201.txt to runsim_7204.txt). All figures below are pooled across the four seeds, weighted by battle count where the unit is a fight.

Caveats, stated once and applicable throughout: runSim plays a simplified economy (345 credits, CP cap 14, against the shipped 120 credits and CP cap 10; no prizes, salvage, or events), and the bot's routing and reward choices are not a human's. Treat the absolute win rate as a bot figure. The shape of the curve (where runs die, which fight classes are hardest, how attrition accumulates) is the evidence; it does not depend on the bot playing well, only on it playing consistently.

## The funnel (400 runs)

- Reach sector 2: 269 (67.3%)
- Reach sector 3: 134 (33.5%)
- Won: 83 (20.8%)
- Died in sector 1: 131 (32.8%)
- Died in sector 2: 135 (33.8%)
- Died in sector 3: 51 (12.8%)
- Win rate conditional on reaching sector 3: 61.9%

Per-seed wins: 21, 23, 19, 20. The 19 to 23 spread is within binomial noise at n=100 (standard deviation about 4 points); no seed looks broken.

Against the Oct 27 balance pack: tuning seeds reproduced the step 9 figures exactly (20 and 19 wins); the fresh pool there (seeds 7103 to 7108, 600 runs) won 16.7%. This pool won 20.8%. Combined fresh evidence across both programs: 183 wins in 1,000 runs, about 18%. The honest headline is roughly one bot run in five wins, with per-pool swings of 17 to 21%.

## Fight classes, pooled (win rate / ships lost per fight / enemy-to-player CP ratio / rounds)

- S1 battle (1,140 fights): 94.0% / 0.27 / 1.00 / 4.0
- S1 elite (199): 79.5% / 0.83 / 1.34 / 4.9
- S1 boss (294): 91.8% / 0.70 / 1.86 / 7.7
- S2 battle (486): 85.4% / 0.65 / 1.46 / 4.7
- S2 elite (117): 69.9% / 1.21 / 1.85 / 5.0
- S2 boss (164): 81.5% / 0.90 / 2.09 / 8.0
- S3 battle (222): 87.9% / 0.46 / 1.51 / 4.1
- S3 elite (69): 75.5% / 1.26 / 1.74 / 4.5
- S3 boss (90): 92.1% / 0.96 / 1.86 / 7.3

## Findings

1. The curve is attrition-driven, not boss-gated. Every fight class is won 70 to 94% of the time, yet 79% of runs die. What kills runs is cumulative ship loss under permanent loss: ships lost per fight climbs from 0.27 in sector 1 battles to 0.83 to 1.26 across elite and boss fights in sectors 2 and 3, with no full reset between sectors. A run rarely dies to one fight; it bleeds out over four or five.

2. Sector 2 elites are the hardest fight class in the game. At 69.9% pooled, they are won less often than the sector 2 boss (81.5%), the sector 3 boss (92.1%), and every other class. They also carry near-peak attrition (1.21 ships per fight). An elite band that out-difficulties its own sector's boss is an inversion: the optional, higher-reward fight is the real gate, and it sits immediately after the sector transition, where the funnel's second cliff is (135 of 400 runs die in sector 2, the largest death bucket).

3. The steepest enemy scaling step is into sector 2. The enemy-to-player CP ratio rises from 1.00 (S1 battles) to 1.46 (S2 battles) and peaks at 2.09 at the S2 boss. Sector 3 ratios (1.51 to 1.86) are no higher than sector 2's. The difficulty step the player feels is S1 to S2; S3 is more of the same against a filtered population.

4. Sector 3 win rates are survivorship artifacts. The S3 boss's 92.1% does not mean the finale is easy; only 134 of 400 runs arrive, and they arrive with built fleets that already survived the S2 elite band. Read S3 figures as "hard for the fleets that get there" evidence of nothing stronger. Sample sizes are also small (69 to 90 fights per class).

5. Bosses are long, not lethal. Boss fights run 7.3 to 8.0 rounds against 4.0 to 5.0 for everything else, but their win rates (81.5 to 92.1%) sit above the elite classes in their own sectors. If a designer expects the boss to be each sector's difficulty peak, the sims say the peak is misplaced by one node type.

## Run 1 / Run 5 / Run 10

At an 18 to 21% win rate, a player of bot-comparable strength statistically banks a first win around run 4 to 6. Runs 1 to 3 mostly end in sector 1 or 2 (about two-thirds of all runs never reach sector 3), so the content gated behind deep runs (sector 3, Heat, permanent Nemesis resolution) is content most early playtime never touches. By run 10 the player has likely won once or twice, but the lived experience of those 10 runs is dominated by the S2 elite band: it is where fleets bleed and where a third of all runs end. The difficulty curve is the retention curve; the loop legs' run 4 leak point sits exactly at the funnel's second cliff, which is consistent with Argon's death-spiral mechanism (pyrrhic sector 1 boss win, crippled fleet, sector 2 opening) as a contributing cause, though the sims record outcomes, not causes.

## Not checked

- Cause of death inside a run (the sim reports outcomes per fight class, not the state of the fleet entering each fight; the death-spiral mechanism is consistent with these numbers, not proven by them).
- Per-faction and per-admiral difficulty splits from runsim (the Oct 27 bossmatrix covers the admiral band separately: 55% to 85% by admiral, faction spread 23 points, Ithar the low outlier at 73%).
- Human difficulty: routing, reward picks, and retreat decisions are the bot's. A skilled human plausibly wins more; a first-time human plausibly wins less. The funnel shape is the transferable claim.
- Godot build difficulty: these sims run the browser build's harness at the pin; G3 parity is Opus's lane.
