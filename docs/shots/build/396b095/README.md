# Playtest build at 396b095 (Nov 1, 2026, 19:15 CDT)

A fresh Windows build of *Embers of the Hollow Sun* from main at 396b095, made on Ryan's PC by the fail-closed export job (lane A job `g2_pt_396b095`). Main has moved on since (42c1c48), but only docs and briefs: the game code and `tools\pc` are the same as in this build.

**To play:** double-click `play_godot.bat` in `Downloads\voidsworn_test` (or `play_godot_safe.bat` if it won't start). It runs `build\export\Voidsworn.exe`.

## How it was checked

- Ship check before anything moved: `MANIFEST OK: 252 files match main's ship manifest (size and sha256)` (`manifest_check.txt`). No ship file changed since e991dc6, so no a4_regen run.
- Export job: `OK: C:\Users\rcbai\Downloads\voidsworn_test\build\export\Voidsworn.exe` (`export_log_lines.txt`).
- Package check (`--check-export`): `[export-check] OK []`.
- Bot smoke on the exported exe: `2 runs, 0 wins, 0 errors, 0 softlocks` (`smoke.json`). It looks for crashes and stuck games, not wins.
- The exe then took its own stills: the title at 3840x2160 and 1920x1080, Credits at 1920x1080, and one battle (seed 4242, Hegemony, belt map) at both sizes with the UI layout check (`--ui-shots`). The layout check passed at both: 6 checks, 0 failed (`ui_check_3840x2160.txt`, `ui_check_1920x1080.txt`; UI scale 2.0 at 4K, 1.0 at 1080p).

## What is new since the e991dc6 build

- **Screen layout fix (UI pass, 1eec6f8, 9e34ce5, 4935f72):** the HUD sits in fixed regions and rebuilds when the window size changes, so nothing overlaps at 4K or 1080p. The title fits on screen at every size and shows the playtest line. **Grid (Z)** is now a button in the top bar.
- **Credits screen** on the title menu (game, engine, fonts and every music track with its licence).

## Stills (from the exported exe)

| Still | What |
|---|---|
| `title_3840x2160.jpg`, `title_1920x1080.jpg` | Title screen. The full title fits now (at e991dc6 it ran off both edges at 1080p). |
| `credits_1920x1080.jpg` | The new Credits screen |
| `battle_start_3840x2160.jpg`, `battle_start_1920x1080.jpg` | Battle opening, first ship up |
| `move_preview_3840x2160.jpg`, `move_preview_1920x1080.jpg` | Hovering a move hex (the "Move here" tip) |
| `enemy_turn_3840x2160.jpg`, `enemy_turn_1920x1080.jpg` | The enemy's turn |

## Looked at by eye

The three problems seen at e991dc6 are gone: the title fits, the YOUR TURN banner sits clear of the ship panel, and the activation card no longer covers the weapons list. The Speed and End ship buttons are fully on screen. No HUD part overlaps another at either size.

Small things, not blockers (for the streams):
- In-world ship labels over the board can crowd each other: "Iron Dusk" and "Oathkeeper" sit almost on top of each other in the enemy turn still, and "Iron Dusk" overlaps a hex next to the ship that is up at the battle start.
- At 4K in the enemy turn, the "Cordon destroyer" label touches the left edge of the ship panel.
- "Out of range." stays on screen under the enemy turn banner (a leftover from the check clicking an enemy out of reach).
- The exe logs two harmless warnings at start (`invalid UID` for main.tscn and battle.tscn, falls back to the file path).

## Notes on the build (vetoable calls)

- Same steps as the e991dc6 build: the code folders in `build\godot` moved aside to `Downloads\voidsworn_test\sync_old\g2_pt_396b095\` (nothing deleted; they held the UI pass test code from the `ui_4935f72` capture job) and main's code and `tools\pc` were unpacked in their place. Generated ships, rocks and sky were kept.
- One change from last time: the export job keeps one older build in `build\export\previous` and overwrites what was there. So that nothing is deleted, the old `previous` (the c2f1437 build) was first moved to `sync_old\g2_pt_396b095\export_previous\`. `previous` now holds the e991dc6 build.
- The package is 5.2 GB, same as e991dc6. 268 GB free on C: after the build.
