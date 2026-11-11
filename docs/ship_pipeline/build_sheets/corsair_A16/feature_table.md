# corsair_A16: Warlord's Pyre-Barge

Ashfall Hullbreakers | Battle-barge | 2026-11-11 v1

## Authority and units

Class length: **26 world units**, from `godot/render/hull_table.gd`, `CLS_LEN`. The game applies `SHIP_K = 1.6`, drawing this class at 41.6 units. This sheet uses the unmultiplied class length. The same 5-unit bars appear on the side and top.

Accepted beauty is the identity reference. The old generated sheet is not a geometry source. Stations, offsets, mount heights and sizes below are an explicit proposed 3D interpretation, not measurements taken from the perspective picture. Counts are individually enumerated. No unseen counterpart is added by symmetry. A stand-in is not a production fitting.

Frame: +X bow, +Y port, +Z up. Station 0% is the foremost claw tip; 100% is the aft-most fitting. Offset is signed world units from the centreline. Aim is a unit vector in this frame. Every row is ONE mount, dish, claw, chain run or engine. A twin has two barrels. A launcher has ten individual tubes. Engine directions may point aft; gun directions may not.

| ID | Fitting | Count | Station % | Offset units | Height units | Aim X,Y,Z | Evidence / open work |
|---|---|---:|---:|---:|---:|---|---|
| I1 | intake | 1 | 8.9 | +2.416 | +0.822 | +0.918,-0.062,-0.391 | Visible; dimensions are blockout interpretation |
| I2 | intake | 1 | 8.6 | -2.824 | -0.462 | +0.918,+0.062,-0.391 | Visible; dimensions are blockout interpretation |
| D1 | dish | 1 | 17.5 | +2.722 | +4.494 | +0.976,-0.028,+0.216 | Visible; dimensions are blockout interpretation |
| D2 | dish | 1 | 20.4 | -0.726 | +4.433 | +0.976,+0.028,+0.216 | Visible; dimensions are blockout interpretation |
| H1 | hook | 1 | 8.6 | +2.654 | -2.478 | +0.867,-0.053,-0.496 | Visible paired boarding claws; hinge and hidden actuator TO BE DESIGNED |
| H2 | hook | 1 | 9.5 | -1.818 | -2.805 | +0.867,+0.053,-0.496 | Visible paired boarding claws; hinge and hidden actuator TO BE DESIGNED |
| C1 | chain | 1 | 42.9 | +3.761 | +2.496 | +0.985,-0.011,+0.175 | Two upper runs visible; underside return and attachment hardware TO BE DESIGNED |
| C2 | chain | 1 | 42.9 | -3.761 | +2.496 | +0.985,+0.011,+0.175 | Two upper runs visible; underside return and attachment hardware TO BE DESIGNED |
| G1 | single gun | 1 | 28.1 | +6.798 | +1.521 | +0.563,+0.824,+0.069 | Port lower single-barrel mount; see annotated beauty inventory |
| G2 | single gun | 1 | 68.2 | +5.048 | -2.415 | +0.381,+0.916,+0.124 | Port lower single-barrel mount; see annotated beauty inventory |
| T1 | twin gun | 1 | 39.5 | +5.513 | +2.378 | +0.693,+0.716,+0.085 | Port twin battery stand-ins; mount geometry simplified |
| T2 | twin gun | 1 | 71.9 | +5.257 | -0.811 | +0.762,+0.599,+0.247 | Port twin battery stand-ins; mount geometry simplified |
| T3 | twin gun | 1 | 75.8 | +4.206 | +0.496 | +0.900,+0.330,-0.286 | Port twin battery stand-ins; mount geometry simplified |
| F1 | single gun | 1 | 22.0 | -5.046 | +0.878 | +0.995,+0.094,-0.024 | Five distinct far-flank single mounts visible; see inventory. Hidden lower battery TO BE DESIGNED |
| F2 | single gun | 1 | 27.5 | -5.852 | +0.961 | +0.915,-0.403,-0.022 | Five distinct far-flank single mounts visible; see inventory. Hidden lower battery TO BE DESIGNED; rest aim forward/outboard to clear other fittings |
| F3 | single gun | 1 | 47.7 | -6.910 | +0.226 | +0.984,+0.019,+0.175 | Five distinct far-flank single mounts visible; see inventory. Hidden lower battery TO BE DESIGNED |
| F4 | single gun | 1 | 47.5 | -6.342 | +1.038 | +0.984,+0.018,+0.175 | Five distinct far-flank single mounts visible; see inventory. Hidden lower battery TO BE DESIGNED |
| F5 | single gun | 1 | 61.5 | -5.990 | +0.846 | +0.941,-0.317,+0.115 | Five distinct far-flank single mounts visible; see inventory. Hidden lower battery TO BE DESIGNED |
| V1 | twin gun | 1 | 67.2 | -4.779 | +1.265 | +0.939,-0.162,+0.305 | Two far upper twin mounts visible beside the launcher |
| V2 | twin gun | 1 | 70.4 | -3.790 | +1.624 | +0.846,-0.457,+0.275 | Two far upper twin mounts visible beside the launcher; rest aim forward/outboard to clear other fittings |
| U | single gun | 1 | 75.4 | +0.819 | +2.983 | +0.951,+0.000,+0.309 | One roof turret. Beauty barrel reads aft; rest aim changed forward to satisfy standard |
| R | launcher | 1 | 58.9 | +0.000 | +3.070 | +0.993,+0.000,+0.122 | One rack, ten mouths in two rows of five; rack back TO BE DESIGNED |
| E1 | engine | 1 | 92.4 | +5.332 | -0.751 | -0.928,+0.226,+0.295 | Port large exit and far shoulder pod visible; far exit TO BE DESIGNED |
| E2 | engine | 1 | 87.4 | -5.304 | -1.473 | -0.928,-0.226,+0.295 | Port large exit and far shoulder pod visible; far exit TO BE DESIGNED |
| A | engine | 1 | 90.2 | +3.058 | +2.354 | -0.947,+0.113,+0.301 | One upper port cylindrical aft unit visible; far equivalent TO BE DESIGNED |
| e | engine | 1 | 94.0 | +5.869 | -2.974 | -0.926,+0.235,+0.294 | One lower port exit visible; far equivalent TO BE DESIGNED |

## TO BE DESIGNED

- Belly skin, internal decks, break lines and belly fittings TO BE DESIGNED
- Unseen starboard lower battery, engine end plumbing and chain returns TO BE DESIGNED
- All dimensions and stations are a proposed blockout interpretation of the accepted beauty
- Annotated beauty inventory pins the visible mounts; concealed barrels and far lower weapons stay open

The neutral belly and far engine caps in the blockout are closure placeholders. Their outer envelope can be measured; no hidden machinery is approved by those surfaces. Top views omit belly-only claws through genuine occlusion by the hull where applicable. Far-side mounts hidden in port profile are shown in the dashed register below that view.

## Rebuild

Run `tools/recipe/build_sheets_532.bat`. The blockout .blend stays in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-532\shots\corsair_A16\corsair_A16_blockout.blend`. The JSON in this folder is the placement source for all renders and the table.

Refs

- ../../../../contrib/muse/design/concept_round8_2026_11/corsair_A16_beauty.jpg
- ../../../../contrib/muse/design/concept_directions_2026_11/corsair_A.jpg
- ../../../../contrib/muse/design/concept_standard_2026_11/standard.md

## Final loft fit

Offsets and heights above include the final seven-section loft fit. The reproducible section coefficients and fitted concept camera are in `fit_parameters.json` and `concept_camera.json`. The JSON placement source is in normalized pre-fit coordinates. Use the coefficients when rebuilding it, or work directly from the .blend.

Engine, intake and claw braces are neutral mounting placeholders, TO BE DESIGNED. Chains follow the actual upper surface; their tabulated height is at mid-run. No hidden engine mouth or far weapon has been approved by adding these mounts.

## Major masses and colour zones

These are blockout masses, one of each named row. Bounds include the final section fit. Paint is schematic; use the accepted beauty for finish.

| Mass | Count | Station % range | Offset range units | Height range units | Role / colour |
|---|---:|---|---|---|---|
| M01_hull_envelope | 1 | 10.0 to 89.8 | -7.385 to +7.385 | -3.367 to +2.920 | hull |
| M07_aft_equipment_body | 1 | 78.9 to 95.3 | -3.832 to +3.832 | -2.611 to +1.821 | red |
| M08_aft_engine_saddle | 1 | 84.8 to 97.3 | -4.968 to +4.968 | -1.161 to +2.167 | steel |
| M02_foredeck | 1 | 16.0 to 61.9 | -3.319 to +3.319 | +1.411 to +3.091 | steel |
| M03_shoulder | 1 | 48.9 to 82.8 | -3.997 to +3.997 | -0.759 to +3.144 | red |
| M04_bridge | 1 | 66.9 to 87.8 | -2.480 to +2.480 | -0.536 to +3.722 | hull |
| M05_bridge_aperture | 1 | 70.6 to 73.1 | -1.939 to +1.939 | +2.249 to +2.876 | dark |
| TBD_belly_closure | 1 | 17.0 to 84.8 | -3.886 to +3.886 | -3.239 to -1.417 | open |
| M06_sponson_-1 | 1 | 58.4 to 83.3 | -6.840 to -3.448 | -2.938 to +0.583 | red |
| P_flank_-1_0 | 1 | 20.0 to 27.9 | -6.218 to -5.000 | +1.549 to +1.938 | steel |
| P_flank_-1_1 | 1 | 31.4 to 39.4 | -6.377 to -5.279 | +1.294 to +1.960 | red |
| P_flank_-1_2 | 1 | 42.9 to 50.9 | -6.394 to -5.230 | +0.793 to +1.473 | steel |
| P_flank_-1_3 | 1 | 54.4 to 62.4 | -5.978 to -4.455 | +0.427 to +1.022 | red |
| P_flank_-1_4 | 1 | 65.9 to 73.9 | -4.943 to -3.815 | -0.376 to +0.638 | steel |
| M06_sponson_1 | 1 | 58.4 to 83.3 | +3.448 to +6.840 | -2.938 to +0.583 | red |
| P_flank_1_0 | 1 | 20.0 to 27.9 | +5.000 to +6.218 | +1.549 to +1.938 | steel |
| P_flank_1_1 | 1 | 31.4 to 39.4 | +5.279 to +6.377 | +1.294 to +1.960 | red |
| P_flank_1_2 | 1 | 42.9 to 50.9 | +5.230 to +6.394 | +0.793 to +1.473 | steel |
| P_flank_1_3 | 1 | 54.4 to 62.4 | +4.455 to +5.978 | +0.427 to +1.022 | red |
| P_flank_1_4 | 1 | 65.9 to 73.9 | +3.815 to +4.943 | -0.376 to +0.638 | steel |
| P_prow_patch | 1 | 17.5 to 31.4 | -2.513 to -0.543 | +2.818 to +3.056 | purple |
| P_crystal_removed | 1 | 39.4 to 51.4 | +4.903 to +6.377 | +1.230 to +1.937 | steel |