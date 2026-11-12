# corsair_A16: Warlord's Pyre-Barge, build sheet

Ashfall Hullbreakers (corsair) | class Battle-barge | version 1, 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\corsair_A16\corsair_A16_blockout.blend`

**Length 26.0 world units** (data.js c_boss (cls 'Battle-barge'); length from godot/render/hull_table.gd CLS_LEN['Battle-barge'] = 26.0 (drawn x SHIP_K 1.6 = 41.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 26.0 |
| length side | 26.025 |
| length top | 26.025 |
| length disagreement percent | 0.0 |
| beam top | 11.9 |
| beam bow | 12.05 |
| beam disagreement percent | 0.58 |
| height side | 10.65 |
| height bow | 10.65 |
| height disagreement percent | 0.0 |
| widest at station percent | 71.3 |
| hull beam | 8.3 |
| hull depth | 4.45 |
| L to B hull | 3.13 |
| L to H hull | 5.84 |
| prow overhang | 1.32 |
| outline iou percent | 85.8 |
| mass outline iou percent | 85.7 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | wake-sniffer scoop, 1.9 across | 1 | 0.3 | 1.45 | -0.45 | forward | - | picture | port scoop |
| I2 | wake-sniffer scoop, 1.9 across | 1 | 0.3 | -1.45 | -0.45 | forward | - | picture | starboard scoop |
| D1 | listening dish, 1.7 across | 1 | 8.5 | 1.40 | 2.20 | 10 deg off the bow to port, +15 elev | - | picture | port dish, faces forward |
| D2 | listening dish, 1.7 across | 1 | 9.7 | -0.60 | 2.30 | 5 deg off the bow to starboard, +15 elev | - | picture | centre dish, faces forward |
| H1 | boarding claw, 4 segments | 1 | 17.0 | 1.50 | -1.65 | hook forward and down | - | picture | port boarding claw, hinged, folds back under the bow |
| H2 | boarding claw, 4 segments | 1 | 11.6 | -1.70 | -1.50 | hook forward and down | - | picture | starboard boarding claw, mismatched (longer reach) |
| C1 | lashing chain, taut between lugs | 1 | 13.9 | 3.15 | 1.45 | to station 46.2%, offset 3.75 | - | picture | port upper lashing, bow to castle |
| C2 | lashing chain, taut between lugs | 1 | 19.3 | 3.62 | -0.90 | to station 59.7%, offset 3.82 | - | picture | port lower lashing, across the 1st break line |
| C3 | lashing chain, taut between lugs | 1 | 50.8 | 3.20 | 2.65 | to station 52.4%, offset -3.60 | - | picture | deck girdle over the foredeck/castle seam |
| R1 | rocket rack, 2 by 5 tubes | 10 tubes | 43.9 | -1.10 | 2.60 | forward, +6 elev | F htorp | picture | heavy rocket pod; tubes fire forward over the bow |
| S1 | single turret | 1 barrel | 13.2 | -3.25 | 2.00 | 60 deg off the bow to starboard | S scatter | picture | bow corner |
| S2 | single turret | 1 barrel | 19.3 | -3.45 | 2.10 | 60 deg off the bow to starboard | S scatter | picture |  |
| S3 | single turret | 1 barrel | 27.4 | -3.55 | 2.25 | 55 deg off the bow to starboard | S scatter | picture | heavy single |
| S4 | single turret | 1 barrel | 35.1 | -3.60 | 2.25 | 55 deg off the bow to starboard | S scatter | picture | big-bore single |
| S5 | twin turret | 2 barrels | 42.8 | -3.65 | 2.25 | 55 deg off the bow to starboard | S scatter | picture | twin |
| S6 | single sponson turret | 1 barrel | 69.3 | -3.60 | 2.25 | 55 deg off the bow to starboard | S scatter | designed | starboard castle; not visible in the picture |
| S7 | twin ball casemate | 2 barrels | 77.0 | -3.85 | 0.40 | 50 deg off the bow to starboard | S scatter | designed | starboard lower flank; not visible in the picture |
| P1 | twin ball casemate | 2 barrels | 50.8 | 3.95 | 0.90 | 50 deg off the bow to port | P scatter | picture |  |
| P2 | single ball casemate | 1 barrel | 52.4 | 3.95 | -1.00 | 45 deg off the bow to port, -5 elev | P scatter | picture |  |
| P3 | twin sponson turret | 2 barrels | 67.8 | 3.75 | 2.60 | 55 deg off the bow to port | P scatter | picture | castle |
| P4 | twin ball casemate | 2 barrels | 75.5 | 3.95 | 0.90 | 60 deg off the bow to port | P scatter | picture |  |
| P5 | single ball casemate | 1 barrel | 63.9 | 3.95 | -0.60 | 40 deg off the bow to port | P scatter | picture | long single |
| T1 | twin turret | 2 barrels | 73.2 | 0.30 | 4.42 | forward, +10 elev | T flak | picture | roof turret; rests forward (the picture shows it aft) |
| E1 | engine, bell 3.5 across | 1 | 95.0 | 2.40 | 0.40 | exhaust aft | - | picture | port main, the large one |
| E2 | engine, bell 2.5 across | 1 | 93.2 | -2.40 | 0.50 | exhaust aft | - | designed | starboard main, smaller (mismatched) |
| E3 | engine, bell 1.4 across | 1 | 93.2 | 2.80 | -1.10 | exhaust aft | - | picture | port lower booster |
| E4 | engine, bell 1.4 across | 1 | 92.0 | -2.60 | 2.75 | exhaust aft | - | picture | starboard upper stern pod |
| E5 | engine, bell 1.5 across | 1 | 54.7 | -4.60 | 2.30 | exhaust aft | - | picture | starboard shoulder booster on a strut |
| B1 | ventral launch bay door, 6.0 x 3.2 | 1 | 52.0 | 0.00 | -2.20 | forward, -90 elev | - | designed | data.js hangar 2: squadrons drop from the belly |
| B2 | ventral scoop housing (claw stowage) | 1 | 27.0 | 0.00 | -2.15 | - | - | designed | claws fold back into it |

Totals: 13 gun mounts with 19 barrels; 10 launcher tubes; 5 engines; 2 intakes; 2 dishes; 2 claws; 3 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot black base plate | 0.1 | 100.0 | whole hull | patched, worn, dim red running lights |
| rust plate (raised foredeck) | 10.1 | 53.2 | deck |  |
| violet Eclipse trophy plate | 10.8 | 17.0 | deck, starboard of the dishes |  |
| violet Eclipse trophy plate | 25.5 | 32.4 | port flank, upper |  |
| pale Hegemony grey trophy plates | 39.3 | 48.5 | port flank, torn and overlapped |  |
| dried-blood red band | 52.0 | 56.2 | round the hull and the castle front |  |
| rust patch | 54.7 | 67.4 | port flank, lower |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull slab | 5.1 to 86.2 | -4.20 to 4.10 | -2.35 to 2.10 | soot black, patched plate | one long lopsided slab, blunt bow |
| Foredeck plating | 10.1 to 53.2 | -3.20 to 2.80 | 1.40 to 2.60 | rust plate | raised second skin |
| Command bunker | 30.1 to 37.4 | -0.90 to 1.50 | 2.40 to 3.55 | soot | bridge, armoured |
| Aft castle | 52.4 to 89.3 | -2.80 to 3.30 | 1.50 to 4.10 | soot with a dried-blood band | stepped stern block |
| Castle top deck | 63.9 to 87.0 | -1.60 to 2.00 | 3.70 to 4.60 | soot |  |
| Engine block | 85.5 to 93.2 | -2.90 to 2.90 | -1.20 to 2.60 | soot, steel |  |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.90 (8% to 85%); main deck 0.60 (8% to 85%); castle deck 2.30 (47% to 83%).

Bulkhead and frame stations: F0 10.1%, F1 23.2%, F2 36.2%, F3 47.8%, F4 62.4%, F5 74.7%, F6 84.7%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| ram void (armour) | 6.2 to 9.7 | -2.30 to 2.30 | -1.20 to 1.00 | ram plating backing and scoop ducts |
| claw machinery (machinery) | 10.5 to 22.4 | -2.60 to 2.60 | -1.90 to -1.00 | claw winches and stowage |
| kennel decks (crew) | 10.8 to 35.5 | -3.00 to 3.00 | -0.80 to 0.50 | boarding gangs, kennel decks |
| rocket magazine (magazine) | 23.9 to 46.2 | -1.40 to 1.40 | 0.70 to 2.20 | under the rocket rack |
| loot hold (hold) | 23.9 to 47.0 | -3.00 to 3.00 | -1.90 to -1.00 | loot holds |
| hangar (hangar) | 48.5 to 61.6 | -2.40 to 2.40 | -1.90 to 0.50 | two squadrons, belly drop |
| shell magazine p (magazine) | 63.2 to 73.9 | 1.40 to 3.20 | -0.80 to 0.50 | port battery magazine |
| shell magazine s (magazine) | 63.2 to 73.9 | -3.40 to -1.40 | -0.80 to 0.50 | starboard battery magazine |
| core (core) | 63.2 to 73.9 | -1.20 to 1.20 | -1.90 to 0.50 | reactor core (hp_core) |
| castle crew (crew) | 47.8 to 82.4 | -2.60 to 2.60 | 2.40 to 3.30 | warlord hall and gun crews |
| flak magazine (magazine) | 68.5 to 77.8 | -1.00 to 1.00 | 3.30 to 4.30 | flak turret magazine |
| engine room (engroom) | 74.7 to 84.7 | -3.00 to 3.00 | -1.90 to 2.20 | engine room and feeds |
| bunker bridge (bridge) | 30.5 to 37.0 | -0.60 to 1.20 | 2.45 to 3.40 | command bunker |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ram bow (forward of 10.4) | 0.60 | stacked scrap ram plating |
| flank belt (main and lower decks) | 0.35 | patch plates over the base hull |
| deck and castle roof | 0.25 |  |
| belly | 0.30 | flat armoured belly with chines |
| engine end | 0.20 | thinnest: the soft spot |

| Break line | Station % | What it opens |
|---|---:|---|
| B-1 | 23.5 | chained seam behind the kennel decks; C2 lashing crosses it and holds the bow for a moment |
| B-2 | 47.4 | the foredeck/castle seam under the C3 girdle; opens the rocket magazine and hangar |
| B-3 | 74.3 | castle/engine room seam; the engine block tears away with the stern |

## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 68.5 | 0.00 | -0.70 |  |  |  |
| hp_breach_0 | 15.5 | 3.40 | 0.40 | port | prow |  |
| hp_breach_1 | 20.8 | -3.85 | -0.80 | stbd | prow |  |
| hp_breach_2 | 34.7 | 3.80 | 0.20 | port | mid |  |
| hp_breach_3 | 44.7 | 0.40 | 2.65 | top | mid |  |
| hp_breach_4 | 56.2 | -4.20 | 1.00 | stbd | mid |  |
| hp_breach_5 | 74.3 | 3.80 | 1.20 | port | eng |  |
| hp_breach_6 | 82.8 | -3.40 | -1.00 | stbd | eng |  |
| hp_rcs_0 | 9.7 | 3.30 | 0.60 | port |  |  |
| hp_rcs_1 | 9.7 | -3.45 | 0.60 | stbd |  |  |
| hp_board_0 | 42.4 | 3.85 | -0.20 | port |  |  |
| hp_board_1 | 46.2 | -4.25 | -0.20 | stbd |  |  |
| hp_bay_0 | 52.0 | 0.00 | -2.25 |  |  | launch down |

## Changed from the picture (R207)

- **Roof turret T1 rests facing forward.** the picture draws its barrel aft; no gun in the game faces aft.
- **Chains are taut lashings between lugs on the hull.** a slack chain cannot hang in a sagging loop in space; the faction rule is chains between hull sections.
- **Every gun sits on a mount that can turn: deck-edge guns on turret rings, flank guns in ball casemates.** several picture guns poke straight out of flat plate with no mount that could turn.
- **Broadside guns rest trained 40 to 60 degrees forward of the beam.** the picture draws the port guns square or slightly aft; no gun faces aft, and a barrel at rest must read in both the profile and the plan.
- **Deck-edge barrels shortened (S4 big-bore 1.5 long, the light guns under 1).** the picture barrels are longer than the hull is deep at their stations and read as poles; kept heavy and short like the rest of the scrap guns.
- **Starboard shoulder booster E5 put on a strut with its bell aft.** the picture shows a pod at mid-length with its glow facing forward, which would push the ship backward.
- **Claws are hinged on drums with actuator housings and fold back into a belly scoop.** the picture hooks hang from nothing visible.
- **Ventral launch bay added (B1).** data.js gives the Pyre-Barge a hangar of 2; the picture shows no bay.
- **Crystal shard removed.** Ryan, R197 (already gone from A16).

## Designed here, not shown in the picture

- Starboard flank below the gallery: designed here (S6, S7, E2); the picture does not show it.
- Belly plating detail beyond the bay, scoop and claw stowage: the picture does not show it.
- S6 (single sponson turret): starboard castle; not visible in the picture.
- S7 (twin ball casemate): starboard lower flank; not visible in the picture.
- E2 (engine, bell 2.5 across): starboard main, smaller (mismatched).
- B1 (ventral launch bay door, 6.0 x 3.2): data.js hangar 2: squadrons drop from the belly.
- B2 (ventral scoop housing (claw stowage)): claws fold back into it.
