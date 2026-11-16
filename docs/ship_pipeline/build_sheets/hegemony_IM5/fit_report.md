# hegemony_IM5 fit report (first sheet; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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


## How first sheet fixed them

| Clash (before) | Fix |
|---|---|
| The sensor fin A1 and the trench coils I1 reported inside the hull: the hull's end caps were one n-gon across a concave section (the canyon), which the fit check's triangle tree fans across the canyon; the trench mouth's corners were cut off by the ray sampling | the end caps triangulated for real (loft_closed); each mouth corner taken by its nearest ring point |
| Windows W1 to W3, louvre V1 and flank hatch H70 inside the hull where it tapers toward the bow | every fitting set flat on its face with the taper included (surf: the face's own normal along x and across) |
| Heat exchanger HX1's port into the module band at -0.6; HX2 to HX4 within 0.1 of a seam band | HX1 aft to -1.75; HX2 to -5.3, HX3 to -7.5, HX4 to -10.4, each 0.15 or more clear of its band |
| The power trunks' collars and flanges into the canyon floor panels | the trunks raised to 0.28 over the floor; their saddles run down into the floor |
| Belly hatch H3 inside the belly armour step where the belly rises at 8.0 | moved to the flat belly at 4.0 |
| Latch rows L0 at the bow band past the deck edge (no mount on the hull) | every latch row set at the middle of the ridge deck at its band |
| Latch rows L1 into deck hatches H1 and H2 | the deck hatches moved to 5.55, between the band and the bow bridge |
| The coolant lines' collars into the canyon wall and ledge panels | the lines set 1.64 off the axis and 0.17 over the ledge |

The table above is every finding, in the order the check made them. Beyond the fit check: the inside check sent back four rooms set below the belly skin and frames F1 and F2 outside the skin at the tapering bow (frames inset 0.08 more); the first battle-camera look sent back the shoulder swell (0.4 out over 0.15, a box sticking out of the flank), now 0.3 over two long ramps; the first look beside IM5 sent back a small trench mouth (2.2 by 1.0, now 2.6 by 1.25) and a bare canyon (coolant lines on the ledges and the engine room's control windows at the canyon's end added).

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 489 objects, 114 parts, 1395 close pairs, 427 rays, 5 guns, 30 sensor pairs, 4 turrets swept, 12 cones, 41 apertures, 1 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| HP | P | 30 to 150 | 25 | 60 | 95 | IM5_deck_panels_hgrey | 95 | hegemony_IM5_hull | no |
| HS | S | -150 to -30 | 25 | -60 | 95 | hegemony_IM5_hull | 95 | IM5_deck_panels_hgrey | no |
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| F1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
