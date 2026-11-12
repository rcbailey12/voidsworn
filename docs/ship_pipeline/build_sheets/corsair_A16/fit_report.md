# corsair_A16 fit report (round 3; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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

Turret marking for issue 560 (R219): each turret is an empty named `<id>_turret` at the ring centre (local +Z = the mount
normal), with custom properties `turret=1`, `slot`, `weapon`, `arc_lo`, `arc_hi`, `arc_deg` (bearings from the bow, + to port, as
core.js inArc), `rest_yaw`, `rest_pitch`; its turning meshes `<id>_turn_<material>` are its children (mesh in the pivot frame,
also `turret=1`); its fixed ring and bolt ring `<id>_mount_<material>` stay on the hull. Casemates are single fixed parts
(`turret=0`, `gun_fixed=1`).

## Round 2 layout, checked (before)

The round 2 design (`tools/blender/build_sheets/ships/r2/corsair_A16.py`, the PR 547 layout) built with the round 3 kit parts and run through the same check. Counts: CLASH 16, MOUNT 0, ARC 0, SWEEP 11, EXHAUST 10, EXIT 1.

| Check | Part | Against | Hits | What |
|---|---|---|---:|---|
| CLASH | H3 | hull | 4 | body piece inside the hull or a hull mass (H3_body_steel in corsair_A16_hull) |
| CLASH | H4 | hull | 4 | body piece inside the hull or a hull mass (H4_body_steel in corsair_A16_hull) |
| CLASH | PB | hull | 1 | body piece inside the hull or a hull mass (PB_body_soot in corsair_A16_hull) |
| CLASH | SB | hull | 1 | body piece inside the hull or a hull mass (SB_body_soot in corsair_A16_hull) |
| CLASH | E0 | hull | 3 | body piece inside the hull or a hull mass (E0_body_steel in corsair_A16_hull) |
| CLASH | E3 | hull | 5 | body piece inside the hull or a hull mass (E3_body_steel in corsair_A16_hull) |
| CLASH | E4 | hull | 5 | body piece inside the hull or a hull mass (E4_body_steel in corsair_A16_hull) |
| CLASH | E5 | hull | 3 | body piece inside the hull or a hull mass (E5_body_steel in A16_aftdeck) |
| CLASH | H1 | hull | 2 | body piece inside the hull or a hull mass (H1_body_steel in A16_H1_housing) |
| CLASH | H2 | hull | 2 | body piece inside the hull or a hull mass (H2_body_steel in A16_H2_housing) |
| CLASH | PB | Q1 | 2 | parts intersect: PB_mount_iron and Q1_mount_iron |
| CLASH | SB | Q2 | 2 | parts intersect: SB_mount_iron and Q2_mount_iron |
| CLASH | E1 | hull | 5 | body piece inside the hull or a hull mass (E1_body_steel in A16_E1_pylon) |
| CLASH | Q3 | hull | 1 | body piece inside the hull or a hull mass (Q3_body_steel in A16_E1_pylon) |
| CLASH | E2 | hull | 5 | body piece inside the hull or a hull mass (E2_body_steel in A16_E2_pylon) |
| CLASH | Q4 | hull | 1 | body piece inside the hull or a hull mass (Q4_body_steel in A16_E2_pylon) |
| SWEEP | T1 | R1 | 18 | turning through its arc hits R1_body_soot; blocked bearings -180 to -140, 140 to 180 |
| SWEEP | P1 | P2 | 15 | turning through its arc hits P2_turn_dark; blocked bearings 85 to 150 |
| SWEEP | P2 | P3 | 15 | turning through its arc hits P3_turn_dark; blocked bearings 85 to 150 |
| SWEEP | S1 | S2 | 15 | turning through its arc hits S2_turn_iron; blocked bearings -150 to -85 |
| SWEEP | S2 | S3 | 15 | turning through its arc hits S3_turn_iron; blocked bearings -150 to -85 |
| SWEEP | T1 | P1 | 1 | T1 barrels at bearing 60 reach P1's housing |
| SWEEP | T1 | P2 | 1 | T1 barrels at bearing 110 reach P2's housing |
| SWEEP | T1 | S1 | 1 | T1 barrels at bearing -70 reach S1's housing |
| SWEEP | T1 | S2 | 1 | T1 barrels at bearing -120 reach S2's housing |
| SWEEP | P1 | P3 | 1 | barrels meet with P1 at 150 and P3 at 30 |
| SWEEP | S1 | S3 | 1 | barrels meet with S1 at -150 and S3 at -30 |
| EXHAUST | E3 | hull | 7 | exhaust cone hits corsair_A16_hull at 0.1 behind the exit |
| EXHAUST | E3 | E0 | 1 | part inside the exhaust cone: E0_body_steel |
| EXHAUST | E4 | hull | 7 | exhaust cone hits corsair_A16_hull at 0.1 behind the exit |
| EXHAUST | E4 | E0 | 1 | part inside the exhaust cone: E0_body_steel |
| EXHAUST | Q1 | PB | 4 | exhaust cone hits PB_body_steel at 1.2 behind the exit |
| EXHAUST | Q2 | SB | 5 | exhaust cone hits SB_body_steel at 0.7 behind the exit |
| EXHAUST | Q3 | E1 | 8 | exhaust cone hits E1_mount_steel at 0.5 behind the exit |
| EXHAUST | Q3 | hull | 2 | exhaust cone hits A16_E1_pylon at 0.2 behind the exit |
| EXHAUST | Q4 | E2 | 7 | exhaust cone hits E2_mount_steel at 0.6 behind the exit |
| EXHAUST | Q4 | hull | 2 | exhaust cone hits A16_E2_pylon at 0.2 behind the exit |
| EXIT | R1 | T1 | 6 | launch cell covered by T1_turn_soot at 1.8 |

## How round 3 fixed them

| Clash (round 2) | Fix (round 3) |
|---|---|
| R1 launch cells covered by T1 (the bunker turret in front of the rack) | bunker turret removed; flak moved to the castle front (T1) and a bridge barbette (T2); the rack raised on a plinth and pitched 12 degrees |
| Q1 and Q2 exhaust into the bow casemates PB and SB | bow quads moved up onto the upper chamfer of the prow, firing up and out; casemates moved aft to 9.0 |
| Q3 and Q4 exhaust into the pods E1 and E2 and their pylons | stern quads moved to the castle's aft corners, above the pods |
| E3 and E4 exhaust into the hull and the E0 housing | boosters moved below and aft of the stern end, exits at -12.1 |
| E0 had no mount on the hull | its housing now runs forward into the stern (a mount piece) |
| Claw blades H1 to H4 inside their hull housings | each housing is now the claw's own mount, the hinge drum in it, the blades clear of the hull |
| Tube bores I1 and I2 inside the prow | a sunk tube is a mount by design: its bore runs back into the prow; the mouth must be clear (EXIT check) |
| Casemate housings P4, P5, S4, S5, SB inside hull masses | casemates set onto the sponson outer faces and the bow flank surface, plates cleared under each mount |
| Dish posts D1 and D2 inside the plinth | dishes stand on the plinth top on their own base plates |

While designing round 3 the check also caught (and the design fixed) plates swallowing slits and lamps, casemate breeches pushed
into the hull, a pipe through a pod, chains through casemates, dishes too low on their posts, and, once turrets turned (R219),
neighbouring deck-edge turrets meeting when trained aft (the middle ones now superfire on barbettes) and antennas inside a
turret's swept circle (moved out).

## Round 3 (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 405 objects, 77 parts, 1086 close pairs, 803 rays, 16 guns, 8 turrets swept, 10 cones, 45 apertures.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear |
|---|---|---|---:|
| T1 | T | -180 to 180 | 73 |
| T2 | T | -180 to 180 | 73 |
| P1 | P | 30 to 150 | 25 |
| P2 | P | 30 to 150 | 25 |
| P3 | P | 30 to 150 | 25 |
| S1 | S | -150 to -30 | 25 |
| S2 | S | -150 to -30 | 25 |
| S3 | S | -150 to -30 | 25 |

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
