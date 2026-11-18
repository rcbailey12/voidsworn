# Issue 1086 report: Glasswright and Eclipse economy simplest forms

## Answer in one line

Glasswright: build cullet (G-B) first, the only piece that helps (+5.4 win
points, loss spiral flat); kiln repair is cost-neutral and one-jump commissions
cost about 4 points, so the full simplest form nets +1.7. Eclipse: build core
recovery (E-B) first (+10.4 win points, spiral halved); Archive slots at a
45-credit copy plus a 40 percent rebuild are close to neutral alone and shave
about 3 points off the combined form, which still gains +7.1 and is significant.

## What changed

All new files, no game file touched:

- contrib/deepseek/ge_economy_1118/README.md (two tables, assumptions, limits)
- contrib/deepseek/ge_economy_1118/results.csv (one row per setup)
- contrib/deepseek/ge_economy_1118/results_sectors.csv (fleet and hull per sector)
- contrib/deepseek/ge_economy_1118/sim/loader_main.js (verbatim copy from issue 1085)
- contrib/deepseek/ge_economy_1118/sim/bot.js (verbatim copy from issue 1085)
- contrib/deepseek/ge_economy_1118/sim/driver_ge.js (driver plus in memory GE layer)
- contrib/deepseek/ge_economy_1118/sim/run_sim.js (seed block runner)
- contrib/deepseek/ge_economy_1118/sim/summarize.js (CSV and table builder)

The shipped files are loaded read only. The only economy changes are in memory
in driver_ge.js. Nine setups, 240 paired runs each, seeds 7000 to 7239, four
admirals per faction, existing campaign bot, Veteran AI.

## Checks

- `node contrib/opus/tools/run_all_checks.js`: exit 0, 67 PASS, 0 FAIL, two
  KNOWN rows as configured. Relevant line:
  `oracle_copy_test | PASS | 0.33 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
- `node --check` on loader_main.js, bot.js, driver_ge.js, run_sim.js and
  summarize.js: PASS for each.
- Every setup ran 240 of 240 runs with 0 errors: the run_sim logs end with
  `240/240 runs ... errors 0` for all nine.
- Parity is skipped by me: no root game file, data table or Godot file changed,
  so the twin tables are untouched and parity should pass unchanged. The runner
  still runs it and its real rows belong under this report.

## The five reach items

- Callers: no game function, constant or save field was added or changed. All new
  code is under contrib/deepseek/ge_economy_1118/sim. The layer wraps rewardFlow,
  completeNode, endRun and the shipyard handler in memory; the shipped code still
  runs underneath.
- Saves: the sim never writes a player save to disk. It calls the shipped saveRun
  in memory only, and no run save shape changed, so an older save still loads and
  behaves the same.
- Twins: not triggered. battle.js, data.js, core.js, campaign_run.js and the
  Godot port are untouched, so no table re-export and no parity change. The oracle
  copy test still PASSes.
- UI: not triggered. No screen reads any new value; the sim has no UI.
- CI: no new standing test file. The sim is an evidence script under
  contrib/deepseek, not a test row, so contrib/opus/tools/run_all_checks.js did not
  need a new entry. GitHub's normal branch rows (standing checks, no em dashes,
  Godot rules parity, Godot game checks) see only new text files under
  contrib/deepseek/ge_economy_1118.

## Skipped

- No screenshots. This job is sims only and changes nothing a player sees.
- No parity run from me, for the reason above.
- No G-D quick anneals, G-E stored light, E-C dormant yards, E-D plate pool or
  E-E drones. The job's simplest-form list names G-A, G-B, G-C, E-A and E-B, so
  those are the measured pieces. Each of the others is a separate build.
