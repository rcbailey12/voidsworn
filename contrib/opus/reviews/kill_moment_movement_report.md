# Kill moment and nose-first movement (issue 521)

Opus 5.5 worker, Nov 11 2026. Branch opus/issue-521. LOOK only: no change to godot/rules/, the browser oracle, the AI,
saves, data exports or the battle's UI flow. Rulings: R193 ("Hold and slow", replaces the Board's R123), R195 (the main
engine does the travelling), R189 (never sudden, jerky or stop-start; it must feel like space), R73.

## What Ryan will see

Pictures (each 1280 x 470, code name on the top line, before above after), in docs/shots/kill_moment/:
- K521_kill_cruiser.jpg, K521_kill_capital.jpg: the kill cut-in on main lets go at 1.6 s, before the core flash; after,
  it holds through the flash and a short slow-motion beat, then comes back to the board.
- M521_frigate_long_diagonal.jpg, M521_cruiser_long_diagonal.jpg, M521_dreadnought_long_diagonal.jpg: the same ruled
  route of four sidesteps in a row. On main the hull skates sideways with its nose 60 degrees off its course the whole
  way; after, it swings its nose onto the course, burns, coasts, and turns back to its ruled facing while it brakes.
- measurements.json beside them: every number below.

## A. The kill moment (audit item 7)

- battle.gd `_play_death`: when the kill takes the cut-in, the hold is now the time to the core flash (read from fx,
  `death_core_at`) plus the slow-motion beat (0.48 s) plus 0.35 s on the wreck. Measured on the PC: a cruiser's cut-in
  lets go at 2.48 s (was 1.6; flash at 1.67), a capital's at 3.10 s (was 1.6; flash at 2.28). The next event waits while
  the cut-in holds, so the battle does not carry on behind the letterbox.
- fx.gd: `kill_slowmo` (the battle turns it on) schedules `death_slowmo` at the core flash of every cruiser, capital and
  flagship kill (fx_ship `death_big`, R73: class, not size). Measured: cruiser beat 1.70 to 2.13 s, capital 2.32 to
  2.75 s, the effect clock at 0.35 to 0.45.
- Skippable: any key or a left or right click during the hold lets the cut-in go and ends the beat now
  (`skip_death_slowmo`, which also stops a beat still queued). Enter or Space still hurries the whole turn as before;
  hurried, the old 1.6 s at the battle's pace is kept.
- Reduce Motion: the game has no Reduce Motion switch yet (ui_spec.md 7.6 specifies the settings key `reduce_motion`;
  building the switch is UI follow-up job A). The battle reads that key now (main.gd; an old settings file reads off)
  and `--reduce-motion` for tests; when on, the beat is off and the hold ends 0.35 s after the flash.
- Small hulls, the Chorus rupture and burnt-out hulks have no core flash: no beat, and the cut-in keeps 1.6 s.

## B. The main engine does the travelling (R195)

- battle.gd `_glide_steps` now hands any move of two hexes or more to `_nose_first`: the ruled hex centres are split
  into straight legs (a zigzag of two hex directions is one diagonal leg), the nose comes round onto each leg, the main
  engine does the travelling, and the ship turns to the ruled final facing while it brakes. Inside a leg the hull is
  drawn 60 percent of the way onto the straight line, so it still passes inside every ruled hex.
- A one-hex slide stays on the jets (a one-hex sidestep or back-off, and the one-hex sidestep that ends a dogleg).
  A move flown only on thrusters runs at 1.45 times the burn's time a hex (`SLIDE_PACE`), so it is plainly slower and
  gentler: a frigate's one-hex sidestep 1.38 s against 0.95 s for a one-hex burn (headless).
- A straight back-off of two hexes (Hegemony can) stays on retro jets at the slide pace rather than spinning the hull
  half round and back. This is my call inside the rule; see "For Ryan" below.
- A nose-first move sets off when the nose is within 43 degrees of its course (`NF_POINT`; section 1's 29 degrees for
  other moves) and starts its final turn earlier while braking (`NF_TRAIL` 0.7), so the turn and the run overlap instead
  of reading as turn, stop, burn.
- movement_spec.md has a new section 1a with Ryan's words, what he was reacting to and every value.

## The five carried items

1. **Cruiser turn then run.** Measured again on the PC (same route as the 505 report, turn first then two hexes): it
   reaches speed at 2.67 s (was 2.87) and the move takes 4.13 s (was 4.33), because the burn now starts with the nose
   43 degrees out. The point-then-burn still reads on the strip; if Ryan wants it snappier the next lever is the spin
   rate itself (MOVE_ROT), which would change every turn.
2. **Frigate jets.** In a flown move no jet starts smaller than 2.4 world units (about 18 px at camera 170; it was 1.4,
   about 11 px), and frigate puffs live 0.4 s (was 0.3). Bigger hulls were already above it.
3. **Enemy move time a round** (tools/pacecheck_godot.sh, s24, sandbox Godot 4.7.2 headless at 60 fixed fps): main 5.9 s,
   after 6.5 s. The 505 report's 5.3 to 6.5 was measured on another machine; on this one main gives 5.9. s23: 16.0 to
   20.4 s; s26: 10.5 to 12.6 s. The rise is the turns that nose-first adds and the slower one-hex slides.
4. **Shutdown crash.** Found: the capture's last command (end_activation) resumed after `_quit` had freed the HUD and
   the board; `_refresh_ui` hit the freed HUD (a script error) and `_overlay` then crashed Godot (signal 11 at the old
   line 2358). Fixed: `_quit` sets `quitting`, and `_refresh_ui` and `_overlay` draw nothing once it is set or the HUD or
   board is gone. Ten PC capture runs on this branch ended cleanly (exit 0).
5. **The engine flicker line** (fx_shaders.gd sprite kind 4, issue 461): not touched. This branch edits no fx_shaders,
   fx_weapons, fx_hull or fx_death file; fx.gd only gains the death_slowmo wiring.

## Battle results identical

- Five seeded bot battles from a real campaign start (seeds 359, 1, 7, 42, 2026; godot/tools/ci/bot_battle.gd with a
  dump of the rules battle log and every unit's final hex, facing, hull, dead and fled flags): byte-identical JSON on
  main and on the final branch (md5 prefixes 19b55da48e91, 26cdd6575f00, 42ffdab78937, 66791c767dc9, b44d86a789f9).
- pacecheck: the same move counts (29, 167, 80) and the same overlap counts (s23 58, s24 38) on main and after; the
  overlap failures are main's own, as the 505 report found.
- Every captured move ends on the same position and facing before and after (`same_end` true for all nine).

## Measured at the battle camera (Ryan's PC, RTX 5080, 60 fps; scenario s1, seed 487)

| Class, move | Before: move s, to speed s, nose off course | After |
|---|---|---|
| Frigate 4 sidesteps | 2.47, 0.47, 60 deg | 3.10, 0.73, 6 deg |
| Cruiser 4 sidesteps | 3.80, 1.08, 60 deg | 4.88, 1.62, 1 deg |
| Dreadnought 4 sidesteps | 5.75, 2.02, 60 deg | 7.00 (the cap), 2.85, 1 deg |
| Dreadnought straight 3 hexes | 4.93, 2.02 | 4.93, 2.02 (unchanged) |
| Cruiser turn then run | 4.33, 2.87 | 4.13, 2.67 |

The long-diagonal captures give each player ship 8 movement points first (both sides), so a four-sidestep route exists
for every class; the rules choose the route.

## Checks

- New, headless, listed in godot/tools/ci/godot_checks.txt: godot/scenes/battle/test/nose_first_check.gd (real rules
  routes through battle.gd's own `_glide_steps`: ends on the rules hex and facing, passes inside every route hex, nose
  within 35 degrees of the course under way on every run of two hexes or more, a one-hex slide is on the jets and at
  least 1.3 times a one-hex burn) and godot/fx/test/kill_slowmo_check.gd (the beat starts at the core flash, 1.66 s and
  2.28 s, not for a frigate, not when off, and a key or click ends it or stops it before it starts).
- godot/tools/ci/run_checks.sh (sandbox): 37 headless checks PASS (death_leap_check needed a fresh import in the sandbox,
  then PASS). movement_flight_check PASS unchanged. destruction_staging_check PASS.
- Checks that enforce the old numbers (contrib/codex/reviews/rules_sweep_checks.md rows 5, 20, C2, C9, M3, M5): none
  needed a change. C9: destruction_staging_check's helper bound (beat under 0.8 real s) and audio_check's synthetic beat
  still pass; the beat length is unchanged and fx keeps it off unless the battle turns it on. C2: no check asserted the
  1.6 s release. The pace
  check's 500 to 1250 ms a hex reads the hull's cruise pace, which is unchanged (the slide pace multiplies the flown time,
  not the printed pace); the 7 s cap still holds (the dreadnought's four sidesteps reach it and play faster as a whole).
  movement_flight_check flies glide steps directly, so the issue 505 numbers it guards are unchanged.

## For Ryan

- A straight back-off of two hexes stays on retro jets (slow), not nose first: flown nose first, a heavy hull would spin
  half round and back for two hexes. Board's pick: keep it.
- The cut-in for a kill frames the attacker and the target side-on from up to 200 units out, so the dying ship is small
  in it (see K521_kill_cruiser.jpg). Holding longer makes that more noticeable; a closer kill framing would be a
  follow-up, not part of this job.
- Moves are a little longer (enemy move time a round 5.9 to 6.5 s in s24): nose-first adds the turns a ship in space
  would make, and the one-hex slides are slower on purpose.

- Stale documents the rulebook job (issue 492) should align: contrib/opus/briefs/ui_spec.md line 29 and its MN6 note
  ("capital deaths never take the player camera", the Board's R123) are replaced by R193; godot/bench/README.md line 71
  (the look bench does not play the beat) is still true of the bench.

## Where things are

- Capture and strip tools: contrib/opus/reviews/movement_capture/capture_521.gd and pack_521.py; PC folder
  Downloads\voidsworn_test\opus521\ (own clone in repo\, raw frames raw_r1\ and raw_r2\, strips out_r1\ and out_r2\; r2
  is the final code). Nothing else on the PC was changed except the queue files q521_r1.bat and q521_r2.bat.
