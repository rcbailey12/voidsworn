# chorus_C11: The bladeback (Chorus cruiser), build sheet

The Chorus (chorus) | class Cruiser | version 3 (round 3, face and massing), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus623\chorus_C11\chorus_C11\chorus_C11_blockout.blend`

**Length 14.5 world units** (data.js b_razor (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.515 |
| length side | 14.537 |
| length top | 14.537 |
| length disagreement percent | 0.0 |
| beam top | 7.375 |
| beam bow | 7.388 |
| beam disagreement percent | 0.09 |
| height side | 7.237 |
| height bow | 7.25 |
| height disagreement percent | 0.09 |
| widest at station percent | 32.3 |
| hull beam | 6.01 |
| hull depth | 4.93 |
| L to B hull | 2.41 |
| L to H hull | 2.94 |
| prow overhang | 1.64 |
| outline iou percent | 82.8 |
| mass outline iou percent | 82.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| M1 | spine volley, throat (fixed) | 1 barrel | 12.9 | 1.22 | -0.28 | forward | F bioplasma | picture | port throat: a fleshy rimmed hole flush in the face, a dark wet throat, the bile gland glowing deep inside |
| M2 | spine volley, throat (fixed) | 1 barrel | 12.9 | -1.22 | -0.28 | forward | F bioplasma | picture | starboard throat: a fleshy rimmed hole flush in the face, a dark wet throat, the bile gland glowing deep inside |
| T1 | boarding tendrils, mane of 30 hooked tendrils (fixed) | 3 barrels | 57.1 | 0.00 | 1.98 | forward | T tendril | picture | boarding tendrils: a mane of twenty-six hooked tendrils on a muscle crest behind the blade row, streaming up and aft (fixed: a mane reaches every way at once) |
| S1p | bile sac, 1.9 across | 1 | 33.0 | 2.68 | -0.95 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S1s | bile sac, 1.9 across | 1 | 33.0 | -2.62 | -0.93 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S2p | bile sac, 1.9 across | 1 | 51.5 | 2.16 | -0.76 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S2s | bile sac, 1.9 across | 1 | 51.5 | -2.21 | -0.78 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S3p | bile sac, 1.9 across | 1 | 68.8 | 1.45 | -0.51 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| S3s | bile sac, 1.9 across | 1 | 68.8 | -1.50 | -0.53 | - | - | picture | a bile reservoir in a wrinkled socket, fed forward to the throats by the veins |
| Q1p | attitude thruster quad | 1 | 19.2 | 2.35 | -1.37 | - | - | designed | siphon below the head: swings the bow |
| Q2p | attitude thruster quad | 1 | 77.7 | 1.08 | 0.30 | - | - | designed | siphon aft: swings the stern |
| Q1s | attitude thruster quad | 1 | 19.2 | -2.31 | -1.35 | - | - | designed | siphon below the head: swings the bow |
| Q2s | attitude thruster quad | 1 | 77.7 | -1.07 | 0.29 | - | - | designed | siphon aft: swings the stern |
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
| Hull: the short broad body | 11.3 to 86.7 | -3.01 to 3.00 | -2.45 to 2.48 | dark olive flesh | blunt at the bow, widest at 40 percent, tapering hard aft |
| Head: the face | 1.5 to 11.5 | -2.59 to 2.59 | -2.17 to 1.99 | flesh | the dome of the face, the throats flush in it |
| Mane | 57.1 to 75.7 | -0.34 to 0.34 | 1.10 to 1.84 | flesh crest, tendrils | the plume rising from the back behind the blades |
| Bile sac 1 (port) | 24.7 to 41.4 | 1.74 to 3.70 | -2.02 to 0.11 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 1 (starboard) | 24.7 to 41.4 | -3.60 to -1.70 | -2.00 to 0.14 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 2 (port) | 43.4 to 59.6 | 1.20 to 3.17 | -1.85 to 0.30 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 2 (starboard) | 43.4 to 59.6 | -3.23 to -1.27 | -1.85 to 0.29 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 3 (port) | 60.9 to 76.8 | 0.54 to 2.50 | -1.61 to 0.56 | flesh dome | a dome on the flank below the shoulder |
| Bile sac 3 (starboard) | 60.9 to 76.8 | -2.53 to -0.56 | -1.62 to 0.55 | flesh dome | a dome on the flank below the shoulder |
| Vent ring | 83.2 to 89.4 | 0.28 to 0.76 | 0.03 to 0.52 | flesh | six pulse vents round the stern's end |
| Bone crest | 18.1 to 51.9 | -0.52 to 0.61 | 1.87 to 3.43 | pale bone | knuckled bone crests down the back |
| Shoulder crests (port) | 24.1 to 58.2 | 1.01 to 2.15 | 1.33 to 2.36 | pale bone | shards along the shoulder |
| Shoulder crests (starboard) | 21.6 to 60.3 | -2.26 to -0.68 | 1.21 to 2.39 | pale bone | shards along the shoulder |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -1.00 (13% to 71%); upper deck 0.75 (13% to 75%).

Bulkhead and frame stations: F0 13.0%, F1 18.2%, F2 23.7%, F3 34.7%, F4 42.3%, F5 49.9%, F6 61.6%, F7 68.5%, F8 75.3%, F9 82.2%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| bile gland p (gland) | 11.6 to 20.6 | 0.50 to 1.50 | -0.65 to 0.35 | the port throat's bile gland: the shot's magazine |
| bile gland s (gland) | 11.6 to 20.6 | -1.50 to -0.50 | -0.65 to 0.35 | the starboard throat's bile gland |
| ganglion (ganglion) | 18.5 to 26.1 | -0.45 to 0.45 | 0.65 to 1.35 | the Node: the knot of nerve that steers the body |
| ram muscle (organ) | 22.3 to 54.0 | -0.50 to 0.50 | 1.03 to 1.67 | the muscle under the blade row (it drives the blades into a hull) |
| bile store 1p (gland) | 29.3 to 36.8 | 0.83 to 1.67 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 1s (gland) | 29.3 to 36.8 | -1.67 to -0.83 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 2p (gland) | 48.1 to 55.0 | 0.63 to 1.47 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 2s (gland) | 48.1 to 55.0 | -1.47 to -0.63 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 3p (gland) | 65.8 to 72.0 | 0.43 to 1.27 | -0.78 to -0.02 | the bile store behind the sac |
| bile store 3s (gland) | 65.8 to 72.0 | -1.27 to -0.43 | -0.78 to -0.02 | the bile store behind the sac |
| heart vat (vat) | 39.9 to 53.0 | -0.75 to 0.75 | -0.70 to 0.60 | the heart vat: the core (hp_core), lit bile-green |
| gut fore (gut) | 20.9 to 41.6 | -0.85 to 0.85 | -1.55 to -0.45 | the gut |
| gut aft (gut) | 53.3 to 69.8 | -0.80 to 0.80 | -1.25 to -0.25 | the second stomach |
| regrowth p (organ) | 65.7 to 72.6 | 0.47 to 1.23 | 0.23 to 0.87 | regrowth tissue (regen 6) |
| regrowth s (organ) | 65.7 to 72.6 | -1.23 to -0.47 | 0.23 to 0.87 | regrowth tissue |
| mane muscle (organ) | 59.8 to 71.6 | -0.40 to 0.40 | 0.64 to 1.16 | the mane's root muscle |
| pulse bladder (engroom) | 76.0 to 85.0 | -0.55 to 0.55 | -0.45 to 0.45 | the pulse bladder: fills and squeezes the six vents (the engine room) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| head and throats | 0.40 | the thickest flesh, over the throat roots |
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
| hp_breach_0 | 23.0 | 2.90 | 0.23 | port | prow | open hide beside a sac |
| hp_breach_1 | 41.6 | -1.95 | -1.50 | stbd | mid | open hide beside a sac |
| hp_breach_2 | 60.2 | 1.46 | -1.14 | port | mid | open hide beside a sac |
| hp_breach_3 | 74.0 | -1.24 | -0.42 | stbd | eng | open hide beside a sac |
| hp_rcs_0 | 19.2 | 2.39 | -1.40 | port |  |  |
| hp_rcs_1 | 19.2 | -2.35 | -1.38 | stbd |  |  |
| hp_rcs_2 | 77.8 | 1.12 | 0.31 | port |  |  |
| hp_rcs_3 | 77.8 | -1.11 | 0.31 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 152 objects, 19 parts, 494 close pairs, 268 rays, 3 guns, 0 turrets swept, 10 cones, 0 apertures, 2 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Colour: bile yellow-green light over dark olive flesh, pale ochre bone and ochre chitin.** R204 and the lore: the colour is fixed in the build; the picture's hide is green-brown with amber light.
- **The two throats are one battery, the Spine volley (bioplasma F): fleshy rimmed holes flush in a domed face.** data.js b_razor has one bioplasma slot; both throats fire it (two muzzles, one slot). R184's single throat stays a later fleet-sheet question; the accepted picture has two.
- **The plume of hair on the back is the boarding tendrils (tendril T), a fixed mane on a muscle crest.** the slot is all round; a mane reaches every way at once, so it is fixed, not a turret. Its roots stop well forward of the stern so no tendril hangs in a vent's jet.
- **The bone ridge is a run of knuckled bone crests of uneven size growing from an open wound channel, with smaller crests along each shoulder.** the bladeback closes and cuts (Razormaw); the plan draws separate pale plates, the profile a row (README 8b: the profile is the view of record).
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
