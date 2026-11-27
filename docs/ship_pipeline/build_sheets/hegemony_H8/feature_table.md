# hegemony_H8: Cordon destroyer (Hegemony Navy escort), build sheet

Hegemony Navy (hegemony) | class Destroyer | version 1 (first sheet), 2026-11-22 | blockout: rendered in the issue 1412 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_H8 <out> render` rebuilds it from this file

**Length 9.5 world units** (data.js h_interdictor (cls 'Destroyer', 'Cordon destroyer'; the Godot rules table godot/rules/data/tables.json carries it); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5; game folder H8_23 (AI_HULLS hegemony|Destroyer)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | ion | F | 1 | I1 (1) |
| 1 | turbo | T | 2 | T1 (2) |

| Check | Value |
|---|---|
| model length | 9.991 |
| length side | 10.012 |
| length top | 10.012 |
| length disagreement percent | 0.0 |
| beam top | 3.362 |
| beam bow | 3.362 |
| beam disagreement percent | 0.0 |
| height side | 2.075 |
| height bow | 2.075 |
| height disagreement percent | 0.0 |
| widest at station percent | 11.1 |
| hull beam | 3.2 |
| hull depth | 1.45 |
| L to B hull | 2.97 |
| L to H hull | 6.55 |
| prow overhang | 0.07 |
| outline iou percent | 92.0 |
| mass outline iou percent | 92.1 |
| PASS | False |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | ion cannon, stepped accelerator and blue emitter (fixed) | 1 barrel | 10.2 | 0.00 | -0.05 | forward | F ion | designed | R287, R289: broad blue emitter lens at the back, nested capacitor rings, inner glow and a framed muzzle lip, all inside the bow face |
| T1 | plasma lance, twin turret | 2 barrels | 36.7 | 0.00 | 0.75 | forward | T turbo | picture | the Plasma lance (turbo T, 2 shots over 2 barrels, one each volley): one low turret on the centreline, on the ion block's aft deck over the step |
| A1 | sensor fin, 0.28 tall, 1.2 long | 1 | 55.8 | 0.00 | 0.40 | - | - | picture | the one low sensor fin, on the aft body below the lance's firing plane (designs.md: aft of the step so it clears the arc; R240) |
| E1 | engine, rectangular nozzle 0.68 x 0.56 | 1 | 99.8 | 0.45 | -0.10 | exhaust aft | - | picture | port nozzle pod: a rectangular nozzle, blue-white throat, on the transom |
| E2 | engine, rectangular nozzle 0.68 x 0.56 | 1 | 99.8 | -0.45 | -0.10 | exhaust aft | - | picture | starboard nozzle pod: a rectangular nozzle, blue-white throat, on the transom |
| Q1p0 | retro thruster, two rectangular nozzles | 1 | 0.7 | 0.88 | 0.42 | - | - | designed | retro thruster on the bow face corner (lore 3.4: backing off is cheap) |
| Q1p1 | retro thruster, two rectangular nozzles | 1 | 0.7 | 0.88 | -0.42 | - | - | designed | retro thruster on the bow face corner (lore 3.4: backing off is cheap) |
| Q2p | attitude thruster, two rectangular nozzles | 1 | 15.2 | 1.50 | 0.42 | - | - | designed | bow attitude thruster on the upper facet |
| Q3p | attitude thruster, two rectangular nozzles | 1 | 87.8 | 0.89 | 0.20 | - | - | designed | stern attitude thruster on the upper facet |
| D1p | flush drone doors 0.55 x 0.2 | 1 | 78.3 | 0.91 | 0.21 | - | - | picture | the faction's small drone bay: flush armoured doors on the aft body's upper facet (designs.md); no hangar in the rules, so no craft fly |
| W1p | vision slit 0.3 x 0.06 | 1 | 12.7 | 1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W2p | vision slit 0.3 x 0.06 | 1 | 16.7 | 1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W3p | vision slit 0.3 x 0.06 | 1 | 26.2 | 1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W4p | vision slit 0.3 x 0.06 | 1 | 30.7 | 1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W5p | vision slit 0.3 x 0.06 | 1 | 35.2 | 1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W6p | vision slit 0.3 x 0.06 | 1 | 39.7 | 1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| V1p | louvre panel 0.2 x 0.6 | 1 | 15.2 | 0.45 | 0.75 | - | - | picture | heat louvre over the ion capacitors |
| V2p | louvre panel 0.2 x 0.4 | 1 | 27.7 | 0.55 | 0.75 | - | - | picture | heat louvre over the reactor |
| V3p | louvre panel 0.2 x 0.5 | 1 | 63.8 | 0.42 | 0.40 | - | - | picture | heat louvre over the crew decks |
| V4p | louvre panel 0.2 x 0.5 | 1 | 80.8 | 0.42 | 0.40 | - | - | picture | heat louvre over the engine room |
| LBpf | module latch row (4 clamps) | 1 | 17.7 | 0.95 | 0.75 | - | - | picture | locks the two block modules together across the band |
| LBpa | module latch row (4 clamps) | 1 | 23.7 | 0.95 | 0.75 | - | - | picture | locks the two block modules together across the band |
| LApf | module latch row (3 clamps) | 1 | 68.3 | 0.45 | 0.43 | - | - | picture | locks two aft body modules together across the band |
| LApa | module latch row (3 clamps) | 1 | 74.3 | 0.45 | 0.43 | - | - | picture | locks two aft body modules together across the band |
| H50p | square hatch 0.4 | 1 | 31.2 | 1.54 | -0.45 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| H51p | square hatch 0.4 | 1 | 83.3 | 0.92 | -0.37 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| Q1s0 | retro thruster, two rectangular nozzles | 1 | 0.7 | -0.88 | 0.42 | - | - | designed | retro thruster on the bow face corner (lore 3.4: backing off is cheap) |
| Q1s1 | retro thruster, two rectangular nozzles | 1 | 0.7 | -0.88 | -0.42 | - | - | designed | retro thruster on the bow face corner (lore 3.4: backing off is cheap) |
| Q2s | attitude thruster, two rectangular nozzles | 1 | 15.2 | -1.50 | 0.42 | - | - | designed | bow attitude thruster on the upper facet |
| Q3s | attitude thruster, two rectangular nozzles | 1 | 87.8 | -0.89 | 0.20 | - | - | designed | stern attitude thruster on the upper facet |
| D1s | flush drone doors 0.55 x 0.2 | 1 | 78.3 | -0.91 | 0.21 | - | - | picture | the faction's small drone bay: flush armoured doors on the aft body's upper facet (designs.md); no hangar in the rules, so no craft fly |
| W1s | vision slit 0.3 x 0.06 | 1 | 12.7 | -1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W2s | vision slit 0.3 x 0.06 | 1 | 16.7 | -1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W3s | vision slit 0.3 x 0.06 | 1 | 26.2 | -1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W4s | vision slit 0.3 x 0.06 | 1 | 30.7 | -1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W5s | vision slit 0.3 x 0.06 | 1 | 35.2 | -1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| W6s | vision slit 0.3 x 0.06 | 1 | 39.7 | -1.61 | -0.07 | - | - | picture | blue-white window of the block's crew decks, between the blue lines |
| V1s | louvre panel 0.2 x 0.6 | 1 | 15.2 | -0.45 | 0.75 | - | - | picture | heat louvre over the ion capacitors |
| V2s | louvre panel 0.2 x 0.4 | 1 | 27.7 | -0.55 | 0.75 | - | - | picture | heat louvre over the reactor |
| V3s | louvre panel 0.2 x 0.5 | 1 | 63.8 | -0.42 | 0.40 | - | - | picture | heat louvre over the crew decks |
| V4s | louvre panel 0.2 x 0.5 | 1 | 80.8 | -0.42 | 0.40 | - | - | picture | heat louvre over the engine room |
| LBsf | module latch row (4 clamps) | 1 | 17.7 | -0.95 | 0.75 | - | - | picture | locks the two block modules together across the band |
| LBsa | module latch row (4 clamps) | 1 | 23.7 | -0.95 | 0.75 | - | - | picture | locks the two block modules together across the band |
| LAsf | module latch row (3 clamps) | 1 | 68.3 | -0.45 | 0.43 | - | - | picture | locks two aft body modules together across the band |
| LAsa | module latch row (3 clamps) | 1 | 74.3 | -0.45 | 0.43 | - | - | picture | locks two aft body modules together across the band |
| H50s | square hatch 0.4 | 1 | 31.2 | -1.54 | -0.45 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| H51s | square hatch 0.4 | 1 | 83.3 | -0.92 | -0.37 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| H1 | square hatch 0.4 | 1 | 15.2 | 0.00 | 0.75 | - | - | picture | deck hatch over the ion capacitor room |
| H2 | square hatch 0.3 | 1 | 78.3 | 0.00 | 0.40 | - | - | picture | deck hatch to the aft crew decks |
| H3 | square hatch 0.3 | 1 | 85.8 | 0.00 | 0.40 | - | - | picture | deck hatch to the engine room |
| H4 | square hatch 0.5 | 1 | 28.2 | 0.00 | -0.76 | - | - | picture | belly hatch on the armour step: the reactor's service hatch |
| H6 | square hatch 0.4 | 1 | 63.3 | 0.00 | -0.62 | - | - | picture | aft belly hatch: stores |

Totals: 2 gun mounts with 3 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| pale grey module plate, steel-blue trim (paint stage) | 0.7 | 95.8 | whole hull |  |
| implant-blue light strips (the blue line), blue-white nozzles and windows | 0.7 | 95.8 | the flank bands, the stern |  |
| no rust, no warm light, no asymmetry | 0.7 | 95.8 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the ion block | 10.2 to 46.3 | -1.60 to 1.60 | -0.70 to 0.75 | pale grey module plate | the deep forward block: slab sides at the full beam, a flat deck, chamfered deck edges, upper facets, the tall flank band in two tiers, lower facets, a flat belly; its aft face is the step |
| Hull: the aft body | 46.3 to 95.8 | -0.95 to 0.95 | -0.62 to 0.40 | pale grey module plate | one narrower hull, sides parallel to a flat transom, the same faceted section with one flank band |
| Bow face round the ion trench | 0.7 to 10.2 | -1.58 to 1.58 | -0.70 to 0.75 | pale grey module plate | the blunt bow face (never a ship's stem): the block's facets run to it, the trench recessed in its middle |
| Belly armour step | 6.2 to 43.2 | -0.95 to 0.95 | -0.76 to -0.67 | recessed grey | a second armour layer under the ion block (a worked belly, R185 (5)) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck 0.12 (11% to 19%); main deck 0.12 (22% to 45%); main deck -0.10 (49% to 70%).

Bulkhead and frame stations: F1 15.2%, F2 28.2%, F3 42.2%, F4 60.3%, F5 83.3%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| ion capacitors (machinery) | 11.2 to 19.2 | -0.90 to 0.90 | -0.50 to 0.06 | the ion cannon's capacitor banks and field drivers behind the trench |
| fwd corridor (hcorr) | 11.2 to 19.2 | -1.23 to 1.23 | 0.18 to 0.50 | white corridors of the forward crew deck |
| command (bridge) | 22.2 to 28.7 | -0.90 to 0.90 | 0.18 to 0.52 | the command deck: the Registry link room |
| lance room (magazine) | 29.7 to 43.7 | -0.75 to 0.75 | 0.18 to 0.50 | the lance's capacitor room under the turret |
| reactor (core) | 23.2 to 44.8 | 0.05 to -0.05 | -0.55 to 0.06 | the reactor (hp_core): its power runs forward to the trench and up to the lance |
| rack 0 p (hrack) | 23.2 to 28.2 | 0.95 to 1.23 | -0.50 to 0.04 | racks of identical equipment beside the reactor (factions.md "Inside") |
| rack 0 s (hrack) | 23.2 to 28.2 | -1.23 to -0.95 | -0.50 to 0.04 | racks of identical equipment beside the reactor (factions.md "Inside") |
| rack 1 p (hrack) | 30.2 to 35.2 | 0.95 to 1.23 | -0.50 to 0.04 | racks of identical equipment beside the reactor (factions.md "Inside") |
| rack 1 s (hrack) | 30.2 to 35.2 | -1.23 to -0.95 | -0.50 to 0.04 | racks of identical equipment beside the reactor (factions.md "Inside") |
| rack 2 p (hrack) | 37.2 to 42.2 | 0.95 to 1.23 | -0.50 to 0.04 | racks of identical equipment beside the reactor (factions.md "Inside") |
| rack 2 s (hrack) | 37.2 to 42.2 | -1.23 to -0.95 | -0.50 to 0.04 | racks of identical equipment beside the reactor (factions.md "Inside") |
| emerg mid (hemerg) | 22.2 to 45.3 | -0.08 to 0.08 | 0.50 to 0.53 | the blue emergency light strip along the corridor ceiling |
| aft crew (hcorr) | 49.0 to 69.8 | -0.61 to 0.61 | -0.05 to 0.20 | crew decks and corridors in the aft body, white, numbered |
| aft stores (machinery) | 49.0 to 69.8 | -0.65 to 0.65 | -0.42 to -0.15 | coolant and fuel plant under the crew deck |
| engine room (engroom) | 72.8 to 93.3 | -0.61 to 0.61 | -0.42 to 0.20 | the engine room: the feeds to the two nozzle pods |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| deck and facets | 0.12 | machined plate in modules, flush panels over it |
| bow face | 0.30 | the blunt bow round the trench, the thickest plate |
| step face | 0.20 | the block's aft face |
| belly and armour step | 0.15 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 46.3 (seam wanders 45.7 to 47.1) | the ion block tears from the aft body at the step, the trench, the reactor and the lance with it |
| B-2 | 71.3 (seam wanders 70.6 to 72.1) | the stern module falls away at the second bulkhead ring, the nozzles and the engine room with it |

Full interiors throughout the hull (R215), hidden until a piece breaks: the ion capacitors, white corridors with blue emergency light, the command deck, the lance room, the reactor and racks of identical equipment, the aft crew decks, the engine room. The Hegemony breaks in modules at the bulkhead rings (factions.md).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 34.2 | 0.00 | -0.25 |  |  |  |
| hp_breach_0 | 20.7 | 1.67 | 0.08 | port | prow | on a module joint |
| hp_breach_1 | 47.5 | -1.02 | 0.08 | stbd | mid | on a module joint |
| hp_breach_2 | 71.3 | 1.02 | 0.08 | port | eng | on a module joint |
| hp_rcs_0 | -0.5 | 0.88 | 0.42 | port |  |  |
| hp_board_0 | 60.3 | 1.01 | 0.00 | port |  |  |
| hp_rcs_1 | -0.5 | -0.88 | 0.42 | stbd |  |  |
| hp_board_1 | 60.3 | -1.01 | 0.00 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 228 objects, 52 parts, 333 close pairs, 259 rays, 2 guns, 12 sensor pairs, 1 turrets swept, 10 cones, 31 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The step sits at 48 percent (x 0.2), where both views draw it, not at the table's 35 percent; the ion block is 4.55 long, the aft body 4.95.** the sheet's top and side views and the beauty all put the step near half length (the anvil Ryan saw); designs.md says the step reads as tabled, a slip in the table's number.
- **The lance turret sits on the ion block's aft deck at 38 percent, just ahead of the step (the top view's and the three-quarter view's place), and the sensor fin on the lower aft body just aft of the step.** R240: the fin stays below the turret's firing plane, so no gun aims through a sensor (designs.md: the fin aft of the step so it clears the arc); the table's turret at 48 percent would sit on the aft body behind the fin.
- **The ion trench is the Dominion's accelerator at 1.1 by 0.6: three stepped capacitor rings, a broad blue lens block at the back, an inner glow and a muzzle lip, its roof opened within the bow module.** designs.md: three stepped capacitor rings, a blue lens, an inset lip; R287 and R289: the same accelerator on every Navy trench, the roof window so the lens reads at the whole-ship camera.
- **Two nozzle pods on the transom; the top view's third and fourth pods and the side view's ventral fin are not built.** designs.md: two pods govern, the extra pods and the ventral fin are picture slips; rule 4.1: no keel fin.
- **The block's tall flank band carries two blue lines with the crew deck windows between them (the concept's two rows); the aft body carries one.** the side view and the beauty draw two rows on the block; factions.md: a line of blue light.
- **Flush drone doors on the aft body's upper facets, one a side, are kept with no craft: the rules give the Cordon no hangar.** designs.md: flush flank doors only, the faction's small drone bays; nothing launches from them in the game.
- **Four retro thrusters on the bow face corners (the concept's four small blocks), attitude thrusters on the facets, louvres, hatches, module latch rows and a belly armour step added.** a ship in space needs thrusters and access (lore 3.4); every part has a job (R221); a worked belly (R185 (5)).
- **Even panel grid of two module sizes, bulkhead rings as raised bands with a deep seam: one on the block, one round the aft body at the step, one at 74 percent.** paint direction hegemony.md; designs.md break lines (the step carries the forward break).

## Designed here, not shown in the picture

- Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled.
- I1 (ion cannon, stepped accelerator and blue emitter (fixed)): R287, R289: broad blue emitter lens at the back, nested capacitor rings, inner glow and a framed muzzle lip, all inside the bow face.
- Q1p0 (retro thruster, two rectangular nozzles): retro thruster on the bow face corner (lore 3.4: backing off is cheap).
- Q1p1 (retro thruster, two rectangular nozzles): retro thruster on the bow face corner (lore 3.4: backing off is cheap).
- Q2p (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3p (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
- Q1s0 (retro thruster, two rectangular nozzles): retro thruster on the bow face corner (lore 3.4: backing off is cheap).
- Q1s1 (retro thruster, two rectangular nozzles): retro thruster on the bow face corner (lore 3.4: backing off is cheap).
- Q2s (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3s (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
