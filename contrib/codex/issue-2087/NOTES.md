# Refs #2087: arrival cuts and hull rebuilds

The biggest cost is processing the live hull triangles, not getting the wreck meshes ready before the split as PR 1831 requires (issue 1829). On I15_11 the fracture worker spent 11.32 s cutting 858,386 triangles and another 0.37 s on piece hulls and reach. The main-thread wreck mesh, material and shape builds took 0.15 s in total. The largest wound rebuild spent 18.83 of its 19.12 s in the surface pass alone. B21_11's largest rebuild spent 10.61 of its 10.70 s there. This CPU run reproduced the multi-second wound waits on both hulls and the arrival cut wait on I15_11. The isolated B21_11 arrival cut was shorter than the waits reported by DEFAULT_A.

## CPU timings on the DEFAULT_A hull assets

Times in seconds. **Cut** and **Prebuild** are from the baseline. Cut is the fracture worker's geometry pass, and prebuild is total main-thread time on wreck meshes, materials and shapes. **HP50** sums the rebuild workers from one HP sync after three hits. The probe also prints gathering, hulls and reach, each hit rebuild, wound surface time and apply time.

| Faction | Hull | Cut input triangles | Cut | Prebuild | HP50 before (2 jobs) | HP50 after (1 job) |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Glasswrights | I15_11 | 858,386 | 11.32 | 0.15 | 24.31 | 18.55 |
| Chorus | B21_11 | 343,586 | 2.40 | 0.08 | 13.12 | 10.02 |
| Sunward Crusade | V16_37 | 89,016 | 1.01 | 0.07 | 5.89 | 4.32 |
| Meridian Directorate | H10_23 | 59,764 | 1.12 | 0.05 | 4.42 | 3.24 |
| Ashfall Hullbreakers | C15s_23 | 87,888 | 1.44 | 0.05 | 4.30 | 3.65 |
| Eclipse | D21_23 | 55,006 | 0.81 | 0.05 | 2.96 | 5.96 |
| Glasswrights | I8_37 | 484,098 | 4.72 | 0.11 | 13.84 | 10.12 |
| Chorus | B22_11 | 519,472 | 3.38 | 0.09 | 9.90 | 8.73 |

The eight cut signatures and all 32 final wound signatures matched, including each individual hit before the HP sync. Worker times vary on the shared PC. D21_23 was slower on the second run during the individual hits too, which use the same path in both runs. The repeatable change is one fewer job at HP50 on every hull.

## Changes and next step

- The look bench opts out of arrival cuts for scripted survivors. A death row still prebuilds the target's wreck, and every hull still gets its arrival shader warm-up. Battle arrivals keep their existing cut behavior. Removing those cuts in battle risks a reinforcement dying before its first wreck is ready.
- One hull sync now submits one snapshot for regraded marks and section changes that take effect together. That removes the partial rebuild without changing wound shapes, hit placements, or stages. If a volley is still animating, mark regrading and the later stage change still request work at their own times.
- Next, trim the cut and wound input geometry on I15_11 and the dense Chorus exports. Start with over-tessellated surfaces away from the silhouette, glass seams and breach edges. Keep the same authored seams, interior and materials. Re-run this probe and compare the wound and wreck at battle and close cameras before accepting new assets. A cache keyed only by hull code is not enough: the live cut uses a ship's seed, pose, and existing wounds. The older exported wreck is not a drop-in substitute for the same break.

## Reproduce

Run from the repo root with Godot 4.7.2. Use the `gen` folder from the DEFAULT_A checkout to repeat the table, or the current installed `godot/gen` to check a new export. The probe rejects placeholders.

```powershell
godot --headless --path godot --script res://bench/arrival_damage_probe.gd -- "C:/path/to/godot/gen"
```

These are CPU timings with the default wounds switch off. Headless builds ArrayMeshes on the main thread, whereas rendering builds piece geometry on the worker. These measurements do not include Vulkan uploads, shader warm-up, or frame hitches. The look bench explicitly waits for its jobs between steps. Battle polls them, so worker duration is not itself a blocked battle frame.

## Verification

Godot 4.7.2 completed both eight-hull probe runs. The headless damage-surface, first-hit scars, capability-loss, cold-kill, battle-cut load and authored-death checks passed. The headless look bench completed a volley row and a death row. No GPU capture was run in the code-only lane.

Standing checks completed with 118 passes, 2 known baseline results and 4 Windows harness failures after retrying Node with symlink preservation. The failing rows were `godot_shard_tests` (Git Bash could not create the plan folder), `pc_jobs_1194_tests` (fake ffmpeg wrapper exceeded its deadline), `runner_selftest` (CIM access denied), and `pc_daemon_selftest` (path permission error). No harness code changed.
