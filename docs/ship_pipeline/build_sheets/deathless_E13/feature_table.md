# deathless_E13: Eclipse mote (the fan frigate), build sheet

Eclipse (deathless) | class Frigate | version 1 (first sheet (issue 739)), 2026-11-15 | blockout: built in the cloud sandbox (Blender 5.3 bpy module, Cycles CPU), not kept; `build.py -- deathless_E13 <out> render` rebuilds it

**Length 6.5 world units** (data.js d_scythe (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5 (drawn x SHIP_K 1.6 = 10.4 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | gauss | T | 3 | T1 (2) |

| Check | Value |
|---|---|
| model length | 6.515 |
| length side | 6.537 |
| length top | 6.537 |
| length disagreement percent | 0.0 |
| beam top | 3.688 |
| beam bow | 3.688 |
| beam disagreement percent | 0.0 |
| height side | 1.312 |
| height bow | 1.325 |
| height disagreement percent | 0.19 |
| widest at station percent | 23.9 |
| hull beam | 0.8 |
| hull depth | 0.49 |
| L to B hull | 8.12 |
| L to H hull | 13.27 |
| prow overhang | 0.0 |
| outline iou percent | 51.1 |
| mass outline iou percent | 49.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| C1 | caged core of trapped light, 0.6 across | 1 | 64.5 | 0.00 | 0.00 | - | - | picture | the trapped light core between the dart and the stern block, under the crest plate, seen through the gaps beside it |
| T1 | null cannon, twin turret | 2 barrels | 80.3 | 0.00 | 0.47 | forward, +4 elev | T gauss | picture | the null cannon: twin rail pairs through a crescent shade on the block roof at the fan's root, firing forward over the plates |
| E1 | engine, bell 0.7 across | 1 | 99.8 | 0.00 | 0.03 | exhaust aft | - | picture | the small thin eclipse ring of pale light at the stern, no flame |
| Q1p | attitude thruster quad | 1 | 19.2 | 0.28 | -0.17 | - | - | designed | nose lower chamfer, firing down and out under the plates |
| Q2p | attitude thruster quad | 1 | 85.2 | 0.35 | -0.27 | - | - | designed | stern block lower chamfer, firing down and out |
| L0p | running light | 1 | 28.4 | 0.36 | -0.08 | - | - | picture | corona strip light low on the dart's flank |
| L1p | running light | 1 | 41.4 | 0.39 | -0.08 | - | - | picture | corona strip light low on the dart's flank |
| V1p | louvre panel 0.2 x 0.2 | 1 | 83.7 | 0.42 | 0.10 | - | - | picture | heat slot panel on the block flank, aft of the plates' roots |
| H1p | square hatch 0.2 | 1 | 83.3 | 0.12 | -0.34 | - | - | picture | belly hatch on the stern block |
| Q1s | attitude thruster quad | 1 | 19.2 | -0.28 | -0.17 | - | - | designed | nose lower chamfer, firing down and out under the plates |
| Q2s | attitude thruster quad | 1 | 85.2 | -0.35 | -0.27 | - | - | designed | stern block lower chamfer, firing down and out |
| L0s | running light | 1 | 28.4 | -0.36 | -0.08 | - | - | picture | corona strip light low on the dart's flank |
| L1s | running light | 1 | 41.4 | -0.39 | -0.08 | - | - | picture | corona strip light low on the dart's flank |
| V1s | louvre panel 0.2 x 0.2 | 1 | 83.7 | -0.42 | 0.10 | - | - | picture | heat slot panel on the block flank, aft of the plates' roots |
| H1s | square hatch 0.2 | 1 | 83.3 | -0.12 | -0.34 | - | - | picture | belly hatch on the stern block |

Totals: 1 gun mounts with 2 barrels; 0 launcher tubes; 1 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| violet-black shade plates, deep violet dart and block (paint stage) | 0.0 | 99.8 | whole ship |  |
| green-white corona line | 6.9 | 80.6 | every plate's outer rim; both rims of the crest plate |  |
| core light | 57.6 | 71.4 | the core under the crest plate |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the dart | 0.0 to 59.3 | -0.40 to 0.40 | -0.26 to 0.23 | deep violet plate | the short dart under the fan: a chamfered octagon section, the nose ahead of the plate tips |
| Stern block | 69.6 to 86.7 | -0.42 to 0.42 | -0.34 to 0.40 | violet plate | a chamfered block from the core's aft hub to the engine, the gun on its roof |
| Root collar | 72.1 to 81.5 | -0.47 to 0.47 | -0.38 to 0.40 | mauve plate | the stepped band where the plates' roots gather on the block |
| Shade plate, crest | 6.6 to 73.2 | -0.25 to 0.25 | 0.05 to 0.47 | violet-black shade | a layered slab gathered at the root collar, its tip forward |
| Shade plate, inner port | 8.1 to 78.1 | 0.36 to 1.19 | -0.04 to 0.34 | violet-black shade | a layered slab gathered at the root collar, its tip forward |
| Shade plate, inner starboard | 8.1 to 78.1 | -1.19 to -0.36 | -0.04 to 0.34 | violet-black shade | a layered slab gathered at the root collar, its tip forward |
| Shade plate, outer port | 14.3 to 81.2 | 0.42 to 1.82 | -0.23 to 0.12 | violet-black shade | a layered slab gathered at the root collar, its tip forward |
| Shade plate, outer starboard | 14.3 to 81.2 | -1.82 to -0.42 | -0.23 to 0.12 | violet-black shade | a layered slab gathered at the root collar, its tip forward |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck -0.06 (15% to 54%); block deck 0.02 (76% to 85%).

Bulkhead and frame stations: F0 16.1%, F1 27.6%, F2 39.9%, F3 52.2%, B0 75.7%, B1 82.1%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| dark decks (darkdeck) | 16.9 to 26.9 | -0.14 to 0.14 | -0.02 to 0.10 | dark decks: the machine crew's stations, unlit |
| archive vault (archive) | 28.4 to 39.1 | -0.24 to 0.24 | -0.02 to 0.12 | the archive vault: the Starwrights' stored selves |
| capacitors (machinery) | 40.7 to 51.4 | -0.22 to 0.22 | -0.02 to 0.12 | the core's capacitor bank and the phase drive |
| conduits (machinery) | 16.9 to 51.4 | -0.12 to 0.12 | -0.18 to -0.09 | power conduits from the core along the keel |
| magazine (magazine) | 76.3 to 81.4 | -0.20 to 0.20 | 0.07 to 0.24 | the null cannon's capacitor magazine, under the gun |
| engine room (engroom) | 82.4 to 85.2 | -0.22 to 0.22 | -0.20 to 0.22 | the engine room and the drive's feed |
| phase coils (machinery) | 76.3 to 81.4 | -0.22 to 0.22 | -0.20 to -0.04 | the phase coils (data.js ab phase) |
| core (ecore) | 60.8 to 68.2 | -0.24 to 0.24 | -0.24 to 0.24 | the core of trapped light, in the open under the crest plate (hp_core) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| shade plates | 0.09 | the fan: the thickest armour, held forward |
| dart | 0.06 | thin; the fan shades it |
| stern block | 0.12 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 64.5 (seam wanders 62.5 to 66.8) | the dart parts from the stern block at the core: the cage bursts, the nose and the plates' fore halves tear away (a ragged bite where the core goes) |
| B-2 | 3.8 to 59.1 (along) | the crest plate peels from the dart, band by band, over the fore compartment (a level plane at 0.25) |

Eclipse breaks in layers (factions.md): the crest plate peels first, then the dart parts from the block at the core and the fan's fore halves go with it; full interiors throughout (R215), hidden until a piece breaks.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 64.5 | 0.00 | 0.00 |  |  |  |
| hp_breach_0 | 23.0 | 0.85 | 0.10 | port | prow | on the inner shade plate |
| hp_breach_1 | 71.1 | -0.68 | 0.05 | stbd | eng | on the outer shade plate near its root |
| hp_rcs_0 | 19.2 | 0.28 | -0.17 | port |  |  |
| hp_rcs_1 | 19.2 | -0.28 | -0.17 | stbd |  |  |
| hp_board_0 | 49.9 | 0.36 | -0.10 | port |  |  |
| hp_board_1 | 49.9 | -0.36 | -0.10 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 96 objects, 15 parts, 83 close pairs, 146 rays, 1 guns, 0 sensor pairs, 1 turrets swept, 5 cones, 8 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The plates gather at the stern by the engine and fan forward, their tips flanking the nose.** the accepted beauty, the sheet's plan and the round 1 Fan direction all draw it so; designs.md says rooted at the bow. The pictures are what Ryan accepted (R229: the whole concept first).
- **Five plates: a crest plate on the spine and two a side, each with a stepped second layer on its root half.** designs.md's count; the pictures' extra blade edges read as the stepped layers. A generated sheet never settles counts (ships.md 5).
- **The outer plates bank down and outward and overlap the inner ones' edges.** the front of the fan reads as a layered stack (the sheet's front view, redrawn as a stack, issue 627) and the plates hold each other at their overlap.
- **The core sits in the open between the dart and the stern block under the crest plate, the spine entering its hub collars.** designs.md: "in a gap between the plates near their root ... partly covered, never a bare bulb"; the beauty shows it on one side only, a matched build puts it on the axis.
- **The gun is the null cannon on the block roof at the plates' root (data.js gauss T).** designs.md and the sheet; the beauty underplays it. Built from the lore (R221): twin rail pairs through a crescent shade.
- **Engines are eclipse rings, not flame.** factions.md: "no flaming bells. An eclipse ring of pale light".
- **Panels dead even, aligned rows on every face, tone in ordered bands (R243).** Ryan, Nov 13: "make the eclipse panels actually panels and dead even and ordered to align"; the kit lays them by size (eclipse parts.py even_panels).
- **Thrusters, belly hatches, heat panels and corona strip lights added.** a ship in space needs thrusters; the picture shows no underside.
- **The crest plate peels on a level plane at 0.25 over the fore compartment (B-2).** Eclipse breaks in layers: the shade plates peel first (factions.md); one level plane takes the crest and clears the dart's insides.
- **The fan slimmed and flattened to the concept sheet's measured proportions (envelope length to beam 1.79 against the sheet's 1.87; the core 0.64 across).** the Board's massing check (ships.md 2c): the first layout read 1.38, a third too broad, and twice the sheet's height. The side stays taller than the sheet's (length to height 5.1 against 9.6) because the gun housing and the engine ring stand above and below the plates; the sheet's side view draws the gun as a thin fin.
- **From above the mote is a leaf of blades with a dart nose, widest at a quarter of its length.** family distinctness (R233): the flagship is a crescent, the cruiser a split oval ring, the flare one closed ring; no Eclipse class is a scaled copy of another from above.

## Designed here, not shown in the picture

- The underside of the dart and the block is designed here; the picture shows no underside.
- Q1p (attitude thruster quad): nose lower chamfer, firing down and out under the plates.
- Q2p (attitude thruster quad): stern block lower chamfer, firing down and out.
- Q1s (attitude thruster quad): nose lower chamfer, firing down and out under the plates.
- Q2s (attitude thruster quad): stern block lower chamfer, firing down and out.
