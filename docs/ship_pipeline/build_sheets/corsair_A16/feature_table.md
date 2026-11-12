# corsair_A16: Warlord's Pyre-Barge, build sheet

Ashfall Hullbreakers (corsair) | class Battle-barge | version 1, 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\corsair_A16\corsair_A16_blockout.blend`

**Length 26.0 world units** (data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 25.94 |
| length side | 25.962 |
| length top | 25.962 |
| length disagreement percent | 0.0 |
| beam top | 11.825 |
| beam bow | 11.887 |
| beam disagreement percent | 0.24 |
| height side | 11.262 |
| height bow | 11.262 |
| height disagreement percent | 0.0 |
| widest at station percent | 96.7 |
| hull beam | 8.7 |
| hull depth | 4.9 |
| L to B hull | 2.99 |
| L to H hull | 5.31 |
| prow overhang | 1.07 |
| outline iou percent | 84.3 |
| mass outline iou percent | 83.6 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | wake-sniffer scoop, 1.9 across | 1 | 0.3 | 1.20 | -0.10 | forward | - | picture | port wake-sniffer scoop |
| I2 | wake-sniffer scoop, 1.9 across | 1 | 0.3 | -1.20 | -0.10 | forward | - | picture | starboard wake-sniffer scoop |
| D1 | listening dish, 1.9 across | 1 | 12.2 | 1.25 | 1.95 | 5 deg off the bow to port, +12 elev | - | picture | port listening dish |
| D2 | listening dish, 1.9 across | 1 | 12.2 | -1.25 | 1.95 | 5 deg off the bow to starboard, +12 elev | - | picture | starboard listening dish |
| H1 | boarding claw, 4 segments | 1 | 11.4 | 1.45 | -2.55 | hook forward and down | - | picture | port boarding claw, hinged, swings forward to grip |
| H2 | boarding claw, 4 segments | 1 | 11.4 | -1.45 | -2.55 | hook forward and down | - | picture | starboard boarding claw, hinged, swings forward to grip |
| H3 | boarding claw, 3 segments | 1 | 53.5 | 2.10 | -3.25 | hook forward and down | - | designed | grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath) |
| H4 | boarding claw, 3 segments | 1 | 53.5 | -2.10 | -3.25 | hook forward and down | - | designed | grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath) |
| C1 | lashing chain, taut between lugs | 1 | 22.1 | 3.75 | 0.60 | to station 22.1%, offset -3.90 | - | picture | girdle over the tier 2 seam |
| C2 | lashing chain, taut between lugs | 1 | 59.4 | 4.40 | 0.40 | to station 59.4%, offset -4.60 | - | picture | girdle over the castle seam |
| C3 | lashing chain, taut between lugs | 1 | 14.5 | 3.50 | -0.20 | to station 56.2%, offset 4.43 | - | picture | port flank lashing, bow to midships |
| R1 | rocket rack, 2 by 5 tubes | 10 tubes | 40.7 | 0.00 | 2.65 | forward, +6 elev | F htorp | picture | heavy rocket rack, 10 tubes, magazine below |
| T1 | twin turret | 2 barrels | 31.5 | 0.00 | 3.45 | forward, +10 elev | T flak | picture | forward flak turret on the gun bunker |
| T2 | twin turret | 2 barrels | 69.3 | 0.00 | 4.05 | forward, +10 elev | T flak | picture | castle flak turret, superfiring over the rack |
| PB | single ball casemate | 1 barrel | 9.9 | 3.25 | 0.30 | 15 deg off the bow to port | P scatter | picture | bow casemate, trained forward |
| P1 | twin turret | 2 barrels | 26.9 | 2.75 | 2.65 | 45 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 |
| P2 | twin turret | 2 barrels | 36.9 | 2.75 | 2.65 | 45 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 |
| P3 | twin turret | 2 barrels | 46.9 | 2.75 | 2.65 | 45 deg off the bow to port | P scatter | picture | deck-edge twin turret, tier 2 |
| P4 | twin ball casemate | 2 barrels | 65.0 | 3.12 | 2.85 | 55 deg off the bow to port | P scatter | picture | castle flank twin casemate |
| P5 | twin ball casemate | 2 barrels | 73.5 | 3.12 | 2.85 | 55 deg off the bow to port | P scatter | picture | castle flank twin casemate |
| SB | single ball casemate | 1 barrel | 9.9 | -3.25 | 0.30 | 15 deg off the bow to starboard | S scatter | picture | bow casemate, trained forward |
| S1 | twin turret | 2 barrels | 26.9 | -2.75 | 2.65 | 45 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 |
| S2 | twin turret | 2 barrels | 36.9 | -2.75 | 2.65 | 45 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 |
| S3 | twin turret | 2 barrels | 46.9 | -2.75 | 2.65 | 45 deg off the bow to starboard | S scatter | picture | deck-edge twin turret, tier 2 |
| S4 | twin ball casemate | 2 barrels | 65.0 | -3.12 | 2.85 | 55 deg off the bow to starboard | S scatter | picture | castle flank twin casemate |
| S5 | twin ball casemate | 2 barrels | 73.5 | -3.12 | 2.85 | 55 deg off the bow to starboard | S scatter | picture | castle flank twin casemate |
| E0 | engine, bell 3.0 across | 1 | 95.5 | 0.00 | -0.10 | exhaust aft | - | picture | centre main engine |
| E1 | engine, bell 3.6 across | 1 | 92.4 | 4.25 | 0.30 | exhaust aft | - | picture | port main pod, the large one |
| E2 | engine, bell 3.1 across | 1 | 92.4 | -4.25 | 0.30 | exhaust aft | - | designed | starboard main pod, smaller (mismatched) |
| E3 | engine, bell 1.2 across | 1 | 90.9 | 1.50 | -2.00 | exhaust aft | - | picture | lower booster |
| E4 | engine, bell 1.2 across | 1 | 90.9 | -1.50 | -2.00 | exhaust aft | - | designed | lower booster |
| E5 | engine, bell 1.3 across | 1 | 89.7 | -1.30 | 2.75 | exhaust aft | - | picture | upper starboard pod on the stern deck |
| Q1 | attitude thruster quad | 1 | 6.1 | 2.85 | 0.60 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 6.1 | -2.90 | 0.60 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 87.0 | 2.40 | 1.20 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 87.0 | -2.40 | 1.20 | - | - | designed | stern |
| B1 | ventral launch bay door, 3.6 x 3.4 | 1 | 58.5 | 0.00 | -3.10 | forward, -90 elev | - | designed | data.js hangar 2: squadrons drop from the belly |

Totals: 14 gun mounts with 26 barrels; 10 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 3 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot black base plate | 0.0 | 100.0 | whole hull | patched, worn; dim red running lights |
| rust plate (tier 2) | 23.0 | 60.0 | raised armoured deck |  |
| violet Eclipse trophy plate | 26.9 | 33.0 | tier 2 deck, starboard |  |
| violet Eclipse trophy plate | 25.3 | 31.9 | port flank |  |
| pale Hegemony grey trophy plates | 40.0 | 50.8 | port flank |  |
| dried-blood red band | 58.3 | 61.4 | castle front |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull slab (tier 1) | 4.1 to 93.2 | -4.45 to 4.25 | -3.05 to 1.85 | soot black, patched plate | deep flat-bellied slab, blunt chin |
| Raised armoured deck (tier 2) | 23.0 to 60.0 | -3.55 to 3.40 | 1.50 to 2.65 | rust plate | the stacked slab over the forward two thirds |
| Castle (tier 3) | 58.5 to 80.1 | -3.20 to 3.10 | 2.30 to 3.45 | soot with a dried-blood band |  |
| Bridge block | 63.9 to 74.7 | -1.90 to 1.90 | 3.35 to 4.05 | soot | command deck on the castle roof |
| Flank sponsons and belt strakes | 61.2 to 74.7 | 2.90 to 4.45 | 0.20 to 1.75 | soot, iron | one per side, matched |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.55 (9% to 89%); main deck 0.10 (8% to 89%); gun deck 1.95 (25% to 59%); castle deck 2.75 (60% to 79%).

Bulkhead and frame stations: F0 7.6%, F1 19.2%, F2 31.5%, F3 46.9%, F4 60.0%, F5 74.7%, F6 84.7%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| ram void (armour) | 4.5 to 7.6 | -2.00 to 2.00 | -1.00 to 1.00 | ram plating and scoop ducts |
| claw machinery (machinery) | 8.0 to 18.8 | -2.60 to 2.60 | -2.40 to -1.65 | claw rams and winches |
| kennel decks (crew) | 8.4 to 31.1 | -3.00 to 3.00 | -1.45 to 1.60 | boarding gangs, two decks |
| rocket magazine (magazine) | 31.9 to 51.5 | -1.60 to 1.60 | 0.20 to 1.85 | under the rocket rack |
| loot hold (hold) | 31.9 to 46.5 | -3.20 to 3.20 | -2.60 to -1.65 | loot holds |
| hangar (hangar) | 47.3 to 66.2 | -2.60 to 2.60 | -2.70 to 0.00 | two squadrons, belly drop |
| core (core) | 66.6 to 74.3 | -1.30 to 1.30 | -2.60 to 0.00 | reactor core (hp_core) |
| shell magazine p (magazine) | 60.4 to 74.3 | 1.60 to 3.30 | 0.20 to 1.80 | port battery magazine |
| shell magazine s (magazine) | 60.4 to 74.3 | -3.30 to -1.60 | 0.20 to 1.80 | starboard battery magazine |
| gun deck (crew) | 25.3 to 59.6 | -2.60 to 2.60 | 2.00 to 2.50 | turret crews and hoists |
| warlord hall (crew) | 60.4 to 78.9 | -2.40 to 2.40 | 2.80 to 3.30 | the warlord hall |
| bridge (bridge) | 64.3 to 74.3 | -1.40 to 1.40 | 3.40 to 3.90 | command deck |
| engine room (engroom) | 75.1 to 89.3 | -2.00 to 2.00 | -2.10 to 1.60 | engine room and pod feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ram bow (forward of 11.0) | 0.60 | stacked scrap ram plating behind the scoops |
| flank belt (lower and main decks) | 0.40 | patch plates over the base hull |
| tier 2 and castle roof | 0.30 |  |
| belly | 0.35 | flat armoured belly with chines |
| engine end | 0.20 | thinnest: the soft spot |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 23.0 (seam wanders 20.7 to 23.8) | tier 2 seam under the C1 girdle: the bow and the kennel decks tear off; C1 holds them a moment |
| B-2 | 59.6 (seam wanders 57.7 to 61.2) | castle seam under the C2 girdle: opens the rocket magazine and the hangar |
| B-3 | 78.5 (seam wanders 77.8 to 80.5) | castle and engine room seam: the engine block tears away with the stern |

Full interiors throughout the hull (R215): decks, frames, spaces and machinery along the whole length, hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 70.4 | 0.00 | -1.30 |  |  |  |
| hp_breach_0 | 13.8 | 3.45 | 0.20 | port | prow |  |
| hp_breach_1 | 21.5 | -3.90 | -1.20 | stbd | prow |  |
| hp_breach_2 | 34.6 | 4.20 | -0.60 | port | mid |  |
| hp_breach_3 | 59.6 | -3.30 | 2.50 | stbd | mid |  |
| hp_breach_4 | 53.1 | 4.40 | 0.90 | port | mid |  |
| hp_breach_5 | 78.9 | 2.70 | 0.90 | port | eng |  |
| hp_breach_6 | 83.2 | -2.60 | -1.40 | stbd | eng |  |
| hp_rcs_0 | 6.1 | 3.10 | 0.60 | port |  |  |
| hp_rcs_1 | 6.1 | -3.15 | 0.60 | stbd |  |  |
| hp_board_0 | 42.3 | 4.30 | -1.00 | port |  |  |
| hp_board_1 | 42.3 | -4.50 | -1.00 | stbd |  |  |
| hp_bay_0 | 58.5 | 0.00 | -3.15 |  |  | launch down |

## Changed from the picture (R207)

- **Guns laid out as matched port and starboard batteries by game slot.** the picture has a row of guns on one deck edge and a cluster on the other flank; scatter P and S are now mirrored: a bow casemate, three deck-edge twin turrets and two castle casemates per side, the flak turrets on the spine.
- **Profile set from a true side reading: deep flat-bellied slab, raised tier 2, castle, bridge block.** one three-quarter camera cannot see height; the round 8 side view and the shape reference give a hull 4.9 deep, 6.5 to the castle roof and 7.1 to the bridge.
- **Roof turret rests facing forward.** the picture draws its barrel aft; no gun faces aft.
- **The mid-length starboard engine pod becomes an upper pod on the stern deck.** a pod at mid-length glowing forward would push the ship backward and burn its own deck.
- **Two main engine pods, port larger, plus a centre main and lower boosters.** the picture shows the port pod only; a single side pod would turn the ship; the faction keeps mismatched bells.
- **Chains are taut girdles over the tier seams.** a slack chain cannot sag in space; the faction rule is chains between hull sections, and the girdles sit on the break lines.
- **Bow claws hinged on housings; two grapple arms added under the belly.** the picture hooks hang from nothing; the round 8 side sheet and Ryan (R196) put hooks underneath.
- **Ventral launch bay and four attitude thruster quads added.** data.js gives the barge a hangar of 2; a ship in space needs thrusters to turn.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Belly detail between the claws and the bay is designed here; the picture does not show it.
- H3 (boarding claw, 3 segments): grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath).
- H4 (boarding claw, 3 segments): grapple arm under the belly (round 8 side sheet; Ryan R196: hooks underneath).
- E2 (engine, bell 3.1 across): starboard main pod, smaller (mismatched).
- E4 (engine, bell 1.2 across): lower booster.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
- B1 (ventral launch bay door, 3.6 x 3.4): data.js hangar 2: squadrons drop from the belly.
