# C19_51 ship pipeline and PNG proof

C19_51 (the `corsair_A16` build sheet) passed stages 4 to 7 on main `eb9094e2` and the patched working tree. The bake took 241.1 s, down from 342.5 s. The concept-camera renders look the same. Across the original 1024 by 1024 images, mean absolute difference was 0.0004 on a 255-point scale.

![C19_51 at the concept camera on main and the patched branch](C19_51_concept_compare.png)

## Installed game comparison

The stage 7 installer put the JPEG and PNG exports in separate scratch copies of the same Godot project. It refreshed both caches and read back 61 nodes from each installed ship. `a4_shots` drew both copies with the same sky and battle lighting.

The battle views look alike. The close views show small differences in surface grain and highlights. The mean absolute RGB difference at 1920 by 1080 was 0.036/255 at battle distance and 2.168/255 in the tightest deck view.

[Battle](../../../docs/shots/issue-1152-codex/C19_51_game_battle.png) · [Battle zoom](../../../docs/shots/issue-1152-codex/C19_51_game_near.png) · [Bow](../../../docs/shots/issue-1152-codex/C19_51_game_q.png) · [Side](../../../docs/shots/issue-1152-codex/C19_51_game_s.png) · [Below](../../../docs/shots/issue-1152-codex/C19_51_game_b.png) · [Top](../../../docs/shots/issue-1152-codex/C19_51_game_t.png) · [Deck](../../../docs/shots/issue-1152-codex/C19_51_game_d.png) · [Underside](../../../docs/shots/issue-1152-codex/C19_51_game_u.png)

## Stages 4 through 7

| Stage | Main wall (s) | Main GPU queue (s) | Main work (s) | Branch wall (s) | Branch GPU queue (s) | Branch work (s) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 4. Parts and audit | 105.8 | No delay logged | ~105.8 | 53.3 | 0 | 53.3 |
| 5. Paint and renders | 733.4 | No delay logged | ~532.4 | 625.6 | ~113 | ~513 |
| 6. LOD export and Godot frame bench | 90.0 | No delay logged | ~90.0 | 235.8 | ~82 | ~154 |
| 7. Game export and self-test | 180.0 | No delay logged | ~180.0 | 366.1 | 0 | 366.1 |

One sequential run per revision on the same Windows PC with Blender 4.5.14 and Godot 4.7.2. Both runs used copies of the same fitted camera, concept and outline data. The patched run used an absent B0 GLB and kept the existing second-camera `b0.npz` outline data. Both stage 7 runs wrote to scratch.

Work is wall time minus queue time and the separate 201 s game-open pause in main stage 5. The first run's watchdog wrote minute heartbeats without acquisition timestamps. The two branch queue estimates use the extra time from each log's creation to its first identical camera output, compared with main. They can include differences in launch and rendering time. Other PC jobs ran during these measurements.

Stage 6 also spent more work time in the LOD export and Godot bench. Branch stage 7 ran with zero GPU claims. Its export fault self-test took about 282 s versus 158 s on main, which accounts for most of that wall time difference.

A timestamped stage 4 repeat tested the CPU queue behavior while another job held the GPU solo. The branch completed stage 4 in 43.2 s with zero GPU claims across all five Blender commands. On main, the sheet contract check alone spent 792.8 s waiting for a shared claim and about 4.0 s after admission.

## Stage 7 exporter retest

Both exporters used the same saved C19_51 bake at 2048 px. A solo watchdog claim kept other queued work off the GPU. Both Blender commands ran in CPU mode and neither took a GPU claim. The outer claim waited 48.6 s before the measurements began.

| Measured work | Main (s) | Branch (s) |
| --- | ---: | ---: |
| Export script | 16.57 | 17.65 |
| Blender command and watchdog | 20.05 | 19.71 |
| Blender glTF gather and write | 6.91 | 7.73 |
| Blender JPEG encoding, seven images | 0.35 | |
| Blender PNG encoding, six images | | 1.72 |
| Pillow JPEG encoding, three images | | 0.06 |
| Atlas resizing and normal renormalization | | 5.24 |

The rows overlap. JPEG and PNG encoding inside Blender are part of glTF export. Blender encoded six intermediate PNGs and four went into the final export. Pillow copied those four files without re-encoding them. Encoding took 1.72 s and the export script difference was 1.08 s. The earlier 14.4 s and 36.8 s exporter readings were not reproduced. The brief's 10 s threshold for changing PNG compression was not reached.

The complete stage 7 launchers also passed in a separate run on the same bake. Work took 151.2 s on main and 160.6 s on the branch, including 129.8 s and 134.7 s in the fault self-tests. The outer solo reservation waited 51.9 s once. Both Blender commands ran CPU-only with zero inner GPU claims. For this retest, the main launcher used the current watchdog's CPU mode so it could run inside the solo reservation.

## C19_51 map sizes

These are the files referenced by the GLB in each installed export. Sizes are file bytes and exclude the GLB and Godot's cache.

| Map | Main JPEG bytes | Branch PNG bytes |
| --- | ---: | ---: |
| Hull normal | 610,738 | 5,472,183 |
| Hull ORM | 1,900,188 | 8,722,560 |
| Parts normal | 446,656 | 4,536,489 |
| Parts ORM | 1,823,571 | 7,339,564 |
| **All maps, including JPEG color and emission** | **8,498,017** | **29,801,782** |

The C19_51 package adds 21,303,765 bytes of maps (20.32 MiB). The C19_51 export of the same bake used for the solo timing measured 8,498,660 and 29,801,782 bytes.

### Average across nine saved bakes

Each pair used the same painted blend and the same 2048 px export setting. A16 and S8 used the current stack rules. For the older A17 to A20 and E11 to E13 atlases, both exporters used the legacy route in scratch because those bakes predate the separate parts normal. E14 was excluded because its saved weapon slots did not match the current ship. The average describes this sample.

| Ship | Main map bytes | Branch map bytes | Added MiB |
| --- | ---: | ---: | ---: |
| C19_51 / A16 | 8,498,660 | 29,801,782 | 20.32 |
| A17 | 7,164,651 | 22,671,264 | 14.79 |
| A18 | 7,971,499 | 22,673,258 | 14.02 |
| A19 | 7,738,633 | 22,070,296 | 13.67 |
| A20 | 7,979,308 | 21,018,267 | 12.43 |
| E11 | 7,669,816 | 20,278,107 | 12.02 |
| E12 | 6,482,336 | 16,814,663 | 9.85 |
| E13 | 5,103,618 | 14,963,097 | 9.40 |
| S8 | 8,092,445 | 25,644,794 | 16.74 |
| **Average** | **7,411,218** | **21,770,614** | **13.69** |

## Cycles and bake passes

Main device probe using the original paint-stack selector

> Cycles device: OPTIX (NVIDIA GeForce RTX 5080 [CUDA], AMD Ryzen 7 5800X 8-Core Processor [CPU], NVIDIA GeForce RTX 5080 [OPTIX])

Patched stage 5 bake log

> Cycles device: OPTIX (NVIDIA GeForce RTX 5080)

The main probe lists enabled preferences. CUDA and OptiX are entries for the same card. Both bakes reported OptiX as the active backend. The atlases were 4096 at 64 samples. The timings below come from the two `A16.json` bake reports.

| Bake pass | Main (s) | Patched (s) |
| --- | ---: | ---: |
| Hull masks | 18.9 | 10.7 |
| Hull albedo | 32.7 | 26.3 |
| Hull ORM | 30.2 | 17.7 |
| Hull normal | 123.9 | 89.2 |
| Parts masks | 14.9 | 11.5 |
| Parts albedo | 14.4 | 9.6 |
| Parts ORM | 17.1 | 9.0 |
| Parts normal | 28.4 | 15.4 |
| Engine glow | 3.3 | 0.9 |
| Whole paint stack | 338.4 | 238.3 |


The following height bakes are included in the hull normal row.

| Hull normal height pass | Main (s) | Patched (s) |
| --- | ---: | ---: |
| `ps_blood_H` | 9.1 | 4.8 |
| `ps_iron_H` | 11.8 | 7.6 |
| `ps_rust_H` | 10.3 | 6.0 |
| `ps_soot2_H` | 10.9 | 13.1 |
| `ps_soot_H` | 15.0 | 8.1 |

## PNG copy jobs and installer

- `godot/fx/test/check_damage_surface.bat` and `godot/fx/test/check_squadrons.bat` copy PNGs and their Godot import sidecars alongside JPGs. Both copy filters copied all seven C19_51 maps and their sidecars in a Windows scratch test.
- `tools/blender/r209/pc/r7_run.bat`, `r7b_run.bat`, `r8_run.bat` and `r8b_run.bat` also copy any PNG in their ship export.
- The PC review jobs `contrib/opus/reviews/attach_370/pc/run370a.bat`, `contrib/opus/reviews/handoff_559_probe/run559.bat` and `contrib/opus/reviews/turrets_560/pc/run560.bat` were updated too. The legacy A4 repaint job only copies the JPEG color map it authors and the import settings for the legacy JPEG normal map.
- `tools/recipe/manifest_merge.py` installs the maps named by the GLB. It accepts ship-prefixed normal and ORM PNGs, removes superseded managed maps from the new install and keeps them in the rollback backup. `manifest_merge_selftest.py` installs a mixed export and tests stray names, exact map selection and rollback.

## Current checks

- The standing suite completed all 77 rows with 75 PASS, two recorded KNOWN baselines and zero failures.
- Godot loaded 241 scripts and 16 scenes. All 85 listed headless checks and the seed 360 bot battle passed. Map trial and formation needed the browser harness and sheet data from the checkout. The two title tests passed with their expected isolated profile path. The smoke test exited zero and its log contained zero case-sensitive `SCRIPT ERROR` lines.
- Blender rebaked A16 through `sheet_fixture_hash.py --bake`. The compressed GLB matched the tracked fixture byte for byte. The refreshed record passed `--check` and the Godot death seam check reported a fresh fixture and zero failures.

## Checks from the first run

- The stage 4 build, sheet contract, audit, audit self-test and silhouette dump, stage 6 LOD export and stage 7 game export each show an acquired GPU claim on main and zero GPU claim lines on the patched run. The patched Godot frame bench kept its solo claim. The patched stage 4 and 5 close-up logs record the sheet-ship skip.
- Both stage 7 exports passed the hardpoint checker and its self-test. The patched package has JPEG albedo and emission maps and 2048 px PNG normal and ORM maps. The largest unit-length error in either decoded normal map was 0.0048. The GLB image references and manifest match the exported files.
- The 76-row standing suite completed all rows. Four Windows-environment failures from the restricted run passed when rerun individually with native permissions and a shorter temp path. The other 70 rows passed and two reported their expected KNOWN baselines. The full native rerun had 73 PASS, two KNOWN and one failure in the PC runner self-test. Its standalone native run passed all 134 cases.
- Godot loaded 239 scripts and 16 scenes. The seed 360 bot battle and all 84 listed headless game checks passed, including three Windows profile retries. The separate A16 fixture-freshness check fails on the patched tree because its fingerprint covers `export7.py`. The main and patched unbaked GLBs matched the tracked fixture byte for byte.
