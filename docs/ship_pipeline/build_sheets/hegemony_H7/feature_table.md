# hegemony_H7: Picket frigate (Meridian Directorate Navy escort), build sheet

Meridian Directorate (hegemony) | class Frigate | version 2 (merged build (R442)), 2026-11-23 | blockout: rendered in the issue 1412 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_H7 <out> render` rebuilds it from this file

**Length 6.5 world units** (data.js h_picket (cls 'Frigate', 'Directorate picket'; the Godot rules table godot/rules/data/tables.json carries it); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5; game folder H7_23 (AI_HULLS hegemony|Frigate)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | laser | F | 2 | bow (2) |
| 1 | flak | T | 3 | dorsal (3) |

| Check | Value |
|---|---|
| model length | 6.524 |
| length side | 6.55 |
| length top | 6.55 |
| length disagreement percent | 0.0 |
| beam top | 2.425 |
| beam bow | 2.425 |
| beam disagreement percent | 0.0 |
| height side | 1.175 |
| height bow | 1.175 |
| height disagreement percent | 0.0 |
| widest at station percent | 49.3 |
| hull beam | 2.3 |
| hull depth | 0.71 |
| L to B hull | 2.83 |
| L to H hull | 9.15 |
| outline iou percent | 92.8 |
| mass outline iou percent | 93.1 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| bow | plasma cannon, twin casemate in the bow face (fixed) | 2 barrels | 4.8 | 0.00 | -0.04 | forward | F laser | picture | the Plasma cannon (laser F, 2 shots): two short bores in a lined recess in the blunt bow face |
| dorsal | picket lasers, triple turret | 3 barrels | 62.3 | 0.00 | 0.46 | forward, +5 elev | T flak | picture | the Picket lasers (flak T, 3 shots over 3 emitters) on the raised dorsal barbette |
| receiver | low swept sensor | 1 | 33.0 | 0.00 | 0.33 | - | - | picture | the one low sensor receiver, ahead of the barbette |
| drive0 | engine, rectangular nozzle 0.50 x 0.49 | 1 | 99.7 | -0.48 | -0.00 | exhaust aft | - | picture | rectangular nozzle pod seated in the stern |
| intake0 | louvre panel 0.3 x 0.5 | 1 | 85.9 | -0.48 | 0.37 | - | - | picture | drive feed louvre |
| transfer0 | square hatch 0.2 | 1 | 49.6 | -1.15 | -0.04 | - | - | picture | boarding door: the waist light breaks round it |
| cooler0_0 | louvre panel 0.2 x 0.3 | 1 | 83.9 | -0.53 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler0_1 | louvre panel 0.2 x 0.3 | 1 | 67.8 | -0.56 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler0_2 | louvre panel 0.2 x 0.3 | 1 | 49.6 | -0.56 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler0_3 | louvre panel 0.2 x 0.3 | 1 | 33.0 | -0.52 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler0_4 | louvre panel 0.2 x 0.3 | 1 | 17.4 | -0.40 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| Q1s | retro thruster, two rectangular nozzles | 1 | 0.5 | -0.40 | -0.04 | - | - | designed | retro thruster on the bow face beside the casemate (lore 3.4; the evasive burn) |
| Q2s | attitude thruster, two rectangular nozzles | 1 | 14.6 | -0.70 | 0.13 | - | - | designed | attitude thruster on the upper facet |
| Q3s | attitude thruster, two rectangular nozzles | 1 | 89.7 | -0.90 | 0.19 | - | - | designed | attitude thruster on the upper facet |
| D1s | flush drone doors 0.4 x 0.14 | 1 | 68.3 | -1.07 | 0.22 | - | - | picture | the faction's small drone bay: flush armoured doors on the upper facet; no hangar in the rules, so no craft fly |
| W1s | vision slit 0.1 x 0.04 | 1 | 40.7 | -1.09 | 0.11 | - | - | picture | blue-white crew deck window above the light race |
| W2s | vision slit 0.1 x 0.04 | 1 | 36.4 | -1.06 | 0.11 | - | - | picture | blue-white crew deck window above the light race |
| W3s | vision slit 0.1 x 0.04 | 1 | 57.2 | -1.12 | 0.12 | - | - | picture | blue-white crew deck window above the light race |
| W4s | vision slit 0.1 x 0.04 | 1 | 22.0 | -0.88 | 0.10 | - | - | picture | blue-white crew deck window above the light race |
| V1s | louvre panel 0.1 x 0.3 | 1 | 17.4 | -0.24 | 0.25 | - | - | picture | heat louvre over the cannon's capacitors |
| LW0sf | module latch row (3 clamps) | 1 | 73.8 | -0.42 | 0.38 | - | - | picture | locks two hull modules together across the joint |
| LW0sa | module latch row (3 clamps) | 1 | 79.9 | -0.42 | 0.37 | - | - | picture | locks two hull modules together across the joint |
| LW1sf | module latch row (3 clamps) | 1 | 22.7 | -0.42 | 0.28 | - | - | picture | locks two hull modules together across the joint |
| LW1sa | module latch row (3 clamps) | 1 | 28.9 | -0.42 | 0.30 | - | - | picture | locks two hull modules together across the joint |
| drive1 | engine, rectangular nozzle 0.50 x 0.49 | 1 | 99.7 | 0.48 | -0.00 | exhaust aft | - | picture | rectangular nozzle pod seated in the stern |
| intake1 | louvre panel 0.3 x 0.5 | 1 | 85.9 | 0.48 | 0.37 | - | - | picture | drive feed louvre |
| transfer1 | square hatch 0.2 | 1 | 49.6 | 1.15 | -0.04 | - | - | picture | boarding door: the waist light breaks round it |
| cooler1_0 | louvre panel 0.2 x 0.3 | 1 | 83.9 | 0.53 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler1_1 | louvre panel 0.2 x 0.3 | 1 | 67.8 | 0.56 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler1_2 | louvre panel 0.2 x 0.3 | 1 | 49.6 | 0.56 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler1_3 | louvre panel 0.2 x 0.3 | 1 | 33.0 | 0.52 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| cooler1_4 | louvre panel 0.2 x 0.3 | 1 | 17.4 | 0.40 | -0.34 | - | - | picture | slatted cooler cassette on the belly |
| Q1p | retro thruster, two rectangular nozzles | 1 | 0.5 | 0.40 | -0.04 | - | - | designed | retro thruster on the bow face beside the casemate (lore 3.4; the evasive burn) |
| Q2p | attitude thruster, two rectangular nozzles | 1 | 14.6 | 0.70 | 0.13 | - | - | designed | attitude thruster on the upper facet |
| Q3p | attitude thruster, two rectangular nozzles | 1 | 89.7 | 0.90 | 0.19 | - | - | designed | attitude thruster on the upper facet |
| D1p | flush drone doors 0.4 x 0.14 | 1 | 68.3 | 1.07 | 0.22 | - | - | picture | the faction's small drone bay: flush armoured doors on the upper facet; no hangar in the rules, so no craft fly |
| W1p | vision slit 0.1 x 0.04 | 1 | 40.7 | 1.09 | 0.11 | - | - | picture | blue-white crew deck window above the light race |
| W2p | vision slit 0.1 x 0.04 | 1 | 36.4 | 1.06 | 0.11 | - | - | picture | blue-white crew deck window above the light race |
| W3p | vision slit 0.1 x 0.04 | 1 | 57.2 | 1.12 | 0.12 | - | - | picture | blue-white crew deck window above the light race |
| W4p | vision slit 0.1 x 0.04 | 1 | 22.0 | 0.88 | 0.10 | - | - | picture | blue-white crew deck window above the light race |
| V1p | louvre panel 0.1 x 0.3 | 1 | 17.4 | 0.24 | 0.25 | - | - | picture | heat louvre over the cannon's capacitors |
| LW0pf | module latch row (3 clamps) | 1 | 73.8 | 0.42 | 0.38 | - | - | picture | locks two hull modules together across the joint |
| LW0pa | module latch row (3 clamps) | 1 | 79.9 | 0.42 | 0.37 | - | - | picture | locks two hull modules together across the joint |
| LW1pf | module latch row (3 clamps) | 1 | 22.7 | 0.42 | 0.28 | - | - | picture | locks two hull modules together across the joint |
| LW1pa | module latch row (3 clamps) | 1 | 28.9 | 0.42 | 0.30 | - | - | picture | locks two hull modules together across the joint |
| H1 | square hatch 0.3 | 1 | 12.3 | 0.00 | 0.22 | - | - | picture | deck hatch over the cannon room |
| H2 | square hatch 0.3 | 1 | 45.3 | 0.00 | 0.37 | - | - | picture | deck hatch to the control deck |
| H3 | square hatch 0.3 | 1 | 89.0 | 0.00 | 0.34 | - | - | picture | deck hatch to the drive room |

Totals: 2 gun mounts with 5 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| Navy grey and steel-blue trim | 99.7 | 0.1 | outer armour and panel edges |  |
| Implant blue | 94.2 | 0.5 | segmented flank race, drone door lamps, windows |  |
| no rust, no warm light, no asymmetry | 99.7 | 0.1 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Dart: drive module | 76.9 to 94.2 | -1.12 to 1.12 | -0.33 to 0.38 | chamfered pressure hull |  |
| Hull: the dart, mission module | 25.8 to 76.9 | -1.15 to 1.15 | -0.33 to 0.38 | chamfered pressure hull |  |
| Dart: fore module | 4.8 to 25.8 | -0.96 to 0.96 | -0.33 to 0.29 | chamfered pressure hull |  |
| Dart: casemate module | 0.5 to 5.0 | -0.56 to 0.56 | -0.33 to 0.17 | chamfered pressure hull |  |
| Flak barbette plinth | 57.2 to 67.4 | -0.33 to 0.33 | 0.34 to 0.46 | recessed grey | the low faceted barbette the Picket lasers turn on |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): 0 deck -0.14 (77% to 92%); 1 deck -0.14 (26% to 76%); 2 deck -0.14 (6% to 25%).

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| drive-1 (hrack) | 81.9 to 87.4 | -0.66 to -0.46 | -0.13 to 0.07 |  |
| drive1 (hrack) | 81.9 to 87.4 | 0.46 to 0.66 | -0.13 to 0.07 |  |
| reactor-1 (hrack) | 66.3 to 71.8 | -0.69 to -0.49 | -0.13 to 0.07 |  |
| reactor1 (hrack) | 66.3 to 71.8 | 0.49 to 0.69 | -0.13 to 0.07 |  |
| control-1 (hrack) | 51.0 to 56.5 | -0.70 to -0.50 | -0.13 to 0.07 |  |
| control1 (hrack) | 51.0 to 56.5 | 0.50 to 0.70 | -0.13 to 0.07 |  |
| sensors-1 (hrack) | 35.9 to 41.4 | -0.67 to -0.47 | -0.13 to 0.07 |  |
| sensors1 (hrack) | 35.9 to 41.4 | 0.47 to 0.67 | -0.13 to 0.07 |  |
| capacitors-1 (hrack) | 18.3 to 23.8 | -0.56 to -0.36 | -0.13 to 0.07 |  |
| capacitors1 (hrack) | 18.3 to 23.8 | 0.36 to 0.56 | -0.13 to 0.07 |  |
| feed-1 (hrack) | 8.5 to 14.0 | -0.46 to -0.26 | -0.13 to 0.07 |  |
| feed1 (hrack) | 8.5 to 14.0 | 0.26 to 0.46 | -0.13 to 0.07 |  |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| belly | 0.04 | Flat sole, chamfered bilges and replaceable cooler cassettes. |

| Break line | Station % | What it opens |
|---|---|---|

Insides through the hull, hidden until a piece breaks: feed racks and capacitor banks forward, sensors, control and the reactor midships, the drive racks aft, a deck through each module, open frames, blue emergency strips on the racks. The Navy breaks in modules at its joints (factions.md).

| ring0 | 76.9 (seam wanders 76.3 to 77.2) | Navy module joint at an open transverse frame. |
| ring1 | 25.8 (seam wanders 25.3 to 26.2) | Navy module joint at an open transverse frame. |

## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_breach_0 | 76.9 | -1.12 | -0.05 | S | eng |  |
| hp_breach_1 | 25.8 | 0.96 | -0.05 | P | prow |  |
| hp_rcs_0 | -0.2 | -0.40 | -0.04 | S |  |  |
| hp_board_0 | 49.6 | -1.15 | -0.04 | S |  |  |
| hp_rcs_1 | -0.2 | 0.40 | -0.04 | P |  |  |
| hp_board_1 | 49.6 | 1.15 | -0.04 | P |  |  |
| hp_core | 69.0 | 0.00 | -0.04 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 230 objects, 48 parts, 301 close pairs, 231 rays, 2 guns, 12 sensor pairs, 1 turrets swept, 8 cones, 29 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The hull, its plate-line cuts, the nozzle pods, the belly coolers and covers, the light races and the joints are Astra's blind build (hegemony_H7A, PR 1745).** Ryan, Nov 23 2026 (R442): Astra's shape, engines, radiator grills and deep plate-line cutouts are better; R443 adopts the method.
- **The Opus fittings sit on that hull: bow face plates, retro and attitude thrusters, flush drone doors with guide lamps, window slits, latch rows at the joints, deck hatches, capacitor louvres and a raised barbette plinth.** Ryan, Nov 23 2026 (R442): he likes the extra plates, bumps, lights and accessories of the Opus build; every part has a job (R221).
- **Flat belly through all three modules.** Ryan, Nov 22 2026: flatten the speedboat keel into a space hull (rule 4.1).
- **Three visible flak emitters on a low eight-sided plinth.** designs.md: three emitters; the plinth lifts their firing plane over the receiver (R240).
- **Flush drone doors on the upper facets, kept with no craft.** designs.md: flush flank doors only; the rules give the Picket no hangar.

## Designed here, not shown in the picture

- Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled.
- Q1s (retro thruster, two rectangular nozzles): retro thruster on the bow face beside the casemate (lore 3.4; the evasive burn).
- Q2s (attitude thruster, two rectangular nozzles): attitude thruster on the upper facet.
- Q3s (attitude thruster, two rectangular nozzles): attitude thruster on the upper facet.
- Q1p (retro thruster, two rectangular nozzles): retro thruster on the bow face beside the casemate (lore 3.4; the evasive burn).
- Q2p (attitude thruster, two rectangular nozzles): attitude thruster on the upper facet.
- Q3p (attitude thruster, two rectangular nozzles): attitude thruster on the upper facet.
