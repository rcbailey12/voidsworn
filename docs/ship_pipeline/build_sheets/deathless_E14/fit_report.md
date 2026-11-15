# deathless_E14 fit report (first sheet (issue 739); RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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

## First full layout, checked (before)

The first complete E14 layout, built with the Eclipse kit and run through the check before any fix. Counts: CLASH 5, MOUNT 4, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0.

| Check | Part | Against | Hits | What |
|---|---|---|---:|---|
| CLASH | Q2s | V1s | 2 | parts intersect: Q2s_mount_gunv and V1s_mount_dark |
| CLASH | D1 | DL1 | 3 | parts intersect: D1_body_violet and DL1_mount_gunv |
| CLASH | D2 | DL2 | 3 | parts intersect: D2_body_violet and DL2_mount_gunv |
| CLASH | D3 | DL3 | 3 | parts intersect: D3_body_violet and DL3_mount_gunv |
| CLASH | D4 | DL4 | 3 | parts intersect: D4_body_violet and DL4_mount_gunv |
| MOUNT | DL1 | hull | 1 | no mount piece touches the hull |
| MOUNT | DL2 | hull | 1 | no mount piece touches the hull |
| MOUNT | DL3 | hull | 1 | no mount piece touches the hull |
| MOUNT | DL4 | hull | 1 | no mount piece touches the hull |

## How first sheet (issue 739) fixed them

| Clash (before) | Fix |
|---|---|
| Q2s (stern thruster) against V1s (heat panel) | the stern thrusters moved aft to 3.38 and the heat panels forward to 2.9 |
| D1 to D4 (drone cradles) against DL1 to DL4 (their lights), and the lights with no mount on the hull | each light is mounted on its own cradle on purpose (an allowed touch, as a part on a part) |

While designing round 3 the check also caught (and the design fixed) plates swallowing slits and lamps, casemate breeches pushed
into the hull, a pipe through a pod, chains through casemates, dishes too low on their posts, and, once turrets turned (R219),
neighbouring deck-edge turrets meeting when trained aft (the middle ones now superfire on barbettes) and antennas inside a
turret's swept circle (moved out).

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 211 objects, 28 parts, 246 close pairs, 176 rays, 2 guns, 0 sensor pairs, 2 turrets swept, 5 cones, 12 apertures, 0 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| F1 | F | -60 to 60 | 25 | 0 | all round | - | all round | - | no |
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
