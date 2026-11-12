# corsair_A17: Hullbreaker wrecker (the Pack Hunter), build sheet

Ashfall Hullbreakers (corsair) | class Cruiser | version 3 (round 3), 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3b\corsair_A17\corsair_A17_blockout.blend`

**Length 14.5 world units** (data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.559 |
| length side | 14.575 |
| length top | 14.588 |
| length disagreement percent | 0.09 |
| beam top | 7.15 |
| beam bow | 7.162 |
| beam disagreement percent | 0.09 |
| height side | 6.562 |
| height bow | 6.562 |
| height disagreement percent | 0.0 |
| widest at station percent | 63.4 |
| hull beam | 5.15 |
| hull depth | 3.35 |
| L to B hull | 2.82 |
| L to H hull | 4.33 |
| prow overhang | 2.14 |
| outline iou percent | 75.5 |
| mass outline iou percent | 75.5 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| SL1 | vision slit 0.7 x 0.14 | 1 | 49.7 | 0.85 | 2.20 | - | - | picture | slit in the hump front |
| HS1 | square hatch 0.5 | 1 | 77.2 | 2.20 | 1.95 | - | - | picture | hatch on the aft hump flank |
| SL2 | vision slit 0.7 x 0.14 | 1 | 49.7 | -0.85 | 2.20 | - | - | picture | slit in the hump front |
| HS2 | square hatch 0.5 | 1 | 77.2 | -2.25 | 1.95 | - | - | picture | hatch on the aft hump flank |
| SL3 | vision slit 1.2 x 0.12 | 1 | 58.3 | 0.00 | 2.84 | - | - | picture | slit in the crest front |
| I1 | scoop drum with a grille, 1.2 across, 2.7 deep | 1 | 10.6 | 2.42 | -0.32 | forward | - | picture | port scoop drum at the head's lower corner, the larger |
| D1 | listening dish, 1.6 across | 1 | 20.5 | 1.95 | 1.40 | 30 deg off the bow to port, +8 elev | - | picture | port ear, listening dish |
| I2 | scoop drum with a grille, 1.1 across, 2.7 deep | 1 | 10.6 | -2.42 | -0.32 | forward | - | picture | starboard scoop drum at the head's lower corner |
| D2 | listening dish, 1.6 across | 1 | 20.5 | -1.95 | 1.40 | 30 deg off the bow to starboard, +8 elev | - | picture | starboard ear, listening dish |
| J1 | boarding jaw, 3 segments, 3 fingers | 1 | 22.6 | 0.85 | -1.88 | hook forward and down | - | picture | port inner jaw, hinged in the mouth |
| J3 | boarding jaw, 3 segments, 2 fingers | 1 | 20.9 | 1.95 | -1.75 | hook forward and down | - | designed | port outer jaw under the scoop drum |
| J2 | boarding jaw, 3 segments, 3 fingers | 1 | 22.6 | -0.85 | -1.88 | hook forward and down | - | picture | starboard inner jaw, hinged in the mouth |
| J4 | boarding jaw, 3 segments, 2 fingers | 1 | 20.9 | -1.95 | -1.75 | hook forward and down | - | picture | starboard outer jaw under the scoop drum |
| PH0 | pipe run, 0.14 bore | 1 | 16.7 | 0.24 | -1.00 | - | - | picture |  |
| PH1 | pipe run, 0.14 bore | 1 | 16.7 | 0.00 | -1.00 | - | - | picture |  |
| PH2 | pipe run, 0.14 bore | 1 | 16.7 | -0.24 | -1.00 | - | - | picture |  |
| C1 | lashing chain, taut between lugs | 1 | 30.8 | 2.60 | -0.50 | to station 30.8%, offset -2.60 | - | picture | girdle over the neck seam, at the back of the head |
| C2 | lashing chain, taut between lugs | 1 | 61.2 | 2.72 | 0.30 | to station 61.2%, offset -2.77 | - | picture | girdle over the hump and crest |
| R1 | rocket rack, 2 by 3 cells | 6 tubes | 22.9 | 0.00 | 2.10 | forward, +8 elev | F torp | picture | rattle-rocket pod on the crown, firing over the jaws |
| T1 | twin turret | 2 barrels | 67.2 | 0.00 | 3.20 | forward, +8 elev | T flak | picture | crest twin, all round |
| T2 | twin belly turret | 2 barrels | 61.0 | 0.00 | -1.75 | forward, +8 elev | T flak | picture | belly twin, covers below |
| P1 | twin turret | 2 barrels | 38.0 | 1.60 | 1.72 | 35 deg off the bow to port | P scatter | picture | neck deck twin turret on a low barbette |
| P2 | twin turret | 2 barrels | 55.2 | 1.50 | 2.75 | 22 deg off the bow to port, +3 elev | P scatter | picture | hump-front twin turret, superfiring over the neck |
| P3 | twin casemate | 2 barrels | 70.3 | 2.21 | 2.05 | 35 deg off the bow to port | P scatter | picture | hump flank casemate |
| S1 | twin turret | 2 barrels | 38.0 | -1.60 | 1.72 | 35 deg off the bow to starboard | S scatter | picture | neck deck twin turret on a low barbette |
| S2 | twin turret | 2 barrels | 55.2 | -1.50 | 2.75 | 22 deg off the bow to starboard, +3 elev | S scatter | picture | hump-front twin turret, superfiring over the neck |
| S3 | twin casemate | 2 barrels | 70.3 | -2.26 | 2.05 | 35 deg off the bow to starboard | S scatter | picture | hump flank casemate |
| E1 | engine, bell 1.5 across | 1 | 99.9 | 1.15 | 0.00 | exhaust aft | - | picture | port main |
| E2 | engine, bell 1.2 across | 1 | 99.9 | 1.36 | 1.38 | exhaust aft | - | picture | port upper |
| E3 | engine, bell 1.0 across | 1 | 99.9 | 1.02 | -1.32 | exhaust aft | - | picture | port lower |
| E4 | engine, bell 1.4 across | 1 | 99.9 | -1.15 | 0.00 | exhaust aft | - | picture | starboard main |
| E5 | engine, bell 1.0 across | 1 | 99.9 | -1.36 | 1.38 | exhaust aft | - | designed | starboard upper |
| E6 | engine, bell 0.9 across | 1 | 99.9 | -1.02 | -1.32 | exhaust aft | - | designed | starboard lower |
| Q1 | attitude thruster quad | 1 | 27.0 | 2.45 | 0.95 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 27.0 | -2.45 | 0.95 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 84.4 | 2.22 | 0.75 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 84.4 | -2.27 | 0.75 | - | - | designed | stern |
| AN1 | antenna array, 1.5 tall, 3 whips | 1 | 81.6 | 0.70 | 2.53 | - | - | picture | aft hump antenna array, port |
| AN2 | antenna array, 1.2 tall, 2 whips | 1 | 81.3 | -0.75 | 2.57 | - | - | picture | aft hump antenna array, starboard (shorter) |
| VSp | louvre panel 0.7 x 0.5 | 1 | 77.9 | 2.47 | 0.30 | - | - | picture |  |
| L0p | running light | 1 | 31.9 | 2.47 | -0.98 | - | - | picture |  |
| L1p | running light | 1 | 41.8 | 2.48 | -0.98 | - | - | picture |  |
| L2p | running light | 1 | 54.2 | 2.56 | -0.98 | - | - | picture |  |
| L3p | running light | 1 | 69.3 | 2.51 | -0.98 | - | - | picture |  |
| L4p | running light | 1 | 80.3 | 2.38 | -0.98 | - | - | picture |  |
| LHp | running light | 1 | 65.2 | 2.21 | 1.65 | - | - | picture |  |
| VSs | louvre panel 0.7 x 0.5 | 1 | 77.9 | -2.52 | 0.30 | - | - | picture |  |
| L0s | running light | 1 | 31.9 | -2.47 | -0.98 | - | - | picture |  |
| L1s | running light | 1 | 41.8 | -2.52 | -0.98 | - | - | picture |  |
| L2s | running light | 1 | 54.2 | -2.61 | -0.98 | - | - | picture |  |
| L3s | running light | 1 | 69.3 | -2.56 | -0.98 | - | - | picture |  |
| L4s | running light | 1 | 80.3 | -2.43 | -0.98 | - | - | picture |  |
| LHs | running light | 1 | 65.2 | -2.26 | 1.65 | - | - | picture |  |
| HB1 | framed deck box 0.6 x 0.5 | 1 | 20.2 | 1.10 | 1.83 | - | - | picture | framed box on the brow, port |
| HB2 | framed deck box 0.5 x 0.5 | 1 | 19.8 | -1.15 | 1.83 | - | - | picture | framed box on the brow, starboard |
| HB3 | framed deck box 0.6 x 0.4 | 1 | 27.4 | -1.30 | 1.86 | - | - | picture | framed box on the brow, aft |
| HB4 | framed deck box 0.8 x 0.8 | 1 | 44.2 | 0.00 | 1.54 | - | - | picture | framed box on the neck deck |
| HB5 | framed deck box 0.5 x 0.4 | 1 | 77.2 | 1.45 | 2.85 | - | - | picture | framed box on the hump top, port |
| HB6 | framed deck box 0.6 x 0.4 | 1 | 77.2 | -1.45 | 2.85 | - | - | picture | framed box on the hump top |

Totals: 8 gun mounts with 16 barrels; 6 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 2 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| weathered grey and soot plate | 0.3 | 99.8 | whole hull |  |
| pale grey trophy plate (brow) | 16.7 | 30.5 | head roof |  |
| rust patch | 18.8 | 22.6 | brow, forward |  |
| dried-blood red stripes | 36.3 | 53.5 | both deck edges |  |
| dried-blood red patch | 61.0 | 69.3 | hump crest |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull (head, neck, body) | 14.7 to 89.9 | -2.60 to 2.55 | -1.75 to 1.60 | weathered grey and soot plate | chamfered head over a cut-in jaw mouth, pinched neck, lean body |
| Head roof, step 1 (brow) | 16.7 to 30.5 | -1.85 to 1.85 | 1.30 to 1.85 | pale grey trophy plate, rust patch | the first roof step, sloped at its front |
| Head roof, step 2 (crown) | 22.6 to 29.8 | -1.00 to 1.00 | 1.75 to 2.10 | soot | the second step, carries the rocket pod |
| Shoulder hump | 47.3 to 84.4 | -2.25 to 2.20 | 1.30 to 2.85 | soot with dried-blood patches | the shoulder hump |
| Hump crest | 58.3 to 77.9 | -1.20 to 1.20 | 2.70 to 3.20 | soot | stepped crest on the hump |
| Engine block | 87.1 to 91.3 | -1.90 to 1.90 | -1.45 to 1.60 | soot, steel |  |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.75 (21% to 87%); main deck 0.55 (19% to 87%); hump deck 1.90 (49% to 80%).

Bulkhead and frame stations: F0 19.8%, F1 32.9%, F2 48.7%, F3 67.9%, F4 82.3%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| jaw machinery (machinery) | 19.8 to 29.4 | -1.80 to 1.80 | -1.45 to -0.85 | jaw rams and winches over the mouth |
| boarding kennels (crew) | 18.5 to 30.1 | -1.90 to 1.90 | -0.65 to 0.45 | boarding gangs behind the jaws |
| ears and bridge (bridge) | 19.1 to 30.1 | -1.40 to 1.40 | 0.65 to 1.25 | listening room and bridge under the brow |
| rocket magazine (magazine) | 23.3 to 29.4 | -0.60 to 0.60 | 1.35 to 1.95 | under the rocket pod |
| loot hold (hold) | 34.3 to 48.0 | -2.00 to 2.00 | -1.45 to 0.45 | neck hold |
| crew decks (crew) | 49.4 to 67.2 | -2.10 to 2.10 | 0.65 to 1.80 |  |
| shell magazine (magazine) | 49.4 to 67.2 | -2.10 to 2.10 | -1.45 to 0.45 | battery magazines |
| flak magazine (magazine) | 61.7 to 73.4 | -0.80 to 0.80 | 2.00 to 2.65 | under the crest twin |
| core (core) | 69.3 to 81.0 | -1.20 to 1.20 | -1.45 to 0.45 | reactor core (hp_core) |
| engine room (engroom) | 83.0 to 87.1 | -1.80 to 1.80 | -1.20 to 1.40 | engine room and feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| head (forward of 4.4) | 0.45 | ram plate and face panels over the mouth |
| flanks | 0.25 | patch plates and the belt strake |
| hump roof and deck | 0.20 |  |
| belly | 0.25 | flat armoured belly with chines |
| engine end | 0.15 | thinnest |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 33.2 (seam wanders 31.2 to 34.9) | the neck seam under the C1 girdle: the head and jaws tear off, opening the kennels and the hold |
| B-2 | 82.7 (seam wanders 81.0 to 84.4) | hump and engine seam: the engine cluster tears away, opening the engine room |

Full interiors throughout the hull (R215), hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 74.8 | 0.00 | -0.50 |  |  |  |
| hp_breach_0 | 23.3 | 2.45 | 0.90 | port | prow |  |
| hp_breach_1 | 30.1 | -2.45 | -0.60 | stbd | prow |  |
| hp_breach_2 | 44.6 | 2.50 | 1.10 | port | mid |  |
| hp_breach_3 | 63.1 | -2.60 | 0.10 | stbd | mid |  |
| hp_breach_4 | 83.7 | 2.20 | 1.40 | port | eng |  |
| hp_rcs_0 | 27.0 | 2.45 | 0.95 | port |  |  |
| hp_rcs_1 | 27.0 | -2.45 | 0.95 | stbd |  |  |
| hp_board_0 | 53.5 | 2.60 | 0.20 | port |  |  |
| hp_board_1 | 53.5 | -2.65 | 0.20 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 312 objects, 59 parts, 762 close pairs, 503 rays, 8 guns, 6 turrets swept, 10 cones, 29 apertures. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The head is a chamfered block with two roof steps, a face overhanging a cut-in jaw mouth, framed face panels and straps.** Ryan R217: "the front is also just a flat block which does not match the concept".
- **Guns laid out as matched batteries by game slot.** the picture scatters guns on one edge and the far flank; scatter P and S are mirrored (a neck deck turret, a hump-front turret superfiring over it and a hump casemate per side), flak on the crest and the belly, the rocket pod on the crown.
- **Engine bells set level at the stern and spaced so no bell touches another.** the fit check found the round 2 cluster's bells inside each other and its exhausts washing the neighbours.
- **Lean hull, profile from the round 8 side view.** Ryan kept A17 lean (R213); the head sits low and heavy, the hump rises behind the neck.
- **Jaws are two matched pairs hinged in their own housings, hooks turned inboard.** the picture shows three loose arms; jaws that open sideways must close on something.
- **Scoops and ears made a matched pair (port scoop larger).** the picture shows a large port scoop and a small starboard one; kept mismatched in size, matched in place.
- **Forward rocket pod, belly flak turret and four attitude thrusters added.** data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters.
- **Chains are taut girdles of real links over the neck and the hump.** a slack chain cannot drape in space (R185); the girdles sit on the break lines.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Belly detail between the jaw housings and the engines is designed here; the picture does not show it.
- J3 (boarding jaw, 3 segments, 2 fingers): port outer jaw under the scoop drum.
- E5 (engine, bell 1.0 across): starboard upper.
- E6 (engine, bell 0.9 across): starboard lower.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
