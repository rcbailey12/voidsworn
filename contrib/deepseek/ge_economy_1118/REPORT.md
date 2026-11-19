# Issue 1086 run 2 report: Glasswright and Eclipse economy simplest forms

## Answer in one line

Glasswright: build cullet (G-B) first, still the only piece that helps (+5.4 win
points, loss spiral flat); kiln repair is cost-neutral and one-jump commissions
now cost about 6.7 points after the one-order fix, so the full simplest form nets
-1.3. The pick does not change, but the full form is now a small loss. Eclipse:
build core recovery (E-B) first (+10.4 win points, spiral halved); Archive slots
at a 45-credit copy plus a 40 percent rebuild are close to neutral alone and
shave about 3 points off the combined form, which still gains +7.1 and is
significant. The Eclipse pick does not change.

## What changed in run 2

Two corrections, then all nine setups rerun on the same paired seeds 7000 to
7239:

- Commission queue (Artoo on PR 1102): one pending order is now enforced at the
  purchase point in mcGeBuyHull, through sim/commission_policy.js. One shipyard
  visit can no longer queue several hulls. This changed the two Glasswright
  commission setups: commissions 40.0 to 37.1 percent, Recommended 45.4 to 42.5
  percent. The other seven setups reproduce run 1's wins, sectors, fleet and hull
  exactly.
- Loss spiral: the driver now uses the shared issue 1085 test
  (contrib/deepseek/chorus_biomass_1118/sim/spiral.js), a 25 percent repair of
  the worst ship capped at what is missing, for both factions. On the same runs
  no run-level spiral flag changed; starvation moved by one run in two
  non-commission setups. The commission rows also changed from the purchase fix.
- New regression test: commission_test.js runs the real mcGeBuyHull through the
  real loader and driver with two affordable 4-point offers, fleet 2 of cap 6,
  1,000 credits. Exactly one order is queued.
- Added commission_test.js to contrib/opus/tools/run_all_checks.js.
- results_run1.csv and results_sectors_run1.csv keep run 1 for the side by side.

The fresh checkout did not contain run 1, so I restored only
contrib/deepseek/ge_economy_1118 from origin/work/issue-1086-deepseek (commit
a39a5881) before editing. I did not run git merge; the base is the runner's
origin/main merge as committed.

## Files

All under contrib/deepseek/ge_economy_1118, no game file touched:

- README.md (run 1 beside run 2, assumptions, limits, checks)
- REPORT.md (this file)
- results.csv, results_sectors.csv (run 2)
- results_run1.csv, results_sectors_run1.csv (run 1)
- sim/loader_main.js, sim/bot.js (verbatim copies from issue 1085)
- the shared spiral test from contrib/deepseek/chorus_biomass_1118/sim/spiral.js
  is loaded from its own folder, not copied
- sim/commission_policy.js (the one-order gate)
- sim/driver_ge.js (driver plus in-memory GE layer, corrected spiral)
- sim/run_sim.js (seed block runner)
- sim/summarize.js (CSV and table builder, both spiral definitions)
- commission_test.js (the regression test)
- contrib/opus/tools/run_all_checks.js (one new row)

## Checks

- `node contrib/opus/tools/run_all_checks.js`: exit 0, 70 PASS, 0 FAIL, two
  KNOWN rows as configured. Relevant rows:
  `oracle_copy_test | PASS | 0.43 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
  `commission_test | PASS | 0.08 | PASS: 7 commission checks`
- `node --check` on driver_ge.js, run_sim.js, summarize.js, commission_policy.js,
  commission_test.js and run_all_checks.js: PASS for each.
- Every setup ran 240 of 240 runs with 0 errors: the run_sim logs end with
  `240/240 runs ... errors 0` for all nine.
- The commission test alone: `PASS: 7 commission checks`.
- Parity is skipped by me: no root game file, data table or Godot file changed,
  so the twin tables are untouched and parity should pass unchanged. The runner
  still runs it and its real row belongs under this report.

## The five reach items

- Callers: no game function, constant or save field was added or changed. All new
  code is under contrib/deepseek/ge_economy_1118. The layer wraps rewardFlow,
  completeNode, endRun and the shipyard handler in memory; the shipped code still
  runs underneath. mcCommissionCanOrder is called only by mcGeBuyHull.
- Saves: the sim never writes a player save to disk. It calls the shipped saveRun
  in memory only, and no run save shape changed, so an older save still loads and
  behaves the same.
- Twins: not triggered. battle.js, data.js, core.js, campaign_run.js and the
  Godot port are untouched, so no table re-export and no parity change. The
  oracle copy test still PASSes.
- UI: not triggered. No screen reads any new value; the sim has no UI.
- CI: the new commission_test.js is added to contrib/opus/tools/run_all_checks.js,
  so GitHub runs it with the standing checks, no em dashes, Godot rules parity and
  Godot game checks.

## Skipped

- No screenshots. This job is sims only and changes nothing a player sees.
- No parity run from me, for the reason above.
- No G-D quick anneals, G-E stored light, E-C dormant yards, E-D plate pool or
  E-E drones. The job's simplest-form list names G-A, G-B, G-C, E-A and E-B, so
  those are the measured pieces. Each of the others is a separate build.
