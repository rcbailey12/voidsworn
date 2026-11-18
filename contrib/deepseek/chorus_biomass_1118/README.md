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

## The measured table

240 Chorus runs per setup, paired seeds 7000 to 7239, existing campaign bot,
Veteran AI, all four Chorus admirals rotated in the same order per seed. A run
win means beating the sector 3 flagship.

| Setup | Win rate (95 percent) | Paired win delta | Mean sectors | Reach S3 | Loss spiral | Income per battle |
|---|---:|---:|---:|---:|---:|---:|
| Today: credits | 72.1% (66.1 to 77.4) | 0.0 | 2.67 | 79.2% | 4.2% (10/240) | 118 +- 81, p10-p90 43-251 |
| Biomass flat | 66.3% (60.1 to 71.9) | -5.8 (-11.3 to -0.3) | 2.58 | 71.7% | 3.8% (9/240) | 116 +- 80, p10-p90 43-248 |
| Biomass flat + kill bonus | 67.9% (61.8 to 73.5) | -4.2 (-9.7 to +1.4) | 2.59 | 73.3% | 2.9% (7/240) | 124 +- 82, p10-p90 48-255 |

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

| Setup | Spiral | Paired spiral delta | Starvation (two setbacks, no recovery) | Two losses in a row |
|---|---:|---:|---:|---:|
| Credits | 4.2% (10/240) | 0.0 | 18.3% (44/240) | 4.2% (10/240) |
| Biomass flat | 3.8% (9/240) | -0.4 +- 2.7 | 20.4% (49/240) | 4.2% (10/240) |
| Biomass + kill | 2.9% (7/240) | -1.3 +- 2.7 | 19.2% (46/240) | 3.3% (8/240) |

The narrower two-loss streak is the same 4.2 percent for credits and flat
biomass, and lower with the kill bonus. The broader starvation measure is 2.1
points higher for flat biomass (95 percent interval -3.0 to +5.1) and 0.8 points
higher with the kill bonus (-4.5 to +6.1), so neither is a real separation. The
loss spiral is not where the biomass flow fails.

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
  and spiral test.
- sim/run_sim.js runs a seed block for one setup.
- sim/summarize.js builds results.csv and results_sectors.csv.
- The job folder delivered here: results.csv and results_sectors.csv.

Reproduce (about 7 minutes per setup, 3 setups run in parallel on this PC):

```
node contrib/deepseek/chorus_biomass_1118/sim/run_sim.js --setup baseline --n 240 --seed0 7000 --out raw/baseline.json
node contrib/deepseek/chorus_biomass_1118/sim/run_sim.js --setup biomass --n 240 --seed0 7000 --out raw/biomass.json
node contrib/deepseek/chorus_biomass_1118/sim/run_sim.js --setup biomass_kill --n 240 --seed0 7000 --out raw/biomass_kill.json
node contrib/deepseek/chorus_biomass_1118/sim/summarize.js raw/baseline.json raw/biomass.json raw/biomass_kill.json
```

Raw JSON was kept in the system temp folder, not in this folder.

## Checks

- Standing checks: `node contrib/opus/tools/run_all_checks.js` returned exit 0,
  67 PASS and 0 FAIL (two KNOWN rows as configured). Full log in the temp folder.
- No change to battle.js, data.js, core.js, campaign_run.js, sim3d.js or the
  Godot game, so rules parity, campaign parity, the export tables and the save
  format are untouched. The runner may still run parity; it should pass because
  no root game file changed.
- Callers: no game function, constant or save field was added or changed. The
  new code is in contrib/deepseek/chorus_biomass_1118/sim only.
- Saves: the sim never writes a player save. It calls the shipped saveRun in
  memory only, and no run save shape changed.
- Twins: not triggered, both sides untouched.
- UI: not triggered, no screen reads any new value.
- CI: no new test file that GitHub should run. The sim is a evidence script
  under contrib/deepseek, not a standing test. GitHub's normal rows (standing
  checks, no em dashes, Godot rules parity, Godot game checks) still apply to
  the branch and see only these new text files.

## Limits

- One bot policy. Absolute win rates are bot-relative, so compare rows, not the
  72 percent to the game.
- 240 runs per setup give about +-5 points on a win rate and about +-3 points on
  the spiral counts.
- This tests the simplest flat biomass flow: no digestion of credits into
  biomass, no starlight trickle, no Feeding Grounds node or price changes. It
  answers the flow question the Board asked, not the full Approach A design.
- The biomass setup locks non-battle credits out of hull work. If the Board
  later allows a bad-rate credit digestion, that would recover some of the
  win-rate gap without changing the flat flow.
