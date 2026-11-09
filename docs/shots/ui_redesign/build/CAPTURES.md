# Issue 271 build: the captures the board runs on Ryan's PC

Branch opus/issue-271-build (Glass Shell bold layout, FINDINGS R145; Lime Tactical identity, FINDINGS R149). The cloud sandbox drew the HUD with software Vulkan and
grey placeholder hulls (the ship assets are not in git, R144), so the real look has to be judged from Ryan's PC: the
real hulls, the RTX 5080, his screen. The sandbox stills in sandbox/ are only there to show the layout.

## Lime Tactical (Nov 9 2026, R149): what the board reruns now

Ryan picked identity 2 (Nov 9 12:00 CST: "yeah i like lime tactical, run it"). It is now the Godot theme
(godot/ui/theme/glass_shell.gd, fonts in godot/ui/theme/fonts/, hud.gd; rules in contrib/opus/briefs/ui_style.md).
The R148 fixes stay: one filled accent button at a time, hatching only while planning a move.

Rerun on the PC, same job, into a new folder: the queue job `start`s
`tools\pc\jobs\ui271_build_shots.bat out_lime` (output Downloads\voidsworn_test\opus271b\out_lime\).

Two changes to the job (the board's PC copy already had the first; the repo copy now matches):

1. It copies **godot/gen** from opus207's clone as well as the ship assets, so the captures show the real hulls (the
   generated hull and kit files are not in git): `if exist "%VT%\opus207\repo\godot\gen" robocopy
   "%VT%\opus207\repo\godot\gen" "%R%\godot\gen" /E /XC /XN /XO /NFL /NDL /NJH /NJS /R:1 /W:1`.
2. It clones with `git -c core.autocrlf=false clone`, so the .bat and .gd files keep their line endings as committed.

The parse step now checks seven scripts (render/ship_view.gd added: the mint ring under your ships). The existing
clone at opus271b\repo is reused (fetch plus reset), so the clone flag only matters on a fresh folder; the new fonts
are imported by the job's own import step.

| Capture | Still | Look for (against docs/shots/ui_redesign/identity/2_lime_tactical.png) |
|---|---|---|
| A_1080 | 5a_planned_move_odds | **Ryan's still.** Black-olive panels with the fine scanline, 14 px cut corners top left and bottom right, the lime bevel and lime brackets; Chakra Petch words, Azeret Mono numbers (odds, damage, hull, keys); section heads in lime caps; Move here lit (lime edge, not filled); END SHIP the one filled lime slab with its SPACE cap |
| A_1080 | 1_battle_start | the up ship's name (star, "LONG WATCH" style) in lime caps, the UP tag filled lime; your names and the fleet list's Ready in **mint**, not green; the ring under your ships mint |
| A_1080 | 5_enemy_targeted | Fire N weapons lit; the armed weapon row lime-edged; NEMESIS tag and the Nemesis block's bar in the reserved red |
| A_1080 | 6_enemy_turn | the lavender turn strip; End block hidden |
| B_1080_20 | 1_battle_start | **Ryan's still.** 20 rows, no scroll (names at 14: Chakra Petch is wider than Barlow) |
| C_4k | 1_battle_start, 5a | chamfers, scanline and brackets scale cleanly at k 2.0; letter spacing grows with k |
| D_4k_20 | 1_battle_start | as B at 4K |
| E_1080_plain | 1_battle_start, 2_move_preview | hatching only where enemies can reach; the hovered hex ring lime |

Pass bar as below (every ui_check.txt "0 failed", parse.txt exit 0 for all seven).

Sandbox check (software renderer, grey placeholder hulls; layout and colours only), stills in sandbox/LIME_*.jpg:

- A at 1920x1080: 21 checks, 0 failed (LIME_A1080_ui_check.txt; battle start, the planned move with odds, the target).
- B at 1920x1080 with 20 ships: 21 checks, 0 failed, the fleet list with no scroll (LIME_B1080_20_ui_check.txt; battle
  start, the tip card with Got it lit, the enemy turn, the menu with keyboard focus on Resume).
- A at 2560x1440 (UI scale 1.33): 21 checks, 0 failed (LIME_A1440_ui_check.txt; the planned move with odds, scaled to
  1920 wide). 4K does not fit the sandbox's memory with the software renderer, so
  C and D on the PC cover it.
- Three small fixes landed after A's sandbox run started and are in B's: Resume keeps dark text on lime while it has
  the keyboard, the tip card's Got it is lit not filled, and only the ship that is up gets a filled lime tag (your
  other ships get a mint outline).
- Every changed script parse-checks (Godot 4.7.2 --check-only): the seven in the job plus main/title.gd and
  main/campaign_fallback_ui.gd.

## R148 fix pass (Nov 9 2026): rerun done earlier (out_r148)

Ryan agreed to two fixes (FINDINGS R148). Both are in this branch now:

1. **End ship** is the big filled gold button of C_glass_shell_bold.png in every state: gold with a top-lit sheen and a
   soft glow, "End ship" centred with the Space key cap after it (dark on gold), 46 tall. A step's own confirm (Move here,
   Fire N weapons, Burn and fire) is now a lit button (gilt edge and gilt text on a dark well), so the screen never shows
   two gold buttons. Code: glass_shell.gd `finish_boxes`, `lit_boxes`, `gilt_sheen`, `keycap_on_gilt`; hud.gd `_end_button`.
2. **Board hatching** is calmer: it shows only in the Move step (a ship up that can still move, nothing targeted, not
   braced), as in the mockup; the lines are about three times as far apart (about three across a hex for one enemy, four for
   two or more) and much lighter (the shader blends in linear light, so the old values read far stronger than their numbers).
   The danger badges on the fleet list and the shell keep their counts in every step. Code: board.gd FILL_SHADER,
   battle.gd `_danger_bands` and `_move_step`.

Rerun on the PC, same job, into a new folder so the first stills stay: the queue job `start`s
`tools\pc\jobs\ui271_build_shots.bat out_r148` (output Downloads\voidsworn_test\opus271b\out_r148\).

| Capture | Still | Look for |
|---|---|---|
| A_1080 | 1_battle_start | End ship gold and filled, Space cap after the label; light hatching on the hexes in reach |
| A_1080 | 5a_planned_move_odds | **Ryan's still.** Move here lit (gilt edge, not filled), End ship still the one gold button; hatching quiet, lines wide apart |
| A_1080 | 5_enemy_targeted | no hatching (an enemy is targeted); Fire N weapons lit; End ship gold |
| A_1080 | 6_enemy_turn | no hatching, End block hidden |
| B_1080_20 | 1_battle_start | **Ryan's still.** 20 rows, no scroll; End ship gold at the bottom right |
| C_4k | 1_battle_start, 5a | the gold button and its sheen scale cleanly at k 2.0 (no gaps at the edges) |
| D_4k_20 | 1_battle_start | as B at 4K |
| E_1080_plain | 1_battle_start, 2_move_preview | fleets apart: hatching only where enemies can reach, none on your own side |

Pass bar as below (every ui_check.txt "0 failed", parse.txt exit 0). Sandbox check of A at 1920x1080 (software renderer,
grey hulls): 21 checks, 0 failed; stills in sandbox/R148_A1080_*.jpg.

The three identity variants (docs/shots/ui_redesign/identity/) were mockups; Ryan's pick (2, Lime Tactical) is now
built, captured by the out_lime rerun above.

## How to run

One job does all of it: `tools/pc/jobs/ui271_build_shots.bat`. Start it the usual way (a one-line queue job in
Downloads\voidsworn_test\queue that `start`s it, LOOP.md Known traps). It clones the branch into
Downloads\voidsworn_test\opus271b\repo, seeds the import cache, the ship assets and godot/gen from opus207's clone,
imports, parse-checks the seven changed scripts, then runs five captures. Output: Downloads\voidsworn_test\opus271b\out\
(status.txt shows progress; each capture folder holds the PNGs and ui_check.txt).

Every capture uses the existing route: `res://scenes/battle/battle.tscn -- --ui-shots <folder>` (godot/ui/battle/ui_shots.gd),
which plays the opening through the player's own handlers and saves a still at each moment, checking at every one that
no HUD part runs off the screen or touches another. New arguments for this job (battle.gd, test only):

- `--ui-demo`: a Nemesis on the enemy side (the Hegemony one from test scenario s38, one weakness found) and Heat 3
  (Hunted plus Vengeful flagships), so the Nemesis block and the Heat gauge show real rules state.
- `--obj ambush`: the ambush encounter, where the fleets start inside gun reach, so the Fire odds and a target show in
  round 1 (in the default rout the fleets start about 18 hexes apart).
- `--fleet-size 20`: the default trio repeated to 20 ships.

## The captures

| Folder | Size | Command line after `battle.tscn --` | What it proves |
|---|---|---|---|
| A_1080 | 1920x1080 | `--ui-shots A_1080 --seed 7 --ui-demo --obj ambush` | the full look at Ryan's base size |
| B_1080_20 | 1920x1080 | `... --ui-demo --obj ambush --fleet-size 20` | 20 ships fit the fleet list with no scroll (checked in ui_check.txt) |
| C_4k | 3840x2160 | as A | the HUD scales by height (k 2.0): same layout, crisp text |
| D_4k_20 | 3840x2160 | as B | 20 ships at 4K |
| E_1080_plain | 1920x1080 | `--ui-shots E_1080_plain --seed 7` | the default battle: no Nemesis, no Heat, fleets apart; empty blocks hide cleanly |

Each folder has these stills (numbering follows the run; moments that cannot happen in that battle are skipped and
say so in ui_check.txt):

| Still | State | Look for |
|---|---|---|
| 1_battle_start | your turn, the first ship handed over | top bar (round, YOUR TURN, pips, objective, enemy crest and name, Heat 3), the unacted set, the seven blocks in order, End ship bottom right |
| 2_move_preview | a move hex under the pointer | the move tip with "N enemies can reach this hex, now M"; reach hatching on the board |
| 3_enemy_clicked | an enemy targeted from where you stand | Fire rows with hit and expected damage, the Target block with the hatched "expected" loss, the odds tag on its nameplate |
| 4_tip_card_and_legend | an onboarding tip and the terrain legend open | both in the middle column, clear of the shell and the fleet list |
| 5a_planned_move_odds | **the Move step with a planned move**, the pointer on an enemy | 1 Move lit with Move here and Cancel; 2 Fire reads "from the planned hex" with real odds; Target block from the planned hex |
| 5_enemy_targeted | **Fire with odds**: the move made, an enemy targeted | 2 Fire lit with Fire N weapons; Target block "to about N" |
| 6_enemy_turn | the enemy's turn | the lavender turn strip with progress, the top bar reads ENEMY TURN, the End block and the unacted set hide |
| 7_menu_focus | the Esc menu | the menu well with corner ticks and the bone focus ring on Resume |

The three states the issue names: the Move step with a planned move is 5a, Fire with odds is 5 (and 3), the 20-ship
fleet is folder B (and D).

## Pass bar

- ui_check.txt in every folder ends "0 failed" (layout, overlap, the End block at the bottom of the shell, no scroll
  in the fleet list at 1080 or more, the menu focus ring, hover facts equal to the rules' own queries, tips that leave
  the battle state and RNG unchanged).
- parse.txt: exit 0 for all seven scripts.
- Ryan's eye on A and B at 1080 against docs/shots/ui_redesign/identity/2_lime_tactical.png and
  2_lime_tactical_20_ships.jpg (the layout spec stays mockups_r2/C_glass_shell_bold.png); the board posts A's 5a and B's 1_battle_start to him (two lines, one image each).
- The R116 gate is not re-measured by this job; if the board wants it, the bench207 scene gate (bench/scene_gate.tscn,
  hud_off mode against base) runs on this branch unchanged.

## Sandbox stills (layout only)

sandbox/ holds JPGs from the cloud runs (software renderer, grey placeholder boxes for hulls, no PC assets), scaled to
1920 wide, with their ui_check.txt (0 failed in both):

- A1440_*: capture A's command line at 2560x1440 (UI scale 1.33) with --ui-rebuild-test (the HUD rebuilt from a wrong
  size comes back right): battle start, the planned move with odds (5a), the target (5), the enemy turn.
- B1080_20_5a_planned_move_odds.jpg: capture B (20 ships at 1080, the fleet list with no scroll). This run predates a
  rename of the demo Nemesis (it reads "Grand Admiral Ilsa Valk", a retired rank and name; the branch now builds
  "Fleet Marshal Petra Valk").

They show where everything sits; colours and text are the real ones, the ships and the board lighting are not. A 4K
run did not fit the sandbox's memory with the software renderer; C and D on the PC cover it.
