# SH372: shield surface

Refs #372. Before is unchanged main at `d32713f288`. The accepted look-bench baseline is not changed.

The shield now uses a closed skin sampled from the actual hull BVH, with a small outward gap. Hits and the drawing use the same skin. A resting ship has only its faint faction rim. The real BattleAPI view supplies `shp`, `shMax` and the four derived catches; an empty pool opens every side. Routing already changes those catches. Recharging the pool, rather than a rise in their sum, triggers the closing shimmer.

The four existing faction patterns are local masks. Three soft wave fronts, a depth contact glow and the baked charge discharge appear around the hit. The active material refracts the opaque background and composes bounded light over it. It does not repeatedly add light from overlapping folds of the skin. Faint light is feathered at the silhouette; nearby hull detail is protected from refraction. Rest and low-quality shader variants omit screen reads. Low also omits depth contact glow. Hull hits keep their existing gas and thrown matter. The Hullbreaker shield break no longer emits its old dirty smoke puff.

## Pictures

Each sheet is 1200 pixels wide and at most 660 pixels high. Camera 170 comes first and uses source pixels. Camera 60 is a half-size crop; camera 26 is a third-size crop, as on the standing bench. The strips show rest, hit +0.08 s and fade +0.42 s. Raw strips retain all eight captured times, including +0.03 s.

| Hull and faction | Battle 170 | Middle 60 | Closest 26 |
| --- | --- | --- | --- |
| V18_51, Sunward Crusade | [170](SH372_voidsworn_c170.jpg) | [60](SH372_voidsworn_c60.jpg) | [26](SH372_voidsworn_c26.jpg) |
| H8_23, Hegemony Navy | [170](SH372_hegemony_c170.jpg) | [60](SH372_hegemony_c60.jpg) | [26](SH372_hegemony_c26.jpg) |
| C15s_23, Ashfall Hullbreakers | [170](SH372_corsair_c170.jpg) | [60](SH372_corsair_c60.jpg) | [26](SH372_corsair_c26.jpg) |
| I15_11, Glasswrights | [170](SH372_ithar_c170.jpg) | [60](SH372_ithar_c60.jpg) | [26](SH372_ithar_c26.jpg) |

The frozen-frame controls show the effect itself: [Sunward bend and contact](SH372_voidsworn_mechanisms.jpg), [Hegemony bend and contact](SH372_hegemony_mechanisms.jpg). The lower pair introduces the game's rock mesh at the shield intersection. The diagnostic checker is an opaque background used only for the controls, not the readability samples.

The same torpedo and V16_37 cruiser, shield versus hull: [170](SH372_hit_pair_c170.jpg), [60](SH372_hit_pair_c60.jpg), [26](SH372_hit_pair_c26.jpg).

## Brightness and readability

The total added shield light is capped at **0.65 per linear RGB channel, after faction tint and fx_gain, before tonemapping**. Core, ripple, rim and contact share this ceiling. It applies even when six hits and several folds overlap. Refraction moves existing scenery light; it is not added shield light.

The production material was rendered with six overlapping hits, over-range tint, an unlit black hull, no bloom and linear tonemapping. Exposure 0.25 avoids clipped measurement pixels. A second render writes a known 0.65 directly from a reference shader through the same pipeline. This avoids confusing Environment's UI colour conversion with linear shader output. All four faction cases reached 0.650 without exceeding the reference.

At each camera, the shield-off and shield-lit samples hold the same effect clock, hull pose and other materials. Twelve interior feature patches and eight baseline-qualified silhouette pairs are chosen from the unshielded image and the rendered hull mask before inspecting the lit image. All 12 cases retained at least 30 percent of local contrast at all 12 interior samples, and all 96 edge pairs exceeded 1.25:1. The lowest measured edge contrast was 1.257:1. The 170 cases' minima were 2.036, 2.004, 1.589 and 4.722 respectively. Pixel coordinates, contrasts, cap calibration and the bend/contact/pattern ablations are in [measurements.json](measurements.json).

## Cost and verification

[performance.json](performance.json) contains the binding #207 comparison: 1080p frame time and 4K GPU time against 12.5 ms. Each number is the median of three session medians, with 120 warm-up and 720 measured frames per session. Both versions were run twice and the second run kept. The additional isolation uses 20 real shielded ships at rest and hit together, at 1080p and 4K; it is not substituted for the full storm battle, HUD, mixed fleet and running volleys.

The exact final check outcomes are in [verification.json](verification.json). The pixel bench creates units with `BattleAPI.new_battle_scenario`, applies real hits and turns, and synchronizes through `BattleAPI.view`. It checks pool depletion, the shader's four zero catches, and recharge. No run, battle, save or pick state is typed as a fixture. Ship files were copied from `build/godot` before import; all 252 tracked manifest entries matched. No placeholder hull was accepted.

The hit-pair capture has a recorded limitation: it saves all six 18-frame strips, then Godot exits with `0xC0000005` and reports five unreleased shaders. Restoring both production files from unchanged main and using the same capture driver produces the same fault. The kept second run still supplies the actual rendered pixels, but its process exit is **not** counted as a passed check. The cause of that shutdown fault is not claimed to be repaired here. The regular surface probe and the #207 runs exit normally.

## Sources and repeat

- `godot/fx/fx_ship.gd`: skin, matching hit BVH, faction material data and pool/view synchronization.
- `godot/fx/fx_shaders.gd`: local masks, ripples, depth contact, bounded composition and lower variants.
- `godot/fx/textures/shield_crackle.png`: 16 frames, four by four; R is the hot filament and G its corona.
- `tools/blender/vfx/bake_shield_crackle.py`: deterministic Pillow bake, seed 372; no smoke and no external art.
- `godot/fx/textures/shield_bench.gd` and `.tscn`: real-state surface proof, cap calibration, controls, low variant and 20-ship isolation. `--bursts` reuses the standing bench's production moment driver and lighting with `moments.json` from this folder.
- `tools/blender/vfx/measure_shields.py`: measurements and labelled sheets.

Worker commands use the installed Godot console executable and the PC's ComfyUI Python. Wrap GPU runs in `tools/pc/tmo.bat`, one at a time, with the GPU go still cleared. Run the surface scene with `--out DIR`, repeat into a second directory, and keep the second. Add `--quality low` for the fallback, `--stress` for isolation, or `--bursts ABSOLUTE_MOMENTS_JSON` for the hit pair. `--headless ... --state-only` runs the state check. Measure with `measure_shields.py --before BEFORE --after AFTER --bursts HIT_PAIR --out SHEETS`. Frame-gate arguments are `--modes base,res_2160 --sessions 3 --warmup 120 --frames 720`.

All linked pictures and measurement reports are also copied into `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-372/shots`. Raw kept folders there are `before_final`, `proof`, `hit_kept`, `gate_before`, `gate_final`, `stress_before` and `stress_delivered`. Logs and scratch remain in TEMP.

R129: callers retain the same hit-point dictionary and function signatures; the skin follows hull motion. No saves, rules, browser oracle, exported tables, UI or ship assets were edited, and no oracle refresh is due. GitHub will still run standing checks, Godot rules parity and Godot game checks. Ryan's visual approval and the issue 256 outside check remain pending. Nothing was committed or pushed by this run.
