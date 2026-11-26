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
