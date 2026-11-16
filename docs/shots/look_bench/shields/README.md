# SH372: a shield layer outside the hull

Refs #372. Run 4 answers R289. The final production source revision is `tree-4fd9819f`, captured in the game bench. This is ready for Ryan's look, not visual acceptance. The accepted look-bench baseline is unchanged.

The hull-fitted shell now stands off the plating. Its starting gap is 16 percent of beam, with a 1.8 world-unit minimum for narrow ships. Six smoothing passes round the little plate ridges into one envelope, keeping at least half the initial gap on every sampled core ray. The hit BVH uses those same final vertices. Measured camera-170 impact gaps are 2.327 for V18_51, 1.922 for H8_23, 1.781 for C15s_23 and 3.784 for I15_11. The shell follows the hull's motion.

A hit lights a continuous faction boundary and a brief patterned surface. Two thin patterned wave fronts travel away from the impact, then fade. The exposed space beside the plating stays dark. Sunward energy mixes its gold with its frost-white edge; Hegemony stays blue, Hullbreakers red-orange and Glasswrights prismatic. RGB is scaled together at the light ceiling, avoiding the pink wash caused by clipping channels separately. The existing baked charge-discharge picture is projected on the shell for 0.24 seconds. Hull hits keep their hot core, gas and thrown matter. Shield hits and the Hullbreaker shield break make no smoke.

R246 Rim and Gap remains the resting state. The PR 855 pool/view synchronization is retained: `shp`, `shMax`, derived catches, routing and recharge. An empty pool opens all four sides. No rules, saves, UI, browser files, tables or ship assets changed.

## Review pictures

Every comparison has four labelled rows: main `d32713f`, PR 855 run 1 `89bb41a`, rejected run 3 `1c2d3868`, and run 4 `tree-4fd9819f`. The source pixels at camera 170 are not enlarged. Camera 60 retains the standing bench's half-size crop and camera 26 its third-size crop. Four-row sheets trim empty vertical margins and stay at 1200 by 720 pixels; full strips retain all eight times.

| Hull and faction | Battle 170 | Middle 60 | Closest 26 |
| --- | --- | --- | --- |
| V18_51, Sunward Crusade | [170](SH372_voidsworn_c170.jpg) | [60](SH372_voidsworn_c60.jpg) | [26](SH372_voidsworn_c26.jpg) |
| H8_23, Hegemony Navy | [170](SH372_hegemony_c170.jpg) | [60](SH372_hegemony_c60.jpg) | [26](SH372_hegemony_c26.jpg) |
| C15s_23, Ashfall Hullbreakers | [170](SH372_corsair_c170.jpg) | [60](SH372_corsair_c60.jpg) | [26](SH372_corsair_c26.jpg) |
| I15_11, Glasswrights | [170](SH372_ithar_c170.jpg) | [60](SH372_ithar_c60.jpg) | [26](SH372_ithar_c26.jpg) |

The same real torpedo and V16_37 cruiser, shield versus hull: [170](SH372_hit_pair_c170.jpg), [60](SH372_hit_pair_c60.jpg), [26](SH372_hit_pair_c26.jpg). The first two columns are shield hits at +0.04 and +0.27 seconds; the last is the hull hit at +0.27 seconds.

[Phone comparison](SH372_hit_pair_phone.jpg) shows main, run 3 and run 4 as whole 1920 by 1080 frames reduced to 390 pixels wide. It deliberately keeps the small ship small. Separate 390-pixel cards keep the central camera-170 crop at source pixel size: [main](SH372_hit_pair_phone_main.jpg), [run 3](SH372_hit_pair_phone_run3.jpg), [run 4](SH372_hit_pair_phone_run4.jpg). These are labelled crops, not enlarged whole-frame claims.

The final shape has a visible boundary and gap, while main's egg has more free surface around the ship on which to display the pattern. This is a tradeoff for Ryan to judge. The Sunward pattern is less obvious than on the main egg at camera 170, and V16_37 remains very pale at peak impact. The separate boundary reads more clearly in the phone crop than in the full-frame phone reduction. Ryan must judge these remaining look risks against the ruling. Pixel checks do not grant visual approval.

## Light, depth and readability

Total added shield light is capped at **3.0 per linear RGB channel**, after faction tint and `fx_gain`, before tonemapping. Face-on light has a **0.55** ceiling; light close to opaque plating is tightened to **0.35**. Exposed grazing boundary light may rise toward 3.0. Overlapping folds and six overlapping hits share the ceiling. The high tier composes against the opaque scene once per fragment; overlap cannot repeatedly add light. The low tier keeps bounded alpha and omits screen and depth reads. Rest also omits those reads.

The cap stress uses the production shader, six overlapping hits, over-range tint, an unlit black hull, linear tonemapping, no bloom and exposure 0.02. A shader-written 3.0 reference calibrates the same pipeline. All four faction cases reached 3.000 without exceeding the reference. An aligned geometry-only mask excludes engine glow and measures a maximum of 0.553 over each hull, including 8-bit calibration rounding; the central near-hull region is dimmer. The calibration images and exact pixel values are recorded in [measurements.json](measurements.json).

Readability pairs hold the same hull pose, clock and materials with the shield off and lit. Twelve interior patches and eight silhouette edge pairs are selected from the unshielded pixels and hull mask first. All 12 faction/camera cases retain at least 30 percent of local contrast at all 12 patches. All 96 silhouette pairs exceed 1.25:1; the lowest is 1.266:1. The JSON records the sample coordinates and actual before/after contrasts.

The same-frame controls remove one feature at a time. Pattern, pulse, boundary and crackle all change the rendered pixels. Refraction is measured at +0.42 seconds, when the wave has reached exposed background; crackle is measured at +0.08 seconds, while its charge picture is alive. At camera 170, removing refraction changes 643, 510, 297 and 69 pixels for Sunward, Hegemony, Hullbreakers and Glasswrights respectively. Rock-contact ablations change 165, 190, 173 and 514 pixels. The checker is used only for mechanism controls. Readability uses the normal background. [Sunward mechanisms](SH372_voidsworn_mechanisms.jpg), [Hegemony mechanisms](SH372_hegemony_mechanisms.jpg).

## Performance and checks

[performance.json](performance.json) reports unchanged main versus run 4 on the binding #207 scene: median frame time at 1080p and GPU time at 4K, each against 12.5 ms. Each result is the median of three session medians, with 120 warm-up and 720 measured frames per session. Both versions run twice and the second launch is kept. The scene includes the storm, HUD, mixed fleet and running volleys. The separate 20-ship rest/hit isolation is additional evidence, not a replacement for that scene.

| Binding measure | Main | Run 4 | Change |
| --- | --- | --- | --- |
| 1080p frame median | 5.794 ms | 5.782 ms | -0.012 ms |
| 4K GPU median | 5.549 ms | 5.616 ms | +0.067 ms |

Both are below 12.5 ms. In the additional 20-ship hit isolation, 4K GPU time is 4.145 ms before and 4.157 ms after. Both complete scene versions log the same existing `exterior_alpha` late shader; no new shield shader is logged after warm-up.

[verification.json](verification.json) records the exact outcomes and limitations. The fixture uses `BattleAPI.new_battle_scenario`, real `applyHit` results and turns, and synchronizes through `BattleAPI.view`. Its checks prove pool depletion, four zero shader catches, recharge, and a shell impact outside the real hull. All 252 PC ship files match the tracked manifest. No placeholder capture was accepted.

The legacy death-spawn probe returns exit 0 with zero stray spawns, but it logs two missing `spawn_frame` metadata errors on both unchanged main and run 4 under the same uncapped headless invocation. Main records 31 pictures and run 4 records 33, with every picture on the hull. This warning is not presented as a clean pass and was left outside the shield scope. The full destruction batch also returns exit 0, including its box and fleet GPU probes.

Ryan's visual approval and the issue 256 outside check remain pending. No commit, push or merge was made by this run.

## Sources and repeat

- `godot/fx/fx_ship.gd`: fitted envelope, matching hit BVH, material data and retained pool/view synchronization.
- `godot/fx/fx_shaders.gd`: faction masks, bounded face light, rim, patterned waves, refraction and contact.
- `godot/fx/textures/shield_crackle.png`: existing 16-frame, four-by-four charge mask; R is filament and G corona.
- `tools/blender/vfx/bake_shield_crackle.py`: retained deterministic source, seed 372, no external art.
- `godot/fx/textures/shield_bench.gd` and `.tscn`: real-state proof, cap calibration, feature controls, full-frame hit captures, low tier and 20-ship isolation.
- `tools/blender/vfx/measure_shields.py`: four-row sheets, phone comparisons and rendered-pixel measurements.

Use the installed Godot console executable, wrapped in `tools/pc/tmo.bat`, with `gpu_go.txt` still cleared. Run the surface scene twice with `--out DIR`; keep the second. `--faction ID --camera 170` narrows a preview. `--quality low` checks the fallback, `--stress` runs isolation, `--bursts ABSOLUTE_MOMENTS_JSON` uses this folder's `moments.json`, and `--headless ... --state-only` runs state checks. Timing launches take a solo GPU claim. Gate arguments are `--modes base,res_2160 --sessions 3 --warmup 120 --frames 720`.

All linked pictures and reports are copied into `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-372/shots`. Kept run-4 folders are `run4_proof`, `run4_delivered_hit`, `run4_phone_main`, `run4_phone_run3`, `run4_gate_main`, `run4_gate` and the separately named stress/low checks. Logs and temporary reference-file backups stay in TEMP. The capture metadata records SHA256 values for the production sources.

R129: callers keep the same hit-point dictionary and function signatures; impacts and the drawing use the same final skin. No save, rules-twin, UI or oracle refresh is due. GitHub still runs standing checks, Godot rules parity and Godot game checks. This worker did not start or claim those future GitHub runs.
