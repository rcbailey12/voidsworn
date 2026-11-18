# Issue 368, Run 5: stronger storm lightning

Refs #368. R300 asks for lightning that holds up beside weapon and hit effects.
Storms now have thicker near-white hot channels, cyan/violet skirts, branching
forks and staggered strikes across separate cloud masses. Each strike lights
the gas locally and leaves a faint light on the hull. The existing battle bloom
is used unchanged. These are installed-in-game pictures. Ryan's approval is pending.

Start with [camera 170](N368A_R5_lightning_c170.jpg), then
[camera 60](N368A_R5_lightning_c60.jpg). The calm purple nebula is beside the
storm. Both come from the same real seed-4207 board and lighting. The distant
blue storm is also visible behind the nebula in the wide view. The native
detail crops are neither enlarged nor sharpened; the 60 view follows the bolt
when its position changes. Every sheet is 1280 by 720 and carries source provenance.

The [170 strike strip](N368A_R5_strike_c170.jpg) and
[60 strike strip](N368A_R5_strike_c60.jpg) show six frames from before the first
strike through its fade. The capture helper sets the first burst's due time,
then calls the production update. It does not draw or assemble a special bolt
for the pictures. Both channels, their glow and the local cloud flash are game output.
The [quality sheet](N368A_R5_quality_tiers.jpg) checks Max, High and Low at both
cameras. High and Low each ran twice, keeping the second. Their hulls remain
readable during the card flash; the game has no setting named Medium.

The resumed partial had replaced the finished Run 4 files with older prototype
files. Run 4 was recovered from local commit `f051a09b` before the baseline was
captured. The new work builds on that recovered source. Current-main picture
provenance changes in battle and the other capture tools were preserved.

The calm card shader, calm volume shader, gas builder, volume builder and mask
are identical to Run 4. The baked noise SHA256 remains
`92c69b3254aa015cd577bced12f694bfa764e4b8d3d5e2b2a332628f11dc5691`.
The faction endpoint cap remains 0.25. The full-frame nebula pictures can differ
in moving debris and distant storm activity; they are not claimed to be identical
whole-scene pixels. [Measurements](lightning_measurements.json) record source
comparisons, native hull pixels and the actual reduced-flashing uniforms.

| Native 4K hull pair | Camera 170 contrast retained | Camera 60 contrast retained |
|---|---:|---:|
| Nebula | 98.93% | 98.85% |
| Storm during strike | 98.89% | 98.92% |

Contrast is luminance standard deviation on the real projected hull mask divided
by the matched clear-frame value, eroded by two pixels. Gas alone is hidden in
the clear frame; bolt light remains. At 1080p the storm strike lifts mean hull
luminance by 0.86/255 at 170 and 0.28/255 at 60. The glow and gas brighten around
the channel while hull plating remains readable. These are observations, not new look gates.

Storm bursts use the real battle flash-area counter, booking a conservative
48-unit disc for the gas and bloom. Strikes within a burst start 0.10 seconds
apart and fade without the old second peak. Refused flashes and Reduce flashing
keep the geometry and use a slower rise and lower peak. Real capture uniforms
peak at 0.94 normally and 0.22 with Reduce flashing; the strike positions match.
The existing flash-area behavior check passes with zero failures.

RTX 5080, Godot 4.7.2 Forward+, Max, MSAA 4x, vsync off, real #207 fleets and
live volleys. Each map ran twice through the watchdog under an exclusive GPU
claim. The first invocation (one session) was discarded; the retained invocation
has three sessions, each with 120 warmup and 720 measured frames per mode.
The 4K mode renders a 3840 by 2160 3D buffer. Both modes passed in every session.

| Retained map | 1080p frame median ms | 4K GPU median ms | 12.5 ms gate |
|---|---:|---:|---|
| Storm, three patches plus nebula | 5.70 | 7.24 | PASS |
| Nebula, three patches | 4.91 | 7.20 | PASS |

Values are medians of the three session medians. Every session, draw-call and
primitive count, VRAM reading and adapter hash is retained in
[measurements](lightning_measurements.json). The existing `exterior_alpha`
late-shader diagnostic remains in those readings; no storm shader error or
placeholder hull was reported. These median gates do not claim that every
individual frame is below 12.5 ms.

The required standing suite ran in full: 59 PASS, two existing KNOWN baselines
and one stale per-bolt cadence assertion. That assertion and the working motion
note were updated together under Rulebook 12.1, then rerun through the standing
wrapper: PASS. Final effective coverage is 60 PASS and two KNOWN baselines
(seven listed findings and twelve oracle differences). The initial failure is
retained in [check results](lightning_checks.json). Parser, both real-map terrain
dry runs at all tiers, scale (53 objects, four existing known rows), and the
flash-area check pass. No rule, save, faction id or exported table changed;
the standing oracle-copy check passes and no oracle refresh is needed.

Changed files: `godot/world/world_living.gd`, the recovered and upgraded
`godot/world/ion_storm.gd`, recovered Run 4 capture scripts/scenes, new
`godot/world/lightning_capture.gd` and `.tscn`, the required motion-note/check
companions in `contrib/opus/`, and this evidence folder's sheets, JSON, scripts
and reports. Import-only churn was restored. No ship assets, generated hulls,
UID files or workflow files are deliverables. All 252 installed ship files
match the repo manifest; captures contain real hulls.

Method: shared-ring hot channels and joined soft skirts, HDR radiance through
the same unshaded additive path as weapon effects, existing Environment bloom,
existing baked 3D noise and local flash lighting in both storm shader tiers.
Max retains fog plus edge cards; High and Low retain cards. No scene-wide glow,
nebula palette, density, geometry, camera, backdrop or quality-setting change.

Evidence root:
`C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-368/shots/run5/`.
`before_keep`, `after_keep` and `reduced_keep` retain raw images, source hashes,
camera poses and production flash samples. Final capture runs have no script
or shader errors. Earlier trial folders are discarded and not used here.
Every linked report, sheet and data file is copied to that evidence root.

Reproduce captures through `tools/pc/tmo.bat` with the console Godot executable,
`--path godot --rendering-method forward_plus --resolution 1920x1080
res://world/lightning_capture.tscn -- --captures --map-case storm
--terrain-tier max --four-k --go-file <gpu_go.txt> --out <folder>`.
Run twice and keep the second. Add `--reduced` for the comfort proof.
Use the original Run 4 source for the before pair. Compose and measure with
`render_lightning.py --source <run5>` and `measure_lightning.py --source <run5>`.
The scripts read real stamped captures and retained bench JSON, never invented readings.

R129: traced world build, storm material creation, bolt callers, flash updates,
the battle counter and live Reduce flashing, plus quality routing and hull fog
exclusion. No UI state, save behavior or rule twin changes. GitHub runs standing
checks, the em-dash scan, rules parity and Godot game checks after the runner pushes.
Skipped a new class-scale, campaign, top-down and camera-26 rollout because this
run changes storm lightning while retaining the accepted gas scale. Full rules
parity was not repeated for this look-only edit. Outside review remains Refs #256.
No commit or push was made. Stop for Ryan's visual approval.
