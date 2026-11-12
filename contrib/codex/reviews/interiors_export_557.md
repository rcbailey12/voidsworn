# Issue 557: authored insides and seams reach Godot

Stage 7 now retains the authored rooms and hull liner. One versioned GLB extra carries their material names and weak
seams to `fx_hull.gd`; damage exposes the rooms and death carries them into irregular pieces. The existing bite, chips,
scorch, faction matter and old-hull fallback remain. A liner alone, missing rooms, and missing seams fail readback.

Changed files:

- `tools/recipe/export7.py`, `check_export.py`: retain interiors and thickness, write/read the contract and validate it.
- `tools/recipe/check_export_selftest.py`, `contract_selftest.py`: valid fixture plus missing-room, missing-seam and
  liner-only failures, alongside the existing hard-point cases. Scratch files are retained in TEMP.
- `godot/fx/fx_hull.gd`, `fx_death.gd`, `fx_breach.gd`: one metadata reader, authored seam preference and room preservation.
  Generic cavity floors and full cut caps no longer cover authored rooms. Legacy native triangle extraction stays intact.
- Three `godot/fx/test/authored_interiors_*` scripts and their CI registry entries: geometry, installed captures, fleet cost.
- `tools/recipe/interiors_export_probe.py`, `interiors_sheets.py`: repeatable export variants and labelled screenshot sheets.
- `docs/ship_pipeline/RECIPE.md`, `godot/fx/API.md`, `docs/playbooks/deaths_and_hits.md`: format, working method and the
  existing main-piece linear Y lock, which prevents physics from pushing the main wreck below the board while it tumbles.

Done-when evidence:

- Source: PC `opus209/out8b/Ab8.blend`, an existing `bakeAb6.py` route output. The original Ab6 file predates hard-point
  registration, so the later baked recipe hull was used. The probe adds six plainly named machinery marker boxes between
  the existing decks for the test. These are test geometry, not production ship art. The original blend is untouched.
- Both versions are exported from that same scene, saved as installed scenes, and loaded through production ShipView.
  The normal FX section-opening and death paths create the pictures. No shared game build or manifest was replaced.
- Authored export: 126,900 triangles and six surfaces; legacy export: 101,892 triangles and three surfaces. The added
  25,008 triangles include the real liner, decks/frames and 72 machinery-marker triangles. This adds three material draws
  per visible ship pass, plus their shadow passes. No detail was reduced to reach a triangle or draw-call limit.
- Moving the first seam in Blender from x -0.125 to -0.225 moves the installed joint from x -2.842 to -5.159. The main
  piece triangle counts change from `[16816, 11485, 53644, 48906]` to `[16139, 11651, 53618, 49444]`. The seam guides a
  ragged tear, not a straight pre-cut chunk. The automated check also proves actual point ownership changes with the seam.

Pictures, at the production camera rig's home angle, with radius 170 and 60. Sheets use equal crops at original pixels;
the full frames and cooled views are beside them. Top row is an opened section, bottom row is the death.

- [Before and after, camera 170](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-557/shots/proof/comparison_camera170.png)
- [Before and after, camera 60](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-557/shots/proof/comparison_camera60.png)
- [Moved seam, camera 60](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-557/shots/proof/seam_moved_camera60.png)

Budget: the #207 battle, 20 ships, all six factions, storm, effects and HUD, Forward+, 1080p with MSAA 4x, vsync off.
The Hullbreaker capital visual alone is replaced by the test hull, at the capital's normal game scale, identically for
both exports. Three sessions, 180 warm-up and 360 measured frames per mode. This measures one rebuilt ship in the real
mixed fleet; it does not predict the cost of 20 future fully rebuilt ships. The binding scene limit is 12.5 ms.

| Measurement | Legacy | Authored |
|---|---:|---:|
| Export triangles | 101892 | 126900 |
| Material surfaces | 3 | 6 |
| 1080p frame median, ms | 5.785 | 6.620 |
| 4K GPU median, ms | 5.291 | 5.267 |
| Scene draws, visible + shadow | 416 + 279 | 425 + 282 |
| Death-mode frame median, ms | 5.846 | 7.158 |

These are medians of the three session medians. Gate PASS. Authored base-frame session medians were 5.265, 9.010 and 6.620 ms; 4K GPU medians were 5.031, 5.468 and 5.267 ms. Scene draw counts also include time-varying effects, so the asset surface count is the direct measure of its added draws.

[Legacy fleet measurements](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-557/shots/proof/fleet_legacy.json), [authored fleet measurements](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-557/shots/proof/fleet_authored.json), [piece counts and export manifest](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-557/shots/proof/interiors_cost.json).

Checks:

- `node contrib/opus/tools/run_all_checks.js`: exit 0. Existing baseline only: seven findings and 12 constant differences.
- Export readback and its broken-copy self-test: PASS, including missing interiors, missing seams and liner-only shells.
- `contract_selftest.py`: PASS for the real C15s_23 weapon slots and class/faction hard-point table.
- `authored_interiors_check.gd`: PASS on its stand-in and the written GLB; every authored triangle survives fracture,
  rooms survive wounds, the open face is not blocked by a generic cap, and moving a seam changes piece ownership.
- The optional `--legacy-cache` check: all 36 cached old assets retain the fallback and identical outside triangles.
  A separate comparison against the starting commit's cutter gives identical surface and cap arrays for metal, organic
  and mirrored cases, zero differences.
- Existing `destruction_steps_check`, `death_plane_check`, `death_leap_check`, `damage_surface_check`,
  `playtest_batch3_check`, `destruction_staging_check` and `fx_smoke`: PASS.
- Document paths, test registry, Python syntax, no em dashes and `git diff --check`: PASS.

Limits: no new production ship was designed or baked, and no art approval is claimed for A16/A17 interiors. The fixture
proves transport and exposure. Full rules/campaign parity and unrelated GPU probes were not repeated because no rules or
campaign code changed. The linked captures and measurements are the final proof. No commit or push was made.
