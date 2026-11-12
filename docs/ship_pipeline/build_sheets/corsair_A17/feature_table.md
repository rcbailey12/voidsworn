# corsair_A17: Hullbreaker wrecker (the Pack Hunter), build sheet

Ashfall Hullbreakers (corsair) | class Cruiser | version 1, 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\corsair_A17\corsair_A17_blockout.blend`

**Length 14.5 world units** (data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.502 |
| length side | 14.525 |
| length top | 14.525 |
| length disagreement percent | 0.0 |
| beam top | 7.438 |
| beam bow | 7.438 |
| beam disagreement percent | 0.0 |
| height side | 6.45 |
| height bow | 6.45 |
| height disagreement percent | 0.0 |
| widest at station percent | 67.1 |
| hull beam | 5.15 |
| hull depth | 3.35 |
| L to B hull | 2.82 |
| L to H hull | 4.33 |
| prow overhang | 2.35 |
| outline iou percent | 83.7 |
| mass outline iou percent | 84.0 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | wake-sniffer scoop, 1.2 across | 1 | 13.5 | 2.55 | 0.25 | forward | - | picture | port scoop drum along the head flank, the larger |
| D1 | listening dish, 1.7 across | 1 | 32.1 | 2.40 | 1.40 | 25 deg off the bow to port, +10 elev | - | picture | port ear, listening dish |
| I2 | wake-sniffer scoop, 1.1 across | 1 | 13.5 | -2.55 | 0.25 | forward | - | picture | starboard scoop drum along the head flank |
| D2 | listening dish, 1.7 across | 1 | 32.1 | -2.40 | 1.40 | 25 deg off the bow to starboard, +10 elev | - | picture | starboard ear, listening dish |
| J1 | boarding jaw, 3 segments | 1 | 19.7 | 1.55 | -1.75 | hook forward and down | - | picture | port lower jaw, hinged, opens sideways |
| J3 | boarding jaw, 3 segments | 1 | 18.3 | 2.20 | -0.85 | hook forward and down | - | designed | port upper jaw |
| J2 | boarding jaw, 3 segments | 1 | 19.7 | -1.55 | -1.75 | hook forward and down | - | picture | starboard lower jaw, hinged, opens sideways |
| J4 | boarding jaw, 3 segments | 1 | 18.3 | -2.20 | -0.85 | hook forward and down | - | picture | starboard upper jaw |
| C1 | lashing chain, taut between lugs | 1 | 33.1 | 2.35 | -0.60 | to station 33.1%, offset -2.35 | - | picture | girdle over the neck seam |
| C2 | lashing chain, taut between lugs | 1 | 54.8 | 2.75 | 0.20 | to station 54.8%, offset -2.80 | - | picture | girdle over the hump front |
| R1 | rocket rack, 2 by 3 tubes | 6 tubes | 20.0 | 0.00 | 1.85 | forward, +5 elev | F torp | picture | rattle-rocket pod on the brow, firing over the jaws |
| T1 | twin turret | 2 barrels | 67.2 | 0.00 | 3.20 | forward, +8 elev | T flak | picture | hump-top twin, 360 degrees |
| T2 | twin belly turret | 2 barrels | 61.0 | 0.00 | -1.75 | forward, -8 elev | T flak | picture | belly twin, covers below |
| P1 | twin turret | 2 barrels | 38.3 | 1.90 | 1.50 | 45 deg off the bow to port | P scatter | picture | deck-edge twin turret |
| P2 | twin turret | 2 barrels | 52.1 | 1.90 | 1.60 | 45 deg off the bow to port | P scatter | picture | deck-edge twin turret |
| P3 | twin ball casemate | 2 barrels | 72.8 | 2.25 | 2.10 | 55 deg off the bow to port | P scatter | picture | hump flank casemate |
| S1 | twin turret | 2 barrels | 38.3 | -1.90 | 1.50 | 45 deg off the bow to starboard | S scatter | picture | deck-edge twin turret |
| S2 | twin turret | 2 barrels | 52.1 | -1.90 | 1.60 | 45 deg off the bow to starboard | S scatter | picture | deck-edge twin turret |
| S3 | twin ball casemate | 2 barrels | 72.8 | -2.25 | 2.10 | 55 deg off the bow to starboard | S scatter | picture | hump flank casemate |
| E1 | engine, bell 1.3 across | 1 | 96.6 | 1.10 | 1.05 | exhaust aft | - | picture | port upper |
| E2 | engine, bell 1.5 across | 1 | 96.1 | 1.10 | 0.00 | exhaust aft | - | picture | port main |
| E3 | engine, bell 1.1 across | 1 | 97.2 | 1.10 | -0.95 | exhaust aft | - | picture | port lower |
| E4 | engine, bell 1.1 across | 1 | 97.1 | -1.10 | 1.05 | exhaust aft | - | picture | starboard upper |
| E5 | engine, bell 1.3 across | 1 | 96.6 | -1.10 | 0.00 | exhaust aft | - | designed | starboard main |
| E6 | engine, bell 1.0 across | 1 | 97.5 | -1.10 | -0.95 | exhaust aft | - | designed | starboard lower |
| Q1 | attitude thruster quad | 1 | 21.0 | 2.45 | 1.00 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 21.0 | -2.45 | 1.00 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 86.6 | 2.10 | 1.00 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 86.6 | -2.15 | 1.00 | - | - | designed | stern |

Totals: 8 gun mounts with 16 barrels; 6 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 2 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| weathered grey and soot plate | 0.0 | 100.0 | whole hull |  |
| pale grey trophy plate (brow) | 17.3 | 30.7 | head top |  |
| rust patch | 18.3 | 22.4 | brow, forward |  |
| dried-blood red stripes | 36.2 | 53.5 | both deck edges |  |
| dried-blood red patch | 61.0 | 69.3 | hump crest |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull (head, neck, body) | 16.2 to 90.0 | -2.60 to 2.55 | -1.75 to 1.60 | weathered grey and soot plate | heavy head, pinched neck, lean body |
| Head brow | 17.3 to 30.7 | -1.85 to 1.85 | 1.05 to 1.85 | pale grey trophy plate, rust patch | the raised brow of the head |
| Shoulder hump | 47.2 to 84.5 | -2.25 to 2.20 | 1.30 to 2.85 | soot with dried-blood patches | the shoulder hump |
| Hump crest | 58.3 to 76.2 | -1.20 to 1.20 | 2.70 to 3.20 | soot | stepped crest on the hump |
| Engine block | 87.2 to 91.4 | -1.90 to 1.90 | -1.30 to 1.60 | soot, steel |  |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.75 (19% to 87%); main deck 0.55 (19% to 87%); hump deck 1.90 (49% to 80%).

Bulkhead and frame stations: F0 19.7%, F1 32.8%, F2 48.6%, F3 67.9%, F4 82.4%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| jaw machinery (machinery) | 18.3 to 26.6 | -1.80 to 1.80 | -1.45 to -0.85 | jaw rams and winches |
| boarding kennels (crew) | 18.3 to 30.0 | -1.90 to 1.90 | -0.65 to 0.45 | boarding gangs behind the jaws |
| ears and bridge (bridge) | 19.0 to 30.0 | -1.40 to 1.40 | 0.65 to 1.25 | listening room and bridge under the brow |
| rocket magazine (magazine) | 20.4 to 26.6 | -0.60 to 0.60 | 1.30 to 1.80 | under the rocket pod |
| loot hold (hold) | 34.1 to 47.9 | -2.00 to 2.00 | -1.45 to 0.45 | neck hold |
| crew decks (crew) | 49.3 to 67.2 | -2.10 to 2.10 | 0.65 to 1.80 |  |
| shell magazine (magazine) | 49.3 to 67.2 | -2.10 to 2.10 | -1.45 to 0.45 | battery magazines |
| flak magazine (magazine) | 61.7 to 73.5 | -0.80 to 0.80 | 2.00 to 2.65 | under the hump twin |
| core (core) | 69.3 to 81.0 | -1.20 to 1.20 | -1.45 to 0.45 | reactor core (hp_core) |
| engine room (engroom) | 83.1 to 87.2 | -1.80 to 1.80 | -1.20 to 1.40 | engine room and feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| head (forward of 4.4) | 0.45 | ram plate behind the jaws |
| flanks | 0.25 | patch plates and the belt strake |
| hump roof and deck | 0.20 |  |
| belly | 0.25 | flat armoured belly with chines |
| engine end | 0.15 | thinnest |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 33.1 (seam wanders 31.0 to 34.8) | the neck seam under the C1 girdle: the head and jaws tear off, opening the kennels and the hold |
| B-2 | 82.8 (seam wanders 81.0 to 84.5) | hump and engine seam: the engine cluster tears away, opening the engine room |

Full interiors throughout the hull (R215), hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 74.8 | 0.00 | -0.50 |  |  |  |
| hp_breach_0 | 23.1 | 2.45 | 0.90 | port | prow |  |
| hp_breach_1 | 30.0 | -2.45 | -0.60 | stbd | prow |  |
| hp_breach_2 | 44.5 | 2.50 | 1.10 | port | mid |  |
| hp_breach_3 | 63.1 | -2.60 | 0.10 | stbd | mid |  |
| hp_breach_4 | 83.8 | 2.20 | 1.40 | port | eng |  |
| hp_rcs_0 | 21.0 | 2.45 | 1.00 | port |  |  |
| hp_rcs_1 | 21.0 | -2.45 | 1.00 | stbd |  |  |
| hp_board_0 | 53.5 | 2.60 | 0.20 | port |  |  |
| hp_board_1 | 53.5 | -2.65 | 0.20 | stbd |  |  |

## Changed from the picture (R207)

- **Guns laid out as matched batteries by game slot.** the picture scatters guns on one edge and the far flank; scatter P and S are mirrored (two deck-edge twin turrets and a hump casemate per side), flak on the spine and the belly, the rocket pod on the brow.
- **Lean hull, profile from the round 8 side view.** Ryan kept A17 lean (R213); the head sits low and heavy, the hump rises behind the neck.
- **Jaws are two matched pairs hinged on a housing, hooks turned inboard.** the picture shows three loose arms; jaws that open sideways must close on something.
- **Scoops and ears made a matched pair (port scoop larger).** the picture shows a large port scoop and a small starboard one; kept mismatched in size, matched in place.
- **Engines are a stacked cluster of three per side, glow aft only.** the picture shows a port cluster and one starboard pod glowing at its front.
- **Forward rocket pod, belly flak turret and four attitude thrusters added.** data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters.
- **Chains are taut girdles over the neck and hump seams.** a slack chain cannot drape in space; the girdles sit on the break lines.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Belly detail between the jaw housing and the engines is designed here; the picture does not show it.
- J3 (boarding jaw, 3 segments): port upper jaw.
- E5 (engine, bell 1.3 across): starboard main.
- E6 (engine, bell 1.0 across): starboard lower.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
