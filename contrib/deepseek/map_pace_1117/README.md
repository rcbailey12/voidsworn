# Map pace numbers for the map size study (issue 1019)

Measurement only. Nothing in the game or the rules changed. This folder runs headless
battles with the browser rules from `battle.js` and `data.js` and changes only the board
size and the ship move speed inside its own setup. It gives the Board numbers for the
map size idea in issue 1004 and the options priced in PR 1008.

## The answer in one table

200 sims per setup, paired seeds 1000 to 1199, mirror Hegemony fleets of 6 ships,
sector 2, strip arena held fixed.

| Setup | Board | Speed | Sims | First contact median (mean), activations [sims with contact] | Battle rounds mean (median) | Capital activations, mean | No shot fired, share | Win rate (95% CI) | Timeouts |
|---|---|---|---|---|---|---|---|---|---|
| Today standard strip 30x22 speed +0 | 30 by 22 | +0 | 200 | 1.0 (2.6) [200/200] | 10.3 (10.0) | 72.2 | 17.1% | 29.5% (23.6% to 36.2%) | 0 |
| Today station defend 30x22 speed +0 (7-hex station, main) | 30 by 22 | +0 | 200 | 1.0 (1.4) [200/200] | 5.9 (6.0) | 47.6 | 17.8% | 17.0% (12.4% to 22.8%) | 0 |
| Today station defend 30x22 speed +0 (19-hex station, R314) | 30 by 22 | +0 | 200 | 4.0 (4.5) [200/200] | 6.5 (7.0) | 52.1 | 26.1% | 37.5% (31.1% to 44.4%) | 0 |
| 38x26 speed +0 | 38 by 26 | +0 | 200 | 13.0 (13.9) [200/200] | 12.1 (12.0) | 85.7 | 28.4% | 34.5% (28.3% to 41.3%) | 0 |
| 38x26 speed +1 | 38 by 26 | +1 | 200 | 12.0 (12.3) [200/200] | 10.3 (10.0) | 75.2 | 22.7% | 29.5% (23.6% to 36.2%) | 0 |
| 38x26 speed +2 | 38 by 26 | +2 | 200 | 12.0 (12.2) [200/200] | 9.6 (9.0) | 70.8 | 21.0% | 19.5% (14.6% to 25.5%) | 0 |

Change against today standard (same seeds, summary minus baseline). A positive first
contact change means contact comes later, which is slower.

| Setup | First contact median change | First contact mean change | Battle rounds change | No shot share change | Win rate change |
|---|---|---|---|---|---|
| Today station defend 30x22 speed +0 (7-hex station, main) | 0.0 | -1.2 | -4.3 | 0.7 pts | -12.5 pts |
| Today station defend 30x22 speed +0 (19-hex station, R314) | 3.0 | 2.0 | -3.8 | 8.9 pts | 8.0 pts |
| 38x26 speed +0 | 12.0 | 11.3 | 1.9 | 11.3 pts | 5.0 pts |
| 38x26 speed +1 | 11.0 | 9.8 | 0.1 | 5.6 pts | 0.0 pts |
| 38x26 speed +2 | 11.0 | 9.6 | -0.6 | 3.9 pts | -10.0 pts |

## What the numbers say

- The 38 by 26 board adds about 12 capital activations before the first shot. At 6
  against 6 a full round is 12 activations, so that is close to one whole round of
  pure approach on every battle. The median goes from 1 to 13.
- Speed does not buy the approach back. On the big board, +1 and +2 speed cut the
  first contact median only from 13 to 12, while battle rounds fall from 12.1 to 10.3
  and 9.6. No-shot turns stay above today: 28.4% at +0, 22.7% at +1, 21.0% at +2,
  against 17.1% today. The extra distance is structural; speed shortens the fight
  after contact, not the approach itself.
- The big board raises mean capital activations per battle from 72.2 to 85.7 at +0,
  75.2 at +1 and 70.8 at +2. The +2 speed roughly returns today's number of turns, but
  it pays for that with a full extra round of no-contact at the start and a lower win
  rate in this bot pairing. No big-board setup gets contact anywhere near today's.
- The defend map on the 19-hex station is slower to first contact than main's 7-hex
  station (median 4 vs 1) and lasts about half a round longer (6.5 vs 5.9 rounds).
  The defender wins more often in this pairing (37.5% vs 17.0%). This is the ruled
  R314 station; see the note below.
- This agrees with PR 1008's own 72-battle table: it measured the same 38 by 26 edge
  board at first contact 12 to 12.5, mean rounds 11.6 / 10.4 / 9.8 and move-only share
  24.2% / 20.4% / 19.2% for +0 / +1 / +2. Our 200-sim runs land on the same direction
  and nearly the same values. PR 1008's recommendation was to keep the 30 by 22 canvas
  and spend the change on shape; these numbers support that.

## Definitions

- A "turn" here is one capital-ship activation, not one battle round and not one
  squadron. A 6 against 6 round has up to 12 capital activations.
- First contact is the number of completed capital activations before the first
  activation in which a weapon fired. A flak interception is not a shot because the
  rules do not spend the gun, and a launch or other ability is not a shot. If no shot
  fires in a battle, that battle is left out of the first contact median and the
  count in square brackets shows how many battles had contact.
- Battle rounds is `B.round` at the end. The defend clock ends at round 6.
- No shot fired is the share of capital activations in which no weapon fired. It
  covers movement, bracing, boarding and abilities.
- Win rate is the player-side bot's `win` result with a 95% Wilson interval. The two
  bots are not equal pilots, so this is a direction check, not a balance verdict.

## Setups and sources

- Today standard: 30 by 22 canvas, belt map, open shape, strip arena, rout, today's
  hull speeds.
- Today defend: 30 by 22 canvas, station map, open shape, strip arena, defend. Main
  at this run still paints the old 7-hex station, so the 7-hex row is what main does
  today. R314 rules the 19-hex station, so the 19-hex row loads `battle.js` from
  `work/issue-983-deepseek` at commit b0c490b2 for that setup only. The 19-hex row is
  the map the brief names; the 7-hex row is kept so the Board can see the gap until
  983 merges.
- Proposed sizes and speeds: PR 1008 priced a 38 by 26 canvas (609 hexes against
  today's 361) with edge deployment at today's speed, +1 speed and +2 speed. Those are
  the three big-board rows. The +1 and +2 rows raise every hull's `sp` by 1 or 2,
  including squadrons, in the loaded copy only.
- Not measured here: PR 1008's shape options (hourglass, corridor, lanes,
  archipelago) change board shape rather than radius or speed, and its Alternative 2
  (38 by 26 with the fleets deployed inward) changes deployment. The brief limits this
  script's overrides to board radius and ship speed, so both are left to PR 1008's own
  numbers. PR 1008 measured Alternative 2 at first contact 0, 9.8 rounds and move-only
  5.3%, the best pace in its study, and says it needs a human playtest.

## Method

- Harness: `sim3d.js`, the game's own bot against the enemy AI, alternating
  activations (`B.alt`), which is the game's default. The script takes the harness's
  headless game loader and supplies its own private copy of `data.js`, `core.js` and
  `battle.js` in a VM context, so no game file is edited and the two setups do not
  share state.
- Board size: the `const BW=30, BH=22;` line in the private copy is replaced in
  memory only.
- Speed: every hull's `sp` in the private `HULLS` table is raised after load and
  before the fleet is built.
- Fleet: mirror Hegemony list, Vanguard, 2 Interdictors, 2 Pickets and a Dominion,
  6 against 6, sector 2. Seeds 1000 to 1199 are the same for every setup, so the
  comparison is paired.
- RNG: `startBattle` reseeds from the seed, so every run repeats. A rerun of
  today_standard on seeds 1000 to 1002 reproduced the stored rows exactly.
- Arena is held at strip for every setup. That is the arena PR 1008 used for its size
  table, and holding it fixed isolates the size and speed effect. Today's rout only
  rolls strip 30% of the time (square 35%, round 35%), and PR 1008 measured the square
  approach as the slowest, so these strip numbers are the best case for contact today.
- Limits: bots, not humans; one mirror fleet; one sector; strip arena only for size;
  the big board is measured with edge deployment, the option PR 1008 rejected. Human
  play would raise the no-shot share everywhere, but the paired comparisons should
  hold in direction.

## Files

- `sim_map_pace.js`: the sim. It reads the game files, overrides size and speed in
  memory, runs the battles, and writes the raw JSON per setup, `raw.csv` and
  `summary.md`.
- `raw.csv`: 1200 rows, one per battle, 200 per setup.
- `raw_<setup>.json`: the per-setup rows the merge step reads.
- `summary.md`: the generated tables above.
- `README.md`: this file.

CSV columns: `setup, label, board_w, board_h, speed_delta, encounter, map, arena, seed,
first_contact_activations, battle_rounds, capital_activations, no_shot_activations,
no_shot_share, win, timeout, result`.

## Re-running

```sh
# one-off: make the R314 19-hex source reachable if it is not in local history
git fetch origin work/issue-983-deepseek

# all six setups, 200 sims each (about 35 to 40 minutes on this PC), writes raw.csv and summary.md
node contrib/deepseek/map_pace_1117/sim_map_pace.js --sims 200

# rebuild the tables and CSV from the stored per-setup JSON
node contrib/deepseek/map_pace_1117/sim_map_pace.js --merge

# quick smoke run of one setup, to the temp folder
node contrib/deepseek/map_pace_1117/sim_map_pace.js --only today_standard --sims 5 --out "$TEMP/pace_check.csv"

# prove the smoke run left the saved dataset alone (also a standing check)
node contrib/deepseek/map_pace_1117/smoke_safety_test.js
```

The per-setup `raw_<setup>.json` files and `summary.md` go in the folder of the
`--out` path, and `--merge` reads them from that same folder. With no `--out` that
folder is this one, which is where the six saved files live. A smoke run pointed at
the temp folder therefore writes its own raw file there and cannot replace the saved
200-sim rows. Dedicated check: `smoke_safety_test.js` runs the smoke command above
and compares the six saved files byte for byte before and after.

If the 19-hex commit cannot be read, the defend 19-hex setup stops with the fetch
command in the error. Run the other setups with `--setups` if that source is not
wanted.
