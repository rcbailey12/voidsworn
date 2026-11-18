# Issue 1070 performance investigation

## Baseline findings

Scene 207's fitted shield passed the 12.5 ms gate in all three 1080p Max sessions. Their frame medians were **7.798, 6.051 and 6.998 ms**. The egg sessions were **4.808, 10.099 and 11.607 ms**. The GPU medians across the launches were **2.625 ms fitted and 2.618 ms egg**. The 1080p GPU results in this mix of hits and idle shields do not show the 1.86 ms frame-time difference reported in PR 1060. CPU and frame pacing vary across the launches.

The biggest scene 207 misses were hitches. The fitted 1080p p99 was 22.463 ms. The longest 4K frame was 644.465 ms, with 631.108 ms between the main-thread process callbacks and a 6.108 ms GPU reading. The pipeline counters stayed flat through that sample. The breach overlay accumulated 673 ms over the session containing the longest hitch.

With shipped LOD at 4K Max, the station battle used **6.128 ms GPU** and the dense storm **5.348 ms GPU**. Dense-storm High used **6.934 ms**, or 1.586 ms more than Max. With full detail forced, the station and storm used 8.264 and 6.118 ms at 4K Max. The full-detail fitted scene 207 run used 5.835 ms.

[The baseline table](baseline.md) covers 24 requested setups and 12 supplemental full-detail setups. Each configuration has three sessions and the four timers' median, p95, p99 and worst. [Session and monitor data](summary.json) link back to the exact frame traces under [raw](raw/).

## Ranked costs

The largest observed stalls come first, followed by the largest measured GPU costs and the smaller controls. The GPU deltas come from the paired isolation sweep unless a profiler number is named. The whole-system switches give upper bounds on savings from that work. They can also affect other passes. Their individual savings do not add together.

| Rank | Cost and measurement | Expected gain | Confidence | Look or gameplay risk | Still to test |
|---:|---|---|---|---|---|
| 1 | Main-thread battle hitches. The 4K fitted worst sample spent 631.108 ms in process callbacks. Godot recorded repeated hull damage material builds and background breakup preparation. | Largest opportunity for reducing hitches. A sustained saving is unproven for the damage path as a whole. | High for the main-thread interval. Lower for the attribution of the individual worst frame. | Damage timing and hull appearance matter. | Trace material preparation and application during several long frames. |
| 2 | Dense 4K storm cards and transparency. Drawing without the cards lowered Max GPU time from 6.079 to 3.874 ms and High from 7.532 to 2.346 ms. High draws 314 cards and Max draws 137 plus seven fog volumes. | Up to 2.205 ms GPU at Max and 5.186 ms at High for the isolated card draws. | Medium. Single matched sweep with stable dense-storm baselines. | Cards carry much of the cloud's shape. | Compare a lower-overdraw implementation at the same cloud density and check the strike in motion. |
| 3 | Hull meshes, materials and LOD. Scene 207 uses 0.990 ms less GPU time with hull draw layers masked. Replacing the idle fleet's materials with a flat material saves 0.178 ms. Stock LOD saves 2.051 ms GPU at 4K in the station, 0.783 ms in the dense storm and 0.337 ms in scene 207 at 1080p. Station visible primitives fall from 16.70M to 3.94M and shadow primitives fall from 20.69M to 6.76M. | Stock LOD provides the largest geometry saving in the tested views where full detail is forced. | Medium. Draw and primitive counts agree with the GPU timings. | Silhouettes, small parts and damage-overlay alignment can change with distance. | Check camera transitions and cuts. Apply the full-detail rule to scene 207. |
| 4 | MSAA at Max. Going from 4× to 2× saved 0.550 ms GPU at 4K and 0.064 ms at 1080p. Turning MSAA off saved 1.284 and 0.244 ms respectively. At 4K, video memory fell from 3.61 GiB to 3.24 GiB at 2× and 2.85 GiB with MSAA off. | Start with the 0.550 ms GPU candidate at 4K. | Medium for GPU time. The sweep's 4K wall time did not improve at 2×. | Fine plates, wing edges and shield ripples can shimmer. | Compare the same flyby and shield hit at both sample counts. |
| 5 | Lights and shadows. The station directional and spotlight shadow pass cost 1.064 ms GPU at 1080p. The equivalent scene 207 pass was 0.200 ms. In scene 207, switching off shadow maps saved 0.140 ms GPU, and hiding lights saved 0.232 ms with shadows included. | Potential in the station's casters. Scene 207 gives much less back. | Medium. GPU profiler and shadow draw counts agree on scope. | Removing casts changes ship relief and the station's depth. | Isolate station cast geometry and light ranges at 4K. |
| 6 | Post effects. Disabling SSAO, SSIL, glow and SSR together saved 0.480 ms GPU in scene 207 at 1080p. Godot showed 0.050 ms for SSAO, 0.080 ms for SSIL and 0.061 ms for glow in the profiled run. | 0.480 ms GPU for the combined switch. | Medium for the group. | Glow and contact shading affect readability. | Test each pass at the same render resolution and preserve the hit and shield looks. |
| 7 | Fog grid and dust. In the dense 4K storm, the 64×128 fog grid saved 0.140 ms GPU, full fog disable saved 0.249 ms and masking dust saved 0.120 ms. | Small. The grid change is the candidate that keeps the fog enabled. | Medium for GPU timing. | A smaller fog grid can soften detail or make steps visible. | Watch the bolt light moving across the gas at both cameras. |
| 8 | Battle and ship process callbacks. Diagnostic suspension lowered the main callback median by 1.675 ms for the battle or 0.971 ms for all 24 ship views in this sweep. Turning off the full effects engine lowered it by 2.158 ms. The profiler also found over 34,000 trail-mesh calls in the 720-frame gate sample. | The switches show scope for CPU work. A safe per-frame saving needs a narrower change. | Low for the switch deltas because the CPU pace varied. High for the observed call counts. | These controls also suspend world stepping, nameplates, ship motion or effects. | Replay identical motion and account for the time in damage and trail allocations. |
| 9 | Shield surface and hit routes. Fitted versus egg differed by 0.007 ms GPU at 1080p Max and 0.027 ms at 4K Max. Masking the shield draw and injecting extra hits or failures shifted the 1080p GPU median by less than 0.2 ms in the sweep. | The measured steady GPU differences are small. | High for the repeated shape baselines. Low for the short event switches. | Shield hit location and response are part of the chosen look. | Remeasure sustained clustered hits and close shots separately. |
| 10 | Particles, breakup and fragments. Masking the sprite and streak pools saved 0.057 ms GPU, and masking the impact-fragment pool saved 0.026 ms. The death control raised the 1080p GPU median by 0.333 ms. Hiding 13 breakup fragments during the same event schedule saved 0.016 ms GPU. | Little steady GPU time in these draw groups in scene 207. | Low for the event sweep. | Fragments carry breakup motion and silhouette. | Compare the cold event tails and the main-thread geometry work. |

Masking the storm-specific cards, volumes, lights and bolt meshes together saved 0.853 ms GPU in the dense 4K Max replay. Masking the eight bolt meshes alone moved the GPU median by 0.078 ms in the slower direction. Weather timing and compensation between passes can move a small reading by this amount.

Code inspection suggests more work on allocations. The fitted shield caches its triangle arrays and recreates the mesh and ray collider for a repeated hull type. The ship effects calculate a shield transform even when the shield surface is hidden. Moving trails build new vertex and index arrays and clear and refill their mesh surfaces. These are hypotheses for targeted CPU tests, with no gain included in the ranking. [Shield and trail code](../../../godot/fx/fx_ship.gd)

The original isolation pass logged light-indexing errors after teardown in five draw-mask cases. The affected timing results above use replays with draw layers and visibility restored before freeing the scene. The flat-material replay pauses volleys so live damage cannot replace the test materials mid-sample. [Isolation pass and replays](summary.json)

## Look comparisons

The review sheets show camera 170, camera 26 and a 1:1 detail at camera 26. The MSAA and fog comparisons use the 4K 3D draw setting and retain the second capture launch. Ambient motion and HUD transitions can vary between the stills.

- 2× MSAA saved 0.550 ms GPU at 4K. The stills keep the fitted shield and show the close plate edges. [PERF1070_MSAA_2X](../../../docs/shots/perf_1118/PERF1070_MSAA_2X.jpg)
- Turning MSAA off saved 1.284 ms GPU at 4K. Some fine bright edges differ in the close crop, and movement is the remaining test. [PERF1070_MSAA_OFF](../../../docs/shots/perf_1118/PERF1070_MSAA_OFF.jpg)
- The smaller fog grid saved 0.140 ms GPU in the dense 4K storm. The close comparison shows a change in the density and detail of the fog. [PERF1070_FOG_64](../../../docs/shots/perf_1118/PERF1070_FOG_64.jpg)
- Stock mesh LOD saved 0.337 ms GPU in the 1080p scene 207 probe and 2.051 ms GPU in the 4K station probe. The sheet shows the 1080p scene 207 comparison. The shape of small hull parts during camera transitions remains the test. [PERF1070_LOD](../../../docs/shots/perf_1118/PERF1070_LOD.jpg)

## Godot profiler

At 1080p Max, the station's depth pre-pass, opaque draw and light shadows took **1.230, 1.612 and 1.064 ms** on the GPU, compared with **0.478, 0.696 and 0.200 ms** in scene 207. The dense storm's transparent pass took **0.577 ms**, compared with **0.271 ms** in scene 207. These are medians of the GPU profiler's printed samples. [Raw profiler log](raw/profile_fitted_s1_engine.log.gz)

The per-hull test changed one hull's draw layers at a time and restored them afterward. All 24 scene 207 rows returned to the same draw totals. The Pyre-Barge `C19_51` removed 23 visible and 23 shadow draw submissions. The Sunward dreadnought `V1b_r_23` removed 22 and 22. The full inventory and per-hull submissions are in the profile trace. [Profile trace](raw/profile_fitted_s1.jsonl.gz)

In 720 profiled scene 207 frames, Godot recorded 17,304 nameplate updates, 34,608 trail-mesh calls, 36,330 hull-motion calls and 412 damage-material builds. The damage path includes background work to prepare breakup geometry and a main-thread pass to apply the new hull surfaces and materials. The script profiler adds overhead and includes worker and nested time. Its call counts and names identify the work, and the separate timing runs establish the wall-clock cost. [Profile trace](raw/profile_fitted_s1.jsonl.gz)

The fitted 1080p Max baseline held a median 6,764 live objects and 1,165 resources, with peaks of 8,072 objects and 1,196 resources. It submitted a median 481 visible draws and 318 shadow draws and used 2.45 GiB of video memory. These monitors track live use. Source inspection identifies the places that create fresh meshes, materials and arrays. [Monitor readings](summary.json)

## First-use timing

The cold probes start a fresh Godot process and keep the game's normal loading and warm-up. The natural storm watcher starts before the battle loads. Its first flare can occur under the loading cover. The other effects are triggered in order when the cover lifts, with their own sampling windows. Each frame trace keeps the viewport timing, main callback interval and FX section counters. A synchronous event dispatch can land between callback intervals, so the FX counters also identify time spent inside the trigger.

Scene 207, 1080p Max, three fresh starts per shape. Each cell gives the median and worst of the three peak frame times in ms. The breakup row covers the two frames on either side of the first wreck submission and the submission frame itself.

| Window | Fitted median peak / worst | Egg median peak / worst |
|---|---:|---:|
| First shield hit | 167.806 / 201.798 | 124.482 / 182.391 |
| First shield failure | 12.160 / 13.207 | 9.864 / 12.748 |
| First impact fragment burst | 39.714 / 42.703 | 37.053 / 60.489 |
| First death and aftermath | 205.457 / 210.296 | 180.320 / 252.298 |
| First wreck submission | 34.777 / 35.654 | 33.131 / 41.029 |
| First natural storm flare during loading | 33.709 / 42.567 | 31.545 / 42.870 |

For example, the first fitted launch's shield-hit window contained a 167.576 ms frame. Of that, 158.378 ms were spent building breakup piece meshes as background work arrived. The renderer's pipeline counters stayed flat. The first death in the same launch took 166.071 ms inside its dispatch. This separates a hitch that happened near the shield hit from the work that occupied that frame.

Each fragment-burst probe emitted 18 impact fragments. Each death probe created a wreck. The cold rows in the summary include each timer's median, p95, p99 and worst. [Cold rows and frame traces](summary.json)

## Applied fix

Retain the alpha exterior shader in the battle's warm-up cache alongside the opaque exterior shader. The same shader code and uniforms serve the hull materials as before. Each of the six fitted Max baseline samples logged a late `exterior_alpha` creation. All six replay samples with the change reported zero late shader creations. The replay used the same scene 207 setup and both resolutions. [One-line fix](../../../godot/fx/fx.gd) [Trial data](summary.json)

| Scene 207 Max fitted | Baseline frame median / p99 / worst | Trial frame median / p99 / worst | Baseline / trial GPU median |
|---|---:|---:|---:|
| 1080p | 6.998 / 22.463 / 206.217 ms | 10.387 / 20.939 / 67.064 ms | 2.625 / 2.564 ms |
| 4K | 11.493 / 39.990 / 644.465 ms | 11.448 / 26.506 / 61.044 ms | 5.835 / 5.819 ms |

The 1080p trial medians were 10.371, 14.206 and 10.387 ms. The median across launches passed the 12.5 ms gate and one session exceeded it. The late shader result verifies the reuse. The shorter observed worst frames and slower 1080p median came from different launch batches, so they give a range of observed behavior for the trial.

The motion comparison used a critical macro hit on the I15_11 Glasswright hull, with 18 frames per camera and flashing setting. At camera 170, all pixels matched after removing the provenance stamps. At camera 26, the largest mean RGB channel difference was 0.00339 of 255, within the variation of a repeat on the original source in both flashing settings. Look Bench wrote the full reports and all four stamped strips with zero warnings before an access violation at shutdown in both revisions. The timing harness completed separately. [Motion comparison data](alpha_motion.json) [Look Bench input](alpha_proof_moments.json)

## Fixture and timing method

The benchmark uses main revision `be03488c5d03aabb0aec3480e949461c1c4f067e`, the NVIDIA GeForce RTX 5080 with driver 617.42, the AMD Ryzen 7 5800X, and Godot 4.7.2 stable `ed1daf0bf` with Vulkan and Forward+. The installed ship manifest SHA-256 is `bb6258bc3f2a8c9e530776c4fd9a228957462beee10a37db73a37da0dc6ff2d1`. The generated asset manifest SHA-256 is `34244bddf5ae0b792bfd99d2313afba5a8beb319661346cfcdf81651652708c5`.

The live shared project still had the older egg default. The staging script copied its installed ship assets and generated cache to TEMP and layered the assigned revision's tracked Godot files over that copy. All 259 installed files matched their manifest entries. The placeholder guard stops on any missing hull.

| Fixture | Workload |
|---|---|
| Scene 207 | Seed 4207, standard scene-gate engagement camera, 20 hulls and four launch wings, HUD and seeded faction volleys. Fitted and egg use the same scene and presentation schedule. |
| Dense storm | PR 994 method, using seed 4103 and the actual terrain generator's nebula condition. 31 storm tiles, 28 nebula tiles, radius 170, live weather, HUD hidden and idle ships. |
| Sector 3 station | The game's `s4` encounter, seed 4004, ten Sunward Crusade hulls against ten Hegemony Navy hulls. Engagement camera, HUD and seeded presentation volleys. |

Timing starts after the load cover lifts, a 2.5 second activity settle, and 180 warm-up frames. Each sample takes at least 720 rendered frames and eight seconds. Every process takes the watchdog's solo GPU claim. The order of the cases and shield shapes reverses on session two. Vsync and the frame limiter are off. At 4K the renderer draws a 3840×2160 3D scene through 2× viewport scaling, the method used by scene 207 and PR 994. The window and HUD stay at 1920×1080. The full-detail storm and station runs establish the comparison for the geometry probes. The default baseline runs those two fixtures at the shipped LOD threshold and scene 207 at its full-detail gate setting. Raw headers record the project rendering settings and each row records the effective quality settings.

- **Frame** is elapsed wall-clock time between rendered frames.
- **Main CPU** covers the engine's process callbacks between an early and late callback on the main thread.
- **Render CPU** is Godot's measured viewport rendering CPU time. The project uses Godot's Safe thread model, so these are separate intervals of work even when they run on the same OS thread.
- **GPU** is Godot's viewport timer. Its readback can lag the main thread. These four measurements overlap and should be read independently.

Percentiles are calculated within each session. The tables take the median of the session medians, p95s and p99s, and the highest individual worst frame. A switch's saving compares its matched baseline at the same quality and resolution. Switch deltas can overlap. The changed-node count, draw counters, FX event markers and memory counters in the raw data show what each switch actually reached.

## Reproduce

Use PowerShell 5.1 on the test PC, from the repo root. Choose a fresh output folder under TEMP. Staging takes the baseline from `HEAD`, including any files with edits in the checkout. The runs use the installed Godot 4.7.2 console build and the repo watchdog for every GPU launch. The watchdog waits for `gpu_go.txt` clearance and an empty GPU slot pool.

```powershell
$work = Join-Path $env:TEMP ("voidsworn1070_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
powershell -NoProfile -ExecutionPolicy Bypass -File contrib/codex/perf_1118/stage.ps1 -Work $work
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase baseline
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase profile -Runs 1
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase switches -Runs 1
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase cold
python contrib/codex/perf_1118/summarize.py $work contrib/codex/perf_1118
```

`-Cases` takes one or more `fixture:quality:scale:variant` strings. Use `-Label` for a fresh run directory. The profiled launch enables Godot's script and GPU profilers and has its own raw trace. Its diagnostic time is excluded from the timed comparisons.

The alpha replay stages the working copy's `godot/fx/fx.gd` over the temporary project's copy and measures `gate:max:1:base` and `gate:max:2:base` with `-Phase baseline -Label alpha_trial -Shapes fitted`. The motion check uses the existing Look Bench with the [I15_11 input](alpha_proof_moments.json). Two launches per source provide the motion comparisons and the repeat controls. The analysis restores the pixels beneath the provenance stamps before comparing them.

## Checks

The standing checks passed on the patched working tree with 67 passes and two known baselines, `findings_tests` and `oracle_drift_guard`. `git diff --check` passed. The delivery check verified the three sessions per baseline and alpha trial setup, the raw trace and probe hashes, the motion comparisons, and all four 1280×720 sheets and sidecars in both output locations.
