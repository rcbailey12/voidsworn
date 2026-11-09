# Issue 271 build: the captures the board runs on Ryan's PC

Branch opus/issue-271-build (Glass Shell bold, FINDINGS R145). The cloud sandbox drew the HUD with software Vulkan and
grey placeholder hulls (the ship assets are not in git, R144), so the real look has to be judged from Ryan's PC: the
real hulls, the RTX 5080, his screen. The sandbox stills in sandbox/ are only there to show the layout.

## How to run

One job does all of it: `tools/pc/jobs/ui271_build_shots.bat`. Start it the usual way (a one-line queue job in
Downloads\voidsworn_test\queue that `start`s it, LOOP.md Known traps). It clones the branch into
Downloads\voidsworn_test\opus271b\repo, seeds the import cache and the ship assets from opus207's clone, imports,
parse-checks the six changed scripts, then runs five captures. Output: Downloads\voidsworn_test\opus271b\out\
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
- parse.txt: exit 0 for all six scripts.
- Ryan's eye on A and B at 1080 against docs/shots/ui_redesign/mockups_r2/C_glass_shell_bold.png and
  C_glass_shell_bold_20_ships.png; the board posts A's 5a and B's 1_battle_start to him (two lines, one image each).
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
