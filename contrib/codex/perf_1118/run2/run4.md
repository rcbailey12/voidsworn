# Issue 1070, run 4

Scene 207, 1080p Max on the RTX 5080, Godot 4.7.2 and Vulkan Forward+. The harness measures from battle construction until the loading cover lifts, then fires the same shield hit, shield failure, fragment burst and death sequence. Every launch used the solo watchdog. The two sources use the preserved Run 2 fleet and generated assets. The baseline is `fd1aa1ff83693afabd0eb758e619ee843fa9d44a`. [Cold-start harness](../perf_1118.gd)

## Timings

| 1080p Max | Matched baseline | Patched |
|---|---:|---:|
| Fitted load, first launch from an empty profile | 71.960 s | 46.308 s |
| Fitted load, relaunch median | 55.777 s | 29.596 s |
| Egg load, relaunch median | 26.924 s | 28.453 s |
| Fitted first fragment frame, worst launch | 38.180 ms | 7.754 ms |
| Egg first fragment frame, worst launch | 37.248 ms | 11.900 ms |
| Fragment window across both shapes, worst frame | 38.180 ms | 14.873 ms |

The empty-profile comparison uses one fitted launch per source. The fitted relaunch medians use two baseline and three patched sessions. The egg medians use three per source. Every patched frame in the 2.3-second fragment window stayed under 16 ms. Egg relaunches were 1.529 s slower than matched main and stayed below the historical Run 2 median of 34.3 s. The fitted empty-profile launch beat the historical 57.6 s median by 11.3 s.

The fitted cache held 12 unique skins, 26.8 MiB total. A box and a torus produced byte-identical baked surface arrays on the original and patched code. The disk round trip retained those arrays. Truncating a test entry forced a cache miss, and its replacement round-tripped exactly.

[Per-session summary](raw/run4/summary.json) · [Raw samples and GPU readings](raw/run4/)

## Look Bench

The H9_23 fitted shield ripple and D21_23 hull impact match by eye at radii 170 and 26. The second shield strips are pixel-identical. The largest mean channel difference in either hull-impact strip is 0.379 out of 255. Both patched Look Bench takes logged one late damage shader. The patched cold battle runs logged zero. [Before-and-after sheet](../../../../docs/shots/perf_1118/run2/PERF1070_RUN4_LOOK.jpg) · [Pixel comparisons](raw/run4/look_differences.json)

## Code

- Fitted shields reuse the marching-tetrahedra cases and build new geometry on workers while the loading cover is up. The main thread finishes the normals and poses the render mesh and ray collider together. The disk cache keys the unposed surface on the hull triangles, bounds, engine version and bake version. A missing or damaged entry triggers a bake. The saved surface keeps every vertex attribute. [Shield setup](../../../../godot/fx/fx_ship.gd) · [Disk cache](../../../../godot/fx/fx_shield_cache.gd)
- Battle FX setup allows up to eight cut workers and a 16 ms piece-build budget under the cover. Impact fragments use the original paint and UVs from the shared hull-array cache. Loading primes those arrays and draws the painted fragment pipeline. [Battle FX setup](../../../../godot/fx/fx.gd) · [Impact fragments](../../../../godot/fx/fx_fragments.gd)
- Damage shaders take the source hull's fog setting at creation. The nebula policy handles custom hull materials and overlays. [Damage shaders](../../../../godot/fx/fx_hull.gd) · [Nebula policy](../../../../godot/world/nebula_hulls.gd)

## Reproduction

Stage two copies of the preserved Run 2 project. Keep the installed `assets/ships/manifest.json` from the preserved fleet when overlaying the tracked base. Its SHA-256 is `bb6258bc3f2a8c9e530776c4fd9a228957462beee10a37db73a37da0dc6ff2d1`. The generated asset manifest is `34244bddf5ae0b792bfd99d2313afba5a8beb319661346cfcdf81651652708c5`. [Staging method](README.md#reproduction)

Run `run.ps1` with `-Phase cold` and a private `APPDATA` directory for each source. Use an empty profile for the first fitted launch. Reuse each source's profile for the subsequent runs. This keeps the installed game's options and caches outside the test. The first fragment frame is the one where the harness sees the pool's emitted count increase. The wider window records every frame for 2.3 seconds after issuing the volley. [Timing launcher](../run.ps1)

For the picture, run `res://bench/look_bench.tscn` twice per source at fixed 60 fps, with fitted shields and `--part moments --only w_hbattery_void_shield,w_hbattery_void_hull`. The sheet uses the second takes at radii 170 and 26.

## Checks

Five headless checks passed on the patched project: shield cache, hit fragments, world and bench audit, destruction staging, and FX smoke. Both copies of the sheet passed provenance verification. Run 4 uses the cold-start gate, so the earlier steady 4K pass was outside this run.

The standing suite recorded 75 passes, two known baselines (`findings_tests` and `oracle_drift_guard`), and a Windows runner test that timed out waiting for its stub agent. The isolated runner retry passed all 134 checks.
