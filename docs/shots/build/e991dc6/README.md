# Playtest build at e991dc6 (Nov 1, 2026, 18:06 CDT)

A fresh Windows build of *Embers of the Hollow Sun* from main at e991dc6, made on Ryan's PC by the fail-closed export job.

**To play:** double-click `play_godot.bat` in `Downloads\voidsworn_test` (or `play_godot_safe.bat` if it won't start). It runs `build\export\Voidsworn.exe`.

## How it was checked

- Export job: `OK: ...\build\export\Voidsworn.exe` (see `export_log_lines.txt`).
- Package check (`--check-export`): `[export-check] OK []`, so no test folders are in the package and the real campaign UI, effects, story and music player are.
- Bot smoke on the exported exe: `2 runs, 0 errors, 0 softlocks` (`smoke.json`). This check looks for crashes and stuck games, not wins (the bots won neither run).
- The exe then took the stills below by itself (title screen, then one battle at the battle camera, same seed, in the default look and in Today).

## What is in this build (new since the Nov 1 00:41 build at d78cce0)

- **Board look C is the default** (Ryan's pick, R72): no grey plate, a faint holo grid that fades away from the ship that is up, terrain shown as real things in space (gas clouds, rocks). **F8** in battle cycles the four looks (Today, A holo war-table, B living terrain, C). In look C, **Z** or the **Grid** button brings up the full tactical grid.
- **Turn flow (F1):** battles open on a wide view of both fleets; an activation card shows the ship that is up and its steps (move, fire, end ship) with big Next ship (Tab) and End ship (Space) buttons; ship names no longer print under the side panels; the battle keeps a play log.
- **Movement (F2):** slower, heavier moves in one smooth motion; big ships build and bleed speed more slowly.
- **Effects (F3):** both rounds so far, including round 2 (bigger hit, muzzle and shield flashes; hit flashes and hot cores hold longer and the afterglow is brighter); softer, warmer kill moments; fewer first-use stutters.
- **Backdrops and rocks (F4):** planets and moons with rings, atmosphere glow and their own lighting; rocks read as rock with craters; the dead-star lens no longer slices nearby rocks.
- **Ships (A4):** concept paint on all 36 ships, surface detail rebuilt on 28, Hegemony lighter with its blue bands, H4 hand livery.
- **Rules (R1):** step 14 (Daybreak speed 2, the sector flagship objective table) and the playtest switch: every admiral, hull and variant unlocked.
- **Portraits (P):** Nemesis scars repainted for every faction, Crusade implant scars removed, admirals in their own settings.

## Still in progress (not final in this build)

- **The second effects pass** is in, but still being tuned: the round 2 review found hits still reading small from the battle camera, and a0dfd5b's longer flashes are the latest step.
- **Board look C's finishing pass** has not landed yet; C is the default as it stands from the trial.

## Stills (from the exported exe, 1920x1080)

| Still | What |
|---|---|
| `title.jpg` | Title screen |
| `c_01_start.jpg` | Battle opening, default look (C), first ship up |
| `c_02_move_preview.jpg` | Same, hovering a move hex |
| `today_01_start.jpg`, `today_02_move_preview.jpg` | The same moments in the old Today look (F8), for comparison |
| `compare_today_left_c_right.jpg` | The board area side by side: Today on the left, C on the right |

## Things seen in the stills (for the streams, not fixed here)

- Title screen: at 1920x1080 the big title runs off both edges of the screen ("bers of the Hollow S").
- Battle: the "YOUR TURN" banner sits over the ship name at the top of the right info panel, and the activation card at the bottom covers the weapons list, whose text shows through it. The Speed button at the top right is cut off.

## Notes on the build (vetoable calls)

- The PC build folder was brought to main by moving the old code folders aside to `Downloads\voidsworn_test\sync_old\g2_pt_<sha>\` (nothing deleted) and unpacking main's code in their place. The generated ships, rocks and sky were kept: every ship file on the PC matches main's ship manifest byte for byte, and the converted ships were rebuilt after the last ship changes, so no a4_regen run was needed.
- The package is 5.2 GB (the Nov 1 00:41 build was 4.0 GB): the 28 ships rebuilt by A4 tonight carry their own normal maps.
- The export job keeps one older build in `build\export\previous`. That is now the c2f1437 build from earlier tonight (same game minus R72's default look and F3's latest tweak); the 00:41 build is no longer kept.
