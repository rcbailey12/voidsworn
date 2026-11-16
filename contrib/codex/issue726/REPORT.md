# Issue 726: paint run stopped before installation

PR 866 is included in source commit `5c5fdbcdd4575a673cd9c21016f6eabd37f060b6`, and GPU clearance was present. The run captured
the five installed ships, then rebuilt A20 from the current sheet with its new hangar cheeks. Its stage 5 bake logged Cycles
`out of SVM stack space` for five hull materials during the detail-normal pass, despite Blender exiting zero. The run was
stopped before stage 6, export or installation. No new ship was installed.

Files added:

- `tools/pc/jobs/HB_PAINT_726.bat` and `hb_paint_726.ps1`: the existing HB_PAINT_R240 route with explicit exit checks,
  before/after captures, GPU-slot watchdogs and a check for the observed shader error.
- `tools/pc/jobs/hb_paint_726_pictures.py`: labeled concept / before / after sheets at 1280 x 720, preserving game pixels.
- `contrib/codex/issue726/normal_bake_diagnostic.py`: isolated fixture comparison and shader-restoration check.
- `contrib/codex/issue726/proposed/`: whole-file proposed copies of the shared normal-bake fix and recipe note. The live shared
  code and recipe are restored. Applying this proposal and resuming installation awaits approval.

Checks completed:

- Copied PC ship assets: all 252 files match the source manifest.
- Godot headless import and five before captures: exit 0.
- A20 stage 4: PASS, including the build contract, audit, audit self-test and outline records. Concept-camera overlap is
  65.7%; battle-camera overlap is 76.5%. These are reports, not pass bars.
- A20 six-view surface check: PASS, zero room-colour pixels and zero bare-surface pixels.
- Proposed normal-bake fixture: PASS. Maximum float differences are 0 for an unlinked normal and
  0.00000011920928955078125 for a bump-linked normal. Original node counts and shader links are restored on success and after
  an injected operator error. This does not yet prove the large A20 shader compiles with the proposal.
- Launcher syntax, Python syntax and `git diff --check`: PASS.
- Standing checks: exit 0, 58 PASS, 2 KNOWN, zero FAIL or SKIP. The known findings and oracle-drift categories remain within
  their existing baselines.

Method: current Hullbreaker sheets and faction stack; no sheet, geometry, palette or fixture-record edits. A20's raw bake
took 197.4 seconds versus 230.6 seconds in hb682out, but the new result is not accepted because of the compiler errors.
Its baked model reports 96,022 exterior triangles and five merged exterior surfaces. These are pre-export costs.

Evidence on Ryan's PC:

- [Run status](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/status.txt)
- [Failure summary](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/diagnostic/failure_summary.json)
- [Fixture result](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/diagnostic/normal_bake_diagnostic.json)
- [A20 surface check](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/diagnostic/surface_check.json)
- Before captures are in `C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/before/`, named by game code.

Skipped: the remaining four bakes, all stage 6 costs, stage 7 exports/installs, installed-ship checks, after captures and the
scene gate. The run must resume and produce all five concept / before / after sheets before issue 726 meets its done-when.

Automatic approval review rejected restarting the full run with an unreviewed shared pipeline change beyond the paint-only
brief. The proposed fix is kept separately for approval. Nothing was committed or pushed.
