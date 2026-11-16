# Issue 221: the scene gate binder, profiled and trimmed

**The answer.** The gate scene's frame median at 1080p fell from **4.87 ms to 3.29 ms** (gate 12.5 ms, R116), with no
visible change. The per-ship cost left (base minus ships hidden) fell from **3.1 ms to 1.6 ms**. Three trims did it: the
name plates no longer reset their colour, relayout and fade every frame, and the strike craft ribbons age in a shader.

Both runs: Ryan's PC, RTX 5080, driver 617.42, Godot 4.7.2, 1920x1080, Forward+, MSAA 4x, vsync off, the gate view
camera, 120 warm-up and 720 measured frames, 3 sessions per mode in reversed order, GPU idle (P8, 0%) before each run
(`gpu_before.txt`, `gpu_after.txt`). Note: main today already runs the base scene at 4.9 ms, not the 6.9 ms of the Nov 7
run, from work merged since.

## Before and after (median of 3 sessions)

| Mode | Frame median before | after | change | Frame p99 before | after | GPU ms before | after |
|---|---:|---:|---:|---:|---:|---:|---:|
| base (gate scene) | 4.87 | 3.29 | -1.58 | 9.99 | 7.40 | 2.29 | 2.24 |
| ships_off (20 ships hidden) | 1.75 | 1.68 | -0.07 | 3.23 | 2.89 | 1.32 | 1.32 |
| fleet_x2 (script-free copy of every hull) | 4.81 | 3.55 | -1.25 | 9.38 | 7.63 | 3.04 | 2.99 |

Sessions (frame median, ms): before base 4.20, 5.30, 4.87; after base 2.62, 3.29, 3.80. Data: `before.json`,
`after.json` (scene_gate.json of each run).

Per-ship cost left: base minus ships hidden is 1.6 ms after (3.1 ms before), about 0.08 ms per ship with full logic. The
script-free copy of every hull adds about 0.3 ms over base, so most of what remains is the engine drawing and culling the
hulls, not our scripts.

## The profile (before, main)

Godot's script profiler over the 720 measured frames of the base mode (`scene_gate.gd --profile`, Godot run with `-d`).
Table: `profile_before.txt` (its total also counts worker-thread jobs: hull breach and death cuts, about 32 s, which are
not frame work, and the bench's own frame waits in `_mode`). Main-thread per-frame scripts, ms per frame with the profiler
on (it slows scripts, so read the order, not the size):

| Script and function | ms per frame | Calls per frame |
|---|---:|---:|
| scenes/battle/battle.gd `_process` (plates, floats) | 0.70 | 1 |
| of which ui/battle/hud.gd `set_plate` | 0.37 | 24 |
| of which ui/battle/hud.gd `declutter_plates` | 0.12 | 1 |
| fx/fx.gd `step` | 0.62 | 1 |
| of which fx/fx_ship.gd `update` | 0.42 | 24 |
| render/squadron_wing.gd `step` | 0.45 | 4 |
| of which render/squadron_wing.gd `_draw_trail` | 0.40 | 16 |
| render/ship_view.gd `_process` | 0.13 | 24 |
| fx/fx.gd `_update_lights` | 0.06 | 1 |

## What changed

- `godot/ui/battle/hud.gd` `set_plate`: the plate's name colour override is set only when the colour changes (an override
  sends THEME_CHANGED, which reshapes the label every frame for every ship); the text is set and the plate resized only
  when the words change or the plate no longer fits them.
- `godot/ui/battle/hud.gd` `declutter_plates`: each plate's fade is decided first and written once, instead of 1 then 0
  every frame for every hidden plate.
- `godot/render/squadron_wing.gd`: the strike craft ribbons drift, widen and fade in their vertex shader from each
  sample's birth time and the wing's clock (the same maths as before), so the ribbon mesh is rebuilt only when a sample
  is added or dropped (about 30 times a second) instead of every frame.
- `godot/bench/scene_gate.gd`: the `--profile` hook (run 1).

Not trimmed: `fx_ship.update` (0.42 ms, spread thin over turrets, hit reaction, trails and drive glow; no single cost
worth the risk) and `ship_view._process` (the idle bob moves each hull, which the engine must propagate).

## No visible change

`gate221_before_after.png`: `scene_gate --still` at step 300, main against this branch, the gate view and the close view.
Pixel difference main against this branch: wide 0.40 to 0.56 mean, close 2.3 to 2.5 mean. Main against a second run of
main: wide 0.24 to 0.50, close 2.2 to 2.9. So the change is inside the run-to-run noise (the idle bob, station-keeping
jets and strike craft run on the real clock, so no two stills match exactly).
