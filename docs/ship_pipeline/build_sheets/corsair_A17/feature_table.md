# corsair_A17: Hullbreaker wrecker (the Pack Hunter), build sheet

Ashfall Hullbreakers (corsair) | class Cruiser | version 1, 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\corsair_A17\corsair_A17_blockout.blend`

**Length 14.5 world units** (data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.521 |
| length side | 14.55 |
| length top | 14.55 |
| length disagreement percent | 0.0 |
| beam top | 7.388 |
| beam bow | 7.638 |
| beam disagreement percent | 1.72 |
| height side | 5.575 |
| height bow | 5.575 |
| height disagreement percent | 0.0 |
| widest at station percent | 69.8 |
| hull beam | 4.88 |
| hull depth | 3.83 |
| L to B hull | 2.97 |
| L to H hull | 3.79 |
| prow overhang | 2.37 |
| outline iou percent | 86.3 |
| mass outline iou percent | 86.8 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | wake-sniffer scoop, 1.2 across | 1 | 13.6 | 1.41 | -0.66 | forward | - | picture | port scoop, low, ribbed duct along the port chin |
| I2 | wake-sniffer scoop, 0.8 across | 1 | 14.6 | -1.54 | 0.13 | forward | - | picture | starboard scoop, small (mismatched pair) |
| D1 | listening dish, 1.6 across | 1 | 27.3 | 2.20 | 0.88 | 35 deg off the bow to port, +10 elev | - | picture | port ear, on the head flank |
| D2 | listening dish, 1.6 across | 1 | 22.5 | -1.98 | 1.36 | 30 deg off the bow to starboard, +15 elev | - | picture | starboard ear, on the head top edge |
| J1 | boarding jaw, 3 segments | 1 | 19.1 | -1.50 | -0.97 | hook forward and down | - | picture | starboard upper jaw |
| J2 | boarding jaw, 3 segments | 1 | 20.5 | -0.88 | -1.28 | hook forward and down | - | picture | starboard lower jaw (shorter, mismatched) |
| J3 | boarding jaw, 3 segments | 1 | 22.5 | 0.97 | -1.28 | hook forward and down | - | picture | port lower jaw |
| J4 | boarding jaw, 3 segments | 1 | 19.1 | 1.58 | -0.88 | hook forward and down | - | designed | port upper jaw: hidden behind the port scoop in the picture; pairs J1 so the jaws can close |
| C1 | lashing chain, taut between lugs | 1 | 51.4 | 2.46 | 1.58 | to station 55.6%, offset -2.51 | - | picture | girdle over the hump front |
| C2 | lashing chain, taut between lugs | 1 | 26.7 | -2.24 | 1.28 | to station 59.7%, offset -2.51 | - | picture | starboard edge lashing, head to hump |
| R1 | rocket rack, 2 by 3 tubes | 6 tubes | 26.7 | 0.44 | 1.80 | forward, +5 elev | F torp | designed | rattle-rocket pod on the head top: data.js gives the wrecker a forward rocket slot; the picture shows none |
| T1 | single turret | 1 barrel | 39.1 | -0.26 | 1.54 | forward, +8 elev | T flak | picture | neck turret on a pedestal |
| T2 | twin turret | 2 barrels | 68.0 | 0.62 | 2.75 | forward, +6 elev | T flak | picture | hump-top twin |
| S1 | twin turret | 2 barrels | 27.3 | -2.16 | 1.28 | 45 deg off the bow to starboard | S scatter | picture | starboard edge |
| S2 | twin turret | 2 barrels | 37.0 | -2.20 | 1.50 | 45 deg off the bow to starboard | S scatter | picture | starboard edge |
| S3 | single turret | 1 barrel | 47.3 | -2.38 | 2.02 | 35 deg off the bow to starboard | S scatter | picture | starboard edge |
| S4 | twin ball casemate | 2 barrels | 76.9 | -2.46 | 0.53 | 50 deg off the bow to starboard | S scatter | designed | starboard hump casemate; the picture does not show the starboard flank |
| P1 | twin ball casemate | 2 barrels | 75.6 | 2.46 | 0.53 | 50 deg off the bow to port | P scatter | picture | port hump casemate |
| P2 | single ball casemate | 1 barrel | 81.8 | 2.24 | 1.32 | 55 deg off the bow to port | P scatter | picture |  |
| P3 | single ball casemate | 1 barrel | 68.7 | 2.46 | -0.62 | 45 deg off the bow to port | P scatter | picture |  |
| P4 | twin belly turret | 2 barrels | 55.6 | 2.02 | -1.45 | 35 deg off the bow to port, -10 elev | P scatter | picture | port chin turret, hangs under the neck |
| E1 | engine, bell 1.2 across | 1 | 94.1 | 1.01 | 1.14 | exhaust aft | - | picture | port upper |
| E2 | engine, bell 1.5 across | 1 | 96.2 | 1.19 | 0.00 | exhaust aft | - | picture | port main, the large one |
| E3 | engine, bell 0.9 across | 1 | 92.8 | 1.32 | -0.84 | exhaust aft | - | picture | port lower, small |
| E4 | engine, bell 1.1 across | 1 | 92.8 | -1.06 | 1.23 | exhaust aft | - | picture | starboard upper |
| E5 | engine, bell 1.2 across | 1 | 94.1 | -1.14 | -0.09 | exhaust aft | - | designed | starboard main, smaller than E2 |

Totals: 10 gun mounts with 16 barrels; 6 launcher tubes; 5 engines; 2 intakes; 2 dishes; 4 claws; 2 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| weathered grey and soot plate | 0.1 | 100.0 | whole hull |  |
| pale grey trophy plate (head top) | 17.7 | 33.5 | head top block |  |
| rust patch | 18.4 | 22.5 | head top, forward |  |
| dried-blood red stripe | 25.3 | 50.1 | starboard deck edge |  |
| dried-blood red patch | 52.8 | 61.1 | hump top |  |
| dried-blood red patch | 72.1 | 79.0 | port hump flank |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull (head, neck, hump) | 16.3 to 90.0 | -2.46 to 2.42 | -1.54 to 2.29 | weathered grey and soot plate | heavy head, narrow neck, shoulder hump |
| Head top block | 17.7 to 33.5 | -1.67 to 1.58 | 1.06 to 1.80 | pale grey trophy plate with a rust patch |  |
| Hump crest | 54.2 to 80.4 | -1.50 to 1.41 | 1.94 to 2.77 | soot with red patches | the shoulder hump top |
| Engine block | 88.6 to 94.1 | -1.90 to 1.90 | -1.00 to 1.90 | soot, steel |  |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.48 (18% to 87%); main deck 0.66 (18% to 87%); hump deck 1.76 (50% to 82%).

Bulkhead and frame stations: F0 20.5%, F1 34.2%, F2 48.7%, F3 69.4%, F4 83.1%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| jaw machinery (machinery) | 18.4 to 26.7 | -1.58 to 1.58 | -1.14 to -0.53 | jaw rams and winches |
| boarding kennels (crew) | 18.4 to 33.5 | -1.67 to 1.67 | -0.40 to 0.62 | boarding gangs at the jaws |
| ears sensor room (bridge) | 19.8 to 32.2 | -1.23 to 1.23 | 0.75 to 1.41 | listening room behind the dishes, the bridge |
| rocket magazine (magazine) | 26.7 to 32.2 | -0.35 to 1.14 | 1.28 to 1.76 | under the rocket pod |
| loot hold (hold) | 34.9 to 48.0 | -1.76 to 1.76 | -1.23 to 0.57 | neck hold |
| crew decks (crew) | 49.4 to 68.0 | -1.94 to 1.94 | 0.75 to 1.67 |  |
| shell magazine (magazine) | 49.4 to 68.0 | -1.94 to 1.94 | -1.23 to 0.57 | battery magazines |
| flak magazine (magazine) | 62.5 to 73.5 | -0.53 to 1.23 | 1.85 to 2.46 | under the hump twin |
| core (core) | 70.0 to 81.8 | -1.06 to 1.06 | -1.14 to 0.57 | reactor core (hp_core) |
| engine room (engroom) | 83.8 to 88.6 | -1.58 to 1.58 | -0.79 to 1.58 | engine room and feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| head (forward of 4.3) | 0.45 | ram plate behind the jaws |
| flanks | 0.25 | patch plates |
| hump roof and deck | 0.20 |  |
| belly | 0.25 | flat armoured belly with chines |
| engine end | 0.15 | thinnest |

| Break line | Station % | What it opens |
|---|---:|---|
| B-1 | 34.2 | the neck seam under the C2 lashing: the head and jaws tear off, opening the kennels and the hold |
| B-2 | 83.1 | hump/engine seam: the engine cluster tears away, opening the engine room |

## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 75.6 | 0.00 | -0.26 |  |  |  |
| hp_breach_0 | 23.2 | 2.40 | 0.90 | port | prow |  |
| hp_breach_1 | 29.4 | -2.50 | -0.60 | stbd | prow |  |
| hp_breach_2 | 43.9 | 2.70 | 1.20 | port | mid |  |
| hp_breach_3 | 62.5 | -2.85 | 0.20 | stbd | mid |  |
| hp_breach_4 | 84.5 | 2.35 | 1.50 | port | eng |  |
| hp_rcs_0 | 18.4 | 2.16 | 0.53 | port |  |  |
| hp_rcs_1 | 18.4 | -2.20 | 0.53 | stbd |  |  |
| hp_board_0 | 54.2 | 2.42 | 0.18 | port |  |  |
| hp_board_1 | 54.2 | -2.46 | 0.18 | stbd |  |  |

## Changed from the picture (R207)

- **Every gun rests facing forward or trained 35 to 55 degrees off the bow.** the picture draws two port flank guns trained aft; no gun faces aft.
- **Every gun sits on a turning ring or a ball casemate.** several picture guns stand on thin posts or come straight out of plate.
- **Jaws hinge on a housing under the head and their hooks turn inboard.** the picture jaws are loose arms; jaws that open sideways must close on something.
- **Fourth jaw J4 added (port upper).** the picture shows three; a pair per side lets the jaws close (it would sit behind the port scoop in the picture).
- **Chains are taut lashings between lugs.** a slack chain cannot drape in space; the faction rule is chains between hull sections.
- **Forward rocket pod R1 added on the head top.** data.js gives the wrecker a forward rocket slot (torp F); the picture shows no launcher.
- **Engine glow points aft only.** the picture shows the upper starboard pod glowing at its front.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Starboard flank aft of the hump front: designed here (S4, E5); the picture does not show it.
- Belly between the jaw housing and the engines: flat armoured belly with chines, P4 chin turret; the picture does not show it.
- J4 (boarding jaw, 3 segments): port upper jaw: hidden behind the port scoop in the picture; pairs J1 so the jaws can close.
- R1 (rocket rack, 2 by 3 tubes): rattle-rocket pod on the head top: data.js gives the wrecker a forward rocket slot; the picture shows none.
- S4 (twin ball casemate): starboard hump casemate; the picture does not show the starboard flank.
- E5 (engine, bell 1.2 across): starboard main, smaller than E2.
