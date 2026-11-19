# Issue 1118: Death, wreck and jump cleanup

Fixed findings 3, 4, 8 and 10 from the [FX audit](../audit_1118/fx_render.md), on top of PR 1134's breakup changes.

- [FX session](../../../godot/fx/fx.gd) and [breakup](../../../godot/fx/fx_death.gd): the session owns each cut until it joins the worker. Leaving the battle drains that list before dropping callbacks, even for a cut replaced by a lance or detached on ship removal.
- [Ship view](../../../godot/render/ship_view.gd) and [battle](../../../godot/scenes/battle/battle.gd): Eclipse reassembly clears the old wreck and cancels its remaining blasts. It restores the fitted pose, mesh and live paint, then uses the risen health and shields from the current event batch.
- [Ship FX](../../../godot/fx/fx_ship.gd): jump removes the collider at the same moment the hull disappears. Death, jump and removal share collider and attached effect cleanup. Ordinary wrecks still survive removal of the original ship view.
- [Breakup](../../../godot/fx/fx_death.gd) and [battle](../../../godot/scenes/battle/battle.gd): the slow beat starts on the frame that spawns the core flash. The camera holds through that flash and keeps its existing tail. An on-time cut keeps its existing split and flash schedule. If a first cut misses the death deadline, the existing no-pieces flash and debris play without waiting for the worker.

## Checks

[Death plane](../../../godot/fx/test/death_plane_check.gd) and [kill slow motion](../../../godot/fx/test/kill_slowmo_check.gd) reproduced all four faults on `8489b8db`:

```text
FAIL death-cut workers joined on battle exit
FAIL Eclipse takes back its wreck and live paint
FAIL jump removes the collider as the hull leaves
FAIL late core flash, slow motion and camera hold
FAIL deadline fallback cue
```

With the fix, the same two headless checks reported:

```text
PASS death-cut workers joined on battle exit
PASS Eclipse takes back its wreck and live paint
PASS jump removes the collider as the hull leaves
DEATH_PLANE failures=0
PASS late core flash, slow motion and camera hold
PASS deadline fallback cue
KILL_SLOWMO cruiser core 1.66 beat 1.67-1.84 | capital core 2.28 beat 2.30-2.47 | failures=0
```

- Standing checks: 74 PASS, 2 KNOWN (existing baselines), 0 FAIL. `PASS: every fx_death picture records its spawn and the vent uses the hull ray`. The oracle check also passed on its own: `PASS: no oracle folders exist and both committed tables equal a fresh export from the root game files`.
- PC parity: `PASS: the Godot port matches the game's rules exactly.` All 284 battles matched. `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- Godot game: `load all: 239 scripts, 16 scenes, 0 failed`; `bot battle: PASS` (seed 360); `PASS fixture record matches the A16 inputs and compressed GLB`. Headless import completed on retry.
- Godot list: 81 of 84 passed in the list runner, including `death_leap_check: PASS`, `death_plane_check: PASS`, `destruction_staging_check: PASS`, `kill_slowmo_check: PASS`, `destruction_steps_check: PASS`, `death_seam_check: PASS` and `fx_smoke: PASS`. The first list run reported `FAIL: 3 Godot check(s) failed.` because three tests refused the Windows user directory supplied to that run. All three passed when rerun with the isolated Windows paths they require: `ONBOARDING PASS`, `PASS: title settings update their labels, save each press, and apply UI scale live`, `PASS: title offers Continue only for a resumable run, and loads an old run`.
- No captures or frame timing, as requested.

## Impact sweep

- Callers: traced FX submission, collection, teardown and core timing through battle, the live bench and tests. Bench timing readers can still read the estimate before the flash. The archived intercept capture helper under `docs/shots/` is outside the live bench; it predates session-owned joins and was left as recorded evidence.
- Saves: no fields or migrations changed. Old profile, settings and run fixtures loaded in `onboarding_test`, `title_settings_test`, `title_continue_test` and `run_resume_test`; `save_test` also passed.
- Twins: presentation only. The root JS rules and both Godot tables match the base; rules parity, campaign parity and the oracle copy check passed.
- UI: the battle plate and the new FX ship use the same risen health and shields. Battle panels refresh from the same batch view; campaign map and intel still read the original rules and save values.
- CI: both extended checks are already in [the Godot game list](../../../godot/tools/ci/godot_checks.txt). No new test file or standing check row was needed. GitHub runs standing checks, rules and campaign parity, the Godot-only rules safety net and Godot game checks.

## Follow-up: rise before tidal damage

[Battle playback](../../../godot/scenes/battle/battle.gd) still takes the ship's identity from the batch view. It uses the existing rise fraction and rounding for the hull and section damage effects, keeps the shields as drawn, and clears fire at the rise. The tidal event then takes its damage once. The final batch sync still reconciles the display with the rules view.

[Death plane](../../../godot/fx/test/death_plane_check.gd) now plays real `startSideTurn` events for an Eclipse ship that rises in the tidal ring and survives. The first run showed 28 hull at rise and 21 after the tick, then snapped back to 28. The fixed playback shows 35 at rise, 28 after the tick and 28 after sync.

```text
First-run base: FAIL rise and tidal damage play in order
With the fix:   PASS rise and tidal damage play in order
DEATH_PLANE failures=0
PASS late core flash, slow motion and camera hold
PASS deadline fallback cue
```

- Standing checks: 74 PASS, 2 KNOWN, 0 FAIL. The first attempt reached the shell timeout; the full retry exited 0.
- Godot game: `load all: 239 scripts, 16 scenes, 0 failed`; `PASS: every listed headless Godot check passed.` (84 checks); `bot battle: PASS` (seed 361); `PASS fixture record matches the A16 inputs and compressed GLB`. Headless import exited 0.
- PC parity: `PASS: the Godot port matches the game's rules exactly.` (284 battles); `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
- No capture: the look bench has no rise followed by a tidal tick. The headless check reads the displayed hull between those two events, before the final sync can hide the bug.

### Follow-up impact sweep

- Callers: `_play_batch` passes the view through the sole `risen` branch to `_reassemble`; `tick` still subtracts the event's hull loss and plays its FX. The existing wreck check still calls the same rise path.
- Saves: no schema or load changes. `onboarding_test`, `title_continue_test`, `run_resume_test` and `save_test` passed with isolated save data, including old profile migration and old run Continue.
- Twins: the browser rules, Godot rules and both tables match the first-run base. No table export was needed; rules parity, campaign parity and the oracle copy check all passed.
- UI: the battle nameplate reads `disp` during playback. The fleet strip, ship panel and target panel refresh after batch sync. Campaign map and intel still use their existing rules and save values.
- CI: the new case is in the existing `death_plane_check` entry. GitHub runs it in Godot game checks alongside standing checks, rules and campaign parity, and the Godot-only rules safety net.
