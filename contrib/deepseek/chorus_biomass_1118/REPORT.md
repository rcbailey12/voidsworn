# Issue 1085 report: Chorus biomass flat per win

## Answer in one line

Pay biomass flat per win plus the small capped kill bonus (2 per kill, cap 12):
it does not open a loss spiral (2.9 percent against 4.2 percent for today's
credits) and its run win rate is within noise of today (67.9 against 72.1
percent). Flat biomass alone also stays out of the spiral (3.8 percent), but it
costs about 6 points of win rate.

## What changed

All new files, no game file touched:

- contrib/deepseek/chorus_biomass_1118/README.md (tables, assumptions, limits)
- contrib/deepseek/chorus_biomass_1118/results.csv (one row per setup)
- contrib/deepseek/chorus_biomass_1118/results_sectors.csv (fleet and hull per sector)
- contrib/deepseek/chorus_biomass_1118/sim/loader_main.js (verbatim muse loader copy)
- contrib/deepseek/chorus_biomass_1118/sim/bot.js (verbatim muse battle pilot copy)
- contrib/deepseek/chorus_biomass_1118/sim/driver_biomass.js (driver plus in memory biomass layer)
- contrib/deepseek/chorus_biomass_1118/sim/run_sim.js (seed block runner)
- contrib/deepseek/chorus_biomass_1118/sim/summarize.js (CSV builder)

The shipped game files are loaded read only. The only economy change is in
memory for the sim. 240 paired Chorus runs per setup, seeds 7000 to 7239, all
four Chorus admirals, existing campaign bot, Veteran AI.

## Checks

- `node contrib/opus/tools/run_all_checks.js`: exit 0, 67 PASS, 0 FAIL, two
  KNOWN rows as configured. Relevant PASS line:
  `oracle_copy_test | PASS | 0.32 | PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`
- `node --check` on all five sim scripts: OK for each.
- Standing checks are the only check I ran. Parity is skipped by me because no
  root game file, data table or Godot file changed; the runner still runs it and
  it should pass unchanged.

## The five reach items

- Callers: no game function, constant or save field was added or changed. All
  new code is under contrib/deepseek/chorus_biomass_1118/sim and is only loaded
  by the sim runner.
- Saves: the sim never writes a player save to disk. It calls the shipped
  saveRun in memory only. No run save shape changed, so an older save still
  loads the same way.
- Twins: not triggered. battle.js, data.js, core.js, campaign_run.js and the
  Godot port are untouched, so no table re-export and no parity change.
- UI: not triggered. No screen reads any new value.
- CI: no new standing test file. The sim is an evidence script under
  contrib/deepseek, not a test row. GitHub's normal branch rows (standing
  checks, no em dashes, rules parity, Godot game checks) see only new text
  files under contrib/deepseek/chorus_biomass_1118.

## Method summary

- Baseline: today's shipped credits rewardFlow and shipped shipyard.
- Biomass: the same flat per win formula with the same modifiers, paid as
  biomass, halved on a partial win. The 120 starting credits move to biomass so
  starting buying power matches. Biomass buys hull repair, new hulls and Mk
  growth at the shipped credit prices. Credits still buy refits and pay events,
  prizes, spoils, salvage and ransoms.
- Biomass plus kill bonus: 2 biomass per enemy ship destroyed, capped at 12 per
  battle.
- Income spread is recorded per battle from the wrapper, so partial wins are
  already halved and the kill bonus already capped.
- Loss spiral: two losses in a row (a loss is a battle not won) where at the
  second the hull money cannot pay a 25 percent repair of the worst ship or the
  cheapest hull. Starvation is the same test on two setbacks (a loss or a win
  that cost ships), because a defeat ends the run and makes the literal
  two-loss streak rare.

## Skipped

- No screenshots. This job is sims only and changes nothing a player sees.
- No Godot import or parity run from me, for the reason above.
- No change to the price list, feeding grounds node, credit digestion or the
  starlight trickle. The brief asked for the flat flow test, so those are listed
  as assumptions and limits in the README.
