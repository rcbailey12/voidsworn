# Issue 726 run 4: all five Hullbreakers painted and installed

A16 to A20 passed stages 4 to 7 and are installed in the playable PC game, dark and weathered with the current R252/R274
stack. Source: `0e9c791d+normal726-run4`, including accepted PRs 866, 884 and 898. Nothing is committed or pushed.

Changed files: shared `paint_stack.py`, stage 5's batch guard/render calls, `RECIPE.md`, `HB_PAINT_726.bat` and its two
helpers, reproducible diagnostics and notes in this folder, the labelled picture gallery, and the generated five-ship
[install manifest](../../../godot/assets/ships/manifest.json).

Method: the existing [build sheets](../../../tools/blender/build_sheets/ships/) and Hullbreaker stack are unchanged.
Large trophy normal inputs use per-material Raw 16-bit patchwork heights, then one combined GPU normal bake. Links,
targets and settings restore on success or failure. Other factions always retain their original bake path. Stage 5 uses
4096-pixel maps at 64 samples; stage 7 retains its standard 2048-pixel export maps.

| Ship | Raw bake, seconds | hb682out, seconds | Normal including heights, seconds |
| --- | ---: | ---: | ---: |
| A16 | 313.6 | 244.8 | 126.0 |
| A17 | 329.2 | 631.5 | 129.1 |
| A18 | 273.1 | 214.6 | 97.2 |
| A19 | 288.2 | 220.5 | 102.0 |
| A20 | 249.6 | 230.6 | 90.2 |

These are observed historical costs; accepted geometry changes prevent a controlled speed comparison.

Checks passed:

- All five surface checks, three render passes each, LOD/export checks, export fault tests, authored interiors, death seams,
  GPU readback, playable installation and readback. No SVM or shader compile error in any accepted bake log.
- Five normal diagnostic cases plus injected-failure restoration; nine stage 5 guard cases, including negative crash exit.
  All 25 intermediate PNGs read back as 4096 by 4096, single-channel, 16-bit files.
- E11's real mesh/UVs and 4096-pixel masks: its deterministic 512-pixel CPU normal at one sample exactly matches the
  unchanged warm repeat's SHA-256. The larger unopted graph diagnostic also matches exactly. All 286 unrelated installed
  ship files retain their hashes; only the five target manifest entries changed.
- A16 fixture record still matches. The stored R274/current comparison retains its shape, palette and weathering.
  A20's same-camera OSL/height beauty comparison differs by 0.846 of one 8-bit colour step RMS.
- Scene gate ran twice, three sessions per mode; kept run 2. 1080p frame medians: 7.071, 8.103, 8.089 ms; 4K GPU medians:
  5.475, 5.530, 5.470 ms. Their medians, 8.089 and 5.475 ms, pass the 12.5 ms law.
- `node contrib/opus/tools/run_all_checks.js`: 58 PASS, 2 KNOWN baseline rows (`findings_tests`, `oracle_drift_guard`),
  0 FAIL, 0 SKIP. Python/PowerShell syntax and `git diff --check` pass.

R252's extra trophy seam grew the controlled capital normal graph from 550 to 729 nodes. R274 and PR 898 leave it at
729; R289 changes modelled plates. Actual A20 reaches 916 input nodes with decals. [NOTES.md](NOTES.md) explains the proof.

Rejected/replaced routes: CPU OSL passed its cold 4096-pixel, one-sample probe in 41.4 seconds, then crashed on retry in
Windows LLVM. Route B was retained. Sheet paint omits the old fixed-four-piece break preview, which crashes on these
authored seam layouts; all paint views and actual authored-interior/death-seam checks run. The helper supplies a missing
check-only dependency and backs up/refreshes the old camera capture harness. Gameplay scripts are unchanged.

[All five labelled beauty/concept and actual camera-170 pictures, logs and checks](<C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run4/README.md>),
[final audit](<C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run4/final_audit.json>),
[repository picture gallery](../../../docs/shots/look_bench/hullbreaker_paint_726/README.md).

Refs #726
