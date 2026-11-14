# Issue 644: text floor 17 on the five screens (DeepSeek workhorse report, Nov 14 2026)

Branch work/issue-644-deepseek. Game files changed: none. Main already meets the 17 px floor on all five
screens, so this run only measured it and wrote this review. New files are this review and the pictures in the
job's out/shots folder (outside the repo). The build's own before and after set is already on main in
docs/shots/text_floor_644.

## Answer first

- The existing floor check passes on main: `ui_spec_tests.js` reads `MIN_TEXT = 17` in godot/ui/ui_scale.gd and
  finds no text size literal under 17 in godot/ui or godot/main. Result: 170 checks, 170 pass, 0 fail.
- The live screens agree. `godot/ui/text_floor_shots.gd` at 1920x1080 reads 17 px as the smallest read text on
  all five screens (battle, at 17, is measured by its own headless check because the orders sheet paints its
  words as draw items, not as Label controls).
- No read text overlaps at any fleet size, including the 12-ship map rail and the 12-ship Fleet and refits
  page. The only pairs the shot script flags are explained under Overlaps below.
- Contrast was measured too. Four screens are at 4.5:1 or better. One Career dim label colour is 3.61:1 on
  its card; that is a palette value, not a size, and it is named under Contrast below rather than changed,
  because the job forbids every other change and the issue's gate is the 17 px size floor.

## Per-screen measurement at 1920x1080

The smallest read text on each screen, its size and its contrast. Colours are read from the theme; the battle
and Map key figures come from their own headless checks, which test over pure white and black (battle) and over
the map's own dark halo (Map key).

| Screen | Smallest read text | Size at 1080 | Contrast | Overlapping text | Measured by |
|---|---|---:|---|---:|---|
| Campaign map | `Map key` (rail body words are 17 too) | 17 px | 10.79:1 over the map halo | 0 | text_floor_shots.gd + map_key_halo_test.gd |
| Battle HUD | key, tip and log words | 17 px | 4.73:1 (`Hegemony Navy: Iron Warden`, TEXT2) over white and black | 0 | ledger_readability_test.gd |
| Career screen | `RUNS` stat label | 17 px | 3.61:1 on the card (see Contrast) | 0 | text_floor_shots.gd + theme colours |
| Glass shell (shared theme) | `Got it` button | 17 px | 15.74:1 on the button fill | 0 | text_floor_shots.gd + theme colours |
| Title screen | credits line | 17 px | 8.11:1 (T_BONE2) and 8.23:1 (gold) on the credits panel | 0 | text_floor_shots.gd + theme colours |

The fleet list, the case Ryan flagged in R177, is clean at 1 and at 12 ships. The screen's own type scale is
the one docs/playbooks/screens.md section 2 names for issue 644 (campaign 17 to 24, Career 17 to 40, title 17
to 84, battle 17 and up, shared theme 17).

## Overlaps

`text_floor_shots.gd` flagged six pairs in its run on this checkout. None is a visible overlap:

- Five are the map's `Preparing the sector...` loading cover against rail or fleet words. This checkout has no
  built hull files (`godot/gen`), so the 3D map stayed on its cover for the first shots; the cover sits over
  the whole page. The clean 12-ship map and 12-ship fleet shots, taken after the sector finished loading, have
  0 overlaps.
- One is `Save and quit` against `Close` while the Map key slide-over is open. The slide-over's opaque panel
  (`column`, #0b0e0b) covers the map's top-right buttons, so a player sees only `Close`. The shot script walks
  the tree and does not know about occlusion.

## Contrast (named, not changed)

Four of five screens are at 4.5:1 or better on the measured smallest words. The Career screen's dim labels
(`RUNS`, `No service yet`, `Empty refit slot`, the "0/30 experience" lines) use BONE3 #7d7768 on the card
IRON #182133, which is 3.61:1 (4.05:1 on the #0f1626 panels, 4.47:1 on the #060910 screen). This is a palette
value, present before and after the size pass. The issue asks for the 17 px floor and says change nothing
else, so I left it. If the Board wants it fixed, raising Career BONE3 to at least #8f8878 makes it 4.57:1 on
the card and is a one-line change in godot/ui/career/career_screen.gd.

## The five reach checks

- Callers: no function, constant or save field changed, so no caller changes. The only new files are this
  review and the pictures outside the repo.
- Saves: no save field or serialised shape touched. An old profile or run loads and behaves as before. The
  standing save_fuzz and campaign save checks still pass.
- Twins: no JS root file (battle.js, data.js, core.js) changed, so no table re-export was needed. The standing
  `oracle_copy_test.js` passes and both committed tables still equal a fresh export.
- UI: no screen reads a changed value. All five take their sizes from the shared godot/ui/ui_scale.gd law;
  `ui_spec_tests.js` checks the five users read `k_for()`.
- CI: no new test file, so `contrib/opus/tools/run_all_checks.js` needed no change. GitHub runs the standing
  checks and the Godot game checks; rules and campaign parity run in the parity job.

## Checks run and their result

- `node contrib/opus/tools/ui_spec_tests.js`
  - `ui_spec_tests: 170 checks, 170 pass, 0 fail`
- `text_floor_shots.gd` at 1920x1080, all screens:
  - `TEXT_FLOOR campaign_map smallest=17 at Map key overlaps=0`
  - `TEXT_FLOOR campaign_map_big_fleet smallest=17 at Map key overlaps=0`
  - `TEXT_FLOOR campaign_fleet_big smallest=17 at Costs 40 credits overlaps=0`
  - `TEXT_FLOOR career_records smallest=17 at RUNS overlaps=0`
  - `TEXT_FLOOR glass_theme smallest=17 at Got it overlaps=0`
  - `TEXT_FLOOR title_menu smallest=19 at New run overlaps=0`
  - `TEXT_FLOOR title_credits smallest=17 at Embers of the Hollow Sun A game by Ryan overlaps=0`
- `ledger_readability_test.gd` (headless, 1080 and 1440):
  - `1920x1080 20 ships: 64 words, smallest 17, Big Shoulders from 28, lowest contrast 5.25 (Log (TEXT3))`
  - `1920x1080 enemy turn: 24 words, smallest 18, Big Shoulders from 28, lowest contrast 4.73 (Hegemony Navy: Iron Warden (TEXT2))`
  - `ledger readability: 0 checks failed`
- `map_key_halo_test.gd` (headless, 1080 and 1440):
  - `PASS: 1920x1080: 'Map key' font_color over the halo is 10.79 to 1 (4.5 or more)`
  - `Map key halo: PASS`
- `node contrib/opus/tools/run_all_checks.js`
  - 48 rows PASS, 2 rows KNOWN, 0 FAIL. The two KNOWN rows are the accepted findings list
    (`KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5`) and the accepted 12-constant oracle drift baseline.
- `tools\pc\parity.bat nopause`
  - `PASS: the Godot port matches the game's rules exactly.`
  - `PASS: the Godot campaign matches the game on all 30 seeded runs, and the cross-twin save hand-off check passes.`
  - exit 0.

## Pictures (out/shots)

Current main, rendered on this PC at 1920x1080 and reduced to 720 px tall with the screen name on the strip:

- `campaign_map_current.jpg`: Old Battleground, 12-ship fleet
- `battle_hud_current.jpg`: orders sheet, 20 ships
- `career_screen_current.jpg`: Records tab
- `glass_shell_current.jpg`: shared theme sizes
- `title_current.jpg`: title menu

The build's own before and after pair, already on main in docs/shots/text_floor_644, copied here for review:

- `campaign_fleet_before.jpg`, `campaign_fleet_after.jpg` (main's pair is captioned Fleet and refits)
- `battle_hud_before.jpg`, `battle_hud_after.jpg`
- `career_screen_before.jpg`, `career_screen_after.jpg`
- `glass_shell_before.jpg`, `glass_shell_after.jpg`
- `title_before.jpg`, `title_after.jpg`
