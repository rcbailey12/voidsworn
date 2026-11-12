# corsair_A17: Hullbreaker wrecker (the Pack Hunter), build sheet

Ashfall Hullbreakers (corsair) | class Cruiser | version 3 (round 3), 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3b\corsair_A17\corsair_A17_blockout.blend`

**Length 14.5 world units** (data.js c_marauder (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.49 |
| length side | 14.512 |
| length top | 14.512 |
| length disagreement percent | 0.0 |
| beam top | 7.612 |
| beam bow | 7.638 |
| beam disagreement percent | 0.17 |
| height side | 5.062 |
| height bow | 5.062 |
| height disagreement percent | 0.0 |
| widest at station percent | 58.8 |
| hull beam | 4.65 |
| hull depth | 2.62 |
| L to B hull | 3.12 |
| L to H hull | 5.53 |
| prow overhang | 1.02 |
| outline iou percent | 72.9 |
| mass outline iou percent | 72.7 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| SL1 | vision slit 0.6 x 0.12 | 1 | 46.6 | 0.65 | 1.02 | - | - | picture | slit in the ramp block slope |
| HS1 | square hatch 0.4 | 1 | 79.9 | 2.15 | 0.98 | - | - | picture | hatch on the aft block flank |
| SL2 | vision slit 0.6 x 0.12 | 1 | 46.6 | -0.75 | 1.02 | - | - | picture | slit in the ramp block slope |
| HS2 | square hatch 0.4 | 1 | 79.9 | -2.05 | 0.98 | - | - | picture | hatch on the aft block flank |
| I1 | scoop drum with a grille, 0.8 across, 2.1 deep | 1 | 6.0 | 1.72 | -0.42 | forward | - | picture | port scoop drum on the head flank, the larger |
| D1 | listening dish, 1.1 across | 1 | 16.4 | 1.84 | 0.03 | 35 deg off the bow to port, +8 elev | - | picture | port ear, listening dish bolted to the top of its scoop drum |
| I2 | scoop drum with a grille, 0.7 across, 2.1 deep | 1 | 6.0 | -1.72 | -0.42 | forward | - | picture | starboard scoop drum on the head flank |
| D2 | listening dish, 1.1 across | 1 | 16.4 | -1.84 | -0.02 | 35 deg off the bow to starboard, +8 elev | - | picture | starboard ear, listening dish bolted to the top of its scoop drum |
| J1 | jaw prong, 2.6 long, hooked tip | 1 | 19.5 | 0.82 | -1.32 | hook forward and down | - | picture | port lower prong, a long flat blade with a hooked tip |
| J3 | jaw prong, 2.3 long, hooked tip | 1 | 18.5 | 1.14 | -1.00 | hook forward and down | - | picture | port upper prong, over and outboard of the lower |
| J2 | jaw prong, 2.6 long, hooked tip | 1 | 19.5 | -0.82 | -1.32 | hook forward and down | - | picture | starboard lower prong, a long flat blade with a hooked tip |
| J4 | jaw prong, 2.3 long, hooked tip | 1 | 18.5 | -1.14 | -1.00 | hook forward and down | - | picture | starboard upper prong, over and outboard of the lower |
| PH0 | pipe run, 0.12 bore | 1 | 8.4 | 0.30 | -0.60 | - | - | picture |  |
| PH1 | pipe run, 0.12 bore | 1 | 8.4 | 0.00 | -0.60 | - | - | picture |  |
| PH2 | pipe run, 0.12 bore | 1 | 8.4 | -0.30 | -0.60 | - | - | picture |  |
| C1 | lashing chain, taut between lugs | 1 | 32.9 | 2.55 | -0.40 | to station 32.9%, offset -2.60 | - | picture | girdle at the neck, between the neck block and the fore block |
| C2 | lashing chain, taut between lugs | 1 | 63.1 | 2.10 | 0.47 | to station 63.1%, offset -2.10 | - | picture | girdle in the gap between the mid and saddle blocks |
| R1 | rocket rack, 2 by 3 cells | 6 tubes | 36.4 | 0.00 | 1.32 | forward, +8 elev | F torp | picture | rattle-rocket pod on the fore block, firing over the head |
| T1 | twin turret | 2 barrels | 81.6 | 0.00 | 1.52 | forward, +8 elev | T flak | picture | aft block twin, all round |
| T2 | twin belly turret | 2 barrels | 56.8 | 0.00 | -1.64 | forward, +8 elev | T flak | picture | belly twin, covers below |
| P1 | twin turret | 2 barrels | 27.4 | 0.60 | 1.18 | 40 deg off the bow to port | P scatter | picture | neck block twin turret on a low barbette |
| P2 | twin turret | 2 barrels | 56.8 | 1.50 | 1.30 | 25 deg off the bow to port, +3 elev | P scatter | picture | mid block twin turret, superfiring |
| P3 | twin casemate | 2 barrels | 65.0 | 2.58 | -0.25 | 35 deg off the bow to port | P scatter | picture | flank casemate on the flank tier |
| S1 | twin turret | 2 barrels | 27.4 | -0.60 | 1.18 | 40 deg off the bow to starboard | S scatter | picture | neck block twin turret on a low barbette |
| S2 | twin turret | 2 barrels | 56.8 | -1.30 | 1.30 | 25 deg off the bow to starboard, +3 elev | S scatter | picture | mid block twin turret, superfiring |
| S3 | twin casemate | 2 barrels | 65.0 | -2.63 | -0.25 | 35 deg off the bow to starboard | S scatter | picture | flank casemate on the flank tier |
| E1 | engine, bell 1.2 across | 1 | 99.9 | 0.72 | 0.55 | exhaust aft | - | picture | port inner main, a squat drum |
| E2 | engine, bell 1.0 across | 1 | 99.9 | 1.90 | 0.00 | exhaust aft | - | picture | port outer, a squat drum |
| E3 | engine, bell 0.9 across | 1 | 99.9 | 0.72 | -0.62 | exhaust aft | - | picture | port inner lower, a squat drum |
| E4 | engine, bell 1.1 across | 1 | 99.9 | -0.72 | 0.55 | exhaust aft | - | picture | starboard inner main, a squat drum |
| E5 | engine, bell 0.9 across | 1 | 99.9 | -1.90 | 0.00 | exhaust aft | - | designed | starboard outer, a squat drum |
| E6 | engine, bell 0.9 across | 1 | 99.9 | -0.72 | -0.62 | exhaust aft | - | designed | starboard inner lower, a squat drum |
| Q1 | attitude thruster quad | 1 | 24.0 | 2.16 | -0.05 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 24.0 | -2.21 | -0.05 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 84.0 | 2.18 | -0.30 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 84.0 | -2.23 | -0.30 | - | - | designed | stern |
| AN1 | antenna array, 1.3 tall, 3 whips | 1 | 68.1 | 0.55 | 1.40 | - | - | picture | antenna array on the saddle block, port |
| AN2 | antenna array, 1.0 tall, 2 whips | 1 | 69.2 | -0.60 | 1.40 | - | - | picture | antenna array on the saddle block, starboard (shorter) |
| VSp | louvre panel 0.5 x 0.5 | 1 | 84.4 | 2.15 | 0.92 | - | - | picture |  |
| L0p | running light | 1 | 27.1 | 2.20 | -0.88 | - | - | picture |  |
| L1p | running light | 1 | 37.1 | 2.25 | -0.88 | - | - | picture |  |
| L2p | running light | 1 | 48.5 | 2.32 | -0.88 | - | - | picture |  |
| L3p | running light | 1 | 60.9 | 2.32 | -0.88 | - | - | picture |  |
| L4p | running light | 1 | 73.3 | 2.32 | -0.88 | - | - | picture |  |
| LHp | running light | 1 | 73.3 | 2.15 | 1.18 | - | - | picture |  |
| VSs | louvre panel 0.5 x 0.5 | 1 | 84.4 | -2.05 | 0.92 | - | - | picture |  |
| L0s | running light | 1 | 27.1 | -2.25 | -0.88 | - | - | picture |  |
| L1s | running light | 1 | 37.1 | -2.31 | -0.88 | - | - | picture |  |
| L2s | running light | 1 | 48.5 | -2.37 | -0.88 | - | - | picture |  |
| L3s | running light | 1 | 60.9 | -2.37 | -0.88 | - | - | picture |  |
| L4s | running light | 1 | 73.3 | -2.37 | -0.88 | - | - | picture |  |
| LHs | running light | 1 | 73.3 | -2.05 | 1.18 | - | - | picture |  |
| HB1 | framed deck box 0.3 x 0.3 | 1 | 15.7 | 0.00 | 1.48 | - | - | picture | framed box on the crown |
| HB2 | framed deck box 0.2 x 0.2 | 1 | 11.5 | 0.70 | 1.26 | - | - | picture | framed box on the brow, port |
| HB3 | framed deck box 0.2 x 0.2 | 1 | 11.5 | -0.70 | 1.26 | - | - | picture | framed box on the brow, starboard |
| HB4 | framed deck box 0.6 x 0.6 | 1 | 47.4 | 0.00 | 1.20 | - | - | picture | framed box on the ramp block |
| HB5 | framed deck box 0.5 x 0.4 | 1 | 60.9 | 0.35 | 1.30 | - | - | picture | framed box on the mid block |
| HB6 | framed deck box 0.4 x 0.3 | 1 | 86.4 | 1.10 | 1.52 | - | - | picture | framed box on the aft block |

Totals: 8 gun mounts with 16 barrels; 6 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 2 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| weathered grey and soot plate | 0.0 | 99.9 | whole hull |  |
| pale grey trophy plate (brow) | 8.1 | 19.1 | head roof |  |
| rust patch | 12.2 | 15.3 | brow, forward |  |
| dried-blood red plates | 34.0 | 43.3 | fore block roof |  |
| dried-blood red patch | 74.7 | 83.7 | aft block roof |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Base hull (head and flank tier) | 7.1 to 87.5 | -2.35 to 2.30 | -1.60 to 1.02 | weathered grey and soot plate | narrow head over a cut-in jaw mouth, then the long low body |
| Lower hull band | 22.9 to 85.7 | -2.05 to 2.00 | -1.64 to -1.00 | dark soot | the belly steps in under the flank tier |
| Head brow (step 1) | 8.1 to 19.1 | -1.20 to 1.20 | 0.85 to 1.30 | pale grey trophy plate | the first roof step, sloped at its front |
| Head crown (step 2) | 12.9 to 18.5 | -0.78 to 0.78 | 1.20 to 1.48 | soot | the second step |
| Flank block 1 port | 26.7 to 32.3 | 1.79 to 2.46 | -0.72 to 0.20 | patched plate | armour block on the flank tier |
| Flank block 2 port | 33.6 to 43.3 | 1.84 to 2.42 | -0.72 to 0.27 | patched plate | armour block on the flank tier |
| Flank block 3 port | 44.7 to 58.1 | 1.90 to 2.48 | -0.72 to 0.21 | patched plate | armour block on the flank tier |
| Flank block 4 port | 59.5 to 70.2 | 1.90 to 2.58 | -0.72 to 0.30 | patched plate | armour block on the flank tier |
| Flank block 5 port | 71.6 to 80.9 | 1.90 to 2.58 | -0.72 to 0.30 | patched plate | armour block on the flank tier |
| Flank block 1 starboard | 26.7 to 32.3 | -2.53 to -1.84 | -0.72 to 0.26 | patched plate | armour block on the flank tier |
| Flank block 2 starboard | 35.0 to 44.1 | -2.46 to -1.89 | -0.72 to 0.26 | patched plate | armour block on the flank tier |
| Flank block 3 starboard | 46.1 to 59.0 | -2.62 to -1.95 | -0.72 to 0.36 | patched plate | armour block on the flank tier |
| Flank block 4 starboard | 59.5 to 70.2 | -2.63 to -1.95 | -0.72 to 0.30 | patched plate | armour block on the flank tier |
| Flank block 5 starboard | 71.6 to 80.9 | -2.59 to -1.95 | -0.72 to 0.27 | patched plate | armour block on the flank tier |
| U1 neck block | 22.2 to 32.6 | -1.50 to 1.50 | 0.40 to 0.78 | soot with dried-blood patches | stepped top block, top 0.78, undercut base |
| U2 fore block | 33.6 to 44.0 | -1.77 to 1.93 | 0.40 to 0.90 | soot with dried-blood patches | stepped top block, top 0.90, undercut base |
| U3 ramp block | 44.7 to 50.9 | -1.85 to 1.75 | 0.40 to 1.20 | soot with dried-blood patches | stepped top block, top 1.20, undercut base |
| U4 mid block | 51.8 to 62.6 | -1.93 to 2.13 | 0.40 to 1.30 | soot with dried-blood patches | stepped top block, top 1.30, undercut base |
| U5 saddle block | 63.5 to 70.9 | -1.82 to 1.58 | 0.40 to 1.40 | soot with dried-blood patches | stepped top block, top 1.40, undercut base |
| U6 aft block | 71.8 to 88.2 | -2.05 to 2.15 | 0.40 to 1.52 | soot with dried-blood patches | stepped top block, top 1.52, undercut base |
| Engine block | 87.1 to 91.3 | -2.00 to 2.00 | -1.35 to 1.35 | soot, steel |  |
| Rack plinth | 35.4 to 43.3 | -0.72 to 0.72 | 0.80 to 1.32 | iron | lifts the rocket pod clear over the neck turrets |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.82 (22% to 87%); top deck 0.90 (34% to 86%); head deck 0.00 (9% to 19%).

Bulkhead and frame stations: F0 12.6%, F1 22.2%, F2 33.3%, F3 44.3%, F4 63.0%, F5 82.3%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| jaw machinery (machinery) | 11.2 to 19.1 | -0.75 to 0.75 | -0.60 to -0.10 | prong rams and winches over the mouth |
| listening bridge (bridge) | 10.5 to 18.8 | -0.70 to 0.70 | 0.05 to 0.55 | listening room and bridge in the head |
| boarding kennels (crew) | 22.9 to 32.6 | -1.60 to 1.60 | -1.45 to -0.88 | boarding gangs behind the prongs |
| loot hold (hold) | 33.3 to 44.0 | -1.70 to 1.70 | -1.45 to -0.88 | neck hold |
| rocket magazine (magazine) | 34.0 to 43.3 | -0.60 to 0.60 | 0.50 to 1.10 | under the rocket pod |
| crew decks (crew) | 44.3 to 63.0 | -1.30 to 1.30 | 0.50 to 1.40 | in the ramp and mid blocks |
| shell magazine (magazine) | 44.3 to 63.0 | -1.70 to 1.70 | -1.45 to -0.88 | battery magazines |
| flak magazine (magazine) | 73.3 to 85.7 | -0.80 to 0.80 | 0.50 to 1.60 | under the aft block twin |
| core (core) | 67.8 to 80.9 | -1.10 to 1.10 | -1.45 to 0.30 | reactor core (hp_core) |
| engine room (engroom) | 82.6 to 87.1 | -1.60 to 1.60 | -1.20 to 0.35 | engine room and feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| head (forward of 4.4) | 0.40 | ram plate and face panels over the mouth |
| flank blocks | 0.30 | armour blocks over the flank tier |
| top blocks | 0.20 |  |
| belly | 0.25 | flat armoured belly, the band stepping in |
| engine end | 0.15 | thinnest |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 32.9 (seam wanders 31.2 to 34.7) | the neck seam under the C1 girdle: the head and prongs tear off, opening the kennels and the hold |
| B-2 | 82.6 (seam wanders 80.9 to 84.4) | aft block and engine seam: the engine cluster tears away, opening the engine room |

Full interiors throughout the hull (R215), hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 74.7 | 0.00 | -0.60 |  |  |  |
| hp_breach_0 | 25.0 | 1.95 | -0.20 | port | prow |  |
| hp_breach_1 | 29.1 | -1.95 | -0.40 | stbd | prow |  |
| hp_breach_2 | 44.3 | 2.00 | 0.10 | port | mid |  |
| hp_breach_3 | 63.0 | -2.05 | -0.30 | stbd | mid |  |
| hp_breach_4 | 83.7 | 1.85 | 0.20 | port | eng |  |
| hp_rcs_0 | 24.0 | 2.16 | -0.05 | port |  |  |
| hp_rcs_1 | 24.0 | -2.21 | -0.05 | stbd |  |  |
| hp_board_0 | 53.3 | 2.05 | -0.30 | port |  |  |
| hp_board_1 | 53.3 | -2.10 | -0.30 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 361 objects, 58 parts, 819 close pairs, 502 rays, 8 guns, 6 turrets swept, 10 cones, 28 apertures. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Long and low, to the concept's measured proportions.** the Board on round 3: the build was short, tall and round; the hull is now length to beam 2.75 and length to height about 4 like the round 8 sheet, at the data.js length.
- **The body is stacked angular blocks: a base hull, flank blocks, six top blocks stepping up toward the stern with gaps and undercuts.** the concept's dense stack of armoured blocks; round 3 was one smooth body with plates stuck on.
- **The head is narrow, chamfered and stepped, a face overhanging a cut-in jaw mouth, the scoop drums on its flanks.** Ryan R217: "the front is also just a flat block".
- **The jaws are four long flat prongs with hooked tips, reaching forward from the lower bow like a fork.** the concept's prongs; round 3's read as hands with fingers.
- **Guns laid out as matched batteries by game slot.** the picture scatters guns; scatter P and S are mirrored (a neck block turret, a mid block turret superfiring, a flank casemate per side), flak on the aft block and the belly, the rocket pod on the fore block.
- **Engines are squat drums in two columns a side, exits level, no bell touching another.** the concept's stacked cluster; the fit check found round 2's bells inside each other.
- **Ear dishes bolted to the tops of the scoop drums.** as the concept shows them.
- **Forward rocket pod, belly flak turret and four attitude thrusters added.** data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters.
- **Chains are taut girdles of real links in the gaps between blocks.** a slack chain cannot drape in space (R185); the girdles sit on the break lines.
- **Crystal shard removed.** Ryan, R197.

## Designed here, not shown in the picture

- Belly detail between the prong housings and the engines is designed here; the picture does not show the underside.
- E5 (engine, bell 0.9 across): starboard outer, a squat drum.
- E6 (engine, bell 0.9 across): starboard inner lower, a squat drum.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
