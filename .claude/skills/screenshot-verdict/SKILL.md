---
name: screenshot-verdict
description: Use whenever a change affects anything the player sees in Embers of the Hollow Sun (ships, weapon and hit effects, shields, deaths, sky, board). Run the look bench (tools/pc/jobs/look_bench.bat) on Ryan's PC for the change and for main, compare with the baseline, and report exactly what differs before any visual work is called done.
---

# Screenshot verdict: run the look bench, compare with the baseline, report what differs

The product is the Godot game in `godot/`. Acceptance is Ryan's eye plus automatic checks (FINDINGS R6). No visual change is done until a
bench sheet shows it and Ryan has seen the picture, not a description. The bench (issue 351) is the standing capture set every looks
job is judged on, so rounds are compared on the same moments at the same cameras (R157).

## The bench in one line

Double-click `tools/pc/jobs/look_bench.bat` (copy it to `Downloads\voidsworn_test\` first, it runs from anywhere): it benches
the newest main and compares it with the accepted baseline (`docs/shots/look_bench/BASELINE.txt`). For a branch:
`look_bench.bat origin/<branch>` (after) and optionally a second commit (before). Details: `godot/bench/README.md`.

What it draws, on a fixed seed and a frame-locked clock:
- the moments sheet: every row of `godot/bench/look_moments.json` (each weapon on a hull and on a shield, shield hit, low and
  break, every death class, one weapon on every weight, the eight PR 327 looks) at the three real cameras: 170 (the battle
  camera, 1 to 1 pixels), 60 and 26 (the closest the game allows), as 30 frames a second strips;
- the fleet sheet: all 36 hulls at the battle camera at true pixel size over the darkest sky, the brightest sky and a storm map;
- before and after: every still side by side with one difference number (mean absolute difference, 0 to 255 levels).

## Procedure

1. Battle camera first (R157, R160 rule 4): judge at camera 170 at true pixel size before any close-up. 60 and 26 are for detail.
   Never judge on a view closer than 26 (the effects gallery's free camera is a build check only).
2. If the change needs a new moment, add a row to `godot/bench/look_moments.json` in the same pull request (no new capture script).
3. Run the bench on the change and compare with main (or the baseline). PC job: the bench waits for the graphics card to be idle and
   for the Board's go file on days the GPU is not already given (`look_bench.bat AFTER BEFORE go`).
4. Read `summary.txt`: every still over the tolerance is listed by moment and camera. A change must differ where it is meant to and
   nowhere else. A difference in a moment the change does not touch is a defect (or a new exempt still: say which and why).
5. Look at the sheets yourself: the overview pages first (one key frame per moment at the three cameras), then the strips of every
   moment that differs. List what differs and anything that looks wrong (blocks instead of ships, black squares, pale squares,
   puffs in empty space, vanished dark hulls, burnt-out pale hulls, naval tells, backward guns).
6. Put the before and after sheets for the moments that changed in the pull request (docs/shots/<job>/, JPG at sensible sizes) and
   lead with camera 170. Commit a new baseline (sheets in docs/shots/look_bench/ and the commit in BASELINE.txt) only when the
   Board accepts the change.
7. Show Ryan the sheet: two lines and one image, with your pick.

## Tolerance and exempt stills

The tolerance and the stills that cannot repeat are measured, not guessed: see `docs/shots/look_bench/README.md` (two runs of the
same commit). Wreck physics is frame-locked in the bench (`--fixed-fps 60`, one effect step per drawn frame), so deaths repeat there
even though the game runs them on real time (R118).

## Stops and traps

- `placeholder hull`: the bench stops if any ship would be drawn as a block (a checkout without `godot/gen`). Copy the PC-built
  hulls in (`LB_SHIPS`, LOOP.md Known traps) and run again. Never show or judge a sheet with blocks (issue 281 run 6).
- The bench draws no hex grid and no HUD. For the whole battle scene use `godot/bench/scene_gate.tscn -- --still`.
- `render/ship_view.gd` runs its idle bob and station-keeping jets on the wall clock; the bench parks ShipView processing so ships hold
  still. A change to those two looks cannot be judged on the bench until they move to the effect clock.
- Effects that are fine in one renderer can draw black squares on the real GPU (NaN from pow with a negative base or a zero-length
  normalize, spread by bloom): guard shaders with `pow(max(b, 0.0), e)`, a safe normalize and clamped outputs.
- The frozen browser build's tools (closeshot.py, fxshot.py, boardshot.py) are history; the browser game is the rules oracle only.
