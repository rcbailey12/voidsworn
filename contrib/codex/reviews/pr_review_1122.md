# Technical review for issue #1574

Reviewed against `main` at `e41b5570`, the runner snapshot. GitHub and local PR heads matched. Line numbers refer to the revision named in each section unless marked main.

On a temporary copy of main with all three Godot patches applied, four headless checks passed with exit 0. These were `hull_wear_check`, `hold_beacon_check`, `close_action_fx_check`, and `close_action_moments_check`. The moments check logged the same certificate-store, placeholder-hull, and Rect2 diagnostics on untouched main. Two extra probes reproduced the repair and stale manifest findings below. `git diff --check` passed for all three patches.

**Not checked.** Real-ship rendering, GPU frame times, cold Hold entry timings, and an end-to-end campaign reload. Headless checks used stand-ins. The full standing suite was outside this review.

## PR 1570 | Hull wear

Reviewed head `e06a4823`. **Verdict is merge after fixes.**

### OBSERVED

1. **Medium | A shield-only hit can choose the crippled ship’s list on the next sync.** `godot/fx/fx_weapons.gd:1862` quotes `fx.later(T, func l_hit_react() -> void: Tg.hit_react(fx, imp, lhp, ldr))`. That callback is queued before the shield-only branch returns. It overwrites `last_hit` (`godot/fx/fx_ship.gd:1164`), which the wear code reads for its list (`godot/fx/fx_ship.gd:1370`). A ship with regenerated shields can therefore start leaning toward a shield hit on the opposite side, even though its hull took no new damage. Use a separate last hull impact and update the list direction when that impact lands. Cover an opposite-side shield hit on an already crippled ship.
2. **Low | A small final repair can leave the wear shader dirty.** `godot/fx/fx_ship.gd:1378` quotes `if absf(hull_wear - _wear_shown) > 0.02 or _wear_marks != _marks.size():`. A headless probe synced a fresh view at 79% HP, then repaired it to 80% with the same section stages and mark count. The model wear fell to zero and the shader weather stayed at 0.0075. Force a material refresh when crossing to zero and cover a repair within the same section stages.

### INFERRED

3. **Low | A rebuilt damaged ship cannot recover which side took the hits.** `godot/fx/fx_ship.gd:1410` quotes `for j in _marks.size():`. The first sync of a fresh ship view restores HP-based wear from the unit state. Side soot depends on live marks and the list defaults to the positive side without `last_hit`. Campaign Continue rebuilds the view from a rules snapshot (`godot/rules/API.md:191` on main). HP and section wear can be restored, while side-specific soot can disappear and the lean can change sides. Decide the reload behavior explicitly. Use a neutral fallback when the hit side is unknown, or save and restore the minimal impact history if continuity is required.

The damage shader template is shared, and each affected mesh surface gets a per-ship duplicate (`godot/fx/fx_ship.gd:1916`). The added per-frame list work is math and a visual root rotation while settling. Battle facing comes from the rules view and `cur_yaw` (`godot/scenes/battle/battle.gd:913`).

## PR 1561 | Navy Relay hold beacon

Reviewed head `89de211d`. **Verdict is merge after fixes.**

### INFERRED

1. **Medium | Cold Hold entry can stall on the Relay load.** `godot/render/board.gd:997` quotes `var n := A4P.beacon(BEACON_LEN)`. The terrain build loads and instantiates the Relay synchronously. The installed PC manifest resolves O3_11 to a 4.8 MB scene. The stub geometry check cannot measure first-load cost. Measure cold Hold entry with that scene installed and put the scene on the Hold-only preload path if the terrain step exceeds its budget. This is the loading seam Artoo flagged for #1445.

### OBSERVED

2. **Low | A stale Relay manifest entry produces a load error on every Hold build.** `godot/assets/ships/a4_props.gd:29` quotes `var ps = load(str(m["ships"][code]["res"]))`. A manifest with no O3_11 entry returns before the load. A headless probe with the entry still present and its scene missing logged two resource errors and produced zero beacons. Check that the resource exists before loading, and cover an O3_11 manifest entry pointing at a missing scene. The current no-beacon fixture removes the whole entry (`godot/render/test/hold_beacon_check.gd:83`).

The generated manifest and its O3_11 scene are present in the installed PC build. The beacon is a child of Terrain, which the board frees when rebuilt (`godot/render/board.gd:257`). Hex picks intersect the board plane and resolve its coordinates (`godot/scenes/battle/battle.gd:3788`).

## PR 1549 | Boarding looks

Reviewed head `e520b5ce`. **Verdict is merge after fixes.**

### INFERRED

1. **Medium | Look C can outlast its hold when another effect slows the FX clock.** `godot/fx/fx.gd:484` quotes `var dt = delta * _speed`. The battle wait uses a scene timer (`godot/scenes/battle/battle.gd:1204`) and the lines use a scene tween, while C starts and expires its inside sprites against FX `now` (`godot/fx/fx.gd:1893`). A lingering hit pause or death slow-motion beat can let the next event start while C still shows pops. Drive the brief inside pops from the hold clock and check actual expiry with the FX clock slowed. The current test reads the scheduled end time (`godot/fx/test/close_action_fx_check.gd:145`).

### OBSERVED

2. **Medium | The hatch width is shared across battles and look variants.** `godot/fx/fx_breach.gd:67` quotes `static var board_k := 1.0`. Every `fx.board` overwrites it (`godot/fx/fx.gd:1851`), and rebuilding a mark from its recorded hit reads the current shared factor (`godot/fx/fx_breach.gd:1884`). For example, draw r0, switch to B, then change the first target’s section damage enough to regrade. Its r0 hatch is rebuilt at B width. Store the width on each boarding mark and pass it through repeat-hit and regrade rebuilds.
3. **Low | r0 can show the breach on a different side from the baseline it stands for.** `godot/fx/fx.gd:1842` quotes `if absf(tl.z - s.hull.core.z) < s.hull.W * 0.75 and cam != null:`. The camera-side override also runs for r0. Before this PR, the same near-centre approach picked the side from the attacker regardless of the camera. The before shot can therefore overstate current main’s breach visibility. Preserve the old side choice for r0, or capture the before shot from main.

B is the default. A, C, and r0 remain selectable for Ryan’s comparison. The lines have per-node materials and a queued free at the end of their tween (`godot/fx/fx.gd:1942`). The light is pooled with a fixed three-second life (`godot/fx/fx.gd:1871`), so the vent and its light can still be visible after an accelerated hold.
