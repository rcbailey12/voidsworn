# voidsworn_S9: Warden-class frigate (Sunward Crusade), build sheet

Sunward Crusade (voidsworn) | class Frigate | version 1 (first sheet), 2026-11-19 | blockout: rendered in the issue 1156 cloud copy (Blender 5.3 as the bpy module, Cycles CPU); `build.py voidsworn_S9 <out> render` rebuilds it from this file

**Length 6.5 world units** (data.js warden (cls 'Frigate'); length from godot/render/hull_table.gd CLS_LEN['Frigate'] = 6.5 (drawn x SHIP_K 1.6 = 10.4 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | autocannon | F | 3 | A1 (3) |
| 1 | flak | T | 3 | F1 (2), F2 (2) |

| Check | Value |
|---|---|
| model length | 6.5 |
| length side | 6.525 |
| length top | 6.525 |
| length disagreement percent | 0.0 |
| beam top | 1.5 |
| beam bow | 1.5 |
| beam disagreement percent | 0.0 |
| height side | 1.625 |
| height bow | 1.625 |
| height disagreement percent | 0.0 |
| widest at station percent | 77.4 |
| hull beam | 1.36 |
| hull depth | 0.74 |
| L to B hull | 4.78 |
| L to H hull | 8.78 |
| prow overhang | 0.0 |
| outline iou percent | 85.0 |
| mass outline iou percent | 87.3 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| A1 | sear repeater, three-barrel rotary casemate (fixed forward) | 3 barrels | 14.0 | 0.00 | 0.17 | forward | F autocannon | picture | the frigate's bow gun (autocannon F, 3 shots: all three barrels fire every volley); the frigate turns to bring it to bear |
| U1p | band louvre 0.15 x 0.06 | 1 | 33.8 | 0.58 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U2p | band louvre 0.15 x 0.06 | 1 | 44.6 | 0.63 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U3p | band louvre 0.15 x 0.06 | 1 | 55.4 | 0.67 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U4p | band louvre 0.15 x 0.06 | 1 | 78.5 | 0.72 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U1s | band louvre 0.15 x 0.06 | 1 | 33.8 | -0.58 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U2s | band louvre 0.15 x 0.06 | 1 | 44.6 | -0.63 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U3s | band louvre 0.15 x 0.06 | 1 | 55.4 | -0.67 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| U4s | band louvre 0.15 x 0.06 | 1 | 78.5 | -0.72 | 0.01 | - | - | picture | a heat louvre in the plated band (the gallery spaces behind it breathe out here) |
| F1 | spark flak, twin turret | 2 barrels | 60.0 | 0.44 | 0.34 | 30 deg off the bow to port, +12 elev | T flak | picture | port spark flak twin; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley) |
| F2 | spark flak, twin turret | 2 barrels | 60.0 | -0.44 | 0.34 | 30 deg off the bow to starboard, +12 elev | T flak | picture | starboard spark flak twin; the pair is the one flak slot (3 shots over 4 barrels: both fire every volley) |
| W1 | vision slit 0.05 x 0.02 | 1 | 56.9 | -0.07 | 0.38 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W2 | vision slit 0.05 x 0.02 | 1 | 56.9 | 0.00 | 0.38 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| W3 | vision slit 0.05 x 0.02 | 1 | 56.9 | 0.07 | 0.38 | - | - | picture | command deck window, ember-lit, in the spine block's face |
| R1 | radiator spire, 0.47 tall, profile raked | 1 | 68.0 | 0.00 | 0.46 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| R2 | radiator spire, 0.65 tall, profile stepped | 1 | 76.0 | 0.00 | 0.46 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| R3 | radiator spire, 0.52 tall, profile blade | 1 | 84.0 | 0.00 | 0.46 | - | - | picture | sheds the reactor's heat: a stack of glowing radiator fins, spaced so the dark iron core shows between every pair |
| E1 | engine, bell 0.6 across | 1 | 99.8 | 0.40 | -0.05 | exhaust aft | - | picture | port main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| E2 | engine, bell 0.6 across | 1 | 99.8 | -0.40 | -0.05 | exhaust aft | - | picture | starboard main engine: a riveted drum deep-set in the stern, a deep bell, ember lining and plug |
| Q1p | attitude thruster quad | 1 | 23.1 | 0.36 | 0.14 | - | - | designed | bow attitude thruster on the upper facet |
| Q2p | attitude thruster quad | 1 | 83.8 | 0.57 | 0.17 | - | - | designed | stern attitude thruster on the upper facet |
| V1p | louvre panel 0.24 x 0.10 | 1 | 70.8 | 0.56 | 0.19 | - | - | designed | reactor heat louvre over the reactor room |
| V2p | louvre panel 0.24 x 0.10 | 1 | 77.7 | 0.56 | 0.19 | - | - | designed | reactor heat louvre over the reactor room |
| L1p | running light | 1 | 14.6 | 0.30 | -0.11 | - | - | designed | frost-white running point on the knuckle line |
| L2p | running light | 1 | 30.0 | 0.49 | -0.13 | - | - | designed | frost-white running point on the knuckle line |
| L3p | running light | 1 | 49.2 | 0.42 | 0.26 | - | - | designed | frost-white running point on the deck edge |
| L4p | running light | 1 | 66.2 | 0.46 | 0.25 | - | - | designed | frost-white running point on the deck edge |
| L5p | running light | 1 | 84.6 | 0.46 | 0.25 | - | - | designed | frost-white running point on the deck edge |
| Q1s | attitude thruster quad | 1 | 23.1 | -0.36 | 0.14 | - | - | designed | bow attitude thruster on the upper facet |
| Q2s | attitude thruster quad | 1 | 83.8 | -0.57 | 0.17 | - | - | designed | stern attitude thruster on the upper facet |
| V1s | louvre panel 0.24 x 0.10 | 1 | 70.8 | -0.56 | 0.19 | - | - | designed | reactor heat louvre over the reactor room |
| V2s | louvre panel 0.24 x 0.10 | 1 | 77.7 | -0.56 | 0.19 | - | - | designed | reactor heat louvre over the reactor room |
| L1s | running light | 1 | 14.6 | -0.30 | -0.11 | - | - | designed | frost-white running point on the knuckle line |
| L2s | running light | 1 | 30.0 | -0.49 | -0.13 | - | - | designed | frost-white running point on the knuckle line |
| L3s | running light | 1 | 49.2 | -0.42 | 0.26 | - | - | designed | frost-white running point on the deck edge |
| L4s | running light | 1 | 66.2 | -0.46 | 0.25 | - | - | designed | frost-white running point on the deck edge |
| L5s | running light | 1 | 84.6 | -0.46 | 0.25 | - | - | designed | frost-white running point on the deck edge |
| H1 | round hatch 0.1 | 1 | 30.8 | 0.16 | 0.29 | - | - | designed | deck hatch over the crew deck |
| H2 | round hatch 0.1 | 1 | 30.8 | -0.16 | 0.29 | - | - | designed | deck hatch over the crew deck |
| H3 | round hatch 0.11 | 1 | 42.3 | 0.15 | -0.44 | - | - | designed | belly hatch on the armour step |
| H4 | round hatch 0.11 | 1 | 42.3 | -0.15 | -0.44 | - | - | designed | belly hatch on the armour step |

Totals: 3 gun mounts with 7 barrels; 0 launcher tubes; 2 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| black iron plate, frost-white markings (paint stage) | 0.0 | 100.0 | whole hull |  |
| ember glow (spire slats, engine throats, window slits, the repeater's lenses) | 10.0 | 100.0 | the spires, the bells, the slits |  |
| frost-white running points | 14.6 | 86.9 | the knuckle forward, the deck edges aft |  |
| no rust anywhere, no blue light | 0.0 | 100.0 | factions.md Never |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the blade | 0.0 to 94.9 | -0.68 to 0.68 | -0.41 to 0.33 | black iron plate | a narrow faceted blade: crowned deck, big upper facets, the plated band, lower facets, a flat worked belly; widest (1.36) at the stern third |
| Bow ridge | 2.6 to 9.7 | -0.08 to 0.08 | 0.03 to 0.16 | darker iron | the spearhead's raised centre ridge (a forged fuller) from the point back to the casemate's glacis |
| Bow cheek plates, port | 4.6 to 26.2 | 0.06 to 0.43 | 0.01 to 0.20 | black iron | a forged layer along the upper facet, the spearhead's bevel |
| Bow cheek plates, starboard | 4.6 to 26.2 | -0.43 to -0.06 | 0.01 to 0.20 | black iron | a forged layer along the upper facet, the spearhead's bevel |
| Band upper lip, port | 26.9 to 85.7 | 0.47 to 0.72 | 0.08 to 0.15 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Band lower lip, port | 26.9 to 85.7 | 0.47 to 0.72 | -0.13 to -0.07 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Band upper lip, starboard | 26.9 to 85.7 | -0.72 to -0.47 | 0.08 to 0.15 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Band lower lip, starboard | 26.9 to 85.7 | -0.72 to -0.47 | -0.13 to -0.07 | darker iron | the armoured shelf over (under) the plated band; its ends are angled |
| Flak tub, port | 57.9 to 62.1 | 0.30 to 0.58 | 0.10 to 0.34 | darker iron | an octagonal forged tub at the deck edge, its skirt running down onto the upper facet |
| Flak tub, starboard | 57.9 to 62.1 | -0.58 to -0.30 | 0.10 to 0.34 | darker iron | an octagonal forged tub at the deck edge, its skirt running down onto the upper facet |
| Spine block (the spire line's base) | 56.9 to 90.0 | -0.17 to 0.17 | 0.29 to 0.46 | darker iron | a forged block along the centreline aft; the spires stand on it, and it snaps off with them (B-3) |
| Radiator spire R1 (raked, 0.47 tall) | 66.7 to 69.3 | -0.04 to 0.04 | 0.57 to 0.93 | ember fin slats on iron | one of the three spires of the spire line |
| Radiator spire R2 (stepped, 0.65 tall) | 74.5 to 77.5 | -0.04 to 0.04 | 0.57 to 1.11 | ember fin slats on iron | one of the three spires of the spire line |
| Radiator spire R3 (blade, 0.52 tall) | 82.7 to 85.3 | -0.04 to 0.04 | 0.57 to 0.98 | ember fin slats on iron | one of the three spires of the spire line |
| Belly armour step | 20.8 to 83.8 | -0.32 to 0.32 | -0.44 to -0.31 | darker iron | a second forged layer under the magazines and the reactor |
| Dorsal power trunk | 20.0 to 53.1 | -0.05 to 0.05 | 0.22 to 0.37 | darker iron | armoured conduits from the reactor to the repeater (the concept's long centre rail) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck 0.00 (12% to 23%); main deck 0.00 (26% to 55%); lower deck -0.20 (26% to 55%); main deck 0.00 (65% to 94%); lower deck -0.22 (65% to 94%).

Bulkhead and frame stations: F0 10.0%, F1 16.2%, F2 27.2%, F3 31.5%, F4 39.2%, F5 46.9%, F6 53.8%, F7 65.4%, F8 72.3%, F9 80.0%, F10 87.7%, F11 93.8%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| repeater magazine (magazine) | 13.1 to 19.2 | -0.05 to 0.05 | 0.03 to 0.07 | the Sear repeater's magazine and feed, under the casemate |
| bow stores (hold) | 19.2 to 23.1 | 0.01 to -0.01 | -0.25 to -0.18 | bow stores and the bow thrusters' feeds |
| crew deck (crew) | 26.3 to 41.5 | -0.19 to 0.19 | 0.03 to 0.16 | the crew deck: berths and the mess, the chalk wall where the names go up before launch |
| fire plot (bridge) | 43.1 to 53.8 | -0.26 to 0.26 | 0.03 to 0.20 | the plotting room (no AI: plotted by hand) |
| flak magazine p (magazine) | 48.5 to 54.6 | 0.30 to 0.30 | 0.03 to 0.20 | the spark flak magazines, under the tubs |
| flak magazine s (magazine) | 48.5 to 54.6 | -0.30 to -0.30 | 0.03 to 0.20 | the spark flak magazines, under the tubs |
| ballast fwd (machinery) | 28.5 to 54.6 | -0.21 to 0.21 | -0.29 to -0.19 | trim tanks and pumps under the crew deck |
| command (bridge) | 64.6 to 66.2 | -0.30 to 0.30 | 0.03 to 0.20 | the command deck under the spine block's slits |
| reactor (core) | 66.9 to 83.8 | 0.01 to -0.01 | -0.33 to 0.20 | the reactor: its heat goes up through the spine block into the spires (hp_core) |
| coolant p (machinery) | 66.9 to 83.8 | 0.36 to 0.33 | -0.20 to 0.20 | coolant pumps and heat exchangers either side of the reactor |
| coolant s (machinery) | 66.9 to 83.8 | -0.33 to -0.36 | -0.20 to 0.20 | coolant pumps and heat exchangers either side of the reactor |
| engine room (engroom) | 85.4 to 92.3 | -0.29 to 0.29 | -0.27 to 0.19 | the engine room and the two drives' feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| upper facets and deck | 0.06 | forged plate over the crew deck and the magazines |
| band and lips | 0.07 | the plated band, the hull's belt |
| spearhead | 0.08 | solid forged layers toward the point |
| belly and armour step | 0.06 |  |
| spine block | 0.05 | it snaps off with the spires |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 56.2 (seam wanders 56.2 to 63.8) | the bow and gun section tears from the reactor section: aft of the flak tubs at the flanks, ahead of the spine block on the centreline |
| B-2 | 26.2 to 55.4 (along) | along the band: the lower hull peels away under the crew deck, the magazines and the stores |
| B-4 | 24.8 (seam wanders 24.8 to 24.8) | the spearhead snaps off whole at the casemate's back, so the peel along the band (B-2) stays aft of it, where the band is tall enough for its torn edge |
| B-3 | 56.9 to 89.7 (along) | the spire line snaps off as one piece, the spine block tearing along its root |

Full interiors throughout the hull (R215), hidden until a piece breaks: iron decks, ember-lit crew spaces, frames, the repeater magazine, the reactor and its machinery. Sunward breaks along the gun decks (factions.md); deaths blow it apart unevenly, a ragged bite where the reactor goes (R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 75.4 | 0.00 | -0.08 |  |  |  |
| hp_breach_0 | 26.6 | 0.49 | 0.01 | port | prow | on the hull side by the broadside band, clear of the louvres, lamps and thrusters |
| hp_breach_1 | 73.8 | -0.68 | -0.06 | stbd | eng | on the hull side by the broadside band, clear of the louvres, lamps and thrusters |
| hp_rcs_0 | 23.1 | 0.36 | 0.14 | port |  |  |
| hp_rcs_2 | 83.8 | 0.57 | 0.17 | port |  |  |
| hp_board_0 | 64.6 | 0.66 | 0.01 | port |  |  |
| hp_rcs_1 | 23.1 | -0.36 | 0.14 | stbd |  |  |
| hp_rcs_3 | 83.8 | -0.57 | 0.17 | stbd |  |  |
| hp_board_1 | 64.6 | -0.66 | 0.01 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 209 objects, 41 parts, 405 close pairs, 356 rays, 3 guns, 0 sensor pairs, 2 turrets swept, 6 cones, 29 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Three radiator spires, not the beauty's four, at 0.47, 0.65 and 0.52 over the spine block (tallest in the middle).** designs.md's table (3 spires, tallest 0.9) outranks the picture; Ryan, Nov 19 2026 (R331): "can we scale down the giant radiator/orange towers on each ship a bit too?", so about 70 percent of the table's heights.
- **The spires' fins stand further apart, so the ember shows as lit slats with dark iron between them, not as a whole lit tower.** R331: the ember shows in the slats, not as a whole lit tower (factions.md Sunward silhouette line).
- **One flak pair (two twin tubs at the deck edges, station 60 percent), not the beauty's four tubs.** designs.md's table and data.js warden carry one flak slot (3 shots); four tubs would be silent or extra mounts (R241).
- **Round 3 (Ryan, Nov 20, on the in-game pictures: "fix ember glow and the boxy gun"): the casemate is about a quarter smaller (size 0.38, was 0.5) with a steeper glacis and narrower roof, and the three barrels reach further out of it.** the concept's bow gun is a compact sloped house with its barrels well out front; ours read as a big box on the spearhead. The spires' heat core now glows under iron ribs (the shared radiator glow='slats', so S8, Vigil and every Sunward build get it).
- **The bow gun is a fixed casemate (the Sear repeater: three barrels round a spindle in a forged housing with a sloped glacis), not a turning turret with a cupola.** data.js autocannon is arc F; a fixed forward mount matches the game, and the frigate turns to bring it to bear (R241); the concept's cupola read as a second gun, so the sight is a slit in the glacis.
- **The broadside band is plated and louvred, with no ports and no lit gallery slits.** designs.md: no broadside slot in data, so no ports (R241: no decorative guns).
- **The command deck looks out through three ember slits in the spine block's forward face at station 61 percent (the table's 58).** the spine block (and with it the spire line) must sit wholly aft of B-1, which runs ahead of it on the centreline and behind the flak tubs at the flanks.
- **Two ember bells 0.55 across at plus and minus 0.4 on riveted drums, the stern widened to 1.2 to carry them.** designs.md's table; the stern face must hold both drums (factions.md: two to four bells, deep-set).
- **The beam is 1.36 at the knuckle (1.47 over the band lips), not the table's 1.5.** the concept's own top view measures about 1.2 over the hull; the lips and louvres bring the envelope near the table, the hull stays a narrow knife.
- **Attitude thrusters, deck and belly hatches, heat louvres, frost running points, a belly armour step added.** a ship in space needs thrusters and access; the reactor needs louvres; the concept shows no underside; every part has a job (R221).
- **A second transverse break, B-4 at x 1.64: the spearhead snaps off whole, and the band peel (B-2) runs only between B-1 and B-4.** the death seam check (stage 7 run, Nov 19): the peel plane tilts and waves across the beam, and in the shallow bow its torn edge reached the knuckle, leaving 154 inside triangles (the hull liner and the bow stores) outside their piece; the bow piece has no peel, so 0 remain.
- **The concept's long centre rail is the dorsal power trunk, banded, from the casemate back to the spine block.** the rail needs a job (R221): it feeds the repeater from the reactor.

## Designed here, not shown in the picture

- The belly is designed here; the concept shows no underside.
- Frost-white markings and the half-sun crest are paint (the Sunward stack, stage 5), not modelled.
- Q1p (attitude thruster quad): bow attitude thruster on the upper facet.
- Q2p (attitude thruster quad): stern attitude thruster on the upper facet.
- V1p (louvre panel 0.24 x 0.10): reactor heat louvre over the reactor room.
- V2p (louvre panel 0.24 x 0.10): reactor heat louvre over the reactor room.
- L1p (running light): frost-white running point on the knuckle line.
- L2p (running light): frost-white running point on the knuckle line.
- L3p (running light): frost-white running point on the deck edge.
- L4p (running light): frost-white running point on the deck edge.
- L5p (running light): frost-white running point on the deck edge.
- Q1s (attitude thruster quad): bow attitude thruster on the upper facet.
- Q2s (attitude thruster quad): stern attitude thruster on the upper facet.
- V1s (louvre panel 0.24 x 0.10): reactor heat louvre over the reactor room.
- V2s (louvre panel 0.24 x 0.10): reactor heat louvre over the reactor room.
- L1s (running light): frost-white running point on the knuckle line.
- L2s (running light): frost-white running point on the knuckle line.
- L3s (running light): frost-white running point on the deck edge.
- L4s (running light): frost-white running point on the deck edge.
- L5s (running light): frost-white running point on the deck edge.
- H1 (round hatch 0.1): deck hatch over the crew deck.
- H2 (round hatch 0.1): deck hatch over the crew deck.
- H3 (round hatch 0.11): belly hatch on the armour step.
- H4 (round hatch 0.11): belly hatch on the armour step.
