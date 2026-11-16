# chorus_CS1BA2: Sealed Gills spore swarm (the Chorus spore swarm craft), build sheet

The Chorus (chorus) | class Squadron | version 1 (first sheet), 2026-11-15 | blockout: rendered in the issue 793 sandbox (Blender 5.3, Cycles CPU); not on the PC: `build.py chorus_CS1BA2 <out> render` rebuilds it from this file

**Length 1.6 world units** (data.js spore (cls 'Squadron', the Chorus wing: chorus sq 'spore'); length from godot/render/hull_table.gd CLS_LEN['Squadron'] = 1.6 (drawn x SHIP_K 1.6 x SQUADRON_K 1.5 = 3.84 on the board, docs/playbooks/scale.md)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

Weapon match (R241): **PASS**, 0 problems. [Full record](weapon_match.json).

| Slot | Weapon | Arc | Shots | Visible mounts (muzzles) |
|---:|---|---|---:|---|
| 0 | sporeb | T | 2 | S1 (1), S2 (1) |

| Check | Value |
|---|---|
| model length | 1.6 |
| length side | 1.602 |
| length top | 1.602 |
| length disagreement percent | 0.0 |
| beam top | 0.462 |
| beam bow | 0.462 |
| beam disagreement percent | 0.0 |
| height side | 0.24 |
| height bow | 0.24 |
| height disagreement percent | 0.0 |
| widest at station percent | 49.3 |
| hull beam | 0.44 |
| hull depth | 0.22 |
| L to B hull | 3.64 |
| L to H hull | 7.27 |
| prow overhang | 0.0 |
| outline iou percent | 83.4 |
| mass outline iou percent | 83.2 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| S1 | sealed gill bladder, 0.93 long, a closed sphincter at its front | 1 tubes | 24.8 | 0.16 | 0.07 | forward | T sporeb | picture | the port acid sac (data.js sporeb T, 2 shots): a sealed gill bladder swelling the upper flank, gill bands across it, a closed sphincter at its front; each sac bursts every volley |
| S2 | sealed gill bladder, 0.93 long, a closed sphincter at its front | 1 tubes | 24.8 | -0.16 | 0.07 | forward | T sporeb | picture | the starboard acid sac (data.js sporeb T, 2 shots): a sealed gill bladder swelling the upper flank, gill bands across it, a closed sphincter at its front; each sac bursts every volley |
| E1 | orifice, mouth 0.043 across | 1 | 99.8 | 0.04 | 0.03 | exhaust aft | - | picture | upper port orifice of the cluster: a muscle ring squeezing pulses of bile gas aft (no nozzle) |
| E2 | orifice, mouth 0.042 across | 1 | 99.8 | -0.04 | 0.03 | exhaust aft | - | picture | upper starboard orifice of the cluster: a muscle ring squeezing pulses of bile gas aft (no nozzle) |
| E3 | orifice, mouth 0.041 across | 1 | 99.8 | 0.03 | -0.03 | exhaust aft | - | picture | lower port orifice of the cluster: a muscle ring squeezing pulses of bile gas aft (no nozzle) |
| E4 | orifice, mouth 0.043 across | 1 | 99.8 | -0.04 | -0.03 | exhaust aft | - | picture | lower starboard orifice of the cluster: a muscle ring squeezing pulses of bile gas aft (no nozzle) |

Totals: 0 gun mounts with 0 barrels; 2 launcher tubes; 4 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| dark olive-brown flesh and callused hide (factions.md; R204: colour fixed in the build, not by the concept's plum) | 0.0 | 100.0 | whole body |  |
| ochre bone: the spine line and its fork; chitin growth knuckles | 0.0 | 90.0 | the back |  |
| muted matte amber in the gill valleys (no glow); bile yellow-green only deep in the orifices | 33.0 | 100.0 | the bladders, the orifices |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the grown spindle | 0.0 to 97.0 | -0.22 to 0.22 | -0.10 to 0.12 | dark olive flesh | one sleek grown spindle, drawn out along its flight axis; a smooth blunt bow, the stern tapering to a blunt end that carries the orifice cluster |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): .

Bulkhead and frame stations: .

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| acid gland p (gland) | 39.0 to 73.0 | 0.05 to 0.18 | -0.05 to 0.05 | the port acid gland: it fills the sac behind it |
| acid gland s (gland) | 39.0 to 73.0 | -0.18 to -0.05 | -0.05 to 0.05 | the starboard acid gland: it fills the sac behind it |
| ganglion (ganglion) | 21.0 to 35.0 | -0.06 to 0.06 | -0.04 to 0.05 | the swarm-mind's ganglion: the craft's pilot, wired to the sense pores ahead of it |
| gut (gut) | 64.0 to 80.0 | -0.08 to 0.08 | -0.06 to 0.06 | the gut that feeds the pulse muscles |
| pulse muscle (organ) | 88.6 to 95.4 | -0.07 to 0.07 | -0.04 to 0.04 | the pulse muscle behind the orifice cluster |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| hide | 0.01 | callused hide over the whole body; the bladders' skin thinnest |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 87.5 (seam wanders 86.7 to 88.3) | the body tears behind the bladders (the Chorus bursts and tears; only for the recipe's records: the game never breaks a craft) |

A craft: the game shows its death as a spark and hides it (godot/fx/fx_death.gd _wing_death); nothing breaks open. These few grown organs are here because the build contract needs an inside (tools/blender/build_sheets/contract.py); they cost few triangles.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 62.0 | 0.00 | 0.00 |  |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SENSOR 0, SWEEP 0, EXHAUST 0, EXIT 0, LANE 0. Tested: 44 objects, 6 parts, 58 close pairs, 62 rays, 0 guns, 0 sensor pairs, 0 turrets swept, 4 cones, 2 apertures, 4 lanes. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Length 1.6 (CLS_LEN Squadron; drawn 3.84 on the board), the same as every craft; length to beam about 3.1.** docs/playbooks/scale.md, Squadron rows, binding; Ryan (R259): a bit sleeker, so the body is drawn out along its flight axis and kept low.
- **Dark olive-brown flesh and ochre bone, not the render's plum.** factions.md (The Chorus: dark olive-brown hide, ochre bone, never red or magenta flesh) and R204 (colour is set in the build); the swarm reads as the same faction as the C10 and C11 hulls beside it.
- **The concept's eye-spots along the bow ridge are sense pores: raised rims round sunk pits.** factions.md: the Chorus never has eyes; the kit's pores are its senses ("it tastes the dark").
- **The bow fork is the bone line parting round the last tenth of the bow and running down to the tip, low and blunt.** the round 4 notes: the render draws two long prongs; the sheet keeps the fork short, blunt and low (DeepSeek: never forward prongs).
- **The stern tapers to a blunt end that carries the full-size orifice cluster (four muscle-ringed orifices facing aft), short creases where it draws in (never full rings: no grub segments).** the round 4 notes: the render runs the stern to a spike; the sheet tapers only the hull behind the cluster and ends blunt. The orifices are the drive, so they face aft.
- **Each gill bladder is one sac part: a long low swell of the flank, six raised gill bands, a matte amber blush in the five valleys, a closed puckered sphincter at its front.** data.js sporeb (2 shots) is the swarm's only weapon, one sac per flank, both bursting every volley; the burst needs a mouth, kept shut at rest (nothing open, no exposed fluid, R259).
- **The sacs are fixed, aimed three degrees out from the bow.** a craft turns onto its prey on a strafing run (the bomber's reading, weapon_match.py FITS sporeb: an acid sac on a launcher, issue 793).
- **No membranes trailing from the orifices.** the capital ships' trailing veils would hang far behind a 3.84 unit craft and read as a tail; the pulse shows in the bile glow deep in each orifice.
- **A small inside: two acid glands, the ganglion, the gut, the pulse muscle; one seam (B-1).** the game shows a craft's death as a spark and hides it (fx_death.gd _wing_death), so nothing breaks open; the build contract needs an inside and a seam.

## Designed here, not shown in the picture

- The flesh tones, the bone and the amber are schematic colour zones: the Chorus has no paint stack yet.
- data.js gives the Chorus hull colour as plum (#57364c) while factions.md and the C10 and C11 sheets use olive; the sheet follows factions.md. The Board may want the two brought in line.
- How a sheet craft reaches the game: the game builds every craft in code today (godot/render/squadron_craft.gd), so no stage 7 export or install here.
