# hegemony_IM5: The Iron Mandate, super-dreadnought (Hegemony Navy flagship, the boss), build sheet

Hegemony Navy (hegemony) | class Super-dreadnought | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 768 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py hegemony_IM5 <out> render` rebuilds it from this file

**Length 31.0 world units** (data.js h_boss (cls 'Super-dreadnought', boss); length from godot/render/hull_table.gd CLS_LEN['Super-dreadnought'] = 31.0 (drawn x SHIP_K 1.6 = 49.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | hturbo | P | 3 | HP (2) |
| 1 | hturbo | S | 3 | HS (2) |
| 2 | turbo | T | 2 | T1 (2) |
| 3 | ion | F | 1 | I1 (1) |
| 4 | flak | T | 3 | F1 (2) |

| Check | Value |
|---|---|
| model length | 31.2 |
| length side | 31.225 |
| length top | 31.225 |
| length disagreement percent | 0.0 |
| beam top | 12.762 |
| beam bow | 12.762 |
| beam disagreement percent | 0.0 |
| height side | 4.487 |
| height bow | 4.487 |
| height disagreement percent | 0.0 |
| widest at station percent | 55.8 |
| hull beam | 12.6 |
| hull depth | 3.8 |
| L to B hull | 2.46 |
| L to H hull | 8.16 |
| outline iou percent | 91.9 |
| mass outline iou percent | 91.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| I1 | ion cannon, emitter trench in the bow face (fixed) | 1 barrel | 8.6 | 0.00 | -0.30 | forward | F ion | picture | the ion cannon (ion F, 1 shot): an emitter trench recessed in the blunt bow face at the canyon's mouth, coil-lined walls, a blue lens on the emitter block at its back |
| E1 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | 3.75 | -0.25 | exhaust aft | - | picture | nozzle 1 of the row (port to starboard): a rectangular nozzle pod, blue-white throat |
| E2 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | 2.25 | -0.25 | exhaust aft | - | picture | nozzle 2 of the row (port to starboard): a rectangular nozzle pod, blue-white throat |
| E3 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | 0.75 | -0.25 | exhaust aft | - | picture | nozzle 3 of the row (port to starboard): a rectangular nozzle pod, blue-white throat |
| E4 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | -0.75 | -0.25 | exhaust aft | - | picture | nozzle 4 of the row (port to starboard): a rectangular nozzle pod, blue-white throat |
| E5 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | -2.25 | -0.25 | exhaust aft | - | picture | nozzle 5 of the row (port to starboard): a rectangular nozzle pod, blue-white throat |
| E6 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | -3.75 | -0.25 | exhaust aft | - | picture | nozzle 6 of the row (port to starboard): a rectangular nozzle pod, blue-white throat |
| HP | heavy plasma lance, twin turret | 2 barrels | 61.2 | 4.22 | 1.38 | 60 deg off the bow to port | P hturbo | picture | port shoulder lance turret: the heavy plasma lance (hturbo P, 3 shots), a low wide mount sunk in the shoulder pit, two short thick barrels |
| HS | heavy plasma lance, twin turret | 2 barrels | 61.2 | -4.22 | 1.38 | 60 deg off the bow to starboard | S hturbo | picture | starboard shoulder lance turret: the heavy plasma lance (hturbo S, 3 shots), a low wide mount sunk in the shoulder pit, two short thick barrels |
| T1 | plasma lance, twin turret | 2 barrels | 61.2 | 0.00 | 1.80 | forward | T turbo | picture | the plasma lance on the midships bridge (turbo T, 2 shots): the same low lance mount at a smaller size, turning all round over the ridge decks |
| F1 | picket lasers, twin turret | 2 barrels | 79.1 | 0.00 | 1.80 | forward, +10 elev | T flak | picture | the picket lasers on the stern bridge (flak T, 3 shots over 2 emitters, both fire every volley): point defence over the stern quarter |
| A1 | sensor fin, 0.5 tall, 2.4 long | 1 | 11.3 | 0.00 | 0.95 | - | - | picture | the one low sensor fin on the bow deck ahead of the canyon: sensor windows and a lens strip; low enough that the bridge lance fires over it (R240) |
| CB1 | capacitor bank (4 cells) | 1 | 23.7 | 0.00 | 0.10 | - | - | picture | the ion cannon's charge banks: four identical cells, a bus bar to the trench |
| CB2 | capacitor bank (3 cells) | 1 | 42.4 | 0.00 | 0.10 | - | - | picture | the ion cannon's second charge bank, on the main power trunks |
| HX1 | heat exchanger | 1 | 55.9 | 0.00 | 0.10 | - | - | picture | the reactor's coolant exchanger: its heat leaves the hull in the open canyon |
| HX2 | heat exchanger | 1 | 67.2 | 0.00 | 0.10 | - | - | picture | the reactor's second coolant exchanger |
| HX3 | heat exchanger | 1 | 74.3 | 0.00 | 0.10 | - | - | picture | the drives' coolant exchanger, over the engine feeds |
| HX4 | heat exchanger | 1 | 83.6 | 0.00 | 0.10 | - | - | picture | the drives' second coolant exchanger, under the stern bridge's aft edge |
| PT0p | power trunk, 3.2 long | 1 | 18.5 | 1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT0s | power trunk, 3.2 long | 1 | 18.5 | -1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT1p | power trunk, 4.6 long | 1 | 30.7 | 1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT1s | power trunk, 4.6 long | 1 | 30.7 | -1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT2p | power trunk, 1.2 long | 1 | 47.4 | 1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT2s | power trunk, 1.2 long | 1 | 47.4 | -1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT3p | power trunk, 5.2 long | 1 | 53.1 | 1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT3s | power trunk, 5.2 long | 1 | 53.1 | -1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT4p | power trunk, 4.4 long | 1 | 71.7 | 1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| PT4s | power trunk, 4.4 long | 1 | 71.7 | -1.05 | 0.38 | - | - | picture | armoured power trunk: the reactor's power forward to the ion cannon and aft to the drives, coupled at each module band |
| CL0p | coolant line, 0.8 long | 1 | 83.3 | 1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL0s | coolant line, 0.8 long | 1 | 83.3 | -1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL1p | coolant line, 1.0 long | 1 | 71.7 | 1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL1s | coolant line, 1.0 long | 1 | 71.7 | -1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL2p | coolant line, 1.2 long | 1 | 66.0 | 1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL2s | coolant line, 1.2 long | 1 | 66.0 | -1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL3p | coolant line, 1.0 long | 1 | 53.1 | 1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL3s | coolant line, 1.0 long | 1 | 53.1 | -1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL4p | coolant line, 1.2 long | 1 | 47.4 | 1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL4s | coolant line, 1.2 long | 1 | 47.4 | -1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL5p | coolant line, 1.8 long | 1 | 39.7 | 1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL5s | coolant line, 1.8 long | 1 | 39.7 | -1.64 | 1.03 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL6p | coolant line, 3.2 long | 1 | 18.5 | 1.64 | 0.94 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| CL6s | coolant line, 3.2 long | 1 | 18.5 | -1.64 | 0.94 | - | - | picture | coolant line on the canyon ledge: the exchangers' loop out to the ridges' plant rooms |
| WC1 | vision slit 0.5 x 0.20 | 1 | 90.0 | 1.05 | 0.95 | - | - | picture | a control window of the engine room, overlooking the canyon |
| WC2 | vision slit 0.5 x 0.20 | 1 | 90.0 | 0.35 | 0.95 | - | - | picture | a control window of the engine room, overlooking the canyon |
| WC3 | vision slit 0.5 x 0.20 | 1 | 90.0 | -0.35 | 0.95 | - | - | picture | a control window of the engine room, overlooking the canyon |
| WC4 | vision slit 0.5 x 0.20 | 1 | 90.0 | -1.05 | 0.95 | - | - | picture | a control window of the engine room, overlooking the canyon |
| Q1p | retro thruster, two rectangular nozzles | 1 | 0.6 | 2.05 | -0.35 | - | - | designed | retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap) |
| Q2p | attitude thruster, two rectangular nozzles | 1 | 13.1 | 3.42 | 0.90 | - | - | designed | bow attitude thruster on the upper facet |
| Q3p | attitude thruster, two rectangular nozzles | 1 | 91.6 | 5.12 | 1.08 | - | - | designed | stern attitude thruster on the upper facet |
| W1p | vision slit 0.5 x 0.10 | 1 | 21.7 | 4.39 | 0.10 | - | - | picture | blue-white window of the ridge's crew decks |
| W2p | vision slit 0.5 x 0.10 | 1 | 24.3 | 4.58 | 0.11 | - | - | picture | blue-white window of the ridge's crew decks |
| W3p | vision slit 0.5 x 0.10 | 1 | 26.9 | 4.76 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W4p | vision slit 0.5 x 0.10 | 1 | 37.4 | 5.33 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W5p | vision slit 0.5 x 0.10 | 1 | 40.0 | 5.44 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W6p | vision slit 0.5 x 0.10 | 1 | 56.7 | 6.31 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W7p | vision slit 0.5 x 0.10 | 1 | 59.2 | 6.31 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W8p | vision slit 0.5 x 0.10 | 1 | 74.6 | 5.93 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W9p | vision slit 0.5 x 0.10 | 1 | 77.2 | 5.87 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W10p | vision slit 0.5 x 0.10 | 1 | 79.7 | 5.81 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| V1p | louvre panel 0.3 x 1.4 | 1 | 23.7 | 3.30 | 1.65 | - | - | picture | heat louvre on the ridge deck over the crew decks |
| V2p | louvre panel 0.3 x 1.4 | 1 | 40.6 | 3.30 | 1.80 | - | - | picture | heat louvre on the ridge deck over the crew decks |
| V3p | louvre panel 0.3 x 1.4 | 1 | 78.8 | 3.30 | 1.80 | - | - | picture | heat louvre on the ridge deck over the drive coolant plant |
| V4p | louvre panel 0.3 x 1.1 | 1 | 92.9 | 2.60 | 1.80 | - | - | picture | heat louvre over the engine room |
| H70p | square hatch 0.6 | 1 | 25.9 | 4.26 | -1.33 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| H71p | square hatch 0.6 | 1 | 75.9 | 5.47 | -1.42 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| L0pf | module latch row (4 clamps) | 1 | 16.5 | 2.58 | 1.57 | - | - | picture | locks two hull modules together across the band |
| L0pa | module latch row (4 clamps) | 1 | 18.6 | 2.65 | 1.59 | - | - | picture | locks two hull modules together across the band |
| L1pf | module latch row (4 clamps) | 1 | 28.7 | 3.02 | 1.71 | - | - | picture | locks two hull modules together across the band |
| L1pa | module latch row (4 clamps) | 1 | 30.8 | 3.09 | 1.73 | - | - | picture | locks two hull modules together across the band |
| L2pf | module latch row (4 clamps) | 1 | 45.4 | 3.40 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L2pa | module latch row (4 clamps) | 1 | 47.4 | 3.45 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L3pf | module latch row (4 clamps) | 1 | 51.2 | 3.59 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L3pa | module latch row (4 clamps) | 1 | 53.2 | 3.68 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L4pf | module latch row (4 clamps) | 1 | 69.7 | 3.67 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L4pa | module latch row (4 clamps) | 1 | 71.8 | 3.62 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L5pf | module latch row (4 clamps) | 1 | 85.8 | 3.41 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L5pa | module latch row (4 clamps) | 1 | 87.8 | 3.38 | 1.80 | - | - | picture | locks two hull modules together across the band |
| Q1s | retro thruster, two rectangular nozzles | 1 | 0.6 | -2.05 | -0.35 | - | - | designed | retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap) |
| Q2s | attitude thruster, two rectangular nozzles | 1 | 13.1 | -3.42 | 0.90 | - | - | designed | bow attitude thruster on the upper facet |
| Q3s | attitude thruster, two rectangular nozzles | 1 | 91.6 | -5.12 | 1.08 | - | - | designed | stern attitude thruster on the upper facet |
| W1s | vision slit 0.5 x 0.10 | 1 | 21.7 | -4.39 | 0.10 | - | - | picture | blue-white window of the ridge's crew decks |
| W2s | vision slit 0.5 x 0.10 | 1 | 24.3 | -4.58 | 0.11 | - | - | picture | blue-white window of the ridge's crew decks |
| W3s | vision slit 0.5 x 0.10 | 1 | 26.9 | -4.76 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W4s | vision slit 0.5 x 0.10 | 1 | 37.4 | -5.33 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W5s | vision slit 0.5 x 0.10 | 1 | 40.0 | -5.44 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W6s | vision slit 0.5 x 0.10 | 1 | 56.7 | -6.31 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W7s | vision slit 0.5 x 0.10 | 1 | 59.2 | -6.31 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W8s | vision slit 0.5 x 0.10 | 1 | 74.6 | -5.93 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W9s | vision slit 0.5 x 0.10 | 1 | 77.2 | -5.87 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| W10s | vision slit 0.5 x 0.10 | 1 | 79.7 | -5.81 | 0.12 | - | - | picture | blue-white window of the ridge's crew decks |
| V1s | louvre panel 0.3 x 1.4 | 1 | 23.7 | -3.30 | 1.65 | - | - | picture | heat louvre on the ridge deck over the crew decks |
| V2s | louvre panel 0.3 x 1.4 | 1 | 40.6 | -3.30 | 1.80 | - | - | picture | heat louvre on the ridge deck over the crew decks |
| V3s | louvre panel 0.3 x 1.4 | 1 | 78.8 | -3.30 | 1.80 | - | - | picture | heat louvre on the ridge deck over the drive coolant plant |
| V4s | louvre panel 0.3 x 1.1 | 1 | 92.9 | -2.60 | 1.80 | - | - | picture | heat louvre over the engine room |
| H70s | square hatch 0.6 | 1 | 25.9 | -4.26 | -1.33 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| H71s | square hatch 0.6 | 1 | 75.9 | -5.47 | -1.42 | - | - | picture | flank hatch on the lower facet: stores to the lower deck |
| L0sf | module latch row (4 clamps) | 1 | 16.5 | -2.58 | 1.57 | - | - | picture | locks two hull modules together across the band |
| L0sa | module latch row (4 clamps) | 1 | 18.6 | -2.65 | 1.59 | - | - | picture | locks two hull modules together across the band |
| L1sf | module latch row (4 clamps) | 1 | 28.7 | -3.02 | 1.71 | - | - | picture | locks two hull modules together across the band |
| L1sa | module latch row (4 clamps) | 1 | 30.8 | -3.09 | 1.73 | - | - | picture | locks two hull modules together across the band |
| L2sf | module latch row (4 clamps) | 1 | 45.4 | -3.40 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L2sa | module latch row (4 clamps) | 1 | 47.4 | -3.45 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L3sf | module latch row (4 clamps) | 1 | 51.2 | -3.59 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L3sa | module latch row (4 clamps) | 1 | 53.2 | -3.68 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L4sf | module latch row (4 clamps) | 1 | 69.7 | -3.67 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L4sa | module latch row (4 clamps) | 1 | 71.8 | -3.62 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L5sf | module latch row (4 clamps) | 1 | 85.8 | -3.41 | 1.80 | - | - | picture | locks two hull modules together across the band |
| L5sa | module latch row (4 clamps) | 1 | 87.8 | -3.38 | 1.80 | - | - | picture | locks two hull modules together across the band |
| H1 | square hatch 0.6 | 1 | 32.5 | 2.60 | 1.75 | - | - | picture | deck hatch over the port ridge's forward crew deck |
| H2 | square hatch 0.6 | 1 | 32.5 | -2.60 | 1.75 | - | - | picture | deck hatch over the starboard ridge's forward crew deck |
| H3 | square hatch 0.8 | 1 | 37.4 | 0.00 | -2.12 | - | - | picture | belly hatch on the armour step: stores |
| H4 | square hatch 0.8 | 1 | 61.2 | 0.00 | -2.12 | - | - | picture | belly hatch on the armour step: the reactor's service hatch |
| H5 | square hatch 0.8 | 1 | 79.1 | 0.00 | -2.12 | - | - | picture | belly hatch on the armour step: the engine room's stores |
| HB1 | framed deck box 1.0 x 0.9 | 1 | 92.9 | 0.00 | 1.50 | - | - | picture | the stern lift head: stores up to the engine room |

Totals: 5 gun mounts with 9 barrels; 0 launcher tubes; 6 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| steel blue-grey module plate, steel-blue trim (paint stage) | 0.6 | 99.9 | whole hull |  |
| implant-blue light strips (the blue line, the bridge faces), blue-white nozzles and windows | 0.6 | 99.9 | the flank bands, the bridges, the stern |  |
| no rust, no warm light, no asymmetry | 0.6 | 99.9 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the broad wedge with its canyon | 8.0 to 96.1 | -6.30 to 6.30 | -2.00 to 1.80 | pale grey module plate | one broad wedge hull: two raised armoured ridges and the canyon cut deep between them, its walls stepped by a ledge; a flat deck on each ridge, chamfered deck edges, upper facets out to the knuckle, the flank band with the blue line, lower facets, a chine, a flat belly; the shoulder pits where the lances sit low |
| Bow face round the ion trench | 0.6 to 8.6 | -3.32 to 3.32 | -1.41 to 1.49 | pale grey module plate | the blunt bow face (never a ship's stem): the ridge ends and the bow deck run to it, the trench recessed in its middle under the bow deck, at the canyon's mouth |
| Bridge deck, bow | 33.3 to 39.0 | -1.90 to 1.90 | 1.05 to 1.80 | pale grey module plate | a low armoured bridge deck spanning the canyon, its top flush with the ridge decks (never above them: no naval read), its underside chamfered, a crossing corridor inside |
| Bridge deck, mid | 57.0 to 65.3 | -1.90 to 1.90 | 1.05 to 1.80 | pale grey module plate | a low armoured bridge deck spanning the canyon, its top flush with the ridge decks (never above them: no naval read), its underside chamfered, a crossing corridor inside |
| Bridge deck, stern | 75.6 to 82.6 | -1.90 to 1.90 | 1.05 to 1.80 | pale grey module plate | a low armoured bridge deck spanning the canyon, its top flush with the ridge decks (never above them: no naval read), its underside chamfered, a crossing corridor inside |
| Belly armour step | 8.6 to 94.8 | -4.43 to 4.43 | -2.12 to -1.39 | recessed grey | a second armour layer under the hull (a worked belly) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.55 (10% to 17%); main deck 0.70 (19% to 45%); lower deck -0.95 (19% to 45%); main deck 0.70 (47% to 70%); lower deck -0.95 (47% to 70%); main deck 0.70 (72% to 86%); lower deck -0.95 (72% to 86%); lower deck -0.95 (88% to 95%).

Bulkhead and frame stations: F1 11.2%, F2 15.0%, F3 21.4%, F4 25.9%, F5 29.7%, F6 34.2%, F7 38.7%, F8 43.2%, F9 49.3%, F10 53.5%, F11 57.9%, F12 61.2%, F13 64.4%, F14 68.8%, F15 73.3%, F16 77.8%, F17 82.3%, F18 85.2%, F19 90.6%, F20 93.8%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| ion capacitors (machinery) | 9.4 to 16.6 | -1.30 to 1.30 | -0.75 to 0.60 | the ion cannon's field drivers behind the trench |
| bow corridor p (hcorr) | 9.9 to 16.6 | 2.16 to 2.61 | 0.75 to 1.05 | white corridors at the ridges' bow ends |
| bow corridor s (hcorr) | 9.9 to 16.6 | -2.61 to -2.16 | 0.75 to 1.05 | white corridors at the ridges' bow ends |
| fwd crew p (hcorr) | 18.8 to 29.1 | 2.16 to 3.31 | 0.80 to 1.20 | white corridors and crew berths of the ridges, numbered posts |
| fwd crew s (hcorr) | 18.8 to 29.1 | -3.31 to -2.16 | 0.80 to 1.20 | white corridors and crew berths of the ridges, numbered posts |
| fwd crew2 p (hcorr) | 30.4 to 45.1 | 2.16 to 4.15 | 0.80 to 1.30 | white corridors and crew berths of the ridges |
| fwd crew2 s (hcorr) | 30.4 to 45.1 | -4.15 to -2.16 | 0.80 to 1.30 | white corridors and crew berths of the ridges |
| command (bridge) | 30.4 to 38.1 | -2.20 to 2.20 | -0.85 to -0.30 | the command deck: the Registry link room, under the bow bridge |
| rack 0 (hrack) | 19.2 to 20.3 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 1 (hrack) | 20.8 to 21.9 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 2 (hrack) | 22.4 to 23.5 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 3 (hrack) | 24.0 to 25.1 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 4 (hrack) | 25.6 to 26.7 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 5 (hrack) | 27.2 to 28.3 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment on the lower deck (factions.md "Inside") |
| ion feed (machinery) | 39.4 to 45.1 | -2.40 to 2.40 | -0.85 to -0.30 | the ion cannon's feed switching, under the second capacitor bank |
| fwd stores (hold) | 25.9 to 45.1 | -3.00 to 3.00 | -1.55 to -1.10 | stores and the retro thrusters' feeds |
| emerg fwd p (hemerg) | 19.5 to 44.5 | 2.16 to 3.36 | 1.15 to 1.20 | the blue emergency light strip along the corridor ceilings |
| emerg fwd s (hemerg) | 19.5 to 44.5 | -3.36 to -2.16 | 1.15 to 1.20 | the blue emergency light strip along the corridor ceilings |
| reactor (core) | 53.8 to 68.5 | -1.60 to 1.60 | -1.60 to -0.30 | the reactor (hp_core): its power rides the trunks forward to the trench and aft to the drives |
| lance rooms p (magazine) | 56.7 to 65.6 | 2.90 to 5.48 | 0.30 to 0.95 | the lance capacitor rooms under the shoulder pits |
| lance rooms s (magazine) | 56.7 to 65.6 | -5.48 to -2.90 | 0.30 to 0.95 | the lance capacitor rooms under the shoulder pits |
| mid crew p (hcorr) | 47.4 to 54.1 | 2.16 to 4.92 | 0.80 to 1.30 | white corridors of the ridges, midships |
| mid crew s (hcorr) | 47.4 to 54.1 | -4.92 to -2.16 | 0.80 to 1.30 | white corridors of the ridges, midships |
| mid racks (hrack) | 47.4 to 53.1 | -2.60 to 2.60 | -0.85 to -0.25 | racks of identical equipment |
| turbo feed (magazine) | 66.3 to 69.2 | -2.00 to 2.00 | -0.85 to -0.25 | the bridge lance's capacitor feed, up through the midships bridge |
| emerg mid p (hemerg) | 47.7 to 53.9 | 2.16 to 4.93 | 1.25 to 1.30 | the blue emergency light strip |
| emerg mid s (hemerg) | 47.7 to 53.9 | -4.93 to -2.16 | 1.25 to 1.30 | the blue emergency light strip |
| aft crew p (hcorr) | 71.7 to 85.5 | 2.16 to 4.85 | 0.80 to 1.30 | white corridors and crew decks |
| aft crew s (hcorr) | 71.7 to 85.5 | -4.85 to -2.16 | 0.80 to 1.30 | white corridors and crew decks |
| drive plant (machinery) | 71.7 to 85.5 | -2.80 to 2.80 | -1.60 to -0.30 | the drives' coolant and fuel plant |
| picket store p (magazine) | 76.9 to 81.3 | 2.40 to 5.31 | 0.15 to 0.60 | the picket lasers' power cells, fed across the stern bridge |
| picket store s (magazine) | 76.9 to 81.3 | -5.31 to -2.40 | 0.15 to 0.60 | the picket lasers' power cells, fed across the stern bridge |
| emerg aft p (hemerg) | 72.1 to 85.5 | 2.16 to 4.85 | 1.25 to 1.30 | the blue emergency light strip |
| emerg aft s (hemerg) | 72.1 to 85.5 | -4.85 to -2.16 | 1.25 to 1.30 | the blue emergency light strip |
| engine room (engroom) | 90.8 to 95.1 | -4.00 to 4.00 | -1.55 to 1.05 | the engine room under the stern deck: the feeds to the six nozzles |
| engine room fwd (engroom) | 87.9 to 90.3 | -3.60 to 3.60 | -1.55 to -0.30 | the engine room's forward bay under the canyon floor |
| bridge corr bow (hcorr) | 34.6 to 37.8 | -1.50 to 1.50 | 1.38 to 1.47 | the crossing corridor inside the bow bridge deck, from ridge to ridge |
| bridge corr mid (hcorr) | 58.3 to 64.0 | -1.50 to 1.50 | 1.38 to 1.47 | the crossing corridor inside the mid bridge deck, from ridge to ridge |
| bridge corr stern (hcorr) | 76.9 to 81.3 | -1.50 to 1.50 | 1.38 to 1.47 | the crossing corridor inside the stern bridge deck, from ridge to ridge |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ridge decks and facets | 0.25 | machined plate in modules, flush panels over it |
| canyon walls and floor | 0.25 | the canyon floor carries the plant; its walls shield it |
| shoulder pits | 0.35 | the lance turrets' pits |
| bow face | 0.45 | the blunt bow round the trench, the thickest plate |
| bridge decks | 0.25 |  |
| belly and armour step | 0.30 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 17.6 (seam wanders 17.2 to 17.9) | the bow module tears off at the first module band: the trench, the fin and the field drivers with it |
| B-2 | 46.4 (seam wanders 46.0 to 46.8) | the forward module parts from midships at the second band, the canyon floor torn across between the second bank and the exchanger |
| B-3 | 70.8 (seam wanders 70.4 to 71.2) | midships parts from the aft module behind the shoulder pits, the reactor's bite ragged |
| B-4 | 86.8 (seam wanders 86.5 to 87.1) | the stern module and the nozzle row fall away at the last band |

Full interiors throughout the hull (R215), hidden until a piece breaks: white corridors, blue emergency light, racks of identical equipment, the command deck, the lance rooms, the reactor, the drive plant, the engine room, the bridges' crossing corridors. The canyon is open space, never filled. The Hegemony breaks in modules at the bulkhead rings (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 61.2 | 0.00 | -1.00 |  |  |  |
| hp_breach_0 | 17.6 | 4.16 | 0.02 | port | prow | on a module joint |
| hp_breach_1 | 17.6 | -4.16 | 0.02 | stbd | prow | on a module joint |
| hp_breach_2 | 29.7 | 5.04 | 0.00 | port | prow | on a module joint |
| hp_breach_3 | 46.4 | -5.78 | 0.00 | stbd | mid | on a module joint |
| hp_breach_4 | 46.4 | 5.78 | 0.00 | port | mid | on a module joint |
| hp_breach_5 | 52.2 | -6.21 | 0.00 | stbd | mid | on a module joint |
| hp_breach_6 | 70.8 | 6.23 | 0.00 | port | eng | on a module joint |
| hp_breach_7 | 86.8 | -5.72 | 0.00 | stbd | eng | on a module joint |
| hp_rcs_0 | 0.3 | 2.05 | -0.35 | port |  |  |
| hp_rcs_2 | 91.6 | 5.62 | 0.80 | port |  |  |
| hp_board_0 | 57.9 | 6.35 | -0.25 | port |  |  |
| hp_rcs_1 | 0.3 | -2.05 | -0.35 | stbd |  |  |
| hp_rcs_3 | 91.6 | -5.62 | 0.80 | stbd |  |  |
| hp_board_1 | 57.9 | -6.35 | -0.25 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 488 objects, 114 parts, 1394 close pairs, 427 rays, 5 guns, 30 sensor pairs, 4 turrets swept, 12 cones, 41 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **IM5's rounded bow in the top view is sharpened into a straight-flanked wedge running to a blunt, nearly upright bow face (2.6 deep at the ridge ends), its corners chamfered.** design notes 758 ("IM5's bow reads rounder in the top view than the wedge the faction wants; the sheet sharpens it"); factions.md: a wedge with a blunt bow face; rule 4.1: no stem or keel line.
- **The hull is 31.0 long, 12.0 across the knuckles (12.6 over the pit swells), 3.8 deep: length to beam 2.46 over the swells, 2.58 off them (IM5's top view about 2.5); the stern 10.3 across, wider than IM5's top view (about 0.62 of the beam) so the six nozzles fit in one row.** data.js h_boss class Super-dreadnought, CLS_LEN 31.0; factions.md asks about 3 : 1 for the line ships, and the boss keeps IM5's broader read (one broad wedge, R255); IM5 has no side view, so the depth is designed (the three-quarter shows a thick hull).
- **The canyon is 3.1 across its floor and 3.8 across its lips (about 0.3 of the beam, narrower than IM5's top view at about 0.4), 1.7 deep, its walls stepped by a ledge halfway down.** design notes 758 (DeepSeek, adopted: the canyon kept narrow so the ridges never read as separate hulls); R244: no flat walls; the depth keeps the canyon floor in view from the battle camera (34 degrees above the board).
- **The canyon runs from the bow deck (10.5) to the stern deck (-12.4); ahead of it a low bow deck (0.45 to 0.6 below the ridge tops) carries the sensor fin, the ion trench is recessed in the bow face under it.** design notes 758: the fin on the bow deck ahead of the canyon mouth, the trench at the canyon's mouth; R240: the bow deck sits low so the bridge lance fires over the fin (the fin's top 0.55 under the lance's pivot, 0.4 with the check's calibre pad).
- **Three low bridge decks (bow 4.4, midships -3.4, stern -9.0) flush with the ridge decks, their undersides chamfered, two girders under each, a crossing corridor inside, a trim band and a blue strip on each face.** IM5 and its notes (bridges at about 64, 40 and 21 percent from the stern, flush with the ridge tops: never above the hull line, no naval read); R244: shaped, not boxes.
- **The heavy plasma lances (hturbo P and S) are low twin turrets sunk in shoulder pits on the ridges' outer shoulders at -3.4, abreast of the midships bridge, each turning through its own broadside arc (30 to 150 degrees off the bow).** design notes 758: shoulder mounts, not the flank mounts the top view renders; R185 (4): guns low, sunk in and real; data.js hturbo P and S, 3 shots each; IM5 shows two thick barrels a mount (its notes say three): two, as the picture shows, both fire every volley (weapon_match SPLIT).
- **The plasma lance (turbo T) on the midships bridge is the heavy lance's mount at a smaller size (0.95 against 1.15), twin barrels, turning all round.** data.js turbo T, 2 shots; factions.md: the same parts repeated at different sizes; IM5 shows a twin turret on that bridge.
- **The flak cluster (flak T) on the stern bridge is one twin picket laser turret, elevating to 60.** data.js flak T, 3 shots over 2 emitters (both fire every volley); IM5 shows a twin mount on the stern bridge; one mount, as the notes say.
- **One flat row of six rectangular nozzle pods across the whole stern face on one datum, not only between the ridge roots.** IM5's three-quarter shows the plumes across the whole stern (its notes say between the ridge roots); factions.md: a flat row of rectangular blue-white nozzles; the boss needs the thrust of the whole stern.
- **The canyon floor's machinery is real plant with a job: two capacitor banks for the ion cannon forward, four heat exchangers for the reactor and the drives aft, two armoured power trunks along the floor, each coupled with flanges short of every module band.** the issue: machinery on the canyon floor is real machinery with a job (R221); IM5 shows pipes and blocks there; R226: the banks and exchangers are machines and sit whole in one module, the trunks stop at the bands.
- **Coolant lines on both canyon ledges (the exchangers' loops out to the ridges' plant rooms), one length per stretch between the bands and the bridges, and four blue-white control windows of the engine room on the stern deck's fore face, looking up the canyon.** IM5 shows pipe runs along the canyon walls and a blue-lit block at the canyon's aft end: here the windows of the engine room that watches the plant; every part has a job (R221); the lines stop short of the bands and bridges (R226).
- **Even panel grid of two module sizes on the decks, the canyon floor and walls, the facets, the belly and the bridges; module bands as raised rings with a deep double seam round the whole section, canyon included; module latch rows on the ridge decks at the bands.** paint direction hegemony.md (approved Nov 14): the even grid, two module sizes, the module band as structure; R243 ("Hegemony also pretty rigid and clean"); every part has a job (R221): the latches lock the modules.
- **The flanks are faceted round a vertical flank band (upper and lower facets, chamfers, a chine) carrying the blue line, broken only at the module bands.** R244, binding on every sheet ship; factions.md: "a pale wedge with a line of blue light"; the strips are the running lights (paint direction 5).
- **Retro thrusters on the bow face, attitude thrusters on the facets, blue-white window slits, louvres, flush hatches, a stern lift head and a belly armour step added; no hangar, no drone bay, no mount for nova.** a ship in space needs thrusters and access (lore 3.4, 3.3); IM5 shows no underside; data.js h_boss has no hangar and its ability nova has no mount (the issue); every part has a job (R221).

## Designed here, not shown in the picture

- IM5 has no side or underside view: the heights, the belly and the underside are designed here.
- Stencil marks and the steel-blue trim tone are paint (the Hegemony stack, a later job), not modelled.
- Q1p (retro thruster, two rectangular nozzles): retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap).
- Q2p (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3p (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
- Q1s (retro thruster, two rectangular nozzles): retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap).
- Q2s (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3s (attitude thruster, two rectangular nozzles): stern attitude thruster on the upper facet.
