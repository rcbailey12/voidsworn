# Environment motion capture, PC completion

Refs #520. Refs #230. PC delivery for draft PR 286; Ryan's A/B/C pick remains open. Capture status is below.

## Merge and changes

The runner supplied a fresh checkout. Fetched full history, based `codex/issue-520` on PR 286's head
`3b34bf8a`, and merged `origin/main` (`3ef2c88f`) with `--no-commit --no-ff`. The merge was clean. All 201
main FINDINGS rows are preserved verbatim, plus PR 286's R139 row. The merge remains uncommitted for the runner.

- Retained PR 286's reconciliation, nebula motion record, tumble and gas capture switches, station value reporting,
  station documentation and synthesis pointers. The shipped rock/gas/tumble defaults remain as on main.
- `godot/world/world.gd`: R191 (4) replaces the AS1/PL8 visual asserts with one report per map build: largest backdrop
  rock angle, planet/rock diameter ratio, and the 0.05 rad / 4.4 targets. No planet or rocks reports n/a. Existing size
  tuning remains; crash, save and correctness guards remain.
- `godot/world/world_shots.gd`: motion captures wait for warm-up, suppress the opening glide without launching the
  battle's separate shots routine, disable camera input, verify the camera stays fixed and verify 1920x1080 frames.
  The motion grab now uses main's placeholder guard.
- `tools/pc/jobs/env230_motion.bat`: runs this merged working tree, copies built hulls and A4 assets from `build/godot`,
  imports headless and runs the five variants sequentially. It checks for another GPU job, stops on failed runs or
  script/shader/placeholder errors, and writes names onto images at no more than 720 px tall. Logs stay in TEMP.
- Updated the existing `env_reconcile_tests.js` and the two environment briefs for R191 and the PC capture.

## Checks

- `node contrib/opus/tools/env_reconcile_tests.js`: 29 checks, 29 pass, 0 fail.
- `node contrib/opus/tools/run_all_checks.js`: exit 0; 42 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. The existing baseline is
  seven findings failures (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5) and 12 constant differences.
- Godot 4.7.2 headless `res://tools/ci/load_all.gd`: 157 scripts, 11 scenes, 0 failed.
- A TEMP headless R191 probe measured a planet/rock ratio of 0.040 against target 4.4, then no planet: both printed
  reports and completed without aborting. Final headless checks used normal Windows access and clean logs.
- Python AST parse of `station_kit.py`: PASS, without writing a bytecode file.
- The PC job's busy guard was exercised while the other GPU job was active: it reported the conflict and exited 3
  without starting a capture. The 720 px label step was also exercised on a TEMP test image.

## PC capture status

Shipped is complete: 12 views, 36 named images, all at most 720 px tall. The other four runs are pending while the
GPU is used by the separately launched issue 461 look bench. The partial periods capture was stopped when that
overlap was detected and is not delivered. The job supports a resume run argument, with another job check between
variants. No other task's process has been stopped.

This is an incomplete delivery. Remaining runs: `periods`, `cap_rocks`, `periods_rocks`, `gas_flat`; B and C are not
available yet. After waiting for issue 461's `done_main.txt`, the continuation attempted B first, but a new issue 461
look bench (`opus461/lb/runs/main2_a`, commit `b8e66671`) had already claimed the GPU. The guard exited 3 again, before
copying assets or starting a capture. No deferred environment process remains running. A scheduling choice was asked
in chat; no permission to pause the other task was received. AGENTS.md's "one GPU job at a time" prevents overlapping
the jobs. Do not treat the source merge or the passing checks as proof that the five-run done condition is met.

Resume a single run with `tools/pc/jobs/env230_motion.bat REPO SHOTS RUN single`; omit `single` to run the named
variant and following variants. Use the merged working tree and the existing final shots folder. No commit is made
by that job. The original issue runner's checkout was reused rather than creating a second clone.

The shipped graveyard debris difference image shows turning wreck pieces and black, unchanged rock silhouettes.
Gas, the planet, selection rings and board highlights also animate, so the whole difference image is not wreck-only;
the debris geometry that changes is wreckage. The cap_rocks comparison has not yet been captured.

[A: shipped, rocks still](../../../docs/shots/env230/option_A_shipped.jpg).
[Graveyard debris difference](../../../docs/shots/env230/shipped/boneyard_graveyard_shipped_cine_m_debris_diff.jpg).
PC review copy: `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-520/shots/final/option_A_shipped.jpg`.

The shipped graveyard debris view has 13.28 percent changed pixels; its fields view has 5.46 percent. These are
whole-image measurements, including unrelated gas/planet/board animation, not percentages of moving debris.
The four map reports each measured 0.050000 rad; planet/rock diameter ratios were 6.137 (frontier), 6.145 (nebula),
4.603 (graveyard) and 5.251 (deep). Each report printed once per map and included the 0.05 rad / 4.4 tuning targets.

## R129 self-check

- Callers: searched all uses of tumble_rate, rock_tumble, wreck_tumble, TUMBLE_K, the rock shader material factories,
  _backdrop_scale and the station audit fields. Default rates are preserved in both debris paths, wreck slots and
  painted hull chunks; blocker_visuals uses the default stationary rock material. Both rock and crystal shaders take
  the capture switch. The size report accumulates all five field paths and prints once after fields are built.
- Saves: no save reader, writer, field or format changed. The standing save checks passed, including save fuzz and
  old-profile coverage. No profile or run migration is needed.
- Twins: presentation only. No browser oracle, Godot rule/campaign code, or exported tables changed against main;
  oracle_copy_test passed in the standing suite. No rules export was needed.
- UI: no player flow or UI value changed. Battle/campaign settings and screens retain their current behavior;
  window size and input overrides exist only in the motion harness.
- CI: run_all_checks automatically discovers env_reconcile_tests; GitHub also runs rules/campaign parity and Godot
  game checks. PC rendering is supplied by this delivery. CI has not run on this uncommitted working tree.

## Scope and limits

The rejected first attempts are preserved on the PC outside the delivered image set. Their opening camera glide
and maximized frame size made them unsuitable for comparison. Only the final fixed-camera 1920x1080 run is delivered.
The capture asserts those conditions before accepting frames.

No Blender station rebuild or new station images: this job changes audit reporting and retains PR 286's station
work. No full rules/campaign parity rerun: this is a presentation-only change, with no rule, table or save changes;
the requested standing checks, Godot load check and live rendering cover this task. Shader TIME rollover and the
unbuilt terrain work remain the limitations recorded in the briefs. No files were deleted, committed or pushed.
