# station_T2: run 3 shape damage review

Refs #373. Fleet station first. R279 sends the run 2 intact shape toward the accepted abandoned T2. This run builds
breaks into the kit and preserves uniform R247 scale. It is ready for a look, with production work still pending.

Review the camera-170 class pictures at native size first, then the concept comparisons:

- [T2 beauty beside the build](T2_beauty_compare.png): damage side in the same viewing direction, matched by eye.
  The generated concept has no calibrated camera. The comparison labels that limit.
- [T2 plan beside the build](T2_plan_compare.png): directly above; gap over the stub, bent spoke and widened limbs.
- [Camera 170 beside the super-dreadnought](game_compare170_super_dreadnought.png).
- [Low camera beside the cruiser](game_compare_low.png), then [open insides](sheet_inside.png).

The uniform span stays 99.2 world units. The new core has four open shell holes and a torn top drum exposing decks,
frames and racks. The ring's 40-degree gap is seized 30 degrees from service, over the bent half arm. Three full arms
retain collars; the stub has none. Three pods and a folded plate remain held against the structure. Five caps are dead
and damaged, the tallest tower leans five degrees, and four radiator banks are cold. The single moving part is radiator
4, hanging open on one hinge and swinging +/-3 degrees in 240 seconds. Six scattered clusters contain 90 blue emission
markers, plus five dull orange battery strips at torn frames. No red is added. Materials are previews only.

| Combat class | Native camera-170 picture |
|---|---|
| Frigate | [V14_23](game_compare170_frigate.png) |
| Destroyer | [V15_37](game_compare170_destroyer.png) |
| Cruiser | [V16_37](game_compare170_cruiser.png) |
| Carrier | [V18_51](game_compare170_carrier.png) |
| Battleship | [V17_37](game_compare170_battleship.png) |
| Dreadnought | [V1b_r_23](game_compare170_dreadnought.png) |
| Super-dreadnought | [H4_11](game_compare170_super_dreadnought.png) |
| Battle-barge | [C19_51](game_compare170_battle_barge.png) |
| Bio-titan | [B16_23](game_compare170_bio_titan.png) |
| Ark | [I8_37](game_compare170_ark.png) |
| Tomb-ark | [D22_23](game_compare170_tomb_ark.png) |

Reproduce by double-clicking `tools/recipe/station_review.bat`. Source scripts are under
`tools/blender/kits/hegemony_station/`. The measured review files, blend, GLB and all linked pictures are preserved in
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-373/shots/review6/`. The pictures and measured JSON reports are also
copied here. Every image is labelled station_T2 and no taller than 720 px. CPU renders use Cycles on CPU. GPU images
use the real game camera, battle lighting and fitted ShipView hulls in an isolated studio, with the second run kept.
They are not a station-map battle or evidence of performance.

Method: [build feature table](feature_table.md), [manifest](manifest.json), [geometry and motion](fit.json),
[export cost](cost.json), [review checks](review_checks.json), [range rejection proof](range_selftest.json),
[real inputs](game_inputs.json) and [camera framing](captures.json). The export count includes insides and the moving
radiator; no triangle cap is imposed. GPU draws and frame time are unmeasured.

Measured cost: 519,028 triangles, including 110,980 inside triangles; 14 GLB material primitives, 11 materials and two
mesh nodes. Dimensions are 99.200 x 70.201 units in plan and 65.185 tall, using the same uniform 1.922853 scale on all axes.

Validation on the PC: the complete review BAT returned 0, with all 34 review checks passing. Both deliberately altered
GLBs were rejected for leaving the scale table's range. The real probe loaded 30 hulls without placeholders; all 12 GPU
views passed framing checks after two capture runs. Standing checks on resume returned 0 with 57 PASS and two existing KNOWN rows.
Godot loaded 198 scripts and 11 scenes with zero failed loads. The scale check passed with six existing KNOWN rows.
Document, whitespace and no-em-dash checks passed. Scratch logs remain in TEMP. GitHub CI awaits the runner's push.

Resume verification: the runner's preserved checkout held the completed run 3 files and pictures, while this checkout
had reverted to the first review. Only the station kit, station recipe entry/launcher and station evidence were restored.
A fresh CPU build in TEMP exactly reproduces the saved manifest and fit report. All 34 export/picture checks and both
range rejection cases pass again. All 25 labelled PNGs are 1280 x 720 and match the required shots folder. The earlier
CPU renders and twice-run GPU captures were preserved; this resume did not repeat those unchanged pictures.
The restored capture script also compiles against the current game without rendering.

The source plan fits the seven real blocked cells. Uniform R247 scale overhangs them, so live footprint integration
remains open. The live board constants and scale_check KNOWN rows stay unchanged. Forty-nine sampled radiator poses
test intersections against other structure, allowing its own hinge contact; they do not certify a continuous sweep
or full static fit. The joined review GLB is not a production destructible export.

R129: callers are the review launcher/probe/capture only. Live board rendering, saves, old profiles, rules twins and UI
paths have no behavior change. No oracle copies or table refreshes are needed. GitHub runs standing checks, Godot rules
parity and Godot game checks after the runner pushes; this no-commit run does not claim GitHub CI results.

Pending by the run 3 scope: production paint and recipe/export support, full fit/tear checks, footprint integration,
the station-map gate, outside review and Ryan's look before a live swap. Ryan has not looked during this run.
