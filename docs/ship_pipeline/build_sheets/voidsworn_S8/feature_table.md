# voidsworn_S8: Daybreak-class dreadnought (Sunward Crusade flagship), build sheet

Sunward Crusade (voidsworn) | class Dreadnought | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 738 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py voidsworn_S8 <out> render` rebuilds it from this file

**Length 27.0 world units** (data.js ascendant (cls 'Dreadnought'); length from godot/render/hull_table.gd CLS_LEN['Dreadnought'] = 27.0 (drawn x SHIP_K 1.6 = 43.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | hbattery | P | 5 | P1 (1), P2 (1), P3 (1), P4 (1), P5 (1) |
| 1 | hbattery | S | 5 | S1 (1), S2 (1), S3 (1), S4 (1), S5 (1) |
| 2 | turret | T | 2 | T1 (1), T2 (1) |
| 3 | flak | T | 3 | F1 (2), F2 (2) |

| Check | Value |
|---|---|
| model length | 26.997 |
| length side | 27.025 |
| length top | 27.025 |
| length disagreement percent | 0.0 |
| beam top | 7.138 |
| beam bow | 7.138 |
| beam disagreement percent | 0.0 |
| height side | 5.5 |
| height bow | 5.5 |
| height disagreement percent | 0.0 |
| widest at station percent | 56.2 |
| hull beam | 5.32 |
| hull depth | 2.87 |
| L to B hull | 5.08 |
| L to H hull | 9.41 |
| prow overhang | 0.0 |
| outline iou percent | 86.2 |
| mass outline iou percent | 87.7 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| P1 | heavy sear broadside, single casemate | 1 barrel | 36.9 | 2.19 | 0.05 | 90 deg off the bow to port | P hbattery | picture | port broadside port 1 of 5 (heavy sear broadside, hbattery P) |
| P2 | heavy sear broadside, single casemate | 1 barrel | 41.9 | 2.20 | 0.05 | 90 deg off the bow to port | P hbattery | picture | port broadside port 2 of 5 (heavy sear broadside, hbattery P) |
| P3 | heavy sear broadside, single casemate | 1 barrel | 46.9 | 2.22 | 0.05 | 90 deg off the bow to port | P hbattery | picture | port broadside port 3 of 5 (heavy sear broadside, hbattery P) |
| P4 | heavy sear broadside, single casemate | 1 barrel | 51.9 | 2.25 | 0.05 | 90 deg off the bow to port | P hbattery | picture | port broadside port 4 of 5 (heavy sear broadside, hbattery P) |
| P5 | heavy sear broadside, single casemate | 1 barrel | 56.9 | 2.32 | 0.05 | 90 deg off the bow to port | P hbattery | picture | port broadside port 5 of 5 (heavy sear broadside, hbattery P) |
| S1 | heavy sear broadside, single casemate | 1 barrel | 36.9 | -2.19 | 0.05 | 90 deg off the bow to starboard | S hbattery | picture | starboard broadside port 1 of 5 (heavy sear broadside, hbattery S) |
| S2 | heavy sear broadside, single casemate | 1 barrel | 41.9 | -2.20 | 0.05 | 90 deg off the bow to starboard | S hbattery | picture | starboard broadside port 2 of 5 (heavy sear broadside, hbattery S) |
| S3 | heavy sear broadside, single casemate | 1 barrel | 46.9 | -2.22 | 0.05 | 90 deg off the bow to starboard | S hbattery | picture | starboard broadside port 3 of 5 (heavy sear broadside, hbattery S) |
| S4 | heavy sear broadside, single casemate | 1 barrel | 51.9 | -2.25 | 0.05 | 90 deg off the bow to starboard | S hbattery | picture | starboard broadside port 4 of 5 (heavy sear broadside, hbattery S) |
| S5 | heavy sear broadside, single casemate | 1 barrel | 56.9 | -2.32 | 0.05 | 90 deg off the bow to starboard | S hbattery | picture | starboard broadside port 5 of 5 (heavy sear broadside, hbattery S) |
| T1 | sear turret, single turret | 1 barrel | 37.4 | 1.42 | 1.44 | forward, +5 elev | T turret | picture | port Sear turret: one heavy focusing emitter, on a low tub; the pair is the one Sear turret slot (2 shots: one each, every volley) |
| F1 | spark flak, twin turret | 2 barrels | 47.8 | 1.42 | 1.30 | 30 deg off the bow to port, +12 elev | T flak | picture | port spark flak twin; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley) |
| T2 | sear turret, single turret | 1 barrel | 37.4 | -1.42 | 1.44 | forward, +5 elev | T turret | picture | starboard Sear turret: one heavy focusing emitter, on a low tub; the pair is the one Sear turret slot (2 shots: one each, every volley) |
| F2 | spark flak, twin turret | 2 barrels | 47.8 | -1.42 | 1.30 | 30 deg off the bow to starboard, +12 elev | T flak | picture | starboard spark flak twin; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley) |
| W1 | vision slit 0.2 x 0.06 | 1 | 61.1 | -0.27 | 1.38 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W2 | vision slit 0.2 x 0.06 | 1 | 61.1 | 0.00 | 1.38 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W3 | vision slit 0.2 x 0.06 | 1 | 61.1 | 0.27 | 1.38 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| R1 | radiator spire, 1.1 tall, profile blade | 1 | 63.9 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| R2 | radiator spire, 1.4 tall, profile raked | 1 | 67.0 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| R3 | radiator spire, 1.6 tall, profile stepped | 1 | 70.2 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| R4 | radiator spire, 1.8 tall, profile twin | 1 | 73.3 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| R5 | radiator spire, 1.6 tall, profile stepped | 1 | 76.5 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| R6 | radiator spire, 1.4 tall, profile raked | 1 | 79.6 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| R7 | radiator spire, 1.1 tall, profile blade | 1 | 82.8 | 0.00 | 1.78 | - | - | picture | sheds the reactor's heat: the lit ember core showing between dark iron ribs |
| E1 | engine, bell 2.3 across | 1 | 99.8 | 1.15 | -0.17 | exhaust aft | - | picture | port main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| E2 | engine, bell 2.3 across | 1 | 99.8 | -1.15 | -0.17 | exhaust aft | - | picture | starboard main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| Q1p | attitude thruster quad | 1 | 14.4 | 1.08 | 0.43 | - | - | designed | bow attitude thruster on the upper facet |
| Q2p | attitude thruster quad | 1 | 89.3 | 2.06 | 0.64 | - | - | designed | stern attitude thruster on the upper facet |
| V1p | louvre panel 0.9 x 0.4 | 1 | 66.3 | 2.05 | 0.81 | - | - | picture | reactor heat louvre over the reactor room |
| V2p | louvre panel 0.9 x 0.4 | 1 | 73.0 | 2.12 | 0.81 | - | - | picture | reactor heat louvre over the reactor room |
| V3p | louvre panel 0.9 x 0.4 | 1 | 79.6 | 2.11 | 0.80 | - | - | picture | reactor heat louvre over the reactor room |
| G1p | vision slit 0.2 x 0.07 | 1 | 44.4 | 2.21 | 0.05 | - | - | picture | a gun gallery's ember slit between two ports |
| G2p | vision slit 0.2 x 0.07 | 1 | 54.4 | 2.28 | 0.05 | - | - | picture | a gun gallery's ember slit between two ports |
| L1p | running light | 1 | 9.3 | 0.93 | -0.24 | - | - | picture | frost-white running point on the deck edge |
| L2p | running light | 1 | 18.9 | 1.61 | -0.35 | - | - | picture | frost-white running point on the deck edge |
| L3p | running light | 1 | 27.0 | 1.98 | -0.41 | - | - | picture | frost-white running point on the deck edge |
| L4p | running light | 1 | 62.6 | 1.64 | 1.06 | - | - | picture | frost-white running point on the deck edge |
| L5p | running light | 1 | 69.6 | 1.74 | 1.07 | - | - | picture | frost-white running point on the deck edge |
| L6p | running light | 1 | 76.3 | 1.77 | 1.06 | - | - | picture | frost-white running point on the deck edge |
| L7p | running light | 1 | 84.8 | 1.69 | 1.02 | - | - | picture | frost-white running point on the deck edge |
| Q1s | attitude thruster quad | 1 | 14.4 | -1.08 | 0.43 | - | - | designed | bow attitude thruster on the upper facet |
| Q2s | attitude thruster quad | 1 | 89.3 | -2.06 | 0.64 | - | - | designed | stern attitude thruster on the upper facet |
| V1s | louvre panel 0.9 x 0.4 | 1 | 66.3 | -2.05 | 0.81 | - | - | picture | reactor heat louvre over the reactor room |
| V2s | louvre panel 0.9 x 0.4 | 1 | 73.0 | -2.12 | 0.81 | - | - | picture | reactor heat louvre over the reactor room |
| V3s | louvre panel 0.9 x 0.4 | 1 | 79.6 | -2.11 | 0.80 | - | - | picture | reactor heat louvre over the reactor room |
| G1s | vision slit 0.2 x 0.07 | 1 | 44.4 | -2.21 | 0.05 | - | - | picture | a gun gallery's ember slit between two ports |
| G2s | vision slit 0.2 x 0.07 | 1 | 54.4 | -2.28 | 0.05 | - | - | picture | a gun gallery's ember slit between two ports |
| L1s | running light | 1 | 9.3 | -0.93 | -0.24 | - | - | picture | frost-white running point on the deck edge |
| L2s | running light | 1 | 18.9 | -1.61 | -0.35 | - | - | picture | frost-white running point on the deck edge |
| L3s | running light | 1 | 27.0 | -1.98 | -0.41 | - | - | picture | frost-white running point on the deck edge |
| L4s | running light | 1 | 62.6 | -1.64 | 1.06 | - | - | picture | frost-white running point on the deck edge |
| L5s | running light | 1 | 69.6 | -1.74 | 1.07 | - | - | picture | frost-white running point on the deck edge |
| L6s | running light | 1 | 76.3 | -1.77 | 1.06 | - | - | picture | frost-white running point on the deck edge |
| L7s | running light | 1 | 84.8 | -1.69 | 1.02 | - | - | picture | frost-white running point on the deck edge |
| H1 | round hatch 0.4 | 1 | 25.6 | 0.75 | 1.15 | - | - | picture | deck hatch |
| H2 | round hatch 0.4 | 1 | 25.6 | -0.75 | 1.15 | - | - | picture | deck hatch |
| H3 | round hatch 0.4 | 1 | 57.0 | 1.30 | 1.26 | - | - | picture | deck hatch |
| H4 | round hatch 0.4 | 1 | 57.0 | -1.30 | 1.26 | - | - | picture | deck hatch |
| H5 | round hatch 0.5 | 1 | 38.9 | 0.60 | -1.72 | - | - | picture | belly hatch on the armour step |
| H6 | round hatch 0.5 | 1 | 38.9 | -0.60 | -1.72 | - | - | picture | belly hatch on the armour step |
| H7 | round hatch 0.5 | 1 | 72.2 | 0.60 | -1.74 | - | - | picture | belly hatch on the armour step |
| H8 | round hatch 0.5 | 1 | 72.2 | -0.60 | -1.74 | - | - | picture | belly hatch on the armour step |
| HB1 | framed deck box 0.8 x 0.6 | 1 | 28.2 | 0.00 | 1.20 | - | - | picture | the bow lift head: stores up to the forward decks |
| HB2 | framed deck box 0.6 x 0.6 | 1 | 55.7 | 0.00 | 1.27 | - | - | picture | the hoist head behind T2: power cells up to the Sear turrets |

Totals: 14 gun mounts with 16 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| black iron plate, frost-white markings (paint stage) | 0.0 | 100.0 | whole hull |  |
| ember glow (radiator bars, engine throats, window slits) | 61.1 | 100.0 | the spires, the bells, the slits |  |
| frost-white running points | 0.0 | 100.0 | the deck edges |  |
| no rust anywhere, no blue light | 0.0 | 100.0 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the blade | 0.0 to 93.0 | -2.66 to 2.66 | -1.58 to 1.29 | black iron plate | a long faceted blade: crowned deck, big upper facets, the broadside band, lower facets, a flat worked belly; widest (5.3) at the stern third |
| Bow ridge | 2.2 to 26.1 | -0.37 to 0.37 | 0.15 to 1.33 | darker iron | the spearhead's raised centre ridge (a forged fuller), tapering to the point; stiffens the long bow |
| Bow cheek plates, port | 6.3 to 30.0 | 0.38 to 1.94 | 0.13 to 0.97 | black iron | two forged layers along the upper facet, the spearhead's bevels |
| Bow cheek plates, starboard | 6.3 to 30.0 | -1.94 to -0.38 | 0.13 to 0.97 | black iron | two forged layers along the upper facet, the spearhead's bevels |
| Gun deck upper lip, port | 33.5 to 60.2 | 2.12 to 2.60 | 0.34 to 0.57 | darker iron | the armoured shelf over (under) the broadside ports; its ends are angled |
| Gun deck lower lip, port | 33.5 to 60.2 | 2.12 to 2.60 | -0.47 to -0.24 | darker iron | the armoured shelf over (under) the broadside ports; its ends are angled |
| Gun deck upper lip, starboard | 33.5 to 60.2 | -2.60 to -2.12 | 0.34 to 0.57 | darker iron | the armoured shelf over (under) the broadside ports; its ends are angled |
| Gun deck lower lip, starboard | 33.5 to 60.2 | -2.60 to -2.12 | -0.47 to -0.24 | darker iron | the armoured shelf over (under) the broadside ports; its ends are angled |
| Sear turret tub, port | 35.0 to 39.8 | 0.77 to 2.07 | 0.43 to 1.44 | darker iron | a low forged tub at the deck edge, its skirt running down onto the upper facet |
| Flak tub, port | 46.1 to 49.5 | 0.96 to 1.88 | 0.43 to 1.30 | darker iron | an octagonal forged tub at the deck edge, lower than the Sear tubs |
| Sear turret tub, starboard | 35.0 to 39.8 | -2.07 to -0.77 | 0.43 to 1.44 | darker iron | a low forged tub at the deck edge, its skirt running down onto the upper facet |
| Flak tub, starboard | 46.1 to 49.5 | -1.88 to -0.96 | 0.43 to 1.30 | darker iron | an octagonal forged tub at the deck edge, lower than the Sear tubs |
| Spine block (the spire line's base) | 61.1 to 84.5 | -0.62 to 0.62 | 1.16 to 1.78 | darker iron | a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-4) |
| Radiator spire R1 (blade, 1.1 tall) | 62.9 to 64.9 | -0.35 to 0.35 | 2.22 to 2.70 | ember core between iron ribs | one of the seven spires of the spire line |
| Radiator spire R2 (raked, 1.4 tall) | 66.1 to 68.1 | -0.38 to 0.38 | 2.22 to 2.98 | ember core between iron ribs | one of the seven spires of the spire line |
| Radiator spire R3 (stepped, 1.6 tall) | 69.1 to 71.3 | -0.41 to 0.41 | 2.22 to 3.22 | ember core between iron ribs | one of the seven spires of the spire line |
| Radiator spire R4 (twin, 1.8 tall) | 72.2 to 74.5 | -0.42 to 0.42 | 2.22 to 3.40 | ember core between iron ribs | one of the seven spires of the spire line |
| Radiator spire R5 (stepped, 1.6 tall) | 75.4 to 77.6 | -0.41 to 0.41 | 2.22 to 3.22 | ember core between iron ribs | one of the seven spires of the spire line |
| Radiator spire R6 (raked, 1.4 tall) | 78.7 to 80.7 | -0.38 to 0.38 | 2.22 to 2.98 | ember core between iron ribs | one of the seven spires of the spire line |
| Radiator spire R7 (blade, 1.1 tall) | 81.9 to 83.7 | -0.35 to 0.35 | 2.22 to 2.66 | ember core between iron ribs | one of the seven spires of the spire line |
| Belly armour step | 26.3 to 86.3 | -1.29 to 1.29 | -1.71 to -1.40 | darker iron | a second forged layer under the gun deck and the reactor |
| Dorsal power trunk | 29.8 to 58.0 | -0.20 to 0.20 | 1.20 to 1.42 | darker iron | armoured conduits from the reactor to the turrets and the bow (S8's centre strip) |

## INSIDE (R98, R209): what each break reveals

The bow deck sits at -0.12 (11% to 29%). The forward decks sit at 0.58 (upper, 32% to 60%) and -0.12 (gun, 35% to 60%). The aft decks sit at 0.58 (upper, 61% to 92%) and -0.45 (gun, 63% to 92%).

Bulkhead and frame stations are F0 8.5%, F1 15.2%, F2 21.9%, F3 28.7%, F4 32.4%, F5 39.4%, F6 44.4%, F7 49.4%, F8 54.5%, F9 59.6%, F10 63.2%, F11 64.8%, F12 71.5%, F13 78.2%, F14 84.8%, and F15 91.9%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| fire control (machinery) | 15.9 to 20.7 | -0.38 to 0.38 | -0.08 to 0.45 | the forward fire-control room: the broadside directors (no AI: plotted by hand) |
| bow stores (hold) | 14.4 to 20.7 | -0.52 to 0.52 | -0.60 to -0.16 | bow stores and the bow thrusters' feeds |
| crew fwd (crew) | 22.2 to 30.0 | 0.04 to -0.04 | -0.08 to 0.74 | crew decks: the dawn watch berths |
| ballast fwd (machinery) | 22.2 to 30.0 | -0.73 to 0.73 | -0.95 to -0.16 | bow trim tanks and pumps |
| gun gallery p (gallery) | 33.0 to 59.1 | 1.30 to 1.55 | -0.26 to 0.53 | the gun crews' galleries behind the ports, ember-lit: the old manual gun deck (lore 2.5) |
| gun gallery s (gallery) | 33.0 to 59.1 | -1.55 to -1.30 | -0.26 to 0.53 | the gun crews' galleries behind the ports, ember-lit: the old manual gun deck (lore 2.5) |
| shell rooms p (magazine) | 33.7 to 58.9 | 0.94 to 1.27 | 0.04 to 0.43 | the broadside shell room in the gun gallery |
| shell hoist p (machinery) | 33.7 to 58.9 | 0.94 to 1.27 | -0.15 to -0.02 | the shell hoist drive below the gallery shell room |
| shell rooms s (magazine) | 33.7 to 58.9 | -1.27 to -0.94 | 0.04 to 0.43 | the broadside shell room in the gun gallery |
| shell hoist s (machinery) | 33.7 to 58.9 | -1.27 to -0.94 | -0.15 to -0.02 | the shell hoist drive below the gallery shell room |
| sear cells (magazine) | 34.1 to 40.4 | -0.90 to 0.90 | -0.26 to 0.53 | the Sear turrets' power cells, hoisted to both tubs |
| fire plot (bridge) | 49.3 to 55.2 | -0.90 to 0.90 | -0.26 to 0.53 | the broadside plotting room (no AI: plotted by hand) |
| flak magazine (magazine) | 41.9 to 48.2 | -0.90 to 0.90 | -0.26 to 0.53 | the spark flak magazine, between the tubs |
| upper fwd rooms (crew) | 33.0 to 59.1 | -0.97 to 0.97 | 0.63 to 0.82 | the gunners' mess and the chalk wall where the names go up before launch |
| command (bridge) | 61.7 to 64.8 | -1.11 to 1.11 | 0.63 to 0.82 | the command deck under the spine block's slits |
| reactor (core) | 65.9 to 78.2 | -1.15 to 1.15 | -1.18 to 0.52 | the reactor: its heat goes up through the plenum into the spires (hp_core) |
| coolant p (machinery) | 65.9 to 78.2 | 1.38 to 1.54 | -0.85 to 0.50 | coolant pumps and heat exchangers either side of the reactor |
| coolant s (machinery) | 65.9 to 78.2 | -1.54 to -1.38 | -0.85 to 0.50 | coolant pumps and heat exchangers either side of the reactor |
| plenum (machinery) | 65.4 to 83.3 | -1.18 to 1.18 | 0.63 to 0.82 | the heat plenum feeding the spire line |
| roll hall (crew) | 63.2 to 65.4 | -1.85 to 1.85 | -0.41 to 0.52 | the Roll, the crew hall under the command deck |
| engine room (engroom) | 78.9 to 87.0 | -1.05 to 1.05 | -1.15 to 0.52 | the engine room and the two drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| upper facets and deck | 0.30 | forged plate over the galleries and the turret hoists |
| broadside band and lips | 0.35 | the gun deck face, the heaviest belt |
| spearhead | 0.40 | solid forged layers toward the point |
| belly and armour step | 0.30 |  |
| spine block | 0.25 | it snaps off with the spires |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 31.5 (seam wanders 30.7 to 32.0) | the spearhead tears from the gun deck at its root, opening the crew decks and the fire-control room |
| B-2 | 60.2 (seam wanders 59.6 to 60.3) | the gun deck tears from the reactor section, between the last ports and the spine block |
| B-3 | 32.6 to 59.3 (along) | along the gun decks: the lower hull peels away under the galleries, their shell rooms and the turrets |
| B-4 | 61.3 to 84.1 (along) | the spire line snaps off as one piece, the spine block tearing along its root |

Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit gun galleries, frames, the reactor and its machinery. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 71.9 | 0.00 | -0.30 |  |  |  |
| hp_breach_0 | 15.2 | 1.44 | -0.01 | port | prow | on the broadside deck line |
| hp_breach_1 | 20.4 | -1.76 | 0.01 | stbd | prow | on the broadside deck line |
| hp_breach_2 | 25.6 | 1.99 | 0.03 | port | prow | on the broadside deck line |
| hp_breach_3 | 39.4 | -1.60 | -1.14 | stbd | mid | on the lower flank, clear of broadside fittings |
| hp_breach_4 | 49.4 | 1.63 | -1.14 | port | mid | on the lower flank, clear of broadside fittings |
| hp_breach_5 | 59.3 | -1.72 | -1.14 | stbd | mid | on the lower flank, clear of broadside fittings |
| hp_breach_6 | 72.2 | 2.63 | 0.05 | port | eng | on the broadside deck line |
| hp_breach_7 | 83.3 | -2.56 | 0.05 | stbd | eng | on the broadside deck line |
| hp_rcs_0 | 14.4 | 1.08 | 0.43 | port |  |  |
| hp_rcs_2 | 89.3 | 2.06 | 0.64 | port |  |  |
| hp_board_0 | 63.3 | 2.46 | 0.05 | port |  |  |
| hp_rcs_1 | 14.4 | -1.08 | 0.43 | stbd |  |  |
| hp_rcs_3 | 89.3 | -2.06 | 0.64 | stbd |  |  |
| hp_board_1 | 63.3 | -2.46 | 0.05 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 401 objects, 64 parts, 1224 close pairs, 733 rays, 14 guns, 0 sensor pairs, 4 turrets swept, 6 cones, 35 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The forked prow is replaced by a forged spearhead: one point at mid height, diamond in section, a raised centre ridge and two layers of cheek plates along its upper facets.** Ryan, Nov 12 (R232, pack.md question 1): "It shouldn't be the same shape for everything"; the Daybreak carries no lance, so no lance recess; the point at mid height with matching upper and lower facets is a blade, never a ship's stem (factions.md Never).
- **Five broadside ports a side, not seven.** data.js hbattery fires 5 shots a volley; seven single guns would leave two silent on every volley (R241, the SPLIT rule); five heavy single guns all fire every volley.
- **S8's four low deck turrets kept in its grid of two pairs, each pair one data.js slot: the two Sear turrets forward with one heavy emitter each, the two spark flak twins aft, all on low tubs at the deck edges.** data.js ascendant carries one turret slot (2 shots) and one flak slot (3 shots); four twin turrets would be extra weapons or silent barrels (R241). Two single-emitter Sear turrets fire one shot each every volley; two flak twins share 3 shots over 4 barrels and both fire every volley (weapon_match SPLIT). The emitters are short enough that a pair trained at each other never meets (the fit check's SWEEP).
- **S8's radiator bank (upright ember bars in two wide wedges either side of the spine, rising to the stern end) becomes one row of seven radiator spires on the centreline spine block, tallest at the middle of the row, each its own profile (blade, raked, stepped, twin), each a stack of flat radiator fins glowing ember between iron posts.** factions.md: "a row of tall radiator spires along the spine, tallest amidships"; Ryan, Nov 12 (R232): "not exactly the same shape for every ship". Upright panels read as organ pipes from the beam and shards from above in the first render; flat fins read as radiators from the battle camera and from above. The ember glow and the line's place in the stern half are S8's.
- **The spires stand aft of every turret and rise toward the middle of the row.** so both turret pairs fire aft past and over the whole line (the fit check's ARC test); the spires are broad finned radiators, never masts, so nothing reads as a gun aimed through a mast (R240).
- **The hull is a little deeper (2.75 against S8's 2.2) and its flanks are angled facets round a vertical broadside band.** The gun deck, upper deck and real insides need the depth (R215). R244 calls for angled facets along the flanks.
- **The shell rooms and hoist drives sit in the port and starboard gun galleries.** This clears the space below the B-3 peel inside the accepted hull (R254, issue 1059).
- **The decks, frames and Roll hall clear the ends of B-3.** The liner has relief along B-3 and across its joints with B-1 and B-2 so the broken interior stays within its own plating (issue 1059).
- **The hull is widest at the stern third (5.3 over the reactor); with the broadside barrels the outline is still widest amidships (7.1 at 56 percent), as S8's is.** factions.md: "widest at the stern third"; S8's body is 4.4 from end to end, its width carried by the radiator bank and the guns.
- **The two engine bells are bigger (2.1 across) and their drums run 1.55 deep into the stern.** factions.md: "big bells, ember orange, deep-set"; S8's two bells are its stern's identity and must read from the battle camera.
- **Weapons built from the lore, not S8's generic barrels (R221).** the broadside guns are heavy short guns in deep round ports (R244: a round opening has depth); the Sear turrets are forged turrets with one heavy focusing emitter and radiator fins (las); the spark flak a squat drum with twin braked barrels and ammunition drums (tools/blender/kits/voidsworn/README.md).
- **Attitude thrusters, deck and belly hatches, lift heads, heat louvres, ember slits, frost running points, a belly armour step added.** a ship in space needs thrusters and access; the spires' reactor needs louvres; S8 shows no underside; every part has a job (R221).
- **The command deck looks out through ember slits in the spine block's forward face, not a box on the deck.** S8's small lit block before the radiators read as a deck house (R185 (5): no deck house); the same ember windows now sit in the spine block itself.
- **The spires stand at about S8's bank height: the tallest 1.8 over the spine block (2.3 over the deck) against S8's 1.8.** Ryan, Nov 19 2026 (R331, issue 1158): "can we scale down the giant radiator/orange towers on each ship a bit too?"; the first build's 2.6 tallest read as giant orange towers. Every spire is 70 percent of its first height (1.6, 2.0, 2.35, 2.6, 2.35, 2.0, 1.55 became 1.12, 1.4, 1.65, 1.82, 1.65, 1.4, 1.09), same count, stations, lengths and profiles; the spire line still crowns the silhouette at the battle camera.
- **The ember is in the fin slats, not a whole lit tower (R331, issue 1158).** The shared Sunward spire option radiator(..., glow='slats'): first three to five glowing fins over a dark core (Nov 19), then from R347 (PR 1164, Nov 20) the core lit the full height between dark iron ribs 0.15 apart, as on the Warden. Warden, Vigil and the later Sunward builds use the same option (R333).
- **Modelled plates: sleek triangles on the spearhead's facets and cheek plates, ordered rows of forged plates elsewhere.** paint direction sunward.md (R243, "more triangle sleek panels") asks for triangles on the flat fields; modelled on the deck in the first render they read as rows of letters at a distance, so the deck keeps forged rows and the Sunward paint stack lays its triangles there.

## Designed here, not shown in the picture

- The belly is designed here; S8 shows no underside.
- Frost-white markings and the half-sun crest are paint (the Sunward stack, a later job), not modelled.
- Q1p (attitude thruster quad): bow attitude thruster on the upper facet.
- Q2p (attitude thruster quad): stern attitude thruster on the upper facet.
- Q1s (attitude thruster quad): bow attitude thruster on the upper facet.
- Q2s (attitude thruster quad): stern attitude thruster on the upper facet.
