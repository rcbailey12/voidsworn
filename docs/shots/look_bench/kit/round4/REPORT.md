# Round 4: Doom's violet sheath (issue 849, R277)

Refs #849. Round 3's three twisting green-white filaments now sit inside a
wider violet-black sheath. Its edge swells, pinches and erodes using the
existing animated noise and flow mask. Green light is confined to the hot
filaments and tendrils; the surrounding haze uses the existing violet hue.

## Files and pictures

- `godot/fx/fx_shaders.gd`: only `ECLIPSE_ARC` changed, six added lines and
  three removed. The filament, fork, pulse, fade and vertex expressions are
  unchanged. `fx_weapons.gd` and `fx.gd` are byte-identical to the control,
  preserving embers, target light, heat shimmer and cooling scorch.
- This folder: [rounds 2, 3 and 4](doom.png),
  [source-pixel before/after](doom_before_after.png),
  [flow sequence](doom_sequence.png), [target contact](doom_contact.png),
  [cooling to scorch](doom_cooling.png), [motion](doom_motion.gif) and
  [phone motion](doom_phone_motion.gif). All sheets and films are at most
  1280 by 720. The phone view is the full frame reduced to 390 by 219.
- `make_sheets.py` reproduces the comparison sheets and complete pixel sweep.
  [Measurements](measurements.json), source hashes and per-view pixel data
  are included beside the pictures.

## Capture method and regression

Both versions have 54 cases at cameras 170 and 60: 108 kept views per version,
zero warnings and normal process exits. Every row rendered a warm take before
its kept take. A separate target-centred Doom take includes the lasting scorch.
The first candidate preview was inspected before the full after run.

All 49 non-Doom cases were compared across their complete strips,
phone views and native camera-60 details where provided. Their largest colour
channel difference is 1/255; peak RMS is 0.000148/255.
The four shield-stopped Doom rows change with the same arc shader.
No other effect source, palette, rule, save or UI file changed.

The complete 54 comparison sheets and raw evidence are in
`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-849/shots`.
The round-2 reference comes from the recorded issue-815 control. The round-3
control was captured fresh here; the recorded round-3 effects source and the
capture driver hashes match. All 252 local ship files match the tracked manifest.

## Cost and checks

Unchanged #207 scene gate, RTX 5080, Forward+, 120 warm-up frames and 360
measured frames, three kept sessions per mode after a separate warm run.
Values are medians of the session medians, in ms.

| Measurement | Fresh round 3 | Round 4 | Change |
|---|---:|---:|---:|
| 1080 frame | 3.473 | 3.414 | -0.059 |
| 1080 GPU | 2.442 | 2.463 | +0.021 |
| 4K GPU | 5.606 | 5.611 | +0.005 |

The allowance was recorded before measurement: round 3's published 3.522 ms
frame median plus 0.800 ms, or 4.322 ms total. Round 4 passes. Both GPU deltas
also pass the declared 0.300 ms margin, and the binding scene measurements
remain below 12.5 ms. This comparison does not establish a speed improvement.
No draw, particle, geometry or texture sample count increased.

- Standing checks: 56 PASS, 2 KNOWN, zero FAIL or SKIP, exit 0.
  The known rows are findings_tests and oracle_drift_guard.
- load all: 196 scripts, 11 scenes, 0 failed.
- Existing round-3 recipe guard: 112 cases, zero failures, exit 0.
- Full `godot/fx/test/check_destruction.bat`: exit 0, including geometry,
  plane, staging, smoke, flash area, recipes, spawn guard, blockers and GPU
  box/fleet probes.
- Final source, coverage, dimensions, regression data and cost verification:
  exit 0. The existing `exterior_alpha` late-shader notice occurs in the
  controls too; it is not a new Doom shader error.

The full batch logs two existing missing-`spawn_frame` diagnostics at
`godot/fx/test/death_spawn_check.gd:132`. Both also occur with the original
round-3 shader: exit 0, 33/33 pictures recorded, zero stray and zero check
failures. [Control evidence](spawn_guard_diagnostics.json) records this.
That unrelated test was left unchanged to keep the requested Doom-only scope.

One setup take ran before the copied ship textures were imported. It was
stopped, retained separately, and excluded from the control. Existing PC
import caches were then checked against every source hash before use.
Scratch logs remain in TEMP. Commits and pushes were skipped as instructed.
Visual acceptance remains with Ryan and the Board.
