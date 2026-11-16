# Check-suite hygiene batch: issue 632 report (sweep 545 rows 1, 8, 9, 10 and the retired numbers)

Refs #632. Opus workhorse arm, branch work/issue-632-opus, from main at a1b6454.

The answer: most of the batch was already done on main by PR 571 (issue 563) and PR 573 (issue 564). The one new
fix is item 10. authored_interiors_check.gd no longer hangs on a hull with no authored seams. Every
godot/**/test/*_check.gd now ends by itself, with exit code 1, on any SCRIPT ERROR or when it runs past its time
limit. Item 6 (text floor 17) is left for the Board: PR 544 has landed, but a 17 px floor puts 165 font sizes on five
screens under it, and fixing those changes what the player sees.

## Item by item

| # | Item | Result | Where |
|---|------|--------|-------|
| 1 | opus_check_248, ten NOTEs (the review has ten, the brief says nine) | Already done or by design | NOTE 1: the campaign_ui.gd `R["nem"]` alias reads are gone. NOTE 2: story.gd:141 and :261 read `C.nemRead(run)`. NOTE 3: the statistical checks sit behind --full by design (the 120,000-start run). NOTE 4: the enum row is a gate row; a gate row never SKIPs under --fast, and a gate SKIP counts as FAIL (run_all_checks.js:141, PR 571 354cfce). NOTE 5: own `missingFoe` counter and label (nem_assign_enum.js, PR 571). NOTE 6: the Godot draw is covered by nem_scenarios.gd and parity. NOTE 7: the scenario twins run in their own CI step (checks.yml:99, run_nem_scenarios.sh). NOTE 8: lazy resolve on render is the B4 design; the views now use nemRead (PR 399 6ee551b). NOTE 9: screenshots for a merged PR, nothing to change now. NOTE 10: rival.gd comment names nemRead and nemActive (PR 571). |
| 2 | opus_check_274 pronoun sites | Already done | (a) the Godot modal reads `nemAdaptWhyLine` (campaign.gd:2198, :3096), as JS does (campaign_run.js:359). (b) the strike line goes through `nemStrikeLine` with nemSay on both sides (campaign_run.js:322, campaign.gd:2115). (c) the clock-full line goes through nemSay on both sides (campaign_run.js:320, campaign.gd:2112). PR 571. |
| 3 | opus_check_341: audit.py fails when any gun lacks its mount normal | Already done | tools/recipe/audit.py, PR 571 |
| 4 | opus_check_349: view read-only claim, map3d.gd detail lines | Condition 1 done; condition 2 overtaken | campaign_view.gd header: starts from C.nemRead and never calls nemActive or ensureNemesis; map_readonly_test.gd proves it (PR 399). map3d.gd on main draws no text at all, and "IN FLIGHT" appears nowhere in godot/, so the three unbacked lines no longer exist. |
| 5 | Recipe stages 3 and 4: outline overlap reported, never a pass bar | Already done | ship.py gate prints REPORT; the stage .bat files and standing.py report it (PR 573 2f31f22, RULEBOOK 5.8) |
| 6 | ui_spec_tests.js MIN_TEXT 12 to 17 | Left for the Board | See below |
| 7 | destruction_staging and destruction_steps: opaque insides and cleanup, not piece counts | Already done | staging_check.gd:156 to 198 (every main piece has an opaque torn face, wreck cleanup frees every piece); steps_check.gd:38, :64 (PR 573) |
| 8 | death_leap_check.gd: capital wait from the death timeline | Already done | uses `death_timeline` `tl.end` (PR 573) |
| 9 | audio_check.gd: cues by family, not a total of 67 | Already done | `CUE_FAMILIES` (PR 573) |
| 10 | authored_interiors_check.gd hang, plus a sweep of every *_check.gd | Fixed here | See below |
| 11 | Report only | Reported | driftDifferedCeiling: the guard reports exactly 12 constant differences, so it sits at its ceiling of 12; one more Godot look change that drifts a constant fails the row. The Board decides. glide_bank: no roll. ship_view.gd sets it to 0 everywhere it is written (:789, :1210, :1228, :1286), and the idle drift is a vertical bob only (:1480). fx_ship.gd:647 reads it, so it reads 0. |

## Item 10: what changed

- The cause. On a GLB with no authored seams, `plan.breaks[0]` (line 92 on main) is an index into an empty Array.
  That is a GDScript runtime error, which stops `_run` before its `quit()`, so Godot stays up forever. I reproduced
  it with a plain box GLB written to the temp folder. Main's copy timed out (exit 124 after 90 s); the fixed copy
  exits 1 with `AUTHORED_INTERIORS failures=15`.
- godot/fx/test/authored_interiors_check.gd: the seam move is now its own function, `_move_first_seam`. It runs only
  when there is a first break and a first seam. When there is none, that is a counted failure ("the fracture plan has
  a seam break to move"), and the rest of the check still runs. On the fixture box the output is unchanged:
  `AUTHORED_INTERIORS failures=0 interior_triangles=7320`, the same as main.
- godot/tools/ci/check_guard.gd (new): `arm(tree, name, limit = 240 s)`. It adds a Logger that sees only SCRIPT
  ERRORs, plus a real-time limit. On the first SCRIPT ERROR, or after the time limit, it prints one FAIL line and
  quits with exit code 1 on the next frame. push_error and engine ERR lines are left alone, so checks that count
  their own failures keep their own exit code. Probes in the temp folder proved all three cases: script error gives
  exit 1, a stuck run gives exit 1 after its limit, and push_error plus `quit(3)` gives exit 3.
- The sweep: all 27 godot/**/test/*_check.gd now call `GUARD.arm(self, "<name>")` first thing in `_init`. That is
  one const line and one call line each. In playtest_batch1_check.gd the one-line `_init` was split onto separate
  lines. The slowest check takes 45 s on this PC, so the 240 s limit leaves room on a slower runner.

## Item 6: why it is left for the Board

PR 544 merged on Nov 12 at 08:03 UTC, so the condition is met. But `MIN_TEXT` in ui_scale.gd is read by no game code;
it is only the floor that ui_spec_tests.js scans every font size against. I raised it to 17 in a temp copy of the
test and got 165 sizes under the floor: campaign_ui.gd 111, hud.gd 31, career_screen.gd 16, glass_shell.gd 5,
title.gd 2. Raising the test alone turns the standing checks red. Raising the sizes changes five screens, which the
job forbids ("change no game behaviour ... or art") and which needs pictures. My pick: a text-pass job that raises
those 165 sizes screen by screen with shots, and then sets ui_scale.gd, ui_spec_tests.js:21, ui_spec.md (lines 23,
88) and ui_constants_diff.js:175 to 17 in the same PR.

## Checks run (on this PC, Godot 4.7.2)

- `node contrib/opus/tools/run_all_checks.js`: 46 PASS, 2 KNOWN, 0 FAIL. The two KNOWN rows:
  `findings_tests | KNOWN | KNOWN: 7 listed failure(s): KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5` and
  `oracle_drift_guard | KNOWN | KNOWN: 12 constant difference(s) within the baseline`.
- `tools\pc\parity.bat nopause`: `PASS: the Godot port matches the game's rules exactly.` and
  `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- All 27 *_check.gd were run headless, on main and on this branch. Every exit code is the same except
  authored_interiors_check, which is fixed. death_spawn_check and installed_ship_check exit 1 on both. They are
  `gpu` rows that need the PC's built ship cache and arguments, so they are not run on GitHub.
- `res://tools/ci/load_all.gd`: `load all: 178 scripts, 11 scenes, 0 failed`.
- `node contrib/opus/tools/ui_spec_tests.js`: `170 checks, 170 pass, 0 fail` (unchanged).

## Reach (the five checks)

- Callers: check_guard.gd is used only by the 27 checks. `_move_first_seam` is used only in its own file. No game
  function, constant or save field changed.
- Saves: no save code or field was touched; campaign parity's save hand-off check passes.
- Twins: no root JS file and no rules were touched; both parity runs pass.
- UI: nothing the player sees changed, so there are no screenshots (the out/shots folder is empty on purpose).
- CI: no new test file. The 27 checks keep their rows in godot/tools/ci/godot_checks.txt, and GitHub runs the
  `headless` rows through run_checks.sh, which still applies its own time limit. check_guard.gd is a helper, not a
  check.
