# Issue 671: PC text-floor captures

All ten requested captures are complete. No text overlaps. Minimum native text: 17 px at 1080, 23 px at 1440. Two sampled contrast failures: the ship name on the 1440/20/world view (4.44:1), and Map key (2.68:1). No game code changed. No commit or push.

Captured the real Godot battle scene with built PC hulls, at 1920x1080 and 2560x1440, with 1 and 20 player ships on the brightest and darkest sampled boards. Also captured the campaign map and fleet page at 1440.

Source: `8f20db55262e91eac279790501b61f49b2e8fb46`. Windows PC, RTX 5080, Godot 4.7.2, Forward Plus, maximum quality, normal UI scale, battle camera 170, battle seed 7. Every battle uses live rules state and the real HUD. No hand-fed sample Ledger data. The capture guard found zero placeholder ships.

Each delivered JPG is 1237x720, including its name strip. Font measurements below come from the native render before reduction; the reduced JPG is for review. Identical JPGs and this report are in `C:\Users\rcbai\Downloads\voidsworn_test\board\issue-671\shots`.

| Picture | Smallest read text, native px | Overlapping text boxes | Text below 4.5:1 | Lowest contrast |
|---|---:|---:|---|---:|
| [battle_1080_1_storm](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1080_1_storm.jpg) ([repo](battle_1080_1_storm.jpg)) | 17 | 0 | None measured | 6.111:1 |
| [battle_1080_1_world](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1080_1_world.jpg) ([repo](battle_1080_1_world.jpg)) | 17 | 0 | None measured | 5.917:1 |
| [battle_1080_20_storm](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1080_20_storm.jpg) ([repo](battle_1080_20_storm.jpg)) | 17 | 0 | None measured | 5.965:1 |
| [battle_1080_20_world](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1080_20_world.jpg) ([repo](battle_1080_20_world.jpg)) | 17 | 0 | None measured | 5.917:1 |
| [battle_1440_1_storm](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1440_1_storm.jpg) ([repo](battle_1440_1_storm.jpg)) | 23 | 0 | None measured | 6.051:1 |
| [battle_1440_1_world](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1440_1_world.jpg) ([repo](battle_1440_1_world.jpg)) | 23 | 0 | None measured | 5.82:1 |
| [battle_1440_20_storm](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1440_20_storm.jpg) ([repo](battle_1440_20_storm.jpg)) | 23 | 0 | None measured | 6.204:1 |
| [battle_1440_20_world](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/battle_1440_20_world.jpg) ([repo](battle_1440_20_world.jpg)) | 23 | 0 | `Unyielding Oath` 4.438:1 | 4.438:1 |
| [campaign_map_1440](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/campaign_map_1440.jpg) ([repo](campaign_map_1440.jpg)) | 23 | 0 | `Map key` 2.684:1 | 2.684:1 |
| [campaign_fleet_1440](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-671/shots/campaign_fleet_1440.jpg) ([repo](campaign_fleet_1440.jpg)) | 23 | 0 | None measured | 5.126:1 |

## Measurement method

The six look-bench presets were rendered at 1080 with the same seed, camera and one-ship fleet. Mean linear relative luminance was sampled over the same clear board rectangle (x 32 to 80 percent, y 25 to 80 percent), with text removed. This selects actual rendered presets, rather than assuming that the region called deep is darkest. Levels: frontier 0.04703, nebula 0.11376, world 0.02632, boneyard 0.03541, deep 0.02947, storm 0.11727. Brightest: storm. Darkest: world. These are the extremes of these six presets and this camera, not every possible campaign seed or camera.

Text sizes and rectangles come from the live Ledger draw items, visible Labels, Buttons and RichTextLabels, and the campaign purse draw parts. Contrast uses WCAG relative luminance of each foreground colour against a second render with text fill removed. Label outlines and button backgrounds remain in that second render, so ship names are measured against their actual black halo. Fully opaque glyph cores are measured; antialiasing edges are excluded. World shader time can advance between the two renders, so these are sampled-frame measurements. `measurements.json` records each word, size, rectangle, contrast, unit hull code and fleet-fold state.

Overlap counts are intersections of the displayed text rectangles, with parent-child widgets excluded. Each delivered view was also inspected visually. The Ledger test separately checks the screen veils over pure white and black, so the sheet has a worst-backdrop check beyond the sampled scene.

## Checks and limits

- `ledger_readability_test.gd`, headless: PASS, zero failed checks at 1080 and 1440.
- Capture GDScript, PowerShell and Python parse checks: PASS.
- Standing checks with bundled Node 22: 47 PASS, 1 FAIL, 2 KNOWN. Failure is in unchanged `godot/fx/test/death_spawn_check.gd:143`: invalid call, nonexistent `float` constructor. The wrapper `fx_death_spawn_tests` fails. The two KNOWN results are the existing findings and oracle-drift baselines. No fix made in this capture-only job.
- Initial default Node 24 attempt stopped at the required Node 22 guard; rerun used bundled Node 22. Initial sandbox render could not write the world-bake cache; final captures ran with local cache access.
- GPU captures waited for other Blender and rendered Godot jobs. The initial wait also held for a headless Godot import; it was narrowed to GPU rendering jobs, then resumed using the completed views. No other job was stopped.
- No requested capture was skipped. Campaign data is an in-memory seed-644 new run with persistence off; no player run or save was written.

Reproduce with `capture.bat`. It waits for other GPU rendering jobs, keeps raw PNGs and logs in TEMP, then writes the named JPGs and measurements here and to the PC shots folder. `capture.gd`, `capture.ps1` and `finish.py` are capture tooling only.
