R297 keeps main's egg shield as the default, removes the remaining Hullbreaker shield-collapse smoke, and adds the fitted surface as an option. Hull-hit effects are unchanged.

Game files: `godot/fx/fx_ship.gd` and `godot/fx/fx_shaders.gd`. The shield fragment shader, including its flash, faction pattern, ripple, fade and timing, is unchanged. Only PR 855's surface mesh and its hit intersection were ported. Select the alternative with project setting `rendering/effects/shield_shape="fitted"` or environment override `VS_SHIELD_SHAPE=fitted`; the default is `egg`.

Main already uses energy crackle for ordinary shield hits. Its remaining smoke emitter was the four kind-3 sprites in the Hullbreaker collapse. Ordinary shield hits and hull hits therefore match main exactly; the collapse comparison shows the smoke removal.

Each sheet names its ship, source revision and stage. Frames are impact, +0.1 s, +0.3 s and +0.6 s relative to the bench's impact anchor; collapse sheets use the collapse event. All use one Sunward torpedo shot, the standing look bench's fixed clock and seeds, and the same target cruiser before and after. Second runs are retained.

| Ship | Egg before / after, camera 170 | Egg / fitted, camera 170 | Egg / fitted, camera 60 | Current hull hit, cameras 170 and 60 |
|---|---|---|---|---|
| V16_37, Sunward Crusade | [Strip](V16_37_shield_before_after_c170.png) | [Shapes](V16_37_egg_vs_fitted_c170.png) | [Shapes](V16_37_egg_vs_fitted_c60.png) | [Hull](V16_37_hull_c170_c60.png) |
| H9_23, Hegemony Navy | [Strip](H9_23_shield_before_after_c170.png) | [Shapes](H9_23_egg_vs_fitted_c170.png) | [Shapes](H9_23_egg_vs_fitted_c60.png) | [Hull](H9_23_hull_c170_c60.png) |
| C15s_23, Ashfall Hullbreakers | [Strip](C15s_23_shield_before_after_c170.png) | [Shapes](C15s_23_egg_vs_fitted_c170.png) | [Shapes](C15s_23_egg_vs_fitted_c60.png) | [Hull](C15s_23_hull_c170_c60.png) |
| I15_11, Glasswrights | [Whole bubble](I15_11_shield_before_after_c170.png) | [Shapes](I15_11_egg_vs_fitted_c170.png) | [Shapes](I15_11_egg_vs_fitted_c60.png) | [Hull](I15_11_hull_c170_c60.png) |

Hullbreaker collapse: [camera 170](C15s_23_collapse_before_after_c170.png), [camera 60](C15s_23_collapse_before_after_c60.png).

The Glasswright egg needs a wider crop. Its compact shield sheets show the complete bubble at 52 percent of the source cells. These separate camera-170 strips preserve native 1080p pixels: [main before](I15_11_native_main_c170.png), [default egg after](I15_11_native_egg_c170.png), [fitted option](I15_11_native_fitted_c170.png). They are 2048 by 610; the other sheets are 1200 by 720. No review picture is taller than 720 pixels.

| Scene-gate setting | 1080p frame medians, ms | 4K GPU medians, ms | Result |
|---|---|---|---|
| Main reference, one session | 4.264 | 5.593 | PASS |
| Default egg, three sessions | 4.598 to 6.553 | 5.552 to 5.583 | PASS |
| Fitted option, three sessions | 5.719 to 6.287 | 5.539 to 5.572 | PASS |

The gate is 12.5 ms. Each mode uses 120 warm-up frames and 720 measured frames. The standing 20-ship storm scene ran through the watchdog with an exclusive GPU claim. `res_2160` draws the 3D scene at 3840 by 2160 with the standing bench's 1080p HUD. Raw measurements: [main](gate_main.json), [egg](gate_egg.json), [fitted](gate_fitted.json). Small differences do not establish a speed gain.

Checks and evidence:

- Standing checks: 60 PASS, two recorded KNOWN results, zero new failures. The known results are the seven listed findings and 12 listed constant differences.
- `godot/fx/test/check_destruction.bat`: exit 0, including geometry, staging, flash-area, hit recipes, stray-puff guard, inside and fleet probes. The spawn guard records all 31 pictures, with zero stray spawns.
- Both settings on the four real cruisers: hit strength, life and spread preserved; 32 fitted collider rays match the visible surface; no shield impact or collapse smoke/gas sprites.
- All 16 standard ordinary shield/hull strips, plus both wider Glasswright strips, match main pixel for pixel. All six pairs of capture runs repeat exactly. The complete shield fragment shader also matches main byte for byte.
- All 21 final pictures pass provenance verification and the height check. Source file hashes, check rows and pixel results are in [checks.json](checks.json); capture settings are in [capture_settings.json](capture_settings.json). The standing bench reads [moments.json](moments.json) and [moments_wide.json](moments_wide.json).

Existing errors left outside this shield job: `death_spawn_check.gd:132` logs two missing `spawn_frame` metadata errors. Both occur on unchanged main as well; both runs still report `DEATH_SPAWN PASS`, 31 recorded pictures and zero check errors. Main and both variants also log the same existing `exterior_alpha` late shader. Neither is introduced by this patch.

The identical sheets and evidence copies are in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-908\shots`. Raw inputs are `main_valid_r2`, `egg_r2`, `fitted_r2` and the three `*_wide_r2` folders. The interrupted `main_r1` setup attempt had missing texture dependencies and is excluded from every final sheet. Scratch originals remain in TEMP; no PC files were deleted. No requested capture or check was skipped. No commit or push was made.
