# corsair_KB1CC: Wide Glacis bomber (Ashfall Hullbreaker bomber wing craft), build sheet

Ashfall Hullbreakers (corsair) | class Squadron | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py corsair_KB1CC <out> render` rebuilds it from this file

**Length 1.6 world units** (data.js bomber (cls 'Squadron', the Hullbreaker wing: corsair sq 'bomber'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bombs | T | 2 | BT1 (1), BT2 (1) |

| Check | Value |
|---|---|
| model length | 1.596 |
| length side | 1.598 |
| length top | 1.598 |
| length disagreement percent | 0.0 |
| beam top | 1.922 |
| beam bow | 1.922 |
| beam disagreement percent | 0.0 |
| height side | 0.381 |
| height bow | 0.381 |
| height disagreement percent | 0.0 |
| widest at station percent | 4.5 |
| hull beam | 1.04 |
| hull depth | 0.35 |
| L to B hull | 1.54 |
| L to H hull | 4.57 |
| prow overhang | 0.0 |
| outline iou percent | 81.3 |
| mass outline iou percent | 81.6 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| W1 | vision slit 0.11 x 0.007 | 1 | 79.7 | 0.03 | 0.25 | - | - | designed | the crew's vision slit in the lip's face, a little to port, looking forward down the ramp (the bombardier aims the craft at its target) |
| BT1 | bomb tube in a corner pod, mouth 0.13 across | 1 tubes | 0.4 | 0.86 | 0.03 | forward | T bombs | picture | the bomb payload (data.js bombs T, 2 shots): the port bomb tube in its corner pod, a dark armoured collar round the mouth; one bomb from each tube every volley |
| BT2 | bomb tube in a corner pod, mouth 0.13 across | 1 tubes | 0.4 | -0.86 | 0.03 | forward | T bombs | picture | the bomb payload (data.js bombs T, 2 shots): the starboard bomb tube in its corner pod, a dark armoured collar round the mouth; one bomb from each tube every volley |
| Y1 | hoist bay 0.34 x 0.21, armoured door | 1 | 60.9 | 0.62 | 0.08 | - | - | picture | the port bomb hoist: the machinery that walks the next bomb from the shoulder's magazine row into its tube, behind an armoured door (the concept's recessed side bay) |
| Y2 | hoist bay 0.34 x 0.21, armoured door | 1 | 60.9 | -0.62 | 0.06 | - | - | picture | the starboard bomb hoist: the machinery that walks the next bomb from the shoulder's magazine row into its tube, behind an armoured door (the concept's recessed side bay) |
| E1 | engine, bell 0.1 across | 1 | 99.8 | 0.17 | 0.19 | exhaust aft | - | picture | first drive: a salvaged bell with a red-orange glow on a short drum |
| E2 | engine, bell 0.1 across | 1 | 99.8 | 0.09 | 0.19 | exhaust aft | - | picture | second drive: a salvaged bell with a red-orange glow on a short drum |
| E3 | engine, bell 0.1 across | 1 | 99.8 | -0.01 | 0.18 | exhaust aft | - | picture | centre drive: a salvaged bell with a red-orange glow on a short drum, the big one |
| E4 | engine, bell 0.1 across | 1 | 99.8 | -0.10 | 0.19 | exhaust aft | - | picture | fourth drive: a salvaged bell with a red-orange glow on a short drum |
| E5 | engine, bell 0.1 across | 1 | 99.8 | -0.17 | 0.18 | exhaust aft | - | picture | fifth drive: a salvaged bell with a red-orange glow on a short drum |

Totals: 0 gun mounts with 0 barrels; 2 launcher tubes; 5 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| rust and dried-blood plate in a patchwork of big uneven plates, soot and bare iron between | 0.0 | 100.0 | whole hull |  |
| trophy patches: pale Hegemony grey, violet Eclipse plate | 0.0 | 100.0 | scattered, big (R252; R274: the Hullbreaker paint stack turns the pale ones dark grey metal, issue 726) |  |
| red-orange glow only in the five bells; the mouths dark; no bright light | 96.2 | 100.0 | the thruster bank; factions.md: runs dark |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the central body (the glacis ramp and the stern housing) | 0.0 to 96.2 | -0.52 to 0.52 | -0.08 to 0.27 | soot and patched plate | one wide low body: its top one long glacis ramp, low at the bow lip and rising aft to the armoured lip and the stern housing that holds the thruster bank; flat belly with chines |
| Shoulder, port | 0.6 to 94.2 | 0.40 to 0.96 | -0.08 to 0.10 | dark soot and patched plate | the port side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row's magazine and the hoist bay |
| Shoulder, starboard | 0.6 to 92.7 | -0.96 to -0.40 | -0.08 to 0.08 | dark soot and patched plate | the starboard side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row's magazine and the hoist bay; a touch lower and shorter than the port one (lopsided) |
| The armoured lip | 79.0 to 87.4 | -0.39 to 0.39 | 0.21 to 0.28 | dark soot plate | an armoured lip across the top of the glacis ramp, against the stern housing: it ends the slope, so the glacis reads as armour on a hull, the crew under it |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): .

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| magazine p (magazine) | 24.1 to 60.2 | 0.61 to 0.74 | -0.06 to 0.02 | the port bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube |
| magazine s (magazine) | 24.1 to 60.2 | -0.74 to -0.61 | -0.06 to 0.02 | the starboard bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube |
| crew (crew) | 76.0 to 85.2 | -0.10 to 0.10 | -0.03 to 0.19 | the pilot and the bombardier under the lip at the top of the ramp, behind the vision slit |
| reactor (core) | 54.1 to 69.2 | -0.14 to 0.14 | -0.06 to 0.10 | the drive reactor, under the ramp |
| drive room (engroom) | 87.2 to 94.2 | -0.21 to 0.21 | -0.06 to 0.22 | the drive room and the bank's feeds, in the stern housing |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| glacis | 0.01 | the heaviest plate, over the crew and the bow |
| body and shoulders | 0.01 | patched plate |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 73.9 (seam wanders 73.1 to 74.8) | the crew and stern block tears from the body at a weld (Hullbreakers: at the seams; only for the recipe's records: the game never breaks a craft) |

A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rows are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber's story; they cost few triangles.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 61.7 | 0.00 | 0.02 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 116 objects, 10 parts, 275 close pairs, 76 rays, 0 guns, 0 sensor pairs, 0 turrets swept, 5 cones, 3 apertures, 4 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; beam about 1.2 of the length, the render's width.** docs/playbooks/scale.md, Squadron rows, binding; R273, Ryan, Nov 15: "Wider for sure": the round 3 beam guard (60 to 65 percent) is lifted for this craft. The first sheet held it at 0.61 and read far narrower than the render.
- **The two round mouths at the front corners are bomb tubes: dark armoured collars round dark bores with the next bomb's nose seated deep inside, no glow.** the round 3 sheet: the mouths at the glacis's extreme corners, each in a dark armoured collar; the render lights them red like engines, which would read as drives facing forward; the glow belongs to the bank aft.
- **The tubes are fixed forward in their pods, not on a turning mount.** a craft turns onto its target on a strafing run; weapon_match.py FITS bombs: a bomb tube on a launcher (the Board's reading of rule 11 for craft); two tubes for the 2 shots, both fire every volley.
- **The top is one long glacis ramp, low at the bow and rising aft to an armoured lip against the stern housing, with the crew's vision slit in the lip's face; the ramp is framed by armoured edge rails with bolted clamps that run diagonally up it.** R275 (Ryan, Nov 15 2026 21:28 CST, sending the wide sheet back): the top must be the concept's sloped glacis, not a flat slab; the round 3 sheet (DeepSeek) put the lip where the slope ends so it reads as armour on a hull; no canopy (R254), so the crew looks out through a slit; the rails are the concept's raised glacis edges.
- **The flank bays are the bomb hoists, one a side in the shoulder's sloped top: a heavy frame, a dark back, pipes and the hoist block inside, an armoured door in a second tone over the fore part.** every part has a job (R221): the hoist walks the next bomb from the shoulder's magazine row into its tube; on the slope they face the battle camera; the doors carry a two-tone value shift so they survive 32 px (Qwen).
- **The stern thruster bank is five mismatched salvaged bells, the centre one the largest, in a recess (a hood, cheeks and a sill) in the stern housing.** the concept's row of stern thrusters; factions.md: mismatched bells with a red-orange glow, one often larger than the rest; the owner's rule for craft: nozzle clusters inside armoured blocks.
- **The starboard shoulder sits a touch lower and shorter than the port one; the plating is a patchwork of fewer, bigger, uneven plates of mixed size and angle (rust, dried blood, soot and iron with big trophy patches), laid by the sheet's own plater, never courses.** factions.md: lopsided, bolted, patched, plates torn from every other faction; R240 and R275: the patchwork never reads even or in rows (the kit's courses read as tidy squares on a craft); R252: big trophy patches (R274: the pale ones become dark grey metal in the Hullbreaker paint stack for every ship, issue 726; the sheet keeps the pale zone).
- **No dishes, claws, antennas, lamps or hangar.** below what the battle camera shows on a 3.84 unit craft, and nothing hangs off (factions.md); bold and simple.
- **A small inside: two magazine rows in the shoulders, the crew cell, the reactor, the drive room; one seam (B-1).** the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam.

## Designed here, not shown in the picture

- The rust, soot, trophy colours and the red running lights are the Hullbreaker paint stack (tools/blender/kits/hullbreakers/stack.py), applied later.
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here.
- W1 (vision slit 0.11 x 0.007): the crew's vision slit in the lip's face, a little to port, looking forward down the ramp (the bombardier aims the craft at its target).
