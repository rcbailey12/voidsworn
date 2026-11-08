# Evidence pack: red team of the Voidsworn destruction, physics feel, and camera gates

Job: a red team of every numeric gate, count limit, timing
constant, and standing assumption in three feel-and-look stacks
of Embers of the Hollow Sun (Voidsworn): destruction (wreck
persistence, debris physics, secondary explosions, derelicts),
physics feel (hit reaction, weapon impulse, ramming, collision,
explosion impulse), and camera and presentation (battle camera
distance, zoom, framing, shake and punch implementation, kill
presentation). Four legs run from this pack: three writer legs
(blind Rey, DeepSeek, Qwen) and one review leg (Argon). The
chair screens every leg before anything is adopted.

This pack is the legs' complete evidence. It is built from
FINDINGS rulings, the breakable ships research (issue 171), the
wreckage kit record (issue 60, ruling R107), the surface detail
standard's break clauses (issue 200, D21 to D25), the frozen JS
battle code, and the Godot battle, fx, and camera code, all read
for this pack. Where this pack and a leg disagree, the pack
wins. Where a source document and this pack's summary of it
disagree, the source wins and the disagreement is a finding.

Relation to the fx audit (Nov 6, 2026): death presentation is
already inventoried there (E3 death budget split, E4 WRECK_COOL,
E5 debris cap as a visual cap, E6 flash budget, E7 death
choreography, E13 emitter arithmetic, E33 hitstop and shake
testing ranges), as are the hit reaction model (A7), the
slow-motion beat (A17), and the draw scale (A19). This pack
REFERENCES those items and does not re-inventory them. Its
subject is the layer underneath: what the wreck and its pieces
physically do, what a hit physically imparts, and what the
camera does while it happens.

## 1. Framing

### 1.1 The owner's instruction

Ryan Bailey, Nov 6, 2026: after the graphics red team and the
effects, animation, and sound audit, he asked what else along
the same lines would be helpful, naming "physics, animation,
motion, backgrounds, other models like asteroids, nebulas,
stations, destruction in general: the things that make it FEEL
and LOOK like a high quality game but we might be artificially
constricting based on arbitrary gates." The environment and
backdrop audit runs as a sibling pack. This pack covers the
destruction, physics feel, and camera slice of that commission,
with all LLMs used (the standing four-prong rule, section 8).

### 1.2 The worked examples, and the rulings that govern this audit

The graphics red team (Nov 6, 2026) inventoried 65 constraints:
MEASURED 4, DERIVED 11, ANCHORED 6, ASSUMED 44. The fx audit the
same day inventoried 76 items across effects, animation, and
sound: MEASURED 13, DERIVED 5, ANCHORED 3, ASSUMED 55. The
worked failure in both was the same shape: an incumbent asset's
measured property, or a demo scene's choreography, promoted by
citation into a law that binds builds. The owner's rulings from
those audits govern this one:

- Assumed and anchored numeric gates stop binding. They are not
  re-derived one by one; they earn their way back only by
  proving themselves in builds. Dispositions in this audit start
  from that ground rule (section 8).
- Tests run uncapped, effects and physics included. Measurements
  exist to find where fidelity can scale UP and where
  performance forces scale DOWN. Numbers are reported
  (triangles, draw calls, surfaces, ms, body counts), never
  treated as pass or fail gates.
- The binding performance limit is the measured scene gate in ms
  on the owner's RTX 5080, set by the owner after the issue 207
  benchmark runs; the first measurement does not become the gate
  by default. Performance target: 60 fps at 4K is the goal,
  flexible as needed, 1440p is the floor (owner, Nov 6, 2026).
- Judgement is the owner's eye on sheets, captures, and in play,
  against the stated objective: AAA style graphics.
- Costs and estimates are stated in agent terms only (section
  1.5). No human-time estimates anywhere (standing rule R99).

Settled rulings this audit must NOT re-open (they are recorded
as facts, not items to re-litigate):

- Breakable by design (R98, R99; issue 171): broken pieces must
  never look empty; real hull thickness, internal decks and
  bulkheads, authored break lines with matching interior faces;
  capitals break on two transverse lines plus one longitudinal.
- Deaths and hits go space-real (R88): fireballs flash and snuff
  out, venting gas, hot metal glowing then cooling, sparks,
  momentum-keeping debris, a longer structural breakup chain.
- The Dead Star is background only, no gravity mechanics
  (owner ruling). PF9 inventories a code ghost against this
  ruling; no leg may propose reinstating gravity play.
- The consolidated movement specification is commissioned
  (issue 210, fx audit ruling R4). Ship movement timing, pace,
  and the glide rule belong to it. This pack inventories physics
  feel only where the spec does not reach, and flags the
  boundary where it is unrecorded (PF10).

### 1.3 This audit's question

For every gate, cap, constant, and standing assumption in the
three stacks, answer three things:

1. What kind of number or rule is it? MEASURED (produced by an
   instrument, a timed run, or a counted test), DERIVED
   (computed from measured or ruled inputs, with the arithmetic
   shown), ASSUMED (a chosen constant or threshold with no
   measurement or derivation in the record), or ANCHORED (the
   property of one incumbent asset, one test scene, one ported
   default, or one external game, promoted into a rule). A code
   constant's existence is verified by reading the code; that
   makes it sourced, not measured.
2. What does it cost if it is wrong, in each of the three
   lenses: game dev (performance or gameplay), domain designer
   (the destruction's read, the motion's weight, the camera's
   framing), agent lead (pipeline effort, enforceability,
   wasted runs)?
3. What measurement, test, or build would settle it, and what
   does that cost in agent terms (section 1.5)?

A gate is artificial, in the owner's sense, when its number
cannot be traced to a measurement or a derivation but it still
binds builds, fails work, or spends review. Where a domain
simply has no number for something a designer would expect one
for (explosion impulse on bystanders, hit direction feedback),
the pack inventories the absence as an item rather than
inventing a value.

### 1.4 Honest scope notes

The three domains have very different shapes of record.
Destruction has real code on two builds (the frozen JS and the
Godot port) and the two builds disagree with each other in
several places; the disagreements are inventoried, not
reconciled. Physics feel is a set of constant tables written by
different jobs at different times, plus a rules layer (ramming)
that is fully arithmetised in code. Camera is one small Godot
file (camera_rig.gd, 194 lines) plus a ported JS controller, and
its central constant (CM1, the 170-unit radius) is load-bearing
far outside the camera: two adopted standards compute their
readability math at that radius. Almost nothing in these three
stacks has ever been measured with an instrument; the tally in
section 2 reflects that, and the legs should treat the zero in
the MEASURED column as a finding to test, not a summary to
repeat.

### 1.5 Cost units

Costs in this pack, and in every leg, are stated only in agent
terms: Codex runs (one-hour cap per run), Opus runs, one-time
script builds, per-asset unattended runs, and owner review
rounds. One-time and recurring costs are stated separately. No
human-time estimates anywhere (R99).

## 2. Evidence base

- FINDINGS (repo contrib/opus/FINDINGS.md, read on main for
  this pack): R88 (deaths and hits space-real; effects may spend
  the RTX 5080 headroom), R96 (paint route and the retired
  ceiling), R98 (broken pieces visibly empty; breakable by
  design on both layers), R99 (breakable research picks adopted;
  R99 also carries the agent-terms estimating rule), R107
  (wreckage kit merged: wreckage fields use ship-derived pieces;
  26 of 26 standing checks), R109 (station detail).
- Issue 171 (closed; read via the connector): the breakable
  ships research commission, R98's build-side method, delivered
  as PR 174 and ruled in PR 176 (all five chair picks adopted).
- Breakable ships synthesis (contrib/muse/research/
  breakable_ships_2026_11/synthesis.md): thickness bands 1 to
  2 m at break lines on the intact ship, decimated dark inner
  liner, break-piece thickness band 0.4 to 0.8 units, interiors
  2 to 3 decks at 0.2 to 0.3 thick, interior albedo 0.01 to
  0.03, centre-of-mass piece origins, one .glb per hull.
- Issue 200 surface detail standard (read on branch
  muse/issue-200, PR 203, including the Nov 6 corrections):
  clauses D21 to D25 (no detail crosses a break line; 1-unit
  break clearance, owner-ruled; liner and interiors exempt;
  damage room inside the paint graph; Chorus interiors), and
  its verification note that break fit needs a mesh with break
  lines marked.
- FX audit pack (Nov 6, 2026), cross-referenced only: E3 to
  E7, E13, E33, A7, A17, A19.
- Code read on main for this pack: battle.js (1,441 lines:
  rules: hulks, ramming, gravity well, chain boons),
  fx3d.js (633: JS death fragmentation, debris batches, wreck
  lifetimes), vfx3d.js (219: secondary explosions on hulks),
  scene3d.js (686: JS camera controller, vignette and grade),
  godot/fx/fx_death.gd (1,453: deaths, debris bodies, wreck
  pieces, secondaries), godot/fx/fx.gd (978: trauma shake,
  punch, hit pause, death slowmo), godot/fx/fx_ship.gd (1,299:
  hit reaction tables), godot/fx/fx_weapons.gd (1,172: weapon
  impulse table), godot/fx/fx_breach.gd (1,855: breach mark
  constants, read for constants), godot/render/camera_rig.gd
  (194, read in full), godot/render/ship_view.gd (1,290: the
  cinematic motion block, lines 447 to 500 read).

Provenance tally for this pack's 40 items: MEASURED 0,
DERIVED 4, ANCHORED 2, ASSUMED 34. Per section: DS 15 items
(DERIVED 2, ASSUMED 13); PF 12 items (DERIVED 2, ASSUMED 10);
CM 13 items (ANCHORED 2, ASSUMED 11). The MEASURED zero is
itself an inventory result: no frame timing, physics step cost,
capture timing, or counted test for any gate in these three
stacks exists in the record read.

## 3. Destruction inventory (DS1 to DS15)

DS1. Visual wreck persistence cap: at most 24 live wrecks in
the Godot build; the oldest wreck is freed when a 25th arrives.
- Lives in: godot/fx/fx_death.gd, _cap_wrecks and _free_wreck:
  while the wreck list holds more than 24, pop the front and
  free its nodes.
- Provenance: ASSUMED. Evidence: a code cap with no recorded
  derivation, no stated interaction with the rules layer (DS2,
  where the same wreck's hex keeps blocking after its visual is
  freed), and no measurement of when it binds.
- If wrong: in a late-battle fleet wipe (20 ships on board),
  early kills visually vanish while their hexes still block;
  or the cap never binds and costs nothing, in which case it is
  dead weight in every death review.
- Settles it: a worst-case battle capture (a full fleet wipe on
  the destruction_fleet_probe that already exists in godot/fx/
  test/) with wreck count logged against the cap, one-time
  script build on the existing probe.

DS2. Rules-side hulk permanence: a dead ship of size 0.7 or
more leaves a hulk hex that blocks movement and line of fire
for the rest of the battle, with no lifetime and no cap.
- Lives in: battle.js line 968 (killUnit sets terrain 'hulk'
  when size >= 0.7 and the hex does not already block) and
  line 10 (terrain meta: "A burning hulk. Blocks movement and
  line of fire.").
- Provenance: ASSUMED. Evidence: the rule is long-standing
  design, but the 0.7 size threshold has no recorded derivation
  and the permanence has never been weighed against DS1's
  visual cap or against late-battle board congestion.
- If wrong: boards clog with invisible-ish blockers late in big
  battles (with DS1), or small ships dying without trace makes
  frigate deaths read as less real than capital deaths.
- Settles it: the same DS1 capture, reporting rules hulks vs
  visual wrecks side by side; any change to the threshold is an
  owner ruling on that capture, one owner review round.

DS3. Cooling and wreck lifetime, two builds, two numbers: the
Godot build cools a wreck over WRECK_COOL 14.0 s (fx audit E4);
the JS build disposes non-persistent wreck nodes at age 22 s
and stops persistent wrecks burning at age 25 s, with smoke
rate decaying from 40 per second after age 6 s.
- Lives in: godot/fx/fx_death.gd line 18 (cross-reference
  fx E4); fx3d.js lines 509 to 516 (hulk update: burn-out at
  25 s if persistent, disposal at 22 s if not).
- Provenance: ASSUMED. Evidence: three constants across two
  builds for the same phenomenon, none compared against the
  others or against how long a battle round actually lasts.
- If wrong: the owner's playtest rulings about death feel
  describe whichever build he played, and the port silently
  picks a different tail.
- Settles it: one death sheeted at both lifetimes in the
  current build, one owner review round (shares fx E4's
  settlement; the new content is the cross-build discrepancy).

DS4. Debris physics bodies: the Godot debris pool is 360
Jolt RigidBody3D bodies (fx audit E5 inventories the count as
a visual cap), recycled round-robin, colliding with hulls and
with each other.
- Lives in: godot/fx/fx_death.gd lines 14 to 17 (layers and
  DEBRIS_CAP 360), 290 to 337 (spawn: pool, collision layer 2,
  mask hull layer 1 plus debris layer 2).
- Provenance: ASSUMED. Evidence: this pack's angle is new: the
  cap is also a physics step cost cap (360 rigid bodies with
  mutual collision), and no physics step timing at or near the
  cap exists in the record read. E5's settlement (a visual
  capture) would not measure this.
- If wrong: the frame cost that binds first in a multi-death
  frame is the physics step, not rendering, and the scene gate
  work in issue 207 will misattribute it.
- Settles it: the fx_cost_probe or destruction_fleet_probe
  extended to report physics step ms at 360 bodies, one-time
  script build; the number feeds the issue 207 scene family.

DS5. Debris spawn counts, two formulas: Godot spawns
4 + weight x 3 loose debris per death; the JS build spawns
round(10 + hull length x 0.8) pieces per death, of which the
first 7 (3 on medium quality, 0 in reduced mode) are hero
embers, the rest wreck shards, into per-faction batches capped
at 320 instances each (140 on mobile).
- Lives in: godot/fx/fx_death.gd line 1184 (spawn_debris call);
  fx3d.js lines 519 to 535 (debBatch caps, debris count and
  hero split).
- Provenance: ASSUMED. Evidence: two unrelated count formulas
  for the same event; neither is derived from the DEBRIS_CAP
  either build carries, and neither states what a capital death
  should look like in pieces.
- If wrong: capital deaths either starve (13 loose pieces from
  the Godot formula at weight 3) or flood the batch and evict
  earlier deaths' debris mid-battle (the JS shift() eviction).
- Settles it: one capital death and one frigate death captured
  in the current build with piece counts reported, one owner
  review round.

DS6. Debris motion constants: Godot debris inherits the dead
ship's velocity plus a random planar kick of 2.0 to 6.0 units
per second, tumbles at a uniform random angular velocity of
-6 to 6 radians per second per axis, and never slows (linear
and angular damp both 0.0, gravity scale 0). The JS build's
fragments fly at 1.6 to 4.2 units per second, halved for
persistent wrecks.
- Lives in: godot/fx/fx_death.gd lines 310 to 337; fx3d.js
  line 445 (fragmentHull velocity) and line 497 (two-piece
  split velocity).
- Provenance: ASSUMED. Evidence: 6 rad/s is about one full
  revolution per second; with damp at 0 the first second's
  energy is the whole battle's energy. R88's "momentum-keeping
  debris" is the design intent; no capture has ever judged
  whether these constants deliver it.
- If wrong: debris reads as either pinwheels or statues, and
  because damp is 0 there is no middle state to tune into
  without changing the constants themselves.
- Settles it: one death capture at the shipped constants and
  one at halved tumble with damp 0.3, one owner review round.

DS7. Wreck piece physics, and the capital freeze: hull break
pieces become rigid bodies only when the fx state's physics_on
flag is set; piece mass is maxf(piece triangles / 400, 5.0);
linear and angular damp are 0; and capital pieces (death_big,
non-organic) are FROZEN outright.
- Lives in: godot/fx/fx_death.gd, the piece build block (about
  lines 1204 to 1225): gravity_scale 0, axis_lock_linear_y,
  mass from triangle count, freeze = death_big and not
  organic, collision on the debris layer.
- Provenance: ASSUMED. Evidence: an implementation choice with
  no recorded measurement or owner judgement. Its consequence
  is stark: the showcase capital deaths, which DS14's constants
  spend the most on, produce pieces that do not move at all in
  physics mode, while frigate pieces tumble.
- If wrong: the biggest deaths read as statues next to lively
  small deaths, the exact inversion of the intended spectacle
  order (and of R88's longer structural breakup chain).
- Settles it: one capital death captured frozen and unfrozen
  in the same build, one owner review round; the physics step
  cost of unfrozen capital pieces reported with it (one-time
  script build on the existing probe).

DS8. Piece separation speeds: break pieces separate at 3.5
(organic), 2.8 (big), 0.7 (the main piece), or 2.1 (other
pieces) units per second, scaled by maxf(k, 0.5), plus the
inherited death velocity and a random 0.3 x k jitter.
- Lives in: godot/fx/fx_death.gd, the separation block (about
  lines 1256 to 1270); split_width for the seam read is
  hull length x 0.04.
- Provenance: ASSUMED. Evidence: four hand-set speeds with no
  derivation; the main piece at 0.7 barely leaves the wreck
  centre, which may be the intended "drifts in place" read of
  battle.js line 968's log text, or may be why deaths can read
  as sudden and static (the R88 complaint).
- If wrong: breakups either crawl (pieces never clear each
  other, reading as one sagging hull) or scatter (the wreck
  stops reading as a ship).
- Settles it: the DS7 capture covers it (same build, speeds
  reported); one owner review round, shared.

DS9. Secondary explosions: on capitals, exactly two secondary
opportunities, at staged cuts 1 and 2, firing 0.08 s after the
cut, each a core flash of size hull length x 0.06 at strength
24.0. The code comment states the intent: "never a per-piece
fire loop." The JS build instead keeps fresh hulks cooking
off with small secondary explosions and no count cap in the
lines read.
- Lives in: godot/fx/fx_death.gd lines 1347 to 1349 and
  _secondary at line 1390; vfx3d.js line 82 (cook-off comment).
- Provenance: ASSUMED. Evidence: the count of two and the
  0.08 s delay are chosen constants; the two builds implement
  two different secondary regimes for the same deaths.
- If wrong: capitals either pop once and go quiet (underdone
  for the game's biggest event) or cook off indefinitely
  (noise, and flash budget pressure against fx E6).
- Settles it: one capital death captured at two secondaries
  and at a capped cook-off, judged against the E6 flash count,
  one owner review round plus the E6 salvo test's flash
  logging (one Codex run, shared with the fx settlement).

DS10. Chain explosions are boon-gated, not physical: a killed
ship damages its neighbours only when its killer carries the
chainBoom boon (flat damage to same-side ships within 2 hexes,
plus chainFire setting them burning for 2 rounds at fireDmg
at least 6). A weapon-side analogue exists (chainSh and spread
patterns, battle.js lines 829 and 862 to 863). No general rule
makes a capital's death dangerous to bystanders.
- Lives in: battle.js lines 974 to 975 (killUnit chain block).
- Provenance: DERIVED. Evidence: the arithmetic is stated in
  code inside the boon system; what is inventoried is the
  boundary: the general case (no boon) is silence, and no
  document read states whether that silence is a design
  decision or an unmade one.
- If wrong: either death positioning never matters tactically
  outside one boon build, or a future chain rule lands without
  ever having been weighed against formation play (the
  Hegemony flagship-anchor ruling makes formations matter).
- Settles it: an owner direction question (section 8 legs will
  price it); no build settles a decision that has not been
  recorded as made.

DS11. Fire spread: fire exists as a ship state (st.fire,
st.fireDmg, set by chainFire) and as damage-surface stages
(fx_breach S_BURN; fx_ship stage ladder), but no mechanism in
the record read spreads fire from a burning ship to a
neighbour, a wreck, or terrain outside DS10's boon.
- Lives in: battle.js (fire state fields; set at line 975);
  godot/fx/fx_breach.gd line 41 (S_BURN) and line 59 (GROW_MAX
  1.6, how far repeated hits can grow a damage mark).
- Provenance: ASSUMED by absence. Evidence: the missing
  parameter is the item; fire is a per-ship timer everywhere
  it exists, and the record contains no statement that this is
  deliberate.
- If wrong: burning ships parked in a formation are safe,
  which undercuts the venting and burning read R88 asked for;
  or spread gets added later without a gate ever being set.
- Settles it: folds into the DS10 owner question; if the owner
  wants spread, its constants are set by capture, not by this
  audit.

DS12. The derelict interaction set: wrecks block movement and
line of fire (DS2); set-piece wrecks, giant asteroids, and
moons fill SOLID hexes blocking both (battle.js line 92);
graveyard maps scatter up to 7 pre-placed wreck spots at least
3 hexes apart (battle.js line 235); the colossus map shape is
a giant wreck set piece (battle.js line 18); a ship that
cannot stop on a wreck hex may climb over or dive under it
(battle.js line 427). Wrecks cannot be targeted or shot in any
rule read, and in-battle salvage does not exist: the only
salvage reference (battle.js line 947) is campaign salvage
reading the kill words and whether the wreck is scrap.
- Lives in: battle.js lines 10, 18, 92, 235, 427, 947, 968.
- Provenance: ASSUMED. Evidence: the placement constants (7
  spots, 3 hexes) are chosen numbers, and the interaction set
  as a whole has no single ruling behind it; it accreted.
- If wrong: the board's most common obstacle class is also its
  least examined, and terrain builds (#139, #140, #100)
  inherit placement constants nobody chose deliberately.
- Settles it: one graveyard and one colossus battle played by
  the owner with wreck density reported, one owner review
  round; placement constants re-set from that play if at all.

DS13. Break geometry clauses D21 to D25 (cross-reference, not
re-inventory): no detail crosses an authored break line (D21);
1-unit break clearance with reserved rim bands (D22,
owner-ruled Nov 5, 2026); liner and interiors exempt (D23);
damage room inside the paint graph (D24); Chorus flesh and
bone (D25). Break-piece thickness band 0.4 to 0.8 units and
rim bands 1 to 2 m wide on the intact ship (issue 171
synthesis).
- Lives in: issue 200 synthesis sections D21 to D25 (branch
  muse/issue-200); issue 171 synthesis sections 2 to 4.
- Provenance: DERIVED. Evidence: D21 derives from R98 and R99;
  the D22 distance is labelled INFERRED in its own standard
  and was owner-ruled; the 171 bands are the adopted method's
  starting values, stated there as tuned at close zoom in the
  169 recordings.
- This pack's angle only: break lines are where DS7 and DS8's
  physics happen, so a geometry clause is also a physics
  clause. If a leg finds a destruction consequence the
  standards missed (a piece too thin to read as a rigid body,
  a seam width that swallows the hot edge), that is a finding;
  otherwise these clauses are KEEP by reference and are not
  re-litigated here.
- Settles it: nothing new; the 169 build's own recordings are
  the standing settlement.

DS14. Capital versus small destruction, as a set: cut count 3
for flagships and the named capital classes against 2 for
everyone else (godot/fx/fx.gd, add_ship); the drift-and-cool
beat lands at 1.6 s for big hulls against 0.85 s (fx_death.gd
line 34); death shake 0.45 against 0.18 and punch 0.018
against 0.006 (fx_death.gd, about line 1185); kill slow
motion only for death_big, decided by class not draw scale
(fx_ship.gd line 26, R73); the JS hulk threshold at size 0.7
(DS2); piece separation and freeze split by the same big flag
(DS7, DS8).
- Provenance: ASSUMED. Evidence: each constant is individually
  unsourced; as a set they define the game's spectacle order
  (capitals should die biggest), and no capture has ever
  compared a capital death and a frigate death side by side
  against the whole set at once.
- If wrong: the order inverts somewhere (a frigate that shakes
  harder per unit size, a capital whose pieces freeze while a
  frigate's tumble), and each constant looks fine alone.
- Settles it: one paired capture, capital and frigate deaths
  at shipped constants, one owner review round. This is the
  cheapest high-information test in the pack.

DS15. Live-ship colliders exist for debris, not for ships:
one convex collider per live ship, built from 50 hull sample
directions, rides the ship root so debris bounces off hulls.
Debris collides with hulls and debris; live ships have no
physics collision with each other or with wrecks at all (the
rules layer handles occupancy by hex, PF8).
- Lives in: godot/fx/fx_death.gd line 460 (the collider
  comment), line 349 (_HULL_DIRS 50), lines 314 to 315 and
  1221 to 1222 (collision layers and masks).
- Provenance: ASSUMED. Evidence: 50 sample directions is a
  code constant with no recorded accuracy check (does debris
  visibly clip hulls between samples?) and no cost figure.
- If wrong: debris passes through hull edges on camera, which
  reads as cheap exactly where R88 asked for physical debris;
  or the colliders are overbuilt for an effect nobody sees.
- Settles it: the DS4 probe reports collider cost with the
  body count; one close-range death capture judged for
  clipping, shared with DS6's review round.

## 4. Physics feel inventory (PF1 to PF12)

PF1. Hit reaction mass table: a hit's shove is resisted by
REACT_MASS [0.6, 1.0, 2.2, 5.0, 12.0] across the five weight
classes (craft, light, medium, heavy, capital). The code
comment states the intent: capital ships barely move.
- Lives in: godot/fx/fx_ship.gd, hit reaction block (the R50
  reaction), about lines 520 to 545.
- Provenance: ASSUMED. Evidence: the fx pack's A7 inventoried
  the reaction model with no magnitudes anywhere; the
  magnitudes exist here in code, hand-set, with the top of the
  table 20 times the bottom and no capture behind any entry.
- If wrong: the whole weight read of the game is off; a table
  20 percent softer makes capitals feel like frigates, and
  every weapon's impulse (PF3) is denominated against this
  table, so the error multiplies.
- Settles it: one ship of each weight class hit by the same
  weapon, captured side by side, one owner review round.

PF2. Reaction timing tables: onset [0.03, 0.05, 0.08, 0.12,
0.16] s, arrest [0.35, 0.5, 0.7, 0.95, 1.2] s, recovery
[3.6, 3.0, 2.4, 1.9, 1.5] rad/s critically damped, shudder
[11, 9, 7, 5, 4] Hz lasting [0.16, 0.2, 0.28, 0.38, 0.5] s,
all by weight class. Designed in the r4 review against the
R50 complaint (hits felt like a "simple cartoonish push
back"): onset kick, thruster arrest at a steady rate, slow
recovery without overshoot.
- Lives in: godot/fx/fx_ship.gd, same block (REACT_ONSET,
  REACT_ARREST, REACT_RECOVER, REACT_SHUDDER_HZ,
  REACT_SHUDDER_T).
- Provenance: ASSUMED. Evidence: a designed table answering a
  feel complaint, never A/B captured; recovery at 1.5 rad/s
  for a capital means a kicked capital is still visibly
  recovering seconds later, which interacts with turn pacing
  in ways no document examines.
- If wrong: either the cartoon push back survives in a more
  expensive costume, or capital recoveries drag across the
  next activation and read as damage they are not.
- Settles it: the PF1 capture set, judged per class; one
  owner review round, shared.

PF3. Weapon impulse table: REACT_IMPULSE gives torp 6.0,
star 6.5, ram 8.0, rockets 2.0, macro 1.0, plasma 0.7,
gauss 1.6, and 0.5 for anything unlisted; the delivered
impulse scales by weapon weight class [0.7, 0.85, 1.0, 1.3,
1.6] and by 1.6 on a critical.
- Lives in: godot/fx/fx_weapons.gd line 50 (the table) and
  line 774 (the scaling in the hit path).
- Provenance: ASSUMED. Evidence: the table embeds an ordering
  claim (a star bolt shoves harder than a torpedo; only a ram
  shoves harder than either) that no document argues; the
  crit multiplier makes a lucky plasma hit (0.7 x 1.6) shove
  like a macro cannon.
- If wrong: weapon identity blurs; the weapons a player
  expects to feel heavy do not, and the reaction system (PF1,
  PF2) gets blamed for the table's choices.
- Settles it: one firing range capture per weapon kind
  against the same target class, one owner review round.

PF4. Ram damage arithmetic: base damage (14 + 46 x size),
scaled by run-up (0.75 at one hex, 1.0 at two, 1.15 at three
or more), by 1.2 for the ramming factions (RAM_FAC:
voidsworn, corsair, chorus, battle.js line 89), by 1.2 again
if the struck shield facing is the zero facing, reduced by
the target's armor at half rate, soaked by the facing shield
up to half the raw damage, and capped at 40 percent of the
target's full hull (plus up to 30 percent more from the
ramCap ship effect). The code comment states the intent:
"rams hit hard but can't one-shot a healthy ship."
- Lives in: battle.js lines 891 to 893 (ramEstimate).
- Provenance: DERIVED. Evidence: the arithmetic is fully
  stated in code; every constant inside it (14, 46, the
  run-up steps, the 40 percent cap) is a chosen value with no
  simulation or playtest citation in the record read. This is
  a game-feel gate wearing rules clothing: it decides how a
  ram FEELS (a finisher, not an opener) as much as what it
  costs.
- If wrong: rams are either a dominant opener the cap was
  meant to prevent, or a trap option the AI keeps pricing
  wrong (PF6), and the log line ("rams at full speed") keeps
  promising more than the arithmetic delivers.
- Settles it: a Monte Carlo over the shipped fleet tables
  reporting ram outcomes by matchup (one-time script build on
  the existing sim), judged against the stated intent; any
  re-tune is an Opus rules call on that evidence.

PF5. Ram recoil and splash: the rammer takes back base x 0.5
(0.35 for RAM_FAC factions) x clamp(target size / rammer
size, 0.5, 1.6), reduced by its own armor and ramGuard. The
ramSplash boon splashes a fraction of the ram damage to the
target's same-side neighbours at distance 1, and can kill
them (killUnit is called).
- Lives in: battle.js line 893 (recoil in ramEstimate) and
  line 906 (ramSplash in ramUnit).
- Provenance: DERIVED. Evidence: stated arithmetic on assumed
  constants, like PF4; the recoil asymmetry (0.35 vs 0.5) is
  the faction identity of the ramming factions expressed as a
  physics discount, and no document weighs it as one.
- If wrong: ramming factions either shrug off their own
  signature move or pay so much that the AI's appetite
  thresholds (PF6) misfire for exactly the factions built to
  ram.
- Settles it: the PF4 Monte Carlo reports recoil outcomes in
  the same run; no extra cost.

PF6. Ram gating and AI appetite: a ram needs an enemy dead
ahead of the bow, at least one clear hex of run-up, and
movement left to cover the gap; squadrons, braced ships,
crewless ships, and ships that have already rammed this
battle are excluded. The AI rams only with a run-up of at
least 2 hexes and only when the estimate kills, or reaches
30 percent of target hull for ramming factions, 45 percent
for everyone else.
- Lives in: battle.js lines 879 to 888 (ramInfo, ramFrom)
  and 941 to 942 (tacticRam).
- Provenance: ASSUMED. Evidence: the 30 and 45 percent
  appetite thresholds are chosen constants; they decide how
  often the player ever SEES the game's most physical move,
  which makes them presentation gates as much as AI gates.
- If wrong: rams are either a rarity the player never learns
  to fear or a spam the log narrates every round.
- Settles it: the PF4 Monte Carlo plus a count of rams per
  battle in bot campaigns (the G3 campaign harness exists);
  appetite changes are an Opus call on those counts.

PF7. Explosion impulse on bystanders: none. Deaths impart
velocity to their own pieces (DS8) and loose debris (DS6);
no code read imparts any shove, drift, or attitude change to
nearby live ships when a ship dies next to them. The only
bystander effects are damage routes, both boon-gated (DS10,
PF5).
- Lives in: the absence across godot/fx/fx_death.gd (1,453
  lines read), godot/fx/fx_ship.gd's reaction entry points
  (hit_react is called from weapon hits), and battle.js's
  killUnit.
- Provenance: ASSUMED by absence. Evidence: the missing
  parameter is the item. The largest visual event in the game
  is physically silent to the ships beside it.
- If wrong: capital deaths feel smaller than frigate deaths
  at formation range, which may be the physical half of the
  R88 complaint ("deaths feel sudden, jerky") that the
  choreography items (fx E7) cannot fix alone.
- Settles it: one capture with a capital dying inside a
  formation, with and without a prototype impulse, one owner
  review round (prototype is one Codex run).

PF8. Collision response between ships and objects: the rules
layer is hex occupancy (passable, blocks); a ship may climb
over or dive under a rock, wreck, or enemy ship it cannot
stop on (battle.js line 427), so rules collision is
pass-through with altitude flavour. The presentation layer
has no ship-to-ship or ship-to-wreck physics at all (DS15);
the only physical collisions in the game are debris against
hulls and debris.
- Lives in: battle.js line 427 and the passable/blocks
  machinery; godot/fx/fx_death.gd collision layers.
- Provenance: ASSUMED by absence. Evidence: no numbers exist
  for any of it, and no document read states whether
  pass-through is a deliberate readability choice (ships on a
  hex board) or an unmade physics decision.
- If wrong: formations interpenetrate visually at close zoom
  in a game whose camera goes to 26 units (CM2), and the
  owner discovers it in a screenshot rather than in a ruling.
- Settles it: one close-zoom formation capture judged by the
  owner; if it reads badly, the fix is a presentation offset
  rule, not a physics engine, and is priced then.

PF9. The gravity well ghost (settled ruling, live code): the
owner ruled the Dead Star background only, no gravity
mechanics. The frozen JS still implements a full well:
WELL_RIM 3, WELL_PULL 5, WELL_ASSIST 6, WELL_DMG 7
(battle.js line 291): inside 6 hexes a ship gains +1
movement (slingshot), inside 5 it is dragged one hex toward
the well at turn end, on the rim (3) it takes 7 hull damage
per turn and can die with killCause 'tidal'. The Godot fx
layer carries the hook too: fx.well holds the dead star's
position and tidal deaths gain +3.0 velocity toward it
(godot/fx/fx.gd line 44; fx_death.gd lines 1265 to 1266).
Whether the Godot RULES port implements wellTick could not
be verified from the files read (section 7).
- Provenance: the mechanic's constants are ASSUMED; the
  ruling against it is the owner's and stands. The item is
  the contradiction: a settled no with a yes still compiled
  into the frozen build and a port-side fx hook waiting for a
  rules decision that was already made the other way.
- If wrong (that is, if the port quietly carries it): a
  ruled-out mechanic ships by inheritance, and the owner's
  background-only Dead Star starts dragging ships in a build
  he never playtested for it.
- Settles it: one Opus run to state the Godot rules state and
  remove or confirm removal. No leg may propose reinstating
  gravity play; that question is closed.

PF10. Cinematic move presentation constants (physics-feel
half): ship_view.gd's motion block (R50 round 2, "Movement:
cinematic") carries a mass parameter clamped 0 to 1,
default 0.5, shared across the move's segments by weight; a
settle overshoot of about 4 percent of hull length capped at
2.5 percent of the run; turn settle 0.03; thruster behaviour
rules (main drive only while pushing ahead, retro jets for
braking, lateral pairs for sidesteps, no banking).
- Lives in: godot/render/ship_view.gd lines 447 to 500.
- Provenance: ASSUMED. Evidence: designed constants from the
  Oct 27 ruling's implementation. The boundary item: the
  consolidated movement specification (issue 210) owns move
  timing and pace, and no document read states which of these
  presentation constants it inherits, replaces, or leaves
  behind. Two mass systems also coexist: this block's 0 to 1
  mass and PF1's REACT_MASS table are unrelated definitions
  of how heavy a ship is (see H5).
- If wrong: the movement spec lands and the presentation
  layer quietly keeps its own physics, so battles still feel
  like the old constants while the spec says otherwise.
- Settles it: one Opus run adding a boundary note to the
  issue 210 job naming which constants the spec governs;
  captures are the spec's own settlements, not this audit's.

PF11. Momentum inheritance and the shove cap: break pieces
and hulks inherit the ship's death_velocity (fx_death.gd
lines 941, 1017, 1042); a hulk's fires drift at 0.45 along
the hull's axis with angular velocity (0.01, 0.035, 0.015)
(fx_death.gd lines 1131 to 1134); in the JS build a shoved
ship's coast is capped at about a tenth of a hex (coast
start caps the slide at hex width x coastCap 0.05, fx3d.js
lines 100 to 101) so a hit can never push a ship off its hex.
- Provenance: ASSUMED. Evidence: R88's "momentum-keeping
  debris" is the intent; the constants implement it in three
  places with three different scales, and the JS coast cap
  means the reaction tables (PF1, PF2) play out inside a
  tenth of a hex no matter what impulse arrives.
- If wrong: reactions read as vibration rather than motion
  (the cap), or hulks drift off their rules hex and the board
  state and the picture disagree (DS2's hex stays; the Godot
  hulk's drift is visual only).
- Settles it: the PF1/PF2 capture set shows slide distances
  against the cap; one owner review round, shared.

PF12. Squadron physics: not inventoried. Squadron craft have
their own Godot files (godot/render/squadron_craft.gd,
squadron_wing.gd), which were not read for this pack, and
the fx audit (A15, A16) already found squadron animation has
no dedicated numbers. Whether wings have any inertia,
separation, or collision model is unknown from the record
read and is listed in section 7 rather than invented here.
- Provenance: unclassified by design; the gap is the item.
- Settles it: one Opus run to read the two files and state
  whether a model exists; if none does, squadron physics
  joins the movement spec's scope question (PF10).

## 5. Camera and presentation inventory (CM1 to CM13)

CM1. The 170-unit camera radius: the Godot rig's default and
home radius are both 170.0 units, ported from the JS CamCtl
(the file header says so). Every px-per-unit figure the
project's standards rely on is computed at this radius: 7.7 px
per unit at 1080p, about 15.4 px per unit at 4K (carried from
the issue 51 and 135 research into the breakable synthesis
and the damage work).
- Lives in: godot/render/camera_rig.gd lines 9 to 12 (r and
  home_r 170.0); the derivations live in the fx pack's E10
  and A19 and in contrib/muse/research/breakable_
  ships_2026_11/synthesis.md section 2.
- Provenance: ANCHORED. Evidence: a ported incumbent default,
  promoted by citation into the readability constant for two
  adopted standards, never itself judged as a framing choice
  at 4K on the owner's screen. This is this audit's candidate
  for the anchor pattern in its purest form.
- If wrong: two standards' worth of readability arithmetic is
  denominated at a distance the owner may not actually play
  at, and every "too small to read" conclusion inherits the
  error multiplicatively.
- Settles it: the owner plays one battle at 170 and one at a
  pulled-back radius and rules his actual default; the
  standards then re-denominator at the ruled radius (one
  owner review round, one Opus run to restate the figures).

CM2. Zoom range: wheel zoom clamps radius between min_r 26.0
and 900.0, stepping by a factor of about 1.14 per notch.
- Lives in: godot/render/camera_rig.gd (min_r line 15;
  handle_input wheel block).
- Provenance: ASSUMED. Evidence: at 900 units the whole board
  (bounds 300 x 220) is a backdrop and a capital ship is
  about 40 px long at 1080p by CM1's arithmetic (see CM13);
  at 26 units a frigate overfills the screen. Neither end has
  a recorded judgement, and no readability rule is stated for
  any zoom level (CM13).
- If wrong: players live at a zoom end the project's
  readability math never covered, and screenshots at those
  ends get judged against standards computed at 170.
- Settles it: folds into the CM1 play ruling (the owner finds
  his ends while finding his default); any clamp change is
  one Opus run.

CM3. Projection constants: FOV 45, near plane 0.5, far plane
5000, fixed except when the punch moves FOV (CM6).
- Lives in: godot/render/camera_rig.gd _ready.
- Provenance: ASSUMED. Evidence: ported defaults; FOV 45 at
  radius 170 is half of what "170 units" means on screen, and
  no document separates the two choices.
- If wrong: the framing feel blamed on radius (CM1) is
  actually the FOV, and tuning one without the other chases
  the wrong constant.
- Settles it: the CM1 ruling states the pair (radius and FOV)
  the owner actually plays; no separate test.

CM4. Orbit, pan, and the near-top-down floor: azimuth free;
polar angle b clamped 0.05 to 1.36 radians, home 0.98; the
top-down toggle goes to 0.05, which is about 3 degrees off
vertical, not vertical; orbit sensitivity 0.0055 horizontal
and 0.0045 vertical per pixel; pan speed scales with radius
(r / 340); a left-drag becomes a pan only after 6 pixels of
movement; pan target clamped to bounds 300 x 220.
- Lives in: godot/render/camera_rig.gd (orbit, pan_by,
  toggle_top, handle_input, bounds line 14).
- Provenance: ASSUMED. Evidence: a full camera-feel set,
  ported and hand-set, none of it ever captured or compared;
  the 0.05 floor means the "top-down" tactical view is
  quietly oblique, which matters on a hex board.
- If wrong: the tactical read the owner thinks he is getting
  from top-down is a 3-degree lie, and pan speed at high zoom
  (r / 340 at r 900 is 2.6 units per pixel-drag unit) makes
  the far zoom end unusable for fine framing.
- Settles it: judged inside the CM1 play ruling; constants
  re-set from that play if at all.

CM5. Smoothing and glide: the camera approaches its target
exponentially at rate 7.0, slowed to 1.7 while a glide is
active; glide duration defaults to 1.1 s; a glide only ever
pulls zoom in, never out; focus() snaps the target with no
glide. The JS controller framed shots with a 4-second slow
window (scene3d.js line 361).
- Lives in: godot/render/camera_rig.gd (glide, focus,
  _process); scene3d.js lines 352 to 374 (CamCtl shot
  framing).
- Provenance: ASSUMED. Evidence: these rates ARE the camera
  feel; 1.1 s against the JS 4 s is a fourfold disagreement
  between builds about how stately a hand-over should feel,
  and no capture has judged either.
- If wrong: hand-overs either whip (interrupting the
  player's read of the board) or drift (taxing every
  activation), and the cost lands on the movement spec's
  pacing work (issue 210) which does not own these constants
  (PF10's boundary problem again).
- Settles it: one hand-over captured at both rates, judged
  in the CM1 play ruling's round.

CM6. The punch: a separate FOV kick channel. Punches live
0.6 s, envelope rising by 0.05 s and out by 0.6 s; summed
kick is capped at 0.06 and applied as camera.fov x (1 - k),
so the largest possible punch narrows FOV by 6 percent.
Deaths punch 0.018 (big) or 0.006; the channel is distinct
from shake (CM7) and from hit pause (CM8).
- Lives in: godot/fx/fx.gd (_update_punch, about lines 613 to
  640); godot/fx/fx_death.gd about line 1185 (death punch
  amounts).
- Provenance: ASSUMED. Evidence: a designed envelope with
  hand-set amounts; 6 percent of 45 degrees is 2.7 degrees,
  and no document or capture states whether that reads as a
  kick or as nothing at battle distance.
- If wrong: the only directed camera gesture the game has
  (CM12) is either invisible or seasick, and deaths lose
  their one framing accent.
- Settles it: the DS14 paired capture shows punches at
  shipped amounts; one alternate at double, judged in the
  same owner review round.

CM7. Trauma shake, the shipped values (beyond fx E33): the
fx pack inventoried the A5 testing ranges (shake 0.15 to
0.30 s, 0.35 to 0.45 s for capital destruction) as unresolved
disagreements. The shipped implementation has since picked:
trauma accumulates with distance falloff 1 / (1 + d /
(120 x unit)), decays at delta x 2.4 (the code comment: about
0.3 s from a normal hit, 0.45 s from the heaviest, citing
the A5 ranges), amplitude is 0.06 x trauma squared, applied
as camera h/v offset x unit x 10. Event amounts: weapon fire
0.03 to 0.08, a ship hit 0.18, a death 0.45 big or 0.18.
- Lives in: godot/fx/fx.gd lines 538 to 609 (shake, trauma
  update); godot/fx/fx_weapons.gd lines 216, 292, 353, 817;
  godot/fx/fx_ship.gd line 476; godot/fx/fx_death.gd about
  line 1185.
- Provenance: ASSUMED. Evidence: the values sit inside and
  outside the E33 ranges with no document recording the
  picking; the 120-unit falloff means a death at the board's
  far edge still delivers about 40 percent of its shake
  (INFERRED arithmetic: 1 / (1 + 170 / 120) is about 0.41 at
  the default radius), which is a framing decision nobody
  made on purpose.
- If wrong: either distant battles jitter the player's own
  framing (falloff too flat) or nearby deaths feel muffled
  (amounts too low after squaring), and E33's ranges get
  blamed for an implementation they never specified.
- Settles it: one battle capture with shake amounts logged
  per event against distance, judged in the DS14 round; the
  E33 settlement (range ends played by the owner) absorbs
  the ranges, this item adds the falloff and the amounts.

CM8. Hit pause, the shipped values (beyond fx E33 and A17):
the effect clock (never Engine.time_scale, input never
blocked) slows to depth 0.08 (8 percent of normal speed)
inside a pause window set at 8 percent of the punch
duration, easing back at lerp 0.6 per frame. Death slow
motion is a separate channel: 0.48 s at speed 0.35, gated so
it cannot retrigger while a hurry window is active.
- Lives in: godot/fx/fx.gd lines 220 to 228 (step), 548 to
  555 (death_slowmo), and the pause block in _update_punch.
- Provenance: ASSUMED. Evidence: fx E33 recorded hitstop
  testing ranges of 2 to 6 frames (normal) and 7 to 12 frames
  (kills); a depth of 0.08 sustained over a punch envelope is
  a far heavier stop than 12 frames at full depth, and no
  document reconciles the shipped feel with the recorded
  ranges. A17's slow-motion beat (50 to 80 percent speed
  proposals) likewise never met the shipped 0.35.
- If wrong: hits either stutter the whole board's clock
  (every weapon shares the effect clock the pause slows) or
  the kill beat lands softer than the ranges promised.
- Settles it: the E33 settlement battle (range ends played
  by the owner) with the shipped values as the third
  candidate; one owner review round, shared with fx.

CM9. Framing rules: a hand-over needs no camera move when
the ship sits inside the central band (sees(), margin 0.22,
so the middle 56 percent of the screen both ways); scripted
framing uses sees_in() to keep action inside the screen
fractions the HUD panels leave clear; the JS overview shot
framed at radius clamp(max(hull length x 1.55, spread x
2.3), 170, 380).
- Lives in: godot/render/camera_rig.gd (sees, sees_in);
  scene3d.js line 374 (overview framing).
- Provenance: ASSUMED. Evidence: the HUD-clear fractions are
  the only place HUD layout constrains the camera, and they
  live in code, not in any UI standard; the 170 floor in the
  JS overview formula is CM1's anchor appearing a second
  time, as a minimum framing radius.
- If wrong: hand-overs glide pointlessly (margin too tight)
  or leave acting ships at the screen edge under panels
  (margin too loose), every activation, all game.
- Settles it: judged in the CM1 play ruling from the owner's
  own hand-over experience; the fractions get restated in
  the UI record if they change.

CM10. The frozen build's presentation layer: the JS build
runs an image-processing pipeline with vignette weight 2.0
and stretch 0.2 and a cinematic color grade (teal shadows,
warm highlights). No Godot equivalent was found in the files
read; the Godot board preloads a board look trial (A holo,
B living, C cinematic plus tactical) whose state this pack
could not verify.
- Lives in: scene3d.js lines 31 to 32; godot/render/board.gd
  line 7 (the board look preload comment).
- Provenance: ASSUMED constants, ANCHORED on the JS build.
  Evidence: a whole presentation layer (vignette and grade)
  whose port state is unknown from the record read; the
  owner's screenshot judgements were made against one build
  or the other at different times.
- If wrong: the game's "look" the owner approved in JS
  screenshots is not the look the Godot build ships, and
  nobody can say when the grade was lost or whether it was.
- Settles it: one Opus run to state the Godot post state;
  if absent, one screenshot pair (JS grade vs Godot current)
  judged by the owner, one owner review round.

CM11. Hit direction feedback: none found. No directional
damage indicator, edge flash, or off-screen hit cue exists
in any file read. Feedback for being hit is the hull's own
damage visuals, positional shake at the hit point (CM7),
floating text, and the log.
- Provenance: ASSUMED by absence. Evidence: the missing
  parameter is the item; at the default radius (CM1) much of
  a 20-ship board is at the screen edge or beyond during a
  zoomed activation, and the record contains no statement
  that the absence is deliberate.
- If wrong: players learn about flank damage from the log,
  a beat late, in a game whose faction design (Hegemony
  facings, shield quadrants) is built on direction mattering.
- Settles it: an owner direction question; if wanted, the
  cheapest form (edge cue toward the shooter) is one Codex
  run prototyped inside the CM7 capture round.

CM12. Kill presentation: no kill-cam, no letterboxing, no
scripted death camera move exists in any file read. A death
plays at whatever framing the player happens to have; the
only directed gestures are the punch (CM6), the slow motion
(CM8), and the hand-over glide system (CM5), none of which
targets a death.
- Provenance: ASSUMED by absence. Evidence: the fx audit's
  E7 established that the death is the game's most judged
  moment; this pack establishes that the camera does nothing
  for it, and the record read does not say whether that is a
  deliberate RTS choice (never take the camera from the
  player) or a decision nobody has made yet.
- If wrong: either the signature moment keeps playing in
  whatever framing chance left it in, or a future kill-cam
  gets built against the owner's unrecorded preference and
  fights him for the camera every capital death.
- Settles it: an owner direction question (the legs will
  price both branches); it is a human-direction call, not a
  measurement.

CM13. Readability per zoom level: no rule states what must
remain readable at any radius except the battle radius
(CM1). By CM1's own arithmetic (INFERRED: 7.7 px per unit at
170 units scales inversely with radius), a 41.6-unit capital
is about 320 px long at radius 170 and 1080p, about 61 px at
900, and a frigate is a handful of pixels at the far end;
the fx standards' 10 px readability line (fx E10) silently
stops applying somewhere between.
- Lives in: the absence across camera_rig.gd and the two
  standards; the only camera-tied readability rule found
  anywhere is the red no-go marker on asteroid and wreck
  hexes (fx3d.js lines 613 to 614).
- Provenance: ASSUMED by absence. Evidence: the gap between
  "standards computed at 170" and "players free between 26
  and 900" is unowned by any document read.
- If wrong: zoomed-out play (where fleet tactics actually
  happen) is the least readable mode in the game, and every
  readability ruling was made for the mode nobody plays
  tactics in.
- Settles it: folds into CM1 and CM2: the owner's ruled
  default and ends define the radii the standards must cover;
  restating is one Opus run.

## 6. Chair observations (hypotheses for the legs to test)

These are the chair's starting suspicions, recorded so the
legs can attack or confirm them. They are INFERRED, they are
not findings, and a leg that merely repeats them has done no
work.

H1. The 170-unit radius is this audit's stage 5. One ported
default (CM1) underwrites the readability math of two adopted
standards, appears again as a floor in the JS overview
formula (CM9), and has never been judged as a framing choice
at 4K. Like the 306k ceiling, it is not a bad number; it is
an unexamined one with dependents.

H2. Destruction has two of everything. Wreck lifetimes
(14 vs 22 and 25 s, DS3), debris counts (two formulas, DS5),
secondary regimes (exactly two vs open cook-off, DS9): the
JS and Godot builds carry different feel constants for the
same events, and the port's parity work checked rules, not
feel. The owner's rulings describe whichever build he played
last; the other build's constants are unruled by definition.

H3. The capital showcase is frozen. DS7 freezes exactly the
pieces DS14 spends the most spectacle on, while frigate
pieces tumble freely. If the inversion is real, it is
invisible to every per-constant review and visible
immediately in the DS14 paired capture, which is why that
capture is the pack's cheapest high-information test.

H4. The rules layer and the visual layer disagree about
wrecks by accident: rules hulks are permanent and uncapped
(DS2), visual wrecks cap at 24 and recycle oldest-first
(DS1). Neither document mentions the other. Late in a fleet
wipe the board can block on wrecks the player cannot see,
and the first symptom will be a "bug" report about an
invisible wall.

H5. Physics feel is a pile of tables, not a system. PF1,
PF2, PF3, PF10, DS6, and DS8 were written by different jobs
(r4 review, A5 sheets, fx_death, ship_view) with no shared
mass model: REACT_MASS tops at 12.0, fx_death piece mass is
triangles divided by 400 with a floor of 5.0, and ship_view's
mass is a 0 to 1 dial. A ship has three unrelated weights in
three systems, so "heavier" cannot be tuned once.

H6. R88's complaint may be physical, not choreographic. The
owner said deaths feel sudden and jerky. The fx audit
covered the choreography (E7) and the budget split (E3).
This pack adds the physical candidates: no explosion impulse
on bystanders (PF7), main pieces separating at 0.7 units per
second (DS8), capitals frozen (DS7), and a hit pause whose
shipped depth dwarfs its recorded ranges (CM8). Any one of
these reads as "sudden" or "jerky" on its own.

H7. The camera has no director. The death (the game's most
judged moment, fx E7) gets no framing (CM12), the hand-over
glide is the only directed move and its rates disagree
fourfold between builds (CM5), and the punch is capped at a
6 percent FOV change (CM6). The board's presentation is
player-framed by default, which may be right for an RTS, but
the record shows a default, not a decision.

H8. The settlements are mostly already built. Probes exist
for exactly these questions (destruction_fleet_probe,
fx_cost_probe, death_leap_probe in godot/fx/test/), the
camera is one 194-line file, and the paired-capture tests
(DS14, PF1) need no new tooling. These assumptions are
expensive only because feel constants were never written
into any job's done-when; the queue kept moving past them.

## 7. Limitations and unverified list

What this audit cannot settle from the record read, and
claims the chair could not source:

1. The current build's actual state, everywhere. This pack
   reads main-branch code and documents. No Godot project was
   run, no capture was taken, no physics step was timed. The
   owner's playtest executable may differ from main.
2. Whether the Godot rules port implements the gravity well
   (PF9). battle.js is the frozen JS build and proves the
   mechanic exists there; godot/rules was not read for this
   pack. The fx-side hook (fx.well) is verified; the
   rules-side state is not.
3. Squadron physics (PF12). godot/render/squadron_craft.gd
   and squadron_wing.gd were not read. The item inventories
   the gap; nothing in this pack states what those files do.
4. godot/render/board.gd (862 lines) was read only at its
   board look preload (line 7). The Godot post-processing
   state behind CM10 (vignette, grade) is therefore
   unverified, not absent.
5. ship_view.gd was read at lines 447 to 500 (the cinematic
   motion block). Its remaining 790 lines (death handling,
   idle drift at line 1280) were not read; PF10 covers the
   motion block only.
6. Issue 60 was not re-read directly. Its record here is
   FINDINGS R107 plus the wreckage code (battle.js terrain
   and hulk rules, fx3d.js fragmentation and persistence).
   The issue's own done-when and shot list are not quoted.
7. The issue 200 standard was read on branch muse/issue-200
   (PR 203, open at pack time, with the Nov 6 corrections
   applied). If the branch changes before merge, DS13's
   quotations should be re-checked against the merged text.
8. Physics and frame costs: no fx.prof output, physics step
   timing, or scene-gate measurement for any item in this
   pack exists in the record read. DS4's settlement produces
   the first one; until then every cost claim in the legs is
   a hypothesis about cost, not a cost.
9. Perceptual questions generally. Whether 6 rad/s tumble
   reads as violent or silly, whether a 6 percent FOV punch
   reads at all, whether 170 is the owner's real radius: no
   document settles any of these. Each needs the owner in
   front of the artefact, which is the Nov 6 ruling's whole
   point.
10. The fx audit's items are cross-referenced at their
    Nov 6 state. Issue 210 carries the fx rulings (listen
    pass next, movement spec, effects in the 207 benchmark);
    if an fx disposition changes an E item's status, this
    pack's cross-references inherit the change silently and
    the chair must reconcile at synthesis.

## 8. Leg prompts

Four legs. The three writer legs (blind Rey, DeepSeek, Qwen)
run from this pack alone, in parallel, without seeing each
other. The Argon leg runs after them, as a review leg only.
The chair screens every leg before anything is adopted, per
the standing four-prong rule.

The lenses, named by the owner and used identically in every
writer leg:

- Game dev lens: does this number or rule bind real
  performance or gameplay? Is it denominated in the metric
  the engine actually charges for (physics bodies, ms, hexes),
  and what happens in a real 20-ship battle, not in a test
  scene or a specification?
- Domain designer lens: does this number or rule bind the
  craft of its own domain (destruction design for DS items,
  physics feel for PF items, camera and presentation craft
  for CM items)? Does it buy real spectacle, weight, or
  framing, and who pays when it is wrong?
- Agent lead lens: can the build pipeline actually produce
  work against this number or rule and measure the result?
  Is it enforceable in a review, on a sheet or a capture the
  owner judges, or does it hide in a constant nobody runs?
  Does it waste runs?

Cost units, the only ones permitted: Codex runs (one-hour cap
per run), Opus runs, one-time script builds, per-asset
unattended runs, owner review rounds. State one-time and
recurring costs separately.

Disposition ground rule, from the owner's Nov 6 rulings:
assumed and anchored numeric gates stop binding. A disposition
of KEEP for an ASSUMED or ANCHORED item must therefore say
what replaces its binding force (a measurement, a consolidated
spec, or the owner's eye on captures), or it is an error.
Settled rulings (section 1.2) are not dispositions to debate:
the Dead Star stays background only, breakable by design
stands, and the movement spec's scope is issue 210's.

---

### Blind Rey leg (writer)

You are a blind reviewer on a game project's destruction,
physics feel, and camera standards. One file is your complete
evidence and your complete instruction: PACK.md, the evidence
pack for a red team of the destruction, physics feel, and
camera stacks of the game Embers of the Hollow Sun. You have
no other sources. Do not browse, do not use outside knowledge
of this project beyond what the pack contains, and do not
invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the
inventory in PACK sections 3 to 5 (DS1 to DS15, PF1 to PF12,
CM1 to CM13), in light of the worked examples in PACK section
1.2 and the limitations in PACK section 7. The chair's
observations in PACK section 6 are hypotheses to test, not
conclusions to repeat. Items the pack cross-references to the
fx audit (E3 to E7, E13, E33, A7, A17, A19) are settled
inventory: use them as given and do not re-derive them.

Produce one report with exactly these parts:

1. Verdict: one of THE GATES HOLD, THE GATES HOLD ONLY WITH
   REPLACEMENTS, or THE GATES DO NOT HOLD, applied to the
   three stacks together, followed by the three inventory
   items your verdict most depends on, named by item number
   (one may be from any section, but say why those three). A
   verdict of THE GATES HOLD must state what evidence, if it
   appeared, would change it.
2. Game dev lens: attack every inventory item, DS1 to DS15,
   then PF1 to PF12, then CM1 to CM13, in order, one entry
   per item: does it bind real performance or gameplay, is it
   denominated in what the engine or the game actually
   charges for, and what does its being wrong cost in a real
   battle? An entry may be one line where the lens genuinely
   finds nothing; silence on an item counts as a miss and the
   review leg will flag it. Mark each entry OBSERVED (present
   in the pack; cite the pack section) or INFERRED (your
   reasoning; say what it rests on). If the pack lacks a fact
   you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order,
   for the craft of each item's own domain: which numbers and
   rules buy real spectacle, weight, or framing, which tax
   them without buying any, and what each error costs on the
   sheet, in motion, or in the frame.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets or captures or does it
   hide in a constant nobody runs, and where does it waste
   runs (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, DS1 to DS15, PF1 to PF12,
   CM1 to CM13, one row each: KEEP, RE-DERIVE, REPLACE, or
   DROP; for RE-DERIVE and REPLACE, the replacement approach
   and its cost in the pack's agent-term units only; for
   DROP, what replaces the protection the item was giving, or
   the statement that none is needed; for KEEP on an ASSUMED
   or ANCHORED item, what replaces its binding force (per
   the ground rule in PACK section 8). A disposition that
   contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and
   one line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. Do not
propose reinstating gravity mechanics (PACK PF9 is a settled
ruling with a code ghost, not an open question). No em
dashes. Plain ASCII.

---

### DeepSeek leg (writer)

You are a blind reviewer on a game project's destruction,
physics feel, and camera standards. One file is your complete
evidence and your complete instruction: PACK.md, the evidence
pack for a red team of the destruction, physics feel, and
camera stacks of the game Embers of the Hollow Sun. You have
no other sources. Do not browse, do not use outside knowledge
of this project beyond what the pack contains, and do not
invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the
inventory in PACK sections 3 to 5 (DS1 to DS15, PF1 to PF12,
CM1 to CM13), in light of the worked examples in PACK section
1.2 and the limitations in PACK section 7. The chair's
observations in PACK section 6 are hypotheses to test, not
conclusions to repeat. Items the pack cross-references to the
fx audit (E3 to E7, E13, E33, A7, A17, A19) are settled
inventory: use them as given and do not re-derive them.

Produce one report with exactly these parts:

1. Verdict: one of THE GATES HOLD, THE GATES HOLD ONLY WITH
   REPLACEMENTS, or THE GATES DO NOT HOLD, applied to the
   three stacks together, followed by the three inventory
   items your verdict most depends on, named by item number
   (one may be from any section, but say why those three). A
   verdict of THE GATES HOLD must state what evidence, if it
   appeared, would change it.
2. Game dev lens: attack every inventory item, DS1 to DS15,
   then PF1 to PF12, then CM1 to CM13, in order, one entry
   per item: does it bind real performance or gameplay, is it
   denominated in what the engine or the game actually
   charges for, and what does its being wrong cost in a real
   battle? An entry may be one line where the lens genuinely
   finds nothing; silence on an item counts as a miss and the
   review leg will flag it. Mark each entry OBSERVED (present
   in the pack; cite the pack section) or INFERRED (your
   reasoning; say what it rests on). If the pack lacks a fact
   you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order,
   for the craft of each item's own domain: which numbers and
   rules buy real spectacle, weight, or framing, which tax
   them without buying any, and what each error costs on the
   sheet, in motion, or in the frame.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets or captures or does it
   hide in a constant nobody runs, and where does it waste
   runs (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, DS1 to DS15, PF1 to PF12,
   CM1 to CM13, one row each: KEEP, RE-DERIVE, REPLACE, or
   DROP; for RE-DERIVE and REPLACE, the replacement approach
   and its cost in the pack's agent-term units only; for
   DROP, what replaces the protection the item was giving, or
   the statement that none is needed; for KEEP on an ASSUMED
   or ANCHORED item, what replaces its binding force (per
   the ground rule in PACK section 8). A disposition that
   contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and
   one line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. Do not
propose reinstating gravity mechanics (PACK PF9 is a settled
ruling with a code ghost, not an open question). No em
dashes. Plain ASCII.

---

### Qwen leg (writer)

You are a blind reviewer on a game project's destruction,
physics feel, and camera standards. One file is your complete
evidence and your complete instruction: PACK.md, the evidence
pack for a red team of the destruction, physics feel, and
camera stacks of the game Embers of the Hollow Sun. You have
no other sources. Do not browse, do not use outside knowledge
of this project beyond what the pack contains, and do not
invent facts the pack does not hold.

Task: answer the question in PACK section 1.3 for the
inventory in PACK sections 3 to 5 (DS1 to DS15, PF1 to PF12,
CM1 to CM13), in light of the worked examples in PACK section
1.2 and the limitations in PACK section 7. The chair's
observations in PACK section 6 are hypotheses to test, not
conclusions to repeat. Items the pack cross-references to the
fx audit (E3 to E7, E13, E33, A7, A17, A19) are settled
inventory: use them as given and do not re-derive them.

Produce one report with exactly these parts:

1. Verdict: one of THE GATES HOLD, THE GATES HOLD ONLY WITH
   REPLACEMENTS, or THE GATES DO NOT HOLD, applied to the
   three stacks together, followed by the three inventory
   items your verdict most depends on, named by item number
   (one may be from any section, but say why those three). A
   verdict of THE GATES HOLD must state what evidence, if it
   appeared, would change it.
2. Game dev lens: attack every inventory item, DS1 to DS15,
   then PF1 to PF12, then CM1 to CM13, in order, one entry
   per item: does it bind real performance or gameplay, is it
   denominated in what the engine or the game actually
   charges for, and what does its being wrong cost in a real
   battle? An entry may be one line where the lens genuinely
   finds nothing; silence on an item counts as a miss and the
   review leg will flag it. Mark each entry OBSERVED (present
   in the pack; cite the pack section) or INFERRED (your
   reasoning; say what it rests on). If the pack lacks a fact
   you need, write NOT IN PACK.
3. Domain designer lens: the same items in the same order,
   for the craft of each item's own domain: which numbers and
   rules buy real spectacle, weight, or framing, which tax
   them without buying any, and what each error costs on the
   sheet, in motion, or in the frame.
4. Agent lead lens: the same items in the same order, for
   production: can the pipeline build to it, can a review
   measure it on the owner's sheets or captures or does it
   hide in a constant nobody runs, and where does it waste
   runs (rebuilds, re-reviews, per-asset adjudication)?
5. Disposition table: every item, DS1 to DS15, PF1 to PF12,
   CM1 to CM13, one row each: KEEP, RE-DERIVE, REPLACE, or
   DROP; for RE-DERIVE and REPLACE, the replacement approach
   and its cost in the pack's agent-term units only; for
   DROP, what replaces the protection the item was giving, or
   the statement that none is needed; for KEEP on an ASSUMED
   or ANCHORED item, what replaces its binding force (per
   the ground rule in PACK section 8). A disposition that
   contradicts one of your own lens entries is an error.
6. Owner questions: at most three, each with your pick and
   one line on the stakes. Questions must be human-direction
   questions, not technical ones.
7. Not checked: what this report could not verify from the
   pack.

Hard constraints: no human-time estimates anywhere (no hours,
days, or weeks of human work); costs only in the units above.
No invented measurements, thresholds, or quotations. Do not
propose reinstating gravity mechanics (PACK PF9 is a settled
ruling with a code ghost, not an open question). No em
dashes. Plain ASCII.

---

### Argon leg (review only, runs after the writer legs)

You are a review leg, not a writer leg. You receive four
files: PACK.md (the evidence pack) and the three writer leg
reports (blind Rey, DeepSeek, Qwen) for the destruction,
physics feel, and camera red team on Embers of the Hollow
Sun. Do not write a new verdict of your own. Audit the three
reports against the pack.

Produce one report with exactly these parts:

1. Quotation and fact check: for each writer leg, list every
   measurement, threshold, rule, and provenance classification
   it states that does NOT match PACK.md, with the pack
   location (section or item number) that contradicts it or
   the note ABSENT FROM PACK. List every leg statement marked
   OBSERVED whose cited pack section does not contain it. Pay
   particular attention to any leg that reclassifies an item's
   provenance (sections 3 to 5) without evidence the pack
   contains, to any leg that re-inventories an fx audit item
   (E3 to E7, E13, E33, A7, A17, A19) instead of
   cross-referencing it, and to any leg that treats the Dead
   Star ruling (PF9) as an open question or proposes gravity
   mechanics.
2. Arithmetic check: recompute every number a leg derives
   (the ram estimate and recoil arithmetic in PF4 and PF5,
   the px-per-unit and zoom arithmetic in CM1 and CM13, the
   shake falloff figure in CM7, debris and wreck counts in
   DS1, DS4, and DS5, and the provenance tallies in PACK
   section 2). List each derivation as CONFIRMED or WRONG,
   with the corrected value when wrong.
3. Missed-item check: the pack inventory is DS1 to DS15, PF1
   to PF12, CM1 to CM13. For each writer leg, list every item
   number absent from any of its three lens sections, and
   every item number absent from its disposition table. Also
   list any numeric gate or standing rule a leg relies on
   that is not in the inventory at all, flagged as either a
   genuine inventory gap (name it) or an invention (part 1).
4. Constraint check: flag any human-time estimate, any em
   dash, any cost stated outside the pack's agent-term units,
   and any owner question beyond the three-question cap, per
   leg. Also flag any disposition that contradicts the same
   leg's own lens entries, and any KEEP on an ASSUMED or
   ANCHORED item that does not state what replaces its
   binding force.
5. Adopt/cut list: for each writer leg, an exact list: ADOPT
   (finding, lens entry, or disposition identifiers), CUT
   (identifiers, with the reason tied to parts 1 to 4), and
   FLAG (identifiers that are sound only with a correction
   you state).
6. Not checked: what this review could not verify.

Hard constraints: the pack is the sole evidence; do not
browse and do not supply project, physics, or camera facts of
your own. If a writer leg and the pack disagree, the pack wins
and the disagreement is a finding. No em dashes. Plain ASCII.
