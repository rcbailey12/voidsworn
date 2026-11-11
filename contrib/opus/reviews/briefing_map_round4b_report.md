# Campaign map round 4b

Refs #465. Five region treatments and their shared emblems, plus the fight-model and four-route fleet-fit fixes. No commit or push.

- `godot/ui/campaign/map3d.gd`: one region scene beside the route band, seeded separately from the existing stop models. Scenery has its own light layer, half-strength sunlight and reduced emissions. Enemy groups are 25% larger with a faint neutral rim. Captions avoid every stop model and search farther when the nearby spaces are full.
- `map3d_system.gd`, `map3d_props.gd`, `map3d_shaders.gd`: neutral broken hulls with closed bulkheads and three exposed decks, drifting scrap fields, layered storm clouds, the planet and its stations, displaced rocks and mining rigs. Deep void removes the sky cloud and reduces both star layers to 67%. Existing star approach, routes and stop tiers stay in place.
- `campaign_ui.gd`, `glass_shell.gd`: five 40 px TEXT2 line emblems, shared by the region heading and Map key. The key's battle-setting sentence reads the live `REGIONS.route` data. Its flown-route wording was already correct on main and is retained and checked. Four-route forks use tighter unchosen rows and reserve at least three fleet lines, with no smaller type. Solid line strokes also avoid the Windows Forward+ retained-canvas fault seen as missing parts of letters during capture.
- `map_readonly_test.gd`, new `map_region_shots.gd`, `godot_checks.txt`, `ui_spec_tests.js`: live checks for all five region scenes and both emblem locations; capture checks for 1080 output, minimum rail type, rail overlaps and four-route fit. The new GPU capture script is registered in the CI inventory.

Region evidence, all generated naturally in sector I and reached through real campaign actions:

| Region | Seed | Built |
|---|---:|---|
| Old battlefield | 6 | One split capital hull with embers at its break; a long field of plates and smaller dead hulls turning slowly. |
| Ion nebula | 3 | One overlapping violet-blue bank below the band, slow faint internal flickers and an off-band storm core. |
| Contested world | 2 | One large world below the band, an atmospheric edge and night settlements, with three small orbital stations. |
| Asteroid frontier | 10 | Clumped rocks, three small mining rigs and one hollowed asteroid with its own built-in rig. |
| Deep void | 1 | No landmark or cloud; three distant neutral derelicts and one seven-second beacon. |

Start with the [five-region sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-465/shots/regions_preview.jpg), then the [three-sector preview](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-465/shots/sectors_preview.jpg) or [full side-by-side sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-465/shots/sectors_sheet.jpg). The sector sequence is seed 344, the same first completed jump of one run, through real actions. Also captured: the [Map key](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-465/shots/map_key.png) and [four-route fork with three fleet lines](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-465/shots/four_routes_4.png). All four route selections pass with three fully visible fleet lines, zero route-list overflow and zero rail text overlaps. Nothing on the rail is below 17 px.

Thirteen full 1920x1080 PNGs, three comparison sheets, final `metrics.json` and `baseline_metrics.json` are in `docs/shots/ui_redesign/briefing/round4b_1080/`, with identical Board copies in `issue-465/shots/`. The sector preview is 1920 px wide. The capture command is the registered `campaign/test/map_region_shots.gd` script with an absolute output folder and `--no-tips`.

Frame intervals on the RTX 5080, Forward+, High detail, 1920x1080, VSync off and uncapped. Same driver and seeds before and after, 90 warm-up frames and 240 measured intervals per state, excluding loading and bakes. Median / p95 in milliseconds; these are whole frame intervals, not isolated GPU timings. Other applications were not isolated.

| Sector | Main before | Round 4b | Texture memory before / after |
|---|---:|---:|---:|
| I | 2.843 / 3.294 | 3.591 / 3.997 | 619.71 / 673.05 MiB |
| II | 3.642 / 4.087 | 4.409 / 5.631 | 929.76 / 983.61 MiB |
| III | 3.718 / 4.241 | 4.621 / 5.145 | 1233.88 / 1287.72 MiB |

Texture figures are the renderer's total live texture allocation at each matched state, including cached assets from earlier scenes. Increase: 53.34 MiB in I and 53.84 MiB in II and III. The new scenery uses procedural materials and existing hull assets; it adds no texture files. Raw before/after figures for all five regions and the fork are retained alongside the captures.

Checks:

- Standing runner: exit 0, 41 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. The existing findings and oracle-drift baselines remain KNOWN.
- UI specification: 135/135 pass. Godot load: 155 scripts, 11 scenes, zero failed, exit 0.
- Map read-only: 83 checks pass, exit 0. Includes actual landmark content, all five mappings, both emblem locations, light isolation, save/profile integrity and rules random-stream integrity.
- Map travel: pass, exit 0, including 30/60/144 fps, lane states, hidden past routes and all-sector spacing.
- Final GPU capture driver: exit 0; all required captures are 1920x1080, zero placeholder hulls, all four fleet-fit cases pass. Final sheets inspected by eye. Whitespace and changed-source em dash scans clean.

Limits: the optional bot battle printed PASS after a three-round win with zero placeholders, then hung on shutdown and was stopped. It also logged missing imported effect atlases already present outside this change; this is not counted as a clean process pass. Godot logged the sandbox certificate-store warning. Full rules/campaign parity, other resolutions and the unrelated battle GPU gate were not rerun for this presentation-only map job. Campaign source, route graphs, save data and browser sources are unchanged. No design ruling is required for implementation; the Board still judges the visual strength from the sheets.
