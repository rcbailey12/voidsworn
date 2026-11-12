# Campaign map round 3

Refs #344. Refs #420.

Built the three distances to the Hollow Sun and readable stop types over the merged Briefing map from issue 418.

- `godot/ui/campaign/map3d_system.gd`: one `APPROACH` table selected by `RUN.sector` controls star size and placement, disc, lighting, sky, debris and route framing. Sector III has inward-moving hot fragments and the final stop nearest the star.
- `map3d.gd`, `map3d_props.gd`, `map3d_shaders.gd`: cold outer reach, warm inner belt, dark well; bent background starlight; shared curves for routes and flight; disc exclusion for captions. Arrival starts when the loading cover lifts and eases out over 1.2 seconds.
- `godot/ui/theme/glass_shell.gd` and `campaign_ui.gd`: one 18 px sage line icon set with dark halos, also drawn in the Map key. Ahead models use 85% size and 75% light; cut-off models and icons are half strength. Numbered choices, current labels and the Nemesis mark remain readable. Solid icon strokes avoid a Windows Forward+ retained-canvas failure seen with antialiased polylines.
- `map_travel_test.gd`, `ui_spec_tests.js`, `map_approach_shots.gd` and `godot_checks.txt`: updated the R170 expectation, checked route/flight agreement in every sector and nearest-star placement at every lane height, and registered the reproducible capture driver.

Captures: six full 1920x1080 PNGs and the side-by-side sheet are in `docs/shots/ui_redesign/briefing/round3_1080/`. PC copies for the Board:

[Three sectors](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-420/shots/sectors_sheet.jpg), [three choices in sector I](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-420/shots/sector_1.png), [later sector I](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-420/shots/sector_1_mid_run.png), [sector III far tip](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-420/shots/sector_3_far_tip.png), [Map key](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-420/shots/map_key.png).

The comparison uses seed 344 at the same completed jump in all three sectors. Its three-choice sector I branch is after jump 1; a separate later capture shows its real choices. No graph was staged to manufacture another three-way fork. Captures are from the final working files, ready for the runner's commit; no commit or push was made.

Checks:

- Standing runner: exit 0, 40 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. The existing findings and oracle-drift baseline entries remain KNOWN.
- UI specification: `106 checks, 106 pass, 0 fail`.
- Godot load: `151 scripts, 11 scenes, 0 failed`.
- Map read-only: `PASS (24 checks)`, including picks, tips, Dossier, Map key, save/profile and random-stream preservation.
- Map travel: `PASS`, including 30/60/144 fps, skips, reachability, every sector's curve and all lane heights.
- Rules parity: 271 scenarios compared with the browser; campaign parity: 30 seeded runs compared step by step. PASS.
- Bot seed 359: `result win after 3 rounds, 3 enemy ships destroyed, 0 of ours lost`, then `bot battle: PASS`. The Windows process crashes during shutdown with exit 3221225477 (0xC0000005). The same check on unchanged HEAD 1889d2e6 gives the same win, PASS line and shutdown crash. This baseline native failure is not counted as a clean process pass.
- `git diff --check` and the changed-file em dash scan: clean.

Frame intervals on the RTX 5080, Forward+, High map detail, 1920x1080, VSync off, uncapped: 240 frames after warm-up for each sector; startup and bakes excluded. Values are median / p95 milliseconds, baseline and final run sequentially while another game held the GPU near 99% utilization and about 14.8 GB VRAM. These are contended frame intervals, not isolated map GPU costs; a quiet final build profile remains to be taken.

| Sector | Main before | Round 3 |
|---|---:|---:|
| 1 | 22.489 / 30.752 | 22.582 / 28.342 |
| 2 | 21.435 / 27.823 | 21.842 / 29.156 |
| 3 | 22.562 / 29.639 | 22.722 / 32.869 |

Impact sweep: the campaign owns nodes, edges and saves; this patch only reads them. The browser oracle and battle sky are unchanged. All map ribbon, caption and fleet-flight callers use the sector curve; the static helper keeps its old default for other callers. Hover and keyboard focus still use the same tip path. Imports made for validation were restored or removed from the diff. Other unrelated GPU checks and another 1440 pass were skipped because this job asks for the map at 1080; the Windows shutdown failure remains for a separate engine/runner investigation.
