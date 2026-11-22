# hegemony_H7: Picket frigate (Hegemony Navy escort), build sheet

Hegemony Navy (hegemony) | class Frigate | version 1 (first sheet), 2026-11-22 | blockout: rendered in the issue 1412 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_H7 <out> render` rebuilds it from this file

**Length 6.5 world units** (data.js h_picket (cls 'Frigate', 'Directorate picket'; the Godot rules table godot/rules/data/tables.json carries it); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5; game folder H7_23 (AI_HULLS hegemony|Frigate)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | laser | F | 2 | L1 (2) |
| 1 | flak | T | 3 | F1 (3) |

| Check | Value |
|---|---|
| model length | 6.84 |
| length side | 6.862 |
| length top | 6.862 |
| length disagreement percent | 0.0 |
| beam top | 2.238 |
| beam bow | 2.237 |
| beam disagreement percent | 0.0 |
| height side | 1.462 |
| height bow | 1.462 |
| height disagreement percent | 0.0 |
| widest at station percent | 54.6 |
| hull beam | 2.2 |
| hull depth | 0.9 |
| L to B hull | 2.95 |
| L to H hull | 7.22 |
| prow overhang | 0.07 |
| outline iou percent | 93.3 |
| mass outline iou percent | 93.4 |
| PASS | False |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| L1 | plasma cannon, twin casemate in the bow face (fixed) | 2 barrels | 10.1 | 0.00 | -0.05 | forward | F laser | picture | the Plasma cannon (laser F, 2 shots): a low casemate inside the bow face, two short thick barrels side by side that barely clear the face; one shot a barrel each volley |
| F1 | picket lasers, triple turret | 3 barrels | 51.5 | 0.00 | 0.52 | forward, +10 elev | T flak | picture | the Picket lasers (flak T, 3 shots over 3 emitters, one each volley) on the dorsal barbette; the plinth lifts the emitters over the low sensor fin (R240) |
| A1 | sensor fin, 0.17 tall, 1.0 long | 1 | 24.4 | 0.00 | 0.40 | - | - | picture | the one low sensor fin: the Picket's search sensors, the command deck under it |
| E1 | engine, rectangular nozzle 0.46 x 0.36 | 1 | 99.7 | 0.40 | -0.10 | exhaust aft | - | picture | port nozzle pod: a rectangular nozzle, blue-white throat, seated in the stern block |
| E2 | engine, rectangular nozzle 0.46 x 0.36 | 1 | 99.7 | -0.40 | -0.10 | exhaust aft | - | picture | starboard nozzle pod: a rectangular nozzle, blue-white throat, seated in the stern block |
| Q1p | retro thruster, two rectangular nozzles | 1 | 1.0 | 0.24 | 0.25 | - | - | designed | retro thruster on the bow face (lore 3.4: backing off is cheap; the Picket's evasive burn) |
| Q2p | attitude thruster, two rectangular nozzles | 1 | 14.2 | 0.67 | 0.21 | - | - | designed | bow attitude thruster on the upper facet |
| Q3p | attitude thruster, two rectangular nozzles | 1 | 89.5 | 0.84 | 0.14 | - | - | designed | stern attitude thruster on the upper facet |
| D1p | flush drone doors 0.4 x 0.16 | 1 | 75.6 | 0.95 | 0.20 | - | - | picture | the faction's small drone bay: flush armoured doors on the upper facet (designs.md); no hangar in the rules, so no craft fly |
| W1p | vision slit 0.2 x 0.05 | 1 | 81.4 | 0.96 | 0.04 | - | - | picture | blue-white window of the aft crew deck, over the blue line |
| W2p | vision slit 0.2 x 0.05 | 1 | 85.1 | 0.94 | 0.04 | - | - | picture | blue-white window of the aft crew deck, over the blue line |
| V1p | louvre panel 0.1 x 0.4 | 1 | 18.6 | 0.22 | 0.40 | - | - | picture | heat louvre over the cannon's capacitors |
| V2p | louvre panel 0.2 x 0.5 | 1 | 78.5 | 0.42 | 0.35 | - | - | picture | heat louvre over the engine room |
| V3p | louvre panel 0.2 x 0.5 | 1 | 53.7 | 0.50 | -0.55 | - | - | picture | belly heat louvre under the reactor |
| V4p | louvre panel 0.1 x 0.4 | 1 | 23.7 | 0.40 | -0.55 | - | - | picture | belly heat louvre under the command deck |
| LW0pf | module latch row (3 clamps) | 1 | 31.4 | 0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| LW0pa | module latch row (3 clamps) | 1 | 37.9 | 0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| LW1pf | module latch row (3 clamps) | 1 | 64.3 | 0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| LW1pa | module latch row (3 clamps) | 1 | 70.8 | 0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| H5p | square hatch 0.3 | 1 | 42.7 | 0.95 | -0.28 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| Q1s | retro thruster, two rectangular nozzles | 1 | 1.0 | -0.24 | 0.25 | - | - | designed | retro thruster on the bow face (lore 3.4: backing off is cheap; the Picket's evasive burn) |
| Q2s | attitude thruster, two rectangular nozzles | 1 | 14.2 | -0.67 | 0.21 | - | - | designed | bow attitude thruster on the upper facet |
| Q3s | attitude thruster, two rectangular nozzles | 1 | 89.5 | -0.84 | 0.14 | - | - | designed | stern attitude thruster on the upper facet |
| D1s | flush drone doors 0.4 x 0.16 | 1 | 75.6 | -0.95 | 0.20 | - | - | picture | the faction's small drone bay: flush armoured doors on the upper facet (designs.md); no hangar in the rules, so no craft fly |
| W1s | vision slit 0.2 x 0.05 | 1 | 81.4 | -0.96 | 0.04 | - | - | picture | blue-white window of the aft crew deck, over the blue line |
| W2s | vision slit 0.2 x 0.05 | 1 | 85.1 | -0.94 | 0.04 | - | - | picture | blue-white window of the aft crew deck, over the blue line |
| V1s | louvre panel 0.1 x 0.4 | 1 | 18.6 | -0.22 | 0.40 | - | - | picture | heat louvre over the cannon's capacitors |
| V2s | louvre panel 0.2 x 0.5 | 1 | 78.5 | -0.42 | 0.35 | - | - | picture | heat louvre over the engine room |
| V3s | louvre panel 0.2 x 0.5 | 1 | 53.7 | -0.50 | -0.55 | - | - | picture | belly heat louvre under the reactor |
| V4s | louvre panel 0.1 x 0.4 | 1 | 23.7 | -0.40 | -0.55 | - | - | picture | belly heat louvre under the command deck |
| LW0sf | module latch row (3 clamps) | 1 | 31.4 | -0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| LW0sa | module latch row (3 clamps) | 1 | 37.9 | -0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| LW1sf | module latch row (3 clamps) | 1 | 64.3 | -0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| LW1sa | module latch row (3 clamps) | 1 | 70.8 | -0.42 | 0.40 | - | - | picture | locks two hull modules together across the band |
| H5s | square hatch 0.3 | 1 | 42.7 | -0.95 | -0.28 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| H1 | square hatch 0.3 | 1 | 12.4 | 0.00 | 0.40 | - | - | picture | deck hatch over the cannon room |
| H2 | square hatch 0.3 | 1 | 40.5 | 0.00 | 0.40 | - | - | picture | deck hatch to the main deck |
| H3 | square hatch 0.3 | 1 | 74.1 | 0.00 | 0.38 | - | - | picture | deck hatch to the engine room |
| H4 | square hatch 0.4 | 1 | 40.5 | 0.00 | -0.55 | - | - | picture | belly hatch on the armour step: stores and the reactor's spares |

Totals: 2 gun mounts with 5 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| pale grey module plate, steel-blue trim (paint stage) | 1.0 | 96.1 | whole hull |  |
| implant-blue light strips (the blue line), blue-white nozzles and windows | 1.0 | 96.1 | the flank bands, the stern |  |
| no rust, no warm light, no asymmetry | 1.0 | 96.1 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the dart | 10.1 to 96.1 | -1.10 to 1.10 | -0.50 to 0.40 | pale grey module plate | one solid dart: a flat deck, chamfered deck edges, upper facets out to the flank band with the blue line, short lower facets, a flat worked belly; the top line chamfered down to the stern |
| Bow face round the casemate | 1.0 to 10.1 | -0.69 to 0.69 | -0.47 to 0.40 | pale grey module plate | the blunt bow face (never a ship's stem): the dart's facets run to it, the casemate recessed low in its middle |
| Flak barbette plinth | 44.7 to 58.2 | -0.46 to 0.46 | 0.35 to 0.52 | recessed grey | the low faceted barbette the Picket lasers turn on |
| Belly armour step | 14.9 to 88.0 | -0.66 to 0.66 | -0.55 to -0.47 | recessed grey | a second armour layer on the flat belly (Ryan Nov 22: flatten the keel into a space hull) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck -0.12 (11% to 33%); main deck -0.12 (36% to 66%); main deck -0.12 (69% to 87%).

Bulkhead and frame stations: F1 19.3%, F2 44.2%, F3 59.5%, F4 80.7%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| cannon room (machinery) | 11.3 to 18.1 | 0.04 to -0.04 | -0.38 to -0.16 | the plasma cannon's capacitor banks and feed behind the casemate |
| command (bridge) | 20.5 to 32.9 | 0.04 to -0.04 | -0.08 to 0.28 | the command deck under the sensor fin |
| bow stores (hold) | 20.5 to 32.9 | 0.04 to -0.04 | -0.38 to -0.16 | bow stores and the retro thrusters' feeds |
| crew corridor (hcorr) | 36.4 to 43.0 | 0.04 to -0.04 | -0.08 to 0.30 | white corridors and crew berths of the main deck, numbered posts |
| flak room (magazine) | 45.3 to 58.5 | 0.04 to -0.04 | -0.08 to 0.28 | the Picket lasers' power cells under the barbette |
| reactor (core) | 45.3 to 60.5 | 0.04 to -0.04 | -0.38 to -0.16 | the reactor (hp_core): its power runs forward to the cannon and up to the barbette |
| rack 0 p (hrack) | 45.3 to 49.1 | 0.48 to 0.73 | -0.06 to 0.24 | racks of identical equipment beside the flak room (factions.md "Inside") |
| rack 0 s (hrack) | 45.3 to 49.1 | -0.73 to -0.48 | -0.06 to 0.24 | racks of identical equipment beside the flak room (factions.md "Inside") |
| rack 1 p (hrack) | 50.6 to 54.4 | 0.48 to 0.77 | -0.06 to 0.24 | racks of identical equipment beside the flak room (factions.md "Inside") |
| rack 1 s (hrack) | 50.6 to 54.4 | -0.77 to -0.48 | -0.06 to 0.24 | racks of identical equipment beside the flak room (factions.md "Inside") |
| rack 2 p (hrack) | 55.8 to 59.6 | 0.48 to 0.80 | -0.06 to 0.24 | racks of identical equipment beside the flak room (factions.md "Inside") |
| rack 2 s (hrack) | 55.8 to 59.6 | -0.80 to -0.48 | -0.06 to 0.24 | racks of identical equipment beside the flak room (factions.md "Inside") |
| emerg mid (hemerg) | 36.4 to 43.0 | 0.04 to -0.04 | 0.30 to 0.33 | the blue emergency light strip along the corridor ceiling |
| engine room (engroom) | 69.3 to 87.3 | 0.04 to -0.04 | -0.38 to -0.16 | the engine room: the feeds to the two nozzle pods |
| aft crew (hcorr) | 69.3 to 79.2 | -0.66 to 0.66 | -0.08 to 0.20 | the aft crew deck, white and numbered |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| deck and facets | 0.08 | machined plate in modules, flush panels over it |
| bow face | 0.15 | the blunt bow round the casemate, the thickest plate |
| belly and armour step | 0.10 | the flat worked belly |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 34.6 (seam wanders 33.8 to 35.5) | the bow module tears off at the first bulkhead ring, the casemate and the command deck with it |
| B-2 | 67.5 (seam wanders 66.7 to 68.4) | the stern module falls away at the second bulkhead ring, the nozzles and the engine room with it |

Full interiors throughout the hull (R215), hidden until a piece breaks: the cannon room, the command deck, white corridors with blue emergency light, racks of identical equipment, the reactor, the engine room. The Hegemony breaks in modules at the bulkhead rings (factions.md).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 52.9 | 0.00 | -0.27 |  |  |  |
| hp_breach_0 | 34.6 | 0.97 | 0.10 | port | prow | on a module joint |
| hp_breach_1 | 67.5 | -1.09 | 0.10 | stbd | eng | on a module joint |
| hp_rcs_0 | -0.4 | 0.24 | 0.25 | port |  |  |
| hp_board_0 | 57.3 | 1.14 | 0.00 | port |  |  |
| hp_rcs_1 | -0.4 | -0.24 | 0.25 | stbd |  |  |
| hp_board_1 | 57.3 | -1.14 | 0.00 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 174 objects, 39 parts, 229 close pairs, 222 rays, 2 guns, 12 sensor pairs, 1 turrets swept, 8 cones, 20 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The concept's V keel (the speedboat underside in the side view) becomes a flat worked belly: short lower facets, a chine, a flat belly with an armour step, panels, hatches and louvres on it.** Ryan, Nov 22 2026, on run 3: flatten the speedboat keel into a space hull; rule 4.1: space ships, never sea ships.
- **The bow casemate is a fixed twin plasma cannon in a lined recess low in the blunt face, its two barrels clearing the face by 0.07; the concept's two dark ports read as the mouth.** designs.md: two short thick barrels side by side, recessed so they barely protrude, never the ion trench; tables.json h_picket laser F, 2 shots, one a barrel.
- **The flak barbette is a low eight-sided plinth (0.12 high) with the picket turret on it, three short emitters; the concept's smooth mound is not followed.** designs.md: three short emitters (the beauty's mound hides them, a picture slip); R240: the plinth lifts the emitters' firing plane clear over the low sensor fin, so no gun aims through a sensor.
- **The sensor fin sits at 25 percent (x 1.65), 0.17 tall and 1.0 long, ahead of the first bulkhead ring; the table put it at 40 percent, 1.2 long.** the top view draws the fin well forward of the barbette (about 28 percent); at 40 percent a 1.2 fin crosses the 35 percent bulkhead ring and crowds the barbette.
- **The two nozzle pods sit side by side in the stern transom, their lips 0.25 proud; the sheet's top view pods on a crossbar are not followed.** designs.md: two rectangular pods in one flat row, seated flush in the single stern block (the forked look is a picture slip).
- **Flush drone doors on the upper facets aft, one a side, are kept with no craft: the rules give the Picket no hangar.** designs.md: flush flank doors only, the faction's small drone bays; nothing launches from them in the game.
- **Retro thrusters on the bow face over the casemate (the concept's two small dark ports there), attitude thrusters on the facets, window slits aft, louvres, hatches and module latch rows added.** a ship in space needs thrusters and access (lore 3.4; ability evasive); every part has a job (R221).
- **Even panel grid of two module sizes, bulkhead rings as raised bands with a deep seam at 35 and 70 percent.** paint direction hegemony.md; designs.md break lines; the concept's scattered greebles are not built one for one.

## Designed here, not shown in the picture

- Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled.
- Q1p (retro thruster, two rectangular nozzles): retro thruster on the bow face (lore 3.4: backing off is cheap; the Picket's evasive burn).
- Q2p (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3p (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
- Q1s (retro thruster, two rectangular nozzles): retro thruster on the bow face (lore 3.4: backing off is cheap; the Picket's evasive burn).
- Q2s (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3s (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
