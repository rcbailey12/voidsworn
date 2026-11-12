# Battle screen, E1 LEDGER in the ember look: the build (issue 271, step 2)

Opus 5.5 worker, Nov 11 2026. Brief: issue 271 "STEP 2, THE BUILD"; Ryan's picks R210 (E1 LEDGER exactly as captured, Glacier
#92b8e8 for shield readouts, shields in space keep faction colours); R177 (say less), R174 (the AI-made list), R176 (the
orders sheet), R191 (lime retired). Step 1: contrib/opus/reviews/battle_screen_ember_options.md.

## What the battle screen is now

The real HUD is E1 LEDGER, not an overlay. godot/ui/battle/ledger.gd lays out and draws one left sheet in decision order
(whose turn; the ship; hull, movement and the four shields as a small plan in Glacier; the status line; the guns with arc,
range and odds or the reason; the target and the odds, large, with one sentence of expected damage; the action box; the
orders that can be given now; the Command and End ship; the fleet at the foot), Menu, the enemy, Heat and the Nemesis top
right, the last three log lines bottom right. hud.gd keeps the battle's whole HUD interface and hands every setter to the
sheet; the menu, the end card, the tip card, hover tips, banners, toasts and floats are restyled in the same look (near-black
square boxes with a hairline edge, Big Shoulders titles, the ember outline for a dialog's one action).

- No panels: a smooth veil from the left (94%, full under the words, fading by 45% of the width) and two soft dark corners.
- One box: the 56 px ember action ("FIRE THE OATH LANCE Enter"), filled ember under the pointer.
- Names on the board: the ship that is up (ember) and the target (red if it is the Nemesis); a hovered ship and the enemy
  acting now while they are; every other name on hover. No bars, strips or tags on the board.
- The camera centres the board in the part the sheet leaves clear (camera_rig.gd screen_shift, from hud.gd clear_shift; 0
  during cut-ins), so the ship it focuses is never under the sheet.
- The previous Lime shell is still built and filled inside a hidden `legacy` node, because the PC tools (ui_shots.gd,
  f1_trace.gd, bench/scene_gate.gd) and story_beat3_test read it. It is never shown. Remove it when those tools read the
  sheet (a DeepSeek-sized follow-up).

## Every function, and how it is reached

| Function | How |
|---|---|
| select a ship | click it on the board; click its fleet line; Tab |
| target and odds | click an enemy (hover previews the odds in the sheet) |
| fire | Enter; click the action box |
| arm one gun | click the gun's line; keys 1 to 6 |
| move | click a blue hex, then Enter or the action box ("MOVE HERE") |
| orders | Brace B, the ship's ability, Ram X and Board G when they can be used, wing stances, the issue 529 role, Turn Q E: words on the sheet with their keys, each clickable |
| Command | "Command <name> C" on the sheet when ready (two clicks or C) |
| End ship | Space; "End ship Space" on the sheet (the action box when nothing is planned) |
| Next ship | Tab; "Next ship Tab" in the orders line when it can be used |
| Cancel | Esc |
| fleet list | the foot of the sheet; hover a line for class, status, hull, who the enemy reaches first, new arrivals |
| log | the last three lines bottom right; L or "Log L" opens the full log (Close L) |
| issue 529 prompts | take the shot's place in the sheet with the choices numbered; 1 to 3 or a click (PR 533's keys) |
| hover details | ship name, guns, target name, shield plan, status line, Heat, the turn count, fleet lines, the Nemesis line, the action |
| menu | Esc or "Menu Esc": the options as before, plus Top-down view (T), Tactical grid (Z) when the look has it, Keys |
| retreat | "Retreat" top right when it can be used |
| terrain key | top right under the Nemesis line; click opens it |
| view keys | T, R, V, F, Z, Home, L, Tab, Space, Enter, Esc, 1 to 6, Q, E, B, X, G, C: unchanged (battle.gd _on_key) |

### What moved behind a hover or a key

| Was on the screen (Lime) | Now |
|---|---|
| captain, armour, evasion, turns, sections, perks, the key list | hover the ship's name |
| a gun's damage, cost, reload, arc words, its number key | hover the gun |
| the target's hull bar with ghost and four shield bars | hover the target's name (hull now and after, four shields in Glacier) |
| the Nemesis block (aboard, flees when, adaptations, weakness) | hover the Nemesis line |
| Heat gauge, enemy crest | "Heat 3" (hover for the rules behind it); the faction by name |
| your admiral's crest | not shown (the admiral's name is in the Command line) |
| acted pips, "4/10 acted, then enemy", the unacted set and "in reach first" | "3 of 3 ships to act" in the top line; hover it |
| fleet bars, status words, LOW, NEW, danger badges | hover a fleet line |
| orders greyed when unavailable | hidden until they can be given; their keys work as before |
| step blocks 1 Move, 2 Fire, 3 End and their hints | one short sentence; the full hint on the action's hover |
| the Cancel button | Esc (and the action's hover says so) |
| speed (1x), threat (R), top-down (T), grid (Z) buttons | the Esc menu; the keys still work |
| the key line along the bottom | the Esc menu (Keys) and the ship name's hover |
| nameplates with bars on every ship | hover a ship |
| the four-line log ticker and colour codes | three plain lines; L for the full log |
| the enemy turn strip | the top line ("Enemy turn, Hegemony Navy: Iron Warden") with a thin progress line |

## Colours

- Lime is gone from the screen and the board: the ring under the ship that is up (ship_view.gd EMBER), the hovered hex
  (board.gd HOVER_RING), banners, floats, every bbcode lime in battle.gd. hud.gd translates any old colour the battle still
  writes (lime and the old amber to ember, the old shield cyan to Glacier, the rest to the three text strengths).
- Glacier is the shield plan only (and shield figures in hover tips and the "shield" floats). The 3D shield bubbles keep
  faction colours (fx untouched).
- **The threat map and the reach hatching are now bone (TEXT, #f0eade)** at a low wash. Red is the Nemesis alarm's alone and
  lavender or purple is on Ryan's AI-made list (R174); blue is the reach, ember the next action, Glacier the shields, so bone
  was the one colour left inside the sheet's palette that cannot be read as any of those. (Board note from PR 301.)
- Left as they were (board colours, not this job): the mint ring under your other ships, the violet enemy markers and the
  acting enemy's lavender ring. Step 1 named them for the board's own pass.

## Readability check (automatic, headless, on GitHub)

godot/ui/battle/test/ledger_readability_test.gd (listed in godot_checks.txt) builds the real HUD, feeds it through hud.gd's
setters and measures what ledger.gd lays out, which is exactly what it draws. Contrast is taken against the sheet's own
darkening at its weakest point under each word, over pure white (the brightest board possible) and pure black, so a pass
holds over any backdrop. 129 checks pass.

| Moment (1920x1080; the same at 2560x1440) | Words | Smallest | Big Shoulders from | Lowest contrast | Overlaps | Fleet lines |
|---|---|---|---|---|---|---|
| your turn, a target | 63 | 17 | 28 | 5.25 ("Log", TEXT3) | 0 | 3 of 3 |
| the enemy's turn | 24 | 18 | 28 | 5.25 | 0 | 3 of 3 |
| a "you may" prompt | 50 | 17 | 28 | 5.25 | 0 | 3 of 3 |
| 20 ships | 66 | 17 | 28 | 5.25 | 0 | 4 shown, "and 16 more" |
| six guns, every order, the longest names | 72 | 17 | 28 | 5.25 | 0 | 1 of 3, folded |
| all of it at once | 72 | 17 | 28 | 5.25 | 0 | 1, folded |
| no ship up (pick a ship) | 30 | 18 | 28 | 5.25 | 0 | 3 of 3 |

Three strengths in use (TEXT, TEXT2, TEXT3, TEXT3 only on joining words); every word in the sheet's palette; Glacier only on
the shield plan; nothing lime in any visible control. It also proves each function has its hit area (confirm, every gun,
every order, Turn Q and E, Next ship, Command, End ship, every fleet line, Menu, Log, the prompt's two choices), that a click
on the action sends the battle's confirm, that clicks on the sheet stay off the board and clicks in the clear part reach it.

How the fleet fits: lines at 36 px (34 when tight). With the target moment's three-gun ship, 5 lines fit at 1080; past
that the ship that is up and the ships still to act keep their lines and the rest fold into "and N more" (hover lists every
ship with its hull; Tab and the board still reach them). A very full sheet (six guns and every order) first folds the guns
that cannot fire into one line, then the fleet becomes one summary line ("Fleet 20 ships, 9 to act").

## Glass Shell follow-ups from PR 314

- 14, keyword definitions: built where the sheet uses state words. Hovering the status line defines Braced, On fire,
  Torpedoes inbound, focus fire and "ships move, then fire"; Heat, the shield facings, the Nemesis adaptations and the
  enemy-reach count are defined on their own hovers.
- 11, arc preview at the hovered destination: left out of this job. The firing arcs already draw at the planned hex once a
  move is clicked (battle.gd _fans on the ghost); drawing them on hover is board work (fans rebuilt per hovered hex), not the
  HUD's, and belongs with the board's pass.

## The issue 529 prompts (PR 533, merged into main while this was built)

Main was merged into this branch after PR 533 landed. hud.gd keeps show_ask, hide_ask and ask_panel with PR 533's
signatures, but the prompt now draws in the shot's place in the sheet instead of a centred Lime modal (the conflict was
resolved in favour of the sheet). battle.gd's PR 533 code (keys 1 to 3, the click guard, `_on_action("ask")`, the role
order) works unchanged against it; tree_prompt_test, wing_cancel_test and the readability check's prompt moment pass.

## Pictures (docs/shots/ui_battle_ember/build/): NOT YET MADE

Blocked on Ryan's PC: its disk was full when the capture job started (Nov 11 19:39 CST; robocopy error 112, "There is not
enough space on the disk", from the first file, before this job had written anything but a shallow clone of main into
opus271b2\main). Nothing was deleted. Once there is room, queue opus271b2\b271_job1.bat again (or a copy under a new name)
and run make_build_pictures.py on opus271b2\out. Main now has PR 533, so the before of the prompt moment is captured too.

### When made


before_* and after_* for three moments: 1_target (your turn with a target), 2_prompt (a "you may" prompt; the before is PR
533's own picture, main having no prompt), 3_enemy (the enemy's turn). 1280 wide, the code name on a strip under the picture,
none taller than 720 px; the 1080 frames in full_1080/. Made by contrib/opus/ui_battle_ember/build/ (build_shots.gd on the PC
through build271_shots.bat, then make_build_pictures.py), seed 7, the Nemesis demo battle, the same steps in both builds.

## Tests run

- ui_spec_tests: 151 checks, 151 pass (section 9 is this screen's structure guards).
- run_all_checks.js: every row PASS or KNOWN (the listed findings and oracle baselines, unchanged).
- Godot: load_all 162 scripts, 11 scenes, 0 failed (after merging main with PR 533); the headless list: every check PASS locally except death_leap_check,
  which failed only because the sandbox's import did not finish the fx atlases ("baked atlas is imported"); GitHub imports
  them. The bot battle (seed 359): PASS, no script errors.

## For the Board and Ryan

- Ryan's defaults block (ui_spec.md 7.5) is unchanged by this job; the E1 values that sit beside it are in the report.
- The fleet at the foot shows 5 lines at most at the target moment; a 20-ship fleet folds the rest. If Ryan wants every
  ship always listed, the next option is a second column or a fleet page on F.
- Muse's outside check (issue 256) before merge, per the brief.
