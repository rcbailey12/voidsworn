# PR 1607 review: background CPU work and display settings

Issue 1614. Reviewed PR head `cef51cbe8` against `origin/main` at `bf51646b2` (diff base `0c13bb59d`).

**Recommendation: hold PR 1607.** AA resets correctly at scene build and the three new settings survive a restart. The render scale misses the campaign map, a windowed bot can inherit the player's display settings, and the map's arrival tween still advances while hidden.

## Findings

| # | Finding | OBSERVED/INFERRED | File:line | Exact quote | Why it matters | Fix | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | The Render scale setting misses the sector map. | INFERRED | `godot/main/main.gd:267` | `get_viewport().scaling_3d_scale = rs` | Only Main's viewport is updated. The chart draws its 3D scene to its own `SubViewport` (`godot/ui/campaign/map3d.gd:121-134`), so it stays at 100% when the title says 70% or 85%. | Apply the same normal-play scale policy to the map's viewport and check the other player-facing 3D previews, or label the setting for the 3D scenes it actually controls. | high |
| 2 | A quick-battle bot can pick up the player's display settings. | OBSERVED | `godot/main/main.gd:121,251` | `bot_mode = player_path == null and args.has("bot-runs")` | The guard only identifies `--bot-runs`; `--bot` also starts a quick battle, which the battle script treats as a bot. A windowed `--bot` benchmark through Main can acquire the saved FPS cap and V-Sync even if launched with `--disable-vsync`. Known capture switches such as `--ui-shots` and `--torp-shots` also are not in Main's capture guard. | Use one shared launch-mode check for bot and capture runs, including `--bot` and the battle capture flags. Preserve explicit timing overrides. | high |
| 3 | The map clock stops, but the arrival tween still runs during combat. | OBSERVED | `godot/ui/campaign/map3d.gd:845,1325` | `_arrive(false)` | The jump starts this tween after `enterNode`, and the host defers hiding the UI. A Windows headless probe called the real arrival function and hid the campaign-style `CanvasLayer`: the zoom changed while `_t` stayed still. | Pause and resume `_arrival_tween` with tree visibility, leaving pending loads alone; test it along with the map clock. | high |
| 4 | Switching Low to Max in Settings leaves the running title battle on Low. | OBSERVED | `godot/scenes/battle/battle.gd:336`; `godot/main/main.gd:253-254,377` | `_apply_quality(str(args.get("quality", "max")))` | The AA setter writes the whole state at world build. The title showcase receives quality once at creation; saving a new quality neither updates that showcase nor rebuilds it. The next battle is correct, but the visible title scene cannot show a live Low/Max comparison. | Reapply the quality and look to the running showcase, or mark the Graphics and Temporal AA rows as applying on the next scene and test that transition. | high |
| 5 | The new check can pass without a working map pause or a display-settings round trip. | OBSERVED | `godot/main/test/background_work_1437_check.gd:26,79-86` | `func _process(_delta): pass` | Deleting the production early return would leave the map assertions green. The settings assertions also pass if the new values are never saved or applied. | Drive the real map `_process` across an ancestor hide and show and assert `_t` stops and resumes; exercise a post-return input. Extend the isolated title settings check to press all three rows and reload their saved values. | high |

## godot/main/main.gd

**INFERRED and OBSERVED: defects.** See findings 1, 2 and 4. The startup and save paths apply the settings in normal play. `_load_settings` overlays saved keys on the defaults, and `save_settings` writes the full dictionary. An old settings file without the three new keys keeps 100%, Off, and On. Main already sets V-Sync on in `godot/project.godot`; the new 100% and Off also match the engine defaults.

## godot/main/test/background_work_1437_check.gd

**OBSERVED: defect in the check.** See finding 5. The AA and shadow assertions exercise real setters, but the map assertions call a predicate on a probe that replaces `_process`. The settings assertions only inspect an unsaved instance and constants; none exercises a press, restart, or application of a nondefault value.

## godot/main/title.gd

**OBSERVED: sound.** All three rows use the existing setting controls. The two numeric choices are stored as numbers and their labels match the values read back from JSON; V-Sync uses the existing Boolean toggle. The controls call `main.save_settings()` on each press. The missing-key fallbacks agree with the new defaults.

## godot/render/look.gd

**OBSERVED: sound.** Low selects two directional splits and the soft-low filter; both High and Max select four splits and soft-high. The battle passes its quality to this function with the key light present. Other callers that omit quality still get Max.

## godot/scenes/battle/battle.gd

**OBSERVED: defect in when quality is applied (finding 4).** At scene build the viewport gets all three AA properties: Low is FXAA with MSAA and TAA off; Max restores MSAA 4x with FXAA off and honors TAA; High does the same with MSAA 2x. Hidden HUD and showcase skip plate projection and decluttering, while rings, floats, bot steps and the watchdog still run. The tooltip pattern is unchanged.

## godot/tools/ci/godot_checks.txt

**OBSERVED: sound.** The new check is registered as `headless`, alongside the existing title settings, Continue, and front-end checks. The Godot game workflow reads this manifest through `godot/tools/ci/run_checks.sh`.

## godot/ui/battle/hud.gd

**OBSERVED: sound.** The metadata belongs to the same plate that owns all three cached children. Removal and HUD rebuild discard the plate, so the next plate gets its own references. The two battle call sites keep the same arguments.

## godot/ui/battle/ledger.gd

**OBSERVED: sound.** `plain` and `_without_key` compile the same patterns once and use the same substitutions. The ledger still uses them for the same text measurement and action labels.

## godot/ui/campaign/map3d.gd

**OBSERVED: defect in the arrival tween (finding 3).** The visibility guard is before `_t`, flight, pan, patrol and wake updates. The campaign host hides the parent UI and restores it on both ordinary completion and save-and-quit. The Windows probe confirmed the clock stops and restarts. The input handlers and the loading coroutine are unchanged.

## godot/ui/test/front_end_test.gd

**OBSERVED: sound.** The expected count goes from 18 to 21, matching the three added rows. The existing wrap, control width, and no-scroll assertions still inspect the real drawer at 1920x1080 with Larger UI scale.

## Reach across the game

- Callers: searched PR head across the repo for changed helpers and settings. Traced title save and startup, showcase and battle construction, host hide/show, map and preview viewports, and the HUD and ledger call sites.
- Saves: a scratch profile with no new keys kept the display defaults and the old Sound preference. Real title buttons wrote 85%, 60 FPS, and V-Sync Off; a fresh Main loaded all three. No campaign save field changed; CI's `title_continue_test` passed with an old run.
- Twins: the diff changes no browser rules or exported tables. On the reviewed head, GitHub's table check and both parity runs passed.
- UI: title choices match the saved settings; battles and the title backdrop use Main's viewport, while the sector map and campaign ship previews have separate viewports. Campaign intel and battle data are untouched. The running showcase does not pick up the changed Graphics preset.
- CI: `godot_checks.txt` puts the new GDScript in the Godot game job. The separate standing JS runner also ran on the reviewed head. GitHub reported All checks successful.

## Checks

Local Windows Godot 4.7.2, using the raw PR head in scratch. Headless import completed on retry after the first attempt timed out. The front-end check used placeholder hulls and exited zero.

```text
background_work_1437_check: PASS
Front end: PASS
PASS: all 21 settings names (issue 1437 added Render scale, Frame cap and V-Sync) wrap and stay clear of their control (21 rows, 0 bad)
PASS: title settings update their labels, save each press, and apply UI scale live; an old nebula_wake false no longer keeps the wake off; the Nebula wakes toggle starts on and its Off survives a restart
PASS map clock while actual CanvasLayer is hidden
FAIL hidden arrival tween freeze: 0.8 -> 0.80903680101037
PASS map clock restarts after CanvasLayer show
PASS old profile keeps display defaults and old values
PASS render scale, cap and V-Sync survive save and reload from real title buttons
```

[`cef51cbe8` GitHub checks](https://github.com/rcbailey12/voidsworn/actions/runs/44991226072), read back rather than rerun locally:

```text
title_continue_test: PASS (3 s)
player_path_map_ready_check: PASS (1 s)
PASS: the Godot port matches the game's rules exactly.
PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.
```

`git diff --check origin/main...pr1607`: PASS, exit 0. `PASS: all 10 file verdicts, all 5 exact quotes, ASCII and whitespace`. A merge-tree check found no conflicts against the named main revision. No merge was performed.

## File read record

Raw blobs from the fetched PR head. Last-line prefixes are shown with `\t` for literal tabs. Ranges record the scoped reads of the two large scripts.

| File | Lines | First 40 characters of last line (or whole shorter line) | Large-file ranges read |
|---|---:|---|---|
| `godot/main/main.gd` | 683 | `\treturn str(v)` | |
| `godot/main/test/background_work_1437_check.gd` | 89 | `\tquit(1 if failures > 0 else 0)` | |
| `godot/main/title.gd` | 666 | `\t_reveal_tw.tween_property(_shade, "colo` | |
| `godot/render/look.gd` | 256 | `\treturn m` | |
| `godot/scenes/battle/battle.gd` | 6365 | `\tget_tree().quit(code)` | 200-265, 327-392, 2323-2334, 3347-3357, 5228-5242, 5375-5615, 6124-6136, 6198-6207, 6357-6365 |
| `godot/tools/ci/godot_checks.txt` | 214 | `headless\|main/test/player_path_map_ready` | |
| `godot/ui/battle/hud.gd` | 1422 | `\tledger.mark()` | |
| `godot/ui/battle/ledger.gd` | 962 | `\t\t\t\tact.emit(h.act, h.arg)` | |
| `godot/ui/campaign/map3d.gd` | 1367 | `\t\t_wake_mesh.surface_end()` | 1-220, 260-313, 805-940, 1160-1348, 1367 |
| `godot/ui/test/front_end_test.gd` | 345 | `\tmp.queue_free()` | |

**Next step:** fix the display path and tween in one revision, then repeat the map hide/show and recheck Low to Max and the three display settings on the Windows player path.

**Not checked:** rendered Windows output, live V-Sync and frame pacing, before/after performance, and map input after a full battle on the rendered player path. This was a CPU-only review, so no new screenshots or full player-path recording were made. The full standing and parity runs were read from GitHub rather than repeated locally.
