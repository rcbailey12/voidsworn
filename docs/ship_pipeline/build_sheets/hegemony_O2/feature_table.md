# hegemony_O2: Convoy transport (Hegemony Navy objective), build sheet

Hegemony Navy (hegemony) | class transport | version 1 (first sheet), 2026-11-20 | blockout: rendered in the issue 1413 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_O2 <out> render` rebuilds it from this file

**Length 11.0 world units** (data.js obj_transport (no data.js ship: tools/recipe/gamedata.py OBJECTIVES, the intercept transport); length from godot/render/hull_table.gd CLS_LEN['Transport'] = 11.0 (drawn x SHIP_K 1.6 = 17.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|

| Check | Value |
|---|---|
| model length | 11.225 |
| length side | 11.25 |
| length top | 11.25 |
| length disagreement percent | 0.0 |
| beam top | 3.738 |
| beam bow | 3.737 |
| beam disagreement percent | 0.0 |
| height side | 2.05 |
| height bow | 2.05 |
| height disagreement percent | 0.0 |
| widest at station percent | 34.1 |
| hull beam | 3.6 |
| hull depth | 1.32 |
| L to B hull | 3.06 |
| L to H hull | 8.33 |
| prow overhang | 0.21 |
| outline iou percent | 90.5 |
| mass outline iou percent | 90.7 |
| PASS | False |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| D1 | docking clamp row (3 clamps) | 1 | 0.8 | 0.30 | 0.00 | - | - | picture | a docking clamp on the bumper: the transport mates to a station or a tug here |
| D2 | docking clamp row (3 clamps) | 1 | 0.8 | -0.30 | 0.00 | - | - | picture | a docking clamp on the bumper: the transport mates to a station or a tug here |
| C1 | cargo module 0.86 x 1.86 x 1.00 | 1 | 35.5 | 0.00 | 0.18 | - | - | picture | one of four identical cargo modules locked in the well: a plain slab box, its lid, stiffener ribs, mooring clamps (designs.md); a loaded module is its own break piece |
| C2 | cargo module 0.86 x 1.86 x 1.00 | 1 | 45.3 | 0.00 | 0.18 | - | - | picture | one of four identical cargo modules locked in the well: a plain slab box, its lid, stiffener ribs, mooring clamps (designs.md); a loaded module is its own break piece |
| C3 | cargo module 0.86 x 1.86 x 1.00 | 1 | 56.3 | 0.00 | 0.18 | - | - | picture | one of four identical cargo modules locked in the well: a plain slab box, its lid, stiffener ribs, mooring clamps (designs.md); a loaded module is its own break piece |
| C4 | cargo module 0.86 x 1.86 x 1.00 | 1 | 66.1 | 0.00 | 0.18 | - | - | picture | one of four identical cargo modules locked in the well: a plain slab box, its lid, stiffener ribs, mooring clamps (designs.md); a loaded module is its own break piece |
| LM1p | mooring clamp pair | 1 | 35.5 | 1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM1s | mooring clamp pair | 1 | 35.5 | -1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM2p | mooring clamp pair | 1 | 45.3 | 1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM2s | mooring clamp pair | 1 | 45.3 | -1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM3p | mooring clamp pair | 1 | 56.3 | 1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM3s | mooring clamp pair | 1 | 56.3 | -1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM4p | mooring clamp pair | 1 | 66.1 | 1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| LM4s | mooring clamp pair | 1 | 66.1 | -1.22 | 0.62 | - | - | picture | mooring clamps on the rail deck beside the module: they hold its lifting eyes |
| A1 | sensor fin, 0.3 tall, 1.3 long | 1 | 20.5 | 0.00 | 0.58 | - | - | picture | the one low sensor fin: the navigation and convoy link sensors; the bridge is under it |
| E1 | engine, rectangular nozzle 0.5 x 0.66 | 1 | 99.8 | 1.14 | -0.16 | exhaust aft | - | picture | nozzle pod 1 of the flat row: a rectangular mouth, blue-white throat |
| E2 | engine, rectangular nozzle 0.5 x 0.66 | 1 | 99.8 | 0.38 | -0.16 | exhaust aft | - | picture | nozzle pod 2 of the flat row: a rectangular mouth, blue-white throat |
| E3 | engine, rectangular nozzle 0.5 x 0.66 | 1 | 99.8 | -0.38 | -0.16 | exhaust aft | - | picture | nozzle pod 3 of the flat row: a rectangular mouth, blue-white throat |
| E4 | engine, rectangular nozzle 0.5 x 0.66 | 1 | 99.8 | -1.14 | -0.16 | exhaust aft | - | picture | nozzle pod 4 of the flat row: a rectangular mouth, blue-white throat |
| Q1p | retro thruster, two rectangular nozzles | 1 | 0.9 | 0.72 | 0.00 | - | - | designed | retro thruster on the bow face: the transport brakes into a dock |
| Q2p | attitude thruster, two rectangular nozzles | 1 | 82.9 | 1.50 | 0.35 | - | - | designed | stern attitude thruster on the upper facet |
| W1p | vision slit 0.2 x 0.06 | 1 | 12.5 | 1.44 | 0.09 | - | - | picture | blue-white window of the crew deck |
| W2p | vision slit 0.2 x 0.06 | 1 | 15.6 | 1.54 | 0.10 | - | - | picture | blue-white window of the crew deck |
| W3p | vision slit 0.2 x 0.06 | 1 | 18.8 | 1.64 | 0.11 | - | - | picture | blue-white window of the crew deck |
| H10p | square hatch 0.3 | 1 | 34.8 | 1.80 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| H11p | square hatch 0.3 | 1 | 41.9 | 1.80 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| H12p | square hatch 0.3 | 1 | 61.5 | 1.55 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| H13p | square hatch 0.3 | 1 | 79.3 | 1.55 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| V1p | louvre panel 0.4 x 0.5 | 1 | 76.7 | 0.70 | 0.61 | - | - | picture | heat louvre over the reactor and the drives |
| V2p | louvre panel 0.4 x 0.5 | 1 | 82.0 | 0.70 | 0.61 | - | - | picture | heat louvre over the reactor and the drives |
| V3p | louvre panel 0.4 x 0.5 | 1 | 87.3 | 0.70 | 0.60 | - | - | picture | heat louvre over the reactor and the drives |
| V4p | louvre panel 0.2 x 0.6 | 1 | 40.4 | 1.35 | 0.62 | - | - | picture | hold louvre on the rail deck: the holds' air plant |
| V5p | louvre panel 0.2 x 0.6 | 1 | 61.2 | 1.35 | 0.62 | - | - | picture | hold louvre on the rail deck: the holds' air plant |
| Q1s | retro thruster, two rectangular nozzles | 1 | 0.9 | -0.72 | 0.00 | - | - | designed | retro thruster on the bow face: the transport brakes into a dock |
| Q2s | attitude thruster, two rectangular nozzles | 1 | 82.9 | -1.50 | 0.35 | - | - | designed | stern attitude thruster on the upper facet |
| W1s | vision slit 0.2 x 0.06 | 1 | 12.5 | -1.44 | 0.09 | - | - | picture | blue-white window of the crew deck |
| W2s | vision slit 0.2 x 0.06 | 1 | 15.6 | -1.54 | 0.10 | - | - | picture | blue-white window of the crew deck |
| W3s | vision slit 0.2 x 0.06 | 1 | 18.8 | -1.64 | 0.11 | - | - | picture | blue-white window of the crew deck |
| H10s | square hatch 0.3 | 1 | 34.8 | -1.80 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| H11s | square hatch 0.3 | 1 | 41.9 | -1.80 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| H12s | square hatch 0.3 | 1 | 61.5 | -1.55 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| H13s | square hatch 0.3 | 1 | 79.3 | -1.55 | -0.20 | - | - | picture | flank hatch on the band: stores and crew access to the holds |
| V1s | louvre panel 0.4 x 0.5 | 1 | 76.7 | -0.70 | 0.61 | - | - | picture | heat louvre over the reactor and the drives |
| V2s | louvre panel 0.4 x 0.5 | 1 | 82.0 | -0.70 | 0.61 | - | - | picture | heat louvre over the reactor and the drives |
| V3s | louvre panel 0.4 x 0.5 | 1 | 87.3 | -0.70 | 0.60 | - | - | picture | heat louvre over the reactor and the drives |
| V4s | louvre panel 0.2 x 0.6 | 1 | 40.4 | -1.35 | 0.62 | - | - | picture | hold louvre on the rail deck: the holds' air plant |
| V5s | louvre panel 0.2 x 0.6 | 1 | 61.2 | -1.35 | 0.62 | - | - | picture | hold louvre on the rail deck: the holds' air plant |
| H1 | square hatch 0.4 | 1 | 10.3 | 0.00 | 0.47 | - | - | picture | deck hatch over the bridge |
| H2 | square hatch 0.4 | 1 | 81.1 | 0.00 | 0.61 | - | - | picture | deck hatch over the engine room |
| H3 | square hatch 0.5 | 1 | 50.8 | 0.00 | -0.76 | - | - | picture | belly hatch on the armour step: the lower hold |

Totals: 0 gun mounts with 0 barrels; 0 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| pale grey module plate, steel-blue trim (paint stage) | 1.8 | 99.8 | whole hull |  |
| implant-blue light strips (the blue line), blue-white nozzles and windows | 1.8 | 99.8 | the flank bands, the stern |  |
| no rust, no warm light, no asymmetry, no weapons | 1.8 | 99.8 | factions.md Never; designs.md: readable as defenseless |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the wedge and the rails | 1.8 to 93.1 | -1.80 to 1.80 | -0.70 to 0.62 | pale grey module plate | a plain wedge bow, the rails either side of the cargo well, the drive section aft: a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band with the blue line, lower facets, a flat worked belly |
| Belly armour step | 13.4 to 89.1 | -0.96 to 0.96 | -0.76 to -0.60 | recessed grey | a second plate under the holds |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck 0.00 (10% to 28%); hold deck -0.32 (31% to 50%); hold deck -0.32 (52% to 70%); main deck -0.10 (74% to 91%).

Bulkhead and frame stations: F1 12.5%, F2 20.5%, F3 27.7%, F4 35.7%, F5 45.5%, F6 56.2%, F7 66.0%, F8 74.9%, F9 82.0%, F10 89.1%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| bridge (bridge) | 13.4 to 27.2 | 0.05 to -0.05 | 0.06 to 0.40 | the bridge under the sensor fin: the convoy link to its escorts |
| crew deck p (hcorr) | 10.7 to 27.2 | 0.85 to -0.05 | 0.06 to 0.40 | white corridors and crew berths, numbered posts |
| crew deck s (hcorr) | 10.7 to 27.2 | 0.05 to -0.85 | 0.06 to 0.40 | white corridors and crew berths, numbered posts |
| bow stores (hold) | 13.4 to 27.2 | 0.05 to -0.05 | -0.50 to -0.06 | bow stores and the retro thrusters' feeds |
| hold fwd (hold) | 31.7 to 49.3 | -0.90 to 0.90 | -0.27 to 0.06 | the lower hold: racks of identical sealed crates under the well floor |
| rail corr fwd p (hcorr) | 31.7 to 49.3 | 1.10 to -0.05 | 0.12 to 0.42 | the rails' corridors either side of the well, white, numbered |
| rail corr fwd s (hcorr) | 31.7 to 49.3 | 0.05 to -1.10 | 0.12 to 0.42 | the rails' corridors either side of the well, white, numbered |
| emerg fwd p (hemerg) | 31.7 to 49.3 | 1.10 to -0.05 | 0.42 to 0.45 | blue emergency light along the rails' corridors |
| emerg fwd s (hemerg) | 31.7 to 49.3 | 0.05 to -1.10 | 0.42 to 0.45 | blue emergency light along the rails' corridors |
| hold aft (hold) | 52.3 to 70.0 | -0.90 to 0.90 | -0.27 to 0.06 | the lower hold: racks of identical sealed crates under the well floor |
| rail corr aft p (hcorr) | 52.3 to 70.0 | 1.10 to -0.05 | 0.12 to 0.42 | the rails' corridors either side of the well, white, numbered |
| rail corr aft s (hcorr) | 52.3 to 70.0 | 0.05 to -1.10 | 0.12 to 0.42 | the rails' corridors either side of the well, white, numbered |
| emerg aft p (hemerg) | 52.3 to 70.0 | 1.10 to -0.05 | 0.42 to 0.45 | blue emergency light along the rails' corridors |
| emerg aft s (hemerg) | 52.3 to 70.0 | 0.05 to -1.10 | 0.42 to 0.45 | blue emergency light along the rails' corridors |
| reactor (core) | 74.4 to 82.9 | 0.05 to -0.05 | -0.05 to 0.42 | the reactor (hp_core) |
| engine room (engroom) | 83.8 to 90.9 | 0.05 to -0.05 | -0.55 to 0.42 | the engine room and the four drives' feeds |
| fuel (machinery) | 74.4 to 82.9 | 0.05 to -0.05 | -0.55 to -0.15 | fuel and coolant plant under the reactor |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| deck and facets | 0.12 | machined plate in modules, flush panels over it |
| bow face and bumper | 0.20 | the solid bumper plate |
| belly and armour step | 0.15 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 29.3 (seam wanders 28.6 to 29.8) | the bow module tears off at the first band, the bridge with it |
| B-2 | 50.8 (seam wanders 50.2 to 51.4) | the hull parts at the middle band between the module pairs, the well floor torn across |
| B-3 | 72.4 (seam wanders 71.7 to 73.1) | the drive section falls away at the last band, the nozzles with it |

Full interiors (R215), hidden until a piece breaks: white corridors, blue emergency light, the bridge, the holds of identical sealed crates, the reactor, the engine room. Each loaded cargo module breaks off as its own piece; the hull breaks in modules at the bands (factions.md).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 78.4 | 0.00 | 0.15 |  |  |  |
| hp_breach_0 | 29.3 | 1.86 | 0.07 | port | prow | on a module joint |
| hp_breach_1 | 50.8 | -1.86 | 0.07 | stbd | mid | on a module joint |
| hp_breach_2 | 50.8 | 1.86 | 0.07 | port | mid | on a module joint |
| hp_breach_3 | 72.4 | -1.61 | 0.07 | stbd | eng | on a module joint |
| hp_rcs_0 | -0.4 | 0.72 | 0.00 | port |  |  |
| hp_board_0 | 61.5 | 1.60 | -0.12 | port |  |  |
| hp_rcs_1 | -0.4 | -0.72 | 0.00 | stbd |  |  |
| hp_board_1 | 61.5 | -1.60 | -0.12 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 213 objects, 50 parts, 348 close pairs, 131 rays, 0 guns, 0 sensor pairs, 0 turrets swept, 8 cones, 27 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Four identical cargo modules in the well, two either side of the middle band (centres 15.6, 5.6, -5.6 and -15.6 percent off midships).** designs.md: four modules govern (the beauty draws three); the module bands at 28, 50 and 72 percent never cross a module, so each loaded module breaks off whole.
- **The module rings are raised trim bands with a deep seam at 28, 50 and 72 percent.** designs.md break lines; factions.md: the Hegemony breaks in modules at the bulkhead rings.
- **The sensor fin is one low fin at 19 percent, 0.3 tall, on the bow deck ahead of the well.** designs.md: one low fin ahead of the cargo row; at 25 percent it would stand on the well's forward wall.
- **The bow face is a solid bumper plate with two docking clamp rows and two retro thrusters; no trench, no gun, no terrace.** designs.md: readable as defenseless; the clamps mate it to a dock or a tug; data gives the transport no weapon (battle.js intercept clears its weapons).
- **Four rectangular nozzle pods in one flat row at the stern (0.5 by 0.66 mouths).** designs.md and factions.md: a flat row of rectangular blue-white nozzles.
- **The well's floor holds the lower holds; the rails carry the corridors either side; the drive section aft is closed deck with reactor louvres.** every part has a job (R221); the concept shows the well running nearly to the stern, cut short here so the drive section is its own break piece (B-3).
- **Flank hatches, blue-white crew windows, hold louvres on the rail decks, mooring clamps beside each module, a belly armour step added.** a transport needs access, light and air (lore 3.3); the mooring clamps hold the modules; the concept shows no underside (R221).

## Designed here, not shown in the picture

- The belly is designed here; the concept shows no underside.
- Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled.
- Q1p (retro thruster, two rectangular nozzles): retro thruster on the bow face: the transport brakes into a dock.
- Q2p (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
- Q1s (retro thruster, two rectangular nozzles): retro thruster on the bow face: the transport brakes into a dock.
- Q2s (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
