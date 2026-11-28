# Issue 2082 | AR-A Spotlight Report

Built the picked [AR-A layout](../../../docs/shots/issue-2036-codex/AR-A_spotlight-report.png) without copying the concept art or figures.

- Victory and defeat use the same table. The MVP uses applied damage and the printed formula. Captain XP and earned ranks moved onto the ship rows. Old reward saves with no rollups retain their original XP lines.
- Credits or faction proceeds, repairs, confirmed weaknesses, captain escape lines and salvage remain reachable. Salvage follows the report and uses the same actions as before.
- A lost ship stays on its battle row. View killmail and the run timeline's Loss records open the same card from the recorded loss. A ship that reassembled is not a loss. The overlay closes with Escape, the Close button or an outside click. Opening it does not change the run or save.

## Verification and review pictures

`res://ui/campaign/test/after_action_report_test.gd` is registered in the headless check list. It settles a seeded combat victory, Eclipse reassembly and a defeat in the campaign and exercises the rendered cards. The test covers MVP weights and tie-breaks, promotion XP, all killmail fields, hazards, both entry points, save reload, focus and dismissal.

The headless report and neighboring reward and debrief checks passed. All 379 reviewed battle results, 30 seeded campaign runs and the Nemesis scenarios matched the saved results. The local Windows run passed 221 of 222 listed headless game checks after reruns. The remaining title layout check in `prefetch_wait_check.gd` sees a 64x64 window on Windows headless, even with a 1920x1080 resolution request.

After green CI and a passed review of this revision (RULEBOOK 3.12), run the same script on the PC through `tools/pc/tmo.bat`, using Forward+ at 1920x1080 without `--headless`. Pass `-- --shots C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-2082\shots` after the script path. It writes and stamps `AR-A_victory.png` and `AR-A_killmail.png` at 1280x720 with provenance sidecars. The capture fixture uses the real game UI and rules with seeded hits, not the concept art.

## Recovery on `4a6c1c18b`

Verified the saved `a6d93b8f9` Spotlight patch against `origin/main` at `4a6c1c18b`. The branch still differs from main in exactly the eight delivery files. Only the Spotlight test fixture needed code changes. It now seeds the campaign's own RNG and accepts the second volley callback argument. No game code or save schema changed in this pass.

Spotlight, debrief and reward flow passed on Godot 4.7.2 headless, including the Spotlight save reload. All 379 battles, 30 seeded campaign runs and the Nemesis scenarios matched the saved results.

260 of 261 listed game checks passed locally after rerunning onboarding with its supported temporary profile. The one remaining failure, `prefetch_wait_check.gd`, reproduced on untouched `4a6c1c18b`. Its audio assertion found no pending clip reads when the sound was made. The 64x64 title layout message was a separate diagnostic. The committed A16 fixture is stale, with no changed fixture inputs in this branch. CI handles its fresh bake. No GPU captures were run.

The Godot rules safety net passed. The standing suite reported 125 passes, two known baseline results and one Windows `runner_selftest` failure. The isolated rerun of that self-test passed all 146 assertions. GitHub's All checks result is not verified by this local run.
