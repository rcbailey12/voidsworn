# hegemony_H10: Dominion-class dreadnought (Hegemony Navy line flagship), build sheet

Hegemony Navy (hegemony) | class Battleship | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 759 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py hegemony_H10 <out> render` rebuilds it from this file

**Length 21.0 world units** (data.js h_dominion (cls 'Battleship'); length from godot/render/hull_table.gd CLS_LEN['Battleship'] = 21.0 (drawn x SHIP_K 1.6 = 33.6 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | hturbo | P | 3 | HP (2) |
| 1 | hturbo | S | 3 | HS (2) |
| 2 | ion | F | 1 | I1 (1) |
| 3 | flak | T | 3 | F1 (2), F2 (2) |

| Check | Value |
|---|---|
| model length | 21.2 |
| length side | 21.225 |
| length top | 21.225 |
| length disagreement percent | 0.0 |
| beam top | 9.075 |
| beam bow | 9.1 |
| beam disagreement percent | 0.12 |
| height side | 3.737 |
| height bow | 3.737 |
| height disagreement percent | 0.0 |
| widest at station percent | 36.5 |
| hull beam | 7.9 |
| hull depth | 2.9 |
| L to B hull | 2.66 |
| L to H hull | 7.24 |
| prow overhang | 0.18 |
| outline iou percent | 93.5 |
| mass outline iou percent | 93.6 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note  | Route |
|---|---|---:|---:|---:|---:|---|---|---|---|---|
| I1 | ion cannon, stepped accelerator and blue emitter (fixed) | 1 barrel | 6.5 | 0.00 | -0.08 | forward | F ion | designed | R287, R289 run 2: lit blue lens, fainter field contacts, metal coils and muzzle lip; beam origin on the lens | hand-built |
| B1 | flush armoured drone doors 3.2 x 1.0 | 1 | 61.9 | 0.00 | 0.50 | - | - | picture | data.js hangar 1: the drone bay's flush armoured doors, a seam line only on the intact ship (R232); the drones launch up out of the trough | kit |
| E1 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | 2.66 | -0.36 | exhaust aft | - | picture | port rail, outer nozzle: a rectangular nozzle pod, blue-white throat | kit |
| E2 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | 1.24 | -0.36 | exhaust aft | - | picture | port rail, inner nozzle: a rectangular nozzle pod, blue-white throat | kit |
| E3 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | -1.24 | -0.36 | exhaust aft | - | picture | starboard rail, inner nozzle: a rectangular nozzle pod, blue-white throat | kit |
| E4 | engine, rectangular nozzle 1.1 x 1.45 | 1 | 99.9 | -2.66 | -0.36 | exhaust aft | - | picture | starboard rail, outer nozzle: a rectangular nozzle pod, blue-white throat | kit |
| HP | heavy plasma lance, twin turret | 2 barrels | 40.0 | 2.90 | 0.68 | 55 deg off the bow to port | P hturbo | picture | port shoulder lance turret: the heavy plasma lance (hturbo P, 3 shots), a low wide mount sunk in the shoulder terrace, two short thick barrels | kit |
| HS | heavy plasma lance, twin turret | 2 barrels | 40.0 | -2.90 | 0.68 | 55 deg off the bow to starboard | S hturbo | picture | starboard shoulder lance turret: the heavy plasma lance (hturbo S, 3 shots), a low wide mount sunk in the shoulder terrace, two short thick barrels | kit |
| A1 | sensor fin, 0.4 tall, 2.4 long | 1 | 42.8 | 0.00 | 1.02 | - | - | picture | the one low sensor fin on the centreline: sensor windows and a lens strip; the command deck is under it | kit |
| F1 | picket lasers, twin belly turret | 2 barrels | 30.1 | 1.35 | -1.97 | 40 deg off the bow to port, +10 elev | T flak | picture | port picket laser turret on the belly (flak T: the pair is the one slot, 3 shots over 4 emitters, both fire every volley) | kit |
| F2 | picket lasers, twin belly turret | 2 barrels | 30.1 | -1.35 | -1.97 | 40 deg off the bow to starboard, +10 elev | T flak | picture | starboard picket laser turret on the belly (flak T: the pair is the one slot, 3 shots over 4 emitters, both fire every volley) | kit |
| Q1p | retro thruster, two rectangular nozzles | 1 | 0.8 | 1.55 | -0.25 | - | - | designed | retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap) | kit |
| Q2p | attitude thruster, two rectangular nozzles | 1 | 12.6 | 2.69 | 0.51 | - | - | designed | bow attitude thruster on the upper facet | kit |
| Q3p | attitude thruster, two rectangular nozzles | 1 | 86.9 | 3.28 | 0.42 | - | - | designed | stern attitude thruster on the rail's outer flank | kit |
| W1p | vision slit 0.4 x 0.09 | 1 | 8.4 | 2.75 | 0.16 | - | - | picture | blue-white window of the forward crew decks | kit |
| W2p | vision slit 0.4 x 0.09 | 1 | 11.7 | 2.89 | 0.17 | - | - | picture | blue-white window of the forward crew decks | kit |
| W3p | vision slit 0.4 x 0.09 | 1 | 15.0 | 3.02 | 0.19 | - | - | picture | blue-white window of the forward crew decks | kit |
| W4p | vision slit 0.5 x 0.09 | 1 | 57.9 | 3.28 | -0.55 | - | - | picture | blue-white window of the rails' crew decks | kit |
| W5p | vision slit 0.5 x 0.09 | 1 | 70.7 | 3.28 | -0.55 | - | - | picture | blue-white window of the rails' crew decks | kit |
| V1p | louvre panel 0.3 x 1.2 | 1 | 58.4 | 1.95 | 1.00 | - | - | picture | heat louvre on the rail deck over the crew decks | kit |
| V2p | louvre panel 0.3 x 1.2 | 1 | 70.7 | 1.95 | 1.00 | - | - | picture | heat louvre on the rail deck over the crew decks | kit |
| V3p | louvre panel 0.3 x 1.2 | 1 | 82.9 | 1.95 | 1.00 | - | - | picture | heat louvre on the rail deck over the engine room | kit |
| V6p | louvre panel 1.5 x 0.2 | 1 | 58.4 | 3.28 | 0.55 | - | - | picture | heat louvre on the rail's upper tier (H10's long flank slots) | kit |
| V7p | louvre panel 1.5 x 0.2 | 1 | 70.7 | 3.28 | 0.55 | - | - | picture | heat louvre on the rail's upper tier (H10's long flank slots) | kit |
| V8p | louvre panel 1.5 x 0.2 | 1 | 81.5 | 3.28 | 0.55 | - | - | picture | heat louvre on the rail's upper tier (H10's long flank slots) | kit |
| H60p | square hatch 0.5 | 1 | 62.2 | 3.28 | -0.85 | - | - | picture | rail flank hatch on the lower tier: access to the plant rooms | kit |
| H61p | square hatch 0.5 | 1 | 74.4 | 3.28 | -0.85 | - | - | picture | rail flank hatch on the lower tier: access to the plant rooms | kit |
| H62p | square hatch 0.5 | 1 | 86.7 | 3.28 | -0.85 | - | - | picture | rail flank hatch on the lower tier: access to the plant rooms | kit |
| H70p | square hatch 0.6 | 1 | 35.3 | 3.28 | -1.21 | - | - | picture | flank hatch on the lower facet: stores to the lower deck | kit |
| H71p | square hatch 0.6 | 1 | 44.7 | 3.28 | -1.21 | - | - | picture | flank hatch on the lower facet: stores to the lower deck | kit |
| V4p | louvre panel 0.3 x 1.2 | 1 | 22.5 | 0.85 | 0.95 | - | - | picture | heat louvre over the lance capacitor rooms | kit |
| V5p | louvre panel 0.3 x 0.9 | 1 | 45.7 | 0.80 | 1.02 | - | - | picture | heat louvre over the reactor | kit |
| LW0pf | module latch row (4 clamps) | 1 | 15.8 | 1.20 | 0.86 | - | - | picture | locks the two wedge modules together across the band | kit |
| LW0pa | module latch row (4 clamps) | 1 | 18.9 | 1.20 | 0.90 | - | - | picture | locks the two wedge modules together across the band | kit |
| LW1pf | module latch row (4 clamps) | 1 | 26.5 | 1.20 | 0.98 | - | - | picture | locks the two wedge modules together across the band | kit |
| LW1pa | module latch row (4 clamps) | 1 | 29.5 | 1.20 | 1.02 | - | - | picture | locks the two wedge modules together across the band | kit |
| LR0pf | module latch row (4 clamps) | 1 | 63.0 | 1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR0pa | module latch row (4 clamps) | 1 | 66.0 | 1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR1pf | module latch row (4 clamps) | 1 | 75.3 | 1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR1pa | module latch row (4 clamps) | 1 | 78.3 | 1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR2pf | module latch row (4 clamps) | 1 | 87.5 | 1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR2pa | module latch row (4 clamps) | 1 | 90.6 | 1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| Q1s | retro thruster, two rectangular nozzles | 1 | 0.8 | -1.55 | -0.25 | - | - | designed | retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap) | kit |
| Q2s | attitude thruster, two rectangular nozzles | 1 | 12.6 | -2.69 | 0.51 | - | - | designed | bow attitude thruster on the upper facet | kit |
| Q3s | attitude thruster, two rectangular nozzles | 1 | 86.9 | -3.28 | 0.42 | - | - | designed | stern attitude thruster on the rail's outer flank | kit |
| W1s | vision slit 0.4 x 0.09 | 1 | 8.4 | -2.75 | 0.16 | - | - | picture | blue-white window of the forward crew decks | kit |
| W2s | vision slit 0.4 x 0.09 | 1 | 11.7 | -2.89 | 0.17 | - | - | picture | blue-white window of the forward crew decks | kit |
| W3s | vision slit 0.4 x 0.09 | 1 | 15.0 | -3.02 | 0.19 | - | - | picture | blue-white window of the forward crew decks | kit |
| W4s | vision slit 0.5 x 0.09 | 1 | 57.9 | -3.28 | -0.55 | - | - | picture | blue-white window of the rails' crew decks | kit |
| W5s | vision slit 0.5 x 0.09 | 1 | 70.7 | -3.28 | -0.55 | - | - | picture | blue-white window of the rails' crew decks | kit |
| V1s | louvre panel 0.3 x 1.2 | 1 | 58.4 | -1.95 | 1.00 | - | - | picture | heat louvre on the rail deck over the crew decks | kit |
| V2s | louvre panel 0.3 x 1.2 | 1 | 70.7 | -1.95 | 1.00 | - | - | picture | heat louvre on the rail deck over the crew decks | kit |
| V3s | louvre panel 0.3 x 1.2 | 1 | 82.9 | -1.95 | 1.00 | - | - | picture | heat louvre on the rail deck over the engine room | kit |
| V6s | louvre panel 1.5 x 0.2 | 1 | 58.4 | -3.28 | 0.55 | - | - | picture | heat louvre on the rail's upper tier (H10's long flank slots) | kit |
| V7s | louvre panel 1.5 x 0.2 | 1 | 70.7 | -3.28 | 0.55 | - | - | picture | heat louvre on the rail's upper tier (H10's long flank slots) | kit |
| V8s | louvre panel 1.5 x 0.2 | 1 | 81.5 | -3.28 | 0.55 | - | - | picture | heat louvre on the rail's upper tier (H10's long flank slots) | kit |
| H60s | square hatch 0.5 | 1 | 62.2 | -3.28 | -0.85 | - | - | picture | rail flank hatch on the lower tier: access to the plant rooms | kit |
| H61s | square hatch 0.5 | 1 | 74.4 | -3.28 | -0.85 | - | - | picture | rail flank hatch on the lower tier: access to the plant rooms | kit |
| H62s | square hatch 0.5 | 1 | 86.7 | -3.28 | -0.85 | - | - | picture | rail flank hatch on the lower tier: access to the plant rooms | kit |
| H70s | square hatch 0.6 | 1 | 35.3 | -3.28 | -1.21 | - | - | picture | flank hatch on the lower facet: stores to the lower deck | kit |
| H71s | square hatch 0.6 | 1 | 44.7 | -3.28 | -1.21 | - | - | picture | flank hatch on the lower facet: stores to the lower deck | kit |
| V4s | louvre panel 0.3 x 1.2 | 1 | 22.5 | -0.85 | 0.95 | - | - | picture | heat louvre over the lance capacitor rooms | kit |
| V5s | louvre panel 0.3 x 0.9 | 1 | 45.7 | -0.80 | 1.02 | - | - | picture | heat louvre over the reactor | kit |
| LW0sf | module latch row (4 clamps) | 1 | 15.8 | -1.20 | 0.86 | - | - | picture | locks the two wedge modules together across the band | kit |
| LW0sa | module latch row (4 clamps) | 1 | 18.9 | -1.20 | 0.90 | - | - | picture | locks the two wedge modules together across the band | kit |
| LW1sf | module latch row (4 clamps) | 1 | 26.5 | -1.20 | 0.98 | - | - | picture | locks the two wedge modules together across the band | kit |
| LW1sa | module latch row (4 clamps) | 1 | 29.5 | -1.20 | 1.02 | - | - | picture | locks the two wedge modules together across the band | kit |
| LR0sf | module latch row (4 clamps) | 1 | 63.0 | -1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR0sa | module latch row (4 clamps) | 1 | 66.0 | -1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR1sf | module latch row (4 clamps) | 1 | 75.3 | -1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR1sa | module latch row (4 clamps) | 1 | 78.3 | -1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR2sf | module latch row (4 clamps) | 1 | 87.5 | -1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| LR2sa | module latch row (4 clamps) | 1 | 90.6 | -1.95 | 1.00 | - | - | picture | locks two rail modules together across the band | kit |
| H1 | square hatch 0.7 | 1 | 12.6 | 0.00 | 0.82 | - | - | picture | deck hatch over the forward crew deck | kit |
| H2 | square hatch 0.6 | 1 | 33.4 | 0.00 | 1.02 | - | - | picture | deck hatch to the command deck | kit |
| H3 | square hatch 0.8 | 1 | 36.7 | 0.00 | -1.98 | - | - | picture | belly hatch on the armour step: stores | kit |
| H4 | square hatch 0.8 | 1 | 45.2 | 0.00 | -1.98 | - | - | picture | belly hatch on the armour step: the reactor's service hatch | kit |
| H5p | square hatch 0.7 | 1 | 70.7 | 1.95 | -1.72 | - | - | picture | rail belly hatch: the engine room's stores | kit |
| H5s | square hatch 0.7 | 1 | 70.7 | -1.95 | -1.72 | - | - | picture | rail belly hatch: the engine room's stores | kit |
| HB1 | framed deck box 1.1 x 0.9 | 1 | 21.6 | 0.00 | 0.93 | - | - | picture | the bow lift head: stores up to the forward decks | kit |

Totals: 5 gun mounts with 9 barrels; 0 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| pale grey module plate, steel-blue trim (paint stage) | 0.8 | 99.9 | whole hull |  |
| implant-blue light strips (the blue line), blue-white nozzles and windows | 0.8 | 99.9 | the flank bands, the rails, the stern |  |
| no rust, no warm light, no asymmetry | 0.8 | 99.9 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the wedge | 6.5 to 52.3 | -3.95 to 3.95 | -1.88 to 1.02 | pale grey module plate | the heavy thick wedge: a flat deck, chamfered deck edges, upper facets out to the knuckle, the flank band with the blue line, lower facets, a flat worked belly; the shoulder terraces where the lance turrets sit low |
| Bow face round the ion trench | 0.8 to 6.5 | -2.64 to 2.64 | -1.22 to 0.73 | pale grey module plate | the blunt bow face (never a ship's stem): the wedge's facets run to it, the trench recessed in its middle |
| Rail, port | 52.0 to 93.8 | 0.62 to 3.28 | -1.72 to 1.00 | pale grey module plate | one of the twin rails: a chamfered block in two module tiers (a recessed band at mid height), the drives at its end |
| Rail, starboard | 52.0 to 93.8 | -3.28 to -0.62 | -1.72 to 1.00 | pale grey module plate | one of the twin rails: a chamfered block in two module tiers (a recessed band at mid height), the drives at its end |
| Drone bay block between the rails | 52.0 to 72.1 | -0.78 to 0.78 | -1.50 to 0.50 | recessed grey | the hangar between the rails (H10's bay): its roof a trough below the rail decks, the flush armoured doors in it |
| Belly armour step | 9.8 to 51.3 | -1.91 to 1.91 | -1.98 to -1.32 | recessed grey | a second armour layer under the wedge (a worked belly, R185 (5)) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck 0.12 (8% to 16%); lower deck -0.72 (9% to 16%); main deck 0.12 (19% to 52%); lower deck -0.95 (19% to 52%); rail deck -0.35 (92% to 54%); hangar deck -1.08 (71% to 54%).

Bulkhead and frame stations: F1 9.8%, F2 13.8%, F3 20.7%, F4 26.8%, F5 33.4%, F6 39.1%, F7 44.7%, F8 51.4%, R1 57.0%, R2 62.6%, R3 68.3%, R4 73.5%, R5 80.6%, R6 86.2%, R7 91.4%, R1 57.0%, R2 62.6%, R3 68.3%, R4 73.5%, R5 80.6%, R6 86.2%, R7 91.4%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| ion capacitors (machinery) | 7.9 to 15.7 | -1.30 to 1.30 | -0.64 to 0.04 | the ion cannon's capacitor banks and field drivers behind the trench |
| fwd corridor (hcorr) | 7.9 to 15.7 | 0.05 to -0.05 | 0.20 to 0.45 | white corridors of the forward crew deck |
| bow stores (hold) | 9.8 to 15.7 | 0.05 to -0.05 | -1.05 to -0.80 | bow stores and the retro thrusters' feeds |
| crew corridor (hcorr) | 19.0 to 31.5 | 0.05 to -0.05 | 0.20 to 0.60 | white corridors and crew berths of the main deck, numbered posts |
| command (bridge) | 34.8 to 48.0 | -1.20 to 1.20 | 0.20 to 0.62 | the command deck under the sensor fin: the Registry link room |
| lance rooms p (magazine) | 32.9 to 47.1 | 1.35 to 3.32 | -0.85 to 0.04 | the lance capacitor rooms under the shoulder turrets |
| lance rooms s (magazine) | 32.9 to 47.1 | -3.32 to -1.35 | -0.85 to 0.04 | the lance capacitor rooms under the shoulder turrets |
| reactor (core) | 34.8 to 49.0 | -1.15 to 1.15 | -1.50 to 0.04 | the reactor (hp_core): its power runs forward to the trench and out to the lances |
| rack 0 p (hrack) | 19.5 to 21.2 | 0.40 to 2.52 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 0 s (hrack) | 19.5 to 21.2 | -2.52 to -0.40 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 1 p (hrack) | 21.7 to 23.4 | 0.40 to 2.62 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 1 s (hrack) | 21.7 to 23.4 | -2.62 to -0.40 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 2 p (hrack) | 24.0 to 25.7 | 0.40 to 2.72 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 2 s (hrack) | 24.0 to 25.7 | -2.72 to -0.40 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 3 p (hrack) | 26.3 to 28.0 | 0.40 to 2.82 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 3 s (hrack) | 26.3 to 28.0 | -2.82 to -0.40 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 4 p (hrack) | 28.5 to 30.2 | 0.40 to 2.92 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| rack 4 s (hrack) | 28.5 to 30.2 | -2.92 to -0.40 | -0.87 to -0.12 | racks of identical equipment on the lower deck (factions.md "Inside") |
| picket store (magazine) | 27.3 to 32.7 | 0.05 to -0.05 | -1.55 to -1.03 | the picket lasers' power cells over the belly turrets |
| emerg mid (hemerg) | 19.2 to 48.5 | 0.05 to -0.05 | 0.56 to 0.60 | the blue emergency light strip along the corridor ceiling |
| hangar (hangar) | 54.4 to 70.7 | -0.40 to 0.40 | -1.00 to 0.15 | the drone hangar: drone racks either side, the doors overhead (data.js hangar 1) |
| rail crew p (hcorr) | 54.4 to 75.4 | 0.98 to 2.92 | -0.25 to 0.55 | crew decks and corridors in the rails, white, numbered |
| rail crew s (hcorr) | 54.4 to 75.4 | -2.92 to -0.98 | -0.25 to 0.55 | crew decks and corridors in the rails, white, numbered |
| rail stores p (machinery) | 54.4 to 75.4 | 0.98 to 2.92 | -1.35 to -0.47 | coolant and fuel plant under the rails' crew decks |
| rail stores s (machinery) | 54.4 to 75.4 | -2.92 to -0.98 | -1.35 to -0.47 | coolant and fuel plant under the rails' crew decks |
| engine room p (engroom) | 78.2 to 92.3 | 0.98 to 2.92 | -1.35 to 0.55 | the engine rooms: the feeds to the two nozzles of each rail |
| engine room s (engroom) | 78.2 to 92.3 | -2.92 to -0.98 | -1.35 to 0.55 | the engine rooms: the feeds to the two nozzles of each rail |
| emerg rail p (hemerg) | 54.4 to 75.4 | 0.98 to 2.92 | 0.50 to 0.54 | blue emergency light along the rails' corridors |
| emerg rail s (hemerg) | 54.4 to 75.4 | -2.92 to -0.98 | 0.50 to 0.54 | blue emergency light along the rails' corridors |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| deck and facets | 0.25 | machined plate in modules, flush panels over it |
| shoulder terraces | 0.35 | the lance turrets' pits |
| bow face | 0.45 | the blunt bow round the trench, the thickest plate |
| rails | 0.25 |  |
| belly and armour step | 0.30 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 17.4 (seam wanders 16.8 to 18.0) | the bow module tears off at the first module band, the trench and the capacitor rooms with it |
| B-2 | 53.0 (seam wanders 52.5 to 53.5) | the wedge tears from the rails at the junction ring, the drone bay roof torn across |
| B-3 | 76.8 (seam wanders 76.3 to 77.3) | the rails part at their middle module band: the stern modules and the nozzles fall away |

Full interiors throughout the hull (R215), hidden until a piece breaks: white corridors, blue emergency light, racks of identical equipment, the command deck, the lance rooms, the reactor, the drone hangar, the engine rooms. The Hegemony breaks in modules at the bulkhead rings (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 41.9 | 0.00 | -0.70 |  |  |  |
| hp_breach_0 | 17.4 | 3.16 | 0.07 | port | prow | on a module joint |
| hp_breach_1 | 28.0 | -3.54 | 0.04 | stbd | prow | on a module joint |
| hp_breach_2 | 51.3 | 3.58 | 0.04 | port | mid | on a module joint |
| hp_breach_3 | 64.5 | -3.36 | 0.35 | stbd | mid | on a module joint |
| hp_breach_4 | 76.8 | 3.36 | 0.35 | port | eng | on a module joint |
| hp_breach_5 | 89.1 | -3.36 | 0.35 | stbd | eng | on a module joint |
| hp_rcs_0 | 0.4 | 1.55 | -0.25 | port |  |  |
| hp_rcs_2 | 86.9 | 3.48 | 0.42 | port |  |  |
| hp_board_0 | 60.8 | 3.33 | 0.20 | port |  |  |
| hp_rcs_1 | 0.4 | -1.55 | -0.25 | stbd |  |  |
| hp_rcs_3 | 86.9 | -3.48 | 0.42 | stbd |  |  |
| hp_board_1 | 60.8 | -3.33 | 0.20 | stbd |  |  |
| hp_bay_0 | 61.9 | 0.00 | 0.58 |  |  | the drone bay doors: drones launch up |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 355 objects, 80 parts, 615 close pairs, 398 rays, 5 guns, 30 sensor pairs, 4 turrets swept, 10 cones, 43 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **H10's two tall box turrets with long thin twin barrels become low wide lance mounts sunk in shoulder terraces: a faceted housing with a sloped glacis, armoured cheeks, a capacitor bustle, two short thick containment barrels with coil rings and vented shrouds.** Ryan, R185 (4): "The hegemony guns look weird and almost cartoonish"; factions.md: low armoured mounts sunk into the shoulder armour, short thick barrels, never tall round turrets with long thin barrels. The turret top stands 0.1 over the deck; the barrels sit at deck level.
- **One shoulder turret a side, each one data.js slot: the port turret is hturbo P, the starboard hturbo S; each turns through its own broadside arc (30 to 150 degrees off the bow).** data.js h_dominion carries hturbo P and hturbo S (3 shots each); two barrels a turret fire on every volley (weapon_match SPLIT). H10's turret count and places are kept.
- **H10's glowing bow panel becomes the ion cannon: an emitter trench recessed in the blunt bow face, coil-lined walls, an emitter block with a blue lens at its back.** R183 (1): the ion weapon is a recessed emitter trench in a blunt bow face, never prongs or a barrel on the nose; data.js ion F (1 shot).
- **H10's small twin-tube fitting on the centreline is removed; the picket lasers (flak T) are two small twin turrets on the belly.** R241: no decorative or extra guns (the little twin tubes read as a gun with no data.js slot); the picket lasers on the belly keep the deck clear for the sensor fin (R240: no gun behind or aiming through a sensor) and cover the underside, where craft come from below.
- **H10's oval sensor panel becomes the one low sensor fin on the centreline between the turrets (0.4 tall, 2.4 long, its leading edge raked).** factions.md: "One low sensor fin, not a tower"; a taller first fin read as a submarine's sail from the beam (factions.md: H7 to H10 read as yachts or submarines); R240: no gun sits behind it or fires through it (the turrets fire outboard, the pickets below).
- **H10's open hangar recess between the rails becomes flush armoured drone doors in a trough between the rails (a seam line only), with blue guide lamps.** R232 (pack.md question 2): flush armoured drone doors on the Dominion; data.js hangar 1; the drones launch up out of the trough.
- **H10's two raised boxes at the ends of the bay opening are left out; the flush doors run the trough's length instead.** the doors fill the trough between the junction seam B-2 and the rails' first band (a box at the bay's forward end would sit across B-2), and H10 gives the boxes no job (R221: every part has a job).
- **H10's nozzles (two stacked pairs a rail in the side view, a pair across in the top view) become one flat row of four rectangular nozzle pods, two a rail, each a thick-lipped mouth with a blue-white throat and guide vanes.** factions.md: "a flat row of rectangular blue-white nozzles"; H10's views disagree with each other on the count; a round opening has depth (R244).
- **Even panel grid of two module sizes, module bands as raised rings with a deep double seam, flush fasteners (no rivets), H10's rows of four blocks kept as module latch rows at the bands.** paint direction hegemony.md (approved Nov 14): the even grid, two module sizes, the module band as structure; R243 ("Hegemony also pretty rigid and clean"); every part has a job (R221): the latches lock the modules.
- **The wedge's flanks are faceted round a vertical flank band (upper and lower facets, chamfers, a chine) and the rails carry a recessed mid band, so no flank is a flat wall.** R244 ("the sides of the carrier are just flat walls"), binding on every sheet ship; H10's rails show the two tiers.
- **The blue line runs along both flank bands and the rails' recess, broken only at the module bands.** factions.md: "a pale wedge with a line of blue light"; the strips are the running lights (paint direction 5).
- **The bow face is blunt and nearly upright (1.6 deep at the face), its corners chamfered; the belly rises toward it but never to a stem.** R183 (1) and factions.md: a blunt bow face; rule 4.1: no ship's prow or keel line.
- **Retro thrusters on the bow face, attitude thrusters on the facets and rails, blue-white window slits, louvres, flush hatches, a lift head, a belly armour step added.** a ship in space needs thrusters and access (lore 3.4: retro thrusters make backing off cheap; 3.3: blue-white windows); H10 shows no underside; every part has a job (R221).

## Designed here, not shown in the picture

- The belly is designed here; H10 shows no underside.
- Stencil marks ("HD-14", "SECTION") and the steel-blue trim tone are paint (the Hegemony stack, a later job), not modelled.
- Q1p (retro thruster, two rectangular nozzles): retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap).
- Q2p (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3p (attitude thruster, two rectangular nozzles): stern attitude thruster on the rail's outer flank.
- Q1s (retro thruster, two rectangular nozzles): retro thruster on the bow face (lore 3.4: retro thrusters make backing off cheap).
- Q2s (attitude thruster, two rectangular nozzles): bow attitude thruster on the upper facet.
- Q3s (attitude thruster, two rectangular nozzles): stern attitude thruster on the rail's outer flank.

## Issue 870, run 2

- **H10's glowing bow panel becomes a recessed ion accelerator: a broad blue lens block at the back, stepped octagonal capacitor rings, an emitter glow skirt and a thick inner muzzle lip** Ryan R287 run 2: open the face to 1.8 by 1.05 and cut an upper field window within the bow module so the blue lens reads at the whole-ship camera; R289: the same accelerator on IM5. The muzzle follows the lens; the wedge outline and insides stay unchanged
