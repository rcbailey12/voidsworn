# voidsworn_SB4: Magazine Block bomber (Sunward Crusade bomber wing craft), build sheet

Sunward Crusade (voidsworn) | class Squadron | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 769 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py voidsworn_SB4 <out> render` rebuilds it from this file

**Length 1.6 world units** (data.js bomber (cls 'Squadron'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bombs | T | 2 | BT (2) |

| Check | Value |
|---|---|
| model length | 1.599 |
| length side | 1.601 |
| length top | 1.601 |
| length disagreement percent | 0.0 |
| beam top | 0.856 |
| beam bow | 0.857 |
| beam disagreement percent | 0.07 |
| height side | 0.499 |
| height bow | 0.499 |
| height disagreement percent | 0.0 |
| widest at station percent | 41.0 |
| hull beam | 0.8 |
| hull depth | 0.43 |
| L to B hull | 2.0 |
| L to H hull | 3.72 |
| prow overhang | 0.16 |
| outline iou percent | 90.5 |
| mass outline iou percent | 90.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| BT | bomb cassette, two tube mouths 0.21 across | 2 tubes | 3.0 | 0.00 | -0.01 | forward | T bombs | picture | the bomb payload (data.js bombs T, 2 shots): two tube mouths in the armoured bow cassette, one bomb from each every volley |
| E1 | engine, bell 0.1 across | 1 | 98.7 | 0.18 | 0.09 | exhaust aft | - | picture | port upper drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals |
| E2 | engine, bell 0.1 across | 1 | 98.7 | 0.18 | -0.09 | exhaust aft | - | picture | port lower drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals |
| E3 | engine, bell 0.1 across | 1 | 98.7 | -0.18 | 0.09 | exhaust aft | - | picture | starboard upper drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals |
| E4 | engine, bell 0.1 across | 1 | 98.7 | -0.18 | -0.09 | exhaust aft | - | picture | starboard lower drive: a deep bell sunk in an eight-sided armoured cowl, ember lining and plug, dim like banked coals |
| V1p | heat louvre 0.080 x 0.176 | 1 | 79.0 | 0.17 | 0.27 | - | - | picture | the drive room's heat louvre on the ridge's aft end: slanted slats over an ember-lit recess (the concept's glowing roof slits) |
| V1s | heat louvre 0.080 x 0.176 | 1 | 79.0 | -0.17 | 0.27 | - | - | picture | the drive room's heat louvre on the ridge's aft end: slanted slats over an ember-lit recess (the concept's glowing roof slits) |

Totals: 0 gun mounts with 0 barrels; 2 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| black iron plate, one frost-white oath band across one shoulder (paint stage) | 0.0 | 100.0 | whole hull |  |
| ember glow (the drive throats, the louvres, the sight slit) | 0.0 | 100.0 | the bells, the louvres, the sight |  |
| no rust anywhere, no blue light, no canopy glass, no bombs outside the hull | 0.0 | 100.0 | factions.md Never; Ryan R254 |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the magazine block | 10.0 to 94.0 | -0.40 to 0.40 | -0.22 to 0.21 | black iron plate | one massive faceted block built round the bomb magazine: deck, chamfers, the flank band, lower chamfers, a flat belly |
| Magazine ridge, port | 20.0 to 88.0 | 0.09 to 0.24 | 0.20 to 0.27 | darker iron | the armoured roof over one bomb row; the row feeds the port tube |
| Magazine ridge, starboard | 20.0 to 88.0 | -0.24 to -0.09 | 0.20 to 0.27 | darker iron | the armoured roof over one bomb row; the row feeds the starboard tube |
| Magazine belt, port | 23.0 to 81.0 | 0.39 to 0.42 | -0.11 to 0.10 | darker iron | a second forged layer over the flank band where the bomb rows lie; its ends are angled |
| Magazine belt, starboard | 23.0 to 81.0 | -0.42 to -0.39 | -0.11 to 0.10 | darker iron | a second forged layer over the flank band where the bomb rows lie; its ends are angled |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): .

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| magazine p (magazine) | 20.0 to 67.0 | 0.06 to 0.30 | -0.15 to 0.16 | the port bomb row: bombs racked nose forward, fed to the port tube |
| magazine s (magazine) | 20.0 to 67.0 | -0.30 to -0.06 | -0.15 to 0.16 | the starboard bomb row, fed to the starboard tube |
| bombardier (crew) | 20.0 to 32.0 | -0.05 to 0.05 | -0.03 to 0.11 | the bombardier and pilot between the rows, behind the sight slit (no AI, lore 2.5) |
| reactor (core) | 70.0 to 80.1 | -0.19 to 0.19 | -0.13 to 0.14 | the drive reactor |
| drive room (engroom) | 81.1 to 87.1 | -0.30 to 0.30 | -0.14 to 0.16 | the drive room and the four drives' feeds |
| bombs (magazine) | 24.0 to 59.0 | -0.23 to 0.23 | -0.05 to 0.05 | eight bombs racked in two rows of four (the magazine the hull is built round) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| block | 0.01 | the magazine block's plate |
| bow cassette | 0.03 | the heaviest armour, round the tubes |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 68.5 (seam wanders 67.8 to 69.2) | the magazine tears from the reactor section (only for the recipe's records: the game never breaks a craft) |

A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rooms are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber's story; they cost few triangles.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 75.0 | 0.00 | 0.00 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 75 objects, 7 parts, 64 close pairs, 64 rays, 0 guns, 0 sensor pairs, 0 turrets swept, 4 cones, 4 apertures, 2 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as the fighter, not the notes' 4.2 units.** docs/playbooks/scale.md, Squadron rows, binding (it wins over the design notes); the bomber reads apart by its mass: about twice the fighter's beam and depth.
- **The two tube mouths sit in a deep armoured cassette that is the bow face: dark bores 0.22 deep with the next bomb's nose seated in each, heavy twelve-sided rims with forged lugs.** R244: a round opening is a real recess with depth and detail, never a disc; the notes: ordnance internal, the hull IS the magazine.
- **The tubes are fixed forward, not on a traverse cassette.** a craft turns onto its target on a strafing run; a turning cassette in the bow face would need the hull round it cut free. The weapon-match table allows bombs (arc T) on a fixed bomb-tube launcher (weapon_match.py FITS, the Board's reading of rule 11 for craft).
- **The rims are worked iron (lighter) round the dark mouths.** the concept's worn grey rims; a light ring round a dark mouth is what reads at the close cameras.
- **The bombardier's sight slit between the mouths belongs to the cassette.** it aims the tubes (the concept's recessed sensor slit at the centre of the bow face).
- **Four drives: two pairs of deep bells sunk in eight-sided armoured cowls in the stern face, not the concept's side pods with rows of small glowing nozzles.** the owner's rule for craft: drives are nozzle clusters inside armoured blocks; four bold bells read at the battle camera where a row of small nozzles would not.
- **The concept's many flank panels and boxes become one forged belt a side over the flank band; the small grilles and boxes are not modelled.** fine greeble reads as a shrunken capital ship at this size (both design legs, production notes); R244: the flanks are angled chamfers round a band with a raised belt, never a flat wall.
- **The two dorsal blocks are the magazine ridges, one over each bomb row; their aft ends carry the drive room's heat louvres (the concept's ember roof slits).** every part has a job (R221): each ridge roofs the row that feeds one tube.
- **No hatches, lamps or attitude thrusters.** below what the battle camera shows on a 3.84 unit craft; the drives turn the craft; bold and simple.
- **A small inside: two magazine rows with eight bombs, the bombardier's cell, the reactor, the drive room; one seam (B-1).** the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam, and the magazine is the bomber's story.

## Designed here, not shown in the picture

- The frost-white oath band across one shoulder and the ember trim are paint: the Sunward stack (issue 756) applies later.
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here.
- At the battle camera the bomber reads by its block and its four ember drives; the two bow mouths read at the close cameras (voidsworn_SF3_SB4_battle_cam.jpg).
