# deathless_E14: Eclipse flare (the glass cannon), build sheet

Eclipse (deathless) | class Destroyer | version 2 (redesign, the upright ring and the glass cannon (issue 782, R256)), 2026-11-15 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\sandbox\deathless_E14\deathless_E14_blockout.blend`

**Length 9.5 world units** (data.js d_jackal (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5 (drawn x SHIP_K 1.6 = 15.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | nlance | F | 3 | L1 (1) |

| Check | Value |
|---|---|
| model length | 9.536 |
| length side | 9.562 |
| length top | 9.562 |
| length disagreement percent | 0.0 |
| beam top | 6.075 |
| beam bow | 6.075 |
| beam disagreement percent | 0.0 |
| height side | 6.075 |
| height bow | 6.075 |
| height disagreement percent | 0.0 |
| widest at station percent | 10.3 |
| hull beam | 1.1 |
| hull depth | 1.05 |
| L to B hull | 8.64 |
| L to H hull | 9.05 |
| prow overhang | 3.29 |
| outline iou percent | 67.7 |
| mass outline iou percent | 67.8 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| S1 | truss strut, 0.9 long | 1 | 16.4 | 0.64 | 0.64 | - | - | designed | truss spoke from the focus collar to the hoop, upper port |
| S2 | truss strut, 0.9 long | 1 | 16.4 | -0.64 | 0.64 | - | - | designed | truss spoke from the focus collar to the hoop, upper starboard |
| S3 | truss strut, 0.9 long | 1 | 16.4 | -0.64 | -0.64 | - | - | designed | truss spoke from the focus collar to the hoop, lower starboard |
| S4 | truss strut, 0.9 long | 1 | 16.4 | 0.64 | -0.64 | - | - | designed | truss spoke from the focus collar to the hoop, lower port |
| C1 | caged core of trapped light, 1.0 across | 1 | 29.0 | 0.00 | 0.00 | - | - | picture | the trapped light core behind the ring's centre, the spar and the gun heart entering its hub collars |
| L1 | spinal projector (fixed) | 1 barrel | 15.4 | 0.00 | 0.00 | forward | F nlance | picture | the null lance (data.js nlance F, issue 784): one fixed spinal rail gun on the gun heart's face, firing forward through the ring's centre; its muzzle, a recessed aperture with a glowing lens and a green focus ring, is the ship's bow |
| E1 | engine, bell 1.2 across | 1 | 99.8 | 0.00 | 0.03 | exhaust aft | - | picture | the broad eclipse ring of pale light at the stern, larger than the mote's; no flame |
| Q1p | attitude thruster quad | 1 | 37.4 | 0.24 | -0.21 | - | - | designed | spar lower chamfer behind the core, firing down and out, clear of the ring |
| Q2p | attitude thruster quad | 1 | 85.4 | 0.47 | -0.42 | - | - | designed | stern block lower chamfer, firing down and out |
| L0p | running light | 1 | 79.8 | 0.52 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| L1p | running light | 1 | 84.6 | 0.54 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| V1p | louvre panel 0.3 x 0.2 | 1 | 80.4 | 0.52 | -0.20 | - | - | picture | heat slot panel low on the block flank |
| H1p | square hatch 0.2 | 1 | 80.9 | 0.18 | -0.50 | - | - | picture | belly hatch on the stern block |
| Q1s | attitude thruster quad | 1 | 37.4 | -0.24 | -0.21 | - | - | designed | spar lower chamfer behind the core, firing down and out, clear of the ring |
| Q2s | attitude thruster quad | 1 | 85.4 | -0.47 | -0.42 | - | - | designed | stern block lower chamfer, firing down and out |
| L0s | running light | 1 | 79.8 | -0.52 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| L1s | running light | 1 | 84.6 | -0.54 | 0.22 | - | - | picture | corona strip light on the stern block flank |
| V1s | louvre panel 0.3 x 0.2 | 1 | 80.4 | -0.52 | -0.20 | - | - | picture | heat slot panel low on the block flank |
| H1s | square hatch 0.2 | 1 | 80.9 | -0.18 | -0.50 | - | - | picture | belly hatch on the stern block |
| D1 | repair drone cradle 0.2 x 0.1 | 1 | 11.6 | 1.86 | 0.00 | - | - | picture | repair drone cradle on the hoop's front face, under the plates' inner edge |
| DL1 | running light | 1 | 10.5 | 1.86 | 0.00 | - | - | picture | the drone's green work light |
| D2 | repair drone cradle 0.2 x 0.1 | 1 | 11.6 | 0.00 | 1.86 | - | - | picture | repair drone cradle on the hoop's front face, under the plates' inner edge |
| DL2 | running light | 1 | 10.5 | 0.00 | 1.86 | - | - | picture | the drone's green work light |
| D3 | repair drone cradle 0.2 x 0.1 | 1 | 11.6 | -1.86 | 0.00 | - | - | picture | repair drone cradle on the hoop's front face, under the plates' inner edge |
| DL3 | running light | 1 | 10.5 | -1.86 | 0.00 | - | - | picture | the drone's green work light |
| D4 | repair drone cradle 0.2 x 0.1 | 1 | 11.6 | -0.00 | -1.86 | - | - | picture | repair drone cradle on the hoop's front face, under the plates' inner edge |
| DL4 | running light | 1 | 10.5 | -0.00 | -1.86 | - | - | picture | the drone's green work light |

Totals: 1 gun mounts with 1 barrels; 0 launcher tubes; 1 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| violet-black shade plates, deep violet spar and gun heart (paint stage) | 0.1 | 99.8 | whole ship |  |
| green-white corona line | 9.1 | 18.5 | every ring plate's rim, front and back edges, and its layer's rim |  |
| lance aperture: the glowing lens and the green focus ring | 0.1 | 5.9 | the lance's mouth at the ring's centre |  |
| core light | 23.2 | 34.8 | the core in its cage |  |
| drone lights, green | 10.1 | 12.2 | the four drone cradles on the hoop |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the spar and the stern block | 34.5 to 87.7 | -0.55 to 0.55 | -0.50 to 0.55 | deep violet plate | a slim chamfered spar from the core aft to a faceted stern block |
| Gun heart | 15.4 to 23.4 | -0.84 to 0.84 | -0.84 to 0.84 | violet plate | the lance's faceted breech casing from the core forward through the ring's centre, the lance on its face |
| Focus collar | 15.6 to 17.2 | -0.94 to 0.94 | -0.94 to 0.94 | mauve band | the band round the gun heart in the ring's plane where the four spokes land |
| Hoop | 11.6 to 17.0 | -2.06 to 2.06 | -2.06 to 2.06 | violet gunmetal | one closed box-section ring under the plates' inner edges |
| Ring plate at 0 degrees | 9.1 to 18.5 | 1.94 to 3.00 | -0.70 to 0.70 | violet-black shade | a deep curved shade block, its front a shallow dish, its rim chamfered fore and aft |
| Ring plate at 90 degrees | 9.1 to 18.5 | -0.70 to 0.70 | 1.94 to 3.00 | violet-black shade | a deep curved shade block, its front a shallow dish, its rim chamfered fore and aft |
| Ring plate at 180 degrees | 9.1 to 18.5 | -3.00 to -1.94 | -0.70 to 0.70 | violet-black shade | a deep curved shade block, its front a shallow dish, its rim chamfered fore and aft |
| Ring plate at 270 degrees | 9.1 to 18.5 | -0.70 to 0.70 | -3.00 to -1.94 | violet-black shade | a deep curved shade block, its front a shallow dish, its rim chamfered fore and aft |
| Capacitor housing | 53.6 to 72.5 | -0.34 to 0.34 | 0.18 to 0.50 | violet plate | the stepped dorsal housing aft of the core that stores the lance's charge |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): block deck 0.02 (77% to 87%); spar deck -0.02 (39% to 74%).

Bulkhead and frame stations: F0 45.8%, F1 60.4%, F2 77.2%, F3 81.4%, F4 85.6%, D0 16.9%, D1 20.6%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| capacitor bank (machinery) | 17.2 to 20.2 | -0.30 to 0.30 | -0.30 to 0.05 | the lance's breech capacitors, in the gun heart behind the ring |
| fwd magazine (magazine) | 17.2 to 20.2 | -0.24 to 0.24 | 0.10 to 0.32 | the lance's slug magazine, over the capacitors |
| conduits (machinery) | 39.5 to 73.0 | -0.15 to 0.15 | -0.20 to -0.07 | power conduits from the core along the spar's keel to the capacitor housing |
| charge store (machinery) | 54.7 to 72.5 | -0.17 to 0.17 | 0.03 to 0.19 | the charge store under the dorsal capacitor housing |
| dark decks (darkdeck) | 40.5 to 53.6 | -0.17 to 0.17 | 0.03 to 0.19 | dark decks: the machine crew along the spar, unlit |
| archive vault (archive) | 77.4 to 81.4 | -0.30 to 0.30 | 0.06 to 0.34 | the archive vault in the stern block |
| repair bay (machinery) | 77.4 to 81.4 | -0.30 to 0.30 | -0.30 to -0.02 | the repair drones' stores and the regeneration plant (data.js regen 2) |
| engine room (engroom) | 81.9 to 86.1 | -0.32 to 0.32 | -0.30 to 0.34 | the engine room and the drive's feed |
| core (ecore) | 25.1 to 32.9 | -0.37 to 0.37 | -0.37 to 0.37 | the core of trapped light, in the open behind the ring's centre (hp_core) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ring plates (the shade) | 0.80 | the thickest armour: deep blocks standing across the bow, facing the enemy |
| gun heart | 0.14 |  |
| spar | 0.08 | thin; the ring shades it from ahead (the glass cannon: data.js hull down, issue 784) |
| stern block | 0.16 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 29.0 (seam wanders 25.8 to 31.6) | the spar parts at the core: the cage bursts, the gun heart, the lance and the ring tear away forward (a ragged bite where the core goes) |
| B-2 | 75.3 (seam wanders 74.7 to 76.2) | the stern block tears from the spar, opening the archive vault and the engine room |

Eclipse breaks in layers (factions.md): the ring's plates peel away first as the hoop tears, then the bare spar parts at the core and the block tears away; full interiors throughout (R215), hidden until a piece breaks.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 29.0 | 0.00 | 0.00 |  |  |  |
| hp_breach_0 | 13.8 | 3.00 | 0.00 | port | prow | on the ring's port beam plate, its outer rim |
| hp_breach_1 | 14.8 | -3.00 | 0.00 | stbd | mid | on the ring's starboard beam plate, its outer rim |
| hp_breach_2 | 82.5 | 0.25 | 0.55 | port | eng | on the stern block's roof (no shade plate reaches the engine third) |
| hp_rcs_0 | 37.4 | 0.24 | -0.21 | port |  |  |
| hp_rcs_1 | 37.4 | -0.24 | -0.21 | stbd |  |  |
| hp_board_0 | 55.2 | 0.35 | 0.00 | port |  |  |
| hp_board_1 | 55.2 | -0.35 | 0.00 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 222 objects, 27 parts, 197 close pairs, 102 rays, 1 guns, 0 sensor pairs, 0 turrets swept, 5 cones, 12 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The ring stands upright across the bow and faces forward, the ship running through its middle (R256).** Ryan, Nov 15: the first sheet's flat ring "changes the entire ship"; the concept's beauty and its middle and right views stand it upright. It is the shade held forward at the enemy (factions.md).
- **The ring is 0.8 deep along the ship, its front a shallow dish, its rim chamfered fore and aft with a corona line on each edge.** from the beam the upright ring is exactly edge-on at any camera height, so its depth is the whole band the battle camera sees: 0.8 is about 10 px at the default battle camera, between two bright lines (the Board, issue 782).
- **One big fixed gun, the null lance, at the ring's centre; its muzzle, a recessed aperture with a glowing lens and a green focus ring, is the bow.** Ryan, Nov 15: "built around one larger gun and that's the center of the ring ... like a glass cannon". data.js gives the flare one forward null lance (issue 784); designs.md's fixed forward housing with a recessed aperture and focus ring comes back.
- **No second gun: the aft turret of the first sheet is gone; a stepped capacitor housing on the spar stores the lance's charge.** issue 784 trades both null cannons for the one lance (the glass cannon); every visible gun is a data.js slot (R241).
- **The gun heart is the lance's breech casing, from the core forward through the ring's centre; four truss spokes carry the hoop to its focus collar.** R207: the picture's plates float; the ring is the lance's focusing ring, so it hangs off the gun's own heart.
- **The core sits just aft of the ring in its broken cage of six small shade plates, its light seen from the beam and the quarters; from ahead the gun heart hides it and the lance's glowing lens is the light at the ring's centre.** designs.md: core and main gun together at the ring's heart; the beauty shows the core lit inside the heart behind the muzzle, which a heart big enough for the lance covers.
- **The ring is 6.0 across, 0.63 of the length, standing in the forward fifth; the spar and stern block run 7.6 aft of it.** the beauty draws a big forward ring with the spar running far aft; kept from the first sheet so the class stays the same size on the board.
- **Twelve plates on one closed hoop (R233).** R233: one closed ring, never a small zenith; the upright ring cannot read as the zenith's split oval round a spine.
- **The repair drones are docked on the hoop's front face, each cradle with a green work light.** the picture shows drones hovering in the ring's gaps; a built ship carries them docked, and every part sits on the ship.
- **The spar is a layered beam 0.72 across behind the core.** the beauty draws a heavy spar body running aft to the engine.
- **Engines are eclipse rings, not flame.** factions.md: "no flaming bells. An eclipse ring of pale light".
- **Panels dead even, aligned rows on every face, tone in ordered bands (R243).** Ryan, Nov 13: "make the eclipse panels actually panels and dead even and ordered to align"; the kit lays them by size (eclipse parts.py even_panels).
- **Thrusters, belly hatches, heat panels and corona strip lights added.** a ship in space needs thrusters; the picture shows no underside.
- **The forward thrusters sit under the spar behind the core, not at the nose.** a thruster on the gun heart fires into the ring's lower plates.
- **The third breach anchor sits on the stern block's roof.** the class table needs one in the engine third; no shade plate reaches it.

## Designed here, not shown in the picture

- The underside of the gun heart and the block is designed here; the picture shows no underside.
- The ring reaches 3.0 below the ship's axis (4.8 drawn): the Board checks it against the board plane in the game.
- S1 (truss strut, 0.9 long): truss spoke from the focus collar to the hoop, upper port.
- S2 (truss strut, 0.9 long): truss spoke from the focus collar to the hoop, upper starboard.
- S3 (truss strut, 0.9 long): truss spoke from the focus collar to the hoop, lower starboard.
- S4 (truss strut, 0.9 long): truss spoke from the focus collar to the hoop, lower port.
- Q1p (attitude thruster quad): spar lower chamfer behind the core, firing down and out, clear of the ring.
- Q2p (attitude thruster quad): stern block lower chamfer, firing down and out.
- Q1s (attitude thruster quad): spar lower chamfer behind the core, firing down and out, clear of the ring.
- Q2s (attitude thruster quad): stern block lower chamfer, firing down and out.
