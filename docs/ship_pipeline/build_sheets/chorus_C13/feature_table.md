# chorus_C13: The spitter (Chorus destroyer), build sheet

The Chorus (chorus) | class Destroyer | version 2 (shaping pass v2 (issue 1154, the Board on v1)), 2026-11-19 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus1154\chorus_C13\chorus_C13\chorus_C13_blockout.blend`

**Length 9.5 world units** (data.js b_spitter (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bioplasma | T | 2 | W2 (1), W3 (1) |
| 1 | bioplasma | F | 2 | W1 (1) |

| Check | Value |
|---|---|
| model length | 9.538 |
| length side | 9.562 |
| length top | 9.562 |
| length disagreement percent | 0.0 |
| beam top | 3.875 |
| beam bow | 3.987 |
| beam disagreement percent | 1.18 |
| height side | 3.688 |
| height bow | 3.688 |
| height disagreement percent | 0.0 |
| widest at station percent | 57.3 |
| hull beam | 2.95 |
| hull depth | 2.57 |
| L to B hull | 3.22 |
| L to H hull | 3.7 |
| prow overhang | 0.43 |
| outline iou percent | 82.4 |
| mass outline iou percent | 82.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| W1 | spine volley, throat (fixed) | 1 barrel | 12.5 | 0.02 | -0.34 | forward, +22 elev | F bioplasma | picture | the prow gland: a knoll grown into the nose bulb, a puckered vent at its crown, short spines round it; it spits forward |
| W2 | spine volley, throat (fixed) | 1 barrel | 35.3 | 0.09 | 0.58 | 22 deg off the bow to port, +71 elev | T bioplasma | picture | a dorsal spine gland: a puckered vent at the crown of a knoll on the back, short spines out of the knoll round it; it faces up and spits every way |
| W3 | spine volley, throat (fixed) | 1 barrel | 51.7 | -0.17 | 0.78 | 90 deg off the bow to starboard, +84 elev | T bioplasma | picture | a dorsal spine gland: a puckered vent at the crown of a knoll on the back, short spines out of the knoll round it; it faces up and spits every way |
| SB1 | spine bed, 1.2 across | 1 | 66.6 | -0.19 | 0.94 | - | - | picture | a knoll aft of the glands studded with growing spines: the spent spines regrow here (regrow, regen 4) |
| S1p | bile sac, 0.8 across | 1 | 24.5 | 0.90 | -0.56 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S2p | bile sac, 1.4 across | 1 | 38.1 | 1.34 | -0.40 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S3p | bile sac, 1.4 across | 1 | 55.4 | 1.30 | -0.65 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S4p | bile sac, 1.0 across | 1 | 70.1 | 1.06 | -0.30 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S1s | bile sac, 0.9 across | 1 | 26.6 | -0.92 | -0.42 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S2s | bile sac, 1.4 across | 1 | 42.8 | -1.05 | -0.64 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S3s | bile sac, 1.2 across | 1 | 59.6 | -1.24 | -0.37 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S4s | bile sac, 0.8 across | 1 | 72.7 | -0.89 | -0.59 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| H1 | hanging sac, 0.8 across | 1 | 31.4 | 0.20 | -1.01 | - | - | picture | a bile sac hanging under the belly: the spitter's deep reserve |
| H2 | hanging sac, 0.9 across | 1 | 49.7 | -0.21 | -1.10 | - | - | picture | a bile sac hanging under the belly: the spitter's deep reserve |
| H3 | hanging sac, 0.8 across | 1 | 65.8 | 0.22 | -1.13 | - | - | picture | a bile sac hanging under the belly: the spitter's deep reserve |
| Q1p | attitude thruster quad | 1 | 13.5 | 0.67 | -0.22 | - | - | designed | siphon behind the nose: swings the bow |
| Q2p | attitude thruster quad | 1 | 76.2 | 0.77 | 0.24 | - | - | designed | siphon aft: swings the stern |
| Q1s | attitude thruster quad | 1 | 13.5 | -0.67 | -0.23 | - | - | designed | siphon behind the nose: swings the bow |
| Q2s | attitude thruster quad | 1 | 76.2 | -0.75 | 0.24 | - | - | designed | siphon aft: swings the stern |
| E1 | pulse vent, mouth 0.3 across | 1 | 84.8 | 0.00 | 0.18 | exhaust aft | - | picture | pulse vent with two wide trailing veils, fanned away from the stern's centre |
| E2 | pulse vent, mouth 0.3 across | 1 | 84.8 | 0.36 | -0.16 | exhaust aft | - | picture | pulse vent with two wide trailing veils, fanned away from the stern's centre |
| E3 | pulse vent, mouth 0.3 across | 1 | 84.8 | -0.36 | -0.16 | exhaust aft | - | picture | pulse vent with two wide trailing veils, fanned away from the stern's centre |

Totals: 3 gun mounts with 3 barrels; 0 launcher tubes; 3 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive flesh, callused olive hide (paint stage) | 0.9 | 81.6 | whole body |  |
| pale ochre bone | 1.4 | 71.7 | the spines of the glands and the spine bed |  |
| raw transition tissue | 1.4 | 71.7 | the vent lips and the spine collars |  |
| bile yellow-green light | 1.4 | 50.7 | deep in the three gland vents |  |
| bile yellow-green light | 81.6 | 100.0 | the vents and the membranes' roots |  |
| dim bile | 19.2 | 76.9 | the veins, the sac windows, the pores |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the broad lumpy body | 4.6 to 82.1 | -1.41 to 1.54 | -1.28 to 1.29 | dark olive flesh | a rounded nose bulb, broad in the middle, short at the tail |
| Spine gland W1 | 2.0 to 16.7 | -0.56 to 0.56 | -0.76 to 0.42 | flesh knoll | the prow gland |
| Spine gland W2 | 27.2 to 41.3 | -0.55 to 0.85 | 0.20 to 1.58 | flesh knoll | a dorsal spine gland |
| Spine gland W3 | 44.0 to 59.4 | -0.93 to 0.55 | 0.44 to 1.76 | flesh knoll | a dorsal spine gland |
| Spine bed | 60.5 to 72.6 | -0.77 to 0.37 | 0.43 to 1.48 | flesh knoll | the knoll aft of the dorsal glands |
| Back and shoulder knolls | 10.6 to 76.8 | -1.45 to 1.49 | -0.36 to 1.27 | flesh | lumps of grown flesh over the back and shoulders |
| Bile sac 1 (port) | 19.9 to 28.9 | 0.52 to 1.32 | -0.95 to -0.18 | flesh dome |  |
| Bile sac 2 (port) | 30.1 to 46.0 | 0.66 to 2.06 | -1.09 to 0.29 | flesh dome |  |
| Bile sac 3 (port) | 47.6 to 63.3 | 0.67 to 2.03 | -1.32 to -0.01 | flesh dome |  |
| Bile sac 4 (port) | 64.9 to 75.5 | 0.61 to 1.58 | -0.78 to 0.20 | flesh dome |  |
| Bile sac 1 (starboard) | 21.7 to 31.6 | -1.36 to -0.51 | -0.87 to 0.02 | flesh dome |  |
| Bile sac 2 (starboard) | 34.7 to 51.1 | -1.77 to -0.37 | -1.34 to 0.02 | flesh dome |  |
| Bile sac 3 (starboard) | 52.7 to 67.1 | -1.89 to -0.65 | -0.97 to 0.25 | flesh dome |  |
| Bile sac 4 (starboard) | 68.7 to 76.9 | -1.28 to -0.55 | -0.96 to -0.22 | flesh dome |  |
| Hanging sac 1 | 27.5 to 35.4 | -0.15 to 0.58 | -1.53 to -0.77 | flesh sac |  |
| Hanging sac 2 | 44.7 to 54.4 | -0.65 to 0.23 | -1.73 to -0.80 | flesh sac |  |
| Hanging sac 3 | 61.6 to 70.0 | -0.16 to 0.61 | -1.67 to -0.87 | flesh sac |  |
| Vents | 77.9 to 85.2 | -0.22 to 0.23 | -0.05 to 0.41 | flesh | three pulse vents at the short stern |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.75 (8% to 77%); upper deck 0.55 (13% to 76%).

Bulkhead and frame stations: F0 8.2%, F1 15.6%, F2 23.4%, F3 31.8%, F4 40.7%, F5 49.6%, F6 58.6%, F7 67.5%, F8 75.3%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| spine sac f (gland) | 6.7 to 17.1 | -0.42 to 0.42 | -0.46 to 0.26 | the prow gland's spine sac and bile gland: the forward volley's magazine |
| spine sac t1 (gland) | 25.3 to 34.1 | -0.23 to 0.53 | 0.67 to 1.23 | the fore dorsal gland's spine sac |
| spine sac t2 (gland) | 42.5 to 52.6 | -0.62 to 0.22 | 0.80 to 1.30 | the great dorsal gland's spine sac |
| ganglion (ganglion) | 15.9 to 24.7 | -0.35 to 0.35 | -0.03 to 0.53 | the Node: the knot of nerve that aims the glands |
| heart vat (vat) | 35.5 to 51.2 | -0.60 to 0.60 | -0.45 to 0.55 | the heart vat: the core (hp_core), lit bile-green |
| bile main (gland) | 27.6 to 50.7 | -0.75 to 0.75 | -1.15 to -0.45 | the main bile store, fed by the flank sacs |
| bile store 0 (gland) | 35.8 to 44.6 | 0.68 to 1.32 | -0.85 to -0.25 | the bile store behind a flank sac |
| bile store 1 (gland) | 54.2 to 63.0 | 0.68 to 1.32 | -0.85 to -0.25 | the bile store behind a flank sac |
| bile store 2 (gland) | 38.9 to 47.8 | -1.32 to -0.68 | -0.85 to -0.25 | the bile store behind a flank sac |
| bile store 3 (gland) | 56.8 to 65.6 | -1.32 to -0.68 | -0.85 to -0.25 | the bile store behind a flank sac |
| gut (gut) | 46.5 to 67.5 | -0.70 to 0.70 | -0.75 to 0.15 | the gut |
| regrowth p (organ) | 62.0 to 70.8 | 0.43 to 1.07 | 0.19 to 0.71 | regrowth tissue (regen 4) |
| regrowth s (organ) | 62.0 to 70.8 | -1.07 to -0.43 | 0.19 to 0.71 | regrowth tissue |
| pulse bladder (engroom) | 69.6 to 79.0 | -0.42 to 0.42 | -0.36 to 0.36 | the pulse bladder: fills and squeezes the three vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| nose bulb and prow gland | 0.32 | the thickest flesh, over the prow gland's root |
| back (the dorsal knolls) | 0.28 | knoll flesh over the spine sacs |
| flanks and sacs | 0.20 | thin over the sacs: they rupture first |
| belly | 0.20 |  |
| stern | 0.18 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 19.2 (seam wanders 16.1 to 21.9) | behind the nose bulb: the prow gland and the nose tear away, opening the spine sac and the Node |
| B-2 | 64.3 (seam wanders 62.2 to 67.5) | behind the great dorsal knoll: the stern tears away through the gut and the regrowth tissue, the aft sacs bursting first |

Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, then the body tears open along ragged lines (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 43.4 | 0.00 | 0.05 |  |  |  |
| hp_breach_0 | 12.9 | 0.67 | -0.04 | port | prow | open hide between the sacs |
| hp_breach_1 | 45.4 | -1.41 | -0.13 | stbd | mid | open hide between the sacs |
| hp_breach_2 | 71.8 | 1.08 | 0.13 | port | eng | open hide between the sacs |
| hp_rcs_0 | 13.4 | 0.72 | -0.23 | port |  |  |
| hp_rcs_1 | 13.4 | -0.71 | -0.23 | stbd |  |  |
| hp_rcs_2 | 76.5 | 0.81 | 0.26 | port |  |  |
| hp_rcs_3 | 76.5 | -0.79 | 0.26 | stbd |  |  |
| hp_board_0 | 37.0 | 1.21 | 0.47 | port |  |  |
| hp_board_1 | 37.0 | -1.23 | 0.50 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 174 objects, 22 parts, 756 close pairs, 262 rays, 3 guns, 0 sensor pairs, 0 turrets swept, 7 cones, 0 apertures, 3 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: bile yellow-green light over dark olive flesh, pale ochre bone.** R204 and the lore: the colour is fixed in the build; the picture's hide is grey-brown with amber light.
- **Three spine glands: one in the nose bulb (bioplasma F) and two on the dorsal knolls (both mounts of bioplasma T).** data.js b_spitter has two bioplasma slots; the picture shows three vents (nose, fore knoll, great knoll). The two dorsal vents share the all-round slot, two muzzles for its two shots, so each fires on every volley (R241 SPLIT).
- **The dorsal glands are fixed organs facing up, not turrets.** the slot is all round (T); a vent at the crown of a knoll spits every way at once, as C11's mane reaches every way (the Board's reading of R241 for organs, weapon_match FITS bioplasma: fixed).
- **Spines only round the three vents and on one spine bed aft of them; the long quills at the stern quarter and under the stern are cut.** every part has a job (R221): the spines round a vent are the shot it spits, the bed regrows them; the stern quills had none and would sit in the vents' wash.
- **Bile sacs: four a side along the lower flank, port and starboard at different sizes, three more hanging under the belly.** the picture's round sacs; uneven sides keep the asymmetric, scarred read (designs.md); every sac stores bile for the volleys.
- **Three pulse vents with two wide veils each at the short stern (the kit's veil trail, shared with C12, R333).** factions.md: no nozzles; the picture's three glow points and ragged membranes. The veils are cut to about 1.4 so the ship is 9.5 nose to veil tip, and fanned so none hangs in a neighbour's jet.
- **Siphons added, a pair forward and a pair aft.** a ship in space must turn; the picture shows none.
- **Boarding origins on the upper flanks at x 1.3, though b_spitter carries no tendril.** the export contract needs one boarding origin a side on every ship (check_export.py); the stinger variant (b_spitter_s, tendril T) is its own job.

## Designed here, not shown in the picture

- The variant b_spitter_s (Spitter stinger: bioplasma T, tendril T) is not built here; it needs a named variant (ships.md, issue 812).
- Q1p (attitude thruster quad): siphon behind the nose: swings the bow.
- Q2p (attitude thruster quad): siphon aft: swings the stern.
- Q1s (attitude thruster quad): siphon behind the nose: swings the bow.
- Q2s (attitude thruster quad): siphon aft: swings the stern.
