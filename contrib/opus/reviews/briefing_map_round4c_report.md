# Campaign map round 4c

Refs #470. All four presentation changes are built and captured at 1920x1080. No commit or push.

- `godot/ui/campaign/map3d.gd`: the Old battlefield has ten wrecks from Hegemony and Hullbreaker hulls, spanning battleship, cruiser, destroyer and frigate classes. Four are split with closed bulkheads and three decks. The largest two lengths are 12 and 11. Varied headings, scattered plates and three faint ember sources sit beside the route band, below the stops' light level. Split planes follow each wreck's orientation.
- `map3d_shaders.gd`: the map planet loses the circular polar-cap mask and its ocean specular spot. Irregular continents, drifting clouds, atmosphere and night settlements remain.
- `map3d_props.gd`: smooth displaced rocks gain finer geometry, small craters alongside the broad craters, and another ridge scale. At High detail, field rocks rise from 1,280 to 5,120 triangles each; the landmark rises from 1,280 to 20,480. The frontier scenery draws 1,315,168 instanced triangles, versus 328,288 from the previous mesh densities with the same instances and rig parts. No texture files are added.
- `map3d_system.gd`, `map3d.gd`: easy fights have a lead frigate with zero or one smaller escort; Even fights a destroyer with two; Hard and Deadly fights a cruiser with two; elites a cruiser with two; bosses their faction's capital alone. Escorts are 1.8 to 2.3 units long against leads of 4.4 to 5.6, behind and to either side at different depths, heights and headings. Sector and stop id seed the formation. Danger changes refresh the class and count; the seeded placement remains stable. Normal groups fit within 9 map units, bosses within 12, verified on actual built hulls.
- `map_readonly_test.gd`, `map_travel_test.gd`, `map_region_shots.gd`, `contrib/opus/tools/ui_spec_tests.js`: live group checks, repeated-build checks, all difficulty/kind combinations, landmark checks and capture evidence. The obsolete assertion requiring 25% larger identical trios is replaced. Capture metrics now include each actual group and scenery geometry.

Review the [Old battlefield comparison](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-470/shots/region_boneyard_preview.jpg), [Contested world comparison](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-470/shots/region_world_preview.jpg), and [Asteroid frontier comparison](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-470/shots/region_frontier_preview.jpg). Each has before above after, at seeds 6, 2 and 10 respectively. Frontier is held by the Hegemony Navy. The [three-sector comparison](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-470/shots/sectors_preview.jpg) follows seed 344 through real campaign actions. All previews are at most 1920 px wide; full sheets and original 1080 PNGs accompany them.

Evidence is duplicated in `docs/shots/ui_redesign/briefing/round4c_1080/` and `board/issue-470/shots/`: 13 final captures, six matched before captures, five sheets, five previews, `metrics.json` and `baseline_metrics.json`. The Map key and all four route selections are also captured. Full-size region images and comparison sheets were inspected.

Frame intervals on the RTX 5080, Forward+, High detail, 1920x1080, VSync off, uncapped. Each state has 90 warm-up frames and 240 measured intervals, excluding loading and bakes. Values are median / p95 milliseconds; texture figures are total live renderer allocation in MiB, including retained assets.

| State | Round 4b ms | Round 4c ms | Texture MiB before / after |
|---|---:|---:|---:|
| Old battlefield, seed 6 | 3.621 / 4.006 | 3.695 / 4.396 | 1537.16 / 1558.50 |
| Contested world, seed 2 | 4.150 / 4.872 | 3.620 / 4.247 | 1801.31 / 1822.65 |
| Asteroid frontier, seed 10 | 4.018 / 4.851 | 3.657 / 4.389 | 1934.13 / 1955.47 |
| Sector I, seed 344 | 3.556 / 4.093 | 3.527 / 4.089 | 673.05 / 694.39 |
| Sector II, seed 344 | 4.496 / 5.346 | 4.380 / 4.955 | 983.61 / 983.61 |
| Sector III, seed 344 | 4.617 / 5.951 | 4.597 / 5.065 | 1287.72 / 1309.06 |

The texture increase is 21.34 MiB in five of these states, zero in sector II. These are matched whole-frame observations, not an isolated GPU speed claim. Other applications were not isolated. The baseline could not write normal Godot caches under the sandbox; the final capture ran with cache access. Both measurements exclude those cold writes and bakes.

Checks: standing runner exit 0, 41 PASS, 2 KNOWN, zero FAIL or SKIP; UI spec 135/135; Godot load 155 scripts and 11 scenes, zero failed; map_readonly 119 checks PASS; map_travel PASS, including group determinism and variation, all three sectors, lane states and flight at 30/60/144 fps. Final GPU capture driver exit 0, zero script errors or placeholder hulls, all images 1920x1080, zero rail text overlaps, zero route-list overflow, all four route selections retain three fleet lines. Whitespace and changed-text em dash scans clean.

Limits: the optional bot battle printed PASS after a three-round win with zero placeholders, then hung during shutdown and was stopped. Missing imported battle effect atlases were also logged; this is not counted as a clean process pass. Full rules/campaign parity, other resolutions and the unrelated battle GPU gate were not rerun for this map presentation change. Campaign rules, route graphs and saved data are untouched, as checked by the read-only snapshots.
