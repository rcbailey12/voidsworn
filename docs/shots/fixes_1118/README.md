# Issue 1045 battle camera checks

## F6 firing fan

[Before and after at camera 170](F6_fan_c170.png). The marked hex is seven
steps from the H9_23 cruiser. Its centre is 105.36 world units from the ship,
inside the old 108.92-unit range-six outline and outside the new 104.42-unit
outline. Both panels use the same battle and the same outline renderer. The
left panel feeds it the original radius and the right uses the game's current
fan path. The mark points to the same hex centre in both panels.

The headless fan check tests the drawn outline and fill against rules distance
and arc for all four displayed arcs and six facings. Ranges 1 to 6 have zero
mismatches across 10,560 centre checks per range. At range 7, 156 arc and facing
checks include a range-eight centre. Each such centre is 120.00 or 121.24 world
units away. The test prints the coordinates and counts them without failing.

Reproduce with [the capture script](capture_fan.gd) through `tools/pc/tmo.bat`.
Use the `godot` project, Forward+, a 1920x1080 window, fixed 60 fps and one
output directory after `--`. The script warms both panels before it saves one
sheet with the provenance band below the frames.

## H9_23 shield

The fitted default and egg option are shown on the same cruiser at camera 170,
at impact and 0.1, 0.3 and 0.6 seconds into the same torpedo hit.
Use `bench/look_bench.tscn` through `tools/pc/tmo.bat` at 1920x1080 with
`--fixed-fps 60 --disable-vsync` and the
[R303 moments](../look_bench/shields_r303/moments.json). Select
`--part moments --only hegemony_shield`. Run once with `VS_SHIELD_SHAPE`
unset for the fitted default and once with it set to `egg`. The
[compositor](compose_shield.py) takes the fitted and egg c170 strips and an
output path.

The fitted path caches the generated surface arrays by hull code and geometry
for the running game. Each ship still creates its own mesh and hit collider
from those arrays.

### Scene 207 at 1080p

Forward+ on the RTX 5080. Each shape ran the scene's base mode under a solo
GPU claim, with 120 warm-up frames followed by 720 measured frames in each
of three sessions. These are the repeated-run results.

| Shield | Session frame medians (ms) | Median of the three (ms) |
|---|---|---|
| Fitted default | 11.468, 13.041, 11.923 | 11.923 |
| Egg option | 10.056, 14.986, 6.387 | 10.056 |

Both three-session medians are under the 12.5 ms gate. Session 2 exceeded it
for each shape. The first full scene build took 52.9 seconds with fitted and
27.4 seconds with egg. Those times include the entire scene load and warm-up.
