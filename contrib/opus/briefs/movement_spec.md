# Movement specification (rewritten for issue 505, Nov 11 2026; section 1a added for issue 521)

Ryan, Nov 11 2026, 09:47 CST: "Make sure it's clean, feels weighty and like you're in space, not water or land? Use of the
main engine, thrusters, turning all make sense, the routing paths for movement make sense, which direction the ship ends
up makes sense".

Ryan, Nov 11 2026, 10:14 CST (FINDINGS R189): "I don't want things to look jerky and the smooth call was because movement
was very stop/start and sudden. Thrusters should be involved when it makes sense on braking and turns. Same with shuffle,
it should make sense in space with how they would fly. The prior record was because everything was so sudden and it
didn't feel like space at all".

**The purpose, which outranks every number below:** movement is never sudden, jerky or stop-start, it feels like space,
and every light on a ship has a reason. A change that makes motion twitchy or busy is wrong, whatever it measures.

This replaces the Nov 8 spec (#228), which wrote R76's "smooth" call down as rules ("thruster puffs only on turns", "no
side-to-side shuffle", "the bow follows the curve"); R189 says those were never the point. **Every number here is a
tuning value chosen by eye from the issue 505 motion strips (docs/shots/movement/), not a limit.** A later builder may
change any of them for a better look, and says so with a strip.

## 1. What a move looks like now (ship_view.gd `play_glide`, `_glide_thrusters`)

- **The path.** The hull slides along one smooth curve through the rules' hex centres (the same curve the blue route
  line draws). The rules choose the route, the end hex and the final facing; the playback never changes them. Speed
  builds from rest, holds cruise (one hex per unit of move time), and bleeds to rest, on eased ramps (no step in speed,
  ever); it slows at a corner by how far the course bends.
- **The heading is flown on its own.** It does not follow the curve. Every rules turn is a spin at the ship's own
  turn-in-place rate, eased in and out:
  - a spin lasts as long as its net angle needs: the rules' route can turn one way and back inside one group (+60,
    -60, +60 is a real route); that is flown as one 60 degree spin, and a group that nets to nothing costs no time;
  - a turn before the run: the spin goes first and the hull sets off when the nose is within about 29 degrees of the
    new heading (`GL_POINT` 0.5 rad): point, then burn, with a little overlap so it never reads as stop-start;
  - a turn at a corner: centred on the hull's passage through the corner; a turn of two steps or more brings the hull
    to rest there for 40 percent of the spin (`GL_DWELL`) while it swings, then it burns out on the new heading;
  - the final facing: starts while the hull is still braking (it overlaps 45 percent of its own length, `GL_TRAIL`) and
    finishes after the hull stops. A visible, weighty manoeuvre, never a late snap.
- **Slides.** A one-hex sidestep or back-off keeps the heading exactly and slides on side or retro jets, smooth in and
  out, slower than a burn. A dogleg (a run, then a one-hex sidestep) keeps the nose and drifts sideways at the bend.
  A longer move is flown nose first (section 1a).
- **No roll.** The hull never banks into a turn (nothing in space leans a ship). ShipView never writes the hull's roll or
  pitch; those belong to the hit reactions (fx/API.md).

## 1a. The main engine does the travelling (issue 521, FINDINGS R195)

Ryan, on the merged issue 505 build: "engines should be clearly stronger and more used for movement than the thrusters.
it sometimes seemed like thrusters would move the ship (especially in slides) just as fast as the engine movement, which
doesn't really make sense to me... it did feel odd to see the ships moving diagnolly or sidewways at rapid speed using
thrusters, especially long distance. for one tile over, it tracks but not when they're going like 3-10 tiles down just
almost skating on thrusters."

**What he was reacting to:** from issue 505 a route made of sidesteps held its heading and was flown on side jets at
cruise speed, so several diagonal steps looked like a ship skating sideways across the board at engine speed.

**The rule (LOOK only; the rules' route, end hex and final facing never change):**
- A move of two hexes or more is flown nose first (battle.gd `_nose_first`). The route's hex centres are split into
  straight legs (`LEG_TOL` 0.55 of a hex: a zigzag of two hex directions is one straight diagonal run, not a heading
  change every hex). The nose comes round onto the first leg before the burn (section 1's turn before the run), onto
  each later leg at its corner, the main engine does the travelling, and the ship turns to the ruled final facing while
  it brakes (section 1's final facing). The rules' own turn steps inside the move are not flown; only their result is.
- Inside a leg the hull is drawn 60 percent of the way onto the leg's straight line (`LEG_PULL`), so it still passes
  inside every hex of the ruled route (a hex centre is at most 0.2 of a hex off the flown line).
- A one-hex slide stays on side or retro jets: a one-hex sidestep or back-off, or a one-hex sidestep at the end or start
  of a longer run (the dogleg drift, on the heading of the leg before it).
- A run straight astern of both the heading and the final facing (more than `ASTERN` 120 degrees off each, a straight
  back-off of two hexes) is backed on retro jets with the heading held: turning a heavy hull round and back again for
  two hexes would be two half-turns of spin for nothing.
- A move flown only on thrusters (the two cases above) takes `SLIDE_PACE` 1.45 times the burn's time per hex, and its
  ramps scale with it, so it is visibly slower and gentler than the main engine.
- Checked by godot/scenes/battle/test/nose_first_check.gd (headless): real rules routes through battle.gd's own
  `_glide_steps`; under way at more than half its peak speed the nose stays within 35 degrees of the course on every run
  of two hexes or more (except a straight back-off and a dogleg's last hex); ends on the rules hex and facing; passes
  inside every route hex; a one-hex slide is at least 1.3 times as long as a one-hex burn.

The small jets: in a flown move no jet starts smaller than `PUFF_MIN` 2.4 world units (about 18 px at the battle
camera, r 170), so a frigate's jets read; puffs live 0.4 to 0.55 s (was 0.3 to 0.55).

## 2. What makes each light (all read from the forces on the hull, in its own frame)

The drive and the jets read the push on the hull as a share of the hardest push in this move. The forces come from the
smooth speed profile along the path and the bend of the curve (`_gl_force`), and the spin's own acceleration
(`_gl_yaw_acc`), so nothing flickers while cruising.

| Light | Lit by | Level |
|---|---|---|
| Main drive | forward push while the hull is not backing | full burn at the hardest push; a hot low glow while coasting (`GL_COAST` 0.15, about 0.6 of the battle's 0..2 drive level); fades with speed as it brakes |
| Retro jets (bow pair, firing forward) | backward push: braking, setting off on a back-off | share of the hardest push |
| Aft jets (stern pair) | forward push while backing: stopping a back-off (the main drive stays low) | share of the hardest push |
| Side jets (matched bow and stern pair) | sideways push: slides, the drift at a dogleg | share of the hardest push; quiet while the turning jets work (fewer, clearer jets) |
| Turning jets (bow one way, stern the other) | spin acceleration: one pair starts a turn, the opposite pair stops it | share of the hardest spin push |

- Every level eases toward its push at `JET_K` 10 a second (the drive rises at 8 and falls at 5): nothing switches on or
  off in one frame. A jet fires above `JET_ON` 0.18; its puffs carry the level, so they fade in and out with the push.
- A jet under way is a stream of puffs, one every 0.07 s (0.1 s on the biggest hulls). Puffs are bigger and last longer
  on a big hull (life 0.3 to 0.55 s; size 7 to 10 percent of hull length, capped at 2.8 to 4.6, by size): a capital's retro burn
  is a heavy plume, not a puff.
- At the end of a move the levels fade out (no new puffs); the battle sets the drive back to its parked level.
- The battle's drive level steps over the 0.95 to 1.05 band that fx_ship.gd reads as "moving, no level given"
  (`_drive_level`), so the plume does not blip there (audit finding 14).

## 3. Weight

- One size scale `sk` (battle.gd): 0 for an escort, 1 for a battleship, and on past it at half the slope: a dreadnought
  about 1.25, titans and arks up to 1.4 (`MOVE_SK_MAX`). Before issue 505 it stopped at 1, so every hull from battleship
  up moved alike. The first strips used the full slope (a dreadnought 1.5): its moves ran 1.6 to 2.3 s longer than
  before, more than "a little", so the slope past battleship was halved (now 0.8 to 1.3 s longer).
- Cruise time per hex: 560 ms for an escort to 860 ms for a battleship, on past it by the same line (a dreadnought
  about 940 ms), times the faction factor to its 0.35 power (`MOVE_PER`, unchanged); the hull cruises a hex in 80
  percent of that (`MOVE_CRUISE`).
- Time to build cruise from rest: 0.7 units for an escort to 1.7 for a battleship (`GL_TR`), on past it (a dreadnought
  about 1.95 units); the stop is the same curve.
- Turn: a 60 degree step weighs 0.6 hexes of time for an escort to 1.1 for a battleship (`MOVE_ROT`), on past it, times
  `GL_SPIN` 2.4; the spin builds and bleeds over 30 to 50 percent of its time by size (`gl_ta`).
- Measured (headless, godot/scenes/battle/test/movement_flight_check.gd, 60 frames a second): a frigate reaches speed in
  0.43 s, stops in 0.37 s and turns at up to 133 degrees a second; a cruiser 1.07 s, 0.85 s, 76; a battleship 1.55 s,
  1.22 s, 59; a dreadnought 1.87 s, 1.52 s, 53. The captured numbers are in contrib/opus/reviews/movement_build_report.md.
- Cap: no move runs longer than 7 s at normal speed (`MOVE_CAP`); a longer one plays faster as a whole.

## 4. Unchanged

- One ship moves at a time (R64). Flip and burn stays off (R64, R55; R193: left alone on the Board's advice, to be looked at again once braking jets are on screen, which they now are). Momentum is never carried between turns (every
  move starts and ends at rest; a rules change, not planned).
- Brisk (a player option) and strike craft keep the older eased motion; `--movement segments` keeps the old rest-to-rest
  segments as a debug flag.
- Climb heights over rocks (9 up, 7.5 down), the dead star's pull (played as a normal move), routes and the suggested
  facing are outside this spec's last build (issue 505 left them alone; see the movement audit findings 6, 7, 9, 10).

## 5. What this spec governs

The flown move in `godot/render/ship_view.gd` (`play_glide`, `_gl_force`, `_gl_yaw_acc`, `_glide_thrusters`, the
`GL_*` and `JET_*` constants, the puffs' size and life in a flown move) and the move timing in
`godot/scenes/battle/battle.gd` (`MOVE_HEX`, `MOVE_ROT`, `MOVE_SK_MAX`, `MOVE_CRUISE`, `MOVE_PER`, `MOVE_CAP`,
`_drive_level`, and since issue 521 `_glide_steps`, `_nose_first`, `LEG_TOL`, `LEG_PULL`, `ASTERN`, `SLIDE_PACE`). Not governed: hit reactions (fx_ship.gd), deaths and wrecks, the camera, the rules.

## 6. How it is checked

- `godot/scenes/battle/test/nose_first_check.gd` (headless, on GitHub, issue 521): section 1a.
- `godot/scenes/battle/test/movement_flight_check.gd` (headless, on GitHub): ends on the rules hex and facing; no roll;
  no frame turns more than 3.5 degrees; slides and straight runs hold the heading; a turn in a move is never faster than
  the same ship's turn in place; burn, coast and retro jets on a straight run; aft jets and a low drive on a back-off;
  side jets on a sidestep; opposite turning jet pairs on every turn; a dreadnought plainly slower than a frigate and
  slower than a battleship.
- Battle results: the rules parity check, and seeded bot battles whose full battle log and final unit states are
  compared before and after a movement change.
- Ryan's eye: the motion strips at the battle camera, before above after.
