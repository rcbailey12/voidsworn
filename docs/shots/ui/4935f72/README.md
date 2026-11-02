# Screen layout pass (Nov 1): nothing on the screen covers anything else

Captured on Ryan's PC (RTX 5080), lane A job `ui_4935f72`, the game started the way the exe starts it (maximised, then the window set to the size being tested), at 1920x1080, 2560x1440, 3840x2160 and 1280x720. Code: wt-ui 4935f72 on main 68df9d4.

## What was wrong, in plain words

The title screen and the battle screen measured the window once, the moment they were built. The game opens maximised on your 4K screen, so they were built at 4K size, and when the window then changed size (as the stills job does, and as Full screen or un-maximising does) everything kept its 4K size. That is why, at 1920x1080, the title ran off both edges and the battle panels piled on top of each other: the banner over the ship name, the card over the weapons list, the Speed button cut off, the Move here tip over the fleet list.

## What changed

- **Both screens follow the window.** When the window changes size, the title and the battle screen are rebuilt at the right size within a fraction of a second, keeping what they showed (the battle log, the card, the panels, an open menu or Settings).
- **The title fits at any size**, centred and big. If a window is ever too narrow for one line it splits onto two lines instead of shrinking to nothing. The gold **"Playtest: everything unlocked"** line now shows under the tagline (it reads the playtest switch from your save; switched off it shows a grey line instead).
- **Credits on the title menu** (Opus's request): a scrolling screen with the game line and every music track's credit and licence from the music list (the eight CC BY tracks need this). Done or Esc closes it.
- **Keyboard and controller on the title**: every title button already took keyboard focus (the review was looking at an older file); the check now proves it at every size: all 9 menu buttons take focus, the first one is focused on open, arrow keys and Enter work.
- **The battle screen has fixed areas**, so parts can't land on each other:
  - top bar across the top: the objective text gives way (ends in "...") before any button is pushed off; **Grid (Z)** now sits in the top bar next to Threat instead of hiding behind the ship panel;
  - fleet list on the left, battle log under it; the fleet list scrolls before it reaches the log;
  - ship panel on the right; it gets shorter and scrolls if the card would ever reach under it;
  - the strip under the top bar, between the two side panels: the terrain chip on the left, then the YOUR TURN / ENEMY TURN strip (it moves right of the chip, and shrinks its text or wraps if it ever has to), then toasts and the tip card below it;
  - the activation card and the key hint at the bottom, between the log and the ship panel;
  - the hover tips (Move here, enemy details) stay in the middle area and step around the card, the log, the strip and the tip card.

## How it was checked

- **Layout check at every still** (new, `godot/ui/battle/ui_shots.gd`): every visible part (top bar, fleet list, ship panel, log, card, turn strip, terrain chip, tips, tip card, toasts, banner, key hint) must be fully on screen and touch no other part, and every top bar button, Grid (Z) included, must be fully inside the top bar. **56 checks at 4 sizes in 2 battles, 0 failed** (`ui_checks.txt`).
- **Title check**: title width, playtest line and menu on screen, menu buttons with keyboard focus: **PASS at all 4 sizes** (`title_checks.txt`).
- The logs show the fix working the way it failed before: every run printed "rebuilt for 1920 x 1080" (or the size tested) right after the window changed.
- I looked at every still myself (sheets below).
- **Rules untouched** (no file in `godot/rules/` or `godot/campaign/` changed). Cloud: rules parity PASS (48 battles, random numbers, maths, threat maps, threads), campaign parity 24 of 24, Nemesis scenarios PASS. F1's acceptance trace headless: s5 39, s14 40, s9 33 checks, 0 failed.

## Pictures

| File | What it shows |
|---|---|
| `compare_title_before_after_1920.jpg` | Title at 1920x1080: the exe you have (left) and now (right) |
| `compare_battle_before_after_1920.jpg` | The same battle moment (Move here hovered) at 1920x1080, before and after |
| `title_1920x1080.jpg`, `title_2560x1440.jpg`, `title_3840x2160.jpg`, `title_1280x720.jpg` | The title at each size |
| `title_credits.jpg` | The new Credits screen |
| `sheet_seed4242_<size>.jpg` | The battle from your stills (seed 4242, Hegemony, belt): start, move preview, enemy clicked (out of reach), tip card with the terrain list open, enemy turn |
| `sheet_s14_<size>.jpg` | A battle with an enemy in reach (s14): the same moments plus an enemy targeted after a move, with the odds in the card |
| `seed4242_1920_battle_start.jpg`, `seed4242_1920_move_preview.jpg`, `s14_1920_enemy_targeted.jpg`, `s14_1920_enemy_turn.jpg` | Full size at 1920x1080 |
| `seed4242_3840_move_preview.jpg` | Full size at 3840x2160 |

## Calls I made (technical, vetoable)

1. The UI scale stays what the game already used: window height divided by 1080 (between 0.6 and 2.2). At 16:9 every size looks the same, just sharper.
2. Grid (Z) is moved into the HUD's top bar from the battle side (board.gd still owns its state and when it shows); board.gd itself is not edited.
3. The card centres on the screen and only slides sideways if it would reach the log or the ship panel.
4. The open terrain list pushes the turn strip to its right rather than covering it.
5. The title's playtest line is read from the save file (the campaign is not loaded on the title); no switch button on the title, it stays on the campaign screens.
6. The Credits game line says "A game by Ryan Bailey", the engine (Godot, MIT) and the three font families (SIL Open Font Licence). Change the wording if you want something else.
7. The layout check forces an onboarding tip card on for one still (stills jobs normally turn tips off) so the tip card's place is checked too.

## Seen, not mine to fix (for F1)

- In `s14_1920_enemy_targeted.jpg` the hover tip on the targeted Glasswright prism says every gun is out of range, while the card and the ship panel say the Oath lance bears (76%). The tip and the card disagree about the same target; F1 owns the tip text (`_tip` in battle.gd).
- When a test job quits in the middle of the enemy's turn the headless build can crash in the move code (`_play_move`); the layout check now lets the enemy turn finish first. Players never quit that way, but other test drivers might.
