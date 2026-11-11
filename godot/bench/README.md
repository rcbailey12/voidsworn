# godot/bench: the scene gate and the look bench

Two standing benches on Ryan's PC (RTX 5080). Both need the PC-built hulls (`godot/gen`, `godot/assets/ships`), which a fresh
clone lacks.

| Bench | What it answers | Run |
|---|---|---|
| `scene_gate.tscn` (issue 207, R111, R116) | What a full battle costs a frame: the 20-ship storm battle with the HUD, measured, plus isolation modes. `--still` makes fixed-clock stills of the whole scene. | `tools/pc/jobs/bench207_scene_gate.bat` |
| `look_bench.tscn` (issue 351, R157, R160) | What the game looks like at the cameras the player uses: every weapon, shield state and death, and all 36 hulls, the same way every time, before and after a change. | `tools/pc/jobs/look_bench.bat` (double-click) |

## The look bench

### Run it

Copy `tools/pc/jobs/look_bench.bat` to `Downloads\voidsworn_test\` and double-click it. With no words it benches the newest
`main` and compares it with the accepted baseline (`docs/shots/look_bench/BASELINE.txt`). Other forms:

```
look_bench.bat origin/opus/issue-365          the branch, against the baseline
look_bench.bat origin/opus/issue-365 origin/main      the branch against main
look_bench.bat origin/main none               one commit, no comparison
look_bench.bat origin/main <commit> go        the same, but first wait for Downloads\voidsworn_test\look_bench\go.txt
```

It keeps its own two clones in `Downloads\voidsworn_test\look_bench\` (`tool\`, the bench script itself, and `repo\`, the commit
under test), copies the PC-built hulls in (copy only, from `LB_SHIPS`), imports, waits until the graphics card is idle (up to 60
minutes, one GPU job at a time), runs the bench, and makes the sheets with ComfyUI's portable Python (it has Pillow; the PC has no
other Python). The bench script always comes from the tool clone, so commits made before the bench existed can be benched. Each
commit is benched once into `runs\<commit>\` and reused. Sheets land in `sheets\<before>_vs_<after>\` and the folder opens.
Nothing on the PC is deleted.

The scene by hand (on the PC):

```
godot --path godot --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 ^
      res://bench/look_bench.tscn -- --out DIR [--part all|moments|fleet] [--only id1,id2] [--commit SHA]
python tools/pc/jobs/look_bench_sheets.py --after DIR [--before DIR2] --out SHEETS [--tol 2.0]
```

### What it draws

- **Moments** (`look_moments.json`, one row per moment; add a moment by adding a row): each of the 20 faction weapons on a hull
  and on a shield; shield hit, low and break; six deaths (frigate, destroyer, cruiser, capital, Chorus rupture, burn-out hulk);
  the macro battery on four weights of the same faction (frigate, destroyer, cruiser, capital: one weapon on every weight, from
  retired issue 233); the eight looks PR 327 changed (las muzzle, prism muzzle, missile launch, torpedo on a shield, lance burn,
  Chorus bile hit, gauss exit, crit). Each at the three real cameras (`render/camera_rig.gd`: 170 the battle camera, 60 the
  middle, 26 the closest the game allows) as 30 frames a second strips, 12 to 16 frames each. Two ships 68 units apart (about
  four hexes), the camera at the game's own angle, centred on the target (on the attacker for muzzles and launches).
- **Cells:** 384x216. Camera 170 is a 1 to 1 pixel crop of the 1920x1080 frame (true pixel size). Camera 60 is the middle
  768x432 shrunk to half, camera 26 the middle 1152x648 shrunk to a third.
- **Fleet:** all 36 hulls of `render/hull_table.gd` `AI_HULLS` at camera 170, 1 to 1 pixels (400x240 cells), over the sky of
  every region of `world/world_sky.gd` (frontier, nebula, world, boneyard, deep) and a storm map (ion storm hexes on and around
  the ship). The sheet maker measures the sky behind the ships and names the darkest and the brightest (`skies.txt`): the
  regions' own numbers do not say which is darker on screen. The 30 faction ships are set up exactly as the battle does
  (faction and class); the three craft and three objects (S1_51, S2_23, B23_51, O1_37, O2_37, O3_11) are drawn from their hull
  files at a stated length (craft 2.56, station 46, transport 17.6, beacon 8), since the battle draws craft procedurally and the
  station through the board.
- No hex grid and no HUD: world, ships and effects only (the audit probe's pattern). The whole battle scene is
  `scene_gate.tscn -- --still`.

### How it repeats

- The effect clock is manual: one 1/60 s step per drawn frame. `fx.rng` is seeded 11 and the global RNG 2070 before every moment.
  Every worker job (hull damage rebuilds, death cuts) is waited for before each step (`scene_gate.gd` `_settle`).
- `--fixed-fps 60` makes the engine clock move 1/60 s per drawn frame too: shader `TIME`, physics, timers and the world's own
  clocks. So the wreck physics, which the game runs on real time (R118), is frame-locked here and deaths repeat.
- Each part starts on a frame grid (a multiple of 900 drawn frames) after its world is built twice (the second build reuses the
  baked sky in one frame), so bake time on the PC does not shift the shader clock.
- `render/ship_view.gd` runs its idle bob and station-keeping jets on the wall clock (`Time.get_ticks_msec`, lines 1277 and 1282):
  the bench turns ShipView processing off, so ships hold still and those jets are not drawn. Shake is off; hit pause and death
  slow motion stay on.
- Measured (`docs/shots/look_bench/README.md`): two runs after the first on a checkout match to the pixel on all 2,484 stills,
  deaths and the storm included; the first run after an import is off by up to 1.63 levels on a few stills. The tolerance is
  2.0 levels per still (the sheet maker's default). No still is exempt.
- A warm pass plays every moment once at camera 170 before the kept ones and keeps nothing, so no pipeline is still compiling.

### Stops

- `placeholder hull`: before drawing, every hull code must have a built file (the same lookup as `ship_view.gd`), and every ship
  set up must have more than a box's worth of corners. Otherwise the bench writes `PLACEHOLDER.txt`, prints
  `LOOK_BENCH placeholder hull`, exits 3, and the .bat stops with "placeholder hull". `--allow-blocks` exists only for a cloud
  smoke run of the script (no hulls in the cloud, no pictures drawn).
- The late-shader counter of issue 376 does not exist yet; the bench prints the pipelines compiled in its run instead.
