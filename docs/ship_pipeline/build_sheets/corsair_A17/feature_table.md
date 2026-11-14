# corsair_A17: Hullbreaker wrecker (the Pack Hunter), build sheet

Ashfall Hullbreakers (corsair) | class Cruiser | version 3 (round 3), 2026-11-11 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532\r3b\corsair_A17\corsair_A17_blockout.blend`

**Length 14.6 world units** (data.js c_marauder (cls 'Cruiser'); class length godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5; this ship 14.6, claw tip to stern (Ryan, Nov 12: 'it's fine to extend the game length a bit'; R229 grabber arms at the concept sheet's share)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.577 |
| length side | 14.6 |
| length top | 14.6 |
| length disagreement percent | 0.0 |
| beam top | 7.612 |
| beam bow | 7.638 |
| beam disagreement percent | 0.17 |
| height side | 5.225 |
| height bow | 5.225 |
| height disagreement percent | 0.0 |
| widest at station percent | 59.0 |
| hull beam | 4.65 |
| hull depth | 3.12 |
| L to B hull | 3.14 |
| L to H hull | 4.68 |
| prow overhang | 1.06 |
| outline iou percent | 73.8 |
| mass outline iou percent | 75.5 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| SL1 | vision slit 0.6 x 0.12 | 1 | 46.9 | 0.65 | 1.02 | - | - | picture | slit in the ramp block slope |
| HS1 | square hatch 0.4 | 1 | 80.0 | 2.15 | 0.98 | - | - | picture | hatch on the aft block flank |
| SL2 | vision slit 0.6 x 0.12 | 1 | 46.9 | -0.75 | 1.02 | - | - | picture | slit in the ramp block slope |
| HS2 | square hatch 0.4 | 1 | 80.0 | -2.05 | 0.98 | - | - | picture | hatch on the aft block flank |
| I1 | scoop drum with a grille, 0.8 across, 2.1 deep | 1 | 6.6 | 1.88 | -0.42 | forward | - | picture | port scoop drum on the head flank, the larger |
| D1 | listening dish, 1.6 across | 1 | 17.6 | 2.40 | 0.30 | 40 deg off the bow to port, +8 elev | - | picture | port ear, a listening dish on the head's shoulder, turned forward and outward |
| I2 | scoop drum with a grille, 0.8 across, 2.1 deep | 1 | 6.6 | -1.88 | -0.42 | forward | - | picture | starboard scoop drum on the head flank |
| D2 | listening dish, 1.6 across | 1 | 17.6 | -2.40 | 0.30 | 40 deg off the bow to starboard, +8 elev | - | picture | starboard ear, a listening dish on the head's shoulder, turned forward and outward |
| J1 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 20.3 | 0.55 | -1.45 | hook forward and down | - | picture | port lower grabber arm: shoulder under the jaw, knuckle low and forward, pincer hooking up |
| J3 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 18.6 | 1.52 | -1.30 | hook forward and down | - | picture | port upper grabber arm: over and outboard of the lower, pincer hooking down |
| J2 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 20.3 | -0.55 | -1.45 | hook forward and down | - | picture | starboard lower grabber arm: shoulder under the jaw, knuckle low and forward, pincer hooking up |
| J4 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 18.6 | -1.52 | -1.30 | hook forward and down | - | picture | starboard upper grabber arm: over and outboard of the lower, pincer hooking down |
| PH0 | pipe run, 0.09 bore | 1 | 9.0 | 0.15 | -0.60 | - | - | picture |  |
| PH1 | pipe run, 0.09 bore | 1 | 9.0 | 0.00 | -0.60 | - | - | picture |  |
| PH2 | pipe run, 0.09 bore | 1 | 9.0 | -0.15 | -0.60 | - | - | picture |  |
| R1 | rocket rack, 2 by 3 cells | 6 tubes | 36.8 | 0.00 | 1.70 | forward, +10 elev | F torp | picture | rattle-rocket pod on the fore block, firing over the head |
| T1 | twin turret | 2 barrels | 81.7 | 0.00 | 2.07 | forward, +8 elev | T flak | picture | aft block twin on a barbette, all round, firing over the saddle antennas |
| T2 | twin belly turret | 2 barrels | 57.0 | 0.00 | -1.64 | forward, +8 elev | T flak | picture | belly twin, covers below |
| P1 | twin turret | 2 barrels | 27.9 | 1.30 | 1.92 | 40 deg off the bow to port | P scatter | picture | neck block twin turret on a low barbette |
| P2 | twin turret | 2 barrels | 59.8 | 1.90 | 1.30 | 35 deg off the bow to port, +3 elev | P scatter | picture | mid block twin turret, superfiring |
| P3 | twin casemate | 2 barrels | 65.2 | 2.58 | -0.25 | 35 deg off the bow to port | P scatter | picture | flank casemate on the flank tier |
| S1 | twin turret | 2 barrels | 27.9 | -1.30 | 1.92 | 40 deg off the bow to starboard | S scatter | picture | neck block twin turret on a low barbette |
| S2 | twin turret | 2 barrels | 59.8 | -1.70 | 1.30 | 35 deg off the bow to starboard, +3 elev | S scatter | picture | mid block twin turret, superfiring |
| S3 | twin casemate | 2 barrels | 65.2 | -2.63 | -0.25 | 35 deg off the bow to starboard | S scatter | picture | flank casemate on the flank tier |
| E1 | engine, bell 1.2 across | 1 | 99.9 | 0.72 | 0.55 | exhaust aft | - | picture | port inner main, a squat drum |
| E2 | engine, bell 1.0 across | 1 | 99.9 | 1.90 | 0.00 | exhaust aft | - | picture | port outer, a squat drum |
| E3 | engine, bell 0.9 across | 1 | 99.9 | 0.72 | -0.62 | exhaust aft | - | picture | port inner lower, a squat drum |
| E4 | engine, bell 1.1 across | 1 | 99.9 | -0.72 | 0.55 | exhaust aft | - | picture | starboard inner main, a squat drum |
| E5 | engine, bell 0.9 across | 1 | 99.9 | -1.90 | 0.00 | exhaust aft | - | designed | starboard outer, a squat drum |
| E6 | engine, bell 0.9 across | 1 | 99.9 | -0.72 | -0.62 | exhaust aft | - | designed | starboard inner lower, a squat drum |
| Q1 | attitude thruster quad | 1 | 24.4 | 2.16 | -0.05 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 24.4 | -2.21 | -0.05 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 84.1 | 2.18 | -0.30 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 84.1 | -2.23 | -0.30 | - | - | designed | stern |
| AN1 | antenna array, 0.8 tall, 3 whips | 1 | 68.3 | 0.55 | 1.40 | - | - | picture | antenna array on the saddle block, port |
| AN2 | antenna array, 0.6 tall, 2 whips | 1 | 69.4 | -0.60 | 1.40 | - | - | picture | antenna array on the saddle block, starboard (shorter) |
| VSp | louvre panel 0.5 x 0.5 | 1 | 84.5 | 2.15 | 0.92 | - | - | picture |  |
| L0p | running light | 1 | 27.5 | 2.20 | -0.88 | - | - | picture |  |
| L1p | running light | 1 | 37.5 | 2.25 | -0.88 | - | - | picture |  |
| L2p | running light | 1 | 48.8 | 2.32 | -0.88 | - | - | picture |  |
| L3p | running light | 1 | 61.1 | 2.32 | -0.88 | - | - | picture |  |
| L4p | running light | 1 | 73.5 | 2.32 | -0.88 | - | - | picture |  |
| LHp | running light | 1 | 73.5 | 2.15 | 1.18 | - | - | picture |  |
| VSs | louvre panel 0.5 x 0.5 | 1 | 84.5 | -2.05 | 0.92 | - | - | picture |  |
| L0s | running light | 1 | 27.5 | -2.25 | -0.88 | - | - | picture |  |
| L1s | running light | 1 | 37.5 | -2.31 | -0.88 | - | - | picture |  |
| L2s | running light | 1 | 48.8 | -2.37 | -0.88 | - | - | picture |  |
| L3s | running light | 1 | 61.1 | -2.37 | -0.88 | - | - | picture |  |
| L4s | running light | 1 | 73.5 | -2.37 | -0.88 | - | - | picture |  |
| LHs | running light | 1 | 73.5 | -2.05 | 1.18 | - | - | picture |  |
| HB1 | framed deck box 0.3 x 0.3 | 1 | 16.2 | 0.00 | 1.98 | - | - | picture | framed box on the crown |
| HB2 | framed deck box 0.2 x 0.2 | 1 | 12.1 | 0.85 | 1.76 | - | - | picture | framed box on the brow, port |
| HB3 | framed deck box 0.2 x 0.2 | 1 | 12.1 | -0.85 | 1.76 | - | - | picture | framed box on the brow, starboard |
| HB4 | framed deck box 0.6 x 0.6 | 1 | 47.7 | 0.00 | 1.20 | - | - | picture | framed box on the ramp block |
| HB5 | framed deck box 0.5 x 0.4 | 1 | 61.1 | 0.35 | 1.30 | - | - | picture | framed box on the mid block |
| HB6 | framed deck box 0.4 x 0.3 | 1 | 86.5 | 1.10 | 1.52 | - | - | picture | framed box on the aft block |

Totals: 8 gun mounts with 16 barrels; 6 launcher tubes; 6 engines; 2 intakes; 2 dishes; 4 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| weathered grey and soot plate | 0.4 | 99.9 | whole hull |  |
| pale grey trophy plate (brow) | 8.6 | 19.6 | head roof |  |
| rust patch | 13.8 | 16.2 | brow, port |  |
| dried-blood red plates | 34.4 | 43.6 | fore block roof |  |
| dried-blood red patch | 74.8 | 83.8 | aft block roof |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Base hull (head and flank tier) | 7.3 to 87.5 | -2.35 to 2.30 | -1.60 to 1.52 | weathered grey and soot plate | narrow head over a cut-in jaw mouth, then the long low body |
| Lower hull band | 23.4 to 85.8 | -2.05 to 2.00 | -1.64 to -1.00 | dark soot | the belly steps in under the flank tier |
| Head brow (step 1) | 10.9 to 19.6 | -1.38 to 1.38 | 1.40 to 1.80 | pale grey trophy plate | the first roof step, sloped at its front |
| Head crown (step 2) | 13.4 to 18.9 | -0.82 to 0.82 | 1.72 to 1.98 | soot | the second step |
| Flank block 1 port | 27.2 to 32.7 | 1.79 to 2.46 | -0.72 to 0.20 | patched plate | armour block on the flank tier |
| Flank block 2 port | 34.0 to 43.6 | 1.84 to 2.42 | -0.72 to 0.27 | patched plate | armour block on the flank tier |
| Flank block 3 port | 45.0 to 58.4 | 1.90 to 2.48 | -0.72 to 0.21 | patched plate | armour block on the flank tier |
| Flank block 4 port | 59.8 to 70.4 | 1.90 to 2.58 | -0.72 to 0.30 | patched plate | armour block on the flank tier |
| Flank block 5 port | 71.8 to 81.0 | 1.90 to 2.58 | -0.72 to 0.30 | patched plate | armour block on the flank tier |
| Flank block 1 starboard | 27.2 to 32.7 | -2.53 to -1.84 | -0.72 to 0.26 | patched plate | armour block on the flank tier |
| Flank block 2 starboard | 35.4 to 44.5 | -2.46 to -1.89 | -0.72 to 0.26 | patched plate | armour block on the flank tier |
| Flank block 3 starboard | 46.4 to 59.2 | -2.62 to -1.95 | -0.72 to 0.36 | patched plate | armour block on the flank tier |
| Flank block 4 starboard | 59.8 to 70.4 | -2.63 to -1.95 | -0.72 to 0.30 | patched plate | armour block on the flank tier |
| Flank block 5 starboard | 71.8 to 81.0 | -2.59 to -1.95 | -0.72 to 0.27 | patched plate | armour block on the flank tier |
| U1 neck block | 22.7 to 33.0 | -1.50 to 1.50 | 0.40 to 1.12 | soot with dried-blood patches | stepped top block, top 1.12, undercut base |
| U2 fore block | 34.0 to 44.3 | -1.77 to 1.93 | 0.40 to 0.90 | soot with dried-blood patches | stepped top block, top 0.90, undercut base |
| U3 ramp block | 45.0 to 51.2 | -1.85 to 1.75 | 0.40 to 1.20 | soot with dried-blood patches | stepped top block, top 1.20, undercut base |
| U4 mid block | 52.1 to 62.8 | -1.93 to 2.13 | 0.40 to 1.30 | soot with dried-blood patches | stepped top block, top 1.30, undercut base |
| U5 saddle block | 63.7 to 71.1 | -1.82 to 1.58 | 0.40 to 1.40 | soot with dried-blood patches | stepped top block, top 1.40, undercut base |
| U6 aft block | 72.0 to 88.2 | -2.05 to 2.15 | 0.40 to 1.52 | soot with dried-blood patches | stepped top block, top 1.52, undercut base |
| Engine block | 87.2 to 91.3 | -2.00 to 2.00 | -1.35 to 1.35 | soot, steel |  |
| Ear bracket port | 14.8 to 20.3 | 1.50 to 2.75 | 0.06 to 0.30 | iron | bracket out from the head's shoulder |
| Ear bracket starboard | 14.8 to 20.3 | -2.75 to -1.50 | 0.06 to 0.30 | iron | bracket out from the head's shoulder |
| Rack plinth | 35.7 to 43.6 | -0.72 to 0.72 | 0.80 to 1.70 | iron | lifts the rocket pod clear over the neck turrets |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.82 (36% to 87%); lower_fore deck -0.82 (23% to 31%); top deck 0.30 (36% to 87%); head deck 0.00 (10% to 20%).

Bulkhead and frame stations: F0 13.1%, F1 22.7%, F2 36.1%, F3 44.7%, F4 63.2%, F5 82.4%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| jaw machinery (machinery) | 11.7 to 19.6 | -0.75 to 0.75 | -0.60 to -0.10 | grabber arm rams and winches over the mouth |
| listening bridge (bridge) | 11.0 to 19.3 | -0.70 to 0.70 | 0.05 to 0.55 | listening room and bridge in the head |
| boarding kennels (crew) | 23.4 to 30.6 | -1.60 to 1.60 | -1.45 to -0.88 | boarding gangs behind the grabbers |
| loot hold (hold) | 36.1 to 44.3 | -1.70 to 1.70 | -1.45 to -0.88 | neck hold |
| rocket magazine (magazine) | 36.4 to 42.9 | -0.60 to 0.60 | 0.34 to 0.70 | under the rocket pod, in the fore block |
| crew decks (crew) | 53.9 to 61.5 | -1.30 to 1.50 | 0.34 to 1.05 | in the mid block |
| shell magazine (magazine) | 44.7 to 63.2 | -1.70 to 1.70 | -1.45 to -0.88 | battery magazines |
| flak magazine (magazine) | 74.8 to 85.8 | -0.80 to 0.80 | 0.34 to 1.25 | under the aft block twin |
| core (core) | 68.0 to 81.0 | -1.10 to 1.10 | -1.45 to 0.30 | reactor core (hp_core) |
| engine room (engroom) | 82.7 to 87.2 | -1.60 to 1.60 | -1.20 to 0.35 | engine room and feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| head (forward of 4.4) | 0.40 | ram plate and face panels over the mouth |
| flank blocks | 0.30 | armour blocks over the flank tier |
| top blocks | 0.20 |  |
| belly | 0.25 | flat armoured belly, the band stepping in |
| engine end | 0.15 | thinnest |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 33.3 (seam wanders 31.6 to 35.1) | the neck seam behind the neck turrets: the head and grabbers tear off, opening the kennels and the hold |
| B-2 | 73.1 (seam wanders 71.8 to 75.5) | the weld between the saddle and aft blocks: the aft block, its flak twin and the engine cluster tear away, biting through the core and opening the engine room |

Full interiors throughout the hull (R215), hidden until a piece breaks. Deaths blow the hull apart unevenly along these seams with a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 74.8 | 0.00 | -0.60 |  |  |  |
| hp_breach_0 | 25.5 | 1.95 | -0.20 | port | prow |  |
| hp_breach_1 | 29.6 | -1.95 | -0.40 | stbd | prow |  |
| hp_breach_2 | 44.7 | 2.00 | 0.10 | port | mid |  |
| hp_breach_3 | 63.2 | -2.05 | -0.30 | stbd | mid |  |
| hp_breach_4 | 83.8 | 1.85 | 0.20 | port | eng |  |
| hp_rcs_0 | 24.4 | 2.16 | -0.05 | port |  |  |
| hp_rcs_1 | 24.4 | -2.21 | -0.05 | stbd |  |  |
| hp_board_0 | 53.6 | 2.05 | -0.30 | port |  |  |
| hp_board_1 | 53.6 | -2.10 | -0.30 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 371 objects, 56 parts, 932 close pairs, 501 rays, 8 guns, 96 sensor pairs, 6 turrets swept, 10 cones, 28 apertures, 2 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Long and low, to the concept's measured proportions.** the Board on round 3: the build was short, tall and round; the hull is now length to beam 2.75 and length to height about 4 like the round 8 sheet, at the data.js length.
- **The body is stacked angular blocks: a base hull, flank blocks, six top blocks stepping up toward the stern with gaps and undercuts.** the concept's dense stack of armoured blocks; round 3 was one smooth body with plates stuck on.
- **The head is narrow, chamfered and stepped, a face overhanging a cut-in jaw mouth, the scoop drums on its flanks.** Ryan R217: "the front is also just a flat block".
- **The jaws are four articulated grabber arms (two segments, knuckles, rams, forked pincers), a pair a side closing toward each other.** Ryan, R229: the round 3b flat prongs came from a bow crop that cut the grabbers off; the whole beauty and the sheet's side view show jointed arms (new kit part claw_arm).
- **Guns laid out as matched batteries by game slot.** the picture scatters guns; scatter P and S are mirrored (a neck block turret, a mid block turret superfiring, a flank casemate per side), flak on the aft block and the belly, the rocket pod on the fore block.
- **Engines are squat drums in two columns a side, exits level, no bell touching another.** the concept's stacked cluster; the fit check found round 2's bells inside each other.
- **The head follows the beauty: a big, tall, boxy front block over the neck, ear dishes on its shoulders (R229 sizes them).** the Board on round 3b: Ryan judges against the accepted picture, which draws the head larger than the round 8 sheet.
- **Forward rocket pod, belly flak turret and four attitude thrusters added.** data.js gives a forward rocket slot (torp F); the belly needs cover; a ship in space needs thrusters.
- **Chains cut.** Ryan, R221: "let's get rid of the chains randomly around the ship. There's no purpose"; every part has a job (ships.md 2c).
- **Neck and mid turrets moved outboard.** R221: no gun in the rocket pod's firing lane or backblast (the fit check tests both).
- **Crystal shard removed.** Ryan, R197.
- **The face is a narrower panel inside a deep bevel frame (corner and brow planes plated), with a lower lip over the mouth.** Ryan R217 on A17: "the front is also just a flat block which does not match the concept"; the beauty's head is chamfered all round, not a flat end (A17 build, issue 532).
- **Ear dishes 1.6 across (were 1.9), lower on the head's shoulders, turned forward and outward, rusted grey.** the Board on PR 611 (R207, R229): measured on the whole beauty, each ear is about three quarters of the head's flank height across and sits at the rear of the head's shoulder; not a white disc high on the top corner (A17 build, issue 532).
- **Grabber arms splayed: the lower pair forward and down, the upper pair forward and outward.** the Board on PR 611 (R229): the arms read tucked under; their reach ahead of the face is the concept sheet's share (side view: 6.8 percent of the whole length, here 7.3), so the hull is not shortened (A17 build, issue 532).
- **Ship length 14.6 (class 14.5), claw tip to stern.** Ryan, Nov 12: "it's fine to extend the game length a bit"; the grabber arms take the concept sheet's share ahead of the face (6.8 percent in its side view, 7.3 here) and the hull body is unchanged; +0.7 percent (A17 build, issue 532).
- **Neck block raised from 0.78 to 1.12.** in the beauty the deck behind the head steps down only a little; at 0.78 the head stood on the neck like a separate box (A17 build, issue 532).
- **Aft seam B-2 moved forward to the weld between the saddle and aft blocks, kinked round the antennas, T1 and the stern thrusters.** R226 (RULEBOOK 5.17): a machine never crosses a seam; at -4.75 the seam cut T1, Q3 and Q4 (A17 build, issue 532).
- **Mid turrets P2 and S2 rest at 35 degrees (were 25).** their data.js arc is 30 to 150; a rest outside it failed the export check (A17 build, issue 532).
- **Rooms in the top blocks kept under their roofs; the top deck lowered to 0.3.** about 70 inside triangles sat outside the intact plating, above the low top blocks and in the gaps between them (issue 532 note from PR 608).

## Designed here, not shown in the picture

- Belly detail between the grabber arm housings and the engines is designed here; the picture does not show the underside.
- E5 (engine, bell 0.9 across): starboard outer, a squat drum.
- E6 (engine, bell 0.9 across): starboard inner lower, a squat drum.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
