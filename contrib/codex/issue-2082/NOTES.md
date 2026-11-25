# Issue 2082 | AR-A Spotlight Report

Built the picked [AR-A layout](../../../docs/shots/issue-2036-codex/AR-A_spotlight-report.png) without copying the concept art or figures.

- Victory and defeat use the same table. The MVP uses applied damage and the printed formula. Captain XP and earned ranks moved onto the ship rows. Old reward saves with no rollups retain their original XP lines.
- Credits or faction proceeds, repairs, confirmed weaknesses, captain escape lines and salvage remain reachable. Salvage follows the report and uses the same actions as before.
- A lost ship stays on its battle row. View killmail and the run timeline's Loss records open the same card from the recorded loss. A ship that reassembled is not a loss. The overlay closes with Escape, the Close button or an outside click. Opening it does not change the run or save.

## Verification and review pictures

`res://ui/campaign/test/after_action_report_test.gd` is registered in the headless check list. It settles a seeded combat victory, Eclipse reassembly and a defeat in the campaign and exercises the rendered cards. The test covers MVP weights and tie-breaks, promotion XP, all killmail fields, hazards, both entry points, save reload, focus and dismissal.

The headless report and neighboring reward and debrief checks passed. All 379 reviewed battle results, 30 seeded campaign runs and the Nemesis scenarios matched the saved results. The local Windows run passed 221 of 222 listed headless game checks after reruns. The remaining title layout check in `prefetch_wait_check.gd` sees a 64x64 window on Windows headless, even with a 1920x1080 resolution request.

After green CI and a passed review of this revision (RULEBOOK 3.12), run the same script on the PC through `tools/pc/tmo.bat`, using Forward+ at 1920x1080 without `--headless`. Pass `-- --shots C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-2082\shots` after the script path. It writes and stamps `AR-A_victory.png` and `AR-A_killmail.png` at 1280x720 with provenance sidecars. The capture fixture uses the real game UI and rules with seeded hits, not the concept art.
