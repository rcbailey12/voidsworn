# chorus_C11: The bladeback (Chorus cruiser), build sheet

The Chorus (chorus) | class Cruiser | version 1 (first sheet), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus623\chorus_C11\chorus_C11\chorus_C11_blockout.blend`

**Length 14.5 world units** (data.js b_razor (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.513 |
| length side | 14.537 |
| length top | 14.537 |
| length disagreement percent | 0.0 |
| beam top | 7.162 |
| beam bow | 7.162 |
| beam disagreement percent | 0.0 |
| height side | 7.287 |
| height bow | 7.3 |
| height disagreement percent | 0.09 |
| widest at station percent | 33.0 |
| hull beam | 5.24 |
| hull depth | 4.42 |
| L to B hull | 2.77 |
| L to H hull | 3.28 |
| prow overhang | 0.83 |
| outline iou percent | 82.2 |
| mass outline iou percent | 80.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| M1 | spine volley, throat (fixed) | 1 barrel | 12.0 | 1.25 | -0.20 | forward | F bioplasma | picture | port throat: a flared rim, an inner sphincter, a ring of spines, the bile gland glowing deep inside |
| M2 | spine volley, throat (fixed) | 1 barrel | 12.0 | -1.25 | -0.20 | forward | F bioplasma | picture | starboard throat: a flared rim, an inner sphincter, a ring of spines, the bile gland glowing deep inside |
| T1 | boarding tendrils, mane of 30 hooked tendrils (fixed) | 3 barrels | 57.1 | 0.00 | 2.20 | forward | T tendril | picture | boarding tendrils: a mane of twenty-six hooked tendrils on a muscle crest behind the blade row, streaming up and aft (fixed: a mane reaches every way at once) |
| S1p | bile sac, 1.9 across | 1 | 33.0 | 2.49 | -0.70 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S1s | bile sac, 1.9 across | 1 | 33.0 | -2.49 | -0.70 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S2p | bile sac, 1.9 across | 1 | 51.5 | 2.43 | -0.68 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S2s | bile sac, 1.9 across | 1 | 51.5 | -2.43 | -0.68 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S3p | bile sac, 1.9 across | 1 | 68.8 | 1.92 | -0.53 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S3s | bile sac, 1.9 across | 1 | 68.8 | -1.92 | -0.53 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| Q1p | attitude thruster quad | 1 | 19.2 | 2.11 | -1.30 | - | - | designed | siphon below the head: swings the bow |
| Q2p | attitude thruster quad | 1 | 77.7 | 1.50 | 0.41 | - | - | designed | siphon aft: swings the stern |
| Q1s | attitude thruster quad | 1 | 19.2 | -2.11 | -1.30 | - | - | designed | siphon below the head: swings the bow |
| Q2s | attitude thruster quad | 1 | 77.7 | -1.50 | 0.41 | - | - | designed | siphon aft: swings the stern |
| E1 | pulse vent, mouth 0.4 across | 1 | 89.1 | 0.52 | 0.28 | exhaust aft | - | picture | pulse vent with three glowing filaments splayed outward |
| E2 | pulse vent, mouth 0.4 across | 1 | 89.1 | 0.00 | 0.54 | exhaust aft | - | picture | pulse vent with three glowing filaments splayed outward |
| E3 | pulse vent, mouth 0.4 across | 1 | 89.1 | -0.52 | 0.28 | exhaust aft | - | picture | pulse vent with three glowing filaments splayed outward |
| E4 | pulse vent, mouth 0.4 across | 1 | 89.1 | -0.52 | -0.24 | exhaust aft | - | picture | pulse vent with three glowing filaments splayed outward |
| E5 | pulse vent, mouth 0.4 across | 1 | 89.1 | -0.00 | -0.50 | exhaust aft | - | picture | pulse vent with three glowing filaments splayed outward |
| E6 | pulse vent, mouth 0.4 across | 1 | 89.1 | 0.52 | -0.24 | exhaust aft | - | picture | pulse vent with three glowing filaments splayed outward |

Totals: 3 gun mounts with 5 barrels; 0 launcher tubes; 6 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive flesh, callused olive hide (paint stage) | 0.6 | 89.1 | whole body |  |
| pale ochre bone | 18.8 | 66.4 | the blade rows |  |
| raw transition tissue | 17.5 | 58.8 | the wound along the spine |  |
| bile yellow-green light | 0.6 | 6.4 | the throat glands |  |
| bile yellow-green light | 89.1 | 100.0 | the vents and the filament nodes |  |
| dim bile | 9.2 | 67.8 | the veins, the sac windows, the acid pores |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the short broad body | 5.8 to 86.7 | -2.62 to 2.62 | -2.27 to 2.15 | dark olive flesh | blunt at the bow, widest at 40 percent, tapering hard aft |
| Port throat | 0.0 to 14.0 | -0.06 to 2.56 | -1.50 to 0.97 | flesh rim | a flared rim 2.7 across |
| Starboard throat | 0.1 to 14.0 | -2.51 to 0.05 | -1.49 to 1.02 | flesh rim | a flared rim 2.7 across |
| Mane | 57.1 to 75.7 | -0.34 to 0.34 | 1.41 to 2.06 | flesh crest, tendrils | the plume rising from the back behind the blades |
| Bile sac 1 (port) | 25.0 to 41.1 | 1.66 to 3.53 | -1.81 to 0.42 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 1 (starboard) | 25.0 to 41.1 | -3.51 to -1.67 | -1.81 to 0.42 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 2 (port) | 43.4 to 59.6 | 1.57 to 3.47 | -1.79 to 0.44 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 2 (starboard) | 43.4 to 59.6 | -3.49 to -1.57 | -1.79 to 0.44 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 3 (port) | 61.1 to 76.6 | 1.08 to 2.99 | -1.65 to 0.60 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 3 (starboard) | 61.1 to 76.6 | -2.97 to -1.06 | -1.64 to 0.60 | flesh dome | a dome on the flank below the shoulder |
| Vent ring | 83.2 to 89.4 | 0.28 to 0.76 | 0.03 to 0.52 | flesh | six pulse vents round the stern's end |
| Head: the brow | 1.5 to 15.5 | -1.91 to 1.94 | 0.35 to 1.87 | flesh | the brow bulging over the throats |
| Head: the chin | 1.8 to 15.1 | -1.58 to 1.60 | -1.95 to -0.85 | flesh | the chin under the throats |
| Blade row | 16.4 to 57.4 | -0.44 to 0.42 | 2.01 to 3.14 | pale bone | the jagged bone crest down the back |
| Shoulder blades (port) | 21.1 to 70.3 | 1.36 to 1.82 | 1.27 to 2.28 | pale bone | shards lying back along the shoulder |
| Shoulder blades (starboard) | 22.3 to 72.4 | -2.01 to -1.28 | 1.40 to 2.33 | pale bone | shards lying back along the shoulder |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.00 (9% to 71%); upper deck 0.75 (10% to 77%).

Bulkhead and frame stations: F0 8.5%, F1 16.1%, F2 23.7%, F3 34.7%, F4 42.3%, F5 49.9%, F6 61.6%, F7 68.5%, F8 75.3%, F9 82.2%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| bile gland p (gland) | 11.6 to 20.6 | 0.50 to 1.50 | -0.65 to 0.35 | the port throat's bile gland: the shot's magazine |
| bile gland s (gland) | 11.6 to 20.6 | -1.50 to -0.50 | -0.65 to 0.35 | the starboard throat's bile gland |
| ganglion (ganglion) | 18.5 to 26.1 | -0.45 to 0.45 | 0.65 to 1.35 | the Node: the knot of nerve that steers the body |
| ram muscle (organ) | 22.3 to 54.0 | -0.50 to 0.50 | 1.03 to 1.67 | the muscle under the blade row (it drives the blades into a hull) |
| bile store 1p (gland) | 29.2 to 36.8 | 0.83 to 1.67 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 1s (gland) | 29.2 to 36.8 | -1.67 to -0.83 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 2p (gland) | 48.1 to 55.0 | 0.71 to 1.55 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 2s (gland) | 48.1 to 55.0 | -1.55 to -0.71 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 3p (gland) | 65.8 to 72.0 | 0.59 to 1.43 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 3s (gland) | 65.8 to 72.0 | -1.43 to -0.59 | -0.78 to -0.02 | the bile store behind the sac |
| heart vat (vat) | 39.9 to 53.0 | -0.75 to 0.75 | -0.70 to 0.60 | the heart vat: the core (hp_core), lit bile-green |
| gut fore (gut) | 20.9 to 41.6 | -0.85 to 0.85 | -1.55 to -0.45 | the gut |
| gut aft (gut) | 53.3 to 69.8 | -0.80 to 0.80 | -1.25 to -0.25 | the second stomach |
| regrowth p (organ) | 65.7 to 72.6 | 0.47 to 1.23 | 0.23 to 0.87 | regrowth tissue (regen 6) |
| regrowth s (organ) | 65.7 to 72.6 | -1.23 to -0.47 | 0.23 to 0.87 | regrowth tissue |
| mane muscle (organ) | 59.5 to 74.0 | -0.42 to 0.42 | 0.72 to 1.28 | the mane's root muscle |
| pulse bladder (engroom) | 76.0 to 85.0 | -0.55 to 0.55 | -0.45 to 0.45 | the pulse bladder: fills and squeezes the six vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| brow and throats | 0.40 | the thickest flesh, over the throat roots |
| back (the blade row) | 0.35 | bone under the wound channel |
| flanks and sacs | 0.25 | thin over the sacs: they rupture first |
| belly | 0.25 |  |
| stern | 0.20 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 29.9 (seam wanders 27.8 to 31.9) | behind the head: the throats and the brow tear away, opening the bile glands and the Node |
| B-2 | 54.7 (seam wanders 52.6 to 56.7) | ahead of the mane: the stern half tears away through the heart vat's aft end, the sacs bursting first |

Flesh, bone and organs through the whole body (R215), hidden until a piece breaks: bone hoops for frames, membrane septa for decks, organs and chambers that never reach the skin. The Chorus bursts and tears: sacs rupture first, then the body tears open along ragged lines (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 46.4 | 0.00 | -0.05 |  |  |  |
| hp_breach_0 | 23.0 | 2.61 | 0.22 | port | prow | open hide beside a sac |
| hp_breach_1 | 41.6 | -1.95 | -1.60 | stbd | mid | open hide beside a sac |
| hp_breach_2 | 60.2 | 1.78 | -1.47 | port | mid | open hide beside a sac |
| hp_breach_3 | 74.0 | -1.67 | -0.65 | stbd | eng | open hide beside a sac |
| hp_rcs_0 | 19.2 | 2.15 | -1.33 | port |  |  |
| hp_rcs_1 | 19.2 | -2.15 | -1.33 | stbd |  |  |
| hp_rcs_2 | 77.8 | 1.54 | 0.42 | port |  |  |
| hp_rcs_3 | 77.8 | -1.54 | 0.42 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 149 objects, 19 parts, 591 close pairs, 263 rays, 3 guns, 0 turrets swept, 10 cones, 0 apertures, 2 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: bile yellow-green light over dark olive flesh, pale ochre bone and ochre chitin.** R204 and the lore: the colour is fixed in the build; the picture's hide is green-brown with amber light.
- **The two throats are one battery, the Spine volley (bioplasma F).** data.js b_razor has one bioplasma slot; both throats fire it (two muzzles, one slot). R184's single throat stays a later fleet-sheet question; the accepted picture has two.
- **The plume of hair on the back is the boarding tendrils (tendril T), a fixed mane on a muscle crest.** the slot is all round; a mane reaches every way at once, so it is fixed, not a turret. Its roots stop well forward of the stern so no tendril hangs in a vent's jet.
- **The bone ridge is a row of ram blades growing from an open wound channel, with smaller blades along each shoulder.** the bladeback closes and cuts (Razormaw); the plan draws separate pale plates, the profile a row (README 8b: the profile is the view of record).
- **The domes are bile sacs feeding the throats; veins run forward to them.** every part has a job (R221): the picture's domes become the throats' reservoirs.
- **The stern ends in a ring of six pulse vents, each with three glowing filaments splayed outward.** factions.md: no nozzles; the picture's amber nodes and filament plume. The filaments are cut to about a third of the picture's so the ship is 14.5 throat rim to filament tip, and splayed so none hangs in a neighbour's jet.
- **Siphons added, a pair forward and a pair aft.** a ship in space must turn; the picture shows none.
- **The small spines along the lower stern are cut.** no job (R221).

## Designed here, not shown in the picture

- The belly is designed here; the sheet has no underside view.
- Q1p (attitude thruster quad): siphon below the head: swings the bow.
- Q2p (attitude thruster quad): siphon aft: swings the stern.
- Q1s (attitude thruster quad): siphon below the head: swings the bow.
- Q2s (attitude thruster quad): siphon aft: swings the stern.
