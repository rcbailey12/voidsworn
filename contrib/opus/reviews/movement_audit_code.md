# Movement audit, code leg (issue 489)

Opus 5.5 worker, Nov 11 2026. Read-only: no game code, tests or playbooks changed. Pinned to main at 611ea9c.
Read: FINDINGS R50, R55, R64, R76, R170 to R188; contrib/opus/briefs/movement_spec.md; the first audit's code leg
(contrib/opus/reviews/cinematic_audit_code.md on branch opus/issue-485, finding 12 in particular); godot/rules/rules.gd
(computeReach, _commit, rotateUnit, wellTick, pathField, aiUnit and its eval functions); battle.js, ui3d.js and data.js for
the same logic; godot/scenes/battle/battle.gd (the move constants, `_play_move`, `_move_segments`, `_glide_steps`,
`_best_facing`, `_path_dots`, `_move_frames`, `_maneuver_score`); godot/render/ship_view.gd (the whole motion layer:
`play_glide`, `_gl_leg`, `_gl_pose`, `_glide_step`, `_glide_thrusters`, the jets, the idle code) and the engine code in
godot/fx/fx_ship.gd and godot/fx/fx.gd.

No PC, no bench and no game run. To get real numbers I ported the glide's timing and heading code (ship_view.gd 792 to 1104)
line for line into a small script and ran the moves named below. Every number marked "port" comes from that script, not from
watching the game; finding by finding I name the capture that would confirm it.

## Top five in one line each

1. The main engine works like a speedometer: the plume is biggest while the ship coasts at cruise and fades as it slows, so it is lit when it should be dark and dark-ish when it should be braking.
2. A sidestep or a back-off is flown as a swerve: the nose swings about 90 degrees for a one-hex sidestep and spins a full circle for a one-hex back-off, which are exactly the moves the Hullbreakers' and Hegemony's own doctrines are built on.
3. A turn inside a move is two to eight times faster than the same ship's turn in place, because the nose is blended onto the course in a fixed slice of the move instead of turning at the ship's own rate; battleships whip round like frigates.
4. Nothing fires to stop the ship or push it sideways: the retro, side and aft jets exist but only the old debug mode uses them, and the turning jets keep firing the same pair for the whole turn instead of a start pair and a stop pair.
5. Weight barely shows: a battleship's cruise is only 1.28 times slower than a frigate's, it reaches full speed in one second, and every ship from battleship up (dreadnoughts, titans, arks) moves exactly like a battleship.

Next five: the dead star's pull is flown as a powered move with the nose turned toward the star; ships drive straight through
friendly ships at the same height; the 4 degree bank is an aircraft tell (I disagree with the first audit's call to raise it);
routes run straight first and dogleg sideways at the end; the facing the game offers by default ignores the prow guns and the
next round.

---

## How a ship moves today

**The rules pick the route.** A ship gets movement points equal to its speed (frigates 5 to 7, cruisers 3 to 5, battleships
and carriers 2, two bosses 1; data.js hull rows, `sp`) and a number of 60 degree turns per round (`tn`: frigates 3, most
cruisers 2, battleships and bosses 1). From any hex it may step: straight ahead along its nose (1 point), to either
forward-diagonal hex without turning, a sidestep (2 points; Hullbreakers 1), or straight back without turning (2 points;
Hegemony 1); climbing over a rock or wreck or diving under an enemy ship costs 1 more (Eclipse 0). Turning happens only in place,
60 degrees at a time, 1 point each (the Chorus get the first turn free). A battleship or carrier with 2 points that sidesteps
spends its whole move on it (battle.js 478: "a heavy hull with too little movement can still spend all of it on one thruster
hop"). The rules search every reachable hex and facing (rules.gd 1560 to 1631, battle.js 454) and keep the cheapest route to
each. There is no momentum: every move starts and ends at rest (R55: carried momentum is a rules redesign, not planned).

**Choosing the move.** The player clicks a blue hex; the game offers, on each hex, the facing that brings the most ready guns
onto any enemy, cheapest on ties (battle.gd 2141, ui3d.js 393). Q and E cycle the other facings; a see-through ghost shows the
end facing and a blue line shows the route. The enemy AI scores every reachable end hex and facing on damage it can deal, damage
it will take, distance and objectives, and picks the best (rules.gd 6331 to 6372, battle.js 2155).

**The playback flies it.** One ship moves at a time (R64). In the default "cinematic" mode the whole move is one continuous
glide along a smooth curve through the hex centres (ship_view.gd 792), with the nose following the curve. Cruise is one hex per
"unit" of time; a unit is 0.45 s for a Glasswright frigate up to 0.62 s for a Hegemony battleship (battle.gd 1501 to 1505,
1524). The hull builds to cruise over 0.8 units (frigate) to 1.6 units (battleship and up), slows for corners (to 58% of cruise
at a 60 degree corner, ship_view.gd 847 to 850), and bleeds to a stop at the end with the same curve it started with. Real
seconds (port): a frigate crosses 3 hexes in 2.1 s, a cruiser in 3.2 s, a battleship in 3.4 s; no move may run past 7 s. A
turn in place spins on a smooth start and stop: 60 degrees takes 0.70 s on a frigate and 1.64 s on a battleship. The rules'
turns inside a move are not flown as turns: the nose is blended from its start heading onto the curve over the first 18% of
the move and onto the final facing over the last 24% (ship_view.gd 1066 to 1067). The hull rolls up to 4 degrees into turns.

**Engines and thrusters.** The main drive's plume follows the ship's speed, not its push: dim pilot glow at rest, full plume at
cruise, fading as it slows (ship_view.gd 1146, battle.gd 1541). Plume length is 1.5 times the hull's beam, 2 to 32 units
(fx_ship.gd 236). The only jets fired in a cinematic move are the turning pair (one at the bow, one at the stern) every 0.24 s
while the nose is swinging (ship_view.gd 1147 to 1149). There are no braking or sideways jets in a cinematic move. At rest,
every ship bobs up and down on one slow sine and puffs a side jet every 1.6 to 2.4 s. One engine sound plays at the start of
each move whatever its length (battle.gd 1534).

**What differs by class and faction.** By class: cruise speed, how long speed and spin take to build, and turn rate, all on
one size scale that stops at battleship size. By faction: only a pace factor (Crusade slowest per hex, Eclipse quickest) and
the exhaust's decoration (Hullbreaker soot, Chorus spores, Eclipse embers). Strike craft use the older brisk motion.

**The spec is out of date.** contrib/opus/briefs/movement_spec.md says retro jets at the bow light while a ship brakes and that
each segment ends in a small settle. Both exist only in the old segments mode (`_thrusters`, ship_view.gd 700 to 738), which is a
debug flag; the cinematic glide has neither. The comment above the glide says so plainly: "The main drive follows speed; RCS is
brief and dim on turns" (ship_view.gd 766).

---

## 1. The main engine is a speedometer, not a thruster (LOOK)

1. **What the player sees now.** The engine plume grows as the ship gets going, is at its biggest while the ship sails along at
   cruise, and shrinks as the ship slows down, like a car's exhaust following the throttle. A one-hex hop shows the same full
   plume at its fastest moment as a five-hex run.
2. **What a ship in space would do.** The drive burns hard to start the ship moving, then goes quiet while it coasts (the ship
   keeps its speed without it), and the stop is a separate burn the other way. A long run reads burn, coast, brake.
3. **Where it lives.** ship_view.gd 1146: `thrust = clampf(velocity.length() / maxf(gl_vpk, 1e-4), 0.0, 1.0)`, the hull's
   speed divided by the peak speed of this move (gl_vpk, 945). battle.gd 1541 turns it into the drive level,
   `lerpf(ENGINE_IDLE, 2.0, sv.thrust)` (0.35 to 2.0); fx_ship.gd 305 and 311 follow it (rise at 4 a second, drop at 14). At
   the end battle.gd 1549 sets 0.35. Note for the Board: the first audit said the plume "cuts off within 0.1 s"; in the glide it
   actually fades with speed over the braking (about 0.4 s on a frigate, 1.0 s on a battleship), and only the last step down to
   the parked glow is fast.
4. **Why.** R76 asked for "the main engine doing the work"; tying the plume to speed was the simplest way to keep it lit for the
   whole glide. The comment at 766 records it as a choice.
5. **The change.** Drive the plume from the forward part of the hull's acceleration in its own frame (the glide already
   computes it as `_acc`, ship_view.gd 1128), divided by the hull's top acceleration (`amax`, 831), so the plume peaks during the
   speed-up and drops to a "hot coast" glow (about 0.6, nozzles lit, short plume, so a coasting ship never reads as dead; R55
   "I like engines glowing dimly") while cruising. Braking is finding 4. Keep the plume's size by hull (already 1.5 times beam).
   The segments mode's `_thrusters` (700 to 738) is a worked example of thrust by phase. LOOK: playback only.
6. **Size.** Medium (two runs, built together with finding 4, plus one capture review).
7. **Capture.** A battleship's straight 3-hex run and a frigate's 5-hex run, side view, with `--speed-trace` printing speed and
   drive level per frame; a strip of six frames from start to stop.

## 2. Sidesteps and back-offs are flown as swerves and pirouettes (LOOK, against the wording of R76)

1. **What the player sees now.** A ship told to sidestep one hex swings its nose round about 90 degrees toward the side (more
   than the 60 degree step itself), drives there, then swings back. A ship told to back off one hex spins a full circle: it
   whips round 140 degrees, drives backward-turned-forward, and finishes the circle as it stops. Left and right sidesteps look
   different from each other.
2. **What a ship in space would do.** Keep pointing where it points and slide: side jets push it sideways and catch it at the
   end; for a back-off the bow's retro jets push it back and the aft jets stop it. Those are the most "space" moves in the game.
3. **Where it lives.** ship_view.gd 913 to 918: any first step more than about 45 degrees off the nose
   (`travel.normalized().dot(bow) < 0.7`) gets a sideways "drift" bend of 0.45 hex, always to the right of the direction of
   travel (`travel.cross(Vector3.UP)`), which is why left and right differ; 920 to 930: the nose follows the curve's tangent;
   1066 to 1067: blended from the start heading over the first 18% of the move and onto the final facing over the last 24%;
   930: the final facing is reached by the short way from wherever the curve left the nose, which for a back-off finishes a full
   circle. Port numbers: a one-hex sidestep turns the nose up to 87 to 90 degrees, peak 694 degrees a second on a frigate and
   353 on a Hegemony battleship; a one-hex back-off rotates the hull 360 degrees, peak 1,142 degrees a second on a frigate and
   575 on a battleship. For scale, that battleship's own turn in place peaks at 66 degrees a second.
4. **Why.** R76 (Ryan, Nov 2): "glides on smooth curves with the main engine doing the work ... no side-to-side shuffle". The
   builder read that as "the bow always follows the curve" (766: "The bow follows the curve instead of the rules' sidestep
   heading"). I read Ryan's "shuffle" as the old rest-to-rest stepping of the segments mode, not as sliding itself; that is his
   call.
5. **The change.** For steps the rules mark `slip` or `rev` (and for the gravity pull, finding 6), keep the nose on the rules'
   heading and slide the hull along the same smooth curve in one continuous motion (no stop between hexes, so no shuffle);
   heavy hulls may lead into the slide with up to 15 degrees of nose and settle back. Drop the right-hand drift bias. Side jets
   fire in matched bow and stern pairs, retro and aft jets for back-offs (finding 4). Who gains most: the Hullbreakers ("Bolted
   burners": sidesteps cost 1), the Hegemony ("Retro thrusters": back-offs cost 1), and every 2-point battleship and carrier,
   whose sidestep is its whole move. LOOK: playback only; the rules already keep the heading. Ryan should rule on it because it
   reads against R76's words.
6. **Size.** Medium (two runs; shares the heading code with finding 3).
7. **Capture.** `--move-frames <dir> --maneuver back --cls Battleship` with a Hegemony fleet, and `--maneuver side` with a
   Hullbreaker fleet; top view, eight frames each. The back-off spin is the one to look at first: if the capture does not show
   a full circle, my port is wrong somewhere.

## 3. Turns inside a move snap, and a battleship turns like a frigate (LOOK)

1. **What the player sees now.** When a move starts with a turn, the nose whips onto the new course in the first moment while
   the ship is already sliding off, overshoots by about 30 degrees, then eases back. A turn at the end of a move happens in the
   last quarter, while the ship brakes, faster than the ship could ever turn standing still. A battleship's swing looks as
   quick as a frigate's.
2. **What a ship in space would do.** Point, then burn (Homeworld, which Ryan named in R76): turning thrusters swing the nose at
   the ship's own rate, slow for a capital, quick for an escort; the main drive lights once the nose is on course; a final turn
   is its own unhurried manoeuvre.
3. **Where it lives.** ship_view.gd 1066 to 1067: `smoothstep(0.0, 0.18, p)` and `smoothstep(0.76, 1.0, p)`, fixed shares of
   the move, the same for every class and every angle. The ship's real turn timing is computed and then not used for the nose:
   the spin windows (`gl_turns`, 869 to 896, weights `MOVE_ROT := [0.6, 1.1]`, battle.gd 55) only set the move's length. And
   1058 stretches the travel over the whole move (`_gl_dist(p * gl_motion_time)`), so a turn at the start makes the ship slide
   off at once and travel the whole run slower (port: a frigate that turns 180 degrees then goes 2 hexes cruises at 1.2 hex a
   second instead of 2.1). The drift bend of finding 2 also applies here, because 915 compares the course with the nose before
   the turn: every move that starts with a turn gets it. Port numbers, peak nose speed in a move against the same ship's turn
   in place: frigate in place 123 degrees a second, "turn 60 to starboard then 1 ahead" 513, "turn 60 to port then 1 ahead"
   167, "2 ahead then turn 60" 199; battleship in place 66, the same three moves 249, 79 and 108.
4. **Why.** R76 wanted one continuous curve; blending the nose onto the curve over fixed slices was the simplest join between
   the rules' turn-in-place steps and that curve.
5. **The change.** Drive the nose from the spin windows that already exist, at the in-place rate (`_spin`, 1077): a start turn
   runs first and the drive lights when the nose is within about 20 degrees of the course (the hull may start drifting slowly
   on its jets meanwhile); a corner turns at no more than the in-place peak, beginning early enough to finish as the hull comes
   out of the bend; a final turn begins early enough to finish at the in-place rate, overlapping the braking if it must. Remove
   the drift bend from forward runs. Move length grows a little for moves with turns; MOVE_CAP 7 s still holds. LOOK.
6. **Size.** Medium (two runs; build with finding 2).
7. **Capture.** `--maneuver turn` on a battleship and a frigate (`--cls Battleship,Frigate`), top view, one frame every 0.2 s,
   with `--speed-trace` printing the spin rate; set beside a turn in place by the same ships.

## 4. Nothing fires to stop the ship, slide it, or stop a turn (LOOK)

1. **What the player sees now.** A ship comes to rest with nothing firing forward; it just slows as if in water. Sideways moves
   show no side jets. While the nose swings, the same pair of turning jets puffs every quarter second for the whole turn, then
   the turn simply stops.
2. **What a ship in space would do.** Every change of motion has a visible cause: bow retro jets (or the main drive after a
   flip, which R64 keeps off) to stop; side jets in matched pairs to slide; one pair of turning jets to start a spin and the
   opposite pair to stop it.
3. **Where it lives.** ship_view.gd 1141 to 1149 `_glide_thrusters`: only `_couple_puffs(signf(_yaw_v), 0.85)` while
   `absf(_yaw_v) > 0.06`, every 0.24 s; it reads the turn's speed, not its acceleration, so the stopping pair never fires.
   `_retro_puffs`, `_aft_puffs` and `_side_puffs` (1175 to 1191) are called only from the segments mode's `_thrusters`
   (733 to 738) and, for side jets, the idle code. The glide already computes everything needed: `_acc` and `_yaw_a` (1128 to
   1131).
4. **Why.** R76's "small thruster puffs only on turns" was implemented literally.
5. **The change.** In `_glide_thrusters`, fire jets from the hull's acceleration in its own frame: backward part to bow retro
   jets, sideways part to matched side pairs, forward part to the main drive (finding 1); turning jets from `_yaw_a`, the start
   pair while the spin builds and the opposite pair while it bleeds. Scale puff size and duration with hull size (a capital's
   retro burn is a long, heavy plume, not a puff; today a puff is 0.28 s and about 5% of hull length, 1199 to 1213). Keep R76's
   restraint: short, matched bursts. LOOK.
6. **Size.** Medium (built with finding 1; two runs together).
7. **Capture.** The last second of a battleship's 3-hex run, side view, and a turn in place, top view, frame every 0.1 s.

## 5. Weight barely shows, and it stops at battleship size (LOOK)

1. **What the player sees now.** A battleship cruises only a little slower than a frigate and is at full speed within a second.
   A dreadnought, a bio-titan or a boss ark moves exactly like a battleship.
2. **What a ship in space would do.** A capital takes visibly longer to get going, turn and stop, with longer, bigger burns;
   the largest hulls are the slowest of all.
3. **Where it lives.** battle.gd 1501: `sk := clampf((size - 0.5) / 0.45, 0.0, 1.0)`, so every hull of size 0.95 or more
   (battleships 0.95 to 0.98, dreadnought 1.18, bosses 1.22 to 1.3) gets the same weight. ship_view.gd 830
   `tr := lerpf(0.8, 1.6, mass)` (time to full speed), battle.gd 52 `MOVE_HEX := [560.0, 860.0]` (time per hex), 55
   `MOVE_ROT := [0.6, 1.1]` (turn weight), ship_view.gd 868 spin ramps 0.3 to 0.45. Port numbers: cruise 2.06 hex a second
   (Crusade frigate) against 1.61 (Hegemony battleship), a ratio of 1.28; full speed in 0.39 s against 1.0 s; turn 60 degrees
   in place in 0.70 s against 1.64 s.
4. **Why.** R64 halved the pace and made every ship move at its own speed, but the spread by size was set once (F2) and never
   judged against a capture (movement_spec.md: "none of them was ever measured against a feel target").
5. **The change.** Let size run past 1 for the largest hulls (clamp at size 1.3), and widen the spread: time to full speed 0.6
   to 2.6 units, turn weight 0.5 to 1.8, spin ramps up to 0.5 of the spin. Keep MOVE_CAP 7 s, so a boss's long move is played a
   little faster as a whole rather than running long. The enemy's turns get a little longer, which R64 already accepted. LOOK.
6. **Size.** Small (one run, numbers only), then Ryan's eye on a side-by-side.
7. **Capture.** The spec's own A3 set (movement_spec.md section 6): frigate, cruiser, battleship and one boss on the same
   straight 3-hex run and the same turn in place, side by side, at today's numbers and the wider ones.

## 6. The dead star's pull is flown as a powered move toward the star (LOOK)

1. **What the player sees now.** When the Hollow Sun drags a ship one hex inward ("Dragged by gravity"), the ship turns its nose
   toward the star, lights its drive and flies there, then turns back.
2. **What a ship in space would do.** It is dragged, not flying: the nose holds (or twists slowly), and the drive flares the
   other way, straining against the pull while the ship slides in anyway. That is the most dramatic moment the dead-star board
   has, and today it reads as a voluntary move.
3. **Where it lives.** rules.gd 1014 emits `pulled`; battle.gd 1324 to 1326 plays it with `_play_move`, the same glide as a
   normal move, so the nose follows the curve (finding 2) and the drive follows speed (finding 1). Port, a pull abeam: the nose
   swings up to 147 degrees and back, peak 858 degrees a second on a frigate, 435 on a battleship.
4. **Why.** Reuse of the move playback.
5. **The change.** A `pulled` playback: hold the nose, ease the hull inward with a slow start and no braking (gravity does not
   brake), drive plume at full but pointed away from the star when the nose allows (a burn against the pull), plus a few hull
   creaks from the tidal sound already in the game. Ends on the hex the rules say. LOOK.
6. **Size.** Small (one run).
7. **Capture.** A ship inside the pull ring at the start of a round on a dead-star board, top view, frames every 0.2 s.

## 7. Ships drive through friendly ships, and climbs ignore hull size (LOOK)

1. **What the player sees now.** A ship whose route crosses a friendly ship's hex flies straight through that ship at the same
   height. Climbing over a rock or wreck, or diving under an enemy, uses the same 9 units up or 7.5 down for a frigate (10 units
   long) as for a super-dreadnought (50 units long). The Eclipse, whose doctrine is passing through obstacles, climb like
   everyone else.
2. **What a ship in space would do.** Pass over or under a friend by a clear margin, scaled to both hulls; the Eclipse should
   fold or phase through.
3. **Where it lives.** rules.gd 1597 (battle.js 481): only an enemy ship marks a step as a dive (`o["side"] != u["side"]`), so a
   friendly hex is a plain step; battle.gd 1618: `p.y = (9.0 if ov > 0 else -7.5) if ov != 0.0 else 0.0`; hull lengths
   render/hull_table.gd 26 to 28 (`SHIP_K` 1.6 times 6.5 to 31). Eclipse "Fold drive" is `over: 0` (data.js 105) but still
   carries the climb flag.
4. **Why.** The rules never needed to know about friends in the way; the playback took the rules' flag as-is.
5. **The change.** In `_glide_steps`, look up each step's hex in the playback's own view of the board: a friendly ship there
   gets a pass above or below by half of each hull's height plus a margin; climbs and dives scale the same way; Eclipse hulls
   do a short phase shimmer instead of a climb. Battle results unchanged. LOOK.
6. **Size.** Small to medium (one or two runs).
7. **Capture.** A cruiser ordered through a friendly battleship's hex, side view. I could not tell from the code how often
   routes cross friends or how bad the overlap looks; the capture settles it.

## 8. The bank is an aircraft tell (LOOK; disagrees with the first audit)

1. **What the player sees now.** In any real turn the hull rolls about 4 degrees into it, like a plane or a speedboat leaning
   into a bend. It is small, so it mostly reads as a slight wobble.
2. **What a ship in space would do.** Not lean. Nothing pushes a ship sideways into a turn in space; turning jets yaw it flat.
   A small roll is only right where something causes it (a jet pair fired off-centre, a hit).
3. **Where it lives.** ship_view.gd 1132: `clampf(-_yaw_v * 0.12, -4 deg, 4 deg) * sin(PI * gl_p)`, and 1134
   `rotation.x = glide_bank`. Any yaw rate over 33 degrees a second hits the 4 degree cap, so in practice every turn in a move
   banks the full 4 degrees (finding 3's turn rates are 79 to 513). The comment at 461 still says "No banking"; the spec calls
   the bank "a cinematic accent, not physics".
4. **Why.** A cinematic accent added with the R76 glide.
5. **The change.** Remove the bank from turns. If a roll is wanted, tie it to finding 4's jets: a brief roll of 1 degree or
   less when a turning pair fires, damped. The first audit (finding 12) proposed raising the bank to 10 to 12 degrees for
   cruisers and up; against this brief ("banking or rolling into a turn like an aircraft") I recommend the opposite. The Board
   should pick one. LOOK.
6. **Size.** Small (one run).
7. **Capture.** Front view of a cruiser making "1 ahead, turn 60, 1 ahead", frames every 0.1 s, with and without the bank.

## 9. Routes run straight first and dogleg sideways at the end (RULE, or a LOOK alternative)

1. **What the player sees now.** When a target hex is off to one side, the route goes straight ahead first and jinks sideways
   at the very end; a hex off the hex grid's six directions comes out as a run plus a hook rather than one clean line. The
   blue route line and the flight match (within a tenth of a hex), so what you see is what you get; it is just not how a
   captain would steer.
2. **What a ship in space would do.** Fly the straight line or one smooth arc to the destination.
3. **Where it lives.** rules.gd 1586 (battle.js 476) tries steps in a fixed order: ahead, sidestep right, sidestep left, back,
   then turns; the search runs breadth first and keeps the first route found to each hex, facing and turn count at equal cost
   (rules.gd 1626, `seen[k] <= n.cost`), so of the routes "ahead, ahead, sidestep", "ahead, sidestep, ahead" and "sidestep,
   ahead, ahead" (same cost, hex and facing) it always keeps the first. The playback and the blue line both draw a smooth curve
   through those hex centres (battle.gd 2407 `_path_dots` uses the glide's own `_prep_run`), differing only by finding 2's drift
   bend (at most 0.11 hex, port). The AI routes are the same: it scores end hexes, never the route's shape.
4. **Why.** A plain breadth-first search; the order of the step list decides ties.
5. **The change.** RULE option: among equal-cost routes, keep the one whose hex centres stay closest to the straight line from
   start to end (or simply spread sidesteps evenly through the run). The end hex, facing, cost and results do not change; the
   path in the event does (it is checked for parity between the twins), and one tree skill reads it (Grax "allScars" counts
   enemies passed). Must change in battle.js and rules.gd together. LOOK option: leave the rules alone and, for a route whose
   steps all keep one heading, fly and draw a straighter curve that only has to pass through each hex, not its centre (both the
   line and the flight use `_prep_run`, so they stay matched). I would try the LOOK option first.
6. **Size.** RULE: small (one run plus a parity run). LOOK: small (one run).
7. **Capture.** A Hullbreaker raider (sidesteps cost 1) ordered to a hex 4 out and 2 across, top view, blue line and flight
   overlaid.

## 10. The facing the game offers ignores the prow guns and the next round (RULE: a UI default, not the rule twins)

1. **What the player sees now.** For each hex the game suggests the facing that brings the most guns onto any enemy. A side
   battery counts the same as the prow lance. Where no gun reaches anything, it suggests whatever facing is cheapest, which can
   leave the ship pointing away from every enemy for next round unless the player turns it with Q and E.
2. **What a captain would do.** Face the threat: prow weapons first (no ship in this game fires backward), and when nothing is
   in range yet, end pointed at the enemy it will fight next.
3. **Where it lives.** battle.gd 2158 to 2164: `sc := -cost * 10 - turns`, `sc += n * 1000` where n counts ready non-flak guns
   that can reach any enemy; the browser's twin is ui3d.js 393 to 397 (`bestFacingReach`).
4. **Why.** A straight port of the browser's helper; the zero-guns case was never given its own rule.
5. **The change.** Keep "most guns" first, but weight prow weapons above broadsides (say 1.5 to 1), and when no gun bears,
   prefer, among the cheapest states only, the facing whose prow arc covers the nearest enemy. Because only equally cheap
   states are compared, it never costs the player movement. Lives in battle.gd and ui3d.js, not in rules.gd or battle.js, so
   the rule twins and the AI are untouched and the same orders give the same results; but it changes what a player who accepts
   the default gets, so I mark it RULE for Ryan's ruling.
6. **Size.** Small (one run, both UI files).
7. **Capture.** A cruiser two hexes out of range of every enemy: the offered ghost on three hexes, before and after.

## 11. The AI does not care where it points when it cannot shoot (RULE)

1. **What the player sees now.** An enemy ship closing in, with nothing in range this turn, ends wherever its cheapest route
   leaves it, sometimes side-on or nose-away from your fleet, then spends next turn's movement turning.
2. **What a captain would do.** Close in and end pointed at the target, prow guns ready.
3. **Where it lives.** rules.gd 6331 to 6372 (battle.js 2155 to 2190): when a state has no offence (`off <= 0`), the score is
   distance to the nearest foe times 4, threat, and `s.cost * 0.05`; nothing rewards the end facing. `aiArcSoon` (rules.gd
   6012) exists but is used only to rate the player's threat.
4. **Why.** The approach scoring only measures distance.
5. **The change.** Add a small term for states with no shot: plus a fraction of a point for each of the ship's own prow (and
   turret) weapons whose arc would cover the nearest foe from that state, enough to break ties between equal-distance states,
   never enough to outweigh distance or threat. RULE: both twins, and a balance run, because it will make the AI a little
   sharper.
6. **Size.** Medium (two runs: both twins plus the balance sims).
7. **Capture.** A count rather than a picture: in 50 seeded bot battles, the share of enemy moves that end with no shot and no
   player ship in the prow arc, before and after. I could not count it from the code alone.

## 12. Every faction moves the same, and the pace factor runs against the lore (LOOK)

1. **What the player sees now.** Glasswrights, Chorus, Hullbreakers and the rest start, turn and stop with the same curves.
   The only difference is a pace factor, and it is backwards for the lore: the "blindingly fast" Glasswrights take each hex at
   the base pace, while the Eclipse take each hex 16% quicker and the Crusade 8% slower.
2. **What a film would do.** Give each navy its own way of moving: the Glasswrights quick and exact, the Chorus alive (a flex
   and a pulse), the Hullbreakers uneven and junky, the Eclipse unnaturally smooth with no visible thrust, the Hegemony
   textbook precise, the Crusade heavy and deliberate.
3. **Where it lives.** battle.gd 48 `MOVE_PER` (Crusade 1.25, Chorus 1.1, Glasswrights 1.0, Hullbreakers 0.85, Hegemony 0.75,
   Eclipse 0.6), entered as its 0.35 power at 1502; it came over from the browser's timing sim (sim3d.js 22), where it looks like
   a pace equaliser, not a character choice. The exhaust extras are the only other faction difference (fx_ship.gd 226 to 262).
4. **Why.** One motion model built first; faction flavour was left to the exhaust.
5. **The change.** A small per-faction motion profile on top of the glide: Glasswrights ramps 0.7 times as long and crisp turns;
   Chorus a slow body undulation of 1 to 2 degrees and a drive that pulses; Hullbreakers uneven burns (the engine sputter
   already exists) and a little overshoot; Eclipse no puffs and a constant-speed glide; Hegemony clean paired retro burns. Drop
   or re-order `MOVE_PER` to match. LOOK.
6. **Size.** Medium (two or three runs, one per pair of factions, plus a capture review).
7. **Capture.** The same 3-hex run by one cruiser of each faction, side by side.

## 13. Parked ships bob like boats and puff for no reason (LOOK)

1. **What the player sees now.** Every parked ship rises and falls on the same slow ten-second swell and fires a side jet every
   two seconds or so that moves nothing. Ships that have moved once glow a third as bright at rest as ships that have not.
2. **What a ship in space would do.** Hold still, or drift very slowly in some direction, with an occasional paired jet that
   visibly corrects that drift. Every parked drive glows the same dim pilot light (R55).
3. **Where it lives.** ship_view.gd 1286: `sin(t * 0.6 + bob_seed) * 0.25` units up and down (a boat at anchor); 1280 to 1284:
   `_side_puffs` every 1.6 to 2.4 s, alternating sides. fx_ship.gd 305: a parked ship glows `IDLE_GLOW * engine_level`; that
   is 0.3 before its first move (engine_level starts at 1.0, fx_ship.gd 32) and 0.105 after it, because battle.gd 1549 leaves
   the level at `ENGINE_IDLE` 0.35.
4. **Why.** The bob was a liveliness accent; the glow difference is two constants meeting by accident.
5. **The change.** Replace the vertical bob with a slow drift of a few tenths of a unit on a different axis for each ship, with
   a paired jet that nudges it back when it wanders; make the parked glow one constant for every ship. The first audit wanted
   two sines and a yaw wander; that fits, as long as the vertical swell goes. LOOK.
6. **Size.** Small (one run).
7. **Capture.** A 20-second still-camera clip of a parked fleet after one round, half the ships moved and half not.

## 14. The plume blips as the ship passes 40% of its speed (LOOK)

1. **What the player sees now.** Probably a brief swell in the drive plume once while speeding up and once while slowing down.
   I could not tell from the code whether it is visible on a frigate; it should be on a battleship.
2. **What a ship in space would do.** A plume that changes only when the burn changes.
3. **Where it lives.** godot/fx/fx_ship.gd 305:
   `(engine_level if absf(engine_level - 1.0) > 0.05 else 1.6)`. A drive level of exactly 1.0 used to mean "moving, no level
   given", so any level between 0.95 and 1.05 is treated as that and jumps to 1.6. The glide's level passes through that band
   at about 36 to 42% of the move's peak speed (battle.gd 1541), twice per move. Port: the band lasts about 0.03 s on a frigate
   and 0.1 s on a battleship; at a rise rate of 4 a second the plume swells by roughly 0.1 and 0.25 of full.
4. **Why.** An old "no level given" convention meeting the new continuous level.
5. **The change.** Have the battle always pass a level (it does in cinematic and brisk), and drop the 1.6 special case, or move
   it to an explicit flag. Moot if finding 1 replaces the level curve, but the special case should go either way. LOOK.
6. **Size.** Small (part of finding 1's run).
7. **Capture.** `--speed-trace` on a battleship's 3-hex run, plus frames at 0.05 s around 40% speed.

---

## Not proposed, on purpose

- **Flip and burn.** Ryan ruled it stays off (R64, after the R55 test). Findings 1 and 4 brake with bow retro jets instead.
- **Momentum carried between turns.** A rules redesign, not planned (R55). Every move still starts and ends at rest; findings
  1 and 4 make the start and the stop read as burns instead of as a car pulling away and parking.
- **The comfort option and frame rate (R187, R188).** Nothing here touches reduce flashing. Findings 4 and 12 add puffs and
  small motions; their cost is a few sprites per ship and belongs on the scene gate.

## What I could not determine

- Everything I describe as seen is worked from the code and from my port of the glide's timing and heading; I watched nothing.
  The port leaves out the box filter's effect on heading and uses a hex spacing of 1; the shapes and rates should hold, but
  the exact degrees a second are the port's, to be checked against Codex's motion strips (issue 487).
- Whether the full-circle back-off (finding 2) shows exactly as I describe. It follows from 930 (the short way from a nose left
  about 140 degrees round), but the capture is the proof.
- How often routes cross friendly ships (finding 7), how often the AI ends pointed away (finding 11), and whether the plume blip
  (finding 14) is visible on smaller hulls.
- Whether the 9 and 7.5 unit climbs clip big rocks or capital hulls; that depends on the rock and hull heights, which I did not
  measure.
- Why `MOVE_PER` has the values it has: it came over from sim3d.js with no reason I could find.
- Brisk mode and strike craft were read but not audited: brisk is a player option and wings were outside this issue.
