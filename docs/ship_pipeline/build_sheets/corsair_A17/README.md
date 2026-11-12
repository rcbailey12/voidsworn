# corsair_A17 build sheet: Hullbreaker wrecker, the Pack Hunter (round 3)

Ashfall Hullbreakers cruiser, class Cruiser, **14.5 world units** (godot/render/hull_table.gd CLS_LEN; data.js c_marauder).
Version 3, 2026-11-11, after Ryan's review of round 2 (R217: "the front is also just a flat block which does not match the
concept", and A16's notes hold here too) and R218 (whole-ship fidelity), with turrets that turn (R219). Lean, as Ryan kept it
(R213). Designer of record: Opus (R205, R207). Rendered on Ryan's PC (Blender 4.5, GPU), blockout
`C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3d\corsair_A17\corsair_A17_blockout.blend`.

![corsair_A17 preview](preview.jpg)

Start here: **[side_by_side.jpg](side_by_side.jpg)** (concept left, blockout right, same camera, full view then bow,
midships and stern at the same windows), then [fit_view.jpg](fit_view.jpg) and [cells.jpg](cells.jpg).

- [sheet.jpg](sheet.jpg): beauty and blockout, true views, INSIDE cutaway, feature table, changes, fit view and nine cells.
- [inventory.md](inventory.md): the parts inventory from the concept, written before modelling (R218): 29 lines, every one
  present, shaped by its kit part type and detailed, ticked per blob-sweep cell.
- [fit_report.md](fit_report.md): 43 clashes on the round 2 layout (20 clash, 2 mount, 6 arc, 7 turret sweep, 8 exhaust:
  engine bells inside each other, the hump-front turrets' barrels striking the hump, turrets through the ear dishes, bow
  thrusters inside the scoop drums), each fix, and **zero left** in round 3.
- [feature_table.md](feature_table.md), [manifest.json](manifest.json), [checks.json](checks.json), the views and the outline
  overlay as for A16. Design source: `tools/blender/build_sheets/ships/corsair_A17.py`; inventory `ships/corsair_A17_inv.py`.

## What round 3 changed

1. **The head is shaped, never a flat block**: an octagonal block with heavy chamfers, two roof steps (the pale brow, then a
   crown carrying the rocket pod), a face that overhangs a cut-in jaw mouth (the bottom rises from the belly line to the face),
   framed face panels with vertical straps, scoop drums with grilles and four bands at its lower corners (port larger), ear
   dishes at its upper front corners, framed boxes on the brow, hoses in the mouth.
2. **Every part is its real shape** from the Hullbreakers kit (as A16): engine bells, turrets, casemates, the 2 by 3 rocket pod,
   dishes, four jaws in their own housings, link chains, thrusters, antennas, hatches, slits, vents, lamps, hull plates.
3. **The engine cluster works**: six bells, exits level at the stern, centres spaced so no bell touches another and no
   exhaust washes a neighbour (round 2's were inside each other).
4. **Guns fit**: neck turrets on low barbettes, hump-front turrets superfiring over them, hump casemates, a crest twin and a
   belly twin; every turret swept through its data.js arc without touching anything (R219).

## What still differs from the concept, and why

- **Surface density** (as A16): the concept's small torn plates, rivets and grime are coarser here and flat-coloured; texture
  is the paint stage, plate size a kit setting.
- **The jaws** in the concept are broad mandible blades; ours are segmented arms with hooked fingers. They read as claws and
  close on something (R207), but are thinner than the picture's.
- **The hump** in the concept has more steps and boxes; ours has the hump, a crest and three framed boxes.
- **The head** is a little lower relative to the hump than the concept's, to keep the ship lean (R213).
