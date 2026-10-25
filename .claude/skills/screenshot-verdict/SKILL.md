---
name: screenshot-verdict
description: Use whenever a change affects anything the player sees in Voidsworn (ships, effects, UI, board, lighting, backdrops). Captures fixed-angle shots on Ryan's PC, compares them with the previous accepted shots, and reports exactly what differs before any visual work is called done.
---

# Screenshot verdict

Acceptance is Ryan's eye plus automatic checks (FINDINGS R6). No visual change is done until a retained screenshot shows it, and Ryan sees the picture, not a description.

## Where shots are taken
- **On Ryan's PC, never in the cloud.** The cloud has no GPU and closeshot times out loading the game.
- `closeshot.py` (software rendering, swiftshader): one hull alone on the board, fixed camera. Env: `OUT`, `TAG`, `TPLS` (hull ids), `ONLY=desk`, `ZOOM` (0.9 surface detail, 1.6 whole ship), `MAP`, `CA`/`CB` (camera), `EVAL` (JS run before the shot, may return a Promise), `EVALWAIT`, `DMG` (damage state), `PRE`. Its server needs `request_queue_size 256` or desktop shots silently lose the kit.
- `fxshot.py` and `corsairfx.py`: real GPU, for effects. `boardshot.py`: the battle board. `errprobe.py`: console errors (smoke does not catch invisible hulls).
- Build first: `python build.py test` writes `index_test.html`.

## Procedure
1. Decide the fixed shot set before changing anything: same hulls, same zooms, same camera, same damage states, same clock. Take "before" shots if none are retained.
2. Make the change; rebuild; take the same shots ("after").
3. Compare side by side in one contact sheet (PIL), labelled before and after. Look region by region; for ships use the 9-cell blob sweep (ship-kit skill).
4. List exactly what differs and anything new that looks wrong (black squares or NaN blocks, missing kit, vanished hulls, naval tells, backward guns, clipped highlights). Check damage states and a battle view, not only studio shots.
5. Retain the sheet in `docs/ship_pipeline/...` (or the relevant docs folder) and commit it with the change.
6. Show Ryan the sheet with a one-line verdict and your pick. Do not ask him to judge what an automatic check could catch.

## Known traps
- Effects that are fine in software rendering can draw black squares on the real GPU (NaN from pow with a negative base or a zero-length normalize, spread by bloom): guard shaders with `pow(max(b, 0.0), e)`, a safe normalize, and clamped outputs.
- Material copies (damage clones) must keep every plugin flag, and compile before swap, or hulls vanish (FINDINGS B-16).
- Blind comparisons (engine test): keep pictures from Ryan until both sides are ready, and label them A and B.
