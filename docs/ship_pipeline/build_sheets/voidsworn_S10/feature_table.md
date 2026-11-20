# voidsworn_S10: Vigil-class cruiser (Sunward Crusade), build sheet

Sunward Crusade (voidsworn) | class Cruiser | version 1 (first sheet), 2026-11-19 | blockout: built in the issue 1157 cloud copy (bpy 5.3, Cycles CPU); `build.py voidsworn_S10 <out> render` rebuilds it from this file

**Length 14.5 world units** (data.js penitent (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | battery | P | 4 | P1 (1), P2 (1), P3 (1), P4 (1) |
| 1 | battery | S | 4 | S1 (1), S2 (1), S3 (1), S4 (1) |
| 2 | lance | F | 1 | L1 (1) |

| Check | Value |
|---|---|
| model length | 14.48 |
| length side | 14.5 |
| length top | 14.5 |
| length disagreement percent | 0.0 |
| beam top | 4.425 |
| beam bow | 4.425 |
| beam disagreement percent | 0.0 |
| height side | 3.538 |
| height bow | 3.538 |
| height disagreement percent | 0.0 |
| widest at station percent | 64.4 |
| hull beam | 2.9 |
| hull depth | 1.81 |
| L to B hull | 5.0 |
| L to H hull | 8.01 |
| prow overhang | 0.95 |
| outline iou percent | 88.2 |
| mass outline iou percent | 88.1 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| L1 | oath lance, one emitter in the point (fixed) | 1 barrel | 10.4 | 0.00 | -0.02 | forward | F lance | picture | the Oath lance (lance F, 1 shot): one emitter set in the spearhead's point: a heavy forged collar, a dark bore about 0.45 across (a third of the concept's opening), an ember lens set shallow in it |
| C1p | louvre panel 0.3 x 0.2 | 1 | 15.6 | 0.67 | 0.40 | - | - | picture | a capacitor bank's heat louvre on the cheek housing |
| C2p | louvre panel 0.3 x 0.2 | 1 | 19.4 | 0.82 | 0.50 | - | - | picture | a capacitor bank's heat louvre on the cheek housing |
| C3p | louvre panel 0.3 x 0.2 | 1 | 23.2 | 0.92 | 0.54 | - | - | picture | a capacitor bank's heat louvre on the cheek housing |
| C1s | louvre panel 0.3 x 0.2 | 1 | 15.6 | -0.67 | 0.40 | - | - | picture | a capacitor bank's heat louvre on the cheek housing |
| C2s | louvre panel 0.3 x 0.2 | 1 | 19.4 | -0.82 | 0.50 | - | - | picture | a capacitor bank's heat louvre on the cheek housing |
| C3s | louvre panel 0.3 x 0.2 | 1 | 23.2 | -0.92 | 0.54 | - | - | picture | a capacitor bank's heat louvre on the cheek housing |
| P1 | sear battery, single casemate | 1 barrel | 38.1 | 1.28 | 0.00 | 90 deg off the bow to port | P battery | picture | port battery port 1 of 4 (Sear battery, battery P) |
| P2 | sear battery, single casemate | 1 barrel | 47.1 | 1.32 | 0.00 | 90 deg off the bow to port | P battery | picture | port battery port 2 of 4 (Sear battery, battery P) |
| P3 | sear battery, single casemate | 1 barrel | 56.1 | 1.35 | 0.00 | 90 deg off the bow to port | P battery | picture | port battery port 3 of 4 (Sear battery, battery P) |
| P4 | sear battery, single casemate | 1 barrel | 65.1 | 1.40 | 0.00 | 90 deg off the bow to port | P battery | picture | port battery port 4 of 4 (Sear battery, battery P) |
| S1 | sear battery, single casemate | 1 barrel | 38.1 | -1.28 | 0.00 | 90 deg off the bow to starboard | S battery | picture | starboard battery port 1 of 4 (Sear battery, battery S) |
| S2 | sear battery, single casemate | 1 barrel | 47.1 | -1.32 | 0.00 | 90 deg off the bow to starboard | S battery | picture | starboard battery port 2 of 4 (Sear battery, battery S) |
| S3 | sear battery, single casemate | 1 barrel | 56.1 | -1.35 | 0.00 | 90 deg off the bow to starboard | S battery | picture | starboard battery port 3 of 4 (Sear battery, battery S) |
| S4 | sear battery, single casemate | 1 barrel | 65.1 | -1.40 | 0.00 | 90 deg off the bow to starboard | S battery | picture | starboard battery port 4 of 4 (Sear battery, battery S) |
| W1 | vision slit 0.1 x 0.04 | 1 | 59.4 | -0.22 | 0.94 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W2 | vision slit 0.1 x 0.04 | 1 | 59.4 | 0.00 | 0.94 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W3 | vision slit 0.1 x 0.04 | 1 | 59.4 | 0.22 | 0.94 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| R1 | radiator spire, 0.80 tall, profile blade | 1 | 66.2 | 0.00 | 1.08 | - | - | picture | sheds the reactor's heat: spaced ember fin slats between iron posts (R331) |
| R2 | radiator spire, 1.02 tall, profile raked | 1 | 71.2 | 0.00 | 1.08 | - | - | picture | sheds the reactor's heat: spaced ember fin slats between iron posts (R331) |
| R3 | radiator spire, 1.20 tall, profile twin | 1 | 76.1 | 0.00 | 1.08 | - | - | picture | sheds the reactor's heat: spaced ember fin slats between iron posts (R331) |
| R4 | radiator spire, 1.00 tall, profile stepped | 1 | 81.1 | 0.00 | 1.08 | - | - | picture | sheds the reactor's heat: spaced ember fin slats between iron posts (R331) |
| R5 | radiator spire, 0.78 tall, profile blade | 1 | 86.1 | 0.00 | 1.08 | - | - | picture | sheds the reactor's heat: spaced ember fin slats between iron posts (R331) |
| E1 | engine, bell 1.3 across | 1 | 99.8 | 0.80 | -0.12 | exhaust aft | - | picture | port main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| E2 | engine, bell 1.3 across | 1 | 99.8 | -0.80 | -0.12 | exhaust aft | - | picture | starboard main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| Q1p | attitude thruster quad | 1 | 11.4 | 0.58 | -0.31 | - | - | designed | bow attitude thruster on the lower facet |
| Q2p | attitude thruster quad | 1 | 86.0 | 1.12 | 0.41 | - | - | designed | stern attitude thruster on the upper facet |
| V1p | louvre panel 0.5 x 0.2 | 1 | 70.8 | 1.20 | 0.48 | - | - | picture | reactor heat louvre over the reactor room |
| V2p | louvre panel 0.5 x 0.2 | 1 | 76.3 | 1.17 | 0.47 | - | - | picture | reactor heat louvre over the reactor room |
| V3p | louvre panel 0.5 x 0.2 | 1 | 81.9 | 1.13 | 0.46 | - | - | picture | reactor heat louvre over the reactor room |
| G1p | vision slit 0.1 x 0.04 | 1 | 42.6 | 1.35 | 0.00 | - | - | picture | a gun gallery's ember slit between two ports |
| G2p | vision slit 0.1 x 0.04 | 1 | 60.6 | 1.42 | 0.00 | - | - | picture | a gun gallery's ember slit between two ports |
| L1p | running light | 1 | 15.6 | 0.84 | -0.22 | - | - | picture | frost-white running point on the blade's edge |
| L2p | running light | 1 | 21.8 | 1.06 | -0.29 | - | - | picture | frost-white running point on the blade's edge |
| L3p | running light | 1 | 27.3 | 1.18 | -0.33 | - | - | picture | frost-white running point on the blade's edge |
| L4p | running light | 1 | 63.2 | 0.97 | 0.65 | - | - | picture | frost-white running point on the blade's edge |
| L5p | running light | 1 | 73.6 | 0.97 | 0.65 | - | - | picture | frost-white running point on the blade's edge |
| L6p | running light | 1 | 79.1 | 0.95 | 0.64 | - | - | picture | frost-white running point on the blade's edge |
| L7p | running light | 1 | 89.5 | 0.83 | 0.58 | - | - | picture | frost-white running point on the blade's edge |
| Q1s | attitude thruster quad | 1 | 11.4 | -0.58 | -0.31 | - | - | designed | bow attitude thruster on the lower facet |
| Q2s | attitude thruster quad | 1 | 86.0 | -1.12 | 0.41 | - | - | designed | stern attitude thruster on the upper facet |
| V1s | louvre panel 0.5 x 0.2 | 1 | 70.8 | -1.20 | 0.48 | - | - | picture | reactor heat louvre over the reactor room |
| V2s | louvre panel 0.5 x 0.2 | 1 | 76.3 | -1.17 | 0.47 | - | - | picture | reactor heat louvre over the reactor room |
| V3s | louvre panel 0.5 x 0.2 | 1 | 81.9 | -1.13 | 0.46 | - | - | picture | reactor heat louvre over the reactor room |
| G1s | vision slit 0.1 x 0.04 | 1 | 42.6 | -1.35 | 0.00 | - | - | picture | a gun gallery's ember slit between two ports |
| G2s | vision slit 0.1 x 0.04 | 1 | 60.6 | -1.42 | 0.00 | - | - | picture | a gun gallery's ember slit between two ports |
| L1s | running light | 1 | 15.6 | -0.84 | -0.22 | - | - | picture | frost-white running point on the blade's edge |
| L2s | running light | 1 | 21.8 | -1.06 | -0.29 | - | - | picture | frost-white running point on the blade's edge |
| L3s | running light | 1 | 27.3 | -1.18 | -0.33 | - | - | picture | frost-white running point on the blade's edge |
| L4s | running light | 1 | 63.2 | -0.97 | 0.65 | - | - | picture | frost-white running point on the blade's edge |
| L5s | running light | 1 | 73.6 | -0.97 | 0.65 | - | - | picture | frost-white running point on the blade's edge |
| L6s | running light | 1 | 79.1 | -0.95 | 0.64 | - | - | picture | frost-white running point on the blade's edge |
| L7s | running light | 1 | 89.5 | -0.83 | 0.58 | - | - | picture | frost-white running point on the blade's edge |
| H1 | round hatch 0.3 | 1 | 32.5 | 0.62 | 0.77 | - | - | picture | deck hatch |
| H2 | round hatch 0.3 | 1 | 32.5 | -0.62 | 0.77 | - | - | picture | deck hatch |
| H3 | round hatch 0.3 | 1 | 56.3 | 0.66 | 0.79 | - | - | picture | deck hatch |
| H4 | round hatch 0.3 | 1 | 56.3 | -0.66 | 0.79 | - | - | picture | deck hatch |
| H5 | round hatch 0.3 | 1 | 39.7 | 0.36 | -1.09 | - | - | picture | belly hatch on the armour step |
| H6 | round hatch 0.3 | 1 | 39.7 | -0.36 | -1.09 | - | - | picture | belly hatch on the armour step |
| H7 | round hatch 0.3 | 1 | 73.6 | 0.36 | -1.10 | - | - | picture | belly hatch on the armour step |
| H8 | round hatch 0.3 | 1 | 73.6 | -0.36 | -1.10 | - | - | picture | belly hatch on the armour step |
| HB1 | framed deck box 0.5 x 0.3 | 1 | 51.5 | 0.60 | 0.75 | - | - | picture | the hoist head over the gun deck: shells up from the shell rooms |

Totals: 9 gun mounts with 9 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| black iron plate, frost-white markings (paint stage) | 0.0 | 100.0 | whole hull |  |
| ember glow (radiator slats, engine throats, window slits, the lance lens) | 0.0 | 100.0 | the spires, the bells, the slits, the lens |  |
| frost-white running points | 0.0 | 100.0 | the blade's edges |  |
| no rust anywhere, no blue light | 0.0 | 100.0 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the blade | 6.6 to 94.6 | -1.45 to 1.45 | -1.01 to 0.80 | black iron plate | a long faceted blade: crowned deck, big upper facets, the broadside band, lower facets, a flat worked belly; widest (2.9) at the stern third |
| Dorsal ridge (the lance power trunk forward) | 7.3 to 53.5 | -0.34 to 0.34 | 0.30 to 0.98 | darker iron | a raised armoured spine from the lance to the spire block; forward of station 30 percent it is the lance's power trunk (designs.md) |
| Lance capacitor housing, port | 12.8 to 27.3 | 0.42 to 1.07 | 0.21 to 0.65 | darker iron | an armoured capacitor bank on the upper facet, one of the paired cheek housings |
| Lance capacitor housing, starboard | 12.8 to 27.3 | -1.07 to -0.42 | 0.21 to 0.65 | darker iron | an armoured capacitor bank on the upper facet, one of the paired cheek housings |
| Gun deck upper lip, port | 32.5 to 70.5 | 1.25 to 1.57 | 0.21 to 0.38 | darker iron | the armoured shelf over (under) the battery ports; its ends are angled |
| Gun deck lower lip, port | 32.5 to 70.5 | 1.25 to 1.57 | -0.40 to -0.23 | darker iron | the armoured shelf over (under) the battery ports; its ends are angled |
| Gun deck upper lip, starboard | 32.5 to 70.5 | -1.57 to -1.25 | 0.21 to 0.38 | darker iron | the armoured shelf over (under) the battery ports; its ends are angled |
| Gun deck lower lip, starboard | 32.5 to 70.5 | -1.57 to -1.25 | -0.40 to -0.23 | darker iron | the armoured shelf over (under) the battery ports; its ends are angled |
| Spine block (the spire line's base) | 59.4 to 91.2 | -0.40 to 0.40 | 0.65 to 1.09 | darker iron | a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-4) |
| Radiator spire R1 (blade, 0.80 tall) | 64.3 to 68.1 | -0.06 to 0.06 | 1.24 to 1.88 | ember fin slats on iron | one of the five spires of the spire line |
| Radiator spire R2 (raked, 1.02 tall) | 69.3 to 73.0 | -0.06 to 0.06 | 1.24 to 2.10 | ember fin slats on iron | one of the five spires of the spire line |
| Radiator spire R3 (twin, 1.20 tall) | 74.2 to 78.0 | -0.05 to 0.05 | 1.24 to 2.28 | ember fin slats on iron | one of the five spires of the spire line |
| Radiator spire R4 (stepped, 1.00 tall) | 79.2 to 83.0 | -0.06 to 0.06 | 1.24 to 2.08 | ember fin slats on iron | one of the five spires of the spire line |
| Radiator spire R5 (blade, 0.78 tall) | 84.2 to 88.0 | -0.06 to 0.06 | 1.24 to 1.86 | ember fin slats on iron | one of the five spires of the spire line |
| Belly armour step | 22.5 to 87.4 | -0.69 to 0.69 | -1.09 to -0.83 | darker iron | a second forged layer under the gun deck and the reactor |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): bow deck -0.10 (12% to 29%); upper deck 0.36 (31% to 91%); gun deck -0.36 (31% to 73%); main_aft deck -0.36 (74% to 91%).

Bulkhead and frame stations: F0 12.8%, F1 19.0%, F2 25.2%, F3 28.3%, F4 31.1%, F5 42.5%, F6 51.5%, F7 60.4%, F8 69.4%, F9 75.0%, F10 80.5%, F11 86.0%, F12 90.5%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| lance capacitors (machinery) | 12.8 to 28.0 | 0.03 to -0.03 | -0.04 to 0.42 | the Oath lance's capacitor room: the trunk's charge banks behind the emitter |
| bow stores (hold) | 14.2 to 28.0 | 0.03 to -0.03 | -0.60 to -0.15 | bow stores and the bow thrusters' feeds |
| gun gallery p (gallery) | 32.1 to 71.5 | 0.78 to 0.96 | -0.31 to 0.30 | the gun crews' galleries behind the ports, ember-lit: the old manual gun deck (lore 2.5) |
| gun gallery s (gallery) | 32.1 to 71.5 | -0.96 to -0.78 | -0.31 to 0.30 | the gun crews' galleries behind the ports, ember-lit: the old manual gun deck (lore 2.5) |
| shell rooms p (magazine) | 32.8 to 70.8 | 0.50 to 0.74 | -0.30 to 0.05 | the battery shell room inboard of the gun gallery |
| shell rooms s (magazine) | 32.8 to 70.8 | -0.74 to -0.50 | -0.30 to 0.05 | the battery shell room inboard of the gun gallery |
| fire plot (bridge) | 43.2 to 53.5 | -0.45 to 0.45 | -0.31 to 0.30 | the broadside plotting room (no AI: plotted by hand) |
| crew mid (crew) | 54.9 to 71.5 | -0.45 to 0.45 | -0.31 to 0.30 | crew berths between the galleries |
| upper rooms (crew) | 32.1 to 58.4 | 0.03 to -0.03 | 0.40 to 0.62 | the gunners' mess and the chalk wall where the names go up before launch |
| command (bridge) | 59.8 to 65.3 | 0.03 to -0.03 | 0.40 to 0.62 | the command deck under the spine block's slits |
| plenum (machinery) | 66.0 to 89.5 | 0.03 to -0.03 | 0.40 to 0.62 | the heat plenum feeding the spire line |
| reactor (core) | 75.0 to 86.0 | -0.75 to 0.75 | -0.40 to 0.30 | the reactor: its heat goes up through the plenum into the spires (hp_core) |
| coolant p (machinery) | 75.0 to 86.0 | 0.82 to 0.93 | -0.40 to 0.28 | coolant pumps either side of the reactor |
| coolant s (machinery) | 75.0 to 86.0 | -0.93 to -0.82 | -0.40 to 0.28 | coolant pumps either side of the reactor |
| engine room (engroom) | 87.0 to 90.8 | -0.81 to 0.81 | -0.40 to 0.30 | the engine room and the two drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| upper facets and deck | 0.16 | forged plate over the galleries |
| broadside band and lips | 0.20 | the gun deck face, the heaviest belt |
| spearhead | 0.22 | solid forged layers toward the point round the lance |
| belly and armour step | 0.16 |  |
| spine block | 0.14 | it snaps off with the spires |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 29.7 (seam wanders 28.7 to 30.4) | the spearhead tears from the gun deck at its root, the lance and its capacitor room going with it |
| B-2 | 91.9 (seam wanders 91.5 to 92.4) | the engine section tears from the reactor section, behind the spire line |
| B-3 | 32.1 to 72.9 (along) | under the gun deck: the belly plating peels away below the galleries and their shell rooms |
| B-4 | 59.8 to 90.8 (along) | the spire line snaps off as one piece, the spine block tearing along its root |

Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit gun galleries, frames, the reactor, the lance's capacitor room. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 80.5 | 0.00 | -0.25 |  |  |  |
| hp_breach_0 | 15.6 | 0.87 | 0.00 | port | prow | on open side plating |
| hp_breach_1 | 48.7 | -1.25 | -0.45 | stbd | mid | on open side plating |
| hp_breach_2 | 43.2 | 1.34 | 0.15 | port | mid | on open side plating |
| hp_breach_3 | 74.3 | -1.43 | -0.30 | stbd | eng | on open side plating |
| hp_rcs_0 | 11.4 | 0.58 | -0.31 | port |  |  |
| hp_rcs_2 | 86.0 | 1.12 | 0.41 | port |  |  |
| hp_board_0 | 70.8 | 1.45 | 0.00 | port |  |  |
| hp_rcs_1 | 11.4 | -0.58 | -0.31 | stbd |  |  |
| hp_rcs_3 | 86.0 | -1.12 | 0.41 | stbd |  |  |
| hp_board_1 | 70.8 | -1.45 | 0.00 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 335 objects, 62 parts, 1045 close pairs, 344 rays, 9 guns, 0 sensor pairs, 0 turrets swept, 6 cones, 41 apertures, 1 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The bow is one spearhead point carrying the Oath lance in a heavy forged round collar (about a third of the concept's opening): one emitter in the point, a dark bore, a small ember lens deep inside.** designs.md: "the beauty's spearhead reads as a shallow fork around the emitter (build one point, emitter in its face)"; the Board's brief: one emitter set into the bow point, never a big glowing disc.
- **Four battery ports a side in one row at 38 / 47 / 56 / 65 percent, not the pictures' two rows of three.** data.js battery fires 4 shots a volley, one port per shot (designs.md table, the family battery pattern on S8; R241 SPLIT rule); the ports are big with heavy proud collars and ember gallery slits between them (Board rev 1 note).
- **Five spires, not seven, about 70 percent of the table's heights (tallest 1.2 over the spine block, against 1.7), set close in one tight row at 66 to 86 percent, ember in the slats (the shared radiator from issue 1158), so the spire is not a whole lit tower.** designs.md table (5 spires); Ryan, Nov 19 2026 (R331): "can we scale down the giant radiator/orange towers on each ship a bit too?"; the ember shows in the slats, not as a whole lit tower.
- **The paired cheek housings on the upper facets either side of the lance trunk are the lance's capacitor banks.** designs.md chair ruling: the faction's "one heavy pair at the bow" is met in form by the emitter and its paired cheek housings.
- **The two engines are bells on short riveted drums (1.2 across, offsets 0.8), glowing ember, no flame plume.** designs.md table; in game the bells glow ember and the game draws the plume (ships.md 0.2 (5)).
- **No deck turrets: the crowned deck stays clean except the power trunk, one hoist head and four hatches.** data.js penitent has no turret slot (designs.md: "the crowned deck stays clean"; R241: no decorative weapons).
- **The hull is widest at the stern third (2.9, 3.0 over the gun deck lips, at 68 percent); with the battery ports, their proud collars and short barrels the outline reaches 4.15 at the guns (the barrels kept short so the ports read as deep round openings, as the concept draws them).** designs.md: beam 3.0 at about 68 percent; factions.md: widest at the stern third.
- **A raised plated dorsal ridge runs from the lance back to the spine block, tapering low before the command slits.** the concept's strongest line (the Board's rev 1 note); it is the lance's power trunk, and it ends low so the bridge slits keep their view.
- **Attitude thrusters, deck and belly hatches, a hoist head, heat louvres, ember slits, frost running points and a belly armour step added.** a ship in space needs thrusters and access; the reactor needs louvres; the pictures show no underside; every part has a job (R221).
- **Transverse breaks at the spearhead root (30 percent) and behind the spire line (B-2); the gun deck peel and the spire line peel sit in the one compartment between.** factions.md "How it breaks" (lengthwise between deck rows, the spire line as one piece); the build contract keeps every long seam inside one transverse compartment, and the spire line overlaps the gun deck stations on this hull.
- **B-3 peels the belly plating below the gun deck, the liner is relieved along that seam and at both joints, frames between the breaks stop above it, and the keel deck and ballast tanks are gone.** the first peel sat on the sloped lower hull and tore through the liner and the rooms behind it, so the death check found 411 inside faces on the outer hull; the S8 liner relief and a clear belly bring that to 0.
- **The battery ports are S8's heavy broadside mount (forged surround, ball mantlet, a real barrel) scaled to the hull (14.5 / 27, then 1.2 times on Ryan's "slightly bigger").** Ryan, Nov 20 2026: the concept's open tube ports read as torpedo tubes in game; he picked S8's gun mounts "sized appropriately for the ship size", which also ties the Vigil to S8's family.

## Designed here, not shown in the picture

- The belly is designed here; the concept shows no underside.
- Frost-white markings and the half-sun crest are paint (the Sunward stack), not modelled.
- Q1p (attitude thruster quad): bow attitude thruster on the lower facet.
- Q2p (attitude thruster quad): stern attitude thruster on the upper facet.
- Q1s (attitude thruster quad): bow attitude thruster on the lower facet.
- Q2s (attitude thruster quad): stern attitude thruster on the upper facet.
