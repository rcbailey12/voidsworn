# Movement build report (issue 505)

Opus 5.5 worker, Nov 11 2026. Branch opus/issue-505, based on main 1b0d003 (main's movement files are unchanged up to
96099ce7, the commit the "before" captures ran on). LOOK only: no change to godot/rules/, the browser oracle, the AI or
`_best_facing`. The new spec is contrib/opus/briefs/movement_spec.md.

## What Ryan will see

1. **Forces drive the lights.** The main drive burns hard to get a ship moving, drops to a low hot glow while it coasts,
   and stays low while it brakes. Bow retro jets fire forward to stop it. A back-off is pushed by the retro jets and
   caught by the aft jets, with the main drive dark. Turning jets fire one pair to start a turn and the opposite pair to
   stop it.
2. **The heading is flown on its own.** A turn before a run is flown first and the ship sets off as the nose comes
   round. The final facing begins while the ship brakes and finishes after it stops, at the ship's own turn rate
   (a dreadnought at about 49 degrees a second instead of a 90 degree a second late swing).
3. **Sidesteps and back-offs are slides.** The nose holds exactly; side jets (matched bow and stern pair) or retro and aft
   jets do the work. On main a one-hex back-off spun the hull a full circle (815 degrees a second on a frigate) and a
   sidestep swung the nose about 90 degrees.
4. **No roll into turns.** The 4 degree bank is gone; ShipView no longer writes the hull's roll at all.
5. **Weight.** Size now runs past battleship at half the slope (dreadnought about 1.25, titans and arks up to 1.4). A
   dreadnought takes about 2.0 s to reach speed and 1.6 s to stop (main: 1.55 and 1.22), and turns at 49 to 53 degrees a
   second against a frigate's 123 to 133.
6. **Smooth.** Every drive and jet level eases (no one-frame switch); spins are eased; no heading jump at a corner; the
   speed has no step. The plume no longer blips as it passes the 0.95 to 1.05 band fx_ship.gd treats specially.

Pictures (each 1280 x 470, before above after, drive and jet levels under every frame): docs/shots/movement/
`<class>_<move>.jpg` for frigate, cruiser and dreadnought on straight, turn, final, side and back (14 strips: the
dreadnought had no legal one-hex back-off in this scenario), plus movement_measurements.json.

## Measured at the battle camera (Ryan's PC, RTX 5080, 60 frames a second; scenario s1, seed 487, as issue 487)

To speed: 95 percent of the move's peak speed. Stop: 95 to 5 percent. Turn: peak degrees a second. Move: seconds.

| Class, move | Before: to speed, stop, turn, move | After: to speed, stop, turn, move |
|---|---|---|
| Frigate straight | 0.52, 0.43, 0, 2.53 | 0.47, 0.38, 0, 2.47 |
| Cruiser straight | 1.07, 0.85, 0, 3.80 | 1.08, 0.87, 0, 3.80 |
| Dreadnought straight | 1.55, 1.22, 0, 4.10 | 2.02, 1.57, 0, 4.93 |
| Frigate turn then run | 0.80, 0.67, 179, 3.20 | 0.83, 0.38, 123, 2.35 |
| Cruiser turn then run | 1.72, 1.37, 192, 4.02 | 2.87, 0.87, 72, 4.33 |
| Dreadnought turn then run | 2.03, 1.60, 61, 4.45 | 3.12, 1.47, 49, 5.35 |
| Frigate run then final facing | 0.72, 0.60, 211, 3.55 | 0.47, 0.38, 123, 3.53 |
| Cruiser run then final facing | 1.25, 1.00, 101, 3.72 | 1.08, 0.87, 72, 3.92 |
| Dreadnought run then final facing | 1.90, 1.50, 90, 4.15 | 1.90, 1.47, 49, 5.43 |
| Frigate sidestep | 0.52, 0.43, 336, 2.05 | 0.47, 0.38, 0, 1.98 |
| Cruiser sidestep | 1.07, 0.85, 287, 2.53 | 1.08, 0.87, 0, 2.53 |
| Dreadnought sidestep | 1.18, 0.90, 295, 2.57 | 1.45, 1.08, 0, 3.18 |
| Frigate back-off | 0.52, 0.43, 815, 1.57 | 0.47, 0.38, 0, 1.50 |
| Cruiser back-off | 0.87, 0.68, 655, 1.88 | 0.87, 0.67, 0, 1.90 |

"To speed" after a turn counts from the start of the move, so it includes the spin flown first. Every after row ends on
the same position and facing as its before row (`same_end` in the JSON). Max roll: up to 3.8 degrees before, 0 after.
Move time: frigates and cruisers within about 0.3 s of main (the frigate's turn move is 0.85 s shorter: see the zigzag
below); dreadnoughts 0.6 to 1.3 s longer. Headless numbers for every class, battleship included, come from
godot/scenes/battle/test/movement_flight_check.gd (in the spec).

## Battle results identical

- Five seeded bot battles from a real campaign start (seeds 359, 1, 7, 42, 2026; the CI bot battle with a dump of the
  rules battle log and every unit's final hex, facing, hull and death): byte-identical JSON before and after, on both
  build states of this branch.
- Every captured move ends on the same hex and facing as main.
- tools/pacecheck_godot.sh (three bot battles, the manual pace check): s26 passes; s23 and s24 report moves starting
  while another burns, and main reports the same 38 overlaps in s24, so that failure is not from this change. Enemy move
  time a round in s24: 5.3 s on main, 6.5 s after (bigger hulls are slower now). The rules parity step runs on GitHub.

## Dropped or softened, and why

- **Weight slope past battleship halved.** The first strips (full slope, dreadnought 1.5) made a dreadnought's move 1.6
  to 2.3 s longer; now 0.6 to 1.3 s.
- **Spin length by net angle.** The rules' route for the captured frigate "turn" was +60, -60, +60: timed by steps it
  crawled at 41 degrees a second; flown as one 60 degree spin it runs at the frigate's own rate. A group that nets to
  nothing costs no time (no pause).
- **Side jets go quiet while the turning jets work**, and the coast glow follows forward speed only, so a slide does not
  light the main drive as if coasting (a forward-diagonal sidestep still shows a modest burn: half of that push is
  forward).
- **Forces read from the speed profile, not the position.** Reading jets from the position's second difference lit
  retro and drive jets at random while cruising (the curve's arc-length ripple). They now come from the smooth speed
  profile along the path and the bend of the curve.
- Not built (out of scope, listed as quick wins): the rules' route itself turns +60, -60, +60 in one place (RULE: a
  route search tie-break would drop the wasted turns); the dead star's pull still plays as a powered move (audit
  finding 6, small); climb heights are fixed at 9 and 7.5 units (finding 7); parked ships still bob (finding 13).

## Frame cost

Only one ship moves at a time (R64), so a twenty-ship turn costs what one moving ship costs. Live jet sprites on the
moving ship peak at 10 to 24 (main: 2 to 4), each one unshaded additive billboard. Mean frame time while moving at
1920 x 1080: 2.86 to 3.34 ms after against 2.97 to 3.38 ms before (the same within noise). The parked ships' idle jets
are unchanged.

## Tests and documents changed on purpose

- New: godot/scenes/battle/test/movement_flight_check.gd (headless, listed in godot/tools/ci/godot_checks.txt). No
  existing test asserted the old heading blend or the 4 degree bank (Codex's rules sweep, issue 496, found none either).
- tools/pacecheck_godot.sh line 30 (now 31) and its header: the cruise pace range 500 to 950 ms a hex becomes 500 to 1250,
  because hulls past battleship are slower now (largest about 1190 ms with the Crusade factor).
- godot/main/README.md, "Ship movement": the Cinematic bullet rewritten for the flown move; "Pace" no longer says the B2
  formula; "Easing" marked as the segments mode. Its "No banking" is now true.
- godot/fx/API.md line 150 ("ShipView never writes them"): now true; ShipView's three `rotation.x` writes were removed
  (the glide step, the end of a glide, snap_to). No change to that file was needed.
- ship_view.gd: the old segments-mode comment block now says it is the debug mode.
- contrib/opus/briefs/movement_spec.md rewritten.

## Unsure

- The puffs are small at camera 170 on frigates; on capitals they read as white bursts at bow and sides. Ryan may want
  them bigger or longer still; the sizes are spec tuning values.
- The cruiser's "turn then run" now takes 2.9 s to reach speed because the nose comes round first; it reads as point
  then burn on the strip, but Ryan should judge whether it feels slow.
- Capture runs on the PC sometimes crash Godot on shutdown in battle.gd `_overlay` (line 2358), after the capture data is
  written (one of ten runs in round 2). Not touched here; worth a look.
- The dreadnought back-off was not captured (no legal one-hex back-off in this scenario); the headless check covers it.

## Where things are

- Capture and strip tools: contrib/opus/reviews/movement_capture/ (capture.gd, pack.py); PC folder
  Downloads\voidsworn_test\opus505\ (its own clone in repo\, raw frames in raw_r1\ and raw_r2\, strips in out_r1\ and
  out_r2\). Nothing outside that folder was changed on the PC except the two queue files q505_r1.bat and q505_r2.bat.
