# chorus_C12: The drone-spawn (Chorus frigate), build sheet

The Chorus (chorus) | class Frigate | version 1 (the first build sheet (issue 1153)), 2026-11-19 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus1153\chorus_C12\chorus_C12\chorus_C12_blockout.blend`

**Length 6.5 world units** (data.js b_drone (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bioplasma | F | 2 | M1 (1) |
| 1 | tendril | T | 2 | T1 (2) |

| Check | Value |
|---|---|
| model length | 6.497 |
| length side | 6.511 |
| length top | 6.511 |
| length disagreement percent | 0.0 |
| beam top | 3.189 |
| beam bow | 3.2 |
| beam disagreement percent | 0.17 |
| height side | 2.989 |
| height bow | 2.983 |
| height disagreement percent | 0.09 |
| widest at station percent | 45.0 |
| hull beam | 2.51 |
| hull depth | 1.67 |
| L to B hull | 2.59 |
| L to H hull | 3.89 |
| prow overhang | 0.67 |
| outline iou percent | 75.5 |
| mass outline iou percent | 76.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| M1 | spine volley, throat (fixed) | 1 barrel | 13.3 | 0.00 | 0.00 | forward | F bioplasma | picture | the knoll: the head ends in a round puckered mouth of raw flesh, a big deep dark bore (about half the head's width) with a fat lip ringed by short bone hooks; the bile gland lies deep down the bore |
| T1 | boarding tendrils, knot of 5 heavy blunt tendrils draped over the hull (fixed) | 2 barrels | 53.3 | 0.00 | 0.87 | forward | T tendril | picture | boarding tendrils: a low mound of knotted muscle holding five heavy tendrils with blunt rounded tips and no claws, draped back over the hull and down its flanks at rest (fixed: they reach every way at once) |
| S1p | bile dome, 0.6 across | 1 | 26.5 | 0.92 | -0.09 | - | - | picture | a bile store in a wrinkled socket, fed forward to the knoll by the veins |
| S1s | bile dome, 0.6 across | 1 | 26.5 | -0.86 | -0.08 | - | - | picture | a bile store in a wrinkled socket, fed forward to the knoll by the veins |
| S2p | bile dome, 0.7 across | 1 | 38.8 | 1.14 | -0.05 | - | - | picture | a bile store in a wrinkled socket, fed forward to the knoll by the veins |
| S2s | bile dome, 0.7 across | 1 | 38.8 | -1.09 | -0.04 | - | - | picture | a bile store in a wrinkled socket, fed forward to the knoll by the veins |
| S3p | bile dome, 0.5 across | 1 | 63.5 | 1.01 | -0.01 | - | - | picture | a bile store in a wrinkled socket, fed forward to the knoll by the veins |
| S3s | bile dome, 0.5 across | 1 | 63.5 | -0.93 | -0.00 | - | - | picture | a bile store in a wrinkled socket, fed forward to the knoll by the veins |
| R1p | regrowth sac, 0.8 across, hanging | 1 | 41.8 | 0.40 | -0.70 | - | - | picture | the regrow reserve: flesh the body draws on to close its wounds (regen 3) |
| R2s | regrowth sac, 0.7 across, hanging | 1 | 55.6 | -0.38 | -0.63 | - | - | picture | the regrow reserve: flesh the body draws on to close its wounds (regen 3) |
| Q1p | attitude thruster quad | 1 | 19.6 | 0.61 | -0.27 | - | - | designed | siphon below the prow: swings the bow |
| Q2p | attitude thruster quad | 1 | 69.3 | 0.50 | 0.31 | - | - | designed | siphon aft: swings the stern |
| Q1s | attitude thruster quad | 1 | 19.6 | -0.57 | -0.25 | - | - | designed | siphon below the prow: swings the bow |
| Q2s | attitude thruster quad | 1 | 69.3 | -0.60 | 0.36 | - | - | designed | siphon aft: swings the stern |
| E1 | pulse vent, mouth 0.2 across | 1 | 76.1 | 0.20 | 0.09 | exhaust aft | - | picture | pulse vent with three wide flowing veils that fan, cup and curl, splayed away from the ring's centre |
| E2 | pulse vent, mouth 0.2 across | 1 | 76.1 | -0.08 | 0.20 | exhaust aft | - | picture | pulse vent with three wide flowing veils that fan, cup and curl, splayed away from the ring's centre |
| E3 | pulse vent, mouth 0.2 across | 1 | 76.1 | -0.20 | -0.07 | exhaust aft | - | picture | pulse vent with three wide flowing veils that fan, cup and curl, splayed away from the ring's centre |
| E4 | pulse vent, mouth 0.2 across | 1 | 76.1 | 0.08 | -0.17 | exhaust aft | - | picture | pulse vent with three wide flowing veils that fan, cup and curl, splayed away from the ring's centre |

Totals: 2 gun mounts with 3 barrels; 0 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive flesh, hard chitin plates over most of the hull (paint stage, R325) | 10.3 | 73.4 | whole body |  |
| raw puckered flesh | 0.2 | 12.6 | the prow knoll |  |
| pale ochre bone | 0.2 | 3.3 | the short hooks round the bore |  |
| bile yellow-green light | 0.2 | 9.5 | the gland deep in the knoll's vent |  |
| bile yellow-green light | 72.6 | 96.4 | the vents and the light in the membranes |  |
| dim bile | 12.6 | 69.5 | the veins, the dome windows, the tendril tips' acid pores |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the compact knot of flesh | 10.2 to 74.1 | -1.22 to 1.29 | -0.73 to 0.94 | dark olive flesh | narrow at the prow, widest a little aft of the middle, rounding into the stern |
| Prow knoll | 2.0 to 17.7 | -0.66 to 0.69 | -0.65 to 0.64 | raw flesh, bone hooks | the gun and nothing else at the prow (Ryan's edits, issue 631) |
| Tendril knot | 38.4 to 68.2 | -0.83 to 0.86 | 0.46 to 1.27 | flesh mound, tendrils | the knot with a crown on the back: the frigate's mark from above (R233) |
| Bile dome 1 (port) | 20.8 to 31.8 | 0.62 to 1.23 | -0.45 to 0.28 | flesh dome | a dome on the flank |
| Bile dome 1 (starboard) | 20.8 to 31.8 | -1.16 to -0.55 | -0.45 to 0.28 | flesh dome | a dome on the flank |
| Bile dome 2 (port) | 32.5 to 44.8 | 0.82 to 1.48 | -0.45 to 0.35 | flesh dome | a dome on the flank |
| Bile dome 2 (starboard) | 32.5 to 44.8 | -1.42 to -0.77 | -0.45 to 0.36 | flesh dome | a dome on the flank |
| Bile dome 3 (port) | 59.6 to 67.9 | 0.78 to 1.26 | -0.30 to 0.28 | flesh dome | a dome on the flank |
| Bile dome 3 (starboard) | 59.6 to 67.9 | -1.17 to -0.70 | -0.29 to 0.29 | flesh dome | a dome on the flank |
| Reserve sac 1 (port) | 35.6 to 47.7 | 0.07 to 0.80 | -1.45 to -0.49 | flesh sac | hanging below the hull |
| Reserve sac 2 (starboard) | 50.7 to 61.2 | -0.73 to -0.08 | -1.31 to -0.44 | flesh sac | hanging below the hull |
| Vent ring | 69.3 to 76.7 | 0.10 to 0.31 | -0.02 to 0.19 | flesh | four pulse vents round the stern's end, their veils streaming aft |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.42 (17% to 66%); upper deck 0.38 (17% to 66%).

Bulkhead and frame stations: F0 16.4%, F1 24.9%, F2 33.3%, F3 41.8%, F4 50.3%, F5 58.7%, F6 66.4%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| bile gland (gland) | 14.6 to 24.4 | -0.26 to 0.26 | -0.29 to 0.19 | the knoll's bile gland: the shot's magazine |
| ganglion (ganglion) | 24.3 to 31.6 | -0.20 to 0.20 | 0.35 to 0.65 | the Node: the knot of nerve that steers the body |
| bile store 1p (gland) | 23.3 to 29.5 | 0.42 to 0.70 | -0.30 to 0.00 | the bile store behind the dome |
| bile store 1s (gland) | 23.3 to 29.5 | -0.70 to -0.42 | -0.30 to 0.00 | the bile store behind the dome |
| bile store 2p (gland) | 35.6 to 41.8 | 0.36 to 0.64 | -0.30 to 0.00 | the bile store behind the dome |
| bile store 2s (gland) | 35.6 to 41.8 | -0.64 to -0.36 | -0.30 to 0.00 | the bile store behind the dome |
| bile store 3p (gland) | 60.6 to 66.7 | 0.30 to 0.58 | -0.30 to 0.00 | the bile store behind the dome |
| bile store 3s (gland) | 60.6 to 66.7 | -0.58 to -0.30 | -0.30 to 0.00 | the bile store behind the dome |
| heart vat (vat) | 36.1 to 49.0 | -0.34 to 0.34 | -0.30 to 0.30 | the heart vat: the core (hp_core), lit bile-green |
| gut (gut) | 23.3 to 40.3 | -0.34 to 0.34 | -0.60 to -0.20 | the gut (kept well off the belly skin: death seam check, issue 1153 run 1) |
| regrowth 1 (organ) | 37.8 to 45.8 | 0.12 to 0.52 | -0.66 to -0.34 | regrowth tissue over the reserve sac (regen 3) |
| regrowth 2 (organ) | 51.7 to 59.7 | -0.52 to -0.12 | -0.66 to -0.34 | regrowth tissue over the reserve sac (regen 3) |
| knot muscle (organ) | 46.9 to 59.8 | -0.30 to 0.30 | 0.36 to 0.68 | the knot's root muscle: it throws the tendrils |
| pulse bladder (engroom) | 62.1 to 70.7 | -0.26 to 0.26 | -0.22 to 0.22 | the pulse bladder: fills and squeezes the four vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| prow and knoll | 0.20 | the thickest flesh, over the knoll's root |
| back (the knot) | 0.18 | thick folded flesh under the knot's root |
| flanks and domes | 0.12 | thin over the domes: they rupture first |
| belly | 0.12 |  |
| stern | 0.10 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 33.3 (seam wanders 31.0 to 35.6) | ahead of the knot: the prow and the knoll tear away, opening the gland, the Node and the gut; the fore domes burst first |

Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, then the body tears open along a ragged line (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 42.6 | 0.00 | 0.00 |  |  |  |
| hp_breach_0 | 23.2 | 0.83 | 0.06 | port | prow | open hide beside a dome |
| hp_breach_1 | 61.2 | -0.90 | -0.27 | stbd | eng | open hide beside a dome |
| hp_rcs_0 | 19.4 | 0.64 | -0.29 | port |  |  |
| hp_rcs_1 | 19.4 | -0.59 | -0.28 | stbd |  |  |
| hp_rcs_2 | 69.7 | 0.52 | 0.33 | port |  |  |
| hp_rcs_3 | 69.7 | -0.62 | 0.38 | stbd |  |  |
| hp_board_0 | 37.9 | 1.03 | 0.30 | port |  |  |
| hp_board_1 | 37.9 | -1.05 | 0.31 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 132 objects, 18 parts, 482 close pairs, 207 rays, 2 guns, 0 sensor pairs, 0 turrets swept, 8 cones, 0 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: bile yellow-green light over dark olive flesh, pale ochre bone; hard chitin plates over most of the hull in the paint (R325, Ryan Nov 19).** R204 and the lore: the colour is fixed in the build; the picture renders the family's grey-amber anchor palette.
- **The head's puckered mouth is the spine volley (bioplasma F): one deep dark bore about half the lip's width, in a soft puckered lip that flares from a waist, twelve short bone hooks set into the lip (Board on blockout v2: a deep bore, never a disc or a lit dot; the head blends into the body; Board on v3: open the bore so it dominates bow-on, no straight collar).** data.js b_drone has one bioplasma slot (issue 649, Ryan's "send the frigate back on guns"); 2 shots leave the one vent in turn.
- **The tendril mound is fixed, not a turret: a knot of muscle holding five draped tendrils (new kit part type drape; accepted by the Board on blockout v2).** the slot is all round (T); tendrils lying over the hull reach every way at once, as C11's mane (issue 623); a turning crown would sweep them through the hull.
- **The tendrils are laid on the hull clear of the hide and hang free below the waterline at their tips.** they must not sit in the hull (fit check CLASH); the picture's tips hang off the flanks.
- **The domes on the flanks are bile stores feeding the knoll; veins run forward to it.** every part has a job (R221); designs.md does not name them; the picture shows three a side.
- **The two hanging sacs are the regrow reserve, one each side, staggered.** designs.md (regen 3); staggered so neither hides behind the other in the side view.
- **The stern is a ring of four pulse vents with three wide flowing veils each (a new kit trail, veil: thin sheets that fan, cup and curl), about 1.45 long.** factions.md: no nozzles, trailing membranes; the picture's veils, cut to fit the 6.5 length; the Board on blockout v2: fewer, wider, curved sheets, never stiff blades.
- **Siphons added, a pair forward and a pair aft.** a ship in space must turn; the picture shows none.
- **The back is wrinkled flesh with seven long folds running bow to stern under the tendrils; no bone on the back.** the Board on blockout v2: the picture's back reads as lengthwise folds and ridges, and the scattered bone chunks read as debris; large relief that reads at camera 170.

## Designed here, not shown in the picture

- The belly is designed here: the sheet's bow-on view shows only the two sacs below.
- Q1p (attitude thruster quad): siphon below the prow: swings the bow.
- Q2p (attitude thruster quad): siphon aft: swings the stern.
- Q1s (attitude thruster quad): siphon below the prow: swings the bow.
- Q2s (attitude thruster quad): siphon aft: swings the stern.
