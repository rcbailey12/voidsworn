# Issue 1086: Glasswright and Eclipse economy ideas, measured against today

Sims only. No game file changed. The shipped files are loaded read only and the
Glasswright and Eclipse layers live in this folder.

## One-line picks

- Glasswright: build cullet (G-B) first. It is still the only measured piece that
  helps (+5.4 win points, 95 percent +0.4 to +10.5, loss spiral flat). Kiln
  repair (G-A) is cost-neutral and one-jump commissions (G-C) now cost about 6.7
  win points after the one-order fix, so the full simplest form nets -1.3. The
  pick does not change, but the full form is now a small loss, not a small gain.
- Eclipse: build core recovery (E-B) first, unchanged from run 1. It adds +10.4
  win points (95 percent +6.1 to +14.8) and halves the loss spiral. Archive slots
  (E-A) at a 45-credit copy plus a 40 percent rebuild are close to neutral alone
  and shave about 3 points off the combined line, so retune E-A before adding it.
  The pick does not change.

The full recommended simplest forms do not open a loss spiral for either
faction. The Eclipse form is a real gain and significant. The Glasswright form is
now slightly negative, carried by cullet and held back by commissions.

## What was measured

240 paired runs per setup, seeds 7000 to 7239, the four admirals of each faction
rotated in the same order per seed, the existing campaign bot, Veteran AI. A run
win means beating the sector 3 flagship. "Today" is the shipped credits and
shipyard economy. Each faction's recommended direction is tested in the simplest
form the job names, and each piece is also tested alone so the table shows which
piece carries the result.

Run 2 reran all nine setups on the same seeds with two corrections: one
commission in flight is now enforced at the purchase point, and the loss spiral
uses the shared issue 1085 test (a 25 percent repair, capped at what is missing).
Run 1 is shown beside run 2 in the tables. The seven setups that do not use
commissions reproduce run 1's wins, sectors, fleet and hull exactly; only the
corrected spiral test moves the broader starvation count by one run in
Glasswright today and Eclipse slots. The two Glasswright commission setups change
because of the purchase fix.

Glasswright pluses are cumulative only in the Recommended row. G-A kiln repair,
G-B cullet, G-C one-jump commissions.

### Glasswrights (ithar)

| Setup | Win rate run 1 -> run 2 (95 percent run 2) | Paired win delta run 2 | Mean sectors | Reach S3 | Loss spiral run 1 -> run 2 | Starvation run 1 -> run 2 | Income per battle |
|---|---:|---:|---:|---:|---:|---:|---:|
| Today: credits | 43.8% -> 43.8% (37.6 to 50.1) | 0.0 | 2.31 | 53.8% | 5.0% (12/240) -> 5.0% (12/240) | 31.3% (75/240) -> 30.8% (74/240) | 108 +- 76, p10-p90 40-231 |
| +G-A kiln repair | 43.3% -> 43.3% (37.2 to 49.7) | -0.4 (-3.1 to +2.3) | 2.31 | 53.8% | 5.4% (13/240) -> 5.4% (13/240) | 30.0% (72/240) -> 30.0% (72/240) | 108 +- 77, p10-p90 40-231 |
| +G-B cullet | 49.2% -> 49.2% (42.9 to 55.5) | +5.4 (+0.4 to +10.5) | 2.35 | 56.7% | 5.0% (12/240) -> 5.0% (12/240) | 29.2% (70/240) -> 29.2% (70/240) | 110 +- 77, p10-p90 43-237 |
| +G-C commissions | 40.0% -> 37.1% (31.2 to 43.4) | -6.7 (-12.8 to -0.5) | 2.19 | 46.3% | 6.3% (15/240) -> 5.4% (13/240) | 38.3% (92/240) -> 35.4% (85/240) | 105 +- 76, p10-p90 40-219 |
| Recommended (A+B+C) | 45.4% -> 42.5% (36.4 to 48.8) | -1.3 (-7.3 to +4.8) | 2.23 | 49.6% | 5.0% (12/240) -> 5.0% (12/240) | 33.8% (81/240) -> 32.1% (77/240) | 107 +- 77, p10-p90 40-231 |

### Eclipse (deathless)

| Setup | Win rate run 1 -> run 2 (95 percent run 2) | Paired win delta run 2 | Mean sectors | Reach S3 | Loss spiral run 1 -> run 2 | Starvation run 1 -> run 2 | Income per battle |
|---|---:|---:|---:|---:|---:|---:|---:|
| Today: credits | 68.8% -> 68.8% (62.6 to 74.3) | 0.0 | 2.57 | 72.1% | 5.8% (14/240) -> 5.8% (14/240) | 20.8% (50/240) -> 20.8% (50/240) | 116 +- 82, p10-p90 43-251 |
| +E-A Archive slots | 66.7% -> 66.7% (60.5 to 72.3) | -2.1 (-7.2 to +3.0) | 2.53 | 70.4% | 5.4% (13/240) -> 5.4% (13/240) | 22.1% (53/240) -> 21.7% (52/240) | 116 +- 81, p10-p90 43-248 |
| +E-B core recovery | 79.2% -> 79.2% (73.6 to 83.8) | +10.4 (+6.1 to +14.8) | 2.66 | 79.6% | 2.9% (7/240) -> 2.9% (7/240) | 12.9% (31/240) -> 12.9% (31/240) | 119 +- 83, p10-p90 43-251 |
| Recommended (A+B) | 75.8% -> 75.8% (70.0 to 80.8) | +7.1 (+1.9 to +12.2) | 2.63 | 78.3% | 3.3% (8/240) -> 3.3% (8/240) | 14.2% (34/240) -> 14.2% (34/240) | 118 +- 82, p10-p90 43-251 |

Paired deltas are against the Today row on the same seeds. Income is the flat
per-win battle payment only, excluding node spoils, salvage, prize money and
event money, and excluding the new cullet, slot and core flows.

Per-sector paired differences for the recommended forms: Glasswright mean
sectors -0.08 (-0.16 to 0.00) and reaching sector 3 -4.0 points (-10.0 to +2.0);
Eclipse mean sectors +0.06 (0.00 to +0.13) and reaching sector 3 +6.0 points
(+2.0 to +11.0).

## Run 2 corrections

1. One commission at a time, enforced at the purchase point. Artoo on PR 1102:
   the shipyard loop checked `commBusy` once before walking the stock shelf and
   `mcGeBuyHull` had no queue check, so one visit could queue several hulls and
   commit more fleet points than the cap. The gate now lives in
   `sim/commission_policy.js` and is called inside `mcGeBuyHull`. This changed
   the two Glasswright commission setups: commissions 40.0 to 37.1 percent
   (96 to 89 wins), Recommended 45.4 to 42.5 percent (109 to 102 wins). The
   other seven setups reproduce run 1's wins, sectors, fleet, hull and spiral
   count; only the corrected starvation test moves one run in two of them.
2. The shared spiral test. Run 1 priced a full repair of the worst ship. Run 2
   uses `contrib/deepseek/chorus_biomass_1118/sim/spiral.js` for both factions:
   a 25 percent repair of the worst ship's maximum hull, capped at what is
   missing, at the shipped 1 credit per 2 hull price and the same multiplier, or
   the cheapest hull the faction can field. On the same runs, the corrected test
   changes no run-level spiral flag and moves the broader starvation flag by one
   run in two non-commission setups (Glasswright today 75 to 74, Eclipse slots 53
   to 52). The commission rows change more because the purchase fix also applied
   there (spiral 15 to 13, starvation 92 to 85 for commissions).
3. The regression test. `commission_test.js` runs the real `mcGeBuyHull` through
   the real loader and driver with the stated case: two affordable 4-point
   offers, fleet 2 of cap 6, 1,000 credits. Exactly one order is queued; the
   second offer is refused at the purchase point and no extra credits are spent.

## Fleet and total hull after each sector

State after the last battle the run fought in that sector, including a battle
the run lost. n is the number of runs that fought in that sector. These are run 2
values; the seven non-commission setups match run 1.

### Glasswrights

| Setup | Sector | n | Fleet | Hull | Hull percent |
|---|---:|---:|---:|---:|---:|
| Today | 1 | 240 | 1.95 | 144 / 167 | 65.7% |
| Today | 2 | 185 | 2.16 | 172 / 195 | 60.5% |
| Today | 3 | 129 | 3.63 | 291 / 313 | 74.2% |
| Kiln | 1 | 240 | 1.96 | 145 / 168 | 65.8% |
| Kiln | 2 | 185 | 2.14 | 172 / 194 | 60.6% |
| Kiln | 3 | 129 | 3.64 | 295 / 317 | 74.8% |
| Cullet | 1 | 240 | 2.02 | 150 / 173 | 67.1% |
| Cullet | 2 | 188 | 2.34 | 187 / 209 | 63.5% |
| Cullet | 3 | 136 | 3.76 | 305 / 329 | 80.2% |
| Commissions | 1 | 240 | 1.78 | 138 / 159 | 62.3% |
| Commissions | 2 | 174 | 1.78 | 160 / 177 | 57.3% |
| Commissions | 3 | 111 | 2.78 | 261 / 284 | 73.2% |
| Recommended | 1 | 240 | 1.81 | 141 / 161 | 63.4% |
| Recommended | 2 | 175 | 2.03 | 174 / 195 | 59.8% |
| Recommended | 3 | 119 | 3.26 | 296 / 321 | 79.0% |

### Eclipse

| Setup | Sector | n | Fleet | Hull | Hull percent |
|---|---:|---:|---:|---:|---:|
| Today | 1 | 240 | 2.60 | 271 / 311 | 72.5% |
| Today | 2 | 203 | 3.94 | 424 / 471 | 75.9% |
| Today | 3 | 173 | 5.89 | 666 / 712 | 89.6% |
| Slots | 1 | 240 | 2.48 | 250 / 292 | 69.9% |
| Slots | 2 | 199 | 3.99 | 415 / 467 | 75.5% |
| Slots | 3 | 169 | 6.00 | 663 / 712 | 88.5% |
| Core | 1 | 240 | 2.87 | 293 / 335 | 74.1% |
| Core | 2 | 207 | 4.87 | 502 / 554 | 83.1% |
| Core | 3 | 191 | 7.12 | 761 / 809 | 93.5% |
| Recommended | 1 | 240 | 2.71 | 267 / 311 | 71.8% |
| Recommended | 2 | 203 | 4.75 | 477 / 529 | 83.4% |
| Recommended | 3 | 188 | 6.82 | 711 / 762 | 90.0% |

The Eclipse recovery flows show up exactly where expected: core runs are about
0.3 ships and 1.6 hull percent ahead after sector 1, about 0.9 ships and 7 hull
percent ahead after sector 2, and about 1.2 ships and 4 hull percent ahead after
sector 3. Slot runs are close to today in hull but reach the later sectors less
often because the premium is paid whether or not the ship dies.

The Glasswright cullet runs are about 0.1 ships ahead after sector 1 and 0.2
after sector 2, and the runs that reach sector 3 are about 6 hull percent
healthier. With the one-order fix the commission runs are behind after sector 1
(1.78 ships against 1.95) and farther behind after sector 2 (1.78 against 2.16);
the survivors reach sector 3 with fewer ships (2.78 against 3.63). That is the
delay cost the design predicted, now measured without the queue loophole.

## Loss spiral and starvation

Definitions are the same as the issue 1085 Chorus sim, using its shared test. A
"loss" is a battle not won (a retreat or a defeat). A "setback" is a loss or a
win that cost ships. The spiral is two losses in a row where, at the second, the
credits cannot pay a 25 percent hull repair of the worst ship or the cheapest
hull the faction can field, and an empty fleet counts as no recovery. Starvation
is the same test on two setbacks in a row, because a defeat ends the run and
makes a literal two-loss streak rare.

| Setup | Spiral run 1 | Spiral run 2 | Starvation run 1 | Starvation run 2 | Two losses in a row |
|---|---:|---:|---:|---:|---:|
| Glasswright today | 5.0% (12/240) | 5.0% (12/240) | 31.3% (75/240) | 30.8% (74/240) | 5.4% (13/240) |
| Glasswright kiln | 5.4% (13/240) | 5.4% (13/240) | 30.0% (72/240) | 30.0% (72/240) | 6.3% (15/240) |
| Glasswright cullet | 5.0% (12/240) | 5.0% (12/240) | 29.2% (70/240) | 29.2% (70/240) | 5.8% (14/240) |
| Glasswright commissions | 6.3% (15/240) | 5.4% (13/240) | 38.3% (92/240) | 35.4% (85/240) | 7.5% (18/240) |
| Glasswright recommended | 5.0% (12/240) | 5.0% (12/240) | 33.8% (81/240) | 32.1% (77/240) | 6.3% (15/240) |
| Eclipse today | 5.8% (14/240) | 5.8% (14/240) | 20.8% (50/240) | 20.8% (50/240) | 6.7% (16/240) |
| Eclipse slots | 5.4% (13/240) | 5.4% (13/240) | 22.1% (53/240) | 21.7% (52/240) | 6.3% (15/240) |
| Eclipse core | 2.9% (7/240) | 2.9% (7/240) | 12.9% (31/240) | 12.9% (31/240) | 3.8% (9/240) |
| Eclipse recommended | 3.3% (8/240) | 3.3% (8/240) | 14.2% (34/240) | 14.2% (34/240) | 4.2% (10/240) |

No setup opens a spiral for either faction: every run 2 share sits between 2.9
and 5.8 percent. Eclipse core recovery halves it (5.8 to 2.9 percent) and the
combined Eclipse form takes it to 3.3. Glasswright cullet leaves it flat at 5.0
and the combined form is also 5.0; commissions take it to 5.4. Starvation is the
sharper signal: Eclipse core cuts it from 20.8 to 12.9 percent, while Glasswright
commissions raise it from 30.8 to 35.4 percent.

On the same runs, the corrected test changes the spiral price but not one
run-level spiral flag. In this table the commission row's spiral count moves 15
to 13 because of the purchase fix, not the spiral test. The narrower two-loss
streak is the same or slightly higher than run 1 in the commission rows, which
is the tempo cost of one order at a time.

## Where the differences come from

- Glasswright cullet paid 20,580 credits over 240 runs (about 86 per run) and
  fired in 219 of 240 runs. That is the whole of the Glasswright gain.
- Glasswright commissions started 638 times in 240 runs (about 2.7 per run) at
  one in flight, down from 955 in run 1 when one visit could queue several. The
  bot was about 0.2 ships behind after sector 1 and 0.4 behind after sector 2,
  and paid the same price up front; the cost is the tempo, not the credits.
- Kiln repair was used at every yard but changed almost nothing. Hull percent
  after sector 1 is 65.8 against 65.7 today. The free 15 percent floor is small
  beside the shipped drydock (60 percent of missing hull) and the post-win patch.
- Eclipse slots bought 541 slots (45 credits each) and restored 126 ships for
  10,230 credits of rebuilds over 240 runs. The copy plus body cost is close to
  break-even in win rate and improves the early fleet and hull a little.
- Eclipse cores earned 482 (about 2 per run) and restored 380 ships at 20
  percent of shop value. That is the strongest single flow in the whole job.
- The combined Eclipse form restored 127 slots and 315 cores but earned fewer
  cores than core alone (423 against 482) because the slot premium competes for
  the same credits.

## Assumptions

1. Each faction uses its four shipped admirals (ithar: aelith, vaelen, thorne,
   mirelle; deathless: nekhet, sekhmar, anuket, khepra), rotated by seed. Veteran
   AI. The battle pilot is the existing montecarlo bot from issue 1085, unchanged.
2. Today is the shipped game untouched: the shipped rewardFlow credit formula,
   the shipped shipyard (1 credit per 2 hull, shipped hull prices and Mk costs),
   the shipped drydock (free 60 percent of missing hull), field repairs (20
   percent), the post-win patch (15 percent), the reward repair (25 percent) and
   the shipped price ladder.
3. Glasswright kiln repair (G-A) applies only at a shipyard. Each ship's first
   15 percent of max hull of missing hull is free; the rest pays the shipped 1
   credit per 2 hull with the shipped multiplier. Repair stays all-or-nothing
   like the shipped repair-all button.
4. Cullet (G-B) is a credit refund, not a second stock, to follow the job's
   "capped refund" and the design's "no standing second currency". It is paid
   only on a win, only for the fleet's own lost Glasswright hulls, fixed by
   class: Frigate 15, Destroyer 30, Cruiser 45, Carrier 50, Battleship 60. It is
   capped at 60 credits per battle and never scales with kills.
5. Commissions (G-C) replace the shelf for yard purchases: the hull is paid up
   front at the shipped price and arrives one completed node later. At most one
   commission is in flight at a time (the design's bench limit), checked at the
   purchase point inside mcGeBuyHull so one visit cannot queue several orders. If
   the command points are full on arrival it waits until there is room. Prizes
   and tows are captured ships and still arrive immediately.
6. Archive slots (E-A) cost a flat 45 credits at a shipyard, which is the
   existing "Back up the fleet" dock-action price, and the fleet holds at most
   two. A slotted ship that dies queues a restore at the next shipyard for 40
   percent of its class shop value. The restored ship is a standard hull at Mk 1
   with no refits and full hull; the slot is consumed. The 40 percent rebuild is
   the physical body cost the design says is lost with the wreck.
7. Core recovery (E-B) earns one core and one un-slotted lost hull only on a
   win, at most one per battle (the most valuable lost hull). At the next
   shipyard a core plus 20 percent of the hull's shop value restores that hull at
   Mk 1 with no refits and full hull. A retreat or a loss recovers no core.
8. The in-battle Archive restore (reanimate) is untouched. So are the faction
   verbs (Glasswright attune, Eclipse waken), the drydock, field repairs, the
   post-win patch, the reward repair, Mk growth, prize and salvage values, and
   the price ladder.
9. Income is the flat per-win battle payment recorded at the rewardFlow wrapper,
   so a partial win is already halved. It excludes node spoils, salvage, prize
   money, event money, cullet, slot rebuilds and core rebuilds.
10. Timeouts resolve as in the harness: a non-boss timeout is a retreat, a boss
    timeout is a loss.
11. The loss spiral and starvation tests are the issue 1085 shared file
    `contrib/deepseek/chorus_biomass_1118/sim/spiral.js`, used for both factions.
    Run 1's full-repair pricing is kept as spiralFull and starveFull in the raw
    records and in results.csv so the two definitions can be compared.

## Limits

- One bot policy. Absolute win rates are bot-relative, so compare rows, not the
  44 or 69 percent to the game.
- 240 runs per setup give about +-5 points on a win rate and about +-4 points on
  the spiral shares.
- The Glasswright recommendation also names G-D quick anneals, and the Eclipse
  recommendation also names E-C dormant yards and E-D plate repair. The job's
  simplest-form list leaves them out, so they are not measured here. G-D is a
  tempo choice with a flaw, E-C is node and event plumbing, and E-D's flat pool
  would be a second repair currency. Each is a separate build.
- The slot price and the rebuild price are the main judgment calls. The report
  models the design's "the copy is cheap, the fitted body is the loss" reading.
  A cheaper rebuild, or restoring at a higher Mark, would move E-A's row up.
- The bot's slot policy is simple: at a yard it covers the flagship and then the
  most valuable uncovered ship, at most two, and keeps a 150-credit buffer. A
  human may cover different ships or skip the insurance when a quiet route is
  known.

## Method and files

- sim/loader_main.js is a verbatim copy of the issue 1085 loader. It loads
  data.js, core.js, battle.js, campaign_meta.js, campaign_run.js and campaign3d.js
  from the repo root read only.
- sim/bot.js is a verbatim copy of the issue 1085 battle pilot.
- The shared issue 1085 spiral test at
  contrib/deepseek/chorus_biomass_1118/sim/spiral.js is loaded from its own
  folder rather than copied, so both jobs use one definition.
- sim/commission_policy.js is the one-order-at-a-time purchase gate, shared by
  the driver and the regression test.
- sim/driver_ge.js is the campaign driver plus the in-memory Glasswright and
  Eclipse layer. It records battle income, the dead ships, the recovery queues,
  the per-battle spiral test and the per-sector state. Nothing is written to disk
  by the layer.
- sim/run_sim.js runs a seed block for one setup.
- sim/summarize.js builds results.csv and results_sectors.csv and prints the two
  tables.
- commission_test.js is the issue 1086 regression test for the commission queue.
- results.csv has one row per setup and includes the paired deltas, both spiral
  definitions and the cullet, slot and core counters. results_sectors.csv has the
  sector fleet and hull. results_run1.csv and results_sectors_run1.csv keep run
  1 for the side by side.

Reproduce (about 7 to 8 minutes per setup, the nine setups were run in parallel
on this PC; raw JSON was kept in the system temp folder, not in this folder):

```
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup ithar_today --n 240 --seed0 7000 --out raw/ithar_today.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup ithar_kiln --n 240 --seed0 7000 --out raw/ithar_kiln.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup ithar_cullet --n 240 --seed0 7000 --out raw/ithar_cullet.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup ithar_commission --n 240 --seed0 7000 --out raw/ithar_commission.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup ithar_rec --n 240 --seed0 7000 --out raw/ithar_rec.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup deathless_today --n 240 --seed0 7000 --out raw/deathless_today.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup deathless_slots --n 240 --seed0 7000 --out raw/deathless_slots.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup deathless_core --n 240 --seed0 7000 --out raw/deathless_core.json
node contrib/deepseek/ge_economy_1118/sim/run_sim.js --setup deathless_rec --n 240 --seed0 7000 --out raw/deathless_rec.json
node contrib/deepseek/ge_economy_1118/sim/summarize.js raw/ithar_today.json raw/ithar_kiln.json raw/ithar_cullet.json raw/ithar_commission.json raw/ithar_rec.json raw/deathless_today.json raw/deathless_slots.json raw/deathless_core.json raw/deathless_rec.json
node contrib/deepseek/ge_economy_1118/commission_test.js
```

## Checks

- Standing checks: `node contrib/opus/tools/run_all_checks.js` returned exit 0,
  70 PASS and 0 FAIL, with the same two KNOWN rows the pack is configured with.
  The two relevant rows:
  `oracle_copy_test | PASS | 0.43 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
  `commission_test | PASS | 0.08 | PASS: 7 commission checks`
- `node --check` on driver_ge.js, run_sim.js, summarize.js, commission_policy.js,
  commission_test.js and run_all_checks.js: PASS for each.
- Every setup ran 240 of 240 runs with 0 errors: the run_sim logs end with
  `240/240 runs ... errors 0` for all nine.
- Parity is skipped by me: no root game file, data table or Godot file changed,
  so the twin tables are untouched and parity should pass unchanged. The runner
  still runs it and its real row belongs under this report.

## The five reach items

- Callers: no game function, constant or save field was added or changed. All new
  code is under contrib/deepseek/ge_economy_1118. The layer wraps rewardFlow,
  completeNode, endRun and the shipyard handler in memory; the shipped functions
  still run underneath. The commission gate is called only by mcGeBuyHull.
- Saves: the sim never writes a player save to disk. It calls the shipped saveRun
  in memory only, and no run save shape changed, so an older save still loads and
  behaves the same.
- Twins: not triggered. battle.js, data.js, core.js, campaign_run.js and the
  Godot port are untouched, so no table re-export and no parity change. The
  oracle copy test still PASSes.
- UI: not triggered. No screen reads any new value; the sim has no UI.
- CI: one new standing test file, contrib/deepseek/ge_economy_1118/commission_test.js,
  added to contrib/opus/tools/run_all_checks.js. GitHub's normal branch rows
  (standing checks, no em dashes, Godot rules parity, Godot game checks) now run
  that test plus the rest of the pack.
