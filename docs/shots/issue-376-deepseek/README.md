# Issue 376: late shader log, PC trace result

Branch: work/issue-376-deepseek, based on main 99f8d06.

## What was run

The scene gate, on the PC's RTX 5080 (Vulkan, Forward+), from a scratch checkout of this branch with the PC-built
hulls and ship files linked in (the same ships the game draws):

```
Godot_v4.7.2-stable_win64_console.exe --path <checkout>/godot --rendering-method forward_plus --windowed \
  --resolution 1920x1080 res://bench/scene_gate.tscn -- \
  --out <run>/base --modes base --sessions 1 --frames 12000 --warmup 120 --trace
```

A first trace of `--modes base,deaths --sessions 1 --frames 1800 --trace` was also run. Its late list was empty
for both modes and it had 0 frames over 16.7 ms, but 1800 frames at the free-run frame rate gave only 29 volleys,
too few to reach every weapon look, so the longer 12000 frame base trace above is the one with full coverage.

## Result

Late shaders after the warm-up ended: 0 in every mode and session (base 1800, deaths 1800, base 12000).

No entry was added to the warm-up: the list is empty, so there is nothing to add and no rerun is needed.

## First use of every weapon look

The base trace has 232 volleys and covers all 20 weapon looks of `godot/bench/scene_gate.gd` LOOKS, shield and hull
variants included (39 distinct look strings). The slowest first-use frames were:

| weapon look | frame | row ms |
| --- | --- | --- |
| corsair:torp:torp | 1301 | 12.300 |
| ithar:lance:pulsar | 7025 | 12.177 |
| hegemony:lance:ion | 5981 | 10.360 |
| ithar:torp:startorp | 9301 | 8.833 |
| chorus:bio:bioplasma | 1254 | 8.792 |

Every first use is under 16.7 ms. The trace has 5 frames over 16.7 ms in total (rows 1681, 5913, 7249, 9791,
11077; 16.91 to 21.09 ms). None of them is a weapon's first use, none has a pipeline compile (`pipes` is empty),
and the GPU time on those rows is 2.34 to 2.58 ms.

## Look bench

`look_bench.tscn --part moments --only w_hbattery_void_hull` printed
`late shaders after warm-up (issue 376): 0`. The process then hit a known shutdown leak in this scratch checkout
(`5 shaders ... were never freed`, then RID leaks) after it printed `LOOK_BENCH_DONE`; the count line is before
that and the bench wrote its stills.

## Files

- `trace_base_s1.json`: the 12000 frame trace (one row per measured frame).
- `scene_gate.json`: the mode row, including `late_shaders` and `late_shader_names`.
- `scene_gate_run.log`: the console output of that run.
- `look_bench_run.log`: the console output of the look bench run.
