# voidsworn_SF3: Spire Dart fighter (Sunward Crusade fighter wing craft), build sheet

Sunward Crusade (voidsworn) | class Squadron | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 769 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py voidsworn_SF3 <out> render` rebuilds it from this file

**Length 1.6 world units** (data.js fighter (cls 'Squadron', the Sunward wing: voidsworn sq 'fighter'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | guns | T | 3 | G1 (3) |

| Check | Value |
|---|---|
| model length | 1.6 |
| length side | 1.602 |
| length top | 1.602 |
| length disagreement percent | 0.0 |
| beam top | 0.373 |
| beam bow | 0.373 |
| beam disagreement percent | 0.0 |
| height side | 0.373 |
| height bow | 0.373 |
| height disagreement percent | 0.0 |
| widest at station percent | 78.6 |
| hull beam | 0.38 |
| hull depth | 0.19 |
| L to B hull | 4.21 |
| L to H hull | 8.42 |
| prow overhang | 0.0 |
| outline iou percent | 90.8 |
| mass outline iou percent | 91.1 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| G1 | interceptor guns, triple turret | 3 barrels | 29.0 | 0.00 | 0.04 | forward, +5 elev | T guns | picture | the interceptor guns (data.js guns T, 3 shots): three barrels in one emitter cluster on a traverse ring in an armoured well; every volley fires all three |
| R1 | radiator spire, 0.18 tall, four ember fins a side | 1 | 75.0 | 0.00 | 0.14 | - | - | picture | sheds the drive reactor's heat: a square-topped column of iron posts round a dark core, ember fins reaching out to each side |
| W1 | armoured sensor slit 0.054 x 0.013 | 1 | 63.9 | 0.00 | 0.10 | - | - | picture | the pilot looks out through an ember-lit armoured slit in the stern block's sloping face: no canopy, no glass bubble |
| E1 | engine, bell 0.1 across | 1 | 99.1 | 0.06 | 0.04 | exhaust aft | - | picture | port drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals |
| E2 | engine, bell 0.1 across | 1 | 99.1 | -0.06 | 0.04 | exhaust aft | - | picture | starboard drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals |
| V1p | heat louvre 0.144 x 0.051 | 1 | 83.0 | 0.13 | 0.08 | - | - | picture | the drive room's heat louvre: slanted slats over an ember-lit recess (the concept's glowing flank slats) |
| V1s | heat louvre 0.144 x 0.051 | 1 | 83.0 | -0.13 | 0.08 | - | - | picture | the drive room's heat louvre: slanted slats over an ember-lit recess (the concept's glowing flank slats) |

Totals: 1 gun mounts with 3 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| black iron plate, frost-white oath stripe along the blade edge (paint stage) | 0.0 | 100.0 | whole hull |  |
| ember glow (the spire's fins, the drive throats, the sensor slit, the louvres) | 60.0 | 100.0 | the spire, the bells, the slit |  |
| no rust anywhere, no blue light, no canopy glass | 0.0 | 100.0 | factions.md Never; Ryan R254 |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the forged blade | 0.0 to 94.5 | -0.19 to 0.19 | -0.04 to 0.15 | black iron plate | one narrow forged blade: a low spine strip, the deck, upper facets out to a thin knife edge, lower facets, a flat belly; thickened at the stern into the armoured block |
| Radiator spire R1 | 71.9 to 78.2 | -0.07 to 0.07 | 0.17 to 0.30 | ember fins on iron | the fighter's one spire (SF3) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): .

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| gun feed (magazine) | 34.0 to 44.0 | -0.05 to 0.05 | -0.02 to 0.02 | the interceptor guns' ammunition drum and feed, behind the gun well |
| pilot (crew) | 66.0 to 72.5 | -0.05 to 0.05 | 0.05 to 0.10 | the pilot's cell: a prone couch under the sensor slit (one unaugmented pilot, no AI, lore 2.5) |
| reactor (core) | 73.5 to 80.0 | -0.07 to 0.07 | 0.05 to 0.12 | the drive reactor under the spire: its heat goes up into the spire |
| drive room (engroom) | 81.0 to 90.5 | -0.09 to 0.09 | -0.02 to 0.12 | the drive room and the two drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| stern block | 0.01 | over the pilot, the reactor and the drives |
| blade | 0.01 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 60.0 (seam wanders 59.3 to 60.4) | the stern block tears from the blade at the block's toe (only for the recipe's records: the game never breaks a craft) |

A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few rooms are here because the build contract needs an inside (tools/blender/build_sheets/contract.py); they cost few triangles.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 76.0 | 0.00 | 0.08 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 56 objects, 7 parts, 75 close pairs, 114 rays, 1 guns, 0 sensor pairs, 1 turrets swept, 2 cones, 3 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as the bomber, not the notes' 3.2 units.** docs/playbooks/scale.md, Squadron rows, binding (it wins over the design notes): "same wing frame as a fighter, only its load differs"; the fighter reads apart by its slim outline, not its length.
- **The spire is an upright, square-topped radiator with four ember fins reaching out to each side, standing on the stern block, not the concept's raked fin.** Ryan (R254): no tail fins; the council flagged spires drifting into stabiliser reads (design_notes_757.md); factions.md: the spires are radiators. A raked blade on the stern reads as a tail fin; fins out to the sides read as a radiator from the battle camera and from above.
- **The two drives are deep bells sunk in eight-sided armoured cowls in the stern face, smaller (0.077 across) and dim, not two big protruding drums with bright bells.** the production notes: SF3's bells render oversized and brighter than banked coals, the sheet dims and shrinks them (R55); the owner's rule for craft: drives are nozzle clusters inside armoured blocks.
- **The interceptor guns turn on a shallow traverse ring in an armoured well on the blade's back near the bow (the concept's dorsal bow recess), three barrels in one emitter cluster.** data.js guns fires all round (arc T): the fit check sweeps the guns through every bearing, which a gun in the nose face cannot do; the notes let the sheet pick the dorsal recess or the nose face, and DeepSeek's traverse ring is in the callout (R241, ships.md rule 11).
- **The guns elevate to 45 degrees (the fit check's band 0 to 45).** interceptor guns engage craft above and below the wing; dead astern the line clears the spire from 30 degrees up (the ARC test).
- **An armoured sensor slit for the pilot in the stern block's sloping face.** Ryan (R254): no canopy, an armoured slit at most; one unaugmented pilot, no AI (lore 2.5), so the pilot needs a view out.
- **The concept's glowing flank slats are the drive room's heat louvres; its glyph decals and small panels are not modelled.** every part has a job (R221); the decals are generator noise (production notes); fine greeble reads as a shrunken capital ship at this size (both design legs).
- **No hatches, lamps or attitude thrusters.** below what the battle camera shows on a 3.84 unit craft (about 30 px long); the drives turn the craft; bold and simple (production notes).
- **A small inside: the gun feed, the pilot's cell, the reactor under the spire, the drive room; one seam (B-1).** the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam (tools/blender/build_sheets/contract.py).

## Designed here, not shown in the picture

- The frost-white oath stripe along the blade edge, the trim and the ember lines are paint: the Sunward stack (issue 756) applies later.
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here.
