# corsair_A16 fit report (round 3; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

Made by `tools/blender/build_sheets/clash.py` on the built blockout (it runs inside every `build.py ... render` and on its own
with `build.py <code> <out> fit`). What it tests, on every part of every type:

1. **CLASH**: no part intersects another part; no non-mount piece (barrel, bell, blade, lid, slat, lens) sits inside the hull.
   Mount pieces (rings, collars, plates, saddles, sunk tubes) may sit into the hull, never into another part.
2. **MOUNT**: every part touches the hull through a mount piece.
3. **ARC**: every gun, at every bearing of its data.js slot arc (core.js inArc: F 60 degrees either side of the bow, P and S
   30 to 150 off the bow, T all round, 5 degree steps), has a clear line at an elevation it can reach (turrets 0 to 30, flak
   0 to 60, casemates -10 to +20), out to 60 percent of the ship's length.
3b. **SENSOR** (R240): no gun sits behind or aims through a dish, antenna or mast: the gun's whole firing volume (every
   bearing of its slot arc, every elevation it can reach, out to 60 percent of the ship's length) misses every sensor piece's
   box padded by the gun's calibre; firing just over a dish is not enough.
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


## How round 3 fixed them

| Clash (before) | Fix |
|---|---|
| R1 launch cells covered by T1 (the bunker turret in front of the rack) | bunker turret removed; flak moved to a bridge barbette (T2) and, after R221, the belly (T1); the rack raised on a plinth and pitched 12 degrees |
| Q1 and Q2 exhaust into the bow casemates PB and SB | bow quads moved up onto the upper chamfer of the prow, firing up and out; casemates moved aft to 9.0 |
| Q3 and Q4 exhaust into the pods E1 and E2 and their pylons | stern quads moved to the castle's aft corners, above the pods |
| E3 and E4 exhaust into the hull and the E0 housing | boosters moved below and aft of the stern end, exits at -12.1 |
| E0 had no mount on the hull | its housing now runs forward into the stern (a mount piece) |
| Claw blades H1 to H4 inside their hull housings | each pincer and grabber has its own housing as its mount, the blades clear of the hull |
| Tube bores I1 and I2 inside the prow | a sunk tube is a mount by design: its bore runs back into the prow; the mouth must be clear (EXIT check) |
| Casemate housings P4, P5, S4, S5, SB inside hull masses | casemates set onto the sponson outer faces and the bow flank surface, plates cleared under each mount |
| Dish posts D1 and D2 inside the plinth | dishes stand on the plinth top on their own base plates |
| SENSOR: T2 (flak, all round) aiming through the port antenna AN1 when trained aft | R240 (Ryan, Nov 13: guns right behind or facing dishes and antennae): AN1 cut from 1.8 to 1.5 tall, so its whips stay under the lowest line of fire of the barbette turret |

While designing round 3 the check also caught (and the design fixed) plates swallowing slits and lamps, casemate breeches pushed
into the hull, a pipe through a pod, chains through casemates, dishes too low on their posts, and, once turrets turned (R219),
neighbouring deck-edge turrets meeting when trained aft (the middle ones now superfire on barbettes) and antennas inside a
turret's swept circle (moved out).

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 371 objects, 65 parts, 922 close pairs, 533 rays, 8 guns, 96 sensor pairs, 8 turrets swept, 10 cones, 45 apertures, 2 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| T2 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| P1 | P | 30 to 150 | 25 | 30 | 125 | A16_barbette_P2 | 135 | HB3_body_soot | no |
| P2 | P | 30 to 150 | 25 | 35 | 170 | R1_body_soot | 85 | R1_body_iron | no |
| P3 | P | 30 to 150 | 25 | 40 | 125 | A16_redband | 15 | A16_barbette_P2 | yes |
| S1 | S | -150 to -30 | 25 | -30 | all round | - | 125 | A16_barbette_S2 | no |
| S2 | S | -150 to -30 | 25 | -35 | 85 | R1_body_iron | 170 | R1_body_soot | no |
| S3 | S | -150 to -30 | 25 | -40 | 15 | A16_barbette_S2 | 125 | A16_castle | yes |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: P3 (starboard 15); S3 (port 15).

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
