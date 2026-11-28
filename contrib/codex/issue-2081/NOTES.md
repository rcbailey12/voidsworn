# CM-A Turn Corner

[Picked concept](../../../docs/shots/issue-2036-codex/CM-A_turn-corner.png)

- Below the KEEL turn block, one portrait and one line at a time. Three messages can wait. Selected section loss comes first, then kills, Commands, other captain section losses and hails. Waiting messages of equal priority keep their arrival order. A high-priority message does not interrupt the one already on screen.
- Section losses ride the existing volley group. Kill announcements use the battle's death playback event and skip Legion knockdowns and downed wings. Kills by the same captain within one second combine, even when the first line is already showing. The opening admiral's line and player Command use that admiral's art. The existing enemy hail log and enemy Command callout stay in place.
- The banner never takes clicks or pauses the battle. Reduce motion removes the slide. Ending or leaving the battle clears the active line and backlog.
- The captain card is part of the existing KEEL selected-ship layout in `ledger.gd`. It stacks above blockers already drawn on the shelf, including the ST-A section-loss strip when the Board combines #2079. No ST-A files are required on this base.
- The Hall of the Fallen uses the same captain identity with a desaturated face. Settlement copies the existing LostShipRecord only when the captain did not escape. Old entries still show their sector.

## Evidence

- `res://ui/battle/test/turn_corner_check.gd` passed all 29 assertions headless. It is registered in `godot/tools/ci/godot_checks.txt`. KEEL readability also passed at 1080p, 1440p and narrow widths.
- The local Godot list and campaign bot passed 249 of 250 checks after reruns. `prefetch_wait_check` still failed because the Windows headless title viewport was 64 by 64. The standing runner also reported Windows shell and PC harness failures.
- The real PC pictures come after green checks and a passed review. Lane C is code only. Capture one labelled `CM-A CAPTAIN` picture from a live section loss and one `CM-A ADMIRAL` picture from a live Command on the combined installed build. Keep each at or below 720 px tall, with its provenance sidecar.

## Run 3 review fixes

- Restored `await _play_death(e, batch_view)` in `battle.gd` alongside the comms kill call. The full diff against `origin/main` (`4a6c1c18b`) showed no other dropped main change in this file.
- The comms clock and active hold now pause while the HUD suppresses the banner. Pending messages still follow the same queue cap and priority rules. Neither the active hold nor queue playback advances until the banner is allowed again.
- `turn_corner_check.gd` opens and closes the battle log to test both an idle banner with a waiting queue and an active banner midway through its hold. All five new assertions failed before the fix and passed after it. The test now seeds the campaign's own random stream, matching the API on merged `main`.
- All 34 Turn Corner assertions passed, including mouse passthrough and battle-end cleanup. KEEL readability, HUD overlap, death view retirement, the all-script load check, and the seed 361 campaign bot battle passed.
- The Windows headless suite passed 260 of 261 checks after retrying eight checks with the right isolated profile or refreshed texture cache. `prefetch_wait_check` still failed its audio timing assertion because no clip reads were pending by the time it checked. The 64 by 64 title warning was separate.
- `node contrib/opus/tools/run_all_checks.js` exited 0 with 126 passed rows and 2 known baseline rows. No GPU captures ran in this pass.
