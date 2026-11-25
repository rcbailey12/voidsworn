# SY-A Gantry | Refs #2080

The shipyard now keeps fleet selection, the lit ship, and the inspector in view together. The bay reuses the flagship podium and fits the installed mesh at both hull scales. Drag to orbit. With reduced motion on, it holds its angle after the drag.

- The selected captain, hull, single shield pool, weapons, and fitted refits come from the live ship. Total hull wear uses saved HP. Sections lost in the last battle can show as cutouts until repaired. Older saves without section history show wear without invented cutouts.
- Repair, Mark and hold refits show their actual PreviewOp changes. New Hull goes to the stocked offers, where hovering shows the candidate hull and its PreviewOp rows. Hover never commits. Disabled actions give their reason above the button.
- No market goods were removed. Late market, captured and standard hulls, recovered cores, and class tracks are below the fleet in the left scroll. Full specs are still on their offers. Manage refits opens the full fleet workspace for removing or swapping fitted gear. The Gantry protects the current flagship from being decommissioned in this screen. The existing sale settlement, prices, and campaign rules were not rewritten.
- Weapon arcs and figures, ability text, and fitted refit effects are on their inspector tooltips.

## Proof

- `shipyard_gantry_test.gd` exercises live roster and action controls, one shield pool, the exact repair readout, PreviewOp values, no state changes on hover, and narrow and large text layouts.
- All 30 saved campaign seeds and the saved Nemesis records match byte for byte.
- The target is the [SY-A concept](../../../docs/shots/issue-2036-codex/SY-A_gantry.png). It is a layout reference, not an installed capture.

## After green checks and review

Run this on a GPU-enabled PC lane with the current ship assets, Forward+ and the approved GPU queue. Use `tools/pc/tmo.bat 120 <Godot console exe> --path godot --resolution 1920x1080 --script res://ui/campaign/test/shipyard_gantry_test.gd -- --shots <issue-2080 shot directory>`. The script saves one 1280 × 720 shot and its provenance per selected hull, with its code visible in the bay. Use the corvette-sized Warden, which the game classifies as a frigate, and the Daybreak dreadnought. No capture was run on lane D.
