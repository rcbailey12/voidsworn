# corsair_KB1CC: Wide Glacis bomber (Ashfall Hullbreaker bomber wing craft), build sheet

Ashfall Hullbreakers (corsair) | class Squadron | version 5 (R304 run 3: long integrated bomb barrels, issue 903), 2026-11-16 | blockout: rebuilt on Ryan's PC; docs/shots/look_bench/corsair_KB1CC/shape_r294/reproduce.py records the sheet and paint proof

**Length 1.6 world units** (data.js bomber (cls 'Squadron', the Hullbreaker wing: corsair sq 'bomber'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | bombs | T | 2 | BT1 (1), BT2 (1) |

| Check | Value |
|---|---|
| model length | 1.599 |
| length side | 1.601 |
| length top | 1.602 |
| length disagreement percent | 0.07 |
| beam top | 1.922 |
| beam bow | 1.922 |
| beam disagreement percent | 0.0 |
| height side | 0.398 |
| height bow | 0.399 |
| height disagreement percent | 0.07 |
| widest at station percent | 18.2 |
| hull beam | 0.98 |
| hull depth | 0.35 |
| L to B hull | 1.63 |
| L to H hull | 4.57 |
| outline iou percent | 79.5 |
| mass outline iou percent | 79.7 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note | Route |
|---|---|---:|---:|---:|---:|---|---|---|---| --- |
| W1 | vision slit 0.11 x 0.007 | 1 | 83.9 | 0.03 | 0.25 | - | - | designed | the crew's vision slit in the lip's face, a little to port, looking forward down the ramp (the bombardier aims the craft at its target) | kit |
| BT1 | integrated bomb barrel 0.864 long, mouth 0.20 across | 1 tubes | 7.1 | 0.79 | 0.09 | forward | T bombs | picture | R304: the port long bomb barrel runs .54 LENGTH from the unchanged dark mouth to its magazine breech, wrapped by curved armour and riveted straps; Run 2 bore light and bomb nose; bombs T, one shot from each tube every volley | hand-built |
| BT2 | integrated bomb barrel 0.864 long, mouth 0.20 across | 1 tubes | 7.1 | -0.79 | 0.09 | forward | T bombs | picture | R304: the starboard long bomb barrel runs .54 LENGTH from the unchanged dark mouth to its magazine breech, wrapped by curved armour and riveted straps; Run 2 bore light and bomb nose; bombs T, one shot from each tube every volley | hand-built |
| Y1 | sunken machinery well, pipes and bomb hoist | 1 | 48.9 | 0.65 | 0.07 | - | - | picture | R294: real opening through the shoulder skin, dark floor and walls, three coupled pipes, hoist and hinged partial cover; R304 barrel seat in outer wall | hand-built |
| Y2 | sunken machinery well, pipes and bomb hoist | 1 | 48.9 | -0.65 | 0.06 | - | - | picture | R294: real opening through the shoulder skin, dark floor and walls, three coupled pipes, hoist and hinged partial cover; R304 barrel seat in outer wall | hand-built |
| E6 | engine, bell 0.3 across | 1 | 99.6 | 0.78 | 0.08 | exhaust aft | - | picture | R294: large round aft-facing main drive, dark armoured drum, cooling bands and a red-orange throat; the housing is welded into the shoulder | kit |
| E7 | engine, bell 0.3 across | 1 | 99.6 | -0.78 | 0.07 | exhaust aft | - | picture | R294: large round aft-facing main drive, dark armoured drum, cooling bands and a red-orange throat; the housing is welded into the shoulder | kit |
| E1 | engine, bell 0.1 across | 1 | 99.8 | 0.17 | 0.19 | exhaust aft | - | picture | first drive: a salvaged bell with a red-orange glow on a short drum | kit |
| E2 | engine, bell 0.1 across | 1 | 99.8 | 0.09 | 0.19 | exhaust aft | - | picture | second drive: a salvaged bell with a red-orange glow on a short drum | kit |
| E3 | engine, bell 0.1 across | 1 | 99.8 | -0.01 | 0.18 | exhaust aft | - | picture | centre drive: a salvaged bell with a red-orange glow on a short drum, the big one | kit |
| E4 | engine, bell 0.1 across | 1 | 99.8 | -0.10 | 0.19 | exhaust aft | - | picture | fourth drive: a salvaged bell with a red-orange glow on a short drum | kit |
| E5 | engine, bell 0.1 across | 1 | 99.8 | -0.17 | 0.18 | exhaust aft | - | picture | fifth drive: a salvaged bell with a red-orange glow on a short drum | kit |

Totals: 0 gun mounts with 0 barrels; 2 launcher tubes; 7 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| rust and dried-blood plate in a patchwork of big uneven plates, soot and bare iron between | 0.1 | 100.0 | whole hull |  |
| weathered steel, iron and blood-red salvage patches | 0.1 | 100.0 | R294: the small pale and violet squares reassigned to the existing weathered zones |  |
| red-orange stern engines; dim deep red inside the forward bomb bores, dark collars | 96.2 | 100.0 | main drives and thruster bank; factions.md: runs dark |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the central body (the glacis ramp and the stern housing) | 0.1 to 96.2 | -0.49 to 0.49 | -0.08 to 0.27 | soot and patched plate | R294: a narrower tapered bow toe, a rising glacis ending at station -0.035, a level upper deck through -0.355, then the stern bank housing; flat belly with chines |
| Shoulder, port | 7.1 to 86.2 | 0.40 to 0.96 | -0.08 to 0.10 | dark soot and patched plate | the port side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row's magazine and the hoist bay |
| Shoulder, starboard | 8.1 to 85.2 | -0.96 to -0.40 | -0.08 to 0.08 | dark soot and patched plate | the starboard side body behind the corner pod, its top sloping down and out to a thin edge: the bomb row's magazine and the hoist bay; a touch lower and shorter than the port one (lopsided) |
| The armoured lip | 83.2 to 87.4 | -0.37 to 0.37 | 0.22 to 0.28 | dark soot plate | an armoured lip across the top of the glacis ramp, against the stern housing: it ends the slope, so the glacis reads as armour on a hull, the crew under it |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): .

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| magazine p (magazine) | 24.1 to 60.2 | 0.61 to 0.74 | -0.06 to 0.02 | the port bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube |
| magazine s (magazine) | 24.1 to 60.2 | -0.74 to -0.61 | -0.06 to 0.02 | the starboard bomb row in the shoulder: salvaged bombs racked nose forward, fed by the hoist to the tube |
| crew (crew) | 76.0 to 85.2 | -0.10 to 0.10 | -0.03 to 0.19 | the pilot and the bombardier under the lip at the top of the ramp, behind the vision slit |
| reactor (core) | 54.2 to 69.2 | -0.14 to 0.14 | -0.06 to 0.10 | the drive reactor, under the ramp |
| drive room (engroom) | 87.2 to 94.2 | -0.21 to 0.21 | -0.06 to 0.22 | the drive room and the bank's feeds, in the stern housing |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| glacis | 0.01 | the heaviest plate, over the crew and the bow |
| body and shoulders | 0.01 | patched plate |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 73.9 (seam wanders 73.1 to 74.8) | the crew and stern block tears from the body at a weld (Hullbreakers: at the seams; only for the recipe's records: the game never breaks a craft) |

R304: continuous .54 LENGTH barrel to a covered breech and lifting cradle, ending inside the unchanged magazine row


R304: continuous .54 LENGTH barrel to a covered breech and lifting cradle, ending inside the unchanged magazine row


A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. The magazine rows are here because the build contract needs an inside (tools/blender/build_sheets/contract.py) and because the magazine is the bomber's story; they cost few triangles.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 61.7 | 0.00 | 0.02 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 120 objects, 12 parts, 161 close pairs, 102 rays, 0 guns, 0 sensor pairs, 0 turrets swept, 7 cones, 3 apertures, 4 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **R304 run 3: each bomb mouth continues into a .54 LENGTH hollow barrel, with rear armour laps, four riveted straps and a covered feed to its existing magazine row.** Ryan: the tubes must be actual tubes running into the ship. Run 2 stopped the drum after .20 LENGTH. Mouths, bomb noses, bore light, rust-red paint inputs, engines, bays, pipes, rails, taper and plateau stay; only the tube seats relieve the shoulder and outer bay wall.
- **Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; beam about 1.2 of the length, the render's width.** docs/playbooks/scale.md, Squadron rows, binding; R273, Ryan, Nov 15: "Wider for sure": the round 3 beam guard (60 to 65 percent) is lifted for this craft. The first sheet held it at 0.61 and read far narrower than the render.
- **R299: two large forward bomb mouths in dark armoured collars, radius .064 LENGTH (was .026), bore .144 LENGTH deep with the bomb nose behind a dim red liner.** Ryan R299: the concept and previous build lost their bombing/torpedo-tube read. The lower drums blend into plated corner wedges; actual bores cut those wedges and the shoulder skins. Both bombs T mounts still fire every volley.
- **The tubes are fixed forward in their pods, not on a turning mount.** a craft turns onto its target on a strafing run; weapon_match.py FITS bombs: a bomb tube on a launcher (the Board's reading of rule 11 for craft); two tubes for the 2 shots, both fire every volley.
- **R294: in shares of LENGTH, the bow narrows from 0.302 half-beam to 0.205 at its toe; the glacis rises to x=-0.035, then stays level to x=-0.355; raised edge frames follow both planes.** R275 was interpreted as one slope all the way aft and kept a full-width bow station. That simplified away the concept's taper and plateau; R294 restores both.
- **The flank bays are the bomb hoists, one a side in the shoulder's sloped top: a heavy frame, a dark back, pipes and the hoist block inside, an armoured door over the fore part.** every part has a job (R221): the hoist walks the next bomb from the shoulder's magazine row into its tube; on the slope they face the battle camera; the doors carry a two-tone value shift so they survive 32 px (Qwen).
- **The stern thruster bank is five mismatched salvaged bells, the centre one the largest, in a recess (a hood, cheeks and a sill) in the stern housing.** the concept's row of stern thrusters; factions.md: mismatched bells with a red-orange glow, one often larger than the rest; the owner's rule for craft: nozzle clusters inside armoured blocks.
- **The starboard shoulder sits a touch lower and shorter than the port one; the plating is a patchwork of fewer, bigger, uneven plates of mixed size and angle (rust, dried blood, soot and iron with big trophy patches), laid by the faction kit's welded plater, never courses.** factions.md: lopsided, bolted, patched; R240 and R275: the patchwork never reads even or in rows. R294 reassigns this craft's isolated pale and violet squares to weathered metal and blood red without changing the faction stack.
- **Issue 875 (R289, R292): mixed-size turned plates and welded laps, bedded close to the skin; dark iron and weathered rust red from the faction stack.** The first patchwork proof still read as clean salmon slabs. The craft-only bright palette and reduced dirt hid its seams and wear; thicker relief made the small patches stand off the hull.
- **R299: two smaller and lower round main drives aft, plus the unchanged five stern thrusters; the two enlarged forward bomb tubes remain the only weapons.** R294 restored the drives. R299 reduces their radii from .096/.090 to .078/.074 LENGTH and lowers centres from .066/.060 to .050/.046. Forward weapons have straight red-lined bores; stern drives have orange flared throats and glowing plugs.
- **R294: the nacelle drums end aft of B-1; the same ragged seam extends to the shoulders' full beam.** a drive must ride whole with its piece (R226). The first long nacelle drum crossed the seam; shortening its mounting drum keeps the engine whole without moving the existing inside rooms.
- **R294: the side machinery bays are cut through the shoulder skin, with sunken floors, coupled pipes, hoists and partial hinged doors.** The old machbay depth of 0.004 length and the uncut skin made the pipes look like flat slats on a panel. The openings now have actual depth and their own dark lining.
- **R294: isolated small pale and violet plate zones become weathered steel and blood red; the little pale bomb-drum cover becomes iron.** Ryan named the remaining light grey and purple squares as stuck-on notes. The PR 898 craft paint stack, its geometry masks, wear and colours are unchanged; only this design's zone assignments change.
- **R299: larger armour plates, 85 percent rust/blood zone weight (was 49 percent); main body and shoulders use rust underpaint.** Ryan asked for the concept's rust red and a minority of grey trophies. Only KB1CC plate sizes, material weights and skin zones change; the PR 898 faction stack, worn rims and dark seams stay intact.
- **No dishes, claws, antennas, lamps or hangar.** below what the battle camera shows on a 3.84 unit craft, and nothing hangs off (factions.md); bold and simple.
- **A small inside: two magazine rows in the shoulders, the crew cell, the reactor, the drive room; one seam (B-1).** the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam.

## Designed here, not shown in the picture

- The rust, soot, trophy colours and the red running lights are the Hullbreaker paint stack (tools/blender/kits/hullbreakers/stack.py), applied later.
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here.
- W1 (vision slit 0.11 x 0.007): the crew's vision slit in the lip's face, a little to port, looking forward down the ramp (the bombardier aims the craft at its target).
