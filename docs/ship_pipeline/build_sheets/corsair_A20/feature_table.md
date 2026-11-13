# corsair_A20: Hullbreaker hulk-carrier (the Den), build sheet

Ashfall Hullbreakers (corsair) | class Carrier | version 1 (first sheet (issue 633)), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus633\corsair_A20\corsair_A20\corsair_A20_blockout.blend`

**Length 16.5 world units** (data.js c_hulk (cls 'Carrier'); length from godot/render/hull_table.gd CLS_LEN['Carrier'] = 16.5). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 16.505 |
| length side | 16.525 |
| length top | 16.525 |
| length disagreement percent | 0.0 |
| beam top | 6.188 |
| beam bow | 6.213 |
| beam disagreement percent | 0.15 |
| height side | 4.612 |
| height bow | 4.612 |
| height disagreement percent | 0.0 |
| widest at station percent | 81.2 |
| hull beam | 5.5 |
| hull depth | 2.05 |
| L to B hull | 3.0 |
| L to H hull | 8.05 |
| prow overhang | 2.51 |
| outline iou percent | 75.0 |
| mass outline iou percent | 75.1 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| HB1 | framed deck box 0.6 x 0.5 | 1 | 22.2 | -1.30 | 1.34 | - | - | picture | salvage locker bolted down on the deck |
| HB2 | framed deck box 0.5 x 0.5 | 1 | 33.7 | 0.00 | 1.34 | - | - | picture | salvage locker bolted down on the deck |
| HB3 | framed deck box 0.7 x 0.6 | 1 | 56.1 | -1.15 | 1.40 | - | - | picture | salvage locker bolted down on the deck |
| HB4 | framed deck box 0.5 x 0.4 | 1 | 63.4 | -0.75 | 1.40 | - | - | picture | salvage locker bolted down on the deck |
| HB5 | framed deck box 0.6 x 0.5 | 1 | 73.7 | 1.10 | 1.36 | - | - | picture | salvage locker bolted down on the deck |
| HB6 | framed deck box 0.6 x 0.5 | 1 | 88.2 | -0.90 | 1.36 | - | - | picture | salvage locker bolted down on the deck |
| HS1 | round hatch 0.5 | 1 | 14.0 | -1.40 | 0.97 | - | - | picture | round deck hatch at the bow end of the deck |
| HS2 | square hatch 0.6 | 1 | 49.4 | 1.55 | 1.00 | - | - | picture | square deck hatch over the hangar decks |
| VS0 | louvre panel 0.6 x 0.4 | 1 | 77.9 | -2.89 | 0.00 | - | - | picture | engine room louvre in the starboard wall |
| VS1 | louvre panel 0.6 x 0.4 | 1 | 85.2 | -2.89 | -0.15 | - | - | picture | engine room louvre in the starboard wall |
| AN1 | antenna array, 1.3 tall, 3 whips | 1 | 90.0 | 1.50 | 1.36 | - | - | picture | comms array on the aft deck: calls the squadrons home |
| H1 | open hangar mouth 3.6 long, 1.6 high, 1.9 deep, doors slid forward | 1 | 41.6 | 2.75 | -0.07 | 90 deg off the bow to port | - | picture | forward mouth on the port flank: torn plate rim, armoured doors slid clear, launch rails, a dim red lamp |
| H2 | open hangar mouth 3.0 long, 1.6 high, 1.9 deep, doors slid aft | 1 | 65.2 | 2.75 | -0.07 | 90 deg off the bow to port | - | picture | aft mouth on the port flank: torn plate rim, armoured doors slid clear, launch rails, a dim red lamp |
| C1 | cobbled fighter, 1.6 long | 1 | 41.0 | 2.10 | -0.86 | 90 deg off the bow to port | - | picture | nosing out of the forward mouth |
| C2 | cobbled fighter, 1.6 long | 1 | 64.0 | 2.13 | -0.86 | 90 deg off the bow to port | - | picture | parked deeper in the aft mouth, half refitted |
| I1 | intake tube, 1.1 across, 2.2 deep | 1 | 0.8 | 0.73 | -0.12 | forward | - | picture | port intake: the family's face (designs.md "two low intake tubes") |
| I2 | intake tube, 1.1 across, 2.2 deep | 1 | 0.8 | -0.73 | -0.12 | forward | - | picture | starboard intake: the family's face (designs.md "two low intake tubes") |
| I3 | wake-sniffer scoop with a grille, 0.2 across, 0.4 deep | 1 | 1.0 | 0.00 | -0.86 | forward | - | picture | chin scoop (designs.md) |
| J1 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 8.8 | 0.68 | -1.42 | hook forward and down | - | picture | port grabber under the bow block |
| J2 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 8.8 | -0.68 | -1.42 | hook forward and down | - | picture | starboard grabber under the bow block |
| J3 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 91.5 | 2.02 | -1.48 | hook forward and down | - | picture | port grapple arm, folded flat under the stern quarter |
| J4 | grabber arm, 2 segments, knuckles, rams, forked pincer | 1 | 91.5 | -2.02 | -1.48 | hook forward and down | - | picture | starboard grapple arm, folded flat under the stern quarter |
| D1 | listening dish, 1.2 across | 1 | 17.3 | 2.10 | 1.00 | 30 deg off the bow to port, +18 elev | - | picture | the larger dish on the port shoulder |
| D2 | listening dish, 0.8 across | 1 | 17.3 | -2.05 | 1.00 | 35 deg off the bow to starboard, +15 elev | - | picture | the smaller dish on the starboard shoulder |
| SB1 | spare engine bell, 1.0 across, lying across the deck in a cradle | 1 | 41.3 | 0.55 | 1.54 | - | - | picture | bolted down flat for field repairs (designs.md); cold, no glow |
| T1 | twin turret | 2 barrels | 28.2 | -0.70 | 1.34 | forward, +6 elev | T turret | picture | fore dorsal turret on the fore deck tier, all round |
| T2 | twin turret | 2 barrels | 79.7 | 0.10 | 1.36 | forward, +6 elev | T turret | picture | aft dorsal turret on the aft deck tier, all round (designs.md's deck gun aft) |
| E1 | engine, bell 0.9 across | 1 | 99.9 | -2.10 | 0.46 | exhaust aft | - | picture | stern bell |
| E2 | engine, bell 0.8 across | 1 | 99.9 | -1.06 | 0.42 | exhaust aft | - | picture | stern bell |
| E3 | engine, bell 1.1 across | 1 | 99.9 | 0.02 | 0.44 | exhaust aft | - | picture | stern bell, the largest |
| E4 | engine, bell 0.8 across | 1 | 99.9 | 1.10 | 0.40 | exhaust aft | - | picture | stern bell, in a violet Eclipse trophy housing |
| E5 | engine, bell 0.9 across | 1 | 99.9 | 2.12 | 0.48 | exhaust aft | - | picture | stern bell |
| Q1 | attitude thruster quad | 1 | 10.1 | 1.61 | -0.60 | - | - | designed | bow |
| Q2 | attitude thruster quad | 1 | 10.1 | -1.61 | -0.60 | - | - | designed | bow |
| Q3 | attitude thruster quad | 1 | 89.7 | 2.75 | -0.10 | - | - | designed | stern |
| Q4 | attitude thruster quad | 1 | 89.7 | -2.75 | -0.10 | - | - | designed | stern |
| L0 | running light | 1 | 16.7 | 2.76 | -0.40 | - | - | picture |  |
| L1 | running light | 1 | 87.3 | 2.76 | -0.60 | - | - | picture |  |
| L2 | running light | 1 | 7.6 | 1.60 | 0.30 | - | - | picture |  |
| L3 | running light | 1 | 22.2 | -2.90 | -0.40 | - | - | picture |  |
| L4 | running light | 1 | 41.6 | -2.90 | -0.55 | - | - | picture |  |
| L5 | running light | 1 | 66.7 | -2.90 | -0.35 | - | - | picture |  |
| L6 | running light | 1 | 81.5 | -2.90 | -0.55 | - | - | picture |  |
| L7 | running light | 1 | 7.6 | -1.60 | 0.30 | - | - | picture |  |

Totals: 2 gun mounts with 4 barrels; 0 launcher tubes; 5 engines; 3 intakes; 2 dishes; 4 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| soot and weathered plate | 0.1 | 100.0 | whole hull |  |
| pale Hegemony trophy plates | 51.9 | 65.2 | starboard wall and the aft deck |  |
| violet Eclipse plate | 22.2 | 28.2 | fore deck; the violet bell housing at the stern |  |
| dried-blood red patch | 50.0 | 57.3 | deck over the hangars |  |
| bare iron | 30.3 | 74.6 | the plate between the mouths |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Base hull (the slab, its port side stepped in at the hangar block) | 15.2 to 95.2 | -2.75 to 2.75 | -1.05 to 1.00 | soot and patched plate | the wide flat slab; between the hangar block's ends its port side is the back wall of the two mouths |
| Bow block | 1.6 to 17.9 | -1.62 to 1.62 | -1.05 to 0.90 | dark soot | the bow block in front of the body, as tall as the slab and about half its beam: a housing for the two huge intake tubes (the beauty) |
| Hangar sill | 30.3 to 74.6 | 0.80 to 2.75 | -1.05 to -0.86 | soot | the floor of both mouths, the belly under them |
| Hangar lintel | 30.3 to 74.6 | 0.80 to 2.75 | 0.72 to 1.00 | dark soot | the roof of both mouths, the deck over them |
| Plate between the mouths | 52.5 to 56.1 | 0.80 to 2.75 | -0.88 to 0.74 | bare iron, patched | the plate between the two mouths (it tears first, designs.md) |
| Starboard brick 1 | 19.1 to 30.7 | -2.89 to -2.45 | -0.55 to 0.45 | patched plate | armour brick on the closed starboard wall |
| Starboard brick 2 | 34.3 to 48.8 | -2.89 to -2.45 | -0.70 to 0.30 | patched plate | armour brick on the closed starboard wall |
| Starboard brick 3 | 52.5 to 67.6 | -2.89 to -2.45 | -0.50 to 0.55 | patched plate | armour brick on the closed starboard wall |
| Starboard brick 4 | 71.2 to 90.0 | -2.89 to -2.45 | -0.70 to 0.35 | patched plate | armour brick on the closed starboard wall |
| D1 fore deck tier | 17.6 to 37.6 | -2.40 to 0.70 | 0.96 to 1.34 | patched deck plate | a low tier of salvage plate on the deck, 0.34 high |
| D2 mid deck tier | 41.9 to 66.7 | -2.50 to -0.30 | 0.96 to 1.40 | patched deck plate | a low tier of salvage plate on the deck, 0.40 high |
| D3 aft deck tier | 69.7 to 92.2 | -2.00 to 2.10 | 0.96 to 1.36 | patched deck plate | a low tier of salvage plate on the deck, 0.36 high |
| Stern frame | 92.2 to 95.5 | -2.70 to 2.70 | 0.55 to 1.06 | iron | the frame along the top of the stern the bell row hangs from |
| Violet bell housing | 91.8 to 97.0 | 0.68 to 1.52 | -0.02 to 0.82 | violet Eclipse plate | a trophy housing torn from an Eclipse hull, round one bell (designs.md) |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): lower deck -0.12 (17% to 92%); upper deck 0.42 (17% to 92%).

Bulkhead and frame stations: F0 17.9%, F1 30.0%, F2 46.7%, F3 60.6%, F4 76.4%, F5 87.6%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| H1 hangar lower (hangar) | 31.3 to 51.9 | -1.90 to 0.65 | -0.75 to -0.20 | lower hangar deck behind the H1 mouth: half-built fighters on scavenged frames |
| H1 hangar upper (hangar) | 31.3 to 51.9 | -1.90 to 0.65 | -0.04 to 0.40 | upper hangar deck behind the H1 mouth: bombers and spares |
| H2 hangar lower (hangar) | 56.7 to 73.7 | -1.90 to 0.65 | -0.75 to -0.20 | lower hangar deck behind the H2 mouth: half-built fighters on scavenged frames |
| H2 hangar upper (hangar) | 56.7 to 73.7 | -1.90 to 0.65 | -0.04 to 0.40 | upper hangar deck behind the H2 mouth: bombers and spares |
| loot hold fore (hold) | 4.0 to 17.0 | -0.80 to 0.80 | -0.60 to 0.00 | loot hold in the bow block (designs.md) |
| loot hold body (hold) | 18.5 to 29.1 | -2.30 to 2.30 | -0.75 to -0.20 | loot hold at the front of the body |
| kennel deck (crew) | 18.5 to 29.1 | -2.30 to 2.30 | -0.04 to 0.60 | kennel deck for the boarding crews |
| turret magazine fore (magazine) | 24.3 to 32.2 | -1.80 to -0.10 | 0.55 to 0.82 | under the fore turret |
| core (core) | 47.6 to 59.1 | -2.20 to 0.60 | -0.75 to -0.20 | reactor core (hp_core), between the hangar decks |
| crew decks (crew) | 47.6 to 59.1 | -2.20 to 0.60 | -0.04 to 0.60 | crew decks over the core |
| turret magazine aft (magazine) | 78.2 to 84.0 | -0.60 to 0.80 | 0.55 to 0.82 | under the aft turret |
| machinery (machinery) | 78.2 to 85.8 | -2.30 to 2.30 | -0.75 to 0.30 | machinery aft |
| engine room (engroom) | 88.5 to 92.8 | -2.30 to 2.30 | -0.75 to 0.60 | engine room and the bell feeds |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| bow block | 0.25 | the intake face |
| starboard wall | 0.22 | the closed wall and its bricks |
| hangar block | 0.12 | thin round the mouths: the bay side tears open first (designs.md) |
| deck | 0.12 | the salvage tiers over it |
| engine end | 0.15 |  |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 21.3 (seam wanders 20.7 to 22.5) | the fore weld: the bow block and the front of the body tear away with the dishes and the grabbers, opening the loot holds |
| B-2 | 53.4 (seam wanders 52.8 to 54.3) | the hangar block parts between the mouths: the plate between them tears first and the craft spill (designs.md) |
| B-3 | 74.3 (seam wanders 73.5 to 74.9) | the aft weld: the stern, the bell row and the aft turret tear away, opening the machinery and the engine room |

Full interiors through the hull (R215), hidden until a piece breaks. The bay side tears open first, then the hull parts at the fore and aft welds: bow, hangar sections and stern, never halves (designs.md, R186).


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 53.4 | -0.70 | -0.45 |  |  |  |
| hp_breach_0 | 18.5 | 2.75 | 0.25 | port | prow |  |
| hp_breach_1 | 26.4 | -2.75 | 0.30 | stbd | prow |  |
| hp_breach_2 | 53.4 | 2.75 | -0.06 | port | mid |  |
| hp_breach_3 | 44.0 | -2.75 | -0.25 | stbd | mid |  |
| hp_breach_4 | 69.4 | -2.75 | -0.05 | stbd | mid |  |
| hp_breach_5 | 88.8 | 2.75 | 0.35 | port | eng |  |
| hp_breach_6 | 92.5 | -2.75 | -0.45 | stbd | eng |  |
| hp_rcs_0 | 10.1 | 1.61 | -0.60 | port |  |  |
| hp_rcs_1 | 10.1 | -1.61 | -0.60 | stbd |  |  |
| hp_board_0 | 53.4 | 2.75 | -0.40 | port |  |  |
| hp_board_1 | 55.5 | -2.75 | -0.30 | stbd |  |  |
| hp_bay_0 | 41.6 | 2.45 | -0.07 | port |  | launch out of the H1 mouth |
| hp_bay_1 | 65.2 | 2.45 | -0.07 | port |  | launch out of the H2 mouth |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 359 objects, 44 parts, 1402 close pairs, 319 rays, 2 guns, 2 turrets swept, 9 cones, 17 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Both hangar mouths on the PORT flank, big: the forward one 3.6 long and the aft one 3.0, 1.58 high (three quarters of the flank), 1.9 deep to the back wall and 1.6 to the blast door.** Ryan's ruling for the round (the sheet's side view is the layout of record; the front view's mouths either side of the intakes are a drift); sized between the sheet's side view and the beauty so a 1.6 fighter fits and they read as launch bays with depth.
- **Each mouth is a real recess with a torn plate rim, armoured doors slid clear on rails, launch rails on the floor, ceiling beams, a dim red lamp, frame ribs and an inner blast door on the back wall.** the Board's brief: they must read as launch bays with depth; designs.md's armoured doors slid open and red lamps.
- **The mouths are lined dark (floor, ceiling, back wall and ends): only the rails, ribs, red lamps and the fighters catch the light.** the Board on round 1 (Nov 13): the mouths must be big, deep, dark openings that show from the beauty camera with the fighter in them; round 1's were 1.37 high and lit grey inside, so they read as shallow grilles.
- **The bow block is as tall as the slab and about half its beam (3.2 across, 1.9 tall, 2.7 long); its face carries two huge intake tubes side by side, each 1.1 across (three quarters of the face's height), reaching 2.3 back into the block.** the Board on round 1 (Nov 13): the build had no twin tubes (two 0.8 tubes in a narrow block); the README's bow intakes and the beauty's two huge tubes. The concept sheet's plan draws the block about 0.4 of the beam; it is widened so the tubes fit side by side.
- **Bow thrusters and the bow lamps on the bow block's flanks, the chin scoop under the web between the tubes.** the wider block and its tubes fill the old places.
- **The bow block's front corners are closed plate, carrying the two shoulder dishes.** the beauty's front openings beside the intake block are the drift Ryan ruled out; designs.md puts the dishes on the shoulders.
- **The slab is 5.5 wide over its hull, about 6 over the starboard bricks (hull length to beam 2.7 on the top view) and 2.05 deep.** the accepted beauty (v2s, "hull deepened") draws it about 2.4 long for its width, the sheet's top view 3.4; the build sits between, nearer the beauty (R229: the whole concept; as A17's head followed its beauty).
- **Two dorsal turrets, one on the fore deck tier and one on the aft.** data.js c_hulk: turret T twice (R221); designs.md's bow casemates, starboard flank guns and rocket rack have no slot, so they are not built.
- **Five mismatched bells in a row along the top of the stern, one in a violet Eclipse trophy housing.** designs.md; the picture's eight become five.
- **A fighter nosing out of the forward mouth and a second parked deeper in the aft one, both 1.6 long.** designs.md (the forward mouth); the game's squadron length gives the scale.
- **The spare engine bell lies across the deck in a cradle, cold.** the picture's bell on the deck; designs.md: bolted down flat (field repairs).
- **The salvage deck is three low tiers of stacked plate with lockers bolted down, not loose junk.** Ryan R185: nothing hangs off the ship; stacked and bolted scrap brick (R196, R197).
- **One pair of grabbers under the bow block and two heavy grapple arms folded flat under the stern quarters.** designs.md (four bow arms become two, so the jaw is not A17's; the grapples drag prizes alongside).
- **Four attitude thrusters.** a ship in space needs them to turn.
- **Every face is plated in courses at the hull's plate size (0.4 to 0.9), each course jointed on its own (a brick bond), patches laid over joints and offset patches over plates; upward faces stepped in terraces of one to three plate thicknesses.** the Board on round 1 (Nov 13): the faces read as big smooth grey planes with a few greebles; the concept is scrap brick, plates over plates on every face (R196, R197). Kit: the sheet kit's courses plating (kit.py, opt-in, issue 633).
- **Insides: two hangar deck levels behind each mouth, loot holds in the bow, a kennel deck, the core between the hangar decks, machinery and the engine room aft.** designs.md; R209, R215.

## Designed here, not shown in the picture

- Belly detail between the bow grabbers and the stern grapples is designed here; the picture does not show the underside.
- Q1 (attitude thruster quad): bow.
- Q2 (attitude thruster quad): bow.
- Q3 (attitude thruster quad): stern.
- Q4 (attitude thruster quad): stern.
