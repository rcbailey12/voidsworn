# Astra Picket | hegemony_H7A

[Three-quarter](renders/hegemony_H7A_three_quarter.png) | [Side](renders/hegemony_H7A_side.png) | [Top](renders/hegemony_H7A_top.png) | [Underside](renders/hegemony_H7A_underside.png) | [Battle 170](renders/hegemony_H7A_battle_170.png)

I kept the dart's long taper and broad stern. The bevels turn into a flat maintenance floor. I would borrow the paired belly coolers and the break in the blue stripe at each boarding door. The plates read more strongly and the stripe more quietly than in the beauty. I did not read, copy or render the excluded Opus build, branches, PRs or comments. [Concept](../../muse/design/class_family_hegemony_2026_11/picket_beauty.webp) | [Build sheet](BUILD_SHEET.md)

**Parts.** I hand-built the shell, gun sleeve, collars, light races, belly rails and interiors. The Navy kit supplied the plates, weapons, sensor, nozzles, hatches, louvres and paint stack. [Manifest](manifest.json) | [Editable Blender model](hegemony_H7A.blend) | [Painted export](export/hegemony_H7A.glb)

**Budget.** Frigate length 6.5. The GLB has 19,462 triangles on 13 surfaces, including 2,936 interior triangles on five surfaces. Eight exterior surfaces imply eight draws in a single material pass. Hull and parts maps are 2048 square. Engine emission is 1024 square.

| Stage | Evidence |
| --- | --- |
| 1. Concept | Stock launcher passed. |
| 2. Reference | Blocked. Lane D refused the GPU claim before TRELLIS started (exit 126). Automatic approval review declined a retry. |
| 3. Outline | Independent camera fit overlaps 92.85% of the beauty mask. Reference scoring awaits stage 2. |
| 4. Parts | Fit, weapon match, audit and both self-tests passed. Zero clashes, 81 interior objects, two structural joints. |
| 5. Paint | CPU stack proof, 2048 at 32 samples. Surface and detail checks passed. Relative density flagged engines, vents and hatches. |
| 6. Cost | Four LODs at 19,462 / 16,526 / 11,949 / 5,402 triangles. Measured GPU draw calls and timing remain open. |
| 7. Export | Stock writer, painted export readback and broken-export self-test passed independently. |

The full recipe needs a GPU lane. All five images are CPU Blender paint proofs. Battle 170 is a native-pixel crop of a 1080p frame. The close views use a brighter inspection exposure. [Isolated launcher](build_picket.bat)

### Painted export readback

```text
[check] authored interiors: 2936 triangles, 5 surfaces; authored seams: 2
[check] 16526 triangles (9270 on part surfaces), box x -0.502 to 0.498, y -0.065 to 0.101, z -0.184 to 0.184
[check] ship length 1.0000: off-mesh limit 0.012 of it, 0.0120; breach clearance at least 0.03
[check] turrets: 1 written (turret_0 dorsal); marked by the kit: ['dorsal']
[check] slot 0 laser F: 2 hard points
[check] slot 1 flak T: 3 hard points
[check] hard points: {"board": 2, "breach": 2, "core": 1, "engine": 2, "rcs": 2, "gun": 5}
PASS hegemony_H7A game export: every required point is there and every hard point passes the mesh checks
```

### Standing checks

100 passed, 11 failed and two matched known baselines. All five Picket pictures passed direct provenance verification.

Failed checks were `gpu_slots_tests`, `pc_jobs_1194_tests` (timeout), `picture_provenance_tests`, `publish_ship_tests`, `pysite_1535_tests`, `relay_push_tests`, `runner_cleanup_tests`, `runner_stall_tests`, `saved_campaign_update_tests`, `runner_selftest` and `stage5_fail_selftest`.
