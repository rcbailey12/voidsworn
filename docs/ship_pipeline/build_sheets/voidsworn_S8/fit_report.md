# voidsworn_S8 fit report (first sheet; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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
| T1 barrels at bearings 150 and -150 reaching the flak housings, and T1 against T2 at 175 to 180 (the first layout: the Sear pair on the centreline on tall drums) | the Sear pair moved to S8's grid: side by side on low tubs at the deck edges (1.42 off the axis), emitters short enough that the pair trained at each other never meets; the tall drums are gone (R185 (5): no battleship turrets) |
| Gallery slits G1 and G2: the ember pane inside the hull face | the pane set proud of the frame's back (kit slit, glass from 0.006) |
| Deck hatches H1 to H4: the seam ring inside the crowned deck | hatches lifted 0.06 onto the crown |
| Lift head HB1 inside the bow ridge | the ridge ends at 6.45; HB1 sits ahead of the trunk at 5.9 |
| Heat louvres V2 against the running lights L5 | the aft running lights moved between the louvres (5.3 and 7.1 aft) |
| Command deck slits W1 to W3 covered by the spine block, then by HB2 and the power trunk | the slits sit in the spine block's vertical forward face; HB2 moved forward to 1.55 aft; the trunk ends at 2.15 aft |
| Spire roots R1 and R2, R6 and R7 intersecting | the root sockets shortened to the spire's own length |
| Bow running lights L2 inside the cheek plates | the bow lights moved down to the knuckle line, the blade's edge |
| Belly hatches H5 and H6 not touching the armour step | the step lofted through every hull station, so its face follows the belly; the hatches seat on it |

The table above is every finding, in the order the check made them. Beyond the fit check, the sheet's own looks sent back: the first hull (3.2 deep, the Sear pair on tall drums) read as a boat with battleship turrets, so the hull came down to 2.75 deep and the turrets went to S8's low grid; the first spires (fin panels leaning out) read as organ pipes from the beam and shards from above, so they became fin stacks that glow; the gun jackets' close fins read as springs, so each carries three cooling rings.

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 401 objects, 64 parts, 1224 close pairs, 739 rays, 14 guns, 0 sensor pairs, 4 turrets swept, 6 cones, 35 apertures, 0 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| F1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| T2 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| F2 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
