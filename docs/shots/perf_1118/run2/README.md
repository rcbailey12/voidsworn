# Issue 1070 performance evidence

The [Run 2 report](../../../../contrib/codex/perf_1118/run2/README.md) has the original timings, raw traces and reproduction steps. [Battle comparison](PERF1070_RUN2_BATTLE.jpg) · [High and Max storm comparison](PERF1070_RUN2_STORM.jpg)

## Run 3 cost baseline on main

Main revision `0c41f332c956040112361444597d02be99a40b75` contains the content-keyed fitted shield cache from issue 1130. Run 3 uses the preserved Run 2 fleet. All 259 installed ship files matched the installed manifest, and both the ship and generated asset manifests matched Run 2. The replay probe follows main's scene-gate build signature and keeps Run 2's event sequence, sampling windows and three-minute load allowance. The first attempt hit main's one-minute timeout before sampling.

The reference is for the flagship death (#1077), shield failure (#1078) and nebula wake (#1079). Use the same case, resolution, camera and timer when comparing a prototype. First-use results use 1080p Max and a fresh Godot process per session. The steady Scene 207 case uses 20 hulls and four launch wings, seeded volleys and the engagement camera. The dense storm case uses seed 4103, 31 storm hexes and 28 nebula hexes at radius 170. Its ships are idle and its weather runs live. The 4K cases render the 3D scene at 3840×2160 in the same 1920×1080 window.

### Cold start at 1080p Max

Each cell gives the median of the three session peaks and the worst frame across the three sessions, in ms. The first-hit row uses the full 2.3-second Run 2 window. The wreck row covers the submission frame and two frames on either side.

| Event | Shield | Run 2 patched | Run 3 on main |
|---|---|---:|---:|
| First shield hit window | Fitted | 8.049 / 9.382 | 20.911 / 35.591 |
| First shield failure | Fitted | 8.090 / 8.753 | 7.783 / 8.555 |
| First death and aftermath | Fitted | 12.947 / 13.868 | 9.753 / 10.934 |
| First wreck submission | Fitted | 9.030 / 13.868 | 6.109 / 8.693 |
| First shield hit window | Egg | 8.627 / 11.032 | 22.097 / 39.150 |
| First shield failure | Egg | 8.699 / 13.230 | 7.430 / 9.012 |
| First death and aftermath | Egg | 15.579 / 22.908 | 10.509 / 16.104 |

The first five fitted draw frames peaked at 5.458 ms across the three launches. The fitted window's 20.488 to 35.591 ms peaks began 589 to 946 ms after dispatch. The egg showed a similar pattern. At the longest fitted frame, the main process callbacks took 2.279 ms, render CPU took 1.391 ms and GPU took 2.289 ms. Pipeline counters stayed flat in all six shield-hit windows.

Two controls skipped the first shield hit and kept the shield hidden through the same 2.3-second window. They still peaked at 40.783 and 22.952 ms. The intervals before the first process callback were 34.579 and 18.889 ms, respectively. The hit-enabled control peaked at 21.057 ms, with 17.848 ms before the first callback. These later gaps account for the over-20 ms control samples. An aborted headless fixture check remained open during the initial main batch. The baseline uses the repeat after the process was closed. The initial traces are retained for comparison.

### Scene 207 and dense storm on main

Three fitted sessions per case, with 180 warm-up frames and at least 720 measured frames and eight seconds. Frame median and p99 are the medians across sessions. Worst is the longest individual frame. GPU median is the median of the session medians. Times are in ms.

| Fixture | Resolution | Frame median | Frame p99 | Worst frame | GPU median |
|---|---|---:|---:|---:|---:|
| Scene 207 Max | 1080p | 3.808 | 10.600 | 36.330 | 2.613 |
| Scene 207 Max | 4K | 6.188 | 13.507 | 40.943 | 5.746 |
| Dense storm Max | 1080p | 2.168 | 2.803 | 3.670 | 1.692 |
| Dense storm High | 1080p | 2.395 | 2.621 | 13.156 | 1.905 |
| Dense storm Max | 4K | 5.666 | 6.443 | 15.887 | 5.273 |
| Dense storm High | 4K | 7.128 | 7.651 | 10.117 | 6.768 |

Scene 207 passed the 12.5 ms gate at both resolutions, using the 1080p frame median and 4K GPU median. All six sessions stayed under Run 2's 50 ms worst-frame mark. The 1080p session medians were 8.409, 3.808 and 3.440 ms. The 4K GPU medians were 5.589, 5.758 and 5.746 ms.

### High storm rendering

High bounds each gas card to its existing height band before drawing and rejects fragments whose density cannot reach the original cutoff. It samples a 96³ table of the existing noise hash values at lattice corners, with the same eased interpolation. Samples beyond the table still use the original hash. The bake is reproducible with `godot --headless --path godot --script res://world/nebula_noise_bake.gd -- --gas-lattice`. The packaged asset matched the trial bake byte for byte.

| Resolution | High GPU on main | High GPU after | Max GPU on the same build | High frame median after | Max frame median on the same build |
|---|---:|---:|---:|---:|---:|
| 1080p | 1.905 | 1.277 | 1.689 | 1.910 | 2.195 |
| 4K | 6.768 | 4.421 | 5.239 | 4.865 | 5.634 |

High had the lower GPU median in every matched session at both resolutions. Its frame median was lower across sessions at both resolutions. The 4K High GPU medians were 4.421, 4.421 and 4.376 ms. Trimming cards alone reached 5.55 ms at 4K and still cost more than Max.

The second take from each source matched by eye at radii 170 and 26. The largest mean RGB channel difference was 0.125 of 255 at radius 170 and 0.645 of 255 at radius 26. The wider view also varies slightly between repeats. The review sheet is `PERF1070_RUN3_STORM.jpg`. [Pixel comparisons](../../../../contrib/codex/perf_1118/run2/raw/run3/look_differences.json)

The replay uses Vulkan Forward+, Godot 4.7.2 and the RTX 5080, with vsync off and one solo watchdog claim per process. Reuse the Run 2 staging method and preserve both asset manifests when overlaying main. Use `run.ps1 -Phase cold` for the six fresh launches and `run.ps1 -Phase baseline -Shapes fitted` with the `gate:max:1:base`, `gate:max:2:base` and `dense:<tier>:<scale>:native_lod` cases above. For the High still pair, use `proof.ps1 -StormHighOnly` on each staged source and `sheets.py --storm-high-only` to compare the second takes. [Replay tools](../../../../contrib/codex/perf_1118/) · [Main summary and control traces](../../../../contrib/codex/perf_1118/run2/raw/run3/main_summary.json) · [Storm summary](../../../../contrib/codex/perf_1118/run2/raw/run3/storm_summary.json)

The final standing suite recorded 73 passes, two known baselines (`findings_tests` and `oracle_drift_guard`) and one picture-provenance self-test failure. The picture self-test passed on its isolated rerun. The headless world and bench audit and shield-cache check both reported zero failures. The copied sheet and sidecar passed provenance verification.
