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

## Pictures pending a graphics lane

The in-game capture script stages these four cards from seeded campaign actions. Lane C is code-only. The pictures and
their provenance sidecars need a graphics lane with GPU clearance.

| Picture code | What it shows |
| --- | --- |
| `V1177_victory` | Victory and the wreck choices on the same card |
| `P1177_promotions` | Perk picks for several captains on one card |
| `D1177_drydock` | The drydock's two hull and credit offers |
| `F1177_field_repairs` | The field stop's two hull and credit offers |

Run from the checkout on the graphics lane. The script writes PNGs up to 1280 by 720 and stamps each with its code and
source revision. The runner collects them from the issue's `shots` folder.

```bat
call tools\pc\tmo.bat 180 "C:\Users\rcbai\Downloads\voidsworn_test\godot\Godot_v4.7.2-stable_win64_console.exe" --path godot --rendering-method gl_compatibility --resolution 1920x1080 --script res://campaign/test/post_win_shots.gd -- "C:\Users\rcbai\Downloads\voidsworn_test\board_c\issue-1177\shots"
```
