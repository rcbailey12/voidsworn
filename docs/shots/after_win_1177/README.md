# Issue 1177 post-win cards

The Godot check plays the first battle to a seeded stub win and takes the first eligible reward choice until the next map
choice. It counts each card once, including a single promotions card across all perk picks. Both measurements use seeds
1 through 30, Vex and the Sunward Crusade.

| Cards | Main `cd8c2515` | Issue 1177 |
| --- | ---: | ---: |
| Victory | 30 | 30 |
| Wreck salvage on its own card | 30 | 0 |
| Captain promotions | 60 | 28 |
| Prizes | 19 | 19 |
| Protocols and refits | 24 | 24 |
| Total | 163 | 101 |

The repair choices use 60% or 30% of missing hull at a drydock, with 35 credits on the smaller repair. Field repairs
use 20% or 10% of maximum hull, with 15 credits on the smaller patch. The existing repair modifiers apply to both choices.
The larger service keeps the previous rate at each stop, so the more capable drydock still matters to a damaged fleet.

## Review pictures

The in-game capture script stages these four cards from seeded campaign actions. Run it on a graphics lane with GPU
clearance to collect the pictures and their provenance sidecars.

| Picture code | What it shows |
| --- | --- |
| `V1177_victory` | Victory, the confirmed Nemesis weakness and the wreck choices on the same card |
| `P1177_promotions` | Perk picks for several captains on one card |
| `D1177_drydock` | The drydock's two hull and credit offers |
| `F1177_field_repairs` | The field stop's two hull and credit offers |

Run from the checkout on the graphics lane. The script writes PNGs no taller than 720 px and stamps each with its code
and source revision. The runner collects them from the issue's `shots` folder.

```bat
call tools\pc\tmo.bat 180 "C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --path godot --rendering-method gl_compatibility --resolution 1920x1080 --script res://campaign/test/post_win_shots.gd -- "C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-1177\shots"
```

## Economy after merging main (Opus, Nov 20 2026)

Main at e15439f9 (with PR 1202's RAMP and FACTION_AI) merged into the branch; campaign_tables.json regenerated from the
combined tree. Paired seeds 1 to 40 per faction, all six factions (240 runs per side), AI Standard, Muse's unmodified Monte
Carlo driver plus the repair-stop pick in `contrib/opus/tools/issue1177/econ_1177.js` (full service when its extra hull is
worth more than the credits at the paid repair price, or when the fleet or flagship is below half hull).

| Measure | Main | Branch |
| --- | ---: | ---: |
| Run win rate | 80.42% (193/240) | 82.08% (197/240) |
| Average credits on entering Sector 3 | 591.79 (198 arrivals) | 594.58 (200 arrivals) |
| Drydock | 133 automatic repairs | 24 full service, 114 repairs and credits |
| Field repairs | 103 automatic repairs | 11 full service, 90 repairs and credits |
| Battle timeouts / driver errors | 5 / 0 | 4 / 0 |

Win rate moves +1.67 points (paired: 6 runs flip to a win, 2 to a loss), inside the two-point limit, so the stipends stay
at 35 and 15 credits. Campaign parity: PASS on 30 seeds after the merge.
