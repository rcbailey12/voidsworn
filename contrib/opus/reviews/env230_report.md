# Environment motion capture, PC completion

Refs #520. Refs #230. All five capture variants are delivered. Ryan's A/B/C choice remains open.

## Changes

Resumed `origin/codex/issue-520` at `1dc189f8`, as the Board's resume note required. Retained the first pass's
main merge, reconciliation, R139 record, R191 size reporting, camera fixes and shipped capture. No Godot game
source changed during this continuation.

- `docs/shots/env230/`: added `periods`, `cap_rocks`, `periods_rocks` and `gas_flat`, plus the B and C choice sheets.
- `docs/shots/env230/capture_counts.json`: records all five runs.
- `tools/pc/jobs/env230_motion.bat`: quoted the comma-separated gas map argument so the batch subroutine receives both maps.
- `contrib/opus/reviews/env230_report.md`: completed the capture results, verdict and checks.
- `godot/world/world_rocks.gd`: issue #541 default change, option B. Rocks turn at the slow cap law unless
  `VS_ROCK_TUMBLE=0`; the cap_rocks capture behaviour is now shipped.

The retained source work includes `world.gd` reporting the measured AS1 rock angle and PL8 planet/rock ratio beside
0.05 rad / 4.4 tuning targets once per map, rather than asserting those visual values. Crash, save and correctness
guards remain. The motion harness checks a stationary camera, 1920x1080 frames and real hull assets.

## Captures

Ran only the four remaining variants through `tools/pc/jobs/env230_motion.bat REPO SHOTS RUN single`, on the PC's
RTX 5080 with Forward+. The job copied `build/godot/gen` and the A4 ship assets, then imported headless. Checked
`queue/running`, active Godot/Blender/ffmpeg jobs and GPU use before each run. The only queue file was the documented
Nov 1 stale A4 entry. Waited for the issue 461 and 271 captures between periods and cap_rocks; neither was stopped.
Their process creation times were after the completed periods run.

The first gas-flat attempt exposed a batch argument bug: an unquoted comma split the map list into separate subroutine
arguments, so only nebula_storm ran. Quoted that argument and reran only gas_flat. Its completed delivery includes
both maps. The one-map attempt is preserved on the PC in `shots/resume/gas_flat_one_map_attempt/`, outside the delivered set.

Every view holds the camera for 30 seconds and samples seven frames, five seconds apart. Each view has a named
sheet, a first-to-last difference image brightened 6x, and its first frame. All delivered images are at most 720 px
tall. The three choice sheets are 1168x720 and put the run name on the image.

| Run | Sheets | Differences | First frames | Purpose |
|---|---:|---:|---:|---|
| shipped | 12 | 12 | 12 | A: retained first-pass baseline, rocks still |
| periods | 12 | 12 | 12 | Wreck periods changed, rocks still |
| cap_rocks | 12 | 12 | 12 | B: rocks turn, slow debris law |
| periods_rocks | 12 | 12 | 12 | C: rocks turn, faster terrain periods |
| gas_flat | 6 | 6 | 6 | Flat gas layer rates on nebula_storm and deep_storm |

54 views, 378 sampled frames: 162 per-view images and three choice sheets. Counts, dimensions and image decoding
were checked across all 165 JPGs. Reviewed the 42 resumed first frames and the B/C sheets; no placeholder blocks.
All four resumed jobs exited 0, logged their done marker, and reported no script, shader, placeholder or motion-guard
errors. The existing shipped set was preserved.

[A: shipped, rocks still](../../../docs/shots/env230/option_A_shipped.jpg).
[B: cap_rocks, slow turning rocks](../../../docs/shots/env230/option_B_cap_rocks.jpg).
[C: periods_rocks, faster terrain periods](../../../docs/shots/env230/option_C_periods_rocks.jpg).

PC review copies of these three sheets: `C:/Users/rcbai/Downloads/voidsworn_test/board/issue-520/shots/resume/`.
The four new per-view sets are in matching run subfolders there. Shipped per-view copies remain in `shots/final/shipped/`.

## Verdict from the difference images

**Shipped moves only wreck pieces among the debris geometry. cap_rocks moves rocks too.** In the shipped graveyard
debris difference, rock shapes stay black while the angular wreck pieces and painted hull fragments are bright.
In cap_rocks, those same rock clusters have bright changing surfaces and outlines, including the large rocks on the
right. The graveyard fields difference also shows the far rocks changing in B. C shows rocks changing as well.

[Shipped debris difference](../../../docs/shots/env230/shipped/boneyard_graveyard_shipped_cine_m_debris_diff.jpg).
[B debris difference](../../../docs/shots/env230/cap_rocks/boneyard_graveyard_cap_rocks_cine_m_debris_diff.jpg).
[B fields difference](../../../docs/shots/env230/cap_rocks/boneyard_graveyard_cap_rocks_cine_m_fields_diff.jpg).

The whole shipped difference image is not wreck-only: gas, the planet, selection rings and board highlights also
animate. The log's changed-pixel shares below include those effects. They are neither percentages of moving debris
nor measurements of spin speed, and differences between runs are not a controlled pixel comparison of gas motion.

| Graveyard run | Debris view changed pixels | Fields view changed pixels |
|---|---:|---:|
| shipped | 13.28% | 5.46% |
| periods | 13.58% | 5.55% |
| cap_rocks | 21.50% | 9.29% |
| periods_rocks | 21.60% | 8.95% |

B is now the shipped default (Board call, issue #541): `rock_tumble_k` in godot/world/world_rocks.gd defaults to the
slow cap law, so backdrop and debris rocks turn; `VS_ROCK_TUMBLE=0` restores the held poses used by the shipped run
above. Ryan can overrule on sight. Gas-flat's six sheets and differences are supplied for NB8's comparison with the corresponding shipped
views; this delivery does not choose new gas rates. Five-second samples do not establish the absence of shimmer
between samples. The shader TIME rollover limitation recorded in the briefs remains.

## Checks and R129 self-check

- `node contrib/opus/tools/env_reconcile_tests.js`: 29 checks, 29 pass, 0 fail at PR 527; issue #541 extends it to 61 checks, 61 pass.
- `node contrib/opus/tools/run_all_checks.js`: exit 0; 42 PASS, 2 KNOWN, 0 FAIL, 0 SKIP at PR 527 (issue #541 rerun: 43 PASS, 2 KNOWN, 0 FAIL). Known baseline: seven findings
  failures (KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5) and 12 constant differences.
- Capture checks: all four resumed jobs exit 0; expected seven-frame views and done markers present; all 165 delivered
  JPGs decode and meet the 720 px ceiling. B and C visibly name their run.
- Callers: retained the first pass's tumble, material, backdrop and station caller sweep. This continuation changes
  no game function or caller. The gas map-list call is verified by capturing both named maps; capture switches are
  confirmed by the batch paths and motion logs.
- Saves and old profiles: no source or data changes; standing save fuzz, progression and old-profile checks passed.
- Twins: no browser oracle, Godot rules, campaign tables or exports changed; oracle_copy_test passed.
- UI: no player flow, screen or setting changed. Camera and window overrides remain capture-only.
- CI: standing checks discover env_reconcile_tests. GitHub's rules parity and game checks are still the branch's
  separate CI jobs; no claim that CI ran on these uncommitted artifacts.

## Scope and limits

Per the resume note, did not redo the main merge, R191 implementation, camera fixes or shipped capture. The only
new harness edit is the quoted gas map-list argument described above. Did not rebuild a Blender station or rerun
full Godot rules/campaign parity: this continuation adds captures and a report,
and both requested check commands passed. The first pass's headless load and R191 probe results remain recorded
in the prior report revision. No new station or terrain look is claimed complete.

Generated import-file changes were preserved in TEMP and restored or moved out of the delivery. No gen files,
ship assets or uid files are included. Logs and helper scripts stay in TEMP. No files were deleted, committed or pushed.
