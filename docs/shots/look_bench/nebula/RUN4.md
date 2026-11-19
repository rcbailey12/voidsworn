# Issue 368, Run 4: calm nebula, charged storm

Refs #368. R289 calls for calm purple/rose nebula gas with no electrical-looking
branches, and steel-blue/cyan ion weather with white-violet lightning. These are
installed-in-game pictures for Ryan to judge. Visual approval is pending.

Start at [camera 170](N368A_R4_after_c170.jpg), then
[camera 60](N368A_R4_after_c60.jpg). Each view uses the same seed-4207 board,
lighting, real cruiser and fixed gas clock. Only the cruiser presentation position
and camera target move between the two real generated patches. The generated
terrain dictionary and rule state are unchanged.

| Actual Graphics setting | Before/after, camera 170 | Before/after, camera 60 | Both on one board |
|---|---|---|---|
| Max (top) | [170](N368A_R4_distinct_max_c170.jpg) | [60](N368A_R4_distinct_max_c60.jpg) | [Board](N368A_R4_board_max_c170.jpg) |
| High (middle) | [170](N368A_R4_distinct_high_c170.jpg) | [60](N368A_R4_distinct_high_c60.jpg) | [Board](N368A_R4_board_high_c170.jpg) |
| Low | [170](N368A_R4_distinct_low_c170.jpg) | [60](N368A_R4_distinct_low_c60.jpg) | [Board](N368A_R4_board_low_c170.jpg) |

The game has Low, High and Max, rather than a setting named Medium. All sheets
are 1280 by 720. Headers identify stage and the actual world/ion shader source
hashes. Native center crops are neither enlarged nor sharpened.
[Nebula motion](N368A_R4_neb_motion.gif) and
[storm motion](N368A_R4_storm_motion.gif) are 4-second, fixed-clock studies at
12 fps and camera 170. The storm study exercises one real flash envelope, not
the random strike schedule.

The resumed partial contained the older storm implementation. The completed Run 3
source was available in local commit `244a71ba`; its world, ion shader and storm
capture files were carried forward before the new baseline. No merge, commit or
push was made. Other current-main files were preserved.

Root cause: the calm card shader still added narrow isocontours from a fine noise
field, making bright gas edges look electrical even with no bolt mesh. Its
obsolete storm branch also remained after storms gained a separate shader.
Nebula cards now use broad, low-energy radiance from the existing density field.
The accepted nebula volume, palette, faction endpoint cap, footprint and drift
remain. Storm shadows and charged lobes are steel blue and cyan, darker between
strikes, with three times Run 3's drift. Existing raised forks, hull light, volume
light injection and flash timing remain; the bolt/light colour is white-violet.

Terrain mechanics were checked first in `battle.js` and `godot/rules/rules.gd`:
nebula subtracts 15 from incoming aim; ion storm subtracts 10 from outgoing aim
and drains 10 shield on the unit's turn. None of those rules, terrain names,
table exports, saves or UI callers changed. No oracle refresh is needed.

Evidence root:
`C:/Users/rcbai/Downloads/voidsworn_test/board/issue-368/shots/run4/`.
Every linked sheet, GIF, report and measurement file is also saved there.
`before_<tier>_keep/` and `after_<tier>_keep/` contain raw images, real-board
metadata, source hashes and camera poses. Warm folders retain the discarded
first invocation. `after_max_keep/` also contains native 4K gas/clear pairs,
real hull masks and the motion source frames.

Rulebook 12.1 requires the check and its working note to follow a picked look.
The first standing run exposed five stale assertions against the retired shared
storm shader. `contrib/opus/tools/env_reconcile_tests.js` now reads the live ion
module and checks the calm/storm split, faster storm motion, counter-drift and
derived flash distances. `contrib/opus/briefs/nebula_motion_spec.md` records those
active values. These two companion edits are required by 12.1, outside the
brief's normal delivery folders. The other 57 standing rows passed, with two
known baselines; the updated environment row passed its focused wrapper rerun.
The first full log retains the original failure for review.

## Measured gate and hull readability

Forward+, RTX 5080, solo GPU claims. Each kept batch follows a discarded first invocation. Max uses three sessions; fallbacks use one. Every session passed the 12.5 ms gate. Values below are medians of session medians.

| Map | Build / tier | 1080p frame ms | 4K GPU ms | Gate |
|---|---|---:|---:|---|
| nebula | before max | 8.531 | 7.094 | PASS |
| storm | before max | 5.169 | 7.409 | PASS |
| nebula | after max | 7.567 | 7.183 | PASS |
| nebula | after high | 7.176 | 5.901 | PASS |
| nebula | after low | 6.854 | 4.255 | PASS |
| storm | after max | 5.552 | 7.334 | PASS |
| storm | after high | 5.564 | 5.010 | PASS |
| storm | after low | 5.346 | 3.565 | PASS |

Observed Max after-minus-before deltas: nebula frame -0.964 ms, GPU +0.089 ms; storm frame +0.383 ms, GPU -0.075 ms. Session variation is retained; these are scene observations, not an isolated shader-cost claim.

| Gas / camera | Hull pixels | Contrast retained | Mean luma change /255 | p95 RGB difference /255 |
|---|---:|---:|---:|---:|
| neb / 170 | 8955 | 99.31% | -0.148 | 0.0 |
| neb / 60 | 83290 | 99.16% | -0.190 | 1.0 |
| storm / 170 | 8955 | 99.36% | -0.164 | 0.0 |
| storm / 60 | 83315 | 99.14% | -0.263 | 0.0 |

Contrast is luminance standard deviation on the real projected hull mask divided by the identical clear-frame value. Masks are eroded by two pixels; no sky rectangle is used. Pictures and hull pixels support crisp plating; the values are measurements for review, not a new look gate.

Raw timing paths, session readings, identical probe hashes and the four hull measurements are in [distinct_measurements.json](distinct_measurements.json). [distinct_checks.json](distinct_checks.json) retains the original stale-guard failure, the focused passing rerun, all other standing results, geometry and preservation checks. Current coverage is 58 PASS rows and two existing KNOWN baselines (seven listed findings and 12 oracle differences). The final scale check passes 53 objects with four existing exceptions. Source comparison proves the accepted nebula volume, palette and mask are unchanged; the endpoint cap stays 0.25 and the baked noise SHA256 is unchanged. All capture and timing commands completed without a shader error or placeholder hull.

Changed files: `world_living.gd`, restored Run 3 `ion_storm.gd` and storm capture scene/script, new `distinct_capture.gd` and `.tscn`, this folder's reproduction script, 11 sheets, two motion GIFs, two JSON records and report, plus the Rulebook 12.1 motion-note/check companions named above. Automatic importer metadata was restored; no ship assets, gen files or UID files are deliverables.

Skipped: new class-scale, campaign, top-down and camera-26 rollouts, because Run 4 only changes the distinction between these two materials and their existing scale is preserved. Full Godot parity was not repeated for this look-only change; no rules or data exports changed. The standing oracle-copy check passed. The full standing suite was run once; after its obsolete environment guard was corrected, only that changed row was rerun.

Method: the existing baked 128-cubed noise, Max fog plus reduced edge cards, High/Low cards, existing raised fork geometry and flash envelope. Both terrain types are captured on the same real board before and after. No commit or push was made. Stop for Ryan's visual approval. Outside review: Refs #256.


Reproduce captures through `tools/pc/tmo.bat` with the console Godot executable,
`--path godot --rendering-method forward_plus --resolution 1920x1080
res://world/distinct_capture.tscn -- --captures --map-case storm --terrain-tier
max --four-k --motion --go-file <gpu_go.txt> --out <folder>`. Repeat for High
and Low using their lowercase keys; native 4K pairs and motion are needed only
at Max. Run each twice and keep the second. Both kinds come from this single
real generated board, with no painted terrain fixture.

Timings use the unchanged `res://world/nebula_bench.tscn` adapter, map cases
`nebula` and `storm`, modes `base,res_2160`, 120 warmup frames and 720 measured
frames, three sessions at Max and one at each fallback. Run twice and keep the
second, with a solo GPU claim. The real gate remains 12.5 ms for the 1080p frame
median and 4K GPU median. Compose evidence with
`python docs/shots/look_bench/nebula/render_distinct.py --source <run4>`.

R129: world build, material/volume creation, battle quality routing, hull fog
exclusion, bolt updates and tick presentation were traced. The shaders change
no game-state API. GitHub runs standing checks, the em-dash scan, rules parity
and Godot game checks after the runner pushes. Outside review remains Refs #256.
Ryan's look approval is still required before acceptance.
