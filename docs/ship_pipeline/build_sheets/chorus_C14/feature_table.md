# chorus_C14: The brood-sac (Chorus carrier), build sheet

The Chorus (chorus) | class Carrier | version 2 (blockout v2, the Board's notes (issue 1155)), 2026-11-19 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus1155\chorus_C14\chorus_C14\chorus_C14_blockout.blend`

**Length 16.5 world units** (data.js b_brood (cls 'Carrier'); length from godot/render/hull_table.gd CLS_LEN['Carrier'] = 16.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bioplasma | F | 2 | M1 (1) |
| 1 | spores | T | 3 | G1 (3) |

| Check | Value |
|---|---|
| model length | 16.509 |
| length side | 16.538 |
| length top | 16.538 |
| length disagreement percent | 0.0 |
| beam top | 12.912 |
| beam bow | 12.912 |
| beam disagreement percent | 0.0 |
| height side | 10.012 |
| height bow | 10.012 |
| height disagreement percent | 0.0 |
| widest at station percent | 25.8 |
| hull beam | 9.4 |
| hull depth | 6.86 |
| L to B hull | 1.76 |
| L to H hull | 2.41 |
| prow overhang | 0.67 |
| outline iou percent | 76.4 |
| mass outline iou percent | 77.1 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| M1 | spine volley, throat (fixed) | 1 barrel | 7.7 | 0.00 | -0.00 | forward | F bioplasma | picture | the spine pore: one small fleshy rimmed hole set in the front folds, a dark wet throat, the bile gland glowing deep inside |
| G1 | spore cloud, spore patch, a honeycomb of pores (turns) | 3 barrels | 20.4 | -0.41 | 3.48 | forward | T spores | picture | the spore cloud: the ragged cluster at the front of the honeycomb field, leaning its cloud toward the craft (turns) |
| L1 | launch opening, 2.1 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 60.5 | 0.00 | 2.45 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L2 | launch opening, 2.1 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 49.7 | 3.95 | 1.27 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L3 | launch opening, 2.1 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 49.7 | -4.03 | 1.29 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L4 | launch opening, 2.1 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 21.7 | 4.21 | 0.27 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| L5 | launch opening, 2.1 across, on a neck of flesh; empty, a dim glow deep inside | 1 | 21.7 | -4.24 | 0.27 | - | - | picture | a spore squadron is born deep in the chamber below and leaves through the mouth |
| S1p | teardrop sac, 1.0 across | 1 | 21.6 | 2.84 | -2.43 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S1s | teardrop sac, 1.0 across | 1 | 21.6 | -2.85 | -2.44 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S2p | teardrop sac, 1.2 across | 1 | 31.9 | 3.10 | -2.47 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S2s | teardrop sac, 1.2 across | 1 | 31.9 | -2.92 | -2.32 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S3p | teardrop sac, 1.3 across | 1 | 42.5 | 2.99 | -2.33 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S3s | teardrop sac, 1.3 across | 1 | 42.5 | -2.98 | -2.31 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S4p | teardrop sac, 1.1 across | 1 | 52.7 | 2.50 | -2.08 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S4s | teardrop sac, 1.1 across | 1 | 52.7 | -2.63 | -2.21 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S5p | teardrop sac, 0.8 across | 1 | 61.4 | 1.62 | -1.55 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S5s | teardrop sac, 0.8 across | 1 | 61.4 | -1.76 | -1.71 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S6p | teardrop sac, 1.0 across | 1 | 26.8 | 1.44 | -3.05 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S6s | teardrop sac, 1.0 across | 1 | 26.8 | -1.44 | -3.05 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S7p | teardrop sac, 1.2 across | 1 | 37.2 | 1.56 | -3.04 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S7s | teardrop sac, 1.2 across | 1 | 37.2 | -1.50 | -2.91 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S8p | teardrop sac, 1.2 across | 1 | 47.6 | 1.48 | -2.84 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S8s | teardrop sac, 1.2 across | 1 | 47.6 | -1.51 | -2.90 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S9p | teardrop sac, 0.9 across | 1 | 57.2 | 1.06 | -2.24 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| S9s | teardrop sac, 0.9 across | 1 | 57.2 | -1.13 | -2.39 | - | - | picture | spore feed for the squadrons and regrowth flesh (regen 6), hanging from the belly |
| Q1p | attitude thruster quad | 1 | 35.2 | 3.92 | -1.88 | - | - | designed | siphon forward: swings the front |
| Q1s | attitude thruster quad | 1 | 35.2 | -3.71 | -1.77 | - | - | designed | siphon forward: swings the front |
| Q2p | attitude thruster quad | 1 | 57.5 | 3.05 | -1.08 | - | - | designed | siphon aft: swings the stern |
| Q2s | attitude thruster quad | 1 | 57.5 | -3.27 | -1.17 | - | - | designed | siphon aft: swings the stern |
| E1 | pulse vent, mouth 0.4 across | 1 | 72.2 | 0.00 | 0.62 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |
| E2 | pulse vent, mouth 0.4 across | 1 | 72.2 | 0.55 | 0.05 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |
| E3 | pulse vent, mouth 0.4 across | 1 | 72.2 | -0.55 | 0.05 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |
| E4 | pulse vent, mouth 0.4 across | 1 | 72.2 | 0.00 | -0.50 | exhaust aft | - | picture | pulse vent with two wide trailing veils lit from within (the family's veil, as C12), splayed away from the stern's centre |

Totals: 2 gun mounts with 4 barrels; 0 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive flesh, hard chitin hide in grown irregular plates (paint stage, R325) | 1.3 | 70.1 | whole body |  |
| raw transition tissue | 20.7 | 54.0 | the lips of the five openings and the spore patch walls |  |
| wet dark maw, dim bile at the floor | 20.7 | 54.0 | inside the five openings |  |
| bile yellow-green light | 1.3 | 6.2 | the spine pore's gland |  |
| bile yellow-green light | 70.1 | 100.0 | the vents and the light in the membranes |  |
| dim bile | 14.6 | 57.0 | the veins, the sac windows, the pores |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the giant sac | 4.0 to 70.1 | -4.70 to 4.70 | -3.28 to 3.58 | dark olive flesh | as long as it is wide, two thirds as tall: one central chamber of folded flesh |
| Front: the puckered face | 2.3 to 4.2 | -1.54 to 1.54 | -1.24 to 1.34 | flesh | a low dome of flesh closing the front, the spine pore flush in it |
| Front folds | 1.3 to 16.9 | -4.02 to 3.96 | -3.26 to 2.93 | skin folds parted by deep creases | creases from the rim sinking in to the spine pore |
| Spore field and patch | 14.9 to 26.6 | -1.27 to 0.44 | 3.24 to 3.69 | a sunk honeycomb of pores, the turning cluster at its front | over the upper front, off the centre line |
| Launch opening L1 | 48.4 to 71.0 | -2.01 to 2.03 | 0.18 to 4.27 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L2 | 35.5 to 60.8 | 1.87 to 5.74 | -1.07 to 3.03 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L3 | 35.5 to 60.6 | -5.83 to -1.92 | -0.96 to 3.05 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L4 | 10.7 to 35.7 | 2.30 to 5.91 | -1.83 to 2.27 | flesh neck and lip | thick fleshy rim, drawn empty |
| Launch opening L5 | 10.7 to 35.6 | -5.93 to -2.33 | -1.83 to 2.26 | flesh neck and lip | thick fleshy rim, drawn empty |
| Teardrop sacs | 39.0 to 46.7 | 2.49 to 3.87 | -4.28 to -1.97 | flesh sacs | a fringe of teardrops under the belly |
| Vents | 66.3 to 72.4 | -0.28 to 0.28 | 0.33 to 0.91 | flesh | four pulse vents at the stern, the membranes streaming aft |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.30 (10% to 63%); upper deck 1.25 (10% to 64%).

Bulkhead and frame stations: F0 8.6%, F1 17.7%, F2 22.2%, F3 32.8%, F4 40.7%, F5 48.6%, F6 55.8%, F7 64.9%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| spine gland (gland) | 6.2 to 12.8 | -0.45 to 0.45 | -0.55 to 0.35 | the spine pore's bile gland: the shot's magazine |
| ganglion (ganglion) | 11.0 to 18.3 | -0.50 to 0.50 | 1.52 to 2.28 | the Node: the knot of nerve that steers the body (no bridge) |
| brood L1 (brood) | 45.8 to 56.1 | -0.75 to 0.75 | -0.62 to 0.78 | brood chamber under opening L1: the squadrons grow here (hangar 3) |
| brood L2 (brood) | 39.3 to 49.6 | 0.73 to 2.23 | -0.54 to 0.86 | brood chamber under opening L2: the squadrons grow here (hangar 3) |
| brood L3 (brood) | 39.3 to 49.6 | -2.30 to -0.80 | -0.52 to 0.88 | brood chamber under opening L3: the squadrons grow here (hangar 3) |
| brood L4 (brood) | 20.4 to 30.7 | 0.69 to 2.19 | -0.62 to 0.78 | brood chamber under opening L4: the squadrons grow here (hangar 3) |
| brood L5 (brood) | 20.4 to 30.7 | -2.22 to -0.72 | -0.62 to 0.78 | brood chamber under opening L5: the squadrons grow here (hangar 3) |
| spore store (gland) | 17.7 to 27.4 | -0.95 to 0.25 | 1.22 to 1.98 | the spore store under the honeycomb field |
| heart vat (vat) | 31.6 to 44.9 | -0.95 to 0.95 | -0.75 to 0.75 | the heart vat: the core (hp_core), lit bile-green |
| gut fore (gut) | 15.8 to 32.8 | -1.20 to 1.20 | -2.55 to -1.45 | the gut: it feeds the brood |
| gut aft (gut) | 40.7 to 56.4 | -1.10 to 1.10 | -2.50 to -1.50 | the second stomach |
| feed 1p (organ) | 29.8 to 37.0 | 1.85 to 2.75 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| feed 1s (organ) | 29.8 to 37.0 | -2.75 to -1.85 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| feed 2p (organ) | 43.7 to 51.0 | 1.85 to 2.75 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| feed 2s (organ) | 43.7 to 51.0 | -2.75 to -1.85 | -2.40 to -1.60 | spore feed store over the teardrop sacs |
| regrowth p (organ) | 53.1 to 59.8 | 1.10 to 1.90 | -0.10 to 0.70 | regrowth tissue (regen 6) |
| regrowth s (organ) | 53.1 to 59.8 | -1.90 to -1.10 | -0.10 to 0.70 | regrowth tissue |
| pulse bladder (engroom) | 59.5 to 66.7 | -0.60 to 0.60 | -0.45 to 0.55 | the pulse bladder: fills and squeezes the four vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| front and the spine pore | 0.40 | the thickest flesh round the throat root |
| back and shoulders | 0.30 | hard chitin hide over the chambers |
| flanks and openings | 0.30 | the necks are thick muscle |
| belly and sacs | 0.25 | thin over the teardrop sacs: they rupture first |
| stern | 0.20 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 12.8 (seam wanders 11.3 to 14.0) | behind the front: the front folds tear away, opening the spine gland and the Node |
| B-2 | 27.1 (seam wanders 26.1 to 27.7) | across the middle, ahead of the pore patch: the sac tears open through the heart vat's front and the gut, the teardrops bursting first |
| B-3 | 61.0 (seam wanders 59.8 to 62.5) | ahead of the stern: the vents and the membranes tear free, opening the pulse bladder |

Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, membrane septa for decks, organs and chambers that never reach the skin; a brood chamber under each opening. The Chorus bursts and tears: sacs rupture first, then the body tears open along ragged lines (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 38.3 | 0.00 | 0.00 |  |  |  |
| hp_breach_0 | 17.9 | 3.63 | -1.66 | port | prow | open hide between the folds |
| hp_breach_1 | 18.8 | -3.18 | 2.31 | stbd | prow | open hide between the folds |
| hp_breach_2 | 37.7 | 4.73 | -0.04 | port | mid | open hide between the folds |
| hp_breach_3 | 41.3 | -4.17 | -1.18 | stbd | mid | open hide between the folds |
| hp_breach_4 | 46.8 | 4.11 | -0.96 | port | mid | open hide between the folds |
| hp_breach_5 | 55.9 | -3.18 | 1.71 | stbd | eng | open hide between the folds |
| hp_breach_6 | 62.6 | 2.21 | -0.99 | port | eng | open hide between the folds |
| hp_rcs_0 | 35.2 | 3.96 | -1.91 | port |  |  |
| hp_rcs_1 | 35.2 | -3.75 | -1.81 | stbd |  |  |
| hp_rcs_2 | 57.7 | 3.08 | -1.10 | port |  |  |
| hp_rcs_3 | 57.7 | -3.30 | -1.19 | stbd |  |  |
| hp_bay_0 | 49.3 | 0.00 | 1.27 | top |  | launch opening L1 floor |
| hp_bay_1 | 42.5 | 2.26 | 0.51 | port |  | launch opening L2 floor |
| hp_bay_2 | 42.5 | -2.33 | 0.53 | stbd |  | launch opening L3 floor |
| hp_bay_3 | 28.0 | 2.28 | 0.14 | port |  | launch opening L4 floor |
| hp_bay_4 | 28.0 | -2.30 | 0.14 | stbd |  | launch opening L5 floor |
| hp_board_0 | 36.4 | 4.32 | -1.44 | port |  |  |
| hp_board_1 | 36.4 | -4.14 | -1.38 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 258 objects, 33 parts, 655 close pairs, 215 rays, 2 guns, 0 sensor pairs, 1 turrets swept, 8 cones, 5 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: dark olive flesh with hard chitin hide, bile yellow-green light; the openings dark inside with a dim bile glow at the floor.** R204 and the lore: the colour is fixed in the build; the picture renders the family's grey-amber anchor palette. R325: hard chitin with a little wet-flesh variety.
- **Five launch openings on necks of flesh, one on the back at the stern, a pair high on the aft shoulders, a pair on the rim at the forward corners.** designs.md: five openings round the rim, evenly dispersed with wide stretches of plain flesh; the front view draws them round the axis, the plan round the disc; placed so each launches clear of every other part (fit check EXIT) and none sits in the vents' jets. The job text said two openings; designs.md, the beauty and the sheet all draw five, so five are built (flagged to the Board).
- **The openings are drawn empty: a deep dark chamber 2.2 deep, a dim glow at its floor, nothing in it; 2.1 across with fat round lips on necks 1.2 tall (blockout v2, the Board's note 3).** Ryan, Nov 13: no pods shown; squadron capacity (hangar 3) is an internal fact, a brood chamber under each opening.
- **One spine pore (bioplasma F): a puckered dark sphincter 1.8 across at the centre of the front, the skin folds creased in to it; the small hole above it is a sense pit (an eye-hole that tastes).** data.js b_brood has one bioplasma slot: one throat; blockout v2 (the Board's notes 1 and 2): creases cut in, not lobes added, the mouth twice v1's, the eye-hole added.
- **The honeycomb is a sunk field of pores over the upper front (about a fifth of the top) in a raised rim; the spore cloud (spores T) is the ragged cluster at its front that leans toward the craft (a turret).** the weapon-match table puts spores on a turning spore organ, and a turret the size of the field could not turn on a curved body; the three biggest pores fire the three shots of each volley. Blockout v2, the Board's note 4.
- **Eighteen big teardrop sacs on soft necks in a fringe low on the belly's edge (nine a side), hanging below the outline (blockout v2, the Board's note 5).** designs.md: a row of teardrop sacs, spore feed and regrowth flesh (regen 6); the picture's count (about fourteen) does not settle counts.
- **Four pulse vents at the stern, the membranes cut to about 0.4 of the body's length.** factions.md: no nozzles, pulsing vents or trailing membranes; the picture's membranes are nearly as long again as the body, which would make the sac a small part of a 16.5 ship; cut so the whole ship is 16.5 front to membrane tip.
- **Siphons added, a pair low on the flanks amidships and a pair low aft.** a ship in space must turn; the picture shows none; siphons, not nozzles.
- **Insides: a brood chamber under each opening, the spore store under the patch, the heart vat, two guts, spore feed stores over the sacs, regrowth tissue and the pulse bladder.** R209, R215: flesh, bone and organs through the whole body; the hangar is the body's own chambers.

## Designed here, not shown in the picture

- The belly between the sacs is designed here; the sheet has no underside view.
- Q1p (attitude thruster quad): siphon forward: swings the front.
- Q1s (attitude thruster quad): siphon forward: swings the front.
- Q2p (attitude thruster quad): siphon aft: swings the stern.
- Q2s (attitude thruster quad): siphon aft: swings the stern.
