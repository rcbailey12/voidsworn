# chorus_C14: The brood-sac (Chorus carrier), build sheet

The Chorus (chorus) | class Carrier | version 1 (first layout (issue 1155)), 2026-11-19 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus1155\chorus_C14\chorus_C14\chorus_C14_blockout.blend`

**Length 16.5 world units** (data.js b_brood (cls 'Carrier'); length from godot/render/hull_table.gd CLS_LEN['Carrier'] = 16.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bioplasma | F | 2 | M1 (1) |
| 1 | spores | T | 3 | G1 (3) |

| Check | Value |
|---|---|
| model length | 16.506 |
| length side | 16.538 |
| length top | 16.538 |
| length disagreement percent | 0.0 |
| beam top | 11.7 |
| beam bow | 11.7 |
| beam disagreement percent | 0.0 |
| height side | 9.562 |
| height bow | 9.562 |
| height disagreement percent | 0.0 |
| widest at station percent | 23.7 |
| hull beam | 9.4 |
| hull depth | 6.86 |
| L to B hull | 1.76 |
| L to H hull | 2.41 |
| prow overhang | 0.47 |
| outline iou percent | 75.1 |
| mass outline iou percent | 75.4 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| M1 | spine volley, throat (fixed) | 1 barrel | 6.9 | 0.00 | -0.00 | forward | F bioplasma | picture | the spine pore: one small fleshy rimmed hole set in the front folds, a dark wet throat, the bile gland glowing deep inside |
| G1 | spore cloud, spore patch, a honeycomb of pores (turns) | 3 barrels | 38.6 | 1.30 | 3.31 | forward | T spores | picture | the spore cloud: a ragged patch of pores on the back that leans its cloud toward the craft (turns) |
| L1 | launch opening, 1.7 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 58.7 | 0.00 | 2.52 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L2 | launch opening, 1.7 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 47.3 | 4.01 | 1.28 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L3 | launch opening, 1.7 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 47.3 | -4.09 | 1.30 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L4 | launch opening, 1.7 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 22.0 | 4.28 | 0.28 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L5 | launch opening, 1.7 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 22.0 | -4.30 | 0.28 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| S1p | teardrop sac, 0.8 across | 1 | 19.0 | 1.15 | -3.09 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S1s | teardrop sac, 0.8 across | 1 | 19.0 | -1.15 | -3.08 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S2p | teardrop sac, 1.0 across | 1 | 25.6 | 1.06 | -3.14 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S2s | teardrop sac, 1.0 across | 1 | 25.6 | -1.06 | -3.14 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S3p | teardrop sac, 1.1 across | 1 | 32.5 | 1.35 | -3.12 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S3s | teardrop sac, 1.1 across | 1 | 32.5 | -1.28 | -2.96 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S4p | teardrop sac, 1.0 across | 1 | 40.1 | 1.11 | -3.06 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S4s | teardrop sac, 1.0 across | 1 | 40.1 | -1.11 | -3.06 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S5p | teardrop sac, 1.1 across | 1 | 47.9 | 1.29 | -2.83 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S5s | teardrop sac, 1.1 across | 1 | 47.9 | -1.31 | -2.88 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S6p | teardrop sac, 0.9 across | 1 | 55.7 | 0.85 | -2.32 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S6s | teardrop sac, 0.9 across | 1 | 55.7 | -0.89 | -2.44 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S7p | teardrop sac, 0.8 across | 1 | 36.2 | 2.63 | -2.72 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S7s | teardrop sac, 0.8 across | 1 | 36.2 | -2.49 | -2.56 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S8p | teardrop sac, 0.9 across | 1 | 44.3 | 2.59 | -2.42 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S8s | teardrop sac, 0.9 across | 1 | 44.3 | -2.64 | -2.47 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S9p | teardrop sac, 0.8 across | 1 | 52.4 | 2.20 | -2.18 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S9s | teardrop sac, 0.8 across | 1 | 52.4 | -2.33 | -2.31 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| Q1p | attitude thruster quad | 1 | 32.2 | 3.85 | -1.94 | - | - | designed | siphon forward: swings the front |
| Q1s | attitude thruster quad | 1 | 32.2 | -3.64 | -1.82 | - | - | designed | siphon forward: swings the front |
| Q2p | attitude thruster quad | 1 | 55.8 | 3.52 | -0.35 | - | - | designed | siphon aft: swings the stern |
| Q2s | attitude thruster quad | 1 | 55.8 | -3.68 | -0.37 | - | - | designed | siphon aft: swings the stern |
| E1 | pulse vent, mouth 0.4 across | 1 | 71.0 | 0.00 | 0.62 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |
| E2 | pulse vent, mouth 0.4 across | 1 | 71.0 | 0.55 | 0.05 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |
| E3 | pulse vent, mouth 0.4 across | 1 | 71.0 | -0.55 | 0.05 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |
| E4 | pulse vent, mouth 0.4 across | 1 | 71.0 | 0.00 | -0.50 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |

Totals: 2 gun mounts with 4 barrels; 0 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive flesh, hard chitin hide in grown irregular plates (paint stage, R325) | 0.1 | 68.9 | whole body |  |
| raw transition tissue | 19.5 | 52.8 | the lips of the five openings and the spore patch walls |  |
| wet dark maw, dim bile at the floor | 19.5 | 52.8 | inside the five openings |  |
| bile yellow-green light | 0.1 | 5.0 | the spine pore's gland |  |
| bile yellow-green light | 68.9 | 100.0 | the vents and the light in the membranes |  |
| dim bile | 13.5 | 55.9 | the veins, the sac windows, the pores |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the giant sac | 2.9 to 68.9 | -4.70 to 4.70 | -3.28 to 3.58 | dark olive flesh | as long as it is wide, two thirds as tall: one central chamber of folded flesh |
| Front: the puckered face | 1.2 to 3.1 | -1.54 to 1.54 | -1.24 to 1.34 | flesh | a low dome of flesh closing the front, the spine pore flush in it |
| Front lobes | 2.1 to 17.1 | -3.96 to 4.06 | -3.02 to 3.47 | swollen flesh folds | pillows of flesh radiating from the spine pore |
| Spore patch | 29.8 to 48.4 | -0.05 to 2.62 | 2.85 to 3.75 | hide mound, honeycomb of pores | off the centre line, forward of the middle |
| Launch opening L1 | 48.5 to 67.4 | -1.83 to 1.81 | 0.53 to 4.01 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L2 | 35.5 to 56.0 | 2.27 to 5.46 | -0.66 to 2.69 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L3 | 35.5 to 56.0 | -5.55 to -2.34 | -0.66 to 2.68 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L4 | 13.3 to 34.2 | 2.72 to 5.66 | -1.52 to 2.05 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L5 | 13.4 to 34.3 | -5.69 to -2.75 | -1.61 to 1.99 | flesh neck and lip | thick fleshy rim, drawn empty |
| Teardrop sacs | 29.2 to 36.0 | 0.90 to 1.97 | -4.97 to -2.82 | flesh sacs | a fringe of teardrops under the belly |
| Vents | 65.2 to 71.3 | -0.28 to 0.28 | 0.33 to 0.91 | flesh | four pulse vents at the stern, the membranes streaming aft |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.30 (9% to 62%); upper deck 1.25 (9% to 63%).

Bulkhead and frame stations: F0 7.4%, F1 16.5%, F2 21.0%, F3 31.6%, F4 39.5%, F5 47.4%, F6 54.7%, F7 63.8%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| spine gland (gland) | 5.0 to 11.7 | -0.45 to 0.45 | -0.55 to 0.35 | the spine pore's bile gland: the shot's magazine |
| ganglion (ganglion) | 9.8 to 17.1 | -0.50 to 0.50 | 1.52 to 2.28 | the Node: the knot of nerve that steers the body (no bridge) |
| brood L1 (brood) | 44.0 to 54.3 | -0.75 to 0.75 | -0.55 to 0.85 | brood chamber under opening L1: the squadrons grow here (hangar 3) |
| brood L2 (brood) | 37.4 to 47.7 | 0.76 to 2.26 | -0.54 to 0.86 | brood chamber under opening L2: the squadrons grow here (hangar 3) |
| brood L3 (brood) | 37.4 to 47.7 | -2.34 to -0.84 | -0.52 to 0.88 | brood chamber under opening L3: the squadrons grow here (hangar 3) |
| brood L4 (brood) | 20.2 to 30.5 | 0.74 to 2.24 | -0.61 to 0.79 | brood chamber under opening L4: the squadrons grow here (hangar 3) |
| brood L5 (brood) | 20.2 to 30.5 | -2.26 to -0.76 | -0.61 to 0.79 | brood chamber under opening L5: the squadrons grow here (hangar 3) |
| spore store (gland) | 33.8 to 43.5 | 0.35 to 1.55 | 1.57 to 2.33 | the spore store under the patch |
| heart vat (vat) | 30.4 to 43.8 | -0.95 to 0.95 | -0.75 to 0.75 | the heart vat: the core (hp_core), lit bile-green |
| gut fore (gut) | 14.7 to 31.6 | -1.20 to 1.20 | -2.55 to -1.45 | the gut: it feeds the brood |
| gut aft (gut) | 39.5 to 55.3 | -1.10 to 1.10 | -2.50 to -1.50 | the second stomach |
| feed 1p (organ) | 28.6 to 35.9 | 1.85 to 2.75 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| feed 1s (organ) | 28.6 to 35.9 | -2.75 to -1.85 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| feed 2p (organ) | 42.5 to 49.8 | 1.85 to 2.75 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| feed 2s (organ) | 42.5 to 49.8 | -2.75 to -1.85 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| regrowth p (organ) | 51.9 to 58.6 | 1.10 to 1.90 | -0.10 to 0.70 | regrowth tissue (regen 6) |
| regrowth s (organ) | 51.9 to 58.6 | -1.90 to -1.10 | -0.10 to 0.70 | regrowth tissue |
| pulse bladder (engroom) | 58.3 to 65.6 | -0.60 to 0.60 | -0.45 to 0.55 | the pulse bladder: fills and squeezes the four vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| front and the spine pore | 0.40 | the thickest flesh round the throat root |
| back and shoulders | 0.30 | hard chitin hide over the chambers |
| flanks and openings | 0.30 | the necks are thick muscle |
| belly and sacs | 0.25 | thin over the teardrop sacs: they rupture first |
| stern | 0.20 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 11.7 (seam wanders 10.1 to 12.9) | behind the front: the front folds tear away, opening the spine gland and the Node |
| B-2 | 25.9 (seam wanders 25.0 to 26.5) | across the middle, ahead of the pore patch: the sac tears open through the heart vat's front and the gut, the teardrops bursting first |
| B-3 | 59.8 (seam wanders 58.6 to 61.3) | ahead of the stern: the vents and the membranes tear free, opening the pulse bladder |

Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, membrane septa for decks, organs and chambers that never reach the skin; a brood chamber under each opening. The Chorus bursts and tears: sacs rupture first, then the body tears open along ragged lines (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 37.1 | 0.00 | 0.00 |  |  |  |
| hp_breach_0 | 15.9 | 4.04 | -0.43 | port | prow | open hide between the folds |
| hp_breach_1 | 14.0 | -1.95 | 2.88 | stbd | prow | open hide between the folds |
| hp_breach_2 | 34.1 | 4.31 | 1.36 | port | mid | open hide between the folds |
| hp_breach_3 | 36.5 | -2.79 | -2.50 | stbd | mid | open hide between the folds |
| hp_breach_4 | 43.2 | 3.94 | -1.46 | port | mid | open hide between the folds |
| hp_breach_5 | 54.7 | -3.18 | 1.71 | stbd | eng | open hide between the folds |
| hp_breach_6 | 61.4 | 2.21 | -0.99 | port | eng | open hide between the folds |
| hp_rcs_0 | 32.2 | 3.88 | -1.97 | port |  |  |
| hp_rcs_1 | 32.2 | -3.68 | -1.86 | stbd |  |  |
| hp_rcs_2 | 55.9 | 3.56 | -0.36 | port |  |  |
| hp_rcs_3 | 55.9 | -3.71 | -0.38 | stbd |  |  |
| hp_bay_0 | 49.0 | 0.00 | 1.50 | top |  | launch opening L1 floor |
| hp_bay_1 | 41.8 | 2.49 | 0.60 | port |  | launch opening L2 floor |
| hp_bay_2 | 41.8 | -2.57 | 0.62 | stbd |  | launch opening L3 floor |
| hp_bay_3 | 27.2 | 2.58 | 0.17 | port |  | launch opening L4 floor |
| hp_bay_4 | 27.2 | -2.61 | 0.17 | stbd |  | launch opening L5 floor |
| hp_board_0 | 35.3 | 4.32 | -1.44 | port |  |  |
| hp_board_1 | 35.3 | -4.14 | -1.38 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 255 objects, 33 parts, 761 close pairs, 214 rays, 2 guns, 0 sensor pairs, 1 turrets swept, 8 cones, 5 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: dark olive flesh with hard chitin hide, bile yellow-green light; the openings dark inside with a dim bile glow at the floor.** R204 and the lore: the colour is fixed in the build; the picture renders the family's grey-amber anchor palette. R325: hard chitin with a little wet-flesh variety.
- **Five launch openings on necks of flesh, one on the back at the stern, a pair high on the aft shoulders, a pair on the rim at the forward corners.** designs.md: five openings round the rim, evenly dispersed with wide stretches of plain flesh; the front view draws them round the axis, the plan round the disc; placed so each launches clear of every other part (fit check EXIT) and none sits in the vents' jets. The job text said two openings; designs.md, the beauty and the sheet all draw five, so five are built (flagged to the Board).
- **The openings are drawn empty: a deep dark chamber 1.9 deep, a dim glow at its floor, nothing in it.** Ryan, Nov 13: no pods shown; squadron capacity (hangar 3) is an internal fact, a brood chamber under each opening.
- **One spine pore (bioplasma F) at the centre of the front folds; the picture's second, lower radial pucker is where the lobes meet round it.** data.js b_brood has one bioplasma slot: one throat; the beauty's small upper pore and its radial pucker are read as one organ, so nothing pictured is left without a job (R221).
- **The pore patch is the spore cloud (spores T): a ragged honeycomb of pores on a low mound that leans toward the craft (a turret).** the weapon-match table puts spores on a turning spore organ; the three biggest pores fire the three shots of each volley.
- **Eighteen teardrop sacs in two rows under the belly (nine a side), clear of the low openings' launch lanes.** designs.md: a row of teardrop sacs, spore feed and regrowth flesh (regen 6); the picture's count (about fourteen) does not settle counts.
- **Four pulse vents at the stern, the membranes cut to about 0.4 of the body's length.** factions.md: no nozzles, pulsing vents or trailing membranes; the picture's membranes are nearly as long again as the body, which would make the sac a small part of a 16.5 ship; cut so the whole ship is 16.5 front to membrane tip.
- **Siphons added, a pair low on the flanks amidships and a pair low aft.** a ship in space must turn; the picture shows none; siphons, not nozzles.
- **Insides: a brood chamber under each opening, the spore store under the patch, the heart vat, two guts, spore feed stores over the sacs, regrowth tissue and the pulse bladder.** R209, R215: flesh, bone and organs through the whole body; the hangar is the body's own chambers.

## Designed here, not shown in the picture

- The belly between the sacs is designed here; the sheet has no underside view.
- Q1p (attitude thruster quad): siphon forward: swings the front.
- Q1s (attitude thruster quad): siphon forward: swings the front.
- Q2p (attitude thruster quad): siphon aft: swings the stern.
- Q2s (attitude thruster quad): siphon aft: swings the stern.
