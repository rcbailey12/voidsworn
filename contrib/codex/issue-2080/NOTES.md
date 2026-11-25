# SY-A Gantry | Refs #2080

The shipyard now keeps fleet selection, the lit ship, and the inspector in view together. The bay reuses the flagship podium and fits the installed mesh at both hull scales. Drag to orbit. With reduced motion on, it holds its angle after the drag.

- The selected captain, hull, single shield pool, weapons, and fitted refits come from the live ship. Total hull wear uses saved HP. Sections lost in the last battle can show as cutouts until repaired. Older saves without section history show wear without invented cutouts.
- Repair, Mark and hull offers read prices and disabled reasons from PreviewOp. A partial repair can read "Repair 18 of 20 for 9". Hover shows the same figures that the campaign applies and does not commit anything. The Chorus yard explains which work takes biomass and which offers fall back to credits.
- No market goods were removed. Late market, captured and standard hulls, recovered cores, and class tracks are below the fleet in the left scroll. Full specs are still on their offers. Manage refits opens the full fleet workspace for removing or swapping fitted gear.
- Decommission sits on its own row, below Repair and Mark. The last ship cannot be sold. Selling a flagship still asks for confirmation, then the existing campaign sale hands on the flag and the yard selects the replacement. No sale settlement or pricing rules changed.
- The CI audio check failed because the Gantry used the quiet click for every transaction. Gantry buttons now use the shared cue roles. Buy Hull plays `ui_reward`, while refit and late-market purchases keep `ui_purchase` from Sound Gate 3.
- Weapon arcs and figures, ability text, and fitted refit effects are on their inspector tooltips.

## Proof

- `shipyard_gantry_test.gd` exercises the visible partial repair quote and charge, read-only hover rows, one reward cue on Buy Hull, a confirmed flagship sale, last-ship protection and responsive layouts.
- The unchanged `audio_check.gd` passes. `desk_polish_2029_test.gd` now selects the ship in the Gantry roster before checking the Decommission row and confirmation flow.
- All 30 seeded campaign runs and the Nemesis records match their saved results byte for byte. The Windows sandbox blocked access to the root certificate store, which the saved-results runner counts as two errors even with no changed records.
- The four local Godot shards and retries passed 229 of 231 game checks. The sparse checkout did not have the two ship-sheet measurements needed by `formation_check`, and `prefetch_wait_check` failed the in-flight audio-read assertion on Windows. Neither check was changed.
- The target is the [SY-A concept](../../../docs/shots/issue-2036-codex/SY-A_gantry.png). It is a layout reference, not an installed capture.

## After green checks and review

Run this on a GPU-enabled PC lane with the current ship assets, Forward+ and the approved GPU queue. Use `tools/pc/tmo.bat 120 <Godot console exe> --path godot --resolution 1920x1080 --script res://ui/campaign/test/shipyard_gantry_test.gd -- --shots <issue-2080 shot directory>`. The script saves one 1280 × 720 shot and its provenance per selected hull, with its code visible in the bay. Use the corvette-sized Warden, which the game classifies as a frigate, and the Daybreak dreadnought. No capture was run in run 2. The Board queues it after review.
