# deathless_E11: The Unsetting (Eclipse flagship), build sheet

Eclipse (deathless) | class Tomb-ark | version 3 (third sheet (R221 weapons, pass 2)), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532e\w\w3\deathless_E11\deathless_E11_blockout.blend`

**Length 28.0 world units** (data.js d_boss (cls 'Tomb-ark'); length from godot/render/hull_table.gd CLS_LEN['Tomb-ark'] = 28.0 (drawn x SHIP_K 1.6 = 44.8 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | gauss | T | 3 | T1 (2) |
| 1 | gauss | T | 3 | T2 (2) |
| 2 | doom | F | 1 | A1 (1) |
| 3 | flak | T | 3 | F1 (5) |

| Check | Value |
|---|---|
| model length | 28.074 |
| length side | 28.1 |
| length top | 28.087 |
| length disagreement percent | 0.04 |
| beam top | 11.025 |
| beam bow | 11.075 |
| beam disagreement percent | 0.18 |
| height side | 6.438 |
| height bow | 6.425 |
| height disagreement percent | 0.04 |
| widest at station percent | 18.3 |
| hull beam | 4.76 |
| hull depth | 4.0 |
| L to B hull | 5.88 |
| L to H hull | 7.0 |
| prow overhang | 8.45 |
| outline iou percent | 82.9 |
| mass outline iou percent | 83.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| A1 | spinal arc emitter (fixed) | 1 barrel | 31.9 | 0.00 | -0.20 | forward | F doom | picture | the corona arc emitter on the axis, through the crescent: a capacitor column ending in a crown of electrode horns round a black shade disc; the spinal shell (nova) fires from it |
| T1 | null cannon, twin turret | 2 barrels | 41.5 | 0.00 | 2.10 | forward, +5 elev | T gauss | picture | fore null cannon: twin rail pairs through a crescent shade, on a low drum behind the crescent |
| T2 | null cannon, twin turret | 2 barrels | 57.9 | 0.00 | 2.85 | forward, +3 elev | T gauss | picture | aft null cannon, superfiring over T1; far enough aft that T1 fires aft over its muzzles |
| F1 | null shredder, twin turret | 2 barrels | 72.8 | 0.00 | 1.78 | forward, +12 elev | T flak | picture | null shredder: a fan of five needle rails, aft on the deck |
| CW1 | core port, hexagonal, 0.7 across | 1 | 63.4 | 0.00 | 2.15 | - | - | picture | the core's light through a hex port in tier 1 |
| HB1 | framed deck box 0.5 x 0.9 | 1 | 66.4 | 0.00 | 2.12 | - | - | picture | raised deck housing (the shade generator) on tier 1 |
| H1 | square hatch 0.3 | 1 | 71.8 | 1.35 | 1.60 | - | - | picture | deck hatch aft, port |
| H2 | square hatch 0.3 | 1 | 71.8 | -1.35 | 1.60 | - | - | picture | deck hatch aft, starboard |
| H3 | square hatch 0.4 | 1 | 61.4 | 0.90 | -1.97 | - | - | picture | belly hatch, port |
| H4 | square hatch 0.4 | 1 | 61.4 | -0.90 | -1.97 | - | - | picture | belly hatch, starboard |
| Q1p | attitude thruster quad | 1 | 44.3 | 2.24 | 0.95 | - | - | designed | neck flank |
| L0p | running light | 1 | 40.8 | 2.22 | 0.62 | - | - | picture | corona strip light over the belt |
| L1p | running light | 1 | 47.9 | 2.31 | 0.62 | - | - | picture | corona strip light over the belt |
| L2p | running light | 1 | 55.0 | 2.27 | 0.62 | - | - | picture | corona strip light over the belt |
| L3p | running light | 1 | 62.2 | 2.18 | 0.62 | - | - | picture | corona strip light over the belt |
| V1p | louvre panel 0.7 x 0.3 | 1 | 71.4 | 1.96 | 1.05 | - | - | picture | heat slot panel over the belt, ahead of the band collar |
| Q2p | attitude thruster quad | 1 | 76.8 | 2.10 | 0.00 | - | - | designed | on the band collar |
| Q1s | attitude thruster quad | 1 | 44.3 | -2.24 | 0.95 | - | - | designed | neck flank |
| L0s | running light | 1 | 40.8 | -2.22 | 0.62 | - | - | picture | corona strip light over the belt |
| L1s | running light | 1 | 47.9 | -2.31 | 0.62 | - | - | picture | corona strip light over the belt |
| L2s | running light | 1 | 55.0 | -2.27 | 0.62 | - | - | picture | corona strip light over the belt |
| L3s | running light | 1 | 62.2 | -2.18 | 0.62 | - | - | picture | corona strip light over the belt |
| V1s | louvre panel 0.7 x 0.3 | 1 | 71.4 | -1.96 | 1.05 | - | - | picture | heat slot panel over the belt, ahead of the band collar |
| Q2s | attitude thruster quad | 1 | 76.8 | -2.10 | 0.00 | - | - | designed | on the band collar |
| E1 | engine, bell 1.3 across | 1 | 99.9 | 0.00 | 1.35 | exhaust aft | - | picture | upper engine of the stack |
| E2 | engine, bell 1.3 across | 1 | 99.9 | 0.00 | -0.04 | exhaust aft | - | picture | centre engine of the stack |
| E3 | engine, bell 1.3 across | 1 | 99.9 | 0.00 | -1.43 | exhaust aft | - | picture | lower engine of the stack |

Totals: 4 gun mounts with 7 barrels; 0 launcher tubes; 3 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| Eclipse violet and mauve plate, violet-black shade (paint stage) | 0.2 | 99.9 | whole hull |  |
| green-white corona line | 0.2 | 39.7 | every crescent rim |  |
| core light | 60.7 | 62.5 | the core port |  |
| pale grey-green weathering (paint) | 18.0 | 28.7 | inner crescent face |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the oval body | 30.1 to 90.7 | -2.38 to 2.38 | -2.05 to 1.95 | Eclipse violet plate | widest behind the crescent, waisted at the band collar, flaring at the stern |
| Crescent lower blade | 0.2 to 39.7 | -5.40 to 5.40 | -1.38 to 1.02 | Eclipse violet and mauve plate | a broad brim: 1.2 thick at the inner wall, 0.6 at the back rim, thin at the horns; it falls 1.6 from the root to the horns |
| Crescent upper layer | 2.2 to 39.7 | -5.40 to 5.40 | -1.06 to 1.25 | mauve plate | the broad outer band, flush with the outer wall, to 140 degrees either side; the inner layer steps down inside it |
| Crescent root layer | 23.4 to 37.6 | -4.60 to 4.60 | 0.39 to 1.37 | violet plate | the third, shortest layer on the broad band over the root |
| Projector breech collars | 20.6 to 34.0 | -0.97 to 0.97 | -1.17 to 0.77 | mauve and violet | a part of the kit projector, counted as its own mass |
| Projector shaft | 5.8 to 19.4 | -0.82 to 0.82 | -1.02 to 0.62 | violet and mauve | a part of the kit projector, counted as its own mass |
| Projector muzzle block | 5.0 to 20.5 | -0.84 to 0.84 | -1.04 to 0.64 | mauve | a part of the kit projector, counted as its own mass |
| Dorsal tier | 50.8 to 69.6 | -1.42 to 1.42 | 1.40 to 2.21 | mauve plate | the layered plate tier along the spine (the concept's raised plate rows), a quarter unit proud |
| Barbette, fore battery | 39.0 to 44.0 | -0.70 to 0.70 | 1.50 to 2.12 | violet plate | a low round drum, slimmed to the turret's foot (R221 pass 2): the fore battery fires aft over the tier and the aft battery's muzzles |
| Barbette, aft battery | 55.5 to 60.3 | -0.72 to 0.72 | 1.90 to 2.87 | violet plate | a low round drum that superfires the aft battery over the fore one |
| Flank belt | 40.1 to 73.9 | -2.50 to 2.50 | -0.05 to 0.42 | grey-mauve armour boxes | a raised strake at mid height, both flanks |
| Lower skirt | 40.8 to 73.9 | -2.42 to 2.42 | -1.66 to -0.46 | deep violet tall plates | tall narrow plates hanging below the belt |
| Band collar | 74.8 to 78.4 | -2.11 to 2.11 | -2.04 to 1.95 | violet gunmetal with segmented blocks | the heavy band ring at 77 percent |
| Feather row 1, blade 1 | 79.3 to 86.4 | 1.46 to 2.06 | 0.00 to 1.03 | violet blade | swept shade blade, lifting aft |
| Feather row 1, blade 4 | 79.3 to 86.4 | -0.97 to 0.07 | 1.71 to 2.01 | violet blade | swept shade blade, lifting aft |
| Feather row 1, blade 7 | 79.3 to 86.4 | -2.08 to -1.45 | -1.11 to -0.11 | violet blade | swept shade blade, lifting aft |
| Feather row 1, blade 10 | 79.3 to 86.4 | -0.04 to 0.98 | -2.07 to -1.74 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 1 | 83.5 to 90.7 | 0.82 to 1.90 | 0.27 to 1.43 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 4 | 83.5 to 90.7 | -1.46 to -0.52 | 1.01 to 2.02 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 7 | 83.5 to 90.7 | -1.88 to -0.80 | -1.47 to -0.37 | violet blade | swept shade blade, lifting aft |
| Feather row 2, blade 10 | 83.5 to 90.7 | 0.53 to 1.42 | -2.07 to -1.08 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 1 | 87.8 to 90.7 | 0.87 to 1.34 | -0.27 to 0.77 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 4 | 87.8 to 90.7 | -1.02 to -0.08 | 1.62 to 2.16 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 7 | 87.8 to 90.7 | -1.35 to -0.87 | -0.90 to 0.13 | violet blade | swept shade blade, lifting aft |
| Feather row 3, blade 10 | 87.8 to 90.7 | 0.10 to 0.97 | -2.25 to -1.62 | violet blade | swept shade blade, lifting aft |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.95 (34% to 89%); main deck 0.30 (33% to 89%); upper deck 1.20 (39% to 88%).

Bulkhead and frame stations: F0 34.7%, F1 42.2%, F2 51.5%, F3 60.7%, F4 69.6%, F5 76.8%, F6 85.0%, F7 89.2%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| capacitor bank (magazine) | 34.0 to 41.9 | -0.90 to 0.90 | -0.90 to 0.20 | corona arc capacitors behind the projector's breech |
| fore magazine (magazine) | 37.9 to 43.6 | -0.70 to 0.70 | 0.40 to 1.15 | under the fore battery |
| archive vault fore (archive) | 42.6 to 51.1 | -1.50 to 1.50 | -0.90 to 0.25 | archive vaults: the Starwrights' stored selves |
| aft magazine (magazine) | 51.5 to 57.9 | -0.70 to 0.70 | 0.40 to 1.15 | under the aft battery |
| dark decks (darkdeck) | 51.8 to 60.4 | -1.40 to 1.40 | 0.40 to 1.15 | dark decks: machine crew stations, unlit |
| core (ecore) | 61.1 to 68.9 | -1.10 to 1.10 | -0.90 to 1.15 | the core of trapped light (hp_core); its port opens on the deck |
| archive vault aft (archive) | 70.0 to 76.0 | -1.20 to 1.20 | -0.90 to 0.25 | archive vaults |
| shade machinery (machinery) | 70.0 to 76.0 | -1.00 to 1.00 | 0.40 to 1.15 | shade generators and the band collar's drives |
| flak magazine (magazine) | 50.8 to 56.5 | -0.70 to 0.70 | -1.50 to -1.00 | the shredder magazine, hoisting aft to F1 |
| engine room (engroom) | 85.3 to 87.8 | -0.70 to 0.70 | -0.90 to 1.15 | engine room and the three drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| crescent (shade layers) | 0.60 | three layers, thickest at the inner wall; the rims knife-thin |
| dorsal tiers and barbettes | 0.40 |  |
| flank belt | 0.30 | over the vaults and magazines |
| belly and skirt | 0.25 |  |
| stern feathers | 0.15 | thinnest; they peel first |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 31.5 (seam wanders 30.5 to 35.4) | the crescent root seam: the shade and the projector tear away from the neck, opening the capacitor bank |
| B-2 | 76.8 (seam wanders 75.7 to 78.6) | at the band collar: the stern (feathers and drives) tears away, opening the engine room and the aft vault |
| B-3 | 45.4 to 69.3 (along) | the dorsal tiers peel off band by band along their base, taking the batteries, laying the dark decks bare |
| B-4 | 5.5 to 29.4 (along) | the crescent's upper layers peel from the lower blade at the root, band by band, over the projector |

Full interiors throughout the hull (R215), hidden until a piece breaks. Eclipse breaks in layers (factions.md): shade plates peel band by band, then the body behind is bare; deaths blow it apart unevenly, a ragged bite where the core goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 65.0 | 0.00 | 0.10 |  |  |  |
| hp_breach_0 | 19.8 | 3.60 | -0.30 | port | prow | on a shade band |
| hp_breach_1 | 21.6 | -3.90 | -0.35 | stbd | prow | on a shade band |
| hp_breach_2 | 10.9 | 2.60 | -1.00 | port | prow | on a shade band |
| hp_breach_3 | 53.3 | -1.40 | 2.00 | stbd | mid | on a shade band |
| hp_breach_4 | 63.6 | 1.30 | 1.98 | port | mid | on a shade band |
| hp_breach_5 | 46.8 | -2.40 | 0.50 | stbd | mid | on a shade band |
| hp_breach_6 | 83.2 | 1.78 | 0.90 | port | eng | on a shade band |
| hp_breach_7 | 86.4 | -1.42 | -0.90 | stbd | eng | on a shade band |
| hp_rcs_0 | 44.3 | 2.24 | 0.95 | port |  |  |
| hp_rcs_1 | 44.3 | -2.24 | 0.95 | stbd |  |  |
| hp_rcs_2 | 76.8 | 2.10 | 0.00 | port |  |  |
| hp_rcs_3 | 76.8 | -2.10 | 0.00 | stbd |  |  |
| hp_board_0 | 58.6 | 2.15 | 0.95 | port |  |  |
| hp_board_1 | 58.6 | -2.15 | 0.95 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 237 objects, 27 parts, 634 close pairs, 389 rays, 4 guns, 0 sensor pairs, 3 turrets swept, 7 cones, 15 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Three big engines stacked one over another, each about a third of the stern's height, standing 2.6 behind the hull, which ends 0.9 sooner and narrows in plan round them (issue 618, the Board's massing round).** the side view and the beauty show three big bells stacked filling the stern; the sheet's diamond of four read small and hid behind the feathers, whose last row now ends at the hull's end.
- **Engines are eclipse rings, not flame.** factions.md: "no flaming bells. An eclipse ring of pale light": each bell has a black shade disc with a thin pale green-white ring inside its lip.
- **Batteries by data.js slot.** d_boss carries gauss T twice, doom F and flak T: the two big mounts are the null cannons (the aft one superfires on a barbette), the projector is the corona arc, the small aft mount is the null shredder.
- **Belly shredder F2 cut; the deck shredder F1 is the whole flak slot.** R241 (Ryan, Nov 13 2026: "all ships should have weapons that match their actual weapons in game"; issue 676 weapon-match check): flak fires 3 shots a volley and each shredder has five needle muzzles, so two shredders took turns and each fell silent on some volleys; one shredder fires on every volley. The board is flat, so the belly added no cover the game uses.
- **B-1 runs on past both flanks to twice the body half-beam.** issue 676 PC destruction proof: without F2 the hull bounds change; a path ending near the flank let the main deck, forward frame and liner tear at different places from their plating (23 triangles outside their piece). Extending the existing end stations keeps the plan kink while aligning the tear through the hull depth.
- **Weapons built from the lore, not the picture's generic turrets (R221).** Ryan: "their turrets look the same as hullbreakers"; the picture draws box turrets with round twin barrels. The null cannons are rail guns (slim round rail pairs with banded collars) firing through the slot of a thin arched crescent shade, the shredders fans of needle rails, all in the hull's curved, layered, banded language (pass 2: "super blocky"), the projector an arc emitter with a crown of electrode horns round the crest's black disc (tools/blender/kits/eclipse/README.md).
- **The green hexagon on the deck is the core port, not a gun.** the faction's green is the trapped core seen through gaps; the flak slot is the small twin.
- **The crescent is one thick tiered band: the broad outer band flush with a thick outer wall, the inner layer stepped down close inside it, the root layer on the band (issue 618, the Board's massing round).** judged against the whole concept: the sheet's thin blade with a raised inner ribbon read as two thin blades with a wide gap between them; the concept is one broad plated band with a stepped inner layer close against it.
- **The crescent is three stacked layers with a corona line on each rim.** factions.md: broad layered plates, the green a thin line on every shade rim; the concept shows two stepped bands and a lip; the layers are also how it breaks (band by band).
- **Low round drums under both batteries, slimmed to the turret feet (R221 pass 2).** so the fore twin clears the tier when it trains aft and fires aft over the aft twin's muzzles, and the aft twin fires over the fore one (the fit check found both).
- **Attitude thrusters, deck and belly hatches, corona strip lights, heat panels added.** a ship in space needs thrusters; the picture shows no underside.
- **B-1 kinks aft round the projector's breech collars (to 4.1 on the axis); B-2 runs aft of the collar thrusters at the flanks (issue 618).** R226: a machine never crosses a seam; the projector and the thrusters ride whole with one piece.
- **B-3 (the dorsal tiers' peel) raised to about 1.7, through the tiers (issue 618).** at 1.45 the game's torn peel plane reached the upper deck's edge (1.2) and left 15 deck triangles past the torn plating (death_seam_check); at 1.7 it still takes the tiers and the batteries.
- **B-4 (the crescent layers' peel) is a level plane at 0.9 over the bow compartment (issue 618).** the game's longitudinal seam is one level plane (RECIPE.md, format version 1); at 0.9 it clears the projector's collars and peels the root and upper layers off the blade.
- **Two boarding origins on the flanks over the belt, between the strip lights (issue 618).** the game contract needs one a side on the mid hull (HARDPOINTS.md).
- **The projector's hard point is its lens, at the crest's centre (issue 618).** the horns' meeting point ahead of it is open space, which the export check refuses as off the mesh; the arc leaves from the lens.
- **Plate courses on the projector's collars, column and head, and stiffener rings on the engine bells (issue 618).** R224 measured on the build: the projector was 0.44 of the hull's triangles and 0.33 of its edges per square unit, the engines 0.68 of its edges; the kit now lays plates at the hull's plate size, so a big part keeps the density.
- **The crescent band is 1.65 wide at its sides.** the plan of record (the 8c sheet's top view) gives 1.3, the beauty reads broader; the band sits between the two so the beauty's fat brim reads without losing the plan.

## Designed here, not shown in the picture

- The belly under the skirt is designed here; the picture does not show the underside.
- Q1p (attitude thruster quad): neck flank.
- Q2p (attitude thruster quad): on the band collar.
- Q1s (attitude thruster quad): neck flank.
- Q2s (attitude thruster quad): on the band collar.
