# ST-A Stacked Plates

The board shows a standing readout for each visible ship. A selected or hovered plate opens to the exact current loss sentences, which are also drawn on the KEEL ship panel. A plate uses the real shield pool, not a sum of coverage values, and the three hull sections each have their own fill and loss cell. A lost generator hatches the shield track. Strike craft have a hull readout but no section cells.

The plate layer tries the local stack first, then side lanes, then the ST-C edge rail. It uses the actual plate bounds, leaves the KEEL shelf clear, and does not take the board's clicks. Leaders connect displaced plates to their ships. Distant standing plates fold the cells away above camera 220. Camera 26 shrinks plate geometry to about 70 percent while keeping text at the readability floor.

Battle gives the selected ship's highlight and a volley danger cue precedence over quiet footprints. A targeted enemy gets corner brackets. Faction tint stays off the plates under Rulebook 9.6. Engine loss is labelled as damage, not zero thrust, because the rules leave steerage speed.

## Evidence

Run `godot --headless --path godot --script res://scenes/battle/test/ship_state_plates_check.gd`. It restores the recorded seed-10 Battle 2 round-3 positions from `docs/shots/player_path_1119/seed-10.jsonl` and uses the live ship templates in the actual battle scene. The check first requires a footprint collision in that formation, then checks the meshes that remain visible and the final plate rectangles. It exercises hover, zoom, the edge rail and loss text from real section damage. The check is registered in `godot/tools/ci/godot_checks.txt`.

The headless fixture placed all four recorded ships' plates at camera 170 with zero intersections between plates, HUD or visible footprints. The hit timing, HUD overlap, KEEL readability, plan commit and camera input checks also passed locally. This checks layout and state, not the look of the installed hulls.

## Visual handoff

The [ST-0 reference](../../../docs/shots/issue-2036-codex/ST-0_crossing-rings.png) is from Battle 2, part 2 at 00:25.000, seed 10, round 3. The [ST-A concept](../../../docs/shots/issue-2036-codex/ST-A_stacked-plates.png) is the approved layout, not current game art.

The Board queues the matched real captures at camera 170 and 26 after review and green checks. Use a capture path that includes the battle HUD, since the effects-only look bench does not draw it. No GPU work ran in lane F.
