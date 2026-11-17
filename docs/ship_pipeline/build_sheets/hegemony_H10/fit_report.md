# hegemony_H10 fit report (first sheet; RULEBOOK 5.15 and 5.16, ships.md 2c, R217 to R219)

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
| HP and HS turning pieces inside the wedge and their bustles turning into the deck panels and the pit lip (the first pit ran 1.95 to 3.6 off the axis) | the shoulder terrace widened inboard to 1.45 and lengthened (0.55 to 3.85 at full depth); no panel under the turret's sweep (a keep-out of 1.45) |
| Window panes W1 to W3 inside the flank band, which tapers in plan | the windows set 0.035 proud of the band |
| Nozzle pods E1 against E2 and E3 against E4 | the pods 1.42 apart across each rail (they overhang the rail by 0.07 a side, as H10's pods do) |
| Picket turrets F1 and F2 inside the belly armour step, and turning into it | the pickets seated on the step's face, 0.1 below the belly |
| Belly hatch H3 half inside the rising belly at 6.0 | moved to the flat belly at 2.9 |
| Reactor louvres V5 inside the pit lip, then V4 into the lift head HB1 and into the latch rows LW0 and LW1 | V5 beside the sensor fin; the deck louvres turned to run along the length, V4 shortened to 1.2 and tilted to the deck's slope |
| Flank hatches H70 and H71 inside the lower facet (their normal pointed in), first on the tapering facets forward | the normal turned out; the hatches moved to 3.2 and 1.2, where the facet runs straight |
| Rail windows W4 and W5 against the rail louvres; stern thrusters Q3 against louvre V8 | the windows to the lower tier, Q3 aft to 7.75, V8 forward to 6.6 |
| Rail louvres V2 against the latch rows at the 3.0 band | the rail louvres centred in their modules (1.7, 4.3, 6.6 aft) |
| The nozzles failed the export's open-bell test (check_export.py, simulated here): the rim covered 0, then 8, of 12 sectors | points laid along the mouth's straight edges, the mouth made 1.1 by 1.45; all four pass, 12 of 12 sectors, a throat, a clear exhaust |
| Lift head HB1 across seam B-1 (structure, allowed, but avoidable) | moved aft to 6.1 |
| Inside frames F5 and F8 outside the inner skin on the terrace ramps; the rails' aft decks past the end cap | frames moved to full-terrace or plain stations; the decks end at 8.9 aft |

The table above is every finding, in the order the check made them. Beyond the fit check, the sheet's own looks sent back: the first lance turrets (size 0.9, barrels 0.92) read small beside H10's big shoulder turrets and their barrels hid behind the glacis, so they grew to 1.1 with 1.25 barrels in a wider, longer pit; the first sensor fin (0.62 tall, 1.8 long) read as a sail from the beam, so it came down to 0.42 and ran out to 2.4; the first panel grid (0.8 by 0.62) left the hull at a seventh of the guns' triangle density, so it went to 0.6 by 0.45.

## The sheet as delivered (after)

Counts: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 356 objects, 80 parts, 616 close pairs, 398 rays, 5 guns, 30 sensor pairs, 4 turrets swept, 10 cones, 43 apertures, 1 lanes.

**Zero clashes left.** No clash is left in as intended.

| Turret | Slot | Arc (bearings) | Sweep steps clear | Rest | Reach to port | Stopped by | Reach to starboard | Stopped by | Under 60 |
|---|---|---|---:|---:|---:|---|---:|---|---|
| HP | P | 30 to 150 | 25 | 55 | 165 | hegemony_H10_wedge | 95 | hegemony_H10_wedge | no |
| HS | S | -150 to -30 | 25 | -55 | 95 | hegemony_H10_wedge | 165 | hegemony_H10_wedge | no |
| F1 | T | -180 to 180 | 73 | 40 | all round | - | all round | - | no |
| F2 | T | -180 to 180 | 73 | -40 | all round | - | all round | - | no |

Reach is measured from the rest bearing, in degrees, turning toward port (bearings rising) and toward starboard; "all round" means nothing stops it within 180. Every turret clears its whole data.js slot arc (sweep steps above). Under 60 degrees either way: none.

Picture: [fit_view.jpg](fit_view.jpg) (top and side with arcs, sweep circles, exhaust cones and exits).
