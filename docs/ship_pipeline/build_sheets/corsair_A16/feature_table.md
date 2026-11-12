# corsair_A16: Warlord's Pyre-Barge, build sheet

Ashfall Hullbreakers (corsair) | class Battle-barge | version 3 (round 3), 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3b\corsair_A16\corsair_A16_blockout.blend`

**Length 26.0 world units** (data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 26.045 |
| length side | 26.075 |
| length top | 26.075 |
| length disagreement percent | 0.0 |
| beam top | 12.588 |
| beam bow | 12.688 |
| beam disagreement percent | 0.38 |
| height side | 12.925 |
| height bow | 12.938 |
| height disagreement percent | 0.05 |
| widest at station percent | 58.0 |
| hull beam | 8.7 |
| hull depth | 4.9 |
| L to B hull | 2.99 |
| L to H hull | 5.31 |
| prow overhang | 1.75 |
| outline iou percent | 80.5 |
| mass outline iou percent | 80.5 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | front tube (wake-sniffer scoop), 1.8 across, 2.5 deep | 1 | 1.7 | 1.36 | -0.25 | forward | - | picture | port front tube: deep bore, hooded rolled lip, clamp bands |
| I2 | front tube (wake-sniffer scoop), 1.8 across, 2.5 deep | 1 | 1.7 | -1.36 | -0.25 | forward | - | picture | starboard front tube: deep bore, hooded rolled lip, clamp bands |
| V0 | louvre panel 0.4 x 1.2 | 1 | 5.4 | 0.00 | -0.25 | - | - | picture | ribbed spine between the tubes |
| SL1 | vision slit 0.9 x 0.16 | 1 | 24.5 | 1.30 | 2.32 | - | - | picture | vision slit in the tier 2 front |
| SL2 | vision slit 0.9 x 0.16 | 1 | 24.5 | -1.30 | 2.32 | - | - | picture | vision slit in the tier 2 front |
| SL3p | vision slit 1.4 x 0.16 | 1 | 72.8 | 1.85 | 3.72 | - | - | picture | bridge flank vision slit |
| SL3s | vision slit 1.4 x 0.16 | 1 | 72.8 | -1.85 | 3.72 | - | - | picture | bridge flank vision slit |
| SL4 | vision slit 0.9 x 0.15 | 1 | 67.8 | 3.06 | 3.00 | - | - | picture | castle flank slit |
| HC1 | square hatch 0.6 | 1 | 73.0 | 3.03 | 2.85 | - | - | picture | castle flank hatch |
| SL5 | vision slit 0.9 x 0.15 | 1 | 67.8 | -3.16 | 3.00 | - | - | picture | castle flank slit |
| HC2 | square hatch 0.6 | 1 | 73.0 | -3.13 | 2.85 | - | - | picture | castle flank hatch |
| HR | round hatch 0.7 | 1 | 83.1 | 1.00 | 2.20 | - | - | picture | round hatch with a hand wheel |
| D1 | listening dish, 1.8 across | 1 | 12.7 | 1.15 | 2.00 | 8 deg off the bow to port, +12 elev | - | picture | port listening dish |
| D2 | listening dish, 1.8 across | 1 | 12.7 | -1.15 | 2.00 | 8 deg off the bow to starboard, +12 elev | - | picture | starboard listening dish |
| H1 | boarding claw, 3 segments, 3 fingers | 1 | 12.1 | 1.45 | -3.10 | hook forward and down | - | picture | port boarding claw, hinged, swings forward to grip |
| H2 | boarding claw, 3 segments, 3 fingers | 1 | 12.1 | -1.45 | -3.10 | hook forward and down | - | picture | starboard boarding claw, hinged, swings forward to grip |
| H3 | boarding claw, 3 segments, 3 fingers | 1 | 53.6 | 2.20 | -3.42 | hook forward and down | - | designed | grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath) |
| H4 | boarding claw, 3 segments, 3 fingers | 1 | 53.6 | -2.20 | -3.42 | hook forward and down | - | designed | grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath) |
| HB1 | framed deck box 1.1 x 0.9 | 1 | 19.4 | 2.00 | 1.80 | - | - | picture | framed deck box, port |
| HB2 | framed deck box 0.9 x 0.8 | 1 | 18.6 | -2.20 | 1.80 | - | - | picture | framed deck box, starboard (smaller) |
| C1 | lashing chain, taut between lugs | 1 | 22.1 | 3.85 | 0.60 | to station 22.1%, offset -4.00 | - | picture | girdle over the tier 2 seam |
| C2 | lashing chain, taut between lugs | 1 | 56.8 | 4.62 | 0.40 | to station 56.8%, offset -4.82 | - | picture | girdle over the castle seam, at the foot of the castle front |
| C3 | lashing chain, taut between lugs | 1 | 19.6 | 4.10 | -0.30 | to station 55.5%, offset 4.60 | - | picture | port flank lashing along the belt top |
| C4 | lashing chain, taut between lugs | 1 | 25.5 | -4.20 | -0.30 | to station 52.4%, offset -4.72 | - | picture | starboard flank lashing, shorter (junky, unmatched) |
| R1 | rocket rack, 2 by 5 cells | 10 tubes | 40.3 | 0.00 | 3.25 | forward, +12 elev | F htorp | picture | heavy rocket rack, 10 cells, magazine below |
| HB3 | framed deck box 1.3 x 1.2, 2 armour fins | 1 | 31.9 | 1.15 | 2.65 | - | - | picture | armoured vent housing with two slanted blades |
| T1 | twin turret | 2 barrels | 61.4 | 0.00 | 3.45 | forward, +10 elev | T flak | picture | castle flak turret, fires over the rack at 10 degrees and up |
| T2 | twin turret | 2 barrels | 75.6 | 0.00 | 4.40 | forward, +30 elev | T flak | picture | bridge barbette flak turret, superfiring over T1, rests at 30 degrees |
| PB | single casemate | 1 barrel | 15.6 | 3.73 | -0.05 | 20 deg off the bow to port | P scatter | picture | bow casemate, trained forward |
| P1 | twin turret | 2 barrels | 25.9 | 2.72 | 2.65 | 15 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| P2 | twin turret | 2 barrels | 39.4 | 2.72 | 3.45 | 20 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| P3 | twin turret | 2 barrels | 52.8 | 2.72 | 2.65 | 25 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2, aft |
| PM | twin casemate | 2 barrels | 46.7 | 4.25 | 0.32 | 35 deg off the bow to port | P scatter | picture | flank twin casemate amidships |
| P4 | twin casemate | 2 barrels | 64.5 | 4.45 | 1.00 | 30 deg off the bow to port | P scatter | picture | sponson twin casemate under the castle |
| P5 | twin casemate | 2 barrels | 72.4 | 4.45 | 1.00 | 30 deg off the bow to port | P scatter | picture | sponson twin casemate under the castle |
| SB | single casemate | 1 barrel | 15.6 | -3.86 | -0.05 | 20 deg off the bow to starboard | S scatter | picture | bow casemate, trained forward |
| S1 | twin turret | 2 barrels | 25.9 | -2.72 | 2.65 | 15 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| S2 | twin turret | 2 barrels | 39.4 | -2.72 | 3.45 | 20 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 (the middle one on a barbette, superfiring) |
| S3 | twin turret | 2 barrels | 52.8 | -2.72 | 2.65 | 25 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2, aft |
| SM | twin casemate | 2 barrels | 46.7 | -4.45 | 0.32 | 35 deg off the bow to starboard | S scatter | picture | flank twin casemate amidships |
| S4 | twin casemate | 2 barrels | 64.5 | -4.45 | 1.00 | 30 deg off the bow to starboard | S scatter | picture | sponson twin casemate under the castle |
| S5 | twin casemate | 2 barrels | 72.4 | -4.45 | 1.00 | 30 deg off the bow to starboard | S scatter | picture | sponson twin casemate under the castle |
| E0 | engine, bell 3.1 across | 1 | 99.8 | 0.00 | -0.10 | exhaust aft | - | picture | centre main engine, its housing sunk in the stern |
| E1 | engine, bell 3.8 across | 1 | 97.7 | 4.35 | 0.30 | exhaust aft | - | picture | port main pod, the large one |
| E2 | engine, bell 3.3 across | 1 | 97.7 | -4.35 | 0.30 | exhaust aft | - | designed | starboard main pod, smaller (mismatched) |
| E3 | engine, bell 1.3 across | 1 | 96.6 | 1.65 | -2.25 | exhaust aft | - | picture | lower booster |
| E4 | engine, bell 1.3 across | 1 | 96.6 | -1.65 | -2.25 | exhaust aft | - | designed | lower booster |
| E5 | engine, bell 1.4 across | 1 | 93.5 | -1.30 | 2.85 | exhaust aft | - | picture | upper starboard pod on the stern deck |
| Q1 | attitude thruster quad | 1 | 11.7 | 2.85 | 1.17 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 11.7 | -2.90 | 1.17 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 78.3 | 2.87 | 2.95 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 78.3 | -2.97 | 2.95 | - | - | designed | stern |
| PP1 | pipe run, 0.18 bore | 1 | 78.1 | 2.72 | 2.27 | - | - | picture |  |
| PP2 | pipe run, 0.18 bore | 1 | 78.1 | -2.72 | 2.27 | - | - | picture |  |
| AN1 | antenna array, 2.0 tall, 3 whips | 1 | 87.5 | 1.25 | 2.20 | - | - | picture | antenna array on the stern deck, port |
| AN2 | antenna array, 1.6 tall, 2 whips | 1 | 84.3 | -0.15 | 2.20 | - | - | picture | antenna array on the stern deck, centre |
| VF0p | louvre panel 1.0 x 0.6 | 1 | 25.7 | 4.00 | 0.22 | - | - | picture |  |
| VF1p | louvre panel 1.0 x 0.6 | 1 | 40.1 | 4.21 | 0.22 | - | - | picture |  |
| VF2p | louvre panel 1.0 x 0.6 | 1 | 57.6 | 4.22 | 0.22 | - | - | picture |  |
| L0p | running light | 1 | 17.5 | 3.75 | -1.62 | - | - | picture |  |
| L1p | running light | 1 | 30.9 | 4.08 | -1.62 | - | - | picture |  |
| L2p | running light | 1 | 44.3 | 4.23 | -1.62 | - | - | picture |  |
| L3p | running light | 1 | 58.6 | 4.21 | -1.62 | - | - | picture |  |
| L4p | running light | 1 | 70.8 | 3.78 | -1.62 | - | - | picture |  |
| LCp | running light | 1 | 62.8 | 3.10 | 3.10 | - | - | picture |  |
| LDp | running light | 1 | 76.0 | 3.02 | 2.60 | - | - | picture |  |
| VF0s | louvre panel 1.0 x 0.6 | 1 | 25.7 | -4.18 | 0.22 | - | - | picture |  |
| VF1s | louvre panel 1.0 x 0.6 | 1 | 40.1 | -4.41 | 0.22 | - | - | picture |  |
| VF2s | louvre panel 1.0 x 0.6 | 1 | 57.6 | -4.40 | 0.22 | - | - | picture |  |
| L0s | running light | 1 | 17.5 | -3.88 | -1.62 | - | - | picture |  |
| L1s | running light | 1 | 30.9 | -4.27 | -1.62 | - | - | picture |  |
| L2s | running light | 1 | 44.3 | -4.43 | -1.62 | - | - | picture |  |
| L3s | running light | 1 | 58.6 | -4.38 | -1.62 | - | - | picture |  |
| L4s | running light | 1 | 70.8 | -3.90 | -1.62 | - | - | picture |  |
| LCs | running light | 1 | 62.8 | -3.20 | 3.10 | - | - | picture |  |
| LDs | running light | 1 | 76.0 | -3.12 | 2.60 | - | - | picture |  |
| B1 | ventral launch bay 3.4 x 3.2 | 1 | 58.7 | 0.00 | -3.05 | - | - | designed | data.js hangar 2: squadrons drop from the belly |

Totals: 16 gun mounts with 30 barrels; 10 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 4 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot black base plate | 0.2 | 100.0 | whole hull | patched, worn; dim red running lights |
| rust plate (tier 2, brow step) | 6.0 | 60.1 | raised armoured deck and the brow |  |
| violet Eclipse trophy plate | 27.5 | 33.2 | tier 2 deck, starboard |  |
| violet Eclipse trophy plate | 28.2 | 34.0 | port flank |  |
| pale Hegemony grey trophy plates | 40.1 | 52.4 | port flank, under the belt |  |
| dried-blood red band | 58.4 | 61.4 | castle front |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull slab (tier 1) | 6.7 to 93.1 | -4.45 to 4.25 | -3.05 to 1.85 | soot black, patched plate | deep flat-bellied slab, rounded faceted prow cap |
| Prow brow (two steps) | 4.6 to 9.8 | -3.05 to 3.00 | 0.50 to 1.72 | soot | overhangs the tube mouths |
| Raised armoured deck (tier 2) | 23.2 to 60.1 | -3.55 to 3.40 | 1.50 to 2.65 | rust plate | the stacked slab over the forward two thirds |
| Rack plinth | 38.6 to 50.9 | -1.65 to 1.65 | 2.50 to 3.25 | soot | lifts the rack so it fires clear over the bow |
| Castle (tier 3) | 58.6 to 80.1 | -3.20 to 3.10 | 2.30 to 3.45 | soot with a dried-blood band |  |
| Bridge block | 67.4 to 77.9 | -1.90 to 1.90 | 3.35 to 4.05 | soot | command deck on the castle roof |
| Flank sponsons and belt strakes | 61.2 to 75.4 | 2.90 to 4.45 | 0.20 to 1.75 | soot, iron | one per side, matched |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.55 (12% to 89%); main deck 0.10 (9% to 89%); gun deck 1.95 (25% to 59%); castle deck 2.75 (60% to 79%).

Bulkhead and frame stations: F0 9.8%, F1 19.4%, F2 31.7%, F3 47.0%, F4 60.1%, F5 74.7%, F6 84.7%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| tube ducts (machinery) | 8.3 to 11.9 | -2.00 to 2.00 | -1.00 to 0.70 | front tube ducts and sniffer gear |
| claw machinery (machinery) | 11.7 to 19.0 | -2.60 to 2.60 | -2.40 to -1.65 | claw rams and winches |
| kennel decks (crew) | 12.1 to 31.3 | -3.00 to 3.00 | -1.45 to 1.60 | boarding gangs, two decks |
| rocket magazine (magazine) | 32.1 to 51.6 | -1.60 to 1.60 | 0.20 to 1.85 | under the rocket rack |
| loot hold (hold) | 32.1 to 46.7 | -3.20 to 3.20 | -2.60 to -1.65 | loot holds |
| hangar (hangar) | 47.4 to 66.2 | -2.60 to 2.60 | -2.70 to 0.00 | two squadrons, belly drop |
| core (core) | 66.6 to 74.3 | -1.30 to 1.30 | -2.60 to 0.00 | reactor core (hp_core) |
| shell magazine p (magazine) | 60.5 to 74.3 | 1.60 to 3.30 | 0.20 to 1.80 | port battery magazine |
| shell magazine s (magazine) | 60.5 to 74.3 | -3.30 to -1.60 | 0.20 to 1.80 | starboard battery magazine |
| gun deck (crew) | 25.5 to 59.7 | -2.60 to 2.60 | 2.00 to 2.50 | turret crews and hoists |
| warlord hall (crew) | 60.5 to 78.9 | -2.40 to 2.40 | 2.80 to 3.30 | the warlord hall |
| bridge (bridge) | 67.8 to 77.4 | -1.40 to 1.40 | 3.40 to 3.90 | command deck |
| engine room (engroom) | 75.1 to 89.3 | -2.00 to 2.00 | -2.10 to 1.60 | engine room and pod feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ram bow (forward of 10.5) | 0.60 | stacked scrap plating in the brow and chin, around the tube ducts |
| flank belt (lower and main decks) | 0.40 | patch plates over the base hull |
| tier 2 and castle roof | 0.30 |  |
| belly | 0.35 | flat armoured belly with chines |
| engine end | 0.20 | thinnest: the soft spot |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 23.2 (seam wanders 20.9 to 24.0) | tier 2 seam under the C1 girdle: the bow and the kennel decks tear off; C1 holds them a moment |
| B-2 | 59.7 (seam wanders 57.8 to 61.2) | castle seam under the C2 girdle: opens the rocket magazine and the hangar |
| B-3 | 78.5 (seam wanders 77.8 to 80.4) | castle and engine room seam: the engine block tears away with the stern |

Full interiors throughout the hull (R215): decks, frames, spaces and machinery along the whole length, hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 70.5 | 0.00 | -1.30 |  |  |  |
| hp_breach_0 | 14.0 | 3.45 | 0.20 | port | prow |  |
| hp_breach_1 | 21.7 | -3.90 | -1.20 | stbd | prow |  |
| hp_breach_2 | 34.7 | 4.20 | -0.60 | port | mid |  |
| hp_breach_3 | 59.7 | -3.30 | 2.50 | stbd | mid |  |
| hp_breach_4 | 53.2 | 4.40 | 0.90 | port | mid |  |
| hp_breach_5 | 78.9 | 2.70 | 0.90 | port | eng |  |
| hp_breach_6 | 83.1 | -2.60 | -1.40 | stbd | eng |  |
| hp_rcs_0 | 11.7 | 2.85 | 1.17 | port |  |  |
| hp_rcs_1 | 11.7 | -2.90 | 1.17 | stbd |  |  |
| hp_board_0 | 42.4 | 4.30 | -1.00 | port |  |  |
| hp_board_1 | 42.4 | -4.50 | -1.00 | stbd |  |  |
| hp_bay_0 | 58.7 | 0.00 | -3.15 |  |  | launch down |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 405 objects, 77 parts, 1086 close pairs, 803 rays, 16 guns, 8 turrets swept, 10 cones, 45 apertures. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Front tubes built as deep tubes with hooded rolled lips, dark bores and clamp bands, jutting 1.3 ahead of a shorter prow under a stepped brow.** Ryan R217: "the tubes at the front ... are just circles on the actual build".
- **Rack raised on a plinth and pitched 12 degrees; no turret in front of it.** Ryan R217: "the guns are visibly blocking the rockets"; the fit check proves every cell fires clear over the bow.
- **Flak superfires from the castle front (T1) and a bridge barbette (T2).** the round 2 bunker turret sat in the rack's line of fire; the picture puts its top turret on the castle.
- **Guns laid out as matched port and starboard batteries by game slot.** the picture has a row of guns on one deck edge and a cluster on the other flank; scatter P and S are mirrored: a bow casemate, three deck-edge twin turrets, a flank casemate amidships and two sponson casemates per side.
- **Profile set from a true side reading: deep flat-bellied slab, raised tier 2, castle, bridge block.** one three-quarter camera cannot see height; the round 8 side view and the shape reference give a hull 4.9 deep, 6.5 to the castle roof.
- **Roof turrets rest facing forward.** the picture draws its barrel aft; no gun faces aft.
- **The mid-length starboard engine pod becomes an upper pod on the stern deck.** a pod at mid-length glowing forward would push the ship backward and burn its own deck.
- **Two main engine pods, port larger, plus a centre main and lower boosters.** the picture shows the port pod only; a single side pod would turn the ship; the faction keeps mismatched bells.
- **Attitude thrusters moved off the casemates and pods.** the fit check found the round 2 bow quads firing into the bow casemates and the stern quads into the pods.
- **Chains are taut girdles and flank lashings of real links.** a slack chain cannot sag in space (R185); the girdles sit on the break lines.
- **Bow claws hinged in their own housings; two grapple arms added under the belly.** the picture hooks hang from nothing; the round 8 side sheet and Ryan (R196) put hooks underneath.
- **Ventral launch bay and four attitude thruster quads added.** data.js gives the barge a hangar of 2; a ship in space needs thrusters to turn.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Belly detail between the claws and the bay is designed here; the picture does not show it.
- The notch in each tube's lower lip is left for the build's kit pass.
- H3 (boarding claw, 3 segments, 3 fingers): grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath).
- H4 (boarding claw, 3 segments, 3 fingers): grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath).
- E2 (engine, bell 3.3 across): starboard main pod, smaller (mismatched).
- E4 (engine, bell 1.3 across): lower booster.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
- B1 (ventral launch bay 3.4 x 3.2): data.js hangar 2: squadrons drop from the belly.
