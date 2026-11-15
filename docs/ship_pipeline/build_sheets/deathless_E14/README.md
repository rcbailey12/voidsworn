# deathless_E14 build sheet: the Eclipse flare, the annulus destroyer (first sheet, issue 739)

Eclipse destroyer, class Destroyer, **9.5 world units** (godot/render/hull_table.gd CLS_LEN['Destroyer']; data.js `d_jackal`:
gauss T, gauss F; ability phase, regen 2, reanimate; speed 3). Accepted picture: contrib/muse/design/class_family_deathless_2026_11/
deathless_E14_flare.jpg and _sheet.jpg (Ryan, Nov 12, issue 627: "The flare is what I was thinking of for the annulus").
Binding design ruling: **one closed ring** (R233). Designer of record: Opus (R205, R207); the Board is the final designer (R233,
R236). The model is 9.52 long. Built and rendered in the cloud sandbox with Blender 5.3 (the bpy module), Cycles CPU, 16 samples;
no PC run in this job (the Board launches stage 1 to 7 after it looks).

![deathless_E14 preview](preview.jpg)

Start here: **[whole_compare.jpg](whole_compare.jpg)** (the whole beauty, the plan and the sheet's middle view beside the blockout,
R229), then [ring_study.jpg](ring_study.jpg) (why the ring lies flat), [side_by_side.jpg](side_by_side.jpg),
[fit_view.jpg](fit_view.jpg), [cells.jpg](cells.jpg) and [weapon_review.jpg](weapon_review.jpg).

## The ring's plane (R233)

The concept's three views disagree: the sheet's plan lays the ring flat round the spar, its middle view stands it upright and
edge-on, the beauty shows it almost face-on from above. The study (`tools/blender/build_sheets/studies/e14_ring_study.py`,
[ring_study.jpg](ring_study.jpg)) renders plain primitives three ways from straight above and at the battle camera's pitch from
the bow quarter, the beam and the stern quarter: **flat** reads as one closed ring from every view; **upright** reads as a bar from
above and a line from the beam, so it fails R233's own test; **leaning back** turns edge-on from the stern quarter. The build lies
flat, and the beauty's twelve plates line up with the build at the fitted camera ([outline_check.jpg](outline_check.jpg)).

## Checks (sandbox, this sheet)

| Check | Result |
|---|---|
| Weapon match (R241, `weapon_match.py`) | PASS, 0 problems: slot 0 gauss T, 3 shots, mount T1 (twin, 2 muzzles); slot 1 gauss F, 3 shots, mount F1 (twin, 2 muzzles), a turret turning only through the F arc; every mount fires every volley ([record](weapon_match.json)) |
| Fit check (`clash.py`, R217 to R219, R240) | CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0; F1 sweeps its whole F arc clear (25 steps of 5 degrees) and nothing stops it turning further, T1 turns all round ([fit_report.md](fit_report.md); the first layout's 9 findings and their fixes are in it) |
| Machines on a seam (R226) | 0: the stage 4 audit passes (`audit.py`) |
| Build contract (`sheet_contract_selftest.py`) | PASS: length, seams, muzzles and slots, both turret pivots, engine, insides and hull thickness reach the recipe unchanged; three broken inputs refused |
| Audit self-test | PASS |
| Stage 7 unbaked export and readback (`export7.py unbaked=1`, `check_export.py`, self-test) | PASS: 4 gun muzzles (2 per slot), 1 engine, 3 breach anchors (Destroyer 3, Eclipse +0), core, 2 braking, 2 boarding, both turret nodes with their turning meshes; the self-test refuses every broken copy |
| Density (R224, the mesh half; `studies/mesh_density.py`) | 0 flags ([mesh_density.json](mesh_density.json)); the paint half is measured at stage 5 |
| Inventory (R218, R221) | 21 lines, all present, shaped and detailed; every part has a job ([inventory.md](inventory.md)) |
| Manifest (`build_manifest_tests.js`) | PASS |

Outline overlap with the beauty at the camera of record: 59.3 percent (mass outline 58.3). Reported, not a bar (RULEBOOK 5.8). The
cut-out leaves out the engine's light ring and glow and the sky's teal nebula. The proportions table in inventory.md compares the
build with the sheet's middle view for height; that view draws the ring upright, so its height ratio is not comparable.

## Budget (sandbox unbaked export, the same route for all four; reported, never capped, R111)

| Ship | Triangles (readback) | Ship mesh surfaces | Turret triangles | Insides |
|---|---:|---:|---:|---|
| **E14 flare** | **34,128** | **9** | 9,208 (2 turrets) | 728 triangles, 7 surfaces |
| E13 mote | 20,288 | 10 | 4,604 (1 turret) | 624 triangles, 7 surfaces |
| E12 zenith | 51,502 | 9 | 10,938 (3 turrets) | 488 triangles, 7 surfaces |
| E11 The Unsetting | 115,530 | 10 | 12,590 (3 turrets) | 1,768 triangles, 8 surfaces |

Draw calls: one per surface, plus one per turret node. The scene gate (RULEBOOK 3.9) is measured on the PC after the paint bake.

## The design, in short

1. **The ring**: twelve curved shade plates on one closed box-section hoop, narrow even gaps between them, lying flat round the
   gun heart, 6.0 across; its bow plate is the ship's bow. Each plate is a slab whose outer rim lifts into a shallow dish, with a
   stepped second layer and a thin green-white corona line on its rim and on its layer's rim. Four truss spokes carry the hoop to
   the heart at the beams; the hoop meets the gun heart at the bow and the spar at the stern.
2. **The gun heart**: a faceted drum at the ring's centre, the forward null cannon (gauss F) on its stepped roof, turning only
   through the F arc and firing over the ring's bow plates; behind it the core in a broken cage of six small curved shade plates.
3. **The spar and the aft gun**: a layered beam running aft from the core, collared where the spokes and the saddle meet it; the
   aft null cannon (gauss T) on a stepped saddle, firing over the ring and turning all round.
4. **The stern block and engine**: a faceted block with corona strip lights, heat panels, belly hatches and attitude thrusters;
   one broad eclipse-ring engine, larger than the mote's, no flame.
5. **The repair drones**: four cradles docked on the hoop between the plates, each with a green work light (data.js regen 2).
6. **INSIDE**: the capacitor bank and the forward magazine in the gun heart; dark decks, the aft magazine and the conduits along
   the spar; the archive vault, the repair bay and the engine room in the block. Two break lines (Destroyer): B-1, the spar parts
   at the core and the ring's fore half tears away with the heart; B-2, the block tears from the spar. Three breach anchors: the
   ring's bow quarter plate, its starboard beam plate, and the block's roof (no shade plate reaches the engine third).

## Changed from the picture (R207, R233, R236), and why

All in [feature_table.md](feature_table.md); the design calls the Board should look at first:

- **One closed ring, flat in plan** (R233 and the study above).
- **The ring 0.63 of the length across**, its bow plate the bow: between the beauty's big forward ring and the line-up's 0.6. The
  sheet's plan draws it nearly the ship's length, which would ring the whole ship as on the zenith.
- **The forward gun turns through the F arc.** designs.md asks for a fixed, recessed housing; the game's gauss is the null cannon on
  a turret (`weapon_match.FITS`), so a fixed housing fails the weapon match. It rests on the bow and turns 60 either side, as the game
  turns an F weapon. If the Board wants it fixed, that is a weapon_match table change first.
- **The drones are docked** on the hoop, not hovering.
- **The spar is heavier** than the zenith's rod, as the beauty draws it.
- **The third breach anchor is on the stern block**, the one Eclipse anchor not on a shade band.

## What still differs from the concept, and why

- **Surface and colour**: the concept's plates are thick, heavily panelled blocks; the blockout is flat schematic colour (stage 5).
- **The gun heart**: the beauty draws a long cylinder with a big round muzzle pointing at the viewer; the build's forward gun is
  the faction's rail gun on a turret, and the heart is a drum holding the core.
- **The core cage** reads as a small drum from straight above; at the beauty camera its gaps show the core.

## Files

[sheet.jpg](sheet.jpg) (tall: open it whole), [feature_table.md](feature_table.md), [inventory.md](inventory.md),
[cells.jpg](cells.jpg), [cells.json](cells.json), [fit_report.md](fit_report.md), [fit_view.jpg](fit_view.jpg),
[fit.json](fit.json), [manifest.json](manifest.json), [checks.json](checks.json), [outline_check.jpg](outline_check.jpg), the views,
the weapon picture [weapon_gauss.jpg](weapon_gauss.jpg). Design source: `tools/blender/build_sheets/ships/deathless_E14.py`; inventory
`ships/deathless_E14_inv.py` (the cage line's count went from 4 to 6 with the design change above); camera
`ships/deathless_E14_camera.json`; recipe entry `tools/recipe/ships/deathless_E14.json` (game folder D20_23, `"bake": "stack"`, the
Eclipse stack unchanged: every (part kind, zone) pair is one the stack already paints on E11 and E12). Pictures not made by the sheet
tools: `studies/e14_ring_study.py` (ring_study.jpg), `studies/whole_compare.py` (whole_compare.jpg), `studies/mesh_density.py`.
