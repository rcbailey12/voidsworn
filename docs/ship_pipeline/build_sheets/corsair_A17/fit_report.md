# corsair_A17 fit report (round 3; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

Made by `tools/blender/build_sheets/clash.py` on the built blockout (it runs inside every `build.py ... render` and on its own
with `build.py <code> <out> fit`). What it tests, on every part of every type:

1. **CLASH**: no part intersects another part; no non-mount piece (barrel, bell, blade, lid, slat, lens) sits inside the hull.
   Mount pieces (rings, collars, plates, saddles, sunk tubes) may sit into the hull, never into another part.
2. **MOUNT**: every part touches the hull through a mount piece.
3. **ARC**: every gun, at every bearing of its data.js slot arc (core.js inArc: F 60 degrees either side of the bow, P and S
   30 to 150 off the bow, T all round, 5 degree steps), has a clear line at an elevation it can reach (turrets 0 to 30, flak
   0 to 60, casemates -10 to +20), out to 60 percent of the ship's length.
4. **SWEEP** (R219): every turret's turning pieces turned through every bearing of its arc touch nothing; no two turrets meet
   when both turn through their arcs.
5. **EXHAUST**: nothing in any engine or thruster exhaust cone.
6. **EXIT**: no launcher cell, tube mouth, dish beam, hatch, lamp, vent or slit is covered.
7. **LANE** (R221: parts must not look like they conflict): each rack has a firing lane forward of its cells (4 degree spread,
   to 80 percent of the ship's length) and a backblast aft (15 degree spread, 2.5 rack depths or 15 percent of the length);
   no gun may sit in either, resting or turned through its slot arc, even when no mesh touches.
8. **Turret reach** (the issue 560 lesson: deck dressing can pin a turret): each turret is turned from rest each way in 5 degree
   steps until something stops it; the table below gives the real reach and flags any under 60 degrees either way.

Turret marking for issue 560 (R219): each turret is an empty named `<id>_turret` at the ring centre (local +Z = the mount
normal), with custom properties `turret=1`, `slot`, `weapon`, `arc_lo`, `arc_hi`, `arc_deg` (bearings from the bow, + to port, as
core.js inArc), `rest_yaw`, `rest_pitch`; its turning meshes `<id>_turn_<material>` are its children (mesh in the pivot frame,
also `turret=1`); its fixed ring and bolt ring `<id>_mount_<material>` stay on the hull. Casemates are single fixed parts
(`turret=0`, `gun_fixed=1`).

## Round 2 layout, checked (before)

The round 2 design (`tools/blender/build_sheets/ships/r2/corsair_A17.py`, the PR 547 layout) built with the round 3 kit parts and run through the same check. Counts: CLASH 20, MOUNT 2, ARC 6, SWEEP 7, EXHAUST 8, EXIT 0.

| Check | Part | Against | Hits | What |
|---|---|---|---:|---|
| CLASH | J1 | hull | 5 | body piece inside the hull or a hull mass (J1_body_steel in corsair_A17_hull) |
| CLASH | J3 | hull | 2 | body piece inside the hull or a hull mass (J3_body_steel in corsair_A17_hull) |
| CLASH | J2 | hull | 5 | body piece inside the hull or a hull mass (J2_body_steel in corsair_A17_hull) |
| CLASH | J4 | hull | 3 | body piece inside the hull or a hull mass (J4_body_steel in corsair_A17_hull) |
| CLASH | P2 | hull | 4 | turn piece inside the hull or a hull mass (P2_turn_soot in A17_hump) |
| CLASH | S2 | hull | 4 | turn piece inside the hull or a hull mass (S2_turn_soot in A17_hump) |
| CLASH | E2 | hull | 2 | body piece inside the hull or a hull mass (E2_body_steel in A17_engblock) |
| CLASH | I1 | Q1 | 6 | parts intersect: I1_mount_soot and Q1_mount_iron |
| CLASH | Q1 | hull | 1 | body piece inside the hull or a hull mass (Q1_body_steel in A17_I1_rib1) |
| CLASH | D1 | P1 | 3 | parts intersect: D1_body_steel and P1_turn_steel |
| CLASH | I2 | Q2 | 5 | parts intersect: I2_mount_soot and Q2_mount_iron |
| CLASH | Q2 | hull | 1 | body piece inside the hull or a hull mass (Q2_body_steel in A17_I2_rib1) |
| CLASH | D2 | S1 | 3 | parts intersect: D2_body_steel and S1_turn_steel |
| CLASH | C2 | P2 | 2 | parts intersect: C2_mount_iron and P2_mount_iron |
| CLASH | C2 | S2 | 1 | parts intersect: C2_mount_iron and S2_mount_steel |
| CLASH | T2 | hull | 4 | turn piece inside the hull or a hull mass (T2_turn_iron in corsair_A17_hull_plates_soot) |
| CLASH | E1 | E2 | 12 | parts intersect: E1_body_steel and E2_body_steel |
| CLASH | E2 | E3 | 13 | parts intersect: E2_body_steel and E3_body_steel |
| CLASH | E4 | E5 | 9 | parts intersect: E4_body_steel and E5_body_steel |
| CLASH | E5 | E6 | 10 | parts intersect: E5_body_steel and E6_body_steel |
| MOUNT | D1 | hull | 1 | no mount piece touches the hull |
| MOUNT | D2 | hull | 1 | no mount piece touches the hull |
| ARC | P1 | D1 | 5 | barrels would strike D1 (slot P): D1_body_steel; blocked bearings 30 to 50 |
| ARC | P2 | hull | 24 | barrels would strike hull (slot P): A17_hump; blocked bearings 30 to 140, 150 |
| ARC | P2 | C2 | 1 | barrels would strike C2 (slot P): C2_mount_iron; blocked bearings 145 |
| ARC | S1 | D2 | 5 | barrels would strike D2 (slot S): D2_body_dish; blocked bearings -50 to -30 |
| ARC | S2 | hull | 24 | barrels would strike hull (slot S): A17_hump; blocked bearings -150, -140 to -30 |
| ARC | S2 | C2 | 1 | barrels would strike C2 (slot S): C2_mount_iron; blocked bearings -145 |
| SWEEP | T2 | hull | 45 | turning through its arc hits corsair_A17_hull_plates_soot; blocked bearings -135 to 85 |
| SWEEP | P1 | D1 | 7 | turning through its arc hits D1_body_steel; blocked bearings 30 to 60 |
| SWEEP | P1 | P2 | 9 | turning through its arc hits P2_turn_dark; blocked bearings 115 to 150 |
| SWEEP | P2 | hull | 25 | turning through its arc hits A17_hump; blocked bearings 30 to 150 |
| SWEEP | S1 | S2 | 9 | turning through its arc hits S2_turn_iron; blocked bearings -150 to -115 |
| SWEEP | S1 | D2 | 7 | turning through its arc hits D2_body_dish; blocked bearings -60 to -30 |
| SWEEP | S2 | hull | 25 | turning through its arc hits A17_hump; blocked bearings -150 to -30 |
| EXHAUST | E2 | E1 | 1 | part inside the exhaust cone: E1_body_steel |
| EXHAUST | E2 | E3 | 1 | part inside the exhaust cone: E3_body_steel |
| EXHAUST | E5 | E6 | 3 | exhaust cone hits E6_body_ember at 0.0 behind the exit |
| EXHAUST | E5 | E4 | 1 | part inside the exhaust cone: E4_body_steel |
| EXHAUST | Q1 | I1 | 5 | exhaust cone hits I1_mount_iron at 0.1 behind the exit |
| EXHAUST | Q1 | hull | 2 | exhaust cone hits A17_I1_rib1 at 0.2 behind the exit |
| EXHAUST | Q2 | I2 | 5 | exhaust cone hits I2_mount_soot at 0.0 behind the exit |
| EXHAUST | Q2 | hull | 1 | part inside the exhaust cone: A17_I2_rib1 |

## How round 3 fixed them

| Clash (round 2) | Fix (round 3) |
|---|---|
| Engine bells E1 to E6 inside each other; E2 and E5 exhausts on their neighbours | two columns a side, exits level at -7.25, centres spaced by the sum of the bell radii plus the lip |
| P2 and S2 barrels striking the hump at every aft bearing | the mid block turrets now stand on the block top and superfire; the blocks behind them are no taller than their barrels |
| P1 and S1 barrels through the ear dishes D1 and D2 | the neck turrets stand inboard on barbettes high enough to fire over the head and the ears |
| Ear dishes D1 and D2 had no mount on the hull | each dish stands on an armoured bracket out from the head's upper corner |
| Q1 and Q2 bow thrusters inside the scoop drums, their exhaust on the drum ribs | bow thrusters on the body flank behind the drums, firing clear outboard |
| Jaw blades inside the hull and the jaw housing | four prongs, each hinged in its own housing in the mouth, the blades clear of the hull |
| C2 girdle through the P2 and S2 turret rings | C2 runs in the gap between the mid and saddle blocks, clear of every ring |
| Crest and belly turret housings sunk in the crest and the belly | turrets sit on their rings on block tops and the belly band, plates cleared under each mount |

While designing round 3 the check also caught (and the design fixed) plates swallowing slits and lamps, casemate breeches pushed
into the hull, a pipe through a pod, chains through casemates, dishes too low on their posts, and, once turrets turned (R219),
neighbouring deck-edge turrets meeting when trained aft (the middle ones now superfire on barbettes) and antennas inside a
turret's swept circle (moved out).

## Round 3 (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 360 objects, 56 parts, 833 close pairs, 532 rays, 8 guns, 6 turrets swept, 10 cones, 28 apertures, 2 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| T2 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| P1 | P | 30 to 150 | 25 | 40 | all round | - | all round | - | no |
| P2 | P | 30 to 150 | 25 | 25 | all round | - | all round | - | no |
| S1 | S | -150 to -30 | 25 | -40 | all round | - | all round | - | no |
| S2 | S | -150 to -30 | 25 | -25 | 155 | AN2_mount_iron | all round | - | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
