# voidsworn_S11: Harrow-class destroyer (Sunward Crusade), build sheet

Sunward Crusade (voidsworn) | class Destroyer | version 1 (first sheet), 2026-11-20 | blockout: rendered in the issue 1414 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py voidsworn_S11 <out> render` rebuilds it from this file

**Length 9.5 world units** (data.js harrow (cls 'Destroyer'); length from godot/render/hull_table.gd CLS_LEN['Destroyer'] = 9.5 (drawn x SHIP_K 1.6 = 15.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | torp | F | 1 | T1 (2) |
| 1 | turret | T | 2 | G1 (1), G2 (1) |

| Check | Value |
|---|---|
| model length | 9.488 |
| length side | 9.512 |
| length top | 9.512 |
| length disagreement percent | 0.0 |
| beam top | 2.212 |
| beam bow | 2.212 |
| beam disagreement percent | 0.0 |
| height side | 2.05 |
| height bow | 2.05 |
| height disagreement percent | 0.0 |
| widest at station percent | 48.3 |
| hull beam | 2.1 |
| hull depth | 0.89 |
| L to B hull | 4.52 |
| L to H hull | 10.67 |
| prow overhang | 0.0 |
| outline iou percent | 89.2 |
| mass outline iou percent | 89.4 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| T1 | twin Cinder torpedo tubes in deck cowls (one launcher, fixed forward) | 2 tubes | 22.4 | 0.00 | 0.47 | forward | F torp | picture | the destroyer's salvo (torp F, 1 shot: it leaves either tube in turn); the ship turns to aim it |
| M1p | heat-vent slit panel 0.7 x 0.3, four long lit slits | 1 | 36.9 | 0.76 | 0.26 | - | - | picture | the torpedo magazine sheds its reload heat here (designs.md: ember heat-vent slits) |
| M1s | heat-vent slit panel 0.7 x 0.3, four long lit slits | 1 | 36.9 | -0.76 | 0.26 | - | - | picture | the torpedo magazine sheds its reload heat here (designs.md: ember heat-vent slits) |
| U1p | band louvre 0.2 x 0.08 | 1 | 29.0 | 0.89 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U2p | band louvre 0.2 x 0.08 | 1 | 38.5 | 1.02 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U3p | band louvre 0.2 x 0.08 | 1 | 52.2 | 1.03 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U4p | band louvre 0.2 x 0.08 | 1 | 66.9 | 0.90 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U5p | band louvre 0.2 x 0.08 | 1 | 77.5 | 0.89 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U1s | band louvre 0.2 x 0.08 | 1 | 29.0 | -0.89 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U2s | band louvre 0.2 x 0.08 | 1 | 38.5 | -1.02 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U3s | band louvre 0.2 x 0.08 | 1 | 52.2 | -1.03 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U4s | band louvre 0.2 x 0.08 | 1 | 66.9 | -0.90 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U5s | band louvre 0.2 x 0.08 | 1 | 77.5 | -0.89 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| G1 | sear turret, single turret | 1 barrel | 46.1 | 0.62 | 0.41 | 35 deg off the bow to port, +4 elev | T turret | picture | port sear turret; the pair is the one turret slot (2 shots: one a mount, both fire every volley) |
| G2 | sear turret, single turret | 1 barrel | 46.1 | -0.62 | 0.41 | 35 deg off the bow to starboard, +4 elev | T turret | picture | starboard sear turret; the pair is the one turret slot (2 shots: one a mount, both fire every volley) |
| W1 | vision slit 0.065 x 0.028 | 1 | 61.1 | -0.10 | 0.47 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W2 | vision slit 0.065 x 0.028 | 1 | 61.1 | 0.00 | 0.47 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W3 | vision slit 0.065 x 0.028 | 1 | 61.1 | 0.10 | 0.47 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| R1 | radiator spire, 0.66 tall, profile raked | 1 | 66.1 | 0.00 | 0.57 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| R2 | radiator spire, 0.85 tall, profile stepped | 1 | 73.1 | 0.00 | 0.57 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| R3 | radiator spire, 0.76 tall, profile blade | 1 | 80.1 | 0.00 | 0.57 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| R4 | radiator spire, 0.58 tall, profile twin | 1 | 87.2 | 0.00 | 0.57 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| E1 | engine, bell 0.9 across | 1 | 99.8 | 0.55 | -0.05 | exhaust aft | - | picture | port main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| E2 | engine, bell 0.9 across | 1 | 99.8 | -0.55 | -0.05 | exhaust aft | - | picture | starboard main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| Q1p | attitude thruster quad | 1 | 26.9 | 0.59 | -0.30 | - | - | designed | bow attitude thruster on the lower facet |
| Q2p | attitude thruster quad | 1 | 84.8 | 0.79 | 0.18 | - | - | designed | stern attitude thruster on the upper facet |
| V1p | louvre panel 0.32 x 0.13 | 1 | 70.1 | 0.69 | 0.23 | - | - | designed | reactor heat louvre over the reactor room |
| V2p | louvre panel 0.32 x 0.13 | 1 | 77.5 | 0.69 | 0.23 | - | - | designed | reactor heat louvre over the reactor room |
| L1p | running light | 1 | 25.3 | 0.74 | -0.15 | - | - | designed | frost-white running point on the knuckle line |
| L2p | running light | 1 | 34.3 | 0.90 | -0.18 | - | - | designed | frost-white running point on the knuckle line |
| L3p | running light | 1 | 43.7 | 0.98 | -0.19 | - | - | designed | frost-white running point on the knuckle line |
| L4p | running light | 1 | 54.3 | 0.66 | 0.30 | - | - | designed | frost-white running point on the deck edge |
| L5p | running light | 1 | 66.9 | 0.59 | 0.30 | - | - | designed | frost-white running point on the deck edge |
| L6p | running light | 1 | 82.7 | 0.58 | 0.29 | - | - | designed | frost-white running point on the deck edge |
| Q1s | attitude thruster quad | 1 | 26.9 | -0.59 | -0.30 | - | - | designed | bow attitude thruster on the lower facet |
| Q2s | attitude thruster quad | 1 | 84.8 | -0.79 | 0.18 | - | - | designed | stern attitude thruster on the upper facet |
| V1s | louvre panel 0.32 x 0.13 | 1 | 70.1 | -0.69 | 0.23 | - | - | designed | reactor heat louvre over the reactor room |
| V2s | louvre panel 0.32 x 0.13 | 1 | 77.5 | -0.69 | 0.23 | - | - | designed | reactor heat louvre over the reactor room |
| L1s | running light | 1 | 25.3 | -0.74 | -0.15 | - | - | designed | frost-white running point on the knuckle line |
| L2s | running light | 1 | 34.3 | -0.90 | -0.18 | - | - | designed | frost-white running point on the knuckle line |
| L3s | running light | 1 | 43.7 | -0.98 | -0.19 | - | - | designed | frost-white running point on the knuckle line |
| L4s | running light | 1 | 54.3 | -0.66 | 0.30 | - | - | designed | frost-white running point on the deck edge |
| L5s | running light | 1 | 66.9 | -0.59 | 0.30 | - | - | designed | frost-white running point on the deck edge |
| L6s | running light | 1 | 82.7 | -0.58 | 0.29 | - | - | designed | frost-white running point on the deck edge |
| H1 | round hatch 0.13 | 1 | 40.1 | 0.22 | 0.40 | - | - | designed | deck hatch over the crew deck |
| H2 | round hatch 0.13 | 1 | 40.1 | -0.22 | 0.40 | - | - | designed | deck hatch over the crew deck |
| H3 | round hatch 0.13 | 1 | 53.2 | 0.22 | 0.41 | - | - | designed | deck hatch over the crew deck |
| H4 | round hatch 0.13 | 1 | 53.2 | -0.22 | 0.41 | - | - | designed | deck hatch over the crew deck |
| H5 | round hatch 0.14 | 1 | 39.5 | 0.22 | -0.53 | - | - | designed | belly hatch on the armour step: torpedo stores come aboard here |
| H6 | round hatch 0.14 | 1 | 39.5 | -0.22 | -0.53 | - | - | designed | belly hatch on the armour step: torpedo stores come aboard here |

Totals: 2 gun mounts with 2 barrels; 2 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| black iron plate, frost-white markings (paint stage) | 0.0 | 100.0 | whole hull |  |
| ember glow (spire slats, engine throats, window slits, the turrets' lenses, the torpedoes' fuse bands) | 18.4 | 100.0 | the spires, the bells, the slits |  |
| frost-white running points | 23.7 | 82.7 | the knuckle forward, the deck edges aft |  |
| no rust anywhere, no blue light | 0.0 | 100.0 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the blade | 0.0 to 94.9 | -1.05 to 1.05 | -0.48 to 0.41 | black iron plate | a faceted blade: crowned deck, big upper facets, the plated band, lower facets, a flat worked belly; the bow one long leaf taper, widest (2.1) over the magazine section |
| Bow ridge | 2.6 to 21.0 | -0.09 to 0.09 | 0.04 to 0.31 | darker iron | the spearhead's raised centre ridge (a forged fuller) from the point back to the power trunk's head |
| Band upper lip, port | 20.6 to 90.6 | 0.64 to 1.09 | 0.07 to 0.19 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Band lower lip, port | 20.6 to 90.6 | 0.64 to 1.09 | -0.18 to -0.08 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Band upper lip, starboard | 20.6 to 90.6 | -1.09 to -0.64 | 0.07 to 0.19 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Band lower lip, starboard | 20.6 to 90.6 | -1.09 to -0.64 | -0.18 to -0.08 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Turret tub, port | 43.9 to 48.3 | 0.40 to 0.84 | 0.11 to 0.41 | darker iron | an octagonal forged tub at the deck edge, its skirt running down onto the upper facet |
| Turret tub, starboard | 43.9 to 48.3 | -0.84 to -0.40 | 0.11 to 0.41 | darker iron | an octagonal forged tub at the deck edge, its skirt running down onto the upper facet |
| Spine block (the spire line's base) | 61.1 to 91.7 | -0.24 to 0.24 | 0.35 to 0.58 | darker iron | a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-3) |
| Radiator spire R1 (raked, 0.66 tall) | 64.9 to 67.3 | -0.06 to 0.06 | 0.72 to 1.23 | ember fin slats on iron | one of the four spires of the spire line |
| Radiator spire R2 (stepped, 0.85 tall) | 71.8 to 74.5 | -0.06 to 0.06 | 0.72 to 1.42 | ember fin slats on iron | one of the four spires of the spire line |
| Radiator spire R3 (blade, 0.76 tall) | 78.9 to 81.3 | -0.06 to 0.06 | 0.72 to 1.33 | ember fin slats on iron | one of the four spires of the spire line |
| Radiator spire R4 (twin, 0.58 tall) | 86.0 to 88.3 | -0.05 to 0.05 | 0.72 to 1.15 | ember fin slats on iron | one of the four spires of the spire line |
| Belly armour step | 21.6 to 85.9 | -0.50 to 0.50 | -0.53 to -0.33 | darker iron | a second forged layer under the magazine and the reactor |
| Dorsal power trunk | 21.1 to 60.1 | -0.07 to 0.07 | 0.26 to 0.46 | darker iron | armoured conduits from the reactor forward over the magazine to the tube room (the concept's centre stripe) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck 0.00 (8% to 16%); main deck 0.00 (20% to 56%); lower deck -0.27 (21% to 56%); main deck 0.00 (60% to 93%); lower deck -0.27 (60% to 93%).

Bulkhead and frame stations: F0 7.9%, F1 13.2%, F2 20.6%, F3 25.8%, F4 32.1%, F5 38.5%, F6 44.8%, F7 51.1%, F8 56.4%, F9 60.6%, F10 68.0%, F11 75.4%, F12 82.7%, F13 89.1%, F14 93.5%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| bow stores (hold) | 8.4 to 15.3 | 0.01 to -0.01 | -0.14 to 0.12 | bow stores and the bow ridge's sensor feeds |
| tube room (magazine) | 20.0 to 26.9 | 0.01 to -0.01 | 0.03 to 0.27 | the tube room: the loaders run the next pair of Cinder torpedoes into the tubes by hand |
| torpedo magazine (magazine) | 27.4 to 40.1 | 0.01 to -0.01 | 0.03 to 0.27 | the torpedo magazine: racks of armoured Cinder bodies on rails, the reload the vents breathe for |
| crew deck (crew) | 40.6 to 55.9 | -0.10 to 0.10 | 0.03 to 0.28 | the crew deck: berths and the mess, the chalk wall where the names go up before launch |
| turret magazine p (magazine) | 42.2 to 50.1 | 0.55 to 0.26 | 0.03 to 0.27 | the sear turrets' charge rooms, under the tubs |
| turret magazine s (magazine) | 42.2 to 50.1 | -0.26 to -0.55 | 0.03 to 0.27 | the sear turrets' charge rooms, under the tubs |
| ballast fwd (machinery) | 21.6 to 55.9 | 0.01 to -0.01 | -0.40 to -0.29 | trim tanks and pumps under the magazine and the crew deck |
| command (bridge) | 60.6 to 63.8 | -0.16 to 0.16 | 0.03 to 0.28 | the command deck under the spine block's slits |
| reactor (core) | 64.3 to 80.6 | 0.01 to -0.01 | -0.40 to 0.28 | the reactor: its heat goes up through the spine block into the spires (hp_core) |
| coolant p (machinery) | 64.3 to 80.6 | 0.46 to 0.05 | -0.25 to 0.28 | coolant pumps and heat exchangers either side of the reactor |
| coolant s (machinery) | 64.3 to 80.6 | -0.05 to -0.46 | -0.25 to 0.28 | coolant pumps and heat exchangers either side of the reactor |
| engine room (engroom) | 81.7 to 92.7 | 0.01 to -0.01 | -0.38 to 0.27 | the engine room and the two drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| upper facets and deck | 0.08 | forged plate over the magazine and the crew deck |
| band and lips | 0.09 | the plated band, the hull's belt |
| bow point and tube cowls | 0.10 | solid forged layers toward the point; the tube cowls are the thickest plate |
| belly and armour step | 0.08 |  |
| spine block | 0.07 | it snaps off with the spires |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 58.0 (seam wanders 53.8 to 58.0) | the gun and magazine section tears from the reactor section, between the turret tubs and the spine block's face |
| B-2 | 17.9 to 57.4 (along) | along the band: the lower hull peels away under the magazine and the crew deck |
| B-4 | 16.9 (seam wanders 16.9 to 16.9) | the bow point snaps off whole just ahead of the tube cowls (designs.md: the bow tube block separates at the forward knuckle), so the tubes stay with the magazine section |
| B-3 | 61.1 to 91.2 (along) | the spire line snaps off as one piece, the spine block tearing along its root |

Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit crew spaces, frames, the tube room and the torpedo magazine, the reactor and its machinery. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 72.2 | 0.00 | -0.10 |  |  |  |
| hp_breach_0 | 20.6 | 0.66 | 0.07 | port | prow | on the hull side by the broadside band, clear of the louvres, lamps and thrusters |
| hp_breach_1 | 61.1 | -0.92 | 0.07 | stbd | mid | on the hull side by the broadside band, clear of the louvres, lamps and thrusters |
| hp_breach_2 | 87.5 | 0.88 | 0.07 | port | eng | on the hull side by the broadside band, clear of the louvres, lamps and thrusters |
| hp_rcs_0 | 26.9 | 0.59 | -0.30 | port |  |  |
| hp_rcs_2 | 84.8 | 0.79 | 0.18 | port |  |  |
| hp_board_0 | 63.8 | 0.90 | 0.01 | port |  |  |
| hp_rcs_1 | 26.9 | -0.59 | -0.30 | stbd |  |  |
| hp_rcs_3 | 84.8 | -0.79 | 0.18 | stbd |  |  |
| hp_board_1 | 63.8 | -0.90 | 0.01 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 254 objects, 50 parts, 420 close pairs, 307 rays, 2 guns, 0 sensor pairs, 2 turrets swept, 6 cones, 39 apertures, 2 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Four radiator spires, not the round 2 pictures' five, at 0.66, 0.85, 0.76 and 0.58 over the spine block (tallest second from the front).** designs.md's table (4 spires) outranks the picture; the final spire table (Board, Nov 19 15:30 UTC, after R331) gives the Harrow tallest 0.85; Ryan took round 2 with 4 small spires (R369).
- **The spires' fins stand apart, so the ember shows as lit slats with dark iron between them, not as a whole lit tower.** R331: the ember shows in the slats (the shared radiator glow='slats', as S8, S9 and S10).
- **The twin torpedo tubes sit in raised armoured cowls on the deck either side of the centreline (station 22 percent, 0.36 off the centreline), each a rounded teardrop fairing sweeping back into the deck, a broad riveted mouth ring, a forged collar, a deep bore and the next torpedo's nose seated inside; the bow is one long leaf taper with no step.** the round 2 pictures Ryan took (R369) draw the tubes in deck cowls on a smooth taper; designs.md's cheek-plate tubes at station 10 percent would sit where the point is too narrow for two bores, and the cowls keep the firing lanes clear over the falling bow (R241).
- **The widest hull (2.1) sits over the magazine section at 40 to 50 percent, then about 1.7 over the stern third.** the round 2 top view measures its widest at 46 percent; designs.md calls this the widened magazine section (20 to 45 percent); its line "widest at about 70 percent" is the family default the picture overrides.
- **The magazine's ember heat-vent slits are one long panel of four lit slits on each upper facet between the tube cowls and the turret pair, as the round 2 pictures draw them.** designs.md: the reload read; R221: they vent the magazine below.
- **One sear turret pair (two single-emitter tubs at the deck edges, station 46 percent).** designs.md's table and data.js harrow carry one turret slot (2 shots: one a mount).
- **The broadside band is plated and louvred, with no ports.** designs.md: no broadside slot in data, so no ports (R241: no decorative guns).
- **Two ember bells 0.8 across at plus and minus 0.55 on riveted drums; no flame plumes.** designs.md's table; the game draws the plume (round 2 pictures draw none at rest).
- **The concept's centre stripe is the dorsal power trunk, banded, from the reactor forward over the magazine to the tube room.** the stripe needs a job (R221): it feeds the turrets and the tube room from the reactor.
- **Attitude thrusters, deck and belly hatches, reactor louvres, frost running points, a belly armour step added.** a ship in space needs thrusters and access; the reactor needs louvres; the concept shows no underside; every part has a job (R221).

## Designed here, not shown in the picture

- The belly is designed here; the concept shows no underside.
- Frost-white markings (one thin stripe and a small sigil, round 2) are paint (the Sunward stack, stage 5), not modelled.
- Q1p (attitude thruster quad): bow attitude thruster on the lower facet.
- Q2p (attitude thruster quad): stern attitude thruster on the upper facet.
- V1p (louvre panel 0.32 x 0.13): reactor heat louvre over the reactor room.
- V2p (louvre panel 0.32 x 0.13): reactor heat louvre over the reactor room.
- L1p (running light): frost-white running point on the knuckle line.
- L2p (running light): frost-white running point on the knuckle line.
- L3p (running light): frost-white running point on the knuckle line.
- L4p (running light): frost-white running point on the deck edge.
- L5p (running light): frost-white running point on the deck edge.
- L6p (running light): frost-white running point on the deck edge.
- Q1s (attitude thruster quad): bow attitude thruster on the lower facet.
- Q2s (attitude thruster quad): stern attitude thruster on the upper facet.
- V1s (louvre panel 0.32 x 0.13): reactor heat louvre over the reactor room.
- V2s (louvre panel 0.32 x 0.13): reactor heat louvre over the reactor room.
- L1s (running light): frost-white running point on the knuckle line.
- L2s (running light): frost-white running point on the knuckle line.
- L3s (running light): frost-white running point on the knuckle line.
- L4s (running light): frost-white running point on the deck edge.
- L5s (running light): frost-white running point on the deck edge.
- L6s (running light): frost-white running point on the deck edge.
- H1 (round hatch 0.13): deck hatch over the crew deck.
- H2 (round hatch 0.13): deck hatch over the crew deck.
- H3 (round hatch 0.13): deck hatch over the crew deck.
- H4 (round hatch 0.13): deck hatch over the crew deck.
- H5 (round hatch 0.14): belly hatch on the armour step: torpedo stores come aboard here.
- H6 (round hatch 0.14): belly hatch on the armour step: torpedo stores come aboard here.
