# deathless_E12: Eclipse zenith (the ring cruiser), build sheet

Eclipse (deathless) | class Cruiser | version 2 (second sheet (Board review)), 2026-11-12 | blockout: `C:\Users\rcbai\Downloads\voidsworn_test\opus532e\e7\deathless_E12\deathless_E12_blockout.blend`

**Length 14.5 world units** (data.js d_harvester (cls 'Cruiser'); length from godot/render/hull_table.gd CLS_LEN['Cruiser'] = 14.5 (drawn x SHIP_K 1.6 = 23.2 on the board)). Frame: +X bow, +Y port, +Z up; station % from the prow tip; offset + port / - starboard; height from the hull datum (the hull centreline is z 0). Counts in this table outrank the pictures.

## Measured off the views

| Check | Value |
|---|---|
| model length | 14.564 |
| length side | 14.588 |
| length top | 14.588 |
| length disagreement percent | 0.0 |
| beam top | 8.475 |
| beam bow | 8.475 |
| beam disagreement percent | 0.0 |
| height side | 2.087 |
| height bow | 2.087 |
| height disagreement percent | 0.0 |
| widest at station percent | 44.6 |
| hull beam | 2.96 |
| hull depth | 1.4 |
| L to B hull | 4.9 |
| L to H hull | 10.36 |
| prow overhang | 7.09 |
| outline iou percent | 45.5 |
| mass outline iou percent | 44.9 |
| PASS | True |

## Feature table (every gun, launcher, engine, dish, claw, chain and major fitting)

| ID | Fitting | Count | Station % | Offset | Height | Points | Game slot | Source | Note |
|---|---|---:|---:|---:|---:|---|---|---|---|
| S1p | truss strut, 1.9 long | 1 | 19.7 | 0.16 | 0.13 | - | - | picture | truss from the spine to the fore port arc |
| S2p | truss strut, 2.5 long | 1 | 35.5 | 0.16 | 0.13 | - | - | designed | truss from the spine to the centre port arc |
| S3p | truss strut, 2.5 long | 1 | 51.4 | 0.16 | 0.13 | - | - | designed | truss from the spine to the centre port arc |
| S4p | truss strut, 1.9 long | 1 | 66.2 | 0.18 | 0.13 | - | - | picture | truss from the spine to the aft port arc |
| S1s | truss strut, 1.9 long | 1 | 19.7 | -0.16 | 0.13 | - | - | picture | truss from the spine to the fore starboard arc |
| S2s | truss strut, 2.5 long | 1 | 35.5 | -0.16 | 0.13 | - | - | designed | truss from the spine to the centre starboard arc |
| S3s | truss strut, 2.5 long | 1 | 51.4 | -0.16 | 0.13 | - | - | designed | truss from the spine to the centre starboard arc |
| S4s | truss strut, 1.9 long | 1 | 66.2 | -0.18 | 0.13 | - | - | picture | truss from the spine to the aft starboard arc |
| C1 | caged core of trapped light, 1.5 across | 1 | 43.4 | 0.00 | 0.15 | - | - | picture | the trapped light core in gimbal rings; the spine enters its hubs |
| T1 | twin turret | 2 barrels | 28.1 | 0.00 | 0.57 | forward, +4 elev | T gauss | picture | fore null cannon twin on its saddle |
| T2 | twin turret | 2 barrels | 59.4 | 0.00 | 0.57 | forward, +4 elev | T gauss | picture | aft null cannon twin on its saddle |
| A1 | spinal projector (fixed) | 1 barrel | 13.7 | 0.00 | 0.15 | forward | F doom | picture | the corona arc emitter on the spine head, firing through the ring's bow gap |
| G1 | twin turret | 2 barrels | 86.1 | 0.00 | 0.90 | forward, +6 elev | T gsentry | picture | the null spire: a small sentry twin on the block roof with green sights |
| E1 | engine, bell 1.0 across | 1 | 99.9 | 1.02 | 0.08 | exhaust aft | - | picture | port engine |
| E2 | engine, bell 1.0 across | 1 | 99.9 | 0.00 | 0.08 | exhaust aft | - | picture | centre engine |
| E3 | engine, bell 1.0 across | 1 | 99.9 | -1.02 | 0.08 | exhaust aft | - | picture | starboard engine |
| L0p | running light | 1 | 80.6 | 1.56 | 0.30 | - | - | picture | green light panel on the block flank |
| L1p | running light | 1 | 82.7 | 1.56 | 0.30 | - | - | picture | green light panel on the block flank |
| L2p | running light | 1 | 84.8 | 1.56 | 0.30 | - | - | picture | green light panel on the block flank |
| V1p | louvre panel 0.4 x 0.3 | 1 | 87.5 | 1.56 | 0.06 | - | - | picture | heat slot panel on the block flank |
| H1p | square hatch 0.3 | 1 | 88.9 | 0.50 | 0.90 | - | - | picture | hatch on the block roof |
| Q1p | attitude thruster quad | 1 | 77.6 | 1.00 | 0.64 | - | - | designed | block roof edge, firing up and out over the ring |
| Q2p | attitude thruster quad | 1 | 77.6 | 1.00 | -0.44 | - | - | designed | block belly edge, firing down and out |
| L0s | running light | 1 | 80.6 | -1.56 | 0.30 | - | - | picture | green light panel on the block flank |
| L1s | running light | 1 | 82.7 | -1.56 | 0.30 | - | - | picture | green light panel on the block flank |
| L2s | running light | 1 | 84.8 | -1.56 | 0.30 | - | - | picture | green light panel on the block flank |
| V1s | louvre panel 0.4 x 0.3 | 1 | 87.5 | -1.56 | 0.06 | - | - | picture | heat slot panel on the block flank |
| H1s | square hatch 0.3 | 1 | 88.9 | -0.50 | 0.90 | - | - | picture | hatch on the block roof |
| Q1s | attitude thruster quad | 1 | 77.6 | -1.00 | 0.64 | - | - | designed | block roof edge, firing up and out over the ring |
| Q2s | attitude thruster quad | 1 | 77.6 | -1.00 | -0.44 | - | - | designed | block belly edge, firing down and out |

Totals: 4 gun mounts with 7 barrels; 0 launcher tubes; 3 engines; 0 intakes; 0 dishes; 0 claws; 0 chains.
No gun rests facing aft: every gun row above points forward or out to the side (yaw under 90 degrees).

## Colour zones (break stations from the side view; finish from the beauty)

| Zone | From % | To % | Where | Note |
|---|---:|---:|---|---|
| deep violet plate, violet-black shade (paint stage) | 0.3 | 99.9 | whole ship |  |
| green-white corona line | 0.7 | 88.5 | every arc's outer rim |  |
| core light | 37.7 | 48.7 | the caged core |  |
| emitter green | 6.1 | 7.5 | the bow lens |  |

## Major masses

| Mass | Station % | Offset range | Height range | Colour | Note |
|---|---|---|---|---|---|
| Hull: the stern block and the aft spine | 48.7 to 93.4 | -1.48 to 1.48 | -0.62 to 0.78 | deep violet plate | a round-shouldered block tapering forward into the spine |
| Block roof step | 78.9 to 90.6 | -0.85 to 0.85 | 0.55 to 0.90 | violet plate | a raised plate step on the block roof, the sentry on it |
| Block flank cheeks | 79.6 to 89.6 | -1.56 to 1.56 | -0.30 to 0.42 | violet plate | armour cheeks on the block flanks, the lights in them |
| Spine, fore | 13.4 to 38.1 | -0.18 to 0.18 | -0.01 to 0.31 | deep violet plate | the plated beam from the core to the emitter |
| Arc, fore port | 0.3 to 27.0 | 0.69 to 3.59 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, centre port | 25.3 to 54.2 | 2.44 to 4.07 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, aft port | 54.3 to 80.4 | 1.49 to 3.87 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, stern port | 73.8 to 87.1 | 0.56 to 2.04 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, fore starboard | 0.3 to 27.0 | -3.59 to -0.69 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, centre starboard | 25.3 to 54.2 | -4.07 to -2.44 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, aft starboard | 54.3 to 80.4 | -3.87 to -1.49 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Arc, stern starboard | 73.8 to 87.1 | -2.04 to -0.56 | -0.31 to 0.11 | deep violet plate | box-section shade arc, the inner bay open |
| Saddle, fore battery | 23.0 to 33.3 | -0.42 to 0.42 | 0.13 to 0.57 | violet plate | the oval saddle the turret stands on |
| Saddle, aft battery | 54.2 to 64.5 | -0.42 to 0.42 | 0.13 to 0.57 | violet plate | the oval saddle the turret stands on |
| Emitter collars | 10.7 to 17.8 | -0.37 to 0.37 | -0.22 to 0.52 | mauve and violet | a part of the kit projector, counted as its own mass |
| Emitter shaft | 7.7 to 10.1 | -0.32 to 0.32 | -0.17 to 0.47 | violet and mauve | a part of the kit projector, counted as its own mass |
| Emitter block | 6.5 to 10.6 | -0.30 to 0.30 | -0.15 to 0.45 | mauve | a part of the kit projector, counted as its own mass |

## INSIDE (R98, R209): what each break reveals

Deck levels (height): block_lower deck -0.30 (78% to 91%); block_upper deck 0.38 (78% to 91%).

Bulkhead and frame stations: F0 73.4%, F1 80.3%, F2 86.5%, F3 91.3%.

| Space | Station % | Offset range | Height range | Note |
|---|---|---|---|---|
| conduit aft (machinery) | 49.4 to 72.1 | -0.10 to 0.10 | 0.06 to 0.24 | the spine's power conduits from the core to the drives |
| conduit fore (machinery) | 14.4 to 37.0 | -0.10 to 0.10 | 0.06 to 0.24 | conduits to the emitter and the fore battery |
| archive vault (archive) | 73.4 to 77.6 | -0.50 to 0.50 | -0.30 to 0.40 | the archive vault in the block's forward taper |
| dark decks (darkdeck) | 77.9 to 83.0 | -0.90 to 0.90 | 0.40 to 0.60 | dark decks: machine crew stations |
| sentry magazine (magazine) | 83.4 to 89.9 | -0.60 to 0.60 | 0.40 to 0.60 | under the null spire |
| engine room (engroom) | 80.3 to 91.3 | -0.90 to 0.90 | -0.55 to 0.30 | engine room and the three drives' feeds |
| battery feeds (magazine) | 26.7 to 29.5 | -0.12 to 0.12 | 0.33 to 0.53 | the fore battery's feed under its saddle |
| core (ecore) | 39.7 to 47.2 | -0.55 to 0.55 | -0.40 to 0.70 | the core of trapped light, caged in the open (hp_core) |

| Armour zone | Thickness (units) | Note |
|---|---:|---|
| ring arcs (outer walls and top plates) | 0.14 | the shade: thickest on the outer wall |
| stern block | 0.30 |  |
| spine | 0.12 | thin; the ring shades it |

| Break line | Station % | What it opens |
|---|---|---|
| B-1 | 43.4 (seam wanders 40.7 to 45.5) | the spine parts at the core: the cage bursts, the fore spine and the bow arcs tear away (a ragged bite where the core goes) |
| B-2 | 74.8 (seam wanders 73.4 to 76.9) | the block tears from the spine at its taper, opening the archive vault and the engine room |

Eclipse breaks in layers (factions.md): the ring arcs peel away first, band by band, as their struts snap, their open bays spilling frames and machinery; then the bare spine parts at the core and the block tears away. Full interiors throughout (R215), hidden until a piece breaks.


## Hard points (the contract of PR 530, tools/blender/kits/shared/hardpoints.py)

| Point | Station % | Offset | Height | Side | Section | Note |
|---|---:|---:|---:|---|---|---|
| hp_core | 43.4 | 0.00 | 0.15 |  |  |  |
| hp_breach_0 | 11.5 | 2.35 | 0.12 | port | prow | on a shade arc |
| hp_breach_1 | 39.8 | -3.64 | 0.12 | stbd | mid | on a shade arc |
| hp_breach_2 | 47.1 | 3.64 | 0.12 | port | mid | on a shade arc |
| hp_breach_3 | 73.0 | -2.58 | 0.12 | stbd | eng | on a shade arc |
| hp_rcs_0 | 77.6 | 1.00 | 0.66 | port |  |  |
| hp_rcs_1 | 77.6 | -1.00 | 0.66 | stbd |  |  |
| hp_rcs_2 | 77.6 | 1.00 | -0.50 | port |  |  |
| hp_rcs_3 | 77.6 | -1.00 | -0.50 | stbd |  |  |

## Fit check (RULEBOOK 5.15, R217 to R219)

Clashes left: CLASH 0, MOUNT 0, ARC 0, SWEEP 0, EXHAUST 0, EXIT 0. Tested: 446 objects, 30 parts, 309 close pairs, 368 rays, 4 guns, 3 turrets swept, 7 cones, 10 apertures. Every clash found on the round 2 layout and how it was fixed: [fit_report.md](fit_report.md); picture: [fit_view.jpg](fit_view.jpg).

## Parts inventory (R218)

Written from the concept before modelling; ticked per blob-sweep cell (present, shaped, detailed) in [inventory.md](inventory.md); the nine cells beside the concept: [cells.jpg](cells.jpg); concept and blockout at the same camera: [side_by_side.jpg](side_by_side.jpg).

## Changed from the picture (R207)

- **Every arc has its own truss struts (eight).** R207: the picture leaves four of seven arcs floating; the centre arcs get two struts each, clear of the core cage, the stern arcs sit into the block.
- **Eight arcs, the stern pair matched.** the picture has one stern arc on the starboard side only; matched pairs (factions.md) unless a break is drawn on purpose.
- **The spine slimmed to a rod (0.36 across); the block made compact and low (1.4 tall), its aft face filled by three 0.92 bells standing out 0.95 behind it.** the Board on the first sheet: the concept's spine is a thin rod carrying the fittings, and its three large dark bells are the stern's most prominent feature.
- **Three engines side by side in one row.** the plan and the beauty show three across; the side view stacks them, which the plan cannot; one row keeps the block broad and low.
- **Engines are eclipse rings, not flame.** factions.md: "no flaming bells. An eclipse ring of pale light".
- **Arcs are real box sections, 0.42 deep.** the side view draws the ring as a line; the beauty shows thick box sections with open bays, which carry frames and machinery.
- **Weapons by data.js slot.** d_harvester: gauss T twice on the spine saddles, doom F the bow emitter, gsentry T the null spire on the block roof (the picture's small green-lit turret).
- **Thrusters, hatches and heat panels added.** a ship in space needs thrusters; the picture shows no underside.

## Designed here, not shown in the picture

- The underside of the block and the ring is designed here; the picture shows no underside.
- S2p (truss strut, 2.5 long): truss from the spine to the centre port arc.
- S3p (truss strut, 2.5 long): truss from the spine to the centre port arc.
- S2s (truss strut, 2.5 long): truss from the spine to the centre starboard arc.
- S3s (truss strut, 2.5 long): truss from the spine to the centre starboard arc.
- Q1p (attitude thruster quad): block roof edge, firing up and out over the ring.
- Q2p (attitude thruster quad): block belly edge, firing down and out.
- Q1s (attitude thruster quad): block roof edge, firing up and out over the ring.
- Q2s (attitude thruster quad): block belly edge, firing down and out.
