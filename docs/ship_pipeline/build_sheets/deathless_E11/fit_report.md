# deathless_E11 fit report (first sheet; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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

## First full layout, checked (before)

The first complete E11 layout, built with the Eclipse kit and run through the check before any fix. Counts: CLASH 1, MOUNT 0, ARC 1, SWEEP 1, EXHAUST 0, EXIT 0.

| Check | Part | Against | Hits | What |
|---|---|---|---:|---|
| CLASH | F1 | HB1 | 2 | parts intersect: F1_turn_mauve and HB1_mount_mauve |
| ARC | T1 | T2 | 2 | fire blocked by T2 (slot T): T2_mount_shade; blocked bearings -175, 175 |
| SWEEP | F1 | HB1 | 13 | turning through its arc hits HB1_mount_mauve; blocked bearings -30 to 30 |

## How first sheet fixed them

| Clash (before) | Fix |
|---|---|
| F1 (aft flak twin) intersecting HB1 (the deck housing), and sweeping through it from bearing -30 to 30 | the housing made shorter (0.5) and moved forward to 4.6 aft of amidships; the twin moved aft to 6.4, so its barrels clear the housing at every bearing |
| T1 (fore twin) firing aft blocked by T2's plinth at bearings 175 and -175 | T2 moved aft (to 57 percent) and T1 raised on a low round drum, so T1's highest line passes over T2's muzzles; both twins carry 2.0 barrels |

While designing, the check also caught (and the design fixed): deck hatches and the core port sunk in the curved tier, the belt lights inside the belt, heat panels covered by the stern feathers (moved forward of the band collar), the aft flak twin sweeping through deck hatches (moved to the deck edge), and, after the crescent was raised over the nose, the fore twin's barrels striking the tier when trained aft (the tier now starts behind its sweep).

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 241 objects, 29 parts, 645 close pairs, 474 rays, 5 guns, 4 turrets swept, 8 cones, 15 apertures.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear |
|---|---|---|---:|
| T1 | T | -180 to 180 | 73 |
| T2 | T | -180 to 180 | 73 |
| F1 | T | -180 to 180 | 73 |
| F2 | T | -180 to 180 | 73 |

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
