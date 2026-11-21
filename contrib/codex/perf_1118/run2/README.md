# Issue 1070, run 2

[Run 4 battle-load and fragment results](run4.md)

The replay used the preserved Run 1 fleet. Both the installed ship manifest and the generated asset manifest matched Run 1. The saved Run 2 before timings use `b7e82cdd25744d9315daabc02fb1c84a81c5a433`. The resumed work uses the merged base `950e1a2f8435e4da702bcbe9104546a9ac2168ac` with the Run 1 assets.

## Code changes

- Battle loading prepares the fleet's base breakup geometry, piece materials and colliders before play. Repeated hulls share their original mesh arrays. Fracture geometry still uses each ship's seed. Workers handle recuts for live damage and lance hits, with one main-thread budget for finished pieces across the fleet. [Loading cover](../../../../godot/scenes/battle/battle.gd) · [Effects warm-up](../../../../godot/fx/fx.gd) · [Breakup](../../../../godot/fx/fx_death.gd)
- Hull materials share their paint and shader setup by source material, hull scale and organic style. Each live surface keeps its material between hits and updates its own cut and pose uniforms. Each wreck owns its power-down and cooling state. [Damage application](../../../../godot/fx/fx_breach.gd) · [Hull materials](../../../../godot/fx/fx_hull.gd)
- Trails submit geometry when the sample history changes. The shader advances the same 2.6-second age between submissions. Hidden shields skip the transform calculation, and fitted shields share their render mesh and ray tree within the battle. Each ship still owns its shield hit uniforms. [Ship effects](../../../../godot/fx/fx_ship.gd) · [Trail shader](../../../../godot/fx/fx_shaders.gd)

## Cold starts at 1080p Max

Three fresh Godot processes per shield shape on each source. Each cell shows the median session peak and the worst session peak in ms. The wreck row covers two frames either side of the first wreck submission. [Run 1 timing](../summary.json) · [Run 2 before](before.json) · [Raw traces](raw/)

| Window | Shape | Run 1 | Run 2 before | Patched |
|---|---|---:|---:|---:|
| First shield hit | Fitted | 167.806 / 201.798 | 19.876 / 22.526 | 8.049 / 9.382 |
| First shield failure | Fitted | 12.160 / 13.207 | 7.695 / 7.740 | 8.090 / 8.753 |
| First impact fragment burst | Fitted | 39.714 / 42.703 | 32.406 / 34.376 | 34.387 / 40.887 |
| First death and aftermath | Fitted | 205.457 / 210.296 | 173.498 / 175.194 | 12.947 / 13.868 |
| First wreck submission | Fitted | 34.777 / 35.654 | 6.076 / 6.135 | 9.030 / 13.868 |
| First natural storm flare | Fitted | 33.709 / 42.567 | 24.618 / 36.088 | 7.473 / 10.124 |
| First shield hit | Egg | 124.482 / 182.391 | 21.129 / 24.042 | 8.627 / 11.032 |
| First shield failure | Egg | 9.864 / 12.748 | 8.172 / 11.490 | 8.699 / 13.230 |
| First impact fragment burst | Egg | 37.053 / 60.489 | 34.218 / 35.786 | 41.003 / 56.783 |
| First death and aftermath | Egg | 180.320 / 252.298 | 155.141 / 195.898 | 15.579 / 22.908 |
| First wreck submission | Egg | 33.131 / 41.029 | 12.896 / 32.013 | 14.306 / 22.908 |
| First natural storm flare | Egg | 31.545 / 42.870 | 28.013 / 29.156 | 9.950 / 10.235 |

The measured work before the loading cover lifted rose from a median of 43.6 to 57.6 seconds with fitted shields and from 20.2 to 34.3 seconds with egg shields, comparing the saved Run 2 before batch with the patched batch. Each patched death produced a wreck.

In the fitted cold traces, the median peak spent building breakup meshes during the first shield-hit window fell from 4.224 ms in the saved Run 2 before batch to zero. Median peaks fell from 143.150 to 4.136 ms for the death dispatch and from 145.748 to 3.139 ms for power-down work. The two timings overlap.

## Scene 207 and dense storm

Three solo RTX 5080 sessions per setup, with fitted shields, 180 warm-up frames and at least 720 measured frames and eight seconds. Frame cells give median / p99 / worst in ms. Median and p99 are the medians of the three session statistics. Worst is the longest frame in any of the three sessions. [Run 1](../summary.json) · [Run 2 before](before.json) · [Patched timings](after.json) · [Raw traces](raw/)

| Fixture | Run 1 frame | Run 2 before frame | Patched frame | GPU median, Run 1 / Run 2 before / patched |
|---|---:|---:|---:|---:|
| Scene 207, 1080p Max | 6.998 / 22.463 / 206.217 | 4.364 / 10.676 / 68.475 | 5.881 / 11.304 / 39.776 | 2.625 / 2.625 / 2.645 |
| Scene 207, 4K Max | 11.493 / 39.990 / 644.465 | 6.797 / 18.245 / 50.093 | 6.611 / 13.038 / 44.282 | 5.835 / 5.835 / 5.907 |
| Dense storm, 4K Max | 5.970 / 6.858 / 11.417 | 5.806 / 6.590 / 8.829 | 5.915 / 7.406 / 11.133 | 5.348 / 5.288 / 5.350 |
| Dense storm, 4K High | 7.549 / 8.367 / 9.499 | 7.363 / 8.504 / 14.832 | 7.485 / 8.226 / 12.383 | 6.934 / 6.842 / 6.956 |

Scene 207 passed the 50 ms worst-frame target and improved both frame medians over Run 1. The 1080p frame median was 1.517 ms higher than the saved Run 2 before batch. The binding 12.5 ms scene gate also passed at both resolutions, using the 1080p frame median and the 4K GPU median.

## Cost of each fix

Three instrumented 1080p Max Scene 207 processes per source measure the CPU work and count allocations. The moving-trail probe uses 20 stand-in hulls and the same ship trail code, at a fixed speed and simulation step for 720 frames per process. CPU means are taken within each process, then the median across the three processes. [Scene 207 counters](after.json) · [Moving-trail probe](trail_cost.gd) · [Raw runs](raw/)

| Work measured | Merged base | Patched |
|---|---:|---:|
| Live hull damage materials created per Scene 207 session, median | 244 | 0 |
| Live damage application CPU per Scene 207 frame | 0.051 ms | 0.015 ms |
| Trail mesh submissions across 720 moving frames | 28,800 | 7,400 |
| Trail update CPU per moving frame | 8.390 ms | 2.252 ms |
| Shield pose calculations per Scene 207 frame | 24.02 | 1.69 |
| Shield pose CPU per Scene 207 frame | 0.077 ms | 0.020 ms |
| Fitted shield mesh and ray tree pairs allocated per battle | 16 | 13 |
| Fitted shield setup CPU for repeated hulls per battle | 163.864 ms | 0.060 ms |

The patched loads prepared 247 private live damage materials per battle. The shield probe saw the same 13 distinct hull types in both sources. The cold traces above isolate the breakup and power-down work around the first hit and death.

## Storm

The current High route uses five puffs per hex in expanded gas patches. Max uses two dimmer puffs and draws fog volumes. Across the dense fixture, this is 314 cards at High and 137 cards plus seven fog volumes at Max. In Run 1, masking the cards saved 5.186 ms at High and 2.205 ms at Max. The same card settings supply the current High cloud's shape, and Max's volume is a distinct layer. The performance patch leaves the routes as shipped. [Gas settings](../../../../godot/world/world_living.gd) · [Run 1 isolation and method](../README.md)

[PERF1070_RUN2_STORM](../../../../docs/shots/perf_1118/run2/PERF1070_RUN2_STORM.jpg)

## Look comparison

Scene 207 uses the same camera, installed V1b_r_23 hull, scripted travel and shield hit in both takes. The views at radii 170 and 26 and the shield hit match by eye. Their largest mean RGB channel differences are 0.350, 0.470 and 0.460 out of 255. The larger of the two repeat differences for each view is 0.249, 0.418 and 0.419. In the first wreck frame the same tear and pieces are visible, with variation in pose, lighting and debris between takes. The largest mean channel difference is 7.740 out of 255, within the patched repeat of 10.845. [Full-resolution pixel differences](look_differences.json)

[PERF1070_RUN2_BATTLE](../../../../docs/shots/perf_1118/run2/PERF1070_RUN2_BATTLE.jpg)

## Reproduction

The [Run 3 report](../../../../docs/shots/perf_1118/run2/README.md) uses the current main scene-gate interface. Use the Run 2 delivery checkout or the archived Run 2 probes in `raw/` when replaying an earlier source.

The timing runs use the [Run 1 probe and method](../README.md). The original installed fleet and generated assets are required. The manifests are `bb6258bc3f2a8c9e530776c4fd9a228957462beee10a37db73a37da0dc6ff2d1` and `34244bddf5ae0b792bfd99d2313afba5a8beb319661346cfcdf81651652708c5`. Use [stage.ps1](../stage.ps1) from the matching `b7e82cdd` checkout with the preserved assets, then overlay tracked Godot source from the revision under test and write that revision in `godot/build_info.json`. Keep the preserved asset manifest in both staged projects. Use the merged base for the matched isolation and picture controls and the patched source for the final timing and picture runs. Run the following from the repo root against a staged directory.

```powershell
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase cold
$cases = 'gate:max:1:base','gate:max:2:base','dense:max:2:native_lod','dense:high:2:native_lod'
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase baseline -Shapes fitted -Cases $cases
```

Use [proof.ps1](proof.ps1) once per staged source. Include `-Storm` on the base capture. The pictures use capture 2, and each source's repeat is measured against capture 1. Save the SHA-256 of `git diff --binary <base> -- godot` as `source_diff.sha256` in the patched staging directory. [sheets.py](sheets.py) reads the staged revision and diff hash, then composes and stamps the matched viewpoints.

After the timing and picture runs, use [diagnose.ps1](diagnose.ps1) with `-Label before_isolation` or `-Label after_isolation`. It adds the counters in [instrument.py](instrument.py) to the staged scripts, runs the 1080p fitted fixture in three processes, and restores those scripts. The narrow counters measure the work in each code path. The timing gate uses the separate runs without counters.

Run [trail_cost.ps1](trail_cost.ps1) with `-Before` and `-After` pointing to the two clean staged projects and `-Output` pointing to a fresh TEMP folder. It runs the fixed flight three times per source through the solo watchdog.

## Checks

The standing suite passed with 72 passes and two known baselines (`findings_tests` and `oracle_drift_guard`). Ten headless Godot FX checks passed, covering damage surfaces and transparency, wreck shape and seams, hit recipes and fragments, shield flash booking, trail and damage behavior, and the FX smoke test. The death-seam check used the repo's unbaked fixture after the installed GLB check reported missing texture paths. The fixture run reported zero split machines, zero interior triangles outside the hull, and all surfaces powered down.
