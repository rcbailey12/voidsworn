# corsair_A17: Pack Hunter

Ashfall Hullbreakers | Cruiser | 2026-11-11 v1

## Authority and units

Class length: **14.5 world units**, from `godot/render/hull_table.gd`, `CLS_LEN`. The game applies `SHIP_K = 1.6`, drawing this class at 23.2 units. This sheet uses the unmultiplied class length. The same 5-unit bars appear on the side and top.

Accepted beauty is the identity reference. The old generated sheet is not a geometry source. Stations, offsets, mount heights and sizes below are an explicit proposed 3D interpretation, not measurements taken from the perspective picture. Counts are individually enumerated. No unseen counterpart is added by symmetry. A stand-in is not a production fitting.

Frame: +X bow, +Y port, +Z up. Station 0% is the foremost claw tip; 100% is the aft-most fitting. Offset is signed world units from the centreline. Aim is a unit vector in this frame. Every row is ONE mount, dish, claw, chain run or engine. A twin has two barrels. A launcher has ten individual tubes. Engine directions may point aft; gun directions may not.

| ID | Fitting | Count | Station % | Offset units | Height units | Aim X,Y,Z | Evidence / open work |
|---|---|---:|---:|---:|---:|---|---|
| I1 | intake | 1 | 11.7 | +2.117 | -0.099 | +0.966,-0.252,-0.053 | Visible; dimensions are blockout interpretation |
| I2 | intake | 1 | 9.8 | -1.906 | -0.200 | +0.966,+0.252,-0.053 | Visible; dimensions are blockout interpretation |
| D1 | dish | 1 | 20.2 | +3.165 | +1.133 | +0.851,+0.323,+0.413 | Visible; dimensions are blockout interpretation |
| D2 | dish | 1 | 23.2 | -2.595 | +0.740 | +0.851,-0.323,+0.413 | Visible; dimensions are blockout interpretation |
| H1 | hook | 1 | 8.1 | +1.499 | -1.337 | +0.954,-0.227,-0.194 | Visible paired boarding claws; hinge and hidden actuator TO BE DESIGNED |
| H2 | hook | 1 | 11.8 | -1.645 | -1.382 | +0.954,+0.227,-0.194 | Visible paired boarding claws; hinge and hidden actuator TO BE DESIGNED |
| C1 | chain | 1 | 42.4 | +2.021 | +1.380 | +0.872,-0.304,-0.384 | Two upper runs visible; underside return and attachment hardware TO BE DESIGNED |
| C2 | chain | 1 | 42.4 | -2.021 | +1.380 | +0.872,+0.304,-0.384 | Two upper runs visible; underside return and attachment hardware TO BE DESIGNED |
| G1 | twin gun | 1 | 56.4 | +3.342 | +0.143 | +0.636,+0.753,+0.170 | Two port middle/aft twin mounts; see annotated beauty inventory |
| G2 | twin gun | 1 | 70.7 | +2.444 | -0.178 | +0.697,+0.693,+0.186 | Two port middle/aft twin mounts; see annotated beauty inventory |
| g | twin gun | 1 | 43.6 | +3.583 | -1.419 | +0.544,+0.818,+0.185 | One low port twin visible |
| J1 | single gun | 1 | 34.1 | +3.939 | +0.986 | +0.652,+0.725,+0.221 | Port forward round gun, small low middle gun and upper shoulder single; see inventory |
| J2 | single gun | 1 | 59.1 | +3.250 | -1.492 | +0.705,+0.684,+0.188 | Port forward round gun, small low middle gun and upper shoulder single; see inventory |
| J3 | single gun | 1 | 62.5 | +2.304 | +1.875 | +0.757,+0.622,+0.202 | Port forward round gun, small low middle gun and upper shoulder single; see inventory |
| F1 | twin gun | 1 | 35.8 | -2.674 | +1.242 | +0.870,-0.311,-0.383 | Three far upper paired barrels visible; hidden lower battery TO BE DESIGNED; rest aim forward/outboard to clear other fittings |
| F2 | twin gun | 1 | 62.6 | -3.989 | -0.172 | +0.789,-0.507,-0.347 | Three far upper paired barrels visible; hidden lower battery TO BE DESIGNED; rest aim forward/outboard to clear other fittings |
| F3 | twin gun | 1 | 63.7 | -3.590 | +0.489 | +0.724,-0.645,+0.245 | Three far upper paired barrels visible; hidden lower battery TO BE DESIGNED; rest aim forward/outboard to clear other fittings |
| U | single gun | 1 | 50.0 | -0.901 | +2.039 | +0.953,-0.167,+0.254 | Visible; dimensions are blockout interpretation |
| E1 | engine | 1 | 85.1 | +2.731 | +0.249 | -0.937,+0.189,+0.292 | Three port aft cylinders visible at staggered heights; far layout TO BE DESIGNED |
| E2 | engine | 1 | 93.6 | +1.632 | -0.008 | -0.944,+0.153,+0.294 | Three port aft cylinders visible at staggered heights; far layout TO BE DESIGNED |
| E3 | engine | 1 | 93.7 | +1.721 | -1.957 | -0.947,+0.129,+0.295 | Three port aft cylinders visible at staggered heights; far layout TO BE DESIGNED |
| A | engine | 1 | 86.7 | -2.592 | +0.470 | -0.941,-0.171,+0.293 | Far upper aft cylinder visible; exit and hidden engine-end structure TO BE DESIGNED |

## TO BE DESIGNED

- Belly skin, internal decks, break lines and belly fittings TO BE DESIGNED
- Unseen starboard lower battery, engine end plumbing and chain returns TO BE DESIGNED
- All dimensions and stations are a proposed blockout interpretation of the accepted beauty
- Annotated beauty inventory pins the visible mounts; concealed barrels and far lower weapons stay open

The neutral belly and far engine caps in the blockout are closure placeholders. Their outer envelope can be measured; no hidden machinery is approved by those surfaces. Top views omit belly-only claws through genuine occlusion by the hull where applicable. Far-side mounts hidden in port profile are shown in the dashed register below that view.

## Rebuild

Run `tools/recipe/build_sheets_532.bat`. The blockout .blend stays in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-532\shots\corsair_A17\corsair_A17_blockout.blend`. The JSON in this folder is the placement source for all renders and the table.

Refs

- ../../../../contrib/muse/design/concept_round8_2026_11/corsair_A17_beauty.jpg
- ../../../../contrib/muse/design/concept_directions_2026_11/corsair_B.jpg
- ../../../../contrib/muse/design/concept_standard_2026_11/standard.md

## Final loft fit

Offsets and heights above include the final seven-section loft fit. The reproducible section coefficients and fitted concept camera are in `fit_parameters.json` and `concept_camera.json`. The JSON placement source is in normalized pre-fit coordinates. Use the coefficients when rebuilding it, or work directly from the .blend.

Engine, intake and claw braces are neutral mounting placeholders, TO BE DESIGNED. Chains follow the actual upper surface; their tabulated height is at mid-run. No hidden engine mouth or far weapon has been approved by adding these mounts.

## Major masses and colour zones

These are blockout masses, one of each named row. Bounds include the final section fit. Paint is schematic; use the accepted beauty for finish.

| Mass | Count | Station % range | Offset range units | Height range units | Role / colour |
|---|---:|---|---|---|---|
| M01_hull_envelope | 1 | 11.2 to 87.1 | -4.326 to +4.326 | -1.794 to +1.606 | hull |
| M07_aft_equipment_body | 1 | 76.6 to 92.4 | -2.255 to +2.255 | -1.281 to +1.303 | red |
| M02_foredeck | 1 | 16.9 to 60.5 | -1.950 to +1.950 | +0.424 to +1.952 | steel |
| M03_shoulder | 1 | 48.2 to 80.4 | -2.481 to +2.481 | -0.255 to +1.900 | red |
| M04_bridge | 1 | 65.3 to 85.2 | -1.532 to +1.532 | -0.142 to +2.532 | hull |
| M05_bridge_aperture | 1 | 68.8 to 71.2 | -1.205 to +1.205 | +1.542 to +1.857 | dark |
| TBD_belly_closure | 1 | 17.8 to 82.3 | -2.019 to +2.019 | -1.747 to -1.135 | open |
| M06_sponson_-1 | 1 | 57.2 to 80.9 | -4.270 to -2.007 | -1.430 to +0.536 | red |
| P_flank_-1_0 | 1 | 20.7 to 28.3 | -3.352 to -2.376 | +0.095 to +0.539 | steel |
| P_flank_-1_1 | 1 | 31.6 to 39.2 | -3.154 to -2.190 | -0.019 to +0.572 | red |
| P_flank_-1_2 | 1 | 42.5 to 50.1 | -3.846 to -2.874 | +0.600 to +1.054 | steel |
| P_flank_-1_3 | 1 | 53.4 to 61.0 | -3.699 to -2.809 | +0.334 to +0.890 | red |
| P_flank_-1_4 | 1 | 64.3 to 71.9 | -3.140 to -2.334 | -0.120 to +0.357 | steel |
| M06_sponson_1 | 1 | 57.2 to 80.9 | +2.007 to +4.270 | -1.430 to +0.536 | red |
| P_flank_1_0 | 1 | 20.7 to 28.3 | +2.376 to +3.352 | +0.095 to +0.539 | steel |
| P_flank_1_1 | 1 | 31.6 to 39.2 | +2.190 to +3.154 | -0.019 to +0.572 | red |
| P_flank_1_2 | 1 | 42.5 to 50.1 | +2.874 to +3.846 | +0.600 to +1.054 | steel |
| P_flank_1_3 | 1 | 53.4 to 61.0 | +2.809 to +3.699 | +0.334 to +0.890 | red |
| P_flank_1_4 | 1 | 64.3 to 71.9 | +2.334 to +3.140 | -0.120 to +0.357 | steel |
| P_prow_patch | 1 | 18.3 to 31.6 | -1.396 to -0.241 | +0.674 to +1.211 | red |