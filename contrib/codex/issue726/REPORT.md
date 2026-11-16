# Issue 726 run 3: approved normal-bake proposal still fails A20

The done-when is not met. The approved normal-only fix was applied, but A20 still exhausted Cycles' SVM stack in five hull
materials during its normal pass. Blender returned zero and wrote its completion marker. The new stage 5 guard caught the
errors and returned 1, stopping before stage 6, export or installation. No new ship was installed.

Changed files:

- `tools/blender/kits/shared/paint_stack.py`: the approved temporary normal-only surface and restoration in `finally`.
- `tools/recipe/5_paint_bake.bat`: reject nonzero Blender exits and shader compile errors even after a zero exit.
- `docs/ship_pipeline/RECIPE.md`: the normal-bake method, guard and observed remaining failure.
- `tools/pc/jobs/HB_PAINT_726.bat` and its two helpers: recovered run 2's checked route, require the merged geometry,
  add diagnostic controls and revision/stage labels, capture the playable build after installation, preserve evidence.
- `contrib/codex/issue726/`: diagnostics, compiler probes and run notes; `docs/shots/look_bench/hullbreaker_paint_726/README.md`:
  the stopped-run status. No accepted painted pictures were produced.

Checks and results:

- A20 stage 4: PASS, including the contract, audit and audit self-test. Concept overlap 65.8%; camera-170 overlap against
  the shape reference 76.1%. These are reports, not pass bars.
- Real A20 stage 5: FAIL. `ps_iron_H`, `ps_soot_H`, `ps_soot2_H`, `ps_blood_H` and `ps_rust_H` still overflow.
- Stricter isolated-normal compiler probe: FAIL too. Removing every node outside the existing normal input leaves 919 nodes
  in those zones, and still overflows on a 64-pixel map. The problem is not solved by disconnecting or pruning unused colour
  branches. This diagnostic method was not applied to live code.
- Fixture diagnostic: PASS. Maximum float differences 0 without a linked normal and `1.1920928955078125e-7` with bump;
  original shader graphs restore on success and an injected operator failure.
- Eclipse E11, real 4096 map at 64 samples: PASS within the unchanged-code repeat range. 6,811 of 50,331,648 RGB channels
  differ, maximum 3/255, RMS 0.0126 of one 8-bit step. The original bake's repeat also reaches 3/255 (RMS 0.0082).
  This is a measured pixel diff, not identical hashes.
- Stage 5 guard: PASS, six compile-error messages, a nonzero Blender exit and a clean completion. The real A20 failure also
  proves the zero-exit/error-log case stops the stage.
- A16 fixture record: PASS before and after. Installed-asset hashes: PASS for A16's GLB and 286 other ship files; 17 recorded
  source inputs still match. PowerShell/Python syntax, no-em-dash scan and `git diff --check`: PASS.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, 58 PASS, 2 KNOWN, zero FAIL or SKIP. The seven findings and twelve
  oracle constant differences remain within their existing baselines. Windows runner self-tests pass all 37 cases.

Method: main `225b10ae`, including PRs 866, 884 and 898; current [A20 build sheet](../../../docs/ship_pipeline/build_sheets/corsair_A20/),
`tools/recipe/ships/corsair_A20.json` and the current Hullbreaker stack. No sheet, geometry, palette or fixture input edits.
No new export manifest exists because stage 7 was not reached. A20's rejected raw bake took 242.7 seconds versus hb682out's
230.6 seconds, and reports 226,314 exterior triangles and five merged surfaces before export. This is not an accepted paint
or performance result.

Evidence on Ryan's PC:

- [Run status](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/status.txt)
- [Failure and compiler node counts](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/diagnostic/failure_summary.json)
- [Full A20 bake log](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/A20/log_bake.txt)
- [Normal-only compiler probe](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/diagnostic/compiler_isolate.log)
- [Captured A20 normal input, compressed blend](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/diagnostic/A20_normal_input.blend.gz)
- [Fixture comparison](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/diagnostic/normal_bake_diagnostic.json)
- [E11 pixel diff and hashes](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/diagnostic/ship_normal_diagnostic.json)
- [Unchanged installed assets](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/diagnostic/install_unchanged.json)
- [Standing check results](C:/Users/rcbai/Downloads/voidsworn_test/board_b/issue-726/shots/run3/standing_checks.log)

Skipped because A20 failed: its surface/render/paint checks, the other four ship bakes, every stage 6 and 7, installed-ship
checks, the scene gate and all ten new painted/installed proof pictures. Before captures are kept in `shots/run3/before/`;
they are not presented as the result of the fix. The recipe's current A20 blend/maps are failed output and must not be
installed. Completing the job needs a normal-bake repair beyond the approved proposal. Nothing was committed or pushed.
