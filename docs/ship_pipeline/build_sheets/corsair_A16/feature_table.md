# corsair_A16: Warlord's Pyre-Barge, build sheet

Ashfall Hullbreakers (corsair) | class Battle-barge | version 3 (round 3), 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3b\corsair_A16\corsair_A16_blockout.blend`

**Length 26.0 world units** (data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 26.139 |
| length side | 26.163 |
| length top | 26.163 |
| length disagreement percent | 0.0 |
| beam top | 12.3 |
| beam bow | 12.3 |
| beam disagreement percent | 0.0 |
| height side | 9.387 |
| height bow | 9.387 |
| height disagreement percent | 0.0 |
| widest at station percent | 66.0 |
| hull beam | 7.8 |
| hull depth | 4.0 |
| L to B hull | 3.33 |
| L to H hull | 6.5 |
| prow overhang | 1.4 |
| outline iou percent | 80.3 |
| mass outline iou percent | 80.7 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | front tube (wake-sniffer scoop), 1.9 across, 2.6 deep | 1 | 2.0 | 1.35 | -0.25 | forward | - | picture | port front tube: the ship's face; deep bore, hooded rolled lip, clamp bands |
| I2 | front tube (wake-sniffer scoop), 1.9 across, 2.6 deep | 1 | 2.0 | -1.35 | -0.25 | forward | - | picture | starboard front tube: the ship's face; deep bore, hooded rolled lip, clamp bands |
| V0 | louvre panel 0.3 x 1.5 | 1 | 4.4 | 0.00 | -0.25 | - | - | picture | ribbed spine between the tubes |
| SL1 | vision slit 0.9 x 0.14 | 1 | 24.6 | 1.30 | 1.75 | - | - | picture | vision slit in the tier 2 front |
| SL2 | vision slit 0.9 x 0.14 | 1 | 24.6 | -1.30 | 1.75 | - | - | picture | vision slit in the tier 2 front |
| SL3p | vision slit 1.4 x 0.13 | 1 | 72.9 | 1.83 | 2.78 | - | - | picture | bridge flank vision slit |
| SL3s | vision slit 1.4 x 0.13 | 1 | 72.9 | -1.83 | 2.78 | - | - | picture | bridge flank vision slit |
| SL4 | vision slit 0.9 x 0.14 | 1 | 67.9 | 2.96 | 2.20 | - | - | picture | castle flank slit |
| HC1 | square hatch 0.5 | 1 | 73.1 | 2.92 | 1.95 | - | - | picture | castle flank hatch |
| SL5 | vision slit 0.9 x 0.14 | 1 | 67.9 | -3.06 | 2.20 | - | - | picture | castle flank slit |
| HC2 | square hatch 0.5 | 1 | 73.1 | -3.02 | 1.95 | - | - | picture | castle flank hatch |
| HR | round hatch 0.7 | 1 | 83.2 | 1.00 | 1.70 | - | - | picture | round hatch with a hand wheel |
| D1 | listening dish, 1.8 across | 1 | 15.3 | 1.15 | 1.52 | 8 deg off the bow to port, +12 elev | - | picture | port listening dish |
| D2 | listening dish, 1.8 across | 1 | 15.3 | -1.15 | 1.52 | 8 deg off the bow to starboard, +12 elev | - | picture | starboard listening dish |
| H1 | boarding claw, 3 segments, 2 fingers | 1 | 9.4 | 1.25 | -2.80 | hook forward and down | - | picture | port pincer: a curved mandible under the bow tip, hooking forward |
| H2 | boarding claw, 3 segments, 2 fingers | 1 | 9.4 | -1.25 | -2.80 | hook forward and down | - | picture | starboard pincer: a curved mandible under the bow tip, hooking forward |
| H3 | boarding claw, 2 segments, 3 fingers | 1 | 73.3 | 1.30 | -2.85 | hook forward and down | - | picture | short grabber under the stern (round 8 side sheet: grabbers under the stern; Ryan R196: hooks underneath) |
| H4 | boarding claw, 2 segments, 3 fingers | 1 | 82.1 | -1.30 | -2.85 | hook forward and down | - | picture | short grabber under the stern (round 8 side sheet: grabbers under the stern; Ryan R196: hooks underneath) |
| HB1 | framed deck box 0.9 x 0.9 | 1 | 19.9 | 1.80 | 1.37 | - | - | picture | framed deck box, port |
| HB2 | framed deck box 0.8 x 0.8 | 1 | 19.9 | -1.90 | 1.37 | - | - | picture | framed deck box, starboard (smaller) |
| C1 | lashing chain, taut between lugs | 1 | 22.4 | 3.95 | 0.95 | to station 22.4%, offset -4.05 | - | picture | girdle over the tier 2 seam |
| C2 | lashing chain, taut between lugs | 1 | 57.0 | 4.15 | 0.95 | to station 57.0%, offset -4.25 | - | picture | girdle over the castle seam, at the foot of the castle front |
| C3 | lashing chain, taut between lugs | 1 | 19.9 | 3.64 | -0.62 | to station 55.7%, offset 4.12 | - | picture | port flank lashing along the lower belt top |
| C4 | lashing chain, taut between lugs | 1 | 25.8 | -3.97 | -0.62 | to station 52.6%, offset -4.23 | - | picture | starboard flank lashing, shorter (junky, unmatched) |
| R1 | rocket rack, 2 by 5 cells | 10 tubes | 40.6 | 0.00 | 2.45 | forward, +10 elev | F htorp | picture | heavy rocket rack, 10 cells, magazine below |
| HB3 | framed deck box 1.3 x 1.2, 2 armour fins | 1 | 32.1 | 1.15 | 2.00 | - | - | picture | armoured vent housing with two slanted blades |
| T1 | twin turret | 2 barrels | 61.6 | 0.00 | 2.60 | forward, +10 elev | T flak | picture | castle flak turret, fires over the rack at 10 degrees and up |
| T2 | twin turret | 2 barrels | 75.7 | 0.00 | 3.25 | forward, +30 elev | T flak | picture | bridge barbette flak turret, superfiring over T1, rests at 30 degrees |
| PB | single casemate | 1 barrel | 15.9 | 3.27 | -0.30 | 20 deg off the bow to port | P scatter | picture | bow casemate in the recessed band, trained forward |
| P1 | twin turret | 2 barrels | 26.2 | 2.72 | 2.00 | 15 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| P2 | twin turret | 2 barrels | 39.6 | 2.72 | 2.75 | 20 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| P3 | twin turret | 2 barrels | 53.0 | 2.72 | 2.00 | 25 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2, aft |
| PM | twin casemate | 2 barrels | 46.9 | 4.06 | 0.50 | 35 deg off the bow to port | P scatter | picture | flank twin casemate on the upper belt amidships |
| P4 | twin casemate | 2 barrels | 64.7 | 4.30 | 0.35 | 30 deg off the bow to port | P scatter | picture | sponson twin casemate under the castle |
| P5 | twin casemate | 2 barrels | 72.5 | 4.30 | 0.35 | 30 deg off the bow to port | P scatter | picture | sponson twin casemate under the castle |
| SB | single casemate | 1 barrel | 15.9 | -3.32 | -0.30 | 20 deg off the bow to starboard | S scatter | picture | bow casemate in the recessed band, trained forward |
| S1 | twin turret | 2 barrels | 26.2 | -2.72 | 2.00 | 15 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| S2 | twin turret | 2 barrels | 39.6 | -2.72 | 2.75 | 20 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| S3 | twin turret | 2 barrels | 53.0 | -2.72 | 2.00 | 25 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2, aft |
| SM | twin casemate | 2 barrels | 46.9 | -4.16 | 0.50 | 35 deg off the bow to starboard | S scatter | picture | flank twin casemate on the upper belt amidships |
| S4 | twin casemate | 2 barrels | 64.7 | -4.30 | 0.35 | 30 deg off the bow to starboard | S scatter | picture | sponson twin casemate under the castle |
| S5 | twin casemate | 2 barrels | 72.5 | -4.30 | 0.35 | 30 deg off the bow to starboard | S scatter | picture | sponson twin casemate under the castle |
| E0 | engine, bell 2.8 across | 1 | 99.8 | 0.00 | -0.35 | exhaust aft | - | picture | centre main engine, its housing sunk in the stern |
| E1 | engine, bell 2.6 across | 1 | 97.7 | 3.60 | 0.45 | exhaust aft | - | picture | port main pod, the large one |
| E2 | engine, bell 2.3 across | 1 | 97.7 | -3.60 | 0.45 | exhaust aft | - | designed | starboard main pod, smaller (mismatched) |
| E3 | engine, bell 1.2 across | 1 | 96.6 | 1.55 | -1.85 | exhaust aft | - | picture | lower booster |
| E4 | engine, bell 1.2 across | 1 | 96.6 | -1.55 | -1.85 | exhaust aft | - | designed | lower booster |
| E5 | engine, bell 1.2 across | 1 | 93.5 | -1.20 | 2.18 | exhaust aft | - | picture | upper starboard pod on the stern deck |
| Q1 | attitude thruster quad | 1 | 10.3 | 2.71 | 0.45 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 10.3 | -2.77 | 0.45 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 78.4 | 2.78 | 2.00 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 78.4 | -2.88 | 2.00 | - | - | designed | stern |
| PP1 | pipe run, 0.18 bore | 1 | 80.3 | 2.35 | 1.60 | - | - | picture |  |
| PP2 | pipe run, 0.18 bore | 1 | 80.3 | -2.35 | 1.60 | - | - | picture |  |
| AN1 | antenna array, 1.8 tall, 3 whips | 1 | 87.6 | 1.25 | 1.70 | - | - | picture | antenna array on the stern deck, port |
| AN2 | antenna array, 1.4 tall, 2 whips | 1 | 84.4 | -0.15 | 1.70 | - | - | picture | antenna array on the stern deck, centre |
| VF0p | louvre panel 1.0 x 0.5 | 1 | 26.0 | 3.67 | -0.22 | - | - | picture |  |
| VF1p | louvre panel 1.0 x 0.5 | 1 | 40.4 | 3.79 | -0.22 | - | - | picture |  |
| VF2p | louvre panel 1.0 x 0.5 | 1 | 57.8 | 3.84 | -0.22 | - | - | picture |  |
| L0p | running light | 1 | 21.2 | 3.44 | -0.32 | - | - | picture |  |
| L1p | running light | 1 | 33.5 | 3.73 | -0.32 | - | - | picture |  |
| L2p | running light | 1 | 44.2 | 3.82 | -0.32 | - | - | picture |  |
| L3p | running light | 1 | 52.6 | 3.86 | -0.32 | - | - | picture |  |
| L4p | running light | 1 | 62.2 | 4.32 | -0.36 | - | - | picture |  |
| L5p | running light | 1 | 68.3 | 4.32 | -0.36 | - | - | picture |  |
| LCp | running light | 1 | 62.9 | 3.00 | 2.25 | - | - | picture |  |
| VF0s | louvre panel 1.0 x 0.5 | 1 | 26.0 | -3.77 | -0.22 | - | - | picture |  |
| VF1s | louvre panel 1.0 x 0.5 | 1 | 40.4 | -3.89 | -0.22 | - | - | picture |  |
| VF2s | louvre panel 1.0 x 0.5 | 1 | 57.8 | -3.94 | -0.22 | - | - | picture |  |
| L0s | running light | 1 | 21.2 | -3.51 | -0.32 | - | - | picture |  |
| L1s | running light | 1 | 33.5 | -3.83 | -0.32 | - | - | picture |  |
| L2s | running light | 1 | 44.2 | -3.92 | -0.32 | - | - | picture |  |
| L3s | running light | 1 | 52.6 | -3.96 | -0.32 | - | - | picture |  |
| L4s | running light | 1 | 62.2 | -4.32 | -0.36 | - | - | picture |  |
| L5s | running light | 1 | 68.3 | -4.32 | -0.36 | - | - | picture |  |
| LCs | running light | 1 | 62.9 | -3.10 | 2.25 | - | - | picture |  |
| B1 | ventral launch bay 3.4 x 3.2 | 1 | 58.9 | 0.00 | -2.60 | - | - | designed | data.js hangar 2: squadrons drop from the belly |

Totals: 16 gun mounts with 30 barrels; 10 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 4 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot black base plate | 0.6 | 100.0 | whole hull | patched, worn; dim red running lights |
| rust plate (tier 2, brow step) | 6.3 | 60.3 | raised armoured deck and the brow |  |
| violet Eclipse trophy plate | 27.7 | 33.5 | tier 2 deck, starboard |  |
| violet Eclipse trophy plate | 28.5 | 34.2 | port flank |  |
| pale Hegemony grey trophy plates | 40.4 | 52.6 | port flank, under the belt |  |
| dried-blood red band | 58.5 | 61.6 | castle front |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull slab (tier 1) | 5.4 to 93.2 | -3.95 to 3.85 | -2.60 to 1.40 | soot black, patched plate | a rounded wedge in section (round flanks and belly, a flatter deck), the bow tapering to a broad rounded nose |
| Upper armour belt | 12.0 to 74.0 | -4.19 to 4.09 | 0.10 to 1.02 | iron and soot | layered flank belt following the hull's curve, standing 0.24 out |
| Lower armour belt | 15.1 to 71.7 | -4.29 to 4.19 | -1.83 to -0.71 | iron and soot | layered flank belt following the hull's curve, standing 0.34 out |
| Prow brow (two steps) | 5.4 to 9.8 | -2.85 to 2.80 | 0.85 to 1.50 | soot | overhangs the tube mouths |
| Brow step | 7.8 to 12.2 | -2.60 to 2.55 | 1.30 to 1.82 | rust | the second brow step |
| Chin | 5.5 to 9.0 | -2.65 to 2.60 | -2.30 to -1.35 | iron | under the tubes, carries the pincers |
| Raised armoured deck (tier 2) | 23.5 to 60.3 | -3.45 to 3.30 | 1.20 to 2.00 | rust plate | a low step over the forward two thirds |
| Rack plinth | 38.8 to 51.1 | -1.65 to 1.65 | 1.90 to 2.45 | soot | lifts the rack so it fires clear over the bow |
| Castle (tier 3) | 58.7 to 80.1 | -3.10 to 3.00 | 1.30 to 2.60 | soot with a dried-blood band |  |
| Bridge block | 67.5 to 78.0 | -1.85 to 1.85 | 2.50 to 3.00 | soot | command deck on the castle roof |
| Stern deck | 79.8 to 89.3 | -2.00 to 2.00 | 1.20 to 1.70 | steel | carries the upper pod and the round hatch |
| Sponson port | 61.4 to 75.6 | 2.90 to 4.30 | -0.55 to 1.20 | soot | flank sponson under the castle |
| Sponson starboard | 61.4 to 75.6 | -4.30 to -2.90 | -0.55 to 1.20 | soot | flank sponson under the castle |
| Pod pylon port | 81.7 to 90.1 | 2.30 to 3.60 | -0.10 to 0.95 | steel | pod pylon, stepped web with plates |
| Pod pylon starboard | 81.7 to 90.1 | -3.60 to -2.30 | -0.10 to 0.95 | steel | pod pylon, stepped web with plates |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.35 (11% to 89%); main deck 0.00 (10% to 89%); gun deck 1.60 (25% to 59%); castle deck 1.95 (60% to 79%).

Bulkhead and frame stations: F0 10.1%, F1 19.7%, F2 31.9%, F3 47.2%, F4 60.3%, F5 74.8%, F6 84.7%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| tube ducts (machinery) | 8.6 to 12.2 | -1.80 to 1.80 | -1.00 to 0.60 | front tube ducts and sniffer gear |
| claw machinery (machinery) | 12.1 to 19.3 | -2.40 to 2.40 | -2.10 to -1.45 | pincer rams and winches |
| kennel decks (crew) | 12.4 to 31.6 | -2.80 to 2.80 | -1.25 to 1.20 | boarding gangs, two decks |
| rocket magazine (magazine) | 32.3 to 51.8 | -1.50 to 1.50 | 0.10 to 1.30 | under the rocket rack |
| loot hold (hold) | 32.3 to 46.9 | -3.00 to 3.00 | -2.25 to -1.45 | loot holds |
| hangar (hangar) | 47.6 to 66.4 | -2.50 to 2.50 | -2.30 to -0.10 | two squadrons, belly drop |
| core (core) | 66.8 to 74.4 | -1.20 to 1.20 | -2.20 to -0.10 | reactor core (hp_core) |
| shell magazine p (magazine) | 60.6 to 74.4 | 1.50 to 3.10 | 0.10 to 1.25 | port battery magazine |
| shell magazine s (magazine) | 60.6 to 74.4 | -3.10 to -1.50 | 0.10 to 1.25 | starboard battery magazine |
| gun deck (crew) | 25.8 to 59.9 | -2.50 to 2.50 | 1.45 to 1.90 | turret crews and hoists |
| warlord hall (crew) | 60.6 to 79.0 | -2.30 to 2.30 | 1.95 to 2.45 | the warlord hall |
| bridge (bridge) | 67.9 to 77.5 | -1.40 to 1.40 | 2.55 to 2.90 | command deck |
| engine room (engroom) | 75.2 to 89.3 | -1.90 to 1.90 | -1.80 to 1.20 | engine room and pod feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ram bow (forward of 10.5) | 0.60 | stacked scrap plating in the brow and chin, around the tube ducts |
| flank belts | 0.40 | the upper and lower armour belts over the base hull |
| tier 2 and castle roof | 0.30 |  |
| belly | 0.35 | flat armoured belly with chines |
| engine end | 0.20 | thinnest: the soft spot |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 23.5 (seam wanders 21.2 to 24.3) | tier 2 seam under the C1 girdle: the bow and the kennel decks tear off; C1 holds them a moment |
| B-2 | 59.9 (seam wanders 58.0 to 61.4) | castle seam under the C2 girdle: opens the rocket magazine and the hangar |
| B-3 | 78.6 (seam wanders 77.9 to 80.5) | castle and engine room seam: the engine block tears away with the stern |

Full interiors throughout the hull (R215): decks, frames, spaces and machinery along the whole length, hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 70.6 | 0.00 | -1.10 |  |  |  |
| hp_breach_0 | 14.3 | 3.30 | 0.20 | port | prow |  |
| hp_breach_1 | 22.0 | -3.90 | -1.10 | stbd | prow |  |
| hp_breach_2 | 35.0 | 4.10 | -0.50 | port | mid |  |
| hp_breach_3 | 59.9 | -3.20 | 1.80 | stbd | mid |  |
| hp_breach_4 | 53.4 | 4.20 | 0.60 | port | mid |  |
| hp_breach_5 | 79.0 | 2.60 | 0.70 | port | eng |  |
| hp_breach_6 | 83.2 | -2.50 | -1.20 | stbd | eng |  |
| hp_rcs_0 | 10.3 | 2.71 | 0.45 | port |  |  |
| hp_rcs_1 | 10.3 | -2.77 | 0.45 | stbd |  |  |
| hp_board_0 | 42.7 | 4.20 | -0.30 | port |  |  |
| hp_board_1 | 42.7 | -4.30 | -0.30 | stbd |  |  |
| hp_bay_0 | 58.9 | 0.00 | -2.70 |  |  | launch down |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 409 objects, 77 parts, 1033 close pairs, 796 rays, 16 guns, 8 turrets swept, 10 cones, 45 apertures. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **A rounded wedge in section (round flanks and belly, a flatter deck), tapering in plan to a broad rounded nose.** the Board on round 3b: the hull still read as a straight-sided box; Ryan: "the builds look like square blocks basically".
- **A long, low slab to the concept's measured proportions, the bow tapering in plan, the flank in layered belts.** the Board on round 3: the hull was a straight-sided box, too tall; now length to beam about 3 and length to height about 4.5 like the round 8 sheet, tier 2 and the castle as low steps.
- **The front tubes are the ship's face: big, side by side across the prow, jutting ahead of a tapered nose under a stepped brow.** Ryan R217: "the tubes at the front ... are just circles on the actual build".
- **Rack raised on a plinth and pitched 12 degrees; no turret in front of it.** Ryan R217: "the guns are visibly blocking the rockets"; the fit check proves every cell fires clear over the bow.
- **Flak superfires from the castle front (T1) and a bridge barbette (T2).** the round 2 bunker turret sat in the rack's line of fire; the picture puts its top turret on the castle.
- **Guns laid out as matched port and starboard batteries by game slot.** the picture has a row of guns on one deck edge and a cluster on the other flank; scatter P and S are mirrored: a bow casemate, three deck-edge twin turrets, a flank casemate amidships and two sponson casemates per side.
- **Profile set from a true side reading: deep flat-bellied slab, raised tier 2, castle, bridge block.** one three-quarter camera cannot see height; the round 8 side view and the shape reference give a hull 4.9 deep, 6.5 to the castle roof.
- **Roof turrets rest facing forward.** the picture draws its barrel aft; no gun faces aft.
- **The mid-length starboard engine pod becomes an upper pod on the stern deck.** a pod at mid-length glowing forward would push the ship backward and burn its own deck.
- **Two main engine pods, port larger, plus a centre main and lower boosters.** the picture shows the port pod only; a single side pod would turn the ship; the faction keeps mismatched bells.
- **Attitude thrusters moved off the casemates and pods.** the fit check found the round 2 bow quads firing into the bow casemates and the stern quads into the pods.
- **Chains are taut girdles and flank lashings of real links.** a slack chain cannot sag in space (R185); the girdles sit on the break lines.
- **Curved pincers under the bow tip; short grabbers under the stern.** the concept's mandibles hang under the bow tip and its grabbers under the stern (the Board on round 3: round 3's read as legs under midships).
- **Engine pods brought in close to the hull.** the concept's pods sit inside the ship's beam (top view); round 3's stood far out.
- **Ventral launch bay and four attitude thruster quads added.** data.js gives the barge a hangar of 2; a ship in space needs thrusters to turn.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Belly detail between the claws and the bay is designed here; the picture does not show it.
- The notch in each tube's lower lip is left for the build's kit pass.
- E2 (engine, bell 2.3 across): starboard main pod, smaller (mismatched).
- E4 (engine, bell 1.2 across): lower booster.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
- B1 (ventral launch bay 3.4 x 3.2): data.js hangar 2: squadrons drop from the belly.
