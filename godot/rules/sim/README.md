# Godot balance simulator

Run from the repo root with the Godot 4 console executable.

```text
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- campaign 10
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- campaignrewards 10
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- fmatrix 6
godot --headless --path godot --script res://rules/sim/balance_sim.gd -- run 2
```

On Windows, double-click `tools\pc\balance_sim.bat` for the default campaign or run
`tools\pc\balance_sim.bat fmatrix 6 nopause` from a terminal. It uses `GODOT_EXE`, the PC bundle's
`godot_path.txt`, or `godot.exe` on PATH, in that order.

In battle modes the number is battles per faction in each cell. The two campaign battle modes report one row per player faction in
each sector and encounter cell, with rounds, hull left, ships lost, and simulated presentation time. The rewards mode
also reports what it carried from earlier stops. The player ability line shows uses per battle and total uses by
ability id, including automatic replacement launches. An omitted ability fired zero times in that row. Faction
matrix prints the `FM` and `FID` JSON lines for existing report consumers. The default activation
schedule is alternating. In the battle modes, pass `--classic` after the count to exercise the classic bot.
`FM.exchange` records the total credited hull damage dealt by each side, including wings, for each ordered matchup.
Divide `dealt` by `taken` for the player-side damage exchange ratio.

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

## Full campaigns

`run N` plays N campaigns per faction and difficulty. It starts each run on a fresh profile, rotates the faction's
admirals in table order, and uses the Muse baseline for routes, battle tactics, rewards, repairs and spending. The
Sector 3 yard preference, market picks and Eclipse core restoration follow the late-run harness. Routes, battles,
rewards and purchases use the Godot campaign's actions.

The Godot campaign uses the encounter already assigned to each boss node and presents the Sector 3 story choice.
The story choice uses the event scorer. The bot declines the optional Chorus core offer.

- The default grid covers all six factions on Standard and Veteran, with seeds 1 through N in each cell.
  `PFACTION` and `AI` narrow the grid. `PAIRSEED` sets the seed offset and takes precedence over `SEED`.
  For example, `PAIRSEED=120` with `run 120` plays seeds 121 through 240. Admiral rotation stays aligned to seed 1
  when the work is split. `SIM_ARM` labels each record.
- Each `RUN` JSON line gives the faction, difficulty, admiral, seed, arm, terminal reason, sector reached, battles
  and bosses fought, retreats, battle timeouts, shop buys by kind and player abilities fired by id. The two boss
  currency fields are captured on entry to the Sector 3 boss and are null if it was never reached.
- A retreat lowers a node's priority. The bot concedes if it would enter the same node after three retreats.
  A non-boss battle timeout resolves as a retreat. A boss timeout ends the run with reason `timeout`. The
  summary divides wins by all planned runs in each cell and counts campaign losses by sector, with separate
  columns for concessions, terminal timeouts and engine errors.
- Save each arm through `RUNS_COMPLETE <count>`. The same `compare_trials.js` command checks full-run logs
  for the planned count, completion marker and matching faction, difficulty, admiral and seed keys. Its
  `PAIRED_RUN` rows summarize deltas by faction and difficulty.
