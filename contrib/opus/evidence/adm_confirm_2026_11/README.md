# Admiral balance confirmation (R93, PR #149)

Crusade only, 200 runs per admiral, seed 1, veteran AI, baseline bot, browser rules build. Same seeds before and after, so the before/after pairs are like for like. Bot rates, not player win rates.

## Result

| Admiral | Before (main 5f4ccb8) | After (main with #149) | Change |
|---|---|---|---|
| Ashgrove (+1 Warden) | 45.5% (38.7 to 52.4) | 56.5% (49.6 to 63.2) | +11 points, back in band |
| Thale (hull +15% to +10%) | 88.0% (82.8 to 91.8) | 88.0% (82.8 to 91.8) | none: 176 wins out of 200 both times |

Crusade faction after #149 (`crusade_all.md`, 50 per admiral): 69.0% (62.3 to 75.0). Vex 80, Draven 50, Ashgrove 54, Thale 92.

Ashgrove is fixed. Thale's hull trim did nothing measurable; he is still clearly above his faction (his lower bound 82.8 is above the faction's upper bound 75.0).

## Thale experiments (scratch copies, not shipped)

All on top of #149, same 200 seeds.

| Test | Change | Thale win | Clear of band? |
|---|---|---|---|
| e1 | no passive at all | 81.0% (75.0 to 85.8) | touching |
| e2 | battleship only, no Warden | 83.0% (77.2 to 87.6) | yes, still high |
| e3 | opens with Vigil cruiser and two Wardens instead of the battleship (passive kept) | 76.0% (69.6 to 81.4) | no, in band |
| e4 | shared iron Command 40% to 25% (moves Maren and Brin too) | 85.5% (80.0 to 89.7) | yes, still high |
| e5 | battleship only and no passive | 75.5% (69.1 to 80.9) | no, in band |

Reading: the starting battleship is the driver. The passive and the Command each matter only a few points. Only e3 and e5 bring him into band.

Files: `*_before.md` are the old-data runs, `thale_exp_e*.md` the experiments.
