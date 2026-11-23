# Godot balance simulator

Run from the repo root with the Godot 4 console executable.

```text
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- campaign 10
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- campaignrewards 10
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- fmatrix 6
```

On Windows, double-click `tools\pc\balance_sim.bat` for the default campaign or run
`tools\pc\balance_sim.bat fmatrix 6 nopause` from a terminal. It uses `GODOT_EXE`, the PC bundle's
`godot_path.txt`, or `godot.exe` on PATH, in that order.

The number is battles per faction in each cell. The two campaign modes report one row per player faction in each
sector and encounter cell, with rounds, hull left, ships lost, and simulated presentation time. The rewards mode
also reports what it carried from earlier stops. The player ability line shows uses per battle and total uses by
ability id, including automatic replacement launches. An omitted ability fired zero times in that row. Faction
matrix prints the `FM` and `FID` JSON lines for existing report consumers. The default activation
schedule is alternating. Pass `--classic` after the count on the Godot command to exercise the classic bot.

- Each campaign battle prints a `TRIAL` JSON line before its cell summary. The record carries the player faction,
  difficulty, cell (mode, sector, encounter kind, and column), seed, arm, and player `abilities_fired` by id.
  The `terminal_reason` field records `completed_win`, `completed_loss`, `bot_concession`, `timeout`, or `engine_error`.
  The current bot plays to a rules outcome or the round cap. `bot_concession` is reserved for an explicit bot exit.
  An engine error during a trial prints the row and stops the run with a failure exit.
- Set `PAIRSEED` to an integer, and reuse the same filters and sample count in both arms. The simulator starts
  each trial at that seed plus its one-based index, before fleet or reward draws. Each player faction starts the
  same sequence. `SEED` sets the initial stream when running without pairing. The row records the actual unsigned
  32-bit RNG state at trial entry in either case.
- Set `SIM_ARM` to label the run. It defaults to `single`. For a paired comparison, give the control and treatment
  distinct labels and save each successful run's output as a UTF-8 log. Run
  `node godot/rules/sim/compare_trials.js <control-log> <treatment-log>` from the repo root. It checks that every
  faction, difficulty, cell, and seed occurs exactly once in each log. Each log needs one `TRIALS_COMPLETE <count>`
  footer after the last trial, with the planned count (factions times cells times battles per cell). Missing or
  extra trials, mismatched keys, duplicates, and engine-error trials fail the comparison. Each `PAIRED` row gives
  the number of pairs and the mean treatment-minus-control change in wins, timeouts, concessions, and hull left
  (percentage points), rounds, ships lost, and uses by ability id.
- Set `PFACTION` to `voidsworn`, `corsair`, `ithar`, `deathless`, `chorus`, or `hegemony` to report just that
  player faction in `campaign` or `campaignrewards`. The sim uses the campaign's faction hull equivalents for
  the fixed sector fleets and keeps the reference admiral, Vex, unless `SIM_BUILD` sets an admiral.
- `CSEC=1,3` selects campaign sectors. `ONLY_BOSS=1` selects the sector 1 and 3 boss cells and the sector 1
  elite comparison in either campaign mode. `FROWS=voidsworn,corsair`, `CPT=8`, and
  `NOADM=1` select matrix rows, fleet command points, and the reference no-admiral setup.
- `AI=standard`, `CAP=0`, `BOTCMD=0`, and `BOTBRACE=0` select the rules or bot options from the prior sim.
  `PACE_OLD=1` changes the timing estimate. `CATS=1` prints a timing breakdown in plain campaign mode.
- Set `SIM_BUILD` to an absolute JSON file path for a build comparison. Apply the same fixture in both arms with
  the item under test changed. For example, use an empty object in the control arm and `{"relics":["lattice"]}`
  in the other. The fields are `relics`, `refits` (each goes on the first compatible ship), `admiral`, and the
  run's `lineage` and `mastery` fields. The simulator applies the fixture after synthetic reward carry, before battle.
  Set `SIM_BUILD` in both arms so both have a designated flagship. Use `CAP=0` to hold enemy fleet power scaling fixed.

Wait times are estimates from the legacy report model. Use the individual `TRIAL` rows to identify the seeds where a
player ability fired. The Godot rules and campaign tables supply the battle and reward effects.
