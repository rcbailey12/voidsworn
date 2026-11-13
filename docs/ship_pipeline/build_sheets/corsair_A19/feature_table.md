# corsair_A19: Hullbreaker gutship (the Mauler), build sheet

Ashfall Hullbreakers (corsair) | class Destroyer | version 1 (first sheet (issue 633)), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus633\corsair_A19\corsair_A19\corsair_A19_blockout.blend`

**Length 9.5 world units** (data.js c_reaver (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 9.502 |
| length side | 9.525 |
| length top | 9.525 |
| length disagreement percent | 0.0 |
| beam top | 3.225 |
| beam bow | 3.288 |
| beam disagreement percent | 0.66 |
| height side | 2.75 |
| height bow | 2.75 |
| height disagreement percent | 0.0 |
| widest at station percent | 50.5 |
| hull beam | 1.76 |
| hull depth | 0.84 |
| L to B hull | 5.4 |
| L to H hull | 11.31 |
| prow overhang | 0.78 |
| outline iou percent | 77.9 |
| mass outline iou percent | 80.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| HB1 | framed deck box 0.4 x 0.3 | 1 | 56.6 | 0.30 | 0.62 | - | - | picture | ready-use locker for the scatter crews on the battery block |
| HB2 | framed deck box 0.3 x 0.3 | 1 | 77.7 | 0.28 | 0.60 | - | - | picture | framed box on the aft spine block |
| HS1 | square hatch 0.3 | 1 | 75.6 | 1.12 | -0.18 | - | - | picture | crew hatch in the port side block |
| HS2 | square hatch 0.3 | 1 | 91.7 | 0.94 | 0.12 | - | - | picture | engine room hatch on the stern block, port |
| SL1 | vision slit 0.2 x 0.06 | 1 | 33.8 | 0.30 | 0.53 | - | - | picture | slit in the fore spine block's slope |
| VSp | louvre panel 0.4 x 0.3 | 1 | 85.6 | 0.94 | 0.32 | - | - | picture | engine room louvre |
| VSs | louvre panel 0.4 x 0.3 | 1 | 85.6 | -0.94 | 0.32 | - | - | picture | engine room louvre |
| AN1 | antenna array, 0.8 tall, 3 whips | 1 | 87.1 | 0.50 | 0.66 | - | - | picture | comms array on the stern block: the pack's gun ship hears the Sniffer's calls |
| R1 | rocket casemate in the bow face, one long tube | 1 tubes | 8.1 | 0.32 | 0.00 | forward | F torp | picture | port casemate: one long rocket tube on a brace (the long-barrelled one) |
| R2 | rocket casemate in the bow face, 3 short fat tubes | 3 tubes | 8.1 | -0.30 | -0.01 | forward | F torp | picture | starboard casemate: three short fat tubes banded together (the short and fat one) |
| I1 | wake-sniffer scoop with a grille, 0.2 across, 0.4 deep | 1 | 8.9 | 0.00 | -0.58 | forward | - | picture | chin scoop under the face (designs.md) |
| J1 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 15.0 | 0.42 | -0.72 | hook forward and down | - | picture | port chin grabber: pins a hull against the bow casemates |
| J3 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 39.3 | 0.48 | -0.86 | hook forward and down | - | picture | port forefoot grabber: the second bite, under the body |
| J2 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 15.0 | -0.42 | -0.72 | hook forward and down | - | picture | starboard chin grabber: pins a hull against the bow casemates |
| J4 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 39.3 | -0.48 | -0.86 | hook forward and down | - | picture | starboard forefoot grabber: the second bite, under the body |
| PH1 | pipe run, 0.07 bore | 1 | 18.2 | 0.00 | -0.56 | - | - | picture | hydraulic feed between the two grabber pairs |
| D1 | listening dish, 0.6 across | 1 | 19.3 | 0.55 | 0.43 | 30 deg off the bow to port, +22 elev | - | picture | the larger listening dish on the foredeck plate to port |
| D2 | listening dish, 0.4 across | 1 | 87.1 | -0.55 | 0.66 | 55 deg off the bow to starboard, +18 elev | - | picture | the small dish on the stern block, starboard |
| S1 | twin casemate | 2 barrels | 38.7 | -0.90 | -0.10 | 50 deg off the bow to starboard | S scatter | picture | starboard flank casemate, twin barrels |
| S2 | single casemate | 1 barrel | 55.6 | -0.89 | -0.10 | 45 deg off the bow to starboard | S scatter | picture | starboard flank casemate, one fat barrel |
| S3 | twin casemate | 2 barrels | 71.9 | -0.89 | -0.10 | 55 deg off the bow to starboard | S scatter | picture | starboard flank casemate, twin barrels |
| S4 | twin turret | 2 barrels | 39.0 | -0.05 | 0.58 | 35 deg off the bow to starboard, +4 elev | S scatter | picture | fore spine turret, superfiring over the casemates to starboard |
| S5 | twin turret | 2 barrels | 70.3 | -0.05 | 0.60 | 40 deg off the bow to starboard, +4 elev | S scatter | picture | aft spine turret |
| E1 | engine, bell 0.8 across | 1 | 99.9 | 0.00 | 0.08 | exhaust aft | - | picture | centre bell, the largest |
| E2 | engine, bell 0.5 across | 1 | 99.9 | 0.62 | 0.42 | exhaust aft | - | picture | port upper bell |
| E3 | engine, bell 0.6 across | 1 | 99.9 | -0.64 | -0.36 | exhaust aft | - | picture | starboard lower bell |
| Q1 | attitude thruster quad | 1 | 21.9 | 0.77 | -0.24 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 21.9 | -0.77 | -0.24 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 88.2 | 0.94 | -0.24 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 88.2 | -0.94 | -0.24 | - | - | designed | stern |
| L0 | running light | 1 | 16.1 | 0.71 | -0.30 | - | - | picture |  |
| L1 | running light | 1 | 30.8 | 0.86 | -0.32 | - | - | picture |  |
| L2 | running light | 1 | 71.4 | 1.13 | -0.38 | - | - | picture |  |
| L3 | running light | 1 | 30.0 | -0.95 | -0.22 | - | - | picture |  |
| L4 | running light | 1 | 47.3 | -0.98 | -0.22 | - | - | picture |  |
| L5 | running light | 1 | 64.1 | -0.97 | -0.22 | - | - | picture |  |
| L6 | running light | 1 | 79.2 | -0.97 | -0.22 | - | - | picture |  |

Totals: 5 gun mounts with 9 barrels; 4 launcher tubes; 3 engines; 1 intakes; 2 dishes; 4 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot and weathered plate | 0.0 | 100.0 | whole hull |  |
| bare iron foredeck plate | 5.6 | 41.4 | the spade |  |
| pale Hegemony trophy plate | 47.1 | 74.5 | port side block |  |
| violet Eclipse plate | 15.6 | 22.9 | foredeck, starboard |  |
| dried-blood red patch | 46.4 | 52.7 | battery block roof |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Base hull (blunt bow, chin, long body) | 8.2 to 88.7 | -0.88 to 0.88 | -0.50 to 0.34 | soot and patched plate | the blunt bow face over a sloped chin, then the long low body |
| Lower hull band | 19.3 to 86.6 | -0.86 to 0.86 | -0.54 to -0.30 | dark soot | the belly steps in under the flank |
| Foredeck plate (the spade) | 2.2 to 41.4 | -1.04 to 1.04 | 0.20 to 0.45 | bare iron and trophy plate | the broad flat bow plate, an arrow-head wedge from above: a blunt point that widens over the first third (the picture's spade) |
| M1 fore spine block | 32.9 to 45.0 | -0.52 to 0.56 | 0.40 to 0.58 | soot with dried-blood patches | stacked spine block, top 0.58 |
| M2 battery block | 46.4 to 61.1 | -0.60 to 0.54 | 0.30 to 0.62 | soot with dried-blood patches | stacked spine block, top 0.62 |
| M3 aft spine block | 62.2 to 81.9 | -0.54 to 0.54 | 0.30 to 0.60 | soot with dried-blood patches | stacked spine block, top 0.60 |
| Port side block | 41.9 to 80.8 | 0.68 to 1.12 | -0.50 to 0.10 | dark soot | widens the port flank amidships (the picture's side block) |
| Starboard brick 1 | 26.1 to 34.0 | -0.94 to -0.64 | -0.42 to 0.12 | patched plate | armour brick between the casemates |
| Starboard brick 2 | 45.0 to 49.6 | -0.97 to -0.67 | -0.42 to 0.04 | patched plate | armour brick between the casemates |
| Starboard brick 3 | 61.6 to 66.6 | -0.97 to -0.67 | -0.42 to 0.15 | patched plate | armour brick between the casemates |
| Starboard brick 4 | 76.6 to 81.9 | -0.96 to -0.66 | -0.42 to 0.07 | patched plate | armour brick between the casemates |
| Stern block | 82.2 to 93.8 | -0.94 to 0.94 | -0.52 to 0.66 | soot, rust | the raised stern block that carries the engines |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.24 (15% to 82%); upper deck 0.16 (35% to 81%).

Bulkhead and frame stations: F0 13.5%, F1 29.3%, F2 48.7%, F3 65.0%, F4 78.7%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| rocket magazine (magazine) | 10.3 to 17.7 | -0.50 to 0.50 | -0.20 to 0.18 | the casemates' rockets, behind the bow face |
| kennel deck (crew) | 15.0 to 25.0 | -0.55 to 0.55 | -0.42 to -0.28 | boarding gangs under the bow, behind the chin grabbers |
| gun gallery (crew) | 34.5 to 78.2 | -0.70 to -0.44 | -0.20 to 0.12 | the scatter crews' gallery along the starboard casemates |
| shell magazine (magazine) | 50.8 to 63.5 | -0.30 to 0.30 | 0.20 to 0.46 | scatter shells in the battery block |
| crew decks (crew) | 66.1 to 78.2 | -0.30 to 0.46 | 0.20 to 0.44 | bunks and galley in the aft spine block |
| core (core) | 49.8 to 64.0 | -0.35 to 0.60 | -0.42 to -0.28 | reactor core (hp_core) |
| loot hold (hold) | 66.1 to 78.7 | -0.60 to 0.60 | -0.42 to -0.28 | the loot hold aft (designs.md) |
| grabber rams (machinery) | 30.8 to 47.1 | -0.62 to 0.62 | -0.42 to -0.28 | rams and winches for both grabber pairs |
| engine room (engroom) | 85.0 to 91.3 | -0.72 to 0.72 | -0.40 to 0.44 | engine room in the stern block |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| bow (forward of 3.2) | 0.16 | the face and the foredeck plate: the casemates fire from under it |
| starboard flank | 0.12 | bricks between the casemates |
| port side block | 0.10 | and the trophy plate |
| spine | 0.08 |  |
| stern block | 0.10 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 25.4 (seam wanders 24.5 to 26.0) | the bow block weld: the bow tears away whole with its casemates, the foredeck plate's front, the dish and the chin grabbers (designs.md) |
| B-2 | 81.9 (seam wanders 81.1 to 82.9) | the stern block weld: the stern block and its engines tear away, opening the engine room and the loot hold |

Full interiors through the hull (R215), hidden until a piece breaks. Patch plates tear first, then the bow block and the stern block part at their welds, ragged (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 57.1 | 0.10 | -0.36 |  |  |  |
| hp_breach_0 | 29.8 | 0.89 | 0.00 | port | prow |  |
| hp_breach_1 | 48.2 | -0.89 | -0.25 | stbd | mid |  |
| hp_breach_2 | 62.9 | 1.14 | -0.12 | port | mid |  |
| hp_breach_3 | 85.6 | -0.96 | 0.00 | stbd | eng |  |
| hp_rcs_0 | 21.9 | 0.77 | -0.24 | port |  |  |
| hp_rcs_1 | 21.9 | -0.77 | -0.24 | stbd |  |  |
| hp_board_0 | 50.8 | 1.13 | -0.30 | port |  |  |
| hp_board_1 | 69.2 | -0.88 | -0.36 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 252 objects, 37 parts, 815 close pairs, 263 rays, 5 guns, 2 turrets swept, 7 cones, 19 apertures, 4 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The two mismatched casemates sit IN the bow face: port, one long rocket tube on a brace; starboard, three short fat tubes banded together.** Ryan, Nov 12 (the round's ruling): "the two mismatched casemates sit IN the bow face", whatever the beauty's foredeck housings suggest. data.js c_reaver's only forward weapon is torp F, so both are rocket casemates (the Hullbreaker rattle rockets); the long tube stays short of a prow gun (RULEBOOK 4.4, Ryan on v5 "added a giant front gun again?").
- **The bow is an arrow-head from above: the broad flat bow plate runs from a blunt point 0.4 across to the full beam over the first third, overhanging a narrow bow face (1.1 across, 0.52 tall) that holds the two casemates; the hull's flanks widen back behind it.** the Board on round 1 (Nov 13, R233): the build had a blunt square bow; the picture's defining shape is the wedge prow (the concept sheet: 0.4 across at the tip, 1.3 just behind it, 2.1 by a third of the length). The face stays blunt and narrow, not a thin edge: the casemates need a face to sit in (designs.md).
- **Every face is plated in courses at the hull's plate size (0.2 to 0.46), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses.** the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit's courses plating (kit.py, opt-in, issue 633).
- **The whole scatter battery on the starboard side: three flank casemates of mixed calibre and two spine turrets resting to starboard.** data.js c_reaver: scatter S (one starboard battery); the picture's pods on both flanks and its foredeck guns have no other slot (R221).
- **No rocket racks on the middle deck.** designs.md's two racks would be a second forward launcher; data.js gives one torp slot and the bow casemates fire it.
- **Port flank: the side block carries one big pale Hegemony trophy plate.** designs.md (the trophy plate widening the port outline amidships) on the picture's side block.
- **Two grabber pairs: one under the chin, one under the forefoot.** the picture's claws at the chin and further aft; designs.md's four arms; split so the jaw is not a copy of A17's.
- **Three engine bells, the centre the largest, staggered in the stern block.** designs.md; the picture's four become three, lopsided (port small and high, starboard lower).
- **Two dishes: the large one standing on the foredeck plate to port, a small one on the stern block to starboard.** designs.md; the picture shows one on the foredeck.
- **Four attitude thrusters.** a ship in space needs them to turn.
- **Insides: two decks, the gun crews' gallery along the starboard casemates, a kennel deck under the bow, the loot hold aft.** designs.md; R209, R215.

## Designed here, not shown in the picture

- Belly detail between the grabber pairs and the stern block is designed here; the picture shows little of the underside.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
