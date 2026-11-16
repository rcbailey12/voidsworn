# SH372 run 3: the full shield hit on a fitted skin

Refs #372. This completes the resumed PR 855 work to Ryan's R282 direction: keep the closed hull-derived skin and small gap, bring back main's bright impact and visible patterned shield, and keep shield hits free of smoke. The original local-only pattern requirement is superseded by run 3's whole-shield pulse. Ryan's look approval and the issue 256 outside check remain pending.

The shader now uses main's impact core, three expanding waves and short whole-shield pulse on PR 855's fitted skin. It restores the four faction mask strengths and removes the normal/depth suppression that reduced PR 855 to a pale patch. Pattern and fill fade after a hit. Rest remains Rim and Gap. The skin, matching hit BVH, BattleAPI pool/catch/routing synchronization, recharge detection, background bend, contact glow and smoke-free discharge are retained.

## Pictures

All faction and hit-pair sheets have three rows: original SH372 main, PR 855, run 3. Each is 1200 by 720 pixels. Camera 170 uses source pixels; camera 60 is a half-size crop and 26 is a third-size crop, matching the standing bench. The faction columns are rest, hit +0.08 s and fade +0.42 s. Raw strips retain all eight times through +1.0 s.

| Hull and faction | Battle 170 | Middle 60 | Closest 26 |
| --- | --- | --- | --- |
| V18_51, Sunward Crusade | [170](SH372_voidsworn_c170.jpg) | [60](SH372_voidsworn_c60.jpg) | [26](SH372_voidsworn_c26.jpg) |
| H8_23, Hegemony Navy | [170](SH372_hegemony_c170.jpg) | [60](SH372_hegemony_c60.jpg) | [26](SH372_hegemony_c26.jpg) |
| C15s_23, Ashfall Hullbreakers | [170](SH372_corsair_c170.jpg) | [60](SH372_corsair_c60.jpg) | [26](SH372_corsair_c26.jpg) |
| I15_11, Glasswrights | [170](SH372_ithar_c170.jpg) | [60](SH372_ithar_c60.jpg) | [26](SH372_ithar_c26.jpg) |

The same V16_37 cruiser and torpedo, shield versus hull: [170](SH372_hit_pair_c170.jpg), [60](SH372_hit_pair_c60.jpg), [26](SH372_hit_pair_c26.jpg). Each version shows shield impact +0.04 s, shield +0.27 s, then hull +0.27 s. The run 3 fixture uses real battle units and the rules weapon factory. It applies one-point torpedo contacts for the shield-only control, where armoured pierce rounds to zero, and depletes the pool through real hits for the hull control. Earlier rows retain the original standing-bench fixture, so control state and damage numbers differ. Timing, cameras, hull codes and production effect paths are the same. The run 3 capture now exits cleanly; the earlier main and PR 855 captures had the already-recorded native shutdown fault.

The frozen-clock controls show [Sunward bend and contact](SH372_voidsworn_mechanisms.jpg) and [Hegemony bend and contact](SH372_hegemony_mechanisms.jpg). Pattern and whole-pulse ablations are retained in the raw captures. The whole-pulse toggle changes pixels across the fitted skin, rather than only at the impact. Contact controls include a real game rock mesh. Refraction protects nearby hull detail; the bend appears over the diagnostic background. Hegemony's camera-170 bend changes no pixels because the opaque hull fills that ripple; cameras 60 and 26 show the bend.

## Brightness and hull visibility

The shield surface's added light is capped at **8.0 per linear RGB channel after faction tint and fx_gain, before blending and tonemapping**. All six hit slots, ripples, contact and rim share the cap. Composition against the opaque screen bounds overlapping skin faces. Rest uses its separate faint-rim material. The low tier keeps bounded alpha and omits screen and depth reads. Other production point sparks and bloom are separate effects, as on main.

The production material was measured with six overlapping hits, over-range tint, an unlit black hull, no bloom, linear tonemapping and exposure 0.02. A shader-written reference at the actual material cap uses the same pipeline. All four faction cases reached **8.000** without exceeding that reference. The lower 0.65 ceiling was not retained because it suppressed the requested hit.

Readability now samples the stronger +0.08 s frame, with shield-off and shield-on clocks held equal. The old report sampled +0.16 s. The unchanged diagnostic selects twelve interior patches and eight baseline-qualified silhouette pairs before looking at the lit image. Across twelve cases, **124/144 interior patches retain at least 30 percent of local contrast and 80/96 edge pairs exceed 1.25:1**. Six of twelve cases meet every old per-case diagnostic threshold. At camera 170 the interior counts are 9, 12, 12 and 11 out of twelve; edge minima are 1.788, 1.631, 1.569 and 1.177 respectively. The strong core temporarily washes out local details, especially on Glasswrights and at close zoom. These losses are reported for Ryan's review, not described as an all-pass readability result.

[measurements.json](measurements.json) records every sample, cap calibration, ablation and rest-to-hit crop measurement for all three versions. Peak added crop luminance at camera 170, main/run 3, is 0.921/0.919 Sunward, 0.998/0.935 Hegemony, 0.862/0.700 Hullbreakers and 0.992/0.952 Glasswrights. These full-crop measurements include bloom and engine animation and are supporting evidence, not a substitute for judging the smaller fitted shape in the sheets.

## Checks and cost

[performance.json](performance.json) gives the fresh main/run 3 comparison on the complete #207 scene: 1080p frame median and 4K GPU median against 12.5 ms. Each is the median of three session medians with 120 warm-up and 720 measured frames. Each version is launched twice and the second kept. Every measurement takes a solo GPU claim through tools/pc/tmo.bat. Photos retain the original SH372 main baseline d32713f288; the new timing baseline is main ba153932, with the same current world and PC assets as run 3.

The binding medians pass: **1080p frame 5.251 to 5.167 ms; 4K GPU 5.584 to 5.579 ms**. The other measured medians are 1080p GPU 2.539 to 2.569 ms and 4K frame 5.954 to 6.019 ms. These small differences are reported without claiming a speed improvement.

[verification.json](verification.json) records the checks run this time, their exits and the remaining reviews. The surface bench creates units through BattleAPI.new_battle_scenario, applies real hits and turns, and reads BattleAPI.view. It proves pool depletion, all four shader catches opening, and recharge closing the rim. The hit-pair hooks now also use real units, mkWeapon and applyHit. All 252 ship files matched the tracked manifest after copy-only refresh from build/godot. No placeholder hull was accepted.

## Files and repeat

- godot/fx/fx_shaders.gd: restored core, waves, whole-skin pulse and faction mask strengths, with bounded composition.
- godot/fx/fx_ship.gd: the new surface light ceiling; the fitted skin and pool sync are retained.
- godot/fx/textures/shield_bench.gd: peak-frame samples, whole-pulse control, cap calibration, complete-capture checks and real-state hit-pair hooks.
- tools/blender/vfx/measure_shields.py: three-row sheets, cap read from the actual material, peak/readability/ablation measurements and three-version hit pairs.
- docs/shots/look_bench/shields/: the sheets and evidence. The shield_crackle.png atlas and bake_shield_crackle.py source from PR 855 remain unchanged.

Wrap Godot launches in tools/pc/tmo.bat with gpu_go.txt still cleared. Run res://fx/textures/shield_bench.tscn with --out DIR twice and keep the second. Use --state-only with --headless, --quality low for the fallback, --faction ID for tuning, or --bursts ABSOLUTE_MOMENTS_JSON for the hit pair. Measure with measure_shields.py --before MAIN --previous PR855 --after RUN3 --bursts RUN3_PAIR --bursts-before MAIN_PAIR --bursts-previous PR855_PAIR --out SHEETS. The scene gate uses --modes base,res_2160 --sessions 3 --warmup 120 --frames 720.

All report-linked pictures and evidence are copied to C:/Users/rcbai/Downloads/voidsworn_test/board/issue-372/shots. The new raw kept folders there are run3_surface, run3_hit_pair, run3_low, run3_gate_main and run3_gate_final. Logs and scratch stay in TEMP. The accepted look-bench baseline is unchanged.

R129: production hit-point dictionaries, callers and signatures are unchanged; the same fitted skin follows hull motion. No saves, old-profile logic, rules, browser oracle, exported tables, UI or ship assets were edited. No oracle refresh is due. GitHub still runs standing checks, Godot rules parity and Godot game checks. Full rules/campaign parity was not repeated locally for this look-only change. No commit, push or merge was made by the worker.
