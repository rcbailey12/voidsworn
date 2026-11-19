# Issue 1124: Battle input and title fixes

- [Battle scene](../../../godot/scenes/battle/battle.gd): Nova and Blink check the marked hexes before leaving targeting mode. A board click uses the release position and current camera. HUD presses and camera drags do not become board clicks.
- [Battle scene](../../../godot/scenes/battle/battle.gd): Changing guns rechecks the current target. An invalid burn-and-fire plan drops the ghost, route and confirm action. A valid plan keeps the weapon selection used to build it.
- [Title settings](../../../godot/main/title.gd): Each toggle and choice updates its own label and saves and applies the change on that press.
- [Campaign host](../../../godot/main/campaign_host.gd): Continue uses the same loader and migration as the campaign. If the run disappears between opening the title and pressing Continue, the host returns to the title.
- [Battle scene](../../../godot/scenes/battle/battle.gd): The threat worker runs after the board catches up to the rules. Hatching, badges, hover tips and the R overlay only use a result for the current revision.

## Checks

The six regressions reproduced the missing ability commands, stale settings labels, wrong hex, stale attack preview, false Continue and stale danger before the fixes. On the fix:

```text
PASS: Nova and Blink fire on marked hexes and ignore unmarked hexes
PASS: title settings update their labels, save each press, and apply UI scale live
PASS: battle picks the release ray after camera motion and skips HUD gestures and drags
PASS: gun changes clear the stale burn-and-fire ghost, card and confirmation
PASS: title offers Continue only for a resumable run, and loads an old run
PASS: a gun knocked out mid-turn is removed from hatching, badges and threat fills
```

- Standing checks: exit 0 with only the two existing `KNOWN` rows. The first parallel run timed out on `tree_effects_test`; it passed on the solo run.
- Godot game checks: `PASS: every listed headless Godot check passed.` All 78 local list entries ran. The first run hit its time limit; the final run also supplied the external fixture paths missing from the temporary test folder.
- Godot import and load: import exited 0; `load all: 233 scripts, 16 scenes, 0 failed`. `bot battle: PASS` on rotation seed 360. `PASS fixture record matches the A16 inputs and compressed GLB`.
- `parity.bat nopause`: `PASS: the Godot port matches the game's rules exactly.` `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`

## Impact sweep

- Callers: Checked mouse and scripted board clicks, number keys and HUD gun buttons, settings rows, the title-to-host handoff, and all threat readers. Scripted hex clicks keep the existing `_on_click()` entry point.
- Saves: Tests use isolated files. They load older settings, a profile-only save, a rejected run, a valid backup, and an old run that still reaches the map. Opening the title leaves the old save bytes alone.
- Twins: No rules, save writers, browser files or exported tables changed.
- UI: The battle ghost, route, card and confirm use the same target plan. Danger hatching, the fleet and active ship, the move tip and the full overlay use the same current result. Continue and initial focus agree with the loaded run.
- CI: All six `*_test.gd` checks are in [godot_checks.txt](../../../godot/tools/ci/godot_checks.txt). GitHub runs them in Godot game checks, beside the standing checks, parity and Godot-only rules safety net.

No captures or frame timing, as requested in the brief.
