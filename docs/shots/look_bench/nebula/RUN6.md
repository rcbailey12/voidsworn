# Issue 368, Run 6: forked storms with colored bloom

Refs #368. Refs #256. Storm patches now carry 2 to 4 staggered strikes, each with
2 to 4 thinner branches. The branches taper and fade sooner than their trunk.
White-hot cores have cyan inner light and a violet outer corona through the
existing weapon bloom. Every strike drives local cloud light. Ryan approval is pending.

Start at [camera 170](N368A_R6_lightning_c170.jpg), then
[camera 60](N368A_R6_lightning_c60.jpg). Each shows Run 5, Run 6 and the unchanged
calm nebula from the same generated board. The six-frame strips at
[170](N368A_R6_strike_c170.jpg) and [60](N368A_R6_strike_c60.jpg) show the real
production burst. [Quality tiers](N368A_R6_quality_tiers.jpg) covers Max, High and Low.
All five sheets are 1280 by 720 with verified revision and stage provenance.

The merged partial was older than Run 5. Terrain source and prior evidence were
recovered from local commit `5ca3dc45`, preserving newer main code elsewhere.
This run builds on that source. No commit or push was made.

The calm card shader, calm fog shader, gas builder, fog builder and mask match
Run 5 exactly. The noise SHA256 stays
`92c69b3254aa015cd577bced12f694bfa764e4b8d3d5e2b2a332628f11dc5691` and the faction endpoint cap stays 0.25.
The nebula has no lightning. Whole-scene pixel equality is not claimed: distant
storm activity and decorative debris differ between the historical and current views.

Method: allocate channels per patch, spread them across cloud masses, give direct
forks tapering tube and skirt geometry, and drive a separate faster branch pulse.
The violet corona peaks outside the cyan skirt, avoiding the pale mix produced by
stacking both hues on the white core. Back faces of the hot tube no longer double
its white spill. Storm cloud flashes use cyan light; their resting shader is kept.
The scene glow, camera, backdrop, quality settings and accepted gas scale are kept.

The capture uses the real seed-4207 battle. Only presentation positions and the
first burst due time are set. Production updates generate every strike and book
its conservative 48-unit disc through the real flash-area counter. The real FX
clock advances beyond warmup flashes before the fixed samples, so stale warmup
entries cannot change which sample is softened. Reduce flashing keeps the same
strike positions with a measured peak 0.22, versus
0.95 normally. No comfort counter is bypassed.

The shown patch has 4 strikes; the other patches have 3 each. The six samples have
[0, 2, 3, 4, 4, 3] active channels. At least two are present in five of six
frames. The geometry probe measures real mesh rings, including thinner branch tips,
and confirms the branch pulse has ended while its trunk remains visible.

Native 4K hull contrast is luminance standard deviation over the real hull mask,
eroded by two pixels, divided by the matched clear-frame value. Clear frames hide
gas only and retain bolt light. Camera pose and 3840 by 2160 size are checked.

| Native 4K pair | Camera 170 contrast retained | Camera 60 contrast retained |
|---|---:|---:|
| Calm nebula | 98.99% | 98.91% |
| Storm during strike | 99.27% | 99.48% |

The default-camera hull brightens by 2.80/255 mean
luminance during the strike. Halo color is measured on pixels outside the bright
neutral core, within eight pixels, above the calm-frame luminance. Camera 170 has
5897 cyan and 554 violet pixels there;
camera 60 has 18861 cyan and 5561 violet.
An earlier trial failed the violet-pixel check and is excluded from the final evidence.

RTX 5080, Godot 4.7.2 Forward+, Max, MSAA 4x, vsync off, live #207 fleets and volleys.
Each map ran twice under the watchdog's solo GPU claim. The first invocation is
warmup only. The retained invocation has three sessions, 120 warmup and 720 measured
frames per mode. The 4K row renders at twice the 1080p viewport dimensions.

| Final map | 1080p frame median ms | 4K GPU median ms | 12.5 ms gate |
|---|---:|---:|---|
| Storm | 3.886 | 7.126 | PASS |
| Nebula | 4.640 | 6.855 | PASS |

Values are medians of three session medians. Every retained session passes both
gates. These are median gates, not a claim about every individual frame.
[Measurements](run6_measurements.json) retain every session, draw-call, primitive
and VRAM reading, adapter hashes, source hashes, pixel measurements and comfort
samples. The existing `exterior_alpha` late-shader diagnostic is present; final
GPU logs have no script or shader errors and no placeholder hulls.

Checks: the complete standing invocation had 59 PASS, two existing KNOWN rows and
one stale motion-check row. The partial had omitted Run 5's motion note and check
companions. Both were recovered under Rulebook 12.1; the corrected row passes all
54 assertions through the standing wrapper. Effective results are 60 PASS and two
KNOWN rows: seven listed findings and twelve oracle differences. Final geometry,
both terrain dry runs at all tiers, flash-area behavior, source preservation,
4K poses, halo pixels and picture provenance checks pass. Scale: 54 objects, zero
failures outside four existing KNOWN rows. All 252 installed ship files match the
manifest. [Check evidence](run6_checks.json) retains the initial result and rerun.

Changed source: `godot/world/world_living.gd`, `ion_storm.gd`, `lightning_capture.gd`
and the new `storm_lightning_check.gd`. Recovered Run 4/5 capture helpers and scenes,
prior reports and evidence remain beside this run. The required companion files
are `contrib/opus/briefs/nebula_motion_spec.md` and
`contrib/opus/tools/env_reconcile_tests.js`. This folder contains the five new
sheets, compositing and measurement scripts, source manifest, checks and report.
Import-only churn was restored. No ship assets, generated hulls, UID files or
workflow changes are deliverables.

R129: traced the world build, both storm material tiers, bolt/ribbon callers,
flash booking, live Reduce flashing and opaque-hull exclusion. No rule, save,
faction id, UI path or table changed. The standing oracle-copy check confirms the
committed tables equal fresh exports; no oracle refresh is needed. GitHub runs
standing checks, the em-dash scan, rules parity and Godot checks after runner push.
Skipped a full rules-parity rerun and new class/campaign/top-down/camera-26 rollout
because this run changes storm lightning and preserves the accepted gas scale.

Final shared evidence root:
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-368/shots/run6/final/`.
Raw `after_keep`, `high_keep`, `low_keep`, `reduced_keep` and both `gate_*_keep`
folders are the final source. Earlier folders are retained trials and are unused.
Run `lightning_capture.tscn -- --captures --map-case storm --terrain-tier max
--four-k --go-file <gpu_go.txt> --out <folder>` through `tools/pc/tmo.bat`, twice.
Use `--reduced` for the comfort pair and High/Low for fallback pairs. Timing uses
`nebula_bench.tscn`, `--sessions 3 --warmup 120 --frames 720 --modes base,res_2160`
under a solo claim. Compose with `render_storm_run6.py --source <final>
--before <run5/after_keep>` and measure with `measure_storm_run6.py --source <final>`.
The CPU geometry probe is `--headless --script res://world/storm_lightning_check.gd`.

Awaiting Ryan's look and the outside check before merge.
