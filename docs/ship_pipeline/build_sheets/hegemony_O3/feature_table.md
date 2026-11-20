# hegemony_O3: Relay beacon (Hegemony Navy objective), build sheet

Hegemony Navy (hegemony) | class beacon | version 1 (first sheet), 2026-11-20 | blockout: rendered in the issue 1413 cloud copy (Blender 4.5 as the bpy module, Cycles CPU); `build.py hegemony_O3 <out> render` rebuilds it from this file

**Length 7.5 world units** (data.js obj_beacon (no data.js ship: tools/recipe/gamedata.py OBJECTIVES, the relay objective); length 7.5 rail end to rail end: designs.md's proposal, locked by the Board Nov 20 2026 and recorded in godot/render/hull_table.gd HULL_LEN). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|

| Check | Value |
|---|---|
| model length | 7.5 |
| length side | 7.525 |
| length top | 7.525 |
| length disagreement percent | 0.0 |
| beam top | 4.438 |
| beam bow | 4.438 |
| beam disagreement percent | 0.0 |
| height side | 2.712 |
| height bow | 2.712 |
| height disagreement percent | 0.0 |
| widest at station percent | 49.3 |
| hull beam | 2.2 |
| hull depth | 2.2 |
| L to B hull | 3.41 |
| L to H hull | 3.41 |
| prow overhang | 2.25 |
| outline iou percent | 85.9 |
| mass outline iou percent | 85.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| L1 | relay lens, 1.72 across, in a 0.55 deep face block | 1 | 37.3 | 0.00 | 0.00 | - | - | picture | the relay lens: stepped machined rings down to a blue lens, a thin blue ring at the mouth that pulses in time with the fleet; no muzzle lip, no trench (designs.md) |
| Kpu | cradle latch pair | 1 | 50.7 | 2.12 | 0.42 | - | - | picture | the latch that locks the cradle clamp round the rail |
| Kpl | cradle latch pair | 1 | 50.7 | 2.12 | -0.42 | - | - | picture | the latch that locks the cradle clamp round the rail |
| Ksu | cradle latch pair | 1 | 50.7 | -2.12 | 0.42 | - | - | picture | the latch that locks the cradle clamp round the rail |
| Ksl | cradle latch pair | 1 | 50.7 | -2.12 | -0.42 | - | - | picture | the latch that locks the cradle clamp round the rail |
| Mpu | mooring collar latch | 1 | 10.0 | 2.09 | 0.42 | - | - | picture | a mooring collar on the rail: tugs and tenders make fast here |
| Mpl | mooring collar latch | 1 | 90.0 | 2.09 | -0.42 | - | - | picture | a mooring collar on the rail: tugs and tenders make fast here |
| Msu | mooring collar latch | 1 | 10.0 | -2.09 | 0.42 | - | - | picture | a mooring collar on the rail: tugs and tenders make fast here |
| Msl | mooring collar latch | 1 | 90.0 | -2.09 | -0.42 | - | - | picture | a mooring collar on the rail: tugs and tenders make fast here |
| A1 | sensor fin, 0.42 tall, 0.7 long | 1 | 63.7 | 0.00 | 1.10 | - | - | picture | the one low sensor fin: the relay's own fleet link and station keeping sensors |
| Q1pu | station-keeping thruster, two rectangular nozzles | 1 | 40.4 | 0.97 | 0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q1pl | station-keeping thruster, two rectangular nozzles | 1 | 40.4 | 0.97 | -0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q1su | station-keeping thruster, two rectangular nozzles | 1 | 40.4 | -0.97 | 0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q1sl | station-keeping thruster, two rectangular nozzles | 1 | 40.4 | -0.97 | -0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q2pu | station-keeping thruster, two rectangular nozzles | 1 | 64.0 | 0.97 | 0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q2pl | station-keeping thruster, two rectangular nozzles | 1 | 64.0 | 0.97 | -0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q2su | station-keeping thruster, two rectangular nozzles | 1 | 64.0 | -0.97 | 0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| Q2sl | station-keeping thruster, two rectangular nozzles | 1 | 64.0 | -0.97 | -0.97 | - | - | designed | station-keeping thruster pad: the relay holds its place, it does not fly |
| H1 | square hatch 0.4 | 1 | 50.7 | 0.00 | 1.10 | - | - | picture | deck hatch: the maintenance crew's way into the relay core |
| H2 | square hatch 0.4 | 1 | 50.7 | 0.00 | -1.10 | - | - | picture | belly hatch: stores and the core's spares |
| V1p | louvre panel 0.3 x 0.5 | 1 | 64.0 | 0.62 | 1.10 | - | - | picture | heat louvre over the relay core's cooling plant |
| V2p | louvre panel 0.2 x 0.4 | 1 | 40.4 | 0.55 | 1.10 | - | - | picture | heat louvre behind the lens: the emitter's cooling |
| V1s | louvre panel 0.3 x 0.5 | 1 | 64.0 | -0.62 | 1.10 | - | - | picture | heat louvre over the relay core's cooling plant |
| V2s | louvre panel 0.2 x 0.4 | 1 | 40.4 | -0.55 | 1.10 | - | - | picture | heat louvre behind the lens: the emitter's cooling |

Totals: 0 gun mounts with 0 barrels; 0 launcher tubes; 0 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| pale grey module plate, steel-blue trim (paint stage) | 30.0 | 100.0 | whole relay |  |
| implant-blue lens and light strips, the pulsing ring at the lens mouth | 30.0 | 100.0 | the lens, the rails |  |
| no rust, no warm light, no asymmetry, no weapons, no propulsion row | 30.0 | 100.0 | factions.md Never; designs.md: no prow, no drive |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Relay module | 37.3 to 70.7 | -1.10 to 1.10 | -1.10 to 1.10 | pale grey module plate | the relay module: a square section with chamfered edges, the relay core inside, the lens in its forward face |
| Rail, port upper | 1.6 to 98.4 | 1.75 to 2.05 | 0.27 to 0.57 | pale grey module plate | a cradle rail: a chamfered beam with flush panels, end caps and blue light strips |
| Rail, port lower | 1.6 to 98.4 | 1.75 to 2.05 | -0.57 to -0.27 | pale grey module plate | a cradle rail: a chamfered beam with flush panels, end caps and blue light strips |
| Rail, starboard upper | 1.6 to 98.4 | -2.05 to -1.75 | 0.27 to 0.57 | pale grey module plate | a cradle rail: a chamfered beam with flush panels, end caps and blue light strips |
| Rail, starboard lower | 1.6 to 98.4 | -2.05 to -1.75 | -0.57 to -0.27 | pale grey module plate | a cradle rail: a chamfered beam with flush panels, end caps and blue light strips |
| Cradle, port | 47.3 to 54.0 | 1.08 to 1.26 | -0.72 to 0.72 | recessed grey | the cradle saddle on the module side, its arms and clamps round the two rails |
| Cradle, starboard | 47.3 to 54.0 | -1.26 to -1.08 | -0.72 to 0.72 | recessed grey | the cradle saddle on the module side, its arms and clamps round the two rails |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): main deck -0.35 (39% to 43%); main deck -0.35 (45% to 56%); main deck -0.35 (58% to 69%).

Bulkhead and frame stations: F2 50.4%, F3 64.0%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| corr fwd (hcorr) | 38.7 to 42.9 | 0.65 to 0.87 | -0.30 to 0.42 | the white maintenance corridor, numbered posts |
| emerg fwd (hemerg) | 38.7 to 42.9 | 0.65 to 0.87 | 0.42 to 0.47 | blue emergency light along the corridor |
| stores fwd (hold) | 38.7 to 42.9 | -0.70 to 0.70 | -0.85 to -0.42 | spares and the power cells under the main deck |
| corr mid (hcorr) | 45.1 to 55.6 | 0.65 to 0.87 | -0.30 to 0.42 | the white maintenance corridor, numbered posts |
| emerg mid (hemerg) | 45.1 to 55.6 | 0.65 to 0.87 | 0.42 to 0.47 | blue emergency light along the corridor |
| stores mid (hold) | 45.1 to 55.6 | -0.70 to 0.70 | -0.85 to -0.42 | spares and the power cells under the main deck |
| corr aft (hcorr) | 57.7 to 68.7 | 0.65 to 0.87 | -0.30 to 0.42 | the white maintenance corridor, numbered posts |
| emerg aft (hemerg) | 57.7 to 68.7 | 0.65 to 0.87 | 0.42 to 0.47 | blue emergency light along the corridor |
| stores aft (hold) | 57.7 to 68.7 | -0.70 to 0.70 | -0.85 to -0.42 | spares and the power cells under the main deck |
| emitter (core) | 38.7 to 42.9 | -0.60 to 0.60 | -0.30 to 0.60 | the lens emitter and its focusing coils, behind the lens (hp_core) |
| relay core (machinery) | 45.1 to 55.6 | -0.60 to 0.60 | -0.30 to 0.60 | the relay core: racks of identical signal equipment, blue status light |
| cooling (hold) | 57.7 to 68.7 | -0.60 to 0.60 | -0.30 to 0.60 | the cooling plant under the louvres |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| module plate | 0.10 | machined plate in modules, flush panels over it |
| lens face | 0.20 | the face block round the lens |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 44.0 (seam wanders 43.3 to 44.7) | the lens module tears off at the forward joint, the lens with it |
| B-2 | 56.7 (seam wanders 56.0 to 57.3) | the aft module falls away at the rear joint, the fin and the cooling plant with it |

Full interiors (R215), hidden until a piece breaks: the lens emitter, the relay core's racks of identical equipment, a white maintenance corridor with blue emergency light, the cooling plant, the stores. It breaks into modules at the relay-ring joints (designs.md); the rails part with the modules.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 40.9 | 0.00 | 0.10 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 174 objects, 24 parts, 97 close pairs, 110 rays, 0 guns, 0 sensor pairs, 0 turrets swept, 8 cones, 6 apertures, 0 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **The rails run along the module, two either side at two heights, in every view.** designs.md: the front view's sideways rails are a picture slip; the top view, the side view and the beauty run them along the module.
- **Length 7.5 to the rail ends, the cradle 4.1 across the rails, the module 2.2 square.** designs.md proposes a 7.5 footprint and a 4.8 cradle span; the top view draws the rails 4.1 apart (followed); the Board locked 7.5 (hull_table.gd HULL_LEN).
- **The cradle is one saddle per side at the module's middle, an arm and a latched clamp round each rail.** the top and side views clamp the rails at the middle; a clamp needs a latch (R221).
- **Four mooring collars, one per rail, the upper pair forward and the lower pair aft.** designs.md: four mooring collars on the rails; mirrored port and starboard (factions.md: no asymmetry).
- **Eight station-keeping thruster pads on the module's chamfered edges, two stations.** designs.md: pads on the module's sides only, no propulsion row; on the chamfers they fire clear of the rails.
- **Module bands at the relay-ring joints (x +0.45 and -0.5) carry the break lines; the cradle joints are not a separate seam.** designs.md: it breaks into modules, not a spine; the rails part with the module pieces.
- **A deck hatch, a belly hatch and four heat louvres added; the side view's longer module not followed.** a maintained relay needs access and cooling (R221); the top view governs the module's length.

## Designed here, not shown in the picture

- The lens ring's pulse in time with the fleet is a game effect, not modelled.
- Stencil marks and the steel-blue trim tone are paint (the Hegemony stack), not modelled.
- Q1pu (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q1pl (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q1su (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q1sl (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q2pu (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q2pl (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q2su (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
- Q2sl (station-keeping thruster, two rectangular nozzles): station-keeping thruster pad: the relay holds its place, it does not fly.
