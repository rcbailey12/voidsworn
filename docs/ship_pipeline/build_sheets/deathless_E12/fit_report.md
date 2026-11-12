# deathless_E12 fit report (fourth sheet (R221 weapons, pass 2); RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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

## First full layout, checked (before)

The first complete E12 layout, built with the Eclipse kit and run through the check before any fix. Counts: CLASH 9, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 6, EXIT 0.

| Check | Part | Against | Hits | What |
|---|---|---|---:|---|
| CLASH | E1 | hull | 2 | body piece inside the hull or a hull mass (E1_body_gunv in deathless_E12_hull) |
| CLASH | E2 | hull | 2 | body piece inside the hull or a hull mass (E2_body_gunv in deathless_E12_hull) |
| CLASH | E3 | hull | 2 | body piece inside the hull or a hull mass (E3_body_gunv in deathless_E12_hull) |
| CLASH | S1p | A1 | 5 | parts intersect: S1p_mount_gunv and A1_mount_mauve |
| CLASH | S3p | C1 | 1 | parts intersect: S3p_mount_mauve and C1_mount_mauve |
| CLASH | S1s | A1 | 5 | parts intersect: S1s_mount_gunv and A1_mount_mauve |
| CLASH | S3s | C1 | 1 | parts intersect: S3s_mount_mauve and C1_mount_mauve |
| CLASH | A1 | Q2p | 1 | parts intersect: A1_mount_mauve and Q2p_mount_gunv |
| CLASH | A1 | Q2s | 1 | parts intersect: A1_mount_mauve and Q2s_mount_gunv |
| EXHAUST | Q1p | hull | 7 | exhaust cone hits E12_arc_aft_p at 0.7 behind the exit |
| EXHAUST | Q2p | S1p | 2 | exhaust cone hits S1p_mount_mauve at 1.0 behind the exit |
| EXHAUST | Q2p | hull | 2 | exhaust cone hits E12_arc_fore_p at 1.1 behind the exit |
| EXHAUST | Q1s | hull | 7 | exhaust cone hits E12_arc_aft_s at 0.7 behind the exit |
| EXHAUST | Q2s | hull | 2 | exhaust cone hits E12_arc_fore_s at 1.1 behind the exit |
| EXHAUST | Q2s | S1s | 2 | exhaust cone hits S1s_mount_mauve at 1.0 behind the exit |

## How fourth sheet (R221 weapons, pass 2) fixed them

| Clash (before) | Fix |
|---|---|
| E1, E2, E3 bells inside the stern block | the block's aft face moved forward to 6.65 aft of the bow datum, so the bells stand clear of it |
| S1p and S1s (fore struts) into the emitter's breech collar | the fore struts meet the arcs at 48 degrees and run straight across, clear of the collar |
| S3p and S3s (aft centre struts) touching the core's hub collars | the struts moved to 103 degrees and the spine collar there moved aft, so the lugs clear the hubs |
| A1 (emitter) collar against the spine-head thrusters Q2p and Q2s | the spine-head thrusters removed; all four thrusters sit on the block's roof and belly edges |
| Q1 and Q2 exhaust cones on the aft and fore arcs and on the fore struts | the thrusters fire up and out, and down and out, from the block edges, clear of every arc |

While designing, the check also caught (and the design fixed): the sentry twin sweeping through the block roof thrusters (moved forward), a roof hatch on a thruster, the block's green lights inside the stern arcs (raised), and the heat panels touching the outer engine housings (moved forward). R221 weapon rebuild (this sheet): the new null cannons, null spire and corona arc emitter checked at zero on their first full run, with the new LANE test and the emitter's own firing lane.

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 457 objects, 30 parts, 314 close pairs, 360 rays, 4 guns, 3 turrets swept, 7 cones, 10 apertures, 1 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| T1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| T2 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |
| G1 | T | -180 to 180 | 73 | 0 | all round | - | all round | - | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
