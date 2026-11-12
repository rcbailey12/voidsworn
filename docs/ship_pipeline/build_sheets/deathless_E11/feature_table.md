# deathless_E11: The Unsetting (Eclipse flagship), build sheet

Eclipse (deathless) | class Tomb-ark | version 1 (first sheet), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532e\e1\deathless_E11\deathless_E11_blockout.blend`

**Length 28.0 world units** (data.js d_boss (cls 'Tomb-ark'); length from godot/render/hull_table.gd CLS_LEN['Tomb-ark'] = 28.0 (drawn x SHIP_K 1.6 = 44.8 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 28.041 |
| length side | 28.062 |
| length top | 28.062 |
| length disagreement percent | 0.0 |
| beam top | 10.85 |
| beam bow | 10.85 |
| beam disagreement percent | 0.0 |
| height side | 6.513 |
| height bow | 6.513 |
| height disagreement percent | 0.0 |
| widest at station percent | 17.6 |
| hull beam | 4.76 |
| hull depth | 4.0 |
| L to B hull | 5.88 |
| L to H hull | 7.0 |
| prow overhang | 8.41 |
| outline iou percent | 82.9 |
| mass outline iou percent | 83.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| A1 | spinal projector (fixed) | 1 barrel | 31.8 | 0.00 | -0.20 | forward | F doom | picture | the corona arc projector on the axis, through the crescent; the spinal shell (nova) fires from it |
| T1 | twin turret | 2 barrels | 41.4 | 0.00 | 2.10 | forward, +5 elev | T gauss | picture | fore null cannon twin on a low drum behind the crescent |
| T2 | twin turret | 2 barrels | 57.8 | 0.00 | 2.85 | forward, +3 elev | T gauss | picture | aft null cannon twin, superfiring over T1; far enough aft that T1 fires aft over its muzzles |
| F1 | twin turret | 2 barrels | 72.8 | 0.00 | 1.78 | forward, +12 elev | T flak | picture | null shredder twin aft on the deck |
| F2 | twin belly turret | 2 barrels | 53.5 | 0.00 | -2.05 | forward, +10 elev | T flak | picture | null shredder twin on the belly, covering below |
| CW1 | core port, hexagonal, 0.7 across | 1 | 63.4 | 0.00 | 2.15 | - | - | picture | the core's light through a hex port in tier 1 |
| HB1 | framed deck box 0.5 x 0.9 | 1 | 66.4 | 0.00 | 2.12 | - | - | picture | raised deck housing (the shade generator) on tier 1 |
| H1 | square hatch 0.3 | 1 | 71.7 | 1.35 | 1.60 | - | - | picture | deck hatch aft, port |
| H2 | square hatch 0.3 | 1 | 71.7 | -1.35 | 1.60 | - | - | picture | deck hatch aft, starboard |
| H3 | square hatch 0.4 | 1 | 61.4 | 0.90 | -1.97 | - | - | picture | belly hatch, port |
| H4 | square hatch 0.4 | 1 | 61.4 | -0.90 | -1.97 | - | - | picture | belly hatch, starboard |
| Q1p | attitude thruster quad | 1 | 44.3 | 2.24 | 0.95 | - | - | designed | neck flank |
| L0p | running light | 1 | 40.7 | 2.22 | 0.62 | - | - | picture | corona strip light over the belt |
| L1p | running light | 1 | 47.8 | 2.31 | 0.62 | - | - | picture | corona strip light over the belt |
| L2p | running light | 1 | 55.0 | 2.27 | 0.62 | - | - | picture | corona strip light over the belt |
| L3p | running light | 1 | 62.1 | 2.18 | 0.62 | - | - | picture | corona strip light over the belt |
| V1p | louvre panel 0.7 x 0.3 | 1 | 71.4 | 1.96 | 1.05 | - | - | picture | heat slot panel over the belt, ahead of the band collar |
| Q2p | attitude thruster quad | 1 | 76.7 | 2.10 | 0.00 | - | - | designed | on the band collar |
| Q1s | attitude thruster quad | 1 | 44.3 | -2.24 | 0.95 | - | - | designed | neck flank |
| L0s | running light | 1 | 40.7 | -2.22 | 0.62 | - | - | picture | corona strip light over the belt |
| L1s | running light | 1 | 47.8 | -2.31 | 0.62 | - | - | picture | corona strip light over the belt |
| L2s | running light | 1 | 55.0 | -2.27 | 0.62 | - | - | picture | corona strip light over the belt |
| L3s | running light | 1 | 62.1 | -2.18 | 0.62 | - | - | picture | corona strip light over the belt |
| V1s | louvre panel 0.7 x 0.3 | 1 | 71.4 | -1.96 | 1.05 | - | - | picture | heat slot panel over the belt, ahead of the band collar |
| Q2s | attitude thruster quad | 1 | 76.7 | -2.10 | 0.00 | - | - | designed | on the band collar |
| E1 | engine, bell 1.5 across | 1 | 99.9 | 0.00 | 1.20 | exhaust aft | - | picture | upper engine of the diamond |
| E2 | engine, bell 1.5 across | 1 | 99.9 | 1.20 | 0.00 | exhaust aft | - | picture | port engine of the diamond |
| E3 | engine, bell 1.5 across | 1 | 99.9 | -1.20 | 0.00 | exhaust aft | - | designed | starboard engine of the diamond |
| E4 | engine, bell 1.5 across | 1 | 99.9 | 0.00 | -1.20 | exhaust aft | - | picture | lower engine of the diamond |

Totals: 5 gun mounts with 9 barrels; 0 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| Eclipse violet and mauve plate, violet-black shade (paint stage) | 0.0 | 99.9 | whole hull |  |
| green-white corona line | 0.0 | 39.6 | every crescent rim |  |
| core light | 60.7 | 62.5 | the core port |  |
| pale grey-green weathering (paint) | 17.9 | 28.6 | inner crescent face |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the oval body | 30.0 to 93.8 | -2.38 to 2.38 | -2.05 to 1.95 | Eclipse violet plate | widest behind the crescent, waisted at the band collar, flaring at the stern |
| Crescent lower blade | 0.1 to 39.6 | -5.40 to 5.40 | -1.36 to 1.00 | Eclipse violet and mauve plate | a broad brim: 1.2 thick at the inner wall, 0.6 at the back rim, thin at the horns; it falls 1.6 from the root to the horns |
| Crescent upper layer | 5.7 to 33.4 | -4.64 to 4.64 | -0.78 to 1.25 | mauve plate | stepped in from the rim, over the inner half of the blade, to 122 degrees either side |
| Crescent root layer | 18.8 to 29.9 | -3.67 to 3.67 | 0.36 to 1.45 | violet plate | the third, shortest layer over the root |
| Projector breech collars | 20.4 to 33.9 | -0.94 to 0.94 | -1.14 to 0.74 | mauve and violet | a part of the kit projector, counted as its own mass |
| Projector shaft | 7.7 to 17.1 | -0.82 to 0.82 | -1.02 to 0.62 | violet and mauve | a part of the kit projector, counted as its own mass |
| Projector muzzle block | 4.8 to 20.4 | -0.78 to 0.78 | -0.98 to 0.58 | mauve | a part of the kit projector, counted as its own mass |
| Dorsal tier | 50.7 to 69.6 | -1.42 to 1.42 | 1.40 to 2.21 | mauve plate | the layered plate tier along the spine (the concept's raised plate rows), a quarter unit proud |
| Barbette, fore battery | 38.0 to 44.8 | -0.95 to 0.95 | 1.50 to 2.12 | violet plate | a low round drum: the fore battery fires aft over the tier and the aft battery's muzzles |
| Barbette, aft battery | 54.4 to 61.2 | -1.00 to 1.00 | 1.90 to 2.87 | violet plate | a low round drum that superfires the aft battery over the fore one |
| Flank belt | 40.0 to 73.9 | -2.50 to 2.50 | -0.05 to 0.42 | grey-mauve armour boxes | a raised strake at mid height, both flanks |
| Lower skirt | 40.7 to 73.9 | -2.42 to 2.42 | -1.66 to -0.46 | deep violet tall plates | tall narrow plates hanging below the belt |
| Band collar | 74.8 to 78.3 | -2.11 to 2.11 | -2.04 to 1.95 | violet gunmetal with segmented blocks | the heavy band ring at 77 percent |
| Feather row 1, blade 1 | 79.2 to 86.4 | 1.82 to 2.14 | 0.01 to 1.03 | violet blade | swept shade blade, lifting aft |
| Feather row 1, blade 4 | 79.2 to 86.4 | -0.97 to 0.07 | 1.71 to 2.01 | violet blade | swept shade blade, lifting aft |
| Feather row 1, blade 7 | 79.2 to 86.4 | -2.15 to -1.74 | -1.11 to -0.11 | violet blade | swept shade blade, lifting aft |
| Feather row 1, blade 10 | 79.2 to 86.4 | -0.04 to 0.98 | -2.08 to -1.74 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 1 | 83.5 to 90.6 | 1.66 to 2.16 | 0.56 to 1.51 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 4 | 83.5 to 90.6 | -1.52 to -0.53 | 1.61 to 2.01 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 7 | 83.5 to 90.6 | -2.12 to -1.52 | -1.55 to -0.65 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 10 | 83.5 to 90.6 | 0.53 to 1.47 | -2.07 to -1.58 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 1 | 87.8 to 96.0 | 1.94 to 2.23 | 0.07 to 1.10 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 4 | 87.8 to 96.0 | -1.01 to 0.03 | 1.87 to 2.08 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 7 | 87.8 to 96.0 | -2.24 to -1.92 | -1.03 to -0.01 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 10 | 87.8 to 96.0 | -0.00 to 1.02 | -2.17 to -1.90 | violet blade | swept shade blade, lifting aft |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.95 (34% to 93%); main deck 0.30 (32% to 93%); upper deck 1.20 (39% to 91%).

Bulkhead and frame stations: F0 33.6%, F1 42.1%, F2 51.4%, F3 60.7%, F4 69.6%, F5 76.7%, F6 84.9%, F7 92.8%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| capacitor bank (magazine) | 33.9 to 41.8 | -0.90 to 0.90 | -0.90 to 0.20 | corona arc capacitors behind the projector's breech |
| fore magazine (magazine) | 37.9 to 43.6 | -0.70 to 0.70 | 0.40 to 1.15 | under the fore battery |
| archive vault fore (archive) | 42.5 to 51.0 | -1.50 to 1.50 | -0.90 to 0.25 | archive vaults: the Starwrights' stored selves |
| aft magazine (magazine) | 51.4 to 57.8 | -0.70 to 0.70 | 0.40 to 1.15 | under the aft battery |
| dark decks (darkdeck) | 51.8 to 60.3 | -1.40 to 1.40 | 0.40 to 1.15 | dark decks: machine crew stations, unlit |
| core (ecore) | 61.0 to 68.9 | -1.10 to 1.10 | -0.90 to 1.15 | the core of trapped light (hp_core); its port opens on the deck |
| archive vault aft (archive) | 69.9 to 76.0 | -1.20 to 1.20 | -0.90 to 0.25 | archive vaults |
| shade machinery (machinery) | 69.9 to 76.0 | -1.00 to 1.00 | 0.40 to 1.15 | shade generators and the band collar's drives |
| flak magazine (magazine) | 50.7 to 56.4 | -0.70 to 0.70 | -1.50 to -1.00 | over the belly twin |
| engine room (engroom) | 85.3 to 92.4 | -1.40 to 1.40 | -0.90 to 1.15 | engine room and the four drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| crescent (shade layers) | 0.60 | three layers, thickest at the inner wall; the rims knife-thin |
| dorsal tiers and barbettes | 0.40 |  |
| flank belt | 0.30 | over the vaults and magazines |
| belly and skirt | 0.25 |  |
| stern feathers | 0.15 | thinnest; they peel first |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 31.4 (seam wanders 30.0 to 32.9) | the crescent root seam: the shade and the projector tear away from the neck, opening the capacitor bank |
| B-2 | 76.7 (seam wanders 75.3 to 78.1) | at the band collar: the stern (feathers and drives) tears away, opening the engine room and the aft vault |
| B-3 | 45.3 to 69.2 (along) | the dorsal tiers peel off band by band along their base, taking the batteries, laying the dark decks bare |
| B-4 | 5.4 to 29.3 (along) | the crescent's upper layers peel from the lower blade, band by band, then the blade splits at a horn root |

Full interiors throughout the hull (R215), hidden until a piece breaks. Eclipse breaks in layers (factions.md): shade plates peel band by band, then the body behind is bare; deaths blow it apart unevenly, a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 65.0 | 0.00 | 0.10 |  |  |  |
| hp_breach_0 | 19.7 | 3.60 | -0.30 | port | prow | on a shade band |
| hp_breach_1 | 21.4 | -3.90 | -0.35 | stbd | prow | on a shade band |
| hp_breach_2 | 10.7 | 2.60 | -1.00 | port | prow | on a shade band |
| hp_breach_3 | 53.2 | -1.40 | 2.00 | stbd | mid | on a shade band |
| hp_breach_4 | 63.5 | 1.30 | 1.98 | port | mid | on a shade band |
| hp_breach_5 | 46.8 | -2.40 | 0.50 | stbd | mid | on a shade band |
| hp_breach_6 | 83.1 | 1.90 | 0.90 | port | eng | on a shade band |
| hp_breach_7 | 87.1 | -1.90 | -0.90 | stbd | eng | on a shade band |
| hp_rcs_0 | 44.3 | 2.24 | 0.95 | port |  |  |
| hp_rcs_1 | 44.3 | -2.24 | 0.95 | stbd |  |  |
| hp_rcs_2 | 76.7 | 2.10 | 0.00 | port |  |  |
| hp_rcs_3 | 76.7 | -2.10 | 0.00 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 241 objects, 29 parts, 645 close pairs, 474 rays, 5 guns, 4 turrets swept, 8 cones, 15 apertures. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The engine cluster is a diamond of four.** the side view and the beauty show three bells stacked, the plan shows two side by side; a diamond of four is the one layout that reads as all three pictures, and keeps the stern wide and flat.
- **Engines are eclipse rings, not flame.** factions.md: "no flaming bells. An eclipse ring of pale light": each bell has a black shade disc with a thin pale green-white ring inside its lip.
- **Batteries by data.js slot.** d_boss carries gauss T twice, doom F and flak T: the two big twins are the null cannons (the aft one superfires on a barbette), the projector is the corona arc, the small aft twin and a belly twin are the null shredders.
- **The green hexagon on the deck is the core port, not a gun.** the faction's green is the trapped core seen through gaps; the flak slot is the small twin.
- **The crescent is three stacked layers with a corona line on each rim.** factions.md: broad layered plates, the green a thin line on every shade rim; the concept shows two stepped bands and a lip; the layers are also how it breaks (band by band).
- **Low round drums under both batteries.** so the fore twin clears the tier when it trains aft and fires aft over the aft twin's muzzles, and the aft twin fires over the fore one (the fit check found both).
- **Belly twin, attitude thrusters, deck and belly hatches, corona strip lights, heat panels added.** the belly needs cover and a ship in space needs thrusters; the picture shows no underside.
- **The crescent band is 1.65 wide at its sides.** the plan of record (the 8c sheet's top view) gives 1.3, the beauty reads broader; the band sits between the two so the beauty's fat brim reads without losing the plan.

## Designed here, not shown in the picture

- The belly between the skirt and the belly twin is designed here; the picture does not show the underside.
- Q1p (attitude thruster quad): neck flank.
- Q2p (attitude thruster quad): on the band collar.
- Q1s (attitude thruster quad): neck flank.
- Q2s (attitude thruster quad): on the band collar.
- E3 (engine, bell 1.5 across): starboard engine of the diamond.
