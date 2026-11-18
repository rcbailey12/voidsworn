# Issue 1085: Chorus biomass flat per win, measured against today's credits

Sims only. No game file changed. The shipped files are loaded read only and the
biomass layer lives in this folder.

## One-line pick

Pay biomass flat per win plus the small capped kill bonus (2 per kill, cap 12):
it does not open a loss spiral (2.9 percent against 4.2 percent for credits) and
its run win rate is within noise of today's credits (67.9 against 72.1 percent).

Flat biomass alone also stays out of the spiral (3.8 percent against 4.2
percent), but it costs about 6 points of run win rate. The kill bonus recovers
about a third of that cost.

Run 2 corrected the spiral price from a full repair to the stated 25 percent
repair. That changes 3 battle verdicts but no run-level spiral or starvation
count, so the pick is unchanged (see "Run 2 correction" below).

## The measured table

240 Chorus runs per setup, paired seeds 7000 to 7239, existing campaign bot,
Veteran AI, all four Chorus admirals rotated in the same order per seed. A run
win means beating the sector 3 flagship. Run 2 repeated the same seeds and
reproduced every number below except the corrected spiral pricing, which is
called out in its own section.

| Setup | Win rate (95 percent) | Paired win delta | Mean sectors | Reach S3 | Loss spiral run 1 -> run 2 | Income per battle |
|---|---:|---:|---:|---:|---:|---:|
| Today: credits | 72.1% (66.1 to 77.4) | 0.0 | 2.67 | 79.2% | 4.2% -> 4.2% (10/240) | 118 +- 81, p10-p90 43-251 |
| Biomass flat | 66.3% (60.1 to 71.9) | -5.8 (-11.3 to -0.3) | 2.58 | 71.7% | 3.8% -> 3.8% (9/240) | 116 +- 80, p10-p90 43-248 |
| Biomass flat + kill bonus | 67.9% (61.8 to 73.5) | -4.2 (-9.7 to +1.4) | 2.59 | 73.3% | 2.9% -> 2.9% (7/240) | 124 +- 82, p10-p90 48-255 |

Paired deltas are against the credits row on the same seeds. Income is the flat
per-win battle payment only: credits in the first row, biomass in the other two,
with the kill bonus added in the last row. It excludes node spoils, salvage,
prize money and event money.

Per-sector paired differences: mean sectors -0.09 (-0.15 to -0.04) for flat
biomass and -0.08 (-0.14 to -0.02) with the kill bonus; reaching sector 3
-7.5 points (-12.0 to -3.0) and -6.0 points (-11.0 to -1.0).

## Fleet and total hull after each sector

State after the last battle the run fought in that sector, including a battle
the run lost. n is the number of runs that fought in that sector.

| Setup | Sector | n | Fleet | Hull | Hull percent |
|---|---:|---:|---:|---:|---:|
| Credits | 1 | 240 | 2.84 | 320 / 341 | 81.4% |
| Credits | 2 | 210 | 3.94 | 483 / 505 | 85.8% |
| Credits | 3 | 190 | 4.93 | 641 / 666 | 87.3% |
| Biomass flat | 1 | 240 | 2.59 | 290 / 311 | 79.6% |
| Biomass flat | 2 | 206 | 3.60 | 426 / 453 | 78.6% |
| Biomass flat | 3 | 172 | 5.05 | 650 / 679 | 88.9% |
| Biomass + kill | 1 | 240 | 2.60 | 291 / 312 | 79.1% |
| Biomass + kill | 2 | 205 | 3.73 | 441 / 467 | 80.4% |
| Biomass + kill | 3 | 176 | 4.94 | 647 / 671 | 88.9% |

The biomass fleet is about 0.25 ships and 1 to 2 hull percent behind after
sector 1, and about 0.2 ships behind after sector 2. By the end of sector 3 the
biomass runs that get there have caught up or are slightly ahead in ships,
because survivors concentrate command points into better hulls.

## Loss spiral and starvation

A "loss" is a battle not won (a retreat or a defeat). A "setback" is a loss or a
win that cost ships. A defeat ends the run in this game, so a literal two-loss
streak needs a retreat first, which is why the literal spiral count is small.

Spiral (the job's definition): two losses in a row where, at the second, the
hull money (credits in row one, biomass in rows two and three) cannot pay for a
25 percent hull repair of the worst ship or for the cheapest hull the faction can
field. An empty fleet counts as no recovery.

| Setup | Spiral run 1 | Spiral run 2 | Starvation run 1 | Starvation run 2 | Two losses in a row |
|---|---:|---:|---:|---:|---:|
| Credits | 4.2% (10/240) | 4.2% (10/240) | 18.3% (44/240) | 18.3% (44/240) | 4.2% (10/240) |
| Biomass flat | 3.8% (9/240) | 3.8% (9/240) | 20.4% (49/240) | 20.4% (49/240) | 4.2% (10/240) |
| Biomass + kill | 2.9% (7/240) | 2.9% (7/240) | 19.2% (46/240) | 19.2% (46/240) | 3.3% (8/240) |

Run 1 and run 2 are the same 240 paired seeds per setup. The run 1 column is
recomputed from run 2's records with run 1's full repair price (spiralFull and
starveFull in results_runs.csv) and matches the PR 1094 counts exactly.

The narrower two-loss streak is the same 4.2 percent for credits and flat
biomass, and lower with the kill bonus. The broader starvation measure is 2.1
points higher for flat biomass (95 percent interval -3.0 to +5.1) and 0.8 points
higher with the kill bonus (-4.5 to +6.1), so neither is a real separation. The
loss spiral is not where the biomass flow fails. The paired spiral deltas are
unchanged: -0.4 +- 2.7 points for flat biomass and -1.3 +- 2.7 with the kill
bonus.

## Run 2 correction: 25 percent repair, not a full repair

Run 1 wrote the spiral test as a 25 percent repair but priced a full repair of
every missing hull point on the worst ship. Artoo's example: a 100 hull ship
missing 50 with 20 to spend was counted stuck even though a 25 hull repair costs
13. Run 2 prices the stated test: 25 percent of the worst ship's maximum hull,
capped at what it is missing, at the shipped 1 credit per 2 hull with the same
price multiplier, or the cheapest hull purchase. The code lives in sim/spiral.js
and both the driver and spiral_test.js use it. The test covers Artoo's example
(100 hull, 50 missing, 20 to spend: recoverable) and a truly unrecoverable case
(10 to spend, cheapest hull 90).

The corrected price flips 3 battle verdicts in the 720 runs:

- credits seed 7076, sector 2 retreat: 97 missing on a 135 hull ship, 46
  credits, 25 percent repair 21 against a full repair of 59 at priceMult 1.2.
- biomass seed 7076, sector 2 retreat: 134 missing on a 135 hull ship, 51
  biomass, 25 percent repair 21 against a full repair of 81 at priceMult 1.2.
- biomass seed 7132, sector 3 retreat: 131 missing on a 135 hull ship, 41
  biomass, 25 percent repair 17 against a full repair of 66.

No run-level spiral or starvation flag changes, because each of those runs still
met the test later: the two seed 7076 runs ended in a defeat that wiped the fleet,
and the seed 7132 run had a second retreat in the same streak where even the 25
percent repair cost more than the money left. results_runs.csv carries the
per-battle price, the 25 percent cost, the full cost, both unrecoverable flags
and both run-level flags, so both definitions can be recounted.

## Where the win-rate cost comes from

The flat payment itself is the same flow: mean 116 biomass against 118 credits,
same spread. The gap is consistent with credits being demoted away from hull
work. In these setups node spoils, salvage scrap, prize strips, ransoms, event
money and boon declines still pay credits, and credits still buy refits, but
they can no longer buy hull repair, new hulls or Mk growth. Over a run the bot
bought 5.55 hulls with biomass against 6.08 with credits, spent slightly less per
yard visit and finished with 548 biomass plus 355 credits unspent (the credits
could not be used for hulls). The kill bonus adds 8 biomass per battle on
average, which is why it recovers part of the gap.

## Assumptions

1. Chorus only. Four Chorus admirals (matriarch, razormaw, mending, voice)
   rotated by seed. Veteran AI. The battle pilot is the existing montecarlo bot
   from contrib/muse/tools/montecarlo/bot.js, unchanged.
2. Baseline is today's game untouched: the shipped rewardFlow credit formula,
   the shipped shipyard (1 credit per 2 hull repaired, shipped hull prices and
   Mk costs, shipped node rewards).
3. Biomass setups move the 120 starting credits into biomass at run start, so
   buying power at the start matches the baseline. The flat per-win payment is
   the shipped credit formula with its modifiers, paid as biomass instead of
   credits, halved on a partial win exactly as credits are.
4. Biomass buys hull repair at 1 per 2 hull, new hulls at the shipped hull
   prices, and Mk growth at the shipped mkCost. All use the same price
   multiplier as credits. Credits keep buying refits and paying events and
   prizes. This is the "spent on Chorus repair and growth in place of shipyard
   purchases" reading of the brief.
5. The kill bonus is 2 biomass per enemy ship destroyed, capped at 12 biomass
   per battle.
6. Drydocks, field repairs, the 15 percent post-win patch, the 40 percent
   sector-transit patch, in-battle Chorus regen, Gorge, the spawning field and
   the martyr relic are all unchanged.
7. Income per battle is recorded from the rewardFlow wrapper at the moment the
   battle pays, so partial wins are already halved and the kill bonus is already
   capped.
8. Timeouts are resolved the way the harness always resolves them: a non-boss
   timeout is a retreat, a boss timeout is a loss.

## Method and files

- sim/loader_main.js is a verbatim copy of the muse montecarlo loader at main
  548b9e3. It loads data.js, core.js, battle.js, campaign_meta.js,
  campaign_run.js and campaign3d.js from the repo root read only.
- sim/bot.js is a verbatim copy of the muse montecarlo battle pilot.
- sim/driver_biomass.js is the harness driver plus the biomass patch layer. The
  patch layer lives only in memory. It moves the flat battle payment to biomass,
  swaps the hull pool inside the shipped shipyard ACT handlers, snapshots the
  fleet before endRun clears RUN, and records the per-battle income, setbacks
  and both the corrected and run 1 spiral tests.
- sim/run_sim.js runs a seed block for one setup.
- sim/spiral.js is the shared spiral recovery test: 25 percent of the worst
  ship's maximum hull, capped at what it is missing, priced as the shipped
  repair is priced, or the cheapest hull.
- spiral_test.js is the tiny unit test for sim/spiral.js (Artoo's example plus an
  unrecoverable case). run_all_checks.js runs it in the standing checks.
- sim/summarize.js builds results.csv, results_sectors.csv and results_runs.csv.
- The job folder delivered here: results.csv, results_sectors.csv,
  results_runs.csv (one row per run and setup), and results_run1.csv plus
  results_sectors_run1.csv (run 1's summary, kept for the side by side).

Reproduce (about 9 minutes per setup on this PC, 3 setups in parallel):

```
node contrib/deepseek/chorus_biomass_1118/sim/run_sim.js --setup baseline --n 240 --seed0 7000 --out raw/baseline.json
node contrib/deepseek/chorus_biomass_1118/sim/run_sim.js --setup biomass --n 240 --seed0 7000 --out raw/biomass.json
node contrib/deepseek/chorus_biomass_1118/sim/run_sim.js --setup biomass_kill --n 240 --seed0 7000 --out raw/biomass_kill.json
node contrib/deepseek/chorus_biomass_1118/sim/summarize.js raw/baseline.json raw/biomass.json raw/biomass_kill.json
node contrib/deepseek/chorus_biomass_1118/spiral_test.js
```

Raw JSON was kept in the system temp folder, not in this folder.

## Checks

- Standing checks: `node contrib/opus/tools/run_all_checks.js` returned exit 0,
  68 PASS and 0 FAIL (two KNOWN rows as configured), including the new
  `spiral_test | PASS | PASS: 6 spiral recovery checks` row. Full log in the
  temp folder.
- Spiral test: `node contrib/deepseek/chorus_biomass_1118/spiral_test.js`
  printed 6 PASS lines and `PASS: 6 spiral recovery checks`.
- Run 2 reran all 3 setups on seeds 7000 to 7239 and reproduced run 1's wins
  (173, 159, 163), sectors, fleet, hull and income exactly. Only the spiral
  pricing changed.
- No change to battle.js, data.js, core.js, campaign_run.js, sim3d.js or the
  Godot game. `cmd.exe //c "tools\\pc\\parity.bat nopause"` returned exit 0:
  `PASS: the Godot port matches the game's rules exactly.` and
  `PASS: the Godot campaign matches the game on all 30 seeded runs`. Rules
  parity, campaign parity, the export tables and the save format are untouched.
- Callers: no game function, constant or save field was added or changed. The
  new code is in contrib/deepseek/chorus_biomass_1118 only. The one file outside
  that folder is the single run_all_checks.js row for the new test.
- Saves: the sim never writes a player save. It calls the shipped saveRun in
  memory only, and no run save shape changed.
- Twins: not triggered, both sides untouched.
- UI: not triggered, no screen reads any new value.
- CI: the new test file spiral_test.js is added to
  contrib/opus/tools/run_all_checks.js, so GitHub's standing checks row runs it.
  The other GitHub rows (no em dashes, Godot rules parity, Godot game checks)
  see only new text and data files under contrib/deepseek.

## Limits

- One bot policy. Absolute win rates are bot-relative, so compare rows, not the
  72 percent to the game.
- 240 runs per setup give about +-5 points on a win rate and about +-3 points on
  the spiral counts.
- The spiral share is dominated by defeats: a wiped fleet is unrecoverable
  under any repair price, so the 25 percent price only decides the rare mid-run
  pair where the fleet survives and the money is small. That is why its
  correction moves 3 battle verdicts and 0 run flags here.
- This tests the simplest flat biomass flow: no digestion of credits into
  biomass, no starlight trickle, no Feeding Grounds node or price changes. It
  answers the flow question the Board asked, not the full Approach A design.
- The biomass setup locks non-battle credits out of hull work. If the Board
  later allows a bad-rate credit digestion, that would recover some of the
  win-rate gap without changing the flat flow.
