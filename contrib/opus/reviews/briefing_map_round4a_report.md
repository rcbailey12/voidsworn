# Campaign map round 4a

Refs #438. Implemented the R174 polish over round 3. No commit or push.

- `godot/ui/campaign/map3d.gd`: removed orbit guides and battlefield scenery at fights. Ordinary fights show three enemy hulls; elites show a larger cruiser and two escorts; bosses use the faction capital. The faction lookup matches the rail, including rival raiders and changes during teaching fights. Neutral local light keeps dark hulls readable and follows the normal size/light tiers. Routes behind the fleet are hidden. Flight follows the drawn ground curve with height handled separately.
- `map3d_system.gd`, `map3d_shaders.gd`: straight outer approach, roughly quarter-turn middle approach, stronger inner curl; consistent lane spacing and clear disc separation. Removed the background star arcs as well as the orbit guides.
- `godot/ui/theme/glass_shell.gd`: shared stop icons and their halos scale from 18 to 24 px. No rail, wording, type, lime or label-style changes.
- Extended `map_travel_test.gd`, `map_readonly_test.gd`, `map_approach_shots.gd` and `contrib/opus/tools/ui_spec_tests.js`; updated the existing capture driver's `godot/tools/ci/godot_checks.txt` entry. No new test script.

Nine full 1920x1080 game captures, the sheet, its 1920-wide preview and raw metrics are in `docs/shots/ui_redesign/briefing/round4_1080/`. Seed 344, the same completed first jump in all sectors, through real campaign actions. Sector I is Old battlefield and III is Ion nebula; both show more than three fights. Captures include the later route state, the far stops, an ion-storm tip and the Map key.

Board copies: [preview](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-438/shots/sectors_preview.jpg), [full sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-438/shots/sectors_sheet.jpg), [Old battlefield](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-438/shots/old_battlefield.png), [Ion nebula](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-438/shots/ion_nebula.png), [far stops](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-438/shots/sector_3_far_stops.png), [Map key](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-438/shots/map_key.png).

Checks:

- Standing runner: exit 0, 41 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. Existing findings and oracle-drift baselines remain KNOWN.
- UI specification: 114/114 pass. Godot load: 152 scripts, 11 scenes, 0 failed, exit 0.
- Map read-only: 42 checks pass, exit 0, including actual fleet factions, teaching-history changes, bows, tier lights, saves and random streams.
- Map travel: pass, exit 0, including 30/60/144 fps, skips, hidden past routes, nearest-star final stops and flight/route agreement in every sector.
- Fullest four-choice graph at 1080: minimum centre gaps 99.02 / 101.09 / 94.72 px. Final captures: 107.13 / 112.66 / 94.58 px. No icons on the disc in either check.
- Capture driver: exit 0, all required PNGs verified at 1920x1080, no placeholder hulls. Diff whitespace and changed-file em dash scans clean.

Frame intervals, RTX 5080, Forward+, High detail, 1920x1080, VSync off, uncapped. Same seeded maps before edits and after, 240 frames per sector after warm-up; startup/bakes excluded. Median / p95 milliseconds, not isolated GPU costs; other applications were not isolated.

| Sector | Round 3 before | Round 4a |
|---|---:|---:|
| I | 2.625 / 2.826 | 2.815 / 3.316 |
| II | 3.425 / 4.101 | 3.564 / 3.930 |
| III | 3.098 / 3.354 | 3.715 / 4.282 |

Board notes: the unchanged Map key still says flown routes are fainter; they are now hidden. Update that sentence in the separate words/rail round. Region landmarks and emblems remain for 4b.

The optional bot probe won in three rounds and printed PASS, then hung during shutdown and was stopped; it is not counted as a clean process pass. It also logged unavailable imported weapon textures. Round 3 already records a Windows shutdown fault. Required map checks exited cleanly. Godot logged sandbox cache-write and certificate-access warnings; captures saved successfully. Full rules/campaign parity, unrelated GPU checks and other resolutions were not rerun for this presentation-only 1080 task. Campaign data, route graph, rules and browser sources are unchanged.
