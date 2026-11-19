# Issue 1070, run 2

Base revision `b7e82cdd25744d9315daabc02fb1c84a81c5a433`. The replay used the preserved Run 1 fleet because the shared build had since changed. Both the installed ship manifest and the generated asset manifest matched Run 1.

## Code changes

- Battle loading now prepares the fleet's base breakup geometry, piece materials and colliders before play. Repeated instances share the original mesh arrays. The fracture seed still comes from the ship ID, so two ships of one hull type can break differently. The workers still handle recuts for live damage and lance hits. One per-frame budget covers finished pieces across the fleet. [Loading cover](../../../../godot/scenes/battle/battle.gd) · [Effects warm-up](../../../../godot/fx/fx.gd) · [Breakup](../../../../godot/fx/fx_death.gd)
- Hull paint and shutdown shader setup is shared by source material, hull scale and organic style. Cut positions, pose and cooling state belong to the live surface or wreck. A damaged live surface keeps its material between hits and updates its own uniforms. [Damage application](../../../../godot/fx/fx_breach.gd) · [Hull materials](../../../../godot/fx/fx_hull.gd)
- Trails submit geometry when the sample history changes. The shader advances the same 2.6-second age between submissions. Hidden shields skip the transform calculation, and fitted shields share their render mesh and ray tree within the battle. Each ship still owns its shield hit uniforms. [Ship effects](../../../../godot/fx/fx_ship.gd) · [Trail shader](../../../../godot/fx/fx_shaders.gd)

## Storm

The current High route uses five puffs per hex in expanded gas patches. Max uses two dimmer puffs and draws fog volumes. Across the dense fixture, this is 314 cards at High and 137 cards plus seven fog volumes at Max. In Run 1, masking the cards saved 5.186 ms at High and 2.205 ms at Max. The same card settings supply the current High cloud's shape, and Max's volume is a distinct layer. The performance patch leaves the routes as shipped. [Gas settings](../../../../godot/world/world_living.gd) · [Run 1 isolation and method](../README.md)

[PERF1070_RUN2_STORM](../../../../docs/shots/perf_1118/run2/PERF1070_RUN2_STORM.jpg)

## Look comparison

Scene 207 uses the same camera, installed V1b_r_23 hull, scripted travel and shield hit in both takes. At radii 170 and 26, and on the shield-hit frame, the largest mean channel difference between builds is 0.336, 0.150 and 0.159 out of 255. Each is within the spread of the repeated captures. The first wreck frame has a larger difference (8.973 out of 255) within the patched build's own repeat (9.069). Small changes in the wreck frame's pose, lighting and debris are visible between takes. The pictured tear, pieces and shield shape match by eye. [Full-resolution pixel differences](look_differences.json)

[PERF1070_RUN2_BATTLE](../../../../docs/shots/perf_1118/run2/PERF1070_RUN2_BATTLE.jpg)

## Reproduction

The timing runs use the [Run 1 probe and method](../README.md). The original installed fleet and generated assets are required. The manifests are `bb6258bc3f2a8c9e530776c4fd9a228957462beee10a37db73a37da0dc6ff2d1` and `34244bddf5ae0b792bfd99d2313afba5a8beb319661346cfcdf81651652708c5`. Stage the same assets and source in two fresh TEMP directories with [stage.ps1](../stage.ps1). Keep one at the base revision and overlay the working Godot scripts on the other. Run the following from the repo root against each staged directory.

```powershell
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase cold
$cases = 'gate:max:1:base','gate:max:2:base','dense:max:2:native_lod','dense:high:2:native_lod'
& .\contrib\codex\perf_1118\run.ps1 -Work $work -Phase baseline -Shapes fitted -Cases $cases
```

Use [proof.ps1](proof.ps1) once per staged source. Include `-Storm` on the base capture. The pictures use capture 2, and each source's repeat is measured against capture 1. Save the SHA-256 of the binary Git diff under `godot/` as `source_diff.sha256` in the patched staging directory when overlaying its scripts. [sheets.py](sheets.py) composes matched viewpoints and stamps the sheets with those revisions.

After the timing and picture runs, use [diagnose.ps1](diagnose.ps1) with `-Label before_isolation` or `-Label after_isolation`. It adds the counters in [instrument.py](instrument.py) to the staged scripts, runs the 1080p fitted fixture in three processes, and restores those scripts. The narrow counters measure the work in each code path. The timing gate uses the separate runs without counters.
