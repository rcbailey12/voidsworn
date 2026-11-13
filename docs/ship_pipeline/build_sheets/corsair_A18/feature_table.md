# corsair_A18: Hullbreaker raider (the Sniffer), build sheet

Ashfall Hullbreakers (corsair) | class Frigate | version 1 (first sheet (issue 633)), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus633\corsair_A18\corsair_A18\corsair_A18_blockout.blend`

**Length 6.5 world units** (data.js c_raider (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 6.507 |
| length side | 6.525 |
| length top | 6.537 |
| length disagreement percent | 0.19 |
| beam top | 2.85 |
| beam bow | 2.85 |
| beam disagreement percent | 0.0 |
| height side | 2.2 |
| height bow | 2.2 |
| height disagreement percent | 0.0 |
| widest at station percent | 80.3 |
| hull beam | 1.46 |
| hull depth | 0.98 |
| L to B hull | 4.45 |
| L to H hull | 6.63 |
| prow overhang | 0.23 |
| outline iou percent | 77.8 |
| mass outline iou percent | 78.4 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | wake-sniffer scoop with a grille, 0.3 across, 0.6 deep | 1 | 2.7 | 0.00 | 0.03 | forward | - | picture | the scoop in the bow face: it tastes the wake of ships ahead (designs.md: the chin scoop, moved up into the face) |
| SL1 | vision slit 0.3 x 0.09 | 1 | 23.0 | -0.98 | -0.05 | - | - | picture | vision slit in the sponson's outboard face: the dish operator's port |
| SL2 | vision slit 0.2 x 0.07 | 1 | 30.2 | 0.22 | 0.56 | - | - | picture | slit in the fore spine block's slope, port (the dish fills the starboard view) |
| HS1 | square hatch 0.2 | 1 | 72.9 | 0.45 | 0.54 | - | - | picture | crew hatch on the aft spine block, port |
| HB1 | framed deck box 0.3 x 0.2 | 1 | 60.2 | 0.20 | 0.69 | - | - | picture | framed box on the sensor block |
| HB2 | framed deck box 0.3 x 0.3 | 1 | 82.1 | 0.00 | 0.61 | - | - | picture | ready-use locker on the aft spine block |
| AN1 | antenna array, 0.7 tall, 2 whips | 1 | 71.1 | -0.20 | 0.61 | - | - | picture | comms array on the aft spine block: calls the pack in on what the dish heard |
| VT1 | louvre panel 0.5 x 0.2 | 1 | 93.1 | 0.00 | 0.50 | - | - | picture | engine-room louvre on the engine block roof |
| D1 | listening dish, 1.0 across | 1 | 20.2 | -0.55 | 0.53 | 15 deg off the bow to starboard, +84 elev | - | picture | the one oversized listening dish, 1.0 across (two thirds of the beam), set nearly flush on the raised sponson, canted a little forward, on the starboard shoulder |
| J1 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 16.8 | 0.34 | -0.72 | hook forward and down | - | picture | port grabber arm under the chin: pins a fleeing hull long enough for the pack to catch up |
| J2 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 16.8 | -0.34 | -0.72 | hook forward and down | - | picture | starboard grabber arm under the chin: pins a fleeing hull long enough for the pack to catch up |
| PH1 | pipe run, 0.06 bore | 1 | 13.0 | 0.00 | -0.35 | - | - | picture | the rams' hydraulic feed |
| T1 | twin turret | 2 barrels | 43.7 | 0.02 | 0.66 | forward, +6 elev | T autocannon | picture | twin autocannon turret on the spine's gun block, all round (data.js c_raider's only weapon) |
| E1 | engine, bell 0.7 across | 1 | 99.8 | 1.10 | 0.00 | exhaust aft | - | picture | port drum, the larger: the overburn engine |
| E2 | engine, bell 0.6 across | 1 | 99.4 | -1.01 | 0.00 | exhaust aft | - | picture | starboard drum: the overburn engine |
| E3 | engine, bell 0.4 across | 1 | 99.0 | 0.00 | -0.09 | exhaust aft | - | picture | small centre bell under the block |
| Q1 | attitude thruster quad | 1 | 41.1 | 0.72 | -0.36 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 41.1 | -0.72 | -0.36 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 70.6 | 0.73 | -0.37 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 70.6 | -0.73 | -0.37 | - | - | designed | stern |
| L0p | running light | 1 | 16.8 | 0.68 | -0.36 | - | - | picture |  |
| L1p | running light | 1 | 56.0 | 0.73 | -0.36 | - | - | picture |  |
| L2p | running light | 1 | 76.0 | 0.74 | -0.36 | - | - | picture |  |
| L1s | running light | 1 | 56.0 | -0.73 | -0.36 | - | - | picture |  |
| L2s | running light | 1 | 76.0 | -0.74 | -0.36 | - | - | picture |  |

Totals: 1 gun mounts with 2 barrels; 0 launcher tubes; 3 engines; 1 intakes; 1 dishes; 2 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot and weathered plate | 0.0 | 99.8 | whole hull |  |
| bare iron sponson | 13.4 | 31.9 | starboard bow shoulder |  |
| pale Hegemony trophy plate | 47.6 | 62.9 | port flank |  |
| violet Eclipse plate | 33.0 | 37.6 | port foredeck |  |
| dried-blood red patch | 71.4 | 79.8 | aft spine roof |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Base hull (wedge bow, body, aft taper) | 3.6 to 93.4 | -0.73 to 0.73 | -0.53 to 0.45 | soot and patched plate | the sloped wedge bow over a cut-in chin, then the long body |
| Lower hull band | 18.4 to 89.8 | -0.71 to 0.71 | -0.57 to -0.36 | dark soot | the belly steps in under the flank |
| Engine pylon port | 81.4 to 92.9 | 0.55 to 0.92 | -0.15 to 0.12 | iron | short pylon out to the engine drum |
| Engine pylon starboard | 81.4 to 92.9 | -0.86 to -0.55 | -0.15 to 0.12 | iron | short pylon out to the engine drum |
| Engine block | 90.6 to 95.2 | -0.56 to 0.56 | -0.42 to 0.50 | soot, steel |  |
| Dish sponson (starboard bow shoulder) | 12.2 to 30.7 | -0.98 to -0.20 | -0.31 to 0.53 | bare iron, patched | bolted onto the starboard shoulder, swelling the outline from above (designs.md's swollen shoulder, on the picture's side) |
| S1 fore spine block | 28.4 to 38.6 | -0.45 to 0.45 | 0.36 to 0.60 | soot with dried-blood patches | stacked spine block, top 0.60 |
| S2 gun block | 39.6 to 47.9 | -0.41 to 0.45 | 0.36 to 0.66 | soot with dried-blood patches | stacked spine block, top 0.66 |
| S3 mid spine block | 48.8 to 56.2 | -0.43 to 0.37 | 0.36 to 0.61 | soot with dried-blood patches | stacked spine block, top 0.61 |
| S4 sensor block | 57.1 to 66.0 | -0.41 to 0.45 | 0.36 to 0.69 | soot with dried-blood patches | stacked spine block, top 0.69 |
| S5 aft spine block | 66.9 to 86.0 | -0.45 to 0.45 | 0.36 to 0.61 | soot with dried-blood patches | stacked spine block, top 0.61 |
| Flank brick 1 port | 32.2 to 45.3 | 0.52 to 0.80 | -0.23 to 0.21 | patched plate | armour brick bolted on the flank |
| Flank brick 2 port | 65.2 to 76.0 | 0.53 to 0.82 | -0.23 to 0.12 | patched plate | armour brick bolted on the flank |
| Flank brick 1 starboard | 36.0 to 47.6 | -0.80 to -0.52 | -0.23 to 0.16 | patched plate | armour brick bolted on the flank |
| Flank brick 2 starboard | 52.9 to 65.2 | -0.83 to -0.53 | -0.23 to 0.14 | patched plate | armour brick bolted on the flank |
| Flank brick 3 starboard | 67.5 to 76.0 | -0.82 to -0.53 | -0.23 to 0.20 | patched plate | armour brick bolted on the flank |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck -0.16 (16% to 89%).

Bulkhead and frame stations: F0 15.3%, F1 29.4%, F2 54.5%, F3 74.5%, F4 88.3%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| sensor room (bridge) | 15.3 to 26.8 | -0.30 to 0.30 | -0.11 to 0.21 | the listening room under the dish: plotters and the dish feed |
| grabber rams (machinery) | 16.8 to 26.0 | -0.29 to 0.29 | -0.39 to -0.22 | rams and winches for the chin grabbers |
| kennel nook (crew) | 36.0 to 43.7 | -0.48 to 0.48 | -0.44 to -0.22 | boarding crew kennel |
| loot hold (hold) | 46.0 to 52.9 | -0.39 to 0.39 | -0.44 to -0.22 | a loot hold the size of a closet (designs.md) |
| ready magazine (magazine) | 40.2 to 46.0 | -0.25 to 0.25 | -0.11 to 0.30 | autocannon belts under the turret |
| crew space (crew) | 56.8 to 72.2 | -0.43 to 0.43 | -0.11 to 0.30 | crew bunks and galley, scavenged frames |
| core (core) | 58.3 to 72.9 | -0.39 to 0.39 | -0.44 to -0.22 | reactor core (hp_core) |
| engine room (engroom) | 76.0 to 87.5 | -0.48 to 0.48 | -0.44 to 0.26 | engine room and the overburn feeds to the drums |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| wedge bow (forward of 1.6) | 0.12 | face plate and the sponson's front |
| flank bricks | 0.08 | bolted bricks over the flank |
| spine | 0.06 |  |
| belly | 0.07 | the flat belly, the band stepping in |
| engine end | 0.05 | thinnest: the raider trades armour for speed |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 33.4 (seam wanders 32.5 to 35.3) | behind the sensor head: the head tears away as one ragged piece with the dish still on it (designs.md), opening the listening room and the grabber rams |

Full interiors through the hull (R215), hidden until a piece breaks. Patch plates tear first; the hull parts at the weld behind the head, ragged (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 66.0 | 0.00 | -0.33 |  |  |  |
| hp_breach_0 | 36.8 | 0.76 | 0.08 | port | prow |  |
| hp_breach_1 | 60.6 | -0.76 | -0.05 | stbd | mid |  |
| hp_breach_2 | 82.1 | 0.75 | -0.05 | port | eng |  |
| hp_rcs_0 | 27.6 | 0.72 | -0.12 | port |  |  |
| hp_rcs_1 | 27.6 | -0.72 | -0.12 | stbd |  |  |
| hp_board_0 | 53.7 | 0.74 | -0.29 | port |  |  |
| hp_board_1 | 53.7 | -0.74 | -0.29 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 178 objects, 25 parts, 357 close pairs, 192 rays, 1 guns, 1 turrets swept, 7 cones, 11 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **One gun: a twin autocannon turret on the spine's gun block.** data.js c_raider carries one weapon, autocannon T (R221: weapons from data.js); the picture's rows of flank guns, designs.md's two bow casemates and its rocket rack have no slot, so they are not built.
- **The one big ear: an oversized listening dish (1.1 across, three quarters of the beam) on a bolted sponson that swells the PORT bow shoulder.** designs.md ("a little brick with one big ear", "the port shoulder swollen out past the hull line by the dish mount"); the v3 picture draws a flush disc on the starboard foredeck. On the port side it gives the frigate its own outline from above (R233).
- **Lopsided engines: two drums on short pylons at the stern quarters, the starboard drum clearly larger, and one small centre bell.** designs.md (two bells, the starboard larger) with the picture's outrigger drums; the picture's three stacked centre bells become one, so the stern does not read as A16's pods.
- **The wake-sniffer scoop sits in the bow face, behind a grille.** designs.md puts it under the chin; the picture's face is a grilled mouth, and the chin carries the grabbers.
- **One pair of small grabber arms under the chin, splayed a little.** designs.md: one pair (A17 carries two pairs); the picture shows a pair of hooked claws there.
- **The spine is five stacked blocks with gaps, the gun block and the sensor block the tallest.** the picture's raised spine; stacked and bolted scrap brick (R196, R197), not one smooth deckhouse.
- **Armour bricks bolted on the flanks, three to port and two to starboard; the starboard flank keeps a pale Hegemony trophy plate.** the picture's patchwork flank; designs.md's trophy plate.
- **Four small attitude thrusters.** a ship in space needs them to turn (the overburn raider turns hard).
- **Insides: one deck with the listening room, a kennel nook, a closet loot hold, the core and the engine room.** designs.md; R209, R215.

## Designed here, not shown in the picture

- Belly detail between the grabber housings and the engine block is designed here; the picture does not show the underside.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
