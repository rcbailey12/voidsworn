# ST-A Stacked Plates

The board shows a standing readout for each visible ship. A selected or hovered plate opens to the exact current loss sentences, which are also drawn on the KEEL ship panel. A plate uses the real shield pool, not a sum of coverage values, and the three hull sections each have their own fill and loss cell. A lost generator hatches the shield track. Strike craft have a hull readout but no section cells.

The plate layer tries the local stack first, then side lanes, then the ST-C edge rail. It uses the actual plate bounds, leaves the KEEL shelf clear, and does not take the board's clicks. Leaders connect displaced plates to their ships. Distant standing plates fold the cells away above camera 220. Camera 26 shrinks plate geometry to about 70 percent while keeping text at the readability floor.

Battle gives the selected ship's highlight and a volley danger cue precedence over quiet footprints. A targeted enemy gets corner brackets. Faction tint stays off the plates under Rulebook 9.6. Engine loss is labelled as damage, not zero thrust, because the rules leave steerage speed.

## Evidence

Run `godot --headless --path godot --script res://scenes/battle/test/ship_state_plates_check.gd`. It restores the recorded seed-10 Battle 2 round-3 positions from `docs/shots/player_path_1119/seed-10.jsonl` and uses the live ship templates in the actual battle scene. The check first requires a footprint collision in that formation, then checks the meshes that remain visible and the final plate rectangles. It exercises hover, zoom, the edge rail and loss text from real section damage. The check is registered in `godot/tools/ci/godot_checks.txt`.

The headless fixture placed all four recorded ships' plates at camera 170 with zero intersections between plates, HUD or visible footprints. The hit timing, HUD overlap, KEEL readability, plan commit and camera input checks also passed locally. This checks layout and state, not the look of the installed hulls.

## Run 4 review findings

- **Fixed, Codex sweep, Artoo, Neon and Duet (R458):** The actual kill cut-in keeps only the attacker and target plates readable, including after the target dies or its model hides. Cut exit retires the dead plate immediately. Ordinary dead and fled plates still retire, hidden plates do not allocate, and cut-in tooltips stay suppressed.
- **Fixed, Codex sweep, Artoo and Neon:** The plate reads hull and the shared shield pool from impact playback. The hit event now carries the rules' resulting section fraction for the affected cell. A section loss uses the same loss projection as KEEL, and a rise restores the plate before the final batch sync. A late impact cannot apply damage a second time after sync.
- **Fixed, published shard 1:** The death view retirement check now exercises the replacement plate layer. Its no-allocation, retirement and Eclipse rise assertions still run.
- **Not reproduced, older Artoo CI findings:** The replacement plate is already used by the KEEL readability test and the HD9 standing check. The new cut-in and meter cases are in the existing ship plate check.
- **Merge repair:** Audited the two files from the actual pre-merge base to the Board's main parent. Main's dead-plate cleanup and cut-in fade now run through the new plate layer. Main's cut-in tip guards were already present, and the old hidden-plate no-allocation change is already covered by the replacement layer. PR #2225 is still separate and was not merged here.

The final Windows game pass covered all 254 listed checks, including two environment-only reruns. The formation test used the tracked SF3 and SB4 measurements in scratch. The unchanged prefetch test passed with CI-style audio imports omitted in a disposable copy. The separate seed-361 bot battle passed. All 379 saved battles, 30 seeded campaigns and the Nemesis scenarios matched.

## Visual handoff

The [ST-0 reference](../../../docs/shots/issue-2036-codex/ST-0_crossing-rings.png) is from Battle 2, part 2 at 00:25.000, seed 10, round 3. The [ST-A concept](../../../docs/shots/issue-2036-codex/ST-A_stacked-plates.png) is the approved layout, not current game art.

The Board queues the matched real captures at camera 170 and 26 after review and green checks. Use a capture path that includes the battle HUD, since the effects-only look bench does not draw it. No GPU work ran in lane F.

## Run 5: combine #2104 and #2253

Tested the working tree on checkout head `fd1eb43ae7d0f23a18b302cb3d362729cc7bf8b8`, which already includes `origin/main`. Ported the compatible hunks from #2253 at `2856c8e8439a98a099a2842ffa6ade7850ccb1b4`. No merge, commit, or push in this run.

- **Kept ST-A:** Its plate layer, overlap and ring handling, and the kill cut-in that keeps both participants readable until the target can retire. The existing `floats_root` in `godot/ui/battle/hud.gd` already provides the separate callout layer.
- **Kept hit callouts:** `godot/scenes/battle/battle.gd` applies the label's own lifetime fade once, without the board fade. `godot/render/test/big_moments_check.gd` checks Miss, Critical, and shield numbers at full and partial alpha during lance and torpedo cuts.
- **Kept camera skip:** A left or right click ends the kill hold without starting a drag or board gesture. The big-moments check also snapshots the drawn pose before starting the return and checks the shot against the 9 percent letterbox.
- **Kept muzzle pulses:** `godot/fx/fx_weapons.gd` keeps muzzle pulses out of the flash budget while still softening them under Reduce Flashing. `godot/fx/test/weapon_layers_check.gd` keeps the upstream budget, tracer tint, rocket soot, and nonzero-clock checks. Torpedo intercepts still book a flash.
- **Dropped the competing plate hunks:** No new participant or deferred-death state in battle setup, shot and kill framing, cut release, overlay stepping, death retirement, or per-frame plate updates. No `cut_plates_root`, HUD rebuild changes, reparenting, or second `floats_root` in the HUD. Removed the upstream plate-specific assertions, including zero plate-root alpha and reparenting. The unchanged ST-A check owns participant visibility and dead-target retirement.

The new callout, skip click, and muzzle checks failed before the fixes and passed after. The seed-10 Battle 2 round-3 check placed all four plates with no overlaps and no crossing visible rings. The load check passed for 488 scripts and 17 scenes. The seed-361 bot battle passed.

All 254 listed headless game checks passed locally across the full run and eight environment-only reruns. Six needed the CI profile path, prefetch needed CI-style audio imports omitted, and formation needed the tracked SF3 and SB4 measurements missing from the sparse checkout. Standing checks exited 0 with the recorded KNOWN rows. All 379 saved Godot battles, 30 seeded campaign runs, Nemesis scenarios, and the tree hand-off passed. The rules cache on/off records matched for all 379 battles, and all 15 ruled-number checks passed. The checked-in A16 death fixture is stale on the unchanged inputs. A fresh A16 bake is left to CI, as this lane is code only.

PR #2253 can close as included once the runner publishes the combined changes on #2104 and GitHub's All checks is green. The Board owns the real ST-0 before and after captures at cameras 170 and 26 after review.
