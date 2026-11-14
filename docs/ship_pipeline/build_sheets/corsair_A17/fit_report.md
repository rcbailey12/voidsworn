# corsair_A17 fit report (round 3; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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
| Engine bells E1 to E6 inside each other; E2 and E5 exhausts on their neighbours | two columns a side, exits level at -7.25, centres spaced by the sum of the bell radii plus the lip |
| P2 and S2 barrels striking the hump at every aft bearing | the mid block turrets now stand on the block top and superfire; the blocks behind them are no taller than their barrels |
| P1 and S1 barrels through the ear dishes D1 and D2 | the neck turrets stand inboard on barbettes high enough to fire over the head and the ears |
| Ear dishes D1 and D2 had no mount on the hull | each dish stands on an armoured bracket out from the head's upper corner |
| Q1 and Q2 bow thrusters inside the scoop drums, their exhaust on the drum ribs | bow thrusters on the body flank behind the drums, firing clear outboard |
| Jaw blades inside the hull and the jaw housing | four grabber arms (R229), each shoulder in its own housing under the jaw, clear of the hull |
| C2 girdle through the P2 and S2 turret rings | C2 runs in the gap between the mid and saddle blocks, clear of every ring |
| SENSOR: P1 and S1 aiming through the ear dishes D1 and D2 at their forward bearings | R240 (Ryan, Nov 13: guns right behind or facing dishes and antennae): the neck turret barbettes raised 0.14 (top 1.78 to 1.92), so the lowest line of fire of P1 and S1 passes over the ears |
| SENSOR: T1 (flak, all round) aiming through the saddle antennas AN1 and AN2 | R240 (Ryan, Nov 13: guns right behind or facing dishes and antennae): T1 lifted onto a 0.55 barbette and the antennas cut (1.3 to 0.75, 1.0 to 0.6 tall), so the crest gun fires over them |
| Crest and belly turret housings sunk in the crest and the belly | turrets sit on their rings on block tops and the belly band, plates cleared under each mount |

While designing round 3 the check also caught (and the design fixed) plates swallowing slits and lamps, casemate breeches pushed
into the hull, a pipe through a pod, chains through casemates, dishes too low on their posts, and, once turrets turned (R219),
neighbouring deck-edge turrets meeting when trained aft (the middle ones now superfire on barbettes) and antennas inside a
turret's swept circle (moved out).

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 370 objects, 54 parts, 938 close pairs, 451 rays, 6 guns, 72 sensor pairs, 6 turrets swept, 10 cones, 28 apertures, 2 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| T2 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| P1 | P | 30 to 150 | 25 | 40 | all round | - | all round | - | no |
| P2 | P | 30 to 150 | 25 | 35 | all round | - | all round | - | no |
| S1 | S | -150 to -30 | 25 | -40 | all round | - | all round | - | no |
| S2 | S | -150 to -30 | 25 | -35 | 165 | AN2_mount_iron | 170 | AN2_mount_iron | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
