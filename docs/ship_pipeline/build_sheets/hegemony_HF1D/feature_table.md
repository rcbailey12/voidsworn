# hegemony_HF1D: Spined Shield fighter (Hegemony Navy fighter wing craft), build sheet

Hegemony Navy (hegemony) | class Squadron | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py hegemony_HF1D <out> render` rebuilds it from this file

**Length 1.6 world units** (data.js fighter (cls 'Squadron', the Hegemony wing: hegemony sq 'fighter'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | guns | T | 3 | G1 (3) |

| Check | Value |
|---|---|
| model length | 1.597 |
| length side | 1.6 |
| length top | 1.6 |
| length disagreement percent | 0.0 |
| beam top | 0.659 |
| beam bow | 0.659 |
| beam disagreement percent | 0.0 |
| height side | 0.179 |
| height bow | 0.179 |
| height disagreement percent | 0.0 |
| widest at station percent | 91.7 |
| hull beam | 0.66 |
| hull depth | 0.13 |
| L to B hull | 2.42 |
| L to H hull | 12.31 |
| prow overhang | 0.0 |
| outline iou percent | 88.7 |
| mass outline iou percent | 88.8 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| G1 | interceptor guns, triple turret | 3 barrels | 19.5 | 0.00 | 0.04 | forward, +3 elev | T guns | picture | the interceptor guns (data.js guns T, 3 shots): three barrels grouped tight in one cassette on a flush ring in the framed recess at the prow; every volley fires all three |
| W1 | sensor slit 0.054 x 0.009 | 1 | 32.7 | 0.00 | 0.07 | - | - | picture | the pilot's sensor slit in its own slot in the ridge's sloped front face, above the recess: dark glass, no canopy |
| E1 | drive, rectangular slit 0.26 x 0.05, three cells | 1 | 99.9 | 0.00 | 0.03 | exhaust aft | - | picture | the drive: one recessed ion-blue slit across the stern block's aft face, three cells behind upright guide vanes (the faction's flat row of rectangular nozzles), in an armoured pod |

Totals: 1 gun mounts with 3 barrels; 0 launcher tubes; 1 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| pale grey module plate, steel-blue trim on the bands, the edging and the frame (paint stage) | 0.0 | 100.0 | whole hull |  |
| implant-blue light: the edging line, the ridge's foot, the drive slit | 10.0 | 100.0 | the blue line |  |
| no warm light, no rust, no canopy glass; the sensor slit stays dark | 0.0 | 100.0 | factions.md Never; Ryan R254; the round 3 notes |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the machined wedge | 0.0 to 95.7 | -0.33 to 0.33 | -0.06 to 0.07 | pale grey module plate | one sleek machined wedge: a flat deck, the flank in three stepped layers (the stepped plate edging), a flat belly; the prow slimmed to a point, the stern corners cut |
| The spine ridge | 30.6 to 87.6 | -0.07 to 0.07 | 0.04 to 0.10 | pale grey module plate | the low broad flat-topped ridge, squared in section, from the bow block's top aft to the stern block; its sloped front face is the bow block's single-stage bevel |
| The stern block | 83.6 to 95.7 | -0.21 to 0.21 | 0.06 to 0.11 | pale grey module plate | a raised armoured block across the stern, as tall as the ridge plus a step, a sloped front; the drive pod stands out of its aft face |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): .

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| gun feed (magazine) | 23.0 to 30.1 | -0.05 to 0.05 | -0.03 to 0.03 | the cassette's charge cells and feed, under the framed recess |
| pilot (crew) | 36.1 to 48.1 | 0.00 to -0.00 | -0.03 to 0.08 | the pilot's cell under the ridge, behind the sensor slit (a linked crew of one, lore 3) |
| reactor (core) | 65.1 to 80.2 | 0.00 to -0.00 | -0.04 to 0.08 | the drive reactor, white-lit, under the ridge's aft end |
| drive room (engroom) | 84.2 to 93.2 | 0.00 to -0.00 | -0.04 to 0.10 | the drive room and the slit's feed, inside the stern block |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| wedge | 0.01 | machined plate over the whole hull |
| stern block | 0.01 | over the reactor and the drive |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 60.1 (seam wanders 59.5 to 60.7) | the craft parts at its mid module band (Hegemony: in modules; only for the recipe's records: the game never breaks a craft) |

A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few rooms are here because the build contract needs an inside (tools/blender/build_sheets/contract.py); they cost few triangles.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 72.1 | 0.00 | 0.02 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 38 objects, 3 parts, 51 close pairs, 97 rays, 1 guns, 0 sensor pairs, 1 turrets swept, 1 cones, 1 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft.** docs/playbooks/scale.md, Squadron rows, binding; the fighter reads apart from the bomber by its outline, not its length.
- **The gun cassette turns: it sits on a flush ring inside the framed recess, a low flat housing round a cassette of three tightly grouped barrels; at rest it faces forward out of its frame.** data.js guns fires all round (arc T), so the guns are a turret (ships.md rule 11 for craft, weapon_match.py FITS guns: turret); the recess frame, the grouping and the place at the prow are the concept's.
- **The recess is a flat framed well in the prow deck, not a vertical bow face.** the round 3 notes put the cassette in a face recess, the slim render on the sloped deck near the tip; a turret needs a deck under it, and the slim prow is too thin for a face recess. The render stands as the silhouette, the sheet keeps the frame and the place.
- **The ridge starts behind the gun recess (its sloped front face holds the sensor slit) and runs to the stern block, no taller than it.** a turning cassette needs the deck clear behind it: the barrels clear the ridge front by 0.06 when turned aft (the fit check sweeps every bearing); the notes put the slit in its own slot above the recess.
- **The sensor slit is dark glass with a machined frame, not lit blue.** the round 3 notes: the render lights the slot blue; the sheet keeps it dark, ion glow only at the stern.
- **The hull keeps HF1C's depth: about 0.075 of the length at the stern, more with the ridge and the stern block.** the round 3 notes: the slim render reads very flat from above; the hull keeps HF1C's depth so it reads as a machined wedge, never a flat wing.
- **The stepped edging is three stepped flank layers, each a 0.015 step out going down, with the implant-blue line along the upper step.** HF1B's edging kept flush and shallow (DeepSeek): steps, never ledges or wings; factions.md: a pale wedge with a line of blue light.
- **The drive slit is one recessed rectangular mouth split by two upright guide vanes into three cells, in an armoured pod that stands 0.07 out of the stern face.** factions.md: a flat row of rectangular blue-white nozzles; the owner's rule for craft: nozzle clusters inside armoured blocks.
- **Three module bands cross the hull (at the bow block, midships and the stern block); the craft gives way at the midships band (B-1).** factions.md: the Hegemony breaks in modules, at the bands; the paint stack keys its module band on every *_bandseam_* joint.
- **No hatches, lamps, thrusters, drone bays or antennas.** below what the battle camera shows on a 3.84 unit craft (about 30 px long); the drive turns the craft; bold and simple.
- **A small inside: the gun feed, the pilot's cell, the reactor, the drive room; one seam (B-1).** the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam (tools/blender/build_sheets/contract.py).

## Designed here, not shown in the picture

- Pale grey, steel-blue trim and the blue line are schematic colour zones: the Hegemony paint stack (issue 780) applies later.
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here.
