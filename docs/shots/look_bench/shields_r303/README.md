R303: fitted shields follow the hull, and hits ripple over the shield surface. The egg remains the default.

Confirmed causes: the old 64 by 32 sphere sampled rays from a single core, then smoothed their radii six times. That cannot follow deep waists or open rings, and tall parts pull the envelope outward. The visible hit disc was the separate `fx.ring` in `_shield_impact`, aligned to the shot normal. Collapse also had explicit discs and an indirect disc in the soft `fx.pop` fallback.

`fx_ship.gd` now offsets samples of the real hull on a uniform grid, flood-fills sealed cavities, and extracts one closed mesh with shared triangle edges. The actual visible mesh supplies the hit BVH. Ring-centre misses aim at real hull instead of falling back to an invisible egg. Mesh arrays are cached. `fx_weapons.gd` removes only the shield impact disc. `fx_shaders.gd` carries the fading travelling bands in hits[]. Collapse uses that same path. The egg build, palette, patterns, rim, core glow, regen and break shader remain unchanged outside the intended hit ripple. The method is recorded in `docs/playbooks/effects.md`.

Pictures use current A17 and E12 exports and installed H9, identically before and after. Main code is d5ee38bfd974907ced8d24e93351f2f9e8309723. After pictures identify the uncommitted working revision in their labels and sidecars. The E12 fixture explicitly enables a shield, using its engine tint and existing lattice style, because Eclipse normally has no shield. This fixture is identical before and after and is not a game change. Diagnostic blue views show mesh geometry, not a new shield colour.

Each version was captured twice. All 24 strip pairs repeat pixel for pixel; the second runs supply the sheets. Times are impact, +0.1, +0.3 and +0.6 s. Camera 170 cells preserve native 1080p pixels; camera 60 uses a wider 900 by 600 source crop scaled to 300 by 200, identically for both shapes and versions, so the whole egg and ripple stay in frame. Every review image is at most 720 pixels tall.

| Ship | Main 170 | R303 170 | Main 60 | R303 60 | Skin alone, side and top |
|---|---|---|---|---|---|
| C15s_23, A17, Hullbreaker | [Before](C15s_23_main_egg_fitted_c170.png) | [After](C15s_23_after_egg_fitted_c170.png) | [Before](C15s_23_main_egg_fitted_c60.png) | [After](C15s_23_after_egg_fitted_c60.png) | [Geometry](C15s_23_fitted_skin_side_top.png) |
| H9_23, Hegemony | [Before](H9_23_main_egg_fitted_c170.png) | [After](H9_23_after_egg_fitted_c170.png) | [Before](H9_23_main_egg_fitted_c60.png) | [After](H9_23_after_egg_fitted_c60.png) | [Geometry](H9_23_fitted_skin_side_top.png) |
| D21_23, E12, Eclipse ring | [Before](D21_23_main_egg_fitted_c170.png) | [After](D21_23_after_egg_fitted_c170.png) | [Before](D21_23_main_egg_fitted_c60.png) | [After](D21_23_after_egg_fitted_c60.png) | [Geometry](D21_23_fitted_skin_side_top.png) |

| Mode | 1080p frame medians, ms | 4K GPU medians, ms | Result |
|---|---|---|---|
| Main egg | 4.393 to 5.639 | 5.318 to 5.348 | PASS |
| R303 default egg | 3.731 to 4.560 | 5.285 to 5.342 | PASS |
| R303 fitted | 3.846 to 4.225 | 5.302 to 5.323 | PASS |

The binding gate is 12.5 ms. All three modes used an exclusive GPU claim, three sessions, 120 warm-up frames and 720 measured frames per mode and session. The standing 20-ship storm scene uses a 1080p window, with the 3D scene at 3840 by 2160 in res_2160. These small differences do not establish a speed gain. Raw results: [main](gate_main.json), [egg](gate_egg.json), [fitted](gate_fitted.json).

First scene builds: main 18.2 s, default egg 17.1 s, fitted 33.2 s. Fitted meshes cost extra to generate on first use; later builds reuse their cached arrays. This is measured loading cost, separate from the frame gate.

| Mesh | Triangles | Connected pieces | Edges not shared by exactly two faces | Median gap along length, world units |
|---|---|---|---|---|
| C15s_23 | 131,612 | 1 | 0 | 0.582 to 0.620 |
| H9_23 | 60,652 | 1 | 0 | 0.379 to 0.404 |
| D21_23 | 90,184 | 1 | 0 | 0.257 to 0.307 |

The mesh retains the E12 ring openings and the C15s waists. Fine surface relief is rounded at the sampling resolution, about 0.24 world units. Gap measurements sample 128 mesh vertices and 128 triangle centres against the original hull triangles, not bounding boxes. Per-point minima and maxima, length bins and triangle counts are in [checks.json](checks.json).

- Standing checks: 60 PASS, two recorded KNOWN results, zero new failures.
- Destruction suite: PASS, including geometry, planes, staging, smoke, flash area, hit recipes, spawn guard, playtest, blockers, inside and fleet GPU probes. The spawn guard records 36 pictures, zero stray spawns and zero check failures.
- Surface probe: PASS for both shapes and normal/reduced flashing. All 432 fitted contacts land on the visible skin within 0.001 world units. Impact and collapse emit zero flat discs and no smoke/gas.
- Egg build and shader outside the hit ripple: unchanged. Documentation paths and whitespace checks: PASS.
- All 15 final pictures pass provenance and height checks. Seeds, source and asset hashes, fixture details and harness hashes are in [capture_settings.json](capture_settings.json).

Existing main issues left outside this shield change: death_spawn_check logs three missing spawn_frame metadata errors on unchanged main and on the repair, while still reporting PASS. The scene gate also logs the existing exterior_alpha late shader in all three modes. An initial scratch capture/probe setup had missing imports or fixture fields, and the first destruction run lacked its picture stamp environment; those setup attempts are excluded from final evidence.

The supplied checkout lacks the requested issue-928 base. No merge, commit or push was made. The complete three-file shield patch applies cleanly to origin/codex/issue-928 under git apply --check, so it preserves that job's hull-hit changes when integrated. The runner or Board still needs to supply the base.

No requested picture or check was skipped. Identical sheets, structured results, retained raw second-run strips and logs are saved under C:/Users/rcbai/Downloads/voidsworn_test/board/issue-929/shots. Scratch projects and failed setup attempts remain in TEMP and are not review evidence.
