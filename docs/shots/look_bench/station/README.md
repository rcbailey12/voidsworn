# station_T2: run 4 towers and fine detail

Refs #373. Fleet station first. Ryan R284 asks for towers spread around the hub, varied heights, fine surface clutter,
varied core drums and exactly one large observation window. Run 3 damage and uniform R247 scale are retained.

Review camera 170 at native size first, then the concept comparisons and camera 60:

- [Camera 170 beside a cruiser](game_compare170_cruiser.png).
- [Accepted T2 beauty beside the build](T2_beauty_compare.png). The camera direction is matched by eye; the concept has no calibrated lens.
- [Directly above beside the accepted plan](T2_plan_compare.png).
- [Camera 60 close detail](game_detail60.png), a partial view at the actual game zoom radius.
- [Low camera beside a cruiser](game_compare_low.png) and [open insides](sheet_inside.png).

The five towers now have individual radial service bridges around the hub, five different heights and five different
caps. Only the tallest leans five degrees. Nine core drums vary in radius and height, with stepped shoulders and dark
glazing bands. One continuous curved observation pane is the only large lit window. Small vented plant pallets, pipes,
pressure hatches, conduits, junction boxes, antennas and panel fittings cover core, ring and arms. Six short ring service
fingers include three small cooling combs. No debris field is added. The three held pods and folded plate remain from run 3.

The seized ring keeps its 40-degree gap over the bent stub, five sprung plates and one buckled spoke. Four side holes
and the torn top expose real decks, frames and machinery. Four main radiator banks remain; radiator 4 on one surviving
hinge swings +/-3 degrees over 240 seconds. It is the only moving part. Six scattered clusters retain 90 small blue
emission markers, with five dull orange battery strips at torn frames. Preview materials only.

Reproduce with `tools/recipe/station_review.bat`, which calls the station kit's `review_run.bat`. Blender uses Cycles on
CPU, eight threads, SHEET_DEVICE=CPU. The watchdog handles PC GPU claims for the Godot captures. The launcher runs the
real-rules/ShipView probe, build and mesh measurements, export checks, both scale rejection cases, then captures twice
and keeps the second set. Source and bake scripts are under `tools/blender/kits/hegemony_station/`.

All linked reports, pictures, editable blend and review GLB are saved in
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-373/shots/review7/`. Earlier reviews are preserved. Labelled pictures
and measured reports are copied beside this README; no image is taller than 720 px. Godot pictures use real fitted hulls,
the game camera and battle lighting in an isolated studio. They are not station-map battle or performance evidence.

Method and budget: [build sheet](feature_table.md), [source-hashed manifest](manifest.json), [mesh and motion report](fit.json),
[export cost](cost.json), [review checks](review_checks.json), [scale rejection proof](range_selftest.json),
[real inputs](game_inputs.json) and [camera framing](captures.json). The cost includes insides and the moving radiator.
Triangles are reported without a cap. GPU draws and station-map frame time remain unmeasured.

Measured cost: 860,992 triangles, including 111,148 inside triangles; 16 GLB material primitives, 13 materials and 2 mesh nodes. Plan span 99.200 x 70.927 units, height 69.268; uniform scale 1.922853 on all axes. No axis stretch.

Validation: all 38 station review checks pass, including actual exported glazing connectivity, tower separation, varied drum dimensions, five open shell apertures and 49 motion poses. Both deliberately altered GLB sizes are rejected. Two final Godot capture runs pass for all 11 combat classes, the low view and camera 60. Standing suite: exit 0, 57 PASS rows and two existing KNOWN rows. Godot scale check: exit 0, 53 objects checked with six existing KNOWN rows. The fresh rules probe loads 30 actual hulls. Documentation, whitespace and em-dash checks pass. The initial fresh-checkout import hit its 600-second watchdog at 81 percent; a resumed import completed with no script errors. Scratch logs stay in TEMP. GitHub CI awaits the runner.

This checkout arrived with the first partial review. The completed run 3 station files were recovered from ecc91038
before run 4 changes. Only task files were restored. PC hulls were copied from build/godot before importing, and all 252
files matched the tracked manifest. The placeholder guard remains enabled for every real ShipView capture.

The source plan fits the seven real blocked cells. Uniform R247 scale overhangs that old live footprint, so footprint
integration remains open. Live board constants and scale_check KNOWN rows stay unchanged. Forty-nine sampled radiator
poses allow its own hinge contact; they do not certify a continuous sweep or full static fit. The review GLB joins
static modules and does not prove production tearing.

R129 sweep: callers are confined to the station review kit and launcher. Saves, old profiles, rule twins and UI paths
are untouched, so no oracle copy or table refresh is needed. The runner's eventual push will run standing checks,
Godot rules parity and Godot game checks. No commit or push was made by this task.

Review only. Production mask/trim paint, production recipe/export support, full fit and tear checks, live footprint
integration, station-map scene gate, outside check and Ryan's look remain pending before installation. Ryan has not
reviewed run 4 during this task. The separate debris job remains later.
