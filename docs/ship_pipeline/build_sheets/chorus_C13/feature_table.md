# chorus_C13: The spitter (Chorus destroyer), build sheet

The Chorus (chorus) | class Destroyer | version 1 (first build sheet (issue 1154)), 2026-11-19 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus1154\chorus_C13\chorus_C13\chorus_C13_blockout.blend`

**Length 9.5 world units** (data.js b_spitter (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bioplasma | T | 2 | W2 (1), W3 (1) |
| 1 | bioplasma | F | 2 | W1 (1) |

| Check | Value |
|---|---|
| model length | 9.525 |
| length side | 9.55 |
| length top | 9.55 |
| length disagreement percent | 0.0 |
| beam top | 4.75 |
| beam bow | 4.938 |
| beam disagreement percent | 1.97 |
| height side | 4.412 |
| height bow | 4.412 |
| height disagreement percent | 0.0 |
| widest at station percent | 57.4 |
| hull beam | 3.79 |
| hull depth | 2.96 |
| L to B hull | 2.51 |
| L to H hull | 3.21 |
| prow overhang | 0.63 |
| outline iou percent | 81.8 |
| mass outline iou percent | 82.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| W1 | spine volley, throat (fixed) | 1 barrel | 13.1 | 0.03 | -0.40 | forward, +26 elev | F bioplasma | picture | the prow gland: a knoll grown into the nose bulb, a puckered vent at its crown, short spines round it; it spits forward |
| W2 | spine volley, throat (fixed) | 1 barrel | 32.9 | 0.14 | 0.95 | 22 deg off the bow to port, +71 elev | T bioplasma | picture | a dorsal spine gland: a puckered vent at the crown of a knoll on the back, short spines out of the knoll round it; it faces up and spits every way |
| W3 | spine volley, throat (fixed) | 1 barrel | 47.7 | -0.23 | 1.24 | 140 deg off the bow to starboard, +81 elev | T bioplasma | picture | a dorsal spine gland: a puckered vent at the crown of a knoll on the back, short spines out of the knoll round it; it faces up and spits every way |
| SB1 | spine bed, 1.2 across | 1 | 66.9 | -0.25 | 1.11 | - | - | picture | a knoll aft of the glands studded with growing spines: the spent spines regrow here (regrow, regen 4) |
| S1p | bile sac, 1.0 across | 1 | 22.6 | 1.09 | -0.64 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S2p | bile sac, 1.6 across | 1 | 36.8 | 1.73 | -0.41 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S3p | bile sac, 1.5 across | 1 | 55.7 | 1.68 | -0.73 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S4p | bile sac, 1.2 across | 1 | 70.4 | 1.41 | -0.33 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S1s | bile sac, 1.1 across | 1 | 25.2 | -1.17 | -0.47 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S2s | bile sac, 1.6 across | 1 | 42.0 | -1.37 | -0.73 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S3s | bile sac, 1.4 across | 1 | 59.9 | -1.62 | -0.39 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| S4s | bile sac, 0.9 across | 1 | 73.5 | -1.12 | -0.69 | - | - | picture | a round bile sac bulging from the lower flank; it swells before a volley |
| H1 | hanging sac, 0.9 across | 1 | 30.6 | 0.26 | -1.20 | - | - | picture | a bile sac hanging under the belly: the spitter's deep reserve |
| H2 | hanging sac, 1.1 across | 1 | 49.4 | -0.27 | -1.29 | - | - | picture | a bile sac hanging under the belly: the spitter's deep reserve |
| H3 | hanging sac, 1.0 across | 1 | 66.0 | 0.29 | -1.30 | - | - | picture | a bile sac hanging under the belly: the spitter's deep reserve |
| Q1p | attitude thruster quad | 1 | 13.6 | 1.01 | -0.29 | - | - | designed | siphon behind the nose: swings the bow |
| Q2p | attitude thruster quad | 1 | 76.5 | 1.01 | 0.28 | - | - | designed | siphon aft: swings the stern |
| Q1s | attitude thruster quad | 1 | 13.6 | -1.00 | -0.29 | - | - | designed | siphon behind the nose: swings the bow |
| Q2s | attitude thruster quad | 1 | 76.5 | -0.98 | 0.29 | - | - | designed | siphon aft: swings the stern |
| E1 | pulse vent, mouth 0.3 across | 1 | 85.1 | 0.00 | 0.18 | exhaust aft | - | picture | pulse vent with two trailing membrane veils, splayed away from the stern's centre |
| E2 | pulse vent, mouth 0.3 across | 1 | 85.1 | 0.36 | -0.16 | exhaust aft | - | picture | pulse vent with two trailing membrane veils, splayed away from the stern's centre |
| E3 | pulse vent, mouth 0.3 across | 1 | 85.1 | -0.36 | -0.16 | exhaust aft | - | picture | pulse vent with two trailing membrane veils, splayed away from the stern's centre |

Totals: 3 gun mounts with 3 barrels; 0 launcher tubes; 3 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive flesh, callused olive hide (paint stage) | 1.1 | 81.9 | whole body |  |
| pale ochre bone | 1.6 | 71.9 | the spines of the glands and the spine bed |  |
| raw transition tissue | 1.6 | 71.9 | the vent lips and the spine collars |  |
| bile yellow-green light | 1.6 | 51.0 | deep in the three gland vents |  |
| bile yellow-green light | 81.9 | 100.0 | the vents and the membranes' roots |  |
| dim bile | 19.5 | 77.2 | the veins, the sac windows, the pores |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the broad lumpy body | 6.6 to 81.9 | -1.81 to 1.98 | -1.46 to 1.50 | dark olive flesh | a rounded nose bulb, broad in the middle, short at the tail |
| Spine gland W1 | 2.5 to 17.5 | -0.59 to 0.61 | -0.85 to 0.43 | flesh knoll | the prow gland |
| Spine gland W2 | 25.3 to 38.7 | -0.47 to 0.87 | 0.57 to 1.95 | flesh knoll | a dorsal spine gland |
| Spine gland W3 | 40.7 to 55.2 | -0.95 to 0.45 | 0.86 to 2.23 | flesh knoll | a dorsal spine gland |
| Spine bed | 60.8 to 72.9 | -0.83 to 0.31 | 0.60 to 1.66 | flesh knoll | the knoll aft of the dorsal glands |
| Back and shoulder knolls | 9.0 to 78.2 | -1.84 to 1.89 | -0.07 to 1.64 | flesh | lumps of grown flesh over the back and shoulders |
| Bile sac 1 (port) | 17.1 to 28.0 | 0.62 to 1.61 | -1.13 to -0.17 | flesh dome |  |
| Bile sac 2 (port) | 27.5 to 45.9 | 0.93 to 2.56 | -1.21 to 0.40 | flesh dome |  |
| Bile sac 3 (port) | 47.1 to 64.3 | 0.99 to 2.46 | -1.46 to -0.03 | flesh dome |  |
| Bile sac 4 (port) | 64.1 to 76.9 | 0.84 to 2.06 | -0.94 to 0.29 | flesh dome |  |
| Bile sac 1 (starboard) | 19.3 to 31.4 | -1.74 to -0.65 | -1.03 to 0.09 | flesh dome |  |
| Bile sac 2 (starboard) | 33.0 to 51.2 | -2.17 to -0.61 | -1.51 to 0.01 | flesh dome |  |
| Bile sac 3 (starboard) | 52.3 to 68.0 | -2.33 to -0.97 | -1.05 to 0.28 | flesh dome |  |
| Bile sac 4 (starboard) | 68.8 to 78.4 | -1.58 to -0.70 | -1.14 to -0.25 | flesh dome |  |
| Hanging sac 1 | 25.8 to 35.4 | -0.17 to 0.71 | -1.82 to -0.90 | flesh sac |  |
| Hanging sac 2 | 43.4 to 55.2 | -0.82 to 0.26 | -2.05 to -0.92 | flesh sac |  |
| Hanging sac 3 | 60.8 to 71.4 | -0.18 to 0.77 | -1.98 to -0.98 | flesh sac |  |
| Vents | 78.2 to 85.5 | -0.22 to 0.23 | -0.05 to 0.41 | flesh | three pulse vents at the short stern |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.75 (8% to 77%); upper deck 0.55 (13% to 76%).

Bulkhead and frame stations: F0 8.4%, F1 15.8%, F2 23.7%, F3 32.1%, F4 41.0%, F5 49.9%, F6 58.8%, F7 67.7%, F8 75.6%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| spine sac f (gland) | 6.9 to 17.4 | -0.42 to 0.42 | -0.46 to 0.26 | the prow gland's spine sac and bile gland: the forward volley's magazine |
| spine sac t1 (gland) | 25.5 to 34.4 | -0.23 to 0.53 | 0.67 to 1.23 | the fore dorsal gland's spine sac |
| spine sac t2 (gland) | 42.8 to 52.8 | -0.62 to 0.22 | 0.80 to 1.30 | the great dorsal gland's spine sac |
| ganglion (ganglion) | 16.1 to 24.9 | -0.35 to 0.35 | -0.03 to 0.53 | the Node: the knot of nerve that aims the glands |
| heart vat (vat) | 35.7 to 51.5 | -0.60 to 0.60 | -0.45 to 0.55 | the heart vat: the core (hp_core), lit bile-green |
| bile main (gland) | 27.9 to 51.0 | -0.75 to 0.75 | -1.15 to -0.45 | the main bile store, fed by the flank sacs |
| bile store 0 (gland) | 36.0 to 44.9 | 0.68 to 1.32 | -0.85 to -0.25 | the bile store behind a flank sac |
| bile store 1 (gland) | 54.4 to 63.2 | 0.68 to 1.32 | -0.85 to -0.25 | the bile store behind a flank sac |
| bile store 2 (gland) | 39.2 to 48.0 | -1.32 to -0.68 | -0.85 to -0.25 | the bile store behind a flank sac |
| bile store 3 (gland) | 57.0 to 65.9 | -1.32 to -0.68 | -0.85 to -0.25 | the bile store behind a flank sac |
| gut (gut) | 46.8 to 67.7 | -0.70 to 0.70 | -0.75 to 0.15 | the gut |
| regrowth p (organ) | 62.3 to 71.1 | 0.43 to 1.07 | 0.19 to 0.71 | regrowth tissue (regen 4) |
| regrowth s (organ) | 62.3 to 71.1 | -1.07 to -0.43 | 0.19 to 0.71 | regrowth tissue |
| pulse bladder (engroom) | 69.8 to 79.3 | -0.42 to 0.42 | -0.36 to 0.36 | the pulse bladder: fills and squeezes the three vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| nose bulb and prow gland | 0.32 | the thickest flesh, over the prow gland's root |
| back (the dorsal knolls) | 0.28 | knoll flesh over the spine sacs |
| flanks and sacs | 0.20 | thin over the sacs: they rupture first |
| belly | 0.20 |  |
| stern | 0.18 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 19.5 (seam wanders 16.3 to 22.1) | behind the nose bulb: the prow gland and the nose tear away, opening the spine sac and the Node |
| B-2 | 60.9 (seam wanders 58.8 to 64.1) | behind the great dorsal knoll: the stern tears away through the gut and the regrowth tissue, the aft sacs bursting first |

Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, then the body tears open along ragged lines (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 43.6 | 0.00 | 0.05 |  |  |  |
| hp_breach_0 | 13.1 | 1.01 | -0.04 | port | prow | open hide between the sacs |
| hp_breach_1 | 45.7 | -1.81 | -0.13 | stbd | mid | open hide between the sacs |
| hp_breach_2 | 72.1 | 1.41 | 0.14 | port | eng | open hide between the sacs |
| hp_rcs_0 | 13.7 | 1.06 | -0.30 | port |  |  |
| hp_rcs_1 | 13.7 | -1.05 | -0.30 | stbd |  |  |
| hp_rcs_2 | 76.8 | 1.05 | 0.30 | port |  |  |
| hp_rcs_3 | 76.8 | -1.01 | 0.30 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 174 objects, 22 parts, 781 close pairs, 262 rays, 3 guns, 0 sensor pairs, 0 turrets swept, 7 cones, 0 apertures, 3 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: bile yellow-green light over dark olive flesh, pale ochre bone.** R204 and the lore: the colour is fixed in the build; the picture's hide is grey-brown with amber light.
- **Three spine glands: one in the nose bulb (bioplasma F) and two on the dorsal knolls (both mounts of bioplasma T).** data.js b_spitter has two bioplasma slots; the picture shows three vents (nose, fore knoll, great knoll). The two dorsal vents share the all-round slot, two muzzles for its two shots, so each fires on every volley (R241 SPLIT).
- **The dorsal glands are fixed organs facing up, not turrets.** the slot is all round (T); a vent at the crown of a knoll spits every way at once, as C11's mane reaches every way (the Board's reading of R241 for organs, weapon_match FITS bioplasma: fixed).
- **Spines only round the three vents and on one spine bed aft of them; the long quills at the stern quarter and under the stern are cut.** every part has a job (R221): the spines round a vent are the shot it spits, the bed regrows them; the stern quills had none and would sit in the vents' wash.
- **Bile sacs: four a side along the lower flank, port and starboard at different sizes, three more hanging under the belly.** the picture's round sacs; uneven sides keep the asymmetric, scarred read (designs.md); every sac stores bile for the volleys.
- **Three pulse vents with two membrane veils each at the short stern.** factions.md: no nozzles; the picture's three glow points and ragged membranes. The membranes are cut to about 1.8 so the ship is 9.5 nose to membrane tip, and splayed so none hangs in a neighbour's jet.
- **Siphons added, a pair forward and a pair aft.** a ship in space must turn; the picture shows none.
- **No boarding origins: data.js b_spitter has no tendril, so the ship has nothing that boards.** the stinger variant (b_spitter_s, tendril T) is its own job.

## Designed here, not shown in the picture

- The variant b_spitter_s (Spitter stinger: bioplasma T, tendril T) is not built here; it needs a named variant (ships.md, issue 812).
- Q1p (attitude thruster quad): siphon behind the nose: swings the bow.
- Q2p (attitude thruster quad): siphon aft: swings the stern.
- Q1s (attitude thruster quad): siphon behind the nose: swings the bow.
- Q2s (attitude thruster quad): siphon aft: swings the stern.
