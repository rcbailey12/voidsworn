# deathless_E14: Eclipse flare (the annulus destroyer), build sheet

Eclipse (deathless) | class Destroyer | version 1 (first sheet (issue 739)), 2026-11-15 | blockout: built in the cloud sandbox (Blender 5.3 bpy module, Cycles CPU), not kept; `build.py -- deathless_E14 <out> render` rebuilds it

**Length 9.5 world units** (data.js d_jackal (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5 (drawn x SHIP_K 1.6 = 15.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | gauss | T | 3 | T1 (2) |
| 1 | gauss | F | 3 | F1 (2) |

| Check | Value |
|---|---|
| model length | 9.522 |
| length side | 9.55 |
| length top | 9.55 |
| length disagreement percent | 0.0 |
| beam top | 6.025 |
| beam bow | 6.025 |
| beam disagreement percent | 0.0 |
| height side | 1.913 |
| height bow | 1.913 |
| height disagreement percent | 0.0 |
| widest at station percent | 29.9 |
| hull beam | 1.1 |
| hull depth | 1.05 |
| L to B hull | 8.64 |
| L to H hull | 9.05 |
| prow overhang | 3.53 |
| outline iou percent | 59.3 |
| mass outline iou percent | 58.3 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| S1 | truss strut, 1.3 long | 1 | 23.7 | 0.32 | 0.00 | - | - | designed | truss spoke from the gun heart to the hoop, port |
| S2 | truss strut, 1.4 long | 1 | 39.3 | 0.29 | 0.00 | - | - | designed | truss spoke from the spar to the hoop, port |
| S3 | truss strut, 1.3 long | 1 | 23.7 | -0.32 | 0.00 | - | - | designed | truss spoke from the gun heart to the hoop, starboard |
| S4 | truss strut, 1.4 long | 1 | 39.3 | -0.29 | 0.00 | - | - | designed | truss spoke from the spar to the hoop, starboard |
| C1 | caged core of trapped light, 1.0 across | 1 | 31.5 | 0.00 | 0.00 | - | - | picture | the trapped light core at the ring's centre, the spar entering its hub collars |
| F1 | null cannon, twin turret | 2 barrels | 18.4 | 0.00 | 0.55 | forward, +3 elev | F gauss | picture | the forward null cannon (gauss F) on the gun heart's roof, turning only through the data arc F (60 either side of the bow), firing over the ring's bow plates |
| T1 | null cannon, twin turret | 2 barrels | 69.3 | 0.00 | 0.47 | forward, +4 elev | T gauss | picture | the aft null cannon (gauss T) on its saddle aft of the ring, firing over the ring and turning all round |
| E1 | engine, bell 1.2 across | 1 | 99.8 | 0.00 | 0.03 | exhaust aft | - | picture | the broad eclipse ring of pale light at the stern, larger than the mote's; no flame |
| Q1p | attitude thruster quad | 1 | 13.7 | 0.30 | -0.23 | - | - | designed | gun heart lower chamfer, firing down and out under the ring |
| Q2p | attitude thruster quad | 1 | 85.4 | 0.47 | -0.42 | - | - | designed | stern block lower chamfer, firing down and out |
| L0p | running light | 1 | 79.8 | 0.52 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| L1p | running light | 1 | 84.5 | 0.54 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| V1p | louvre panel 0.3 x 0.2 | 1 | 80.3 | 0.52 | -0.20 | - | - | picture | heat slot panel low on the block flank |
| H1p | square hatch 0.2 | 1 | 80.9 | 0.18 | -0.50 | - | - | picture | belly hatch on the stern block |
| Q1s | attitude thruster quad | 1 | 13.7 | -0.30 | -0.23 | - | - | designed | gun heart lower chamfer, firing down and out under the ring |
| Q2s | attitude thruster quad | 1 | 85.4 | -0.47 | -0.42 | - | - | designed | stern block lower chamfer, firing down and out |
| L0s | running light | 1 | 79.8 | -0.52 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| L1s | running light | 1 | 84.5 | -0.54 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| V1s | louvre panel 0.3 x 0.2 | 1 | 80.3 | -0.52 | -0.20 | - | - | picture | heat slot panel low on the block flank |
| H1s | square hatch 0.2 | 1 | 80.9 | -0.18 | -0.50 | - | - | picture | belly hatch on the stern block |
| D1 | framed deck box 0.2 x 0.1 | 1 | 17.5 | 1.33 | 0.12 | - | - | picture | repair drone cradle on the hoop, in the gap under the plates' inner edge |
| DL1 | running light | 1 | 17.5 | 1.33 | 0.22 | - | - | picture | the drone's green work light |
| D2 | framed deck box 0.2 x 0.1 | 1 | 45.5 | 1.33 | 0.12 | - | - | picture | repair drone cradle on the hoop, in the gap under the plates' inner edge |
| DL2 | running light | 1 | 45.5 | 1.33 | 0.22 | - | - | picture | the drone's green work light |
| D3 | framed deck box 0.2 x 0.1 | 1 | 45.5 | -1.33 | 0.12 | - | - | picture | repair drone cradle on the hoop, in the gap under the plates' inner edge |
| DL3 | running light | 1 | 45.5 | -1.33 | 0.22 | - | - | picture | the drone's green work light |
| D4 | framed deck box 0.2 x 0.1 | 1 | 17.5 | -1.33 | 0.12 | - | - | picture | repair drone cradle on the hoop, in the gap under the plates' inner edge |
| DL4 | running light | 1 | 17.5 | -1.33 | 0.22 | - | - | picture | the drone's green work light |

Totals: 2 gun mounts with 4 barrels; 0 launcher tubes; 1 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| violet-black shade plates, deep violet spar and gun heart (paint stage) | 0.0 | 99.8 | whole ship |  |
| green-white corona line | 0.0 | 63.0 | every ring plate's outer rim and its layer's rim |  |
| core light | 25.7 | 37.3 | the core in its cage |  |
| drone lights, green | 7.9 | 55.1 | the four drone cradles on the hoop |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the spar and the stern block | 37.1 to 87.7 | -0.55 to 0.55 | -0.50 to 0.55 | deep violet plate | a slim chamfered spar from the core aft to a faceted stern block |
| Gun heart | 9.3 to 25.9 | -0.40 to 0.40 | -0.32 to 0.46 | violet plate | the faceted drum on the spar at the ring's centre, the forward gun on its roof |
| Hoop | 9.9 to 53.1 | -2.06 to 2.06 | -0.12 to 0.12 | violet gunmetal | one closed box-section ring under the plates' inner edges |
| Ring plate at 0 degrees | 0.0 to 11.1 | -0.70 to 0.70 | -0.15 to 0.21 | violet-black shade | a curved shade slab, its outer rim lifting into a shallow dish |
| Ring plate at 90 degrees | 24.2 to 38.9 | 1.94 to 3.00 | -0.15 to 0.21 | violet-black shade | a curved shade slab, its outer rim lifting into a shallow dish |
| Ring plate at 180 degrees | 51.9 to 63.0 | -0.70 to 0.70 | -0.15 to 0.21 | violet-black shade | a curved shade slab, its outer rim lifting into a shallow dish |
| Ring plate at 270 degrees | 24.2 to 38.9 | -3.00 to -1.94 | -0.15 to 0.21 | violet-black shade | a curved shade slab, its outer rim lifting into a shallow dish |
| Saddle, aft gun | 64.1 to 74.6 | -0.40 to 0.40 | 0.18 to 0.47 | violet plate | the stepped saddle the aft gun stands on |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): block deck 0.02 (77% to 87%); spar deck -0.02 (39% to 74%).

Bulkhead and frame stations: F0 45.7%, F1 60.4%, F2 77.2%, F3 81.4%, F4 85.6%, D0 15.2%, D1 21.5%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| capacitor bank (machinery) | 15.8 to 21.3 | -0.22 to 0.22 | -0.18 to 0.05 | the forward gun's capacitor bank, in the gun heart |
| fwd magazine (magazine) | 15.8 to 21.3 | -0.18 to 0.18 | 0.10 to 0.30 | the forward gun's magazine, under it |
| conduits (machinery) | 39.4 to 73.0 | -0.15 to 0.15 | -0.20 to -0.07 | power conduits from the core along the spar's keel |
| aft magazine (magazine) | 66.2 to 72.5 | -0.17 to 0.17 | 0.03 to 0.19 | the aft gun's magazine, under its saddle |
| dark decks (darkdeck) | 46.7 to 65.1 | -0.17 to 0.17 | 0.03 to 0.19 | dark decks: the machine crew along the spar, unlit |
| archive vault (archive) | 77.4 to 81.4 | -0.30 to 0.30 | 0.06 to 0.34 | the archive vault in the stern block |
| repair bay (machinery) | 77.4 to 81.4 | -0.30 to 0.30 | -0.30 to -0.02 | the repair drones' stores and the regeneration plant (data.js regen 2) |
| engine room (engroom) | 81.9 to 86.1 | -0.32 to 0.32 | -0.30 to 0.34 | the engine room and the drive's feed |
| core (ecore) | 27.6 to 35.4 | -0.37 to 0.37 | -0.37 to 0.37 | the core of trapped light, in the open at the ring's centre (hp_core) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ring plates (the shade) | 0.30 | the thickest armour, flat round the heart |
| gun heart | 0.14 |  |
| spar | 0.08 | thin; the ring shades it from ahead |
| stern block | 0.16 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 31.5 (seam wanders 28.4 to 34.1) | the spar parts at the core: the cage bursts, the gun heart and the ring's fore half tear away, the hoop torn across (a ragged bite where the core goes) |
| B-2 | 75.3 (seam wanders 74.7 to 76.1) | the stern block tears from the spar, opening the archive vault and the engine room |

Eclipse breaks in layers (factions.md): the ring's plates peel away first as the hoop tears, then the bare spar parts at the core and the block tears away; full interiors throughout (R215), hidden until a piece breaks.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 31.5 | 0.00 | 0.00 |  |  |  |
| hp_breach_0 | 8.3 | 0.80 | 0.17 | port | prow | on the ring's bow quarter plate |
| hp_breach_1 | 31.5 | -2.30 | 0.17 | stbd | mid | on the ring's starboard beam plate |
| hp_breach_2 | 82.4 | 0.25 | 0.55 | port | eng | on the stern block's roof (no shade plate reaches the engine third) |
| hp_rcs_0 | 13.7 | 0.30 | -0.23 | port |  |  |
| hp_rcs_1 | 13.7 | -0.30 | -0.23 | stbd |  |  |
| hp_board_0 | 55.1 | 0.35 | 0.00 | port |  |  |
| hp_board_1 | 55.1 | -0.35 | 0.00 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 211 objects, 28 parts, 246 close pairs, 176 rays, 2 guns, 0 sensor pairs, 2 turrets swept, 5 cones, 12 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **One closed ring, lying flat in plan round the gun heart (R233).** Ryan, Nov 12: "I agree with your take": from above the flare never reads as a small zenith (the split oval ring). The study (studies/e14_ring_study.py) found flat reads as one closed ring from above and from every battle camera bearing; the sheet's upright ring reads as a bar from above.
- **The ring is 6.0 across, 0.63 of the length, its bow plate the ship's bow, the spar and stern block behind it.** between the beauty (a big forward ring) and the line-up (about 0.6 of the length); the sheet's plan draws it nearly the ship's length, which would put the ring round the whole ship as on the zenith.
- **Twelve plates on one closed hoop, joined to the gun heart at the bow and the spar at the stern, four truss spokes at the beams.** R207: the picture's plates float in a broken circle; a built ring needs a structure, and the closed hoop is the ring R233 asks for.
- **The forward gun is the null cannon on the gun heart's roof, turning only through the data arc F.** data.js gauss F; the game shows gauss as the null cannon on a turret (tools/blender/build_sheets/weapon_match.py FITS), so a fixed recessed housing (designs.md) would fail the weapon match. It rests on the bow and turns 60 either side, as the game turns an F weapon.
- **The aft gun is the null cannon on a stepped saddle aft of the ring (data.js gauss T).** designs.md and the beauty: a low housing on the spar's dorsal line aft of the ring; it fires over the ring's plates.
- **The core is green-white, in a broken cage of six small curved shade plates.** designs.md conforms the beauty's teal to green (R204); the cage plates leave gaps the light shows through.
- **The repair drones are docked on the hoop, each cradle with a green work light.** the picture shows drones hovering in the ring's gaps; a built ship carries them docked, and every part sits on the ship.
- **The spar is a layered beam 0.72 across behind the core, collared where the spokes and the saddle meet it.** the beauty draws a heavy spar body running aft to the engine; a rod as thin as the zenith's spine (E12) read too slight beside a ring this big.
- **From above the flare is one closed ring with the gun heart at its centre and a tail behind it (the spar, the aft gun, the stern block and the engine).** family distinctness (R233): the zenith's split oval rings its whole spine and has no tail; the mote is a leaf of blades; the flagship a crescent.
- **Engines are eclipse rings, not flame.** factions.md: "no flaming bells. An eclipse ring of pale light".
- **Panels dead even, aligned rows on every face, tone in ordered bands (R243).** Ryan, Nov 13: "make the eclipse panels actually panels and dead even and ordered to align"; the kit lays them by size (eclipse parts.py even_panels).
- **Thrusters, belly hatches, heat panels and corona strip lights added.** a ship in space needs thrusters; the picture shows no underside.
- **The third breach anchor sits on the stern block's roof.** the class table needs one in the engine third; no shade plate reaches it.

## Designed here, not shown in the picture

- The underside of the gun heart, the ring and the block is designed here; the picture shows no underside.
- S1 (truss strut, 1.3 long): truss spoke from the gun heart to the hoop, port.
- S2 (truss strut, 1.4 long): truss spoke from the spar to the hoop, port.
- S3 (truss strut, 1.3 long): truss spoke from the gun heart to the hoop, starboard.
- S4 (truss strut, 1.4 long): truss spoke from the spar to the hoop, starboard.
- Q1p (attitude thruster quad): gun heart lower chamfer, firing down and out under the ring.
- Q2p (attitude thruster quad): stern block lower chamfer, firing down and out.
- Q1s (attitude thruster quad): gun heart lower chamfer, firing down and out under the ring.
- Q2s (attitude thruster quad): stern block lower chamfer, firing down and out.
