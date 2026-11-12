# Battle screen in the ember orders-sheet look: three layouts (issue 271, step 1)

Opus 5.5 worker, Nov 11 2026. Brief: the body of issue 271 (rewritten by the Board Nov 11), FINDINGS R174, R176, R177,
R191, R201, R202; the look as built on the map: contrib/opus/briefs/campaign_rail_orders_sheet.md (issue 441, PR 464).
No game screen changes in this job: everything here is a capture-only overlay.

## What Ryan sees (docs/shots/ui_battle_ember/)

| Picture | What it is |
|---|---|
| before_lime.jpg | today's battle screen at the same moment (Lime, retired by R191) |
| E1_ledger.jpg, E2_crossing.jpg, E3_footing.jpg | one option each, 1280x720, code name in the corner |
| E*_panel_true.png | the selected ship's block at true pixel size (1080 screen) |
| E*_shields.png | that block three times: Cyan, Glacier, Verdigris shields, true size |
| E*_prompt.jpg | the same moment with the issue 529 "you may" prompt open (Debt Comes Due, its words from PR 533) |
| full_1080/ | the 1920x1080 frames the checks were measured on |
| readability.json | every word on each screen: size, face, colour, contrast on the brightest and darkest board |

The moment is the same in all three: seed 7, the Nemesis demo battle (--ui-demo --obj ambush), Unyielding Oath moved to
where its guns bear, Fleet Marshal Petra Valk (the Nemesis flagship) targeted, the Oath lance at 92%. It is reached through
the same handlers a player uses (the steps of ui_shots.gd moment 5). Every word and figure on the pictures is read from the
battle at that moment (battle.gd _panel_info, _target_info, the fleet rows, the log); none is typed in.

## The three options (one look, three layouts)

All three: no panels, words on a darkened edge of the scene, one large focus (the odds, in ember), ember the only accent
(the action box, the odds, "Your turn", the ring under the ship that is up, its name on the board), NEM red only for the
Nemesis, Big Shoulders for names, Barlow for sentences, Azeret Mono for figures, square corners, one box on the screen.

**E1 LEDGER.** The map's rail carried over: one left sheet read top to bottom in decision order (whose turn, the ship, its
hull and four shields, its guns, the target and the odds, FIRE, the orders and the Command), the fleet at the foot as on
the map, the enemy and Nemesis top right, the log bottom right. Moved behind a click or hover: the captain, armour,
evasion and turns (hover the ship name), per-gun damage and cost (hover a gun), the Nemesis's adaptations and weakness
(Dossier), the full log (L).

**E2 CROSSING.** Yours on the left edge, theirs on the right edge (the target's hull and four shields shown as fully as
your own, the odds very large under it), the action, the Command and End ship at the foot between them. Moved behind a
click or hover: the same as E1, and the expected damage stays one sentence under the odds.

**E3 FOOTING.** One band along the bottom (the ship, its guns and orders, the shot and FIRE, in three columns); the scene
keeps the whole upper two thirds; the fleet top left, the enemy and the log top right. Moved: the same as E1.

### What every option moves off the screen (SAY LESS, R177), and where it lives

| Today (Lime) | In the ember options | Why |
|---|---|---|
| Nemesis block: ship, two adaptations, weakness, their reasons | one line: "Nemesis Fleet Marshal Petra Valk Dossier"; the rest in the Dossier, as on the map | not needed to choose this shot |
| captain's name, ARM, evasion, TURNS | hover the ship name (the HUD's existing "more on hover" layer) | read once per battle, not per shot |
| weapon table columns: number, Dmg, Cost | name, arc and range, then the odds or why it cannot fire; damage and cost on hover over the gun | the odds decide; the damage is in the shot sentence |
| the Fire block's long sentence and "Enter Fire 1 weapon / Esc Cancel" | the action box "FIRE THE OATH LANCE  Enter"; Esc still cancels | one action, said once |
| Orders grid with every order, greyed when unavailable | only the orders that can be given now (Ram and Board appear when they can be used); Turn left and Turn right become "Turn Q E" | say less |
| Target block: hull bar with ghost, four shield bars, sentence | E1 and E3: one sentence ("About 16 damage: 7 to its prow shield, 8 to hull."); E2 keeps the target's hull and shields | the sentence carries the same figures |
| End block: "2 ships still Ready, Tab jumps", "then enemy turn" sentence | "3 of 3 ships to act" in the top line, "End ship Space" beside the Command; Tab still works | the fleet list shows who is left |
| acted pips, unacted set ("in reach first: ...") | the top line's count; who the enemy can reach first goes on hover over a fleet name | a second list of the same ships |
| fleet list: shield badge, status word, hull and shield bars per ship | name and hull figure, ember bar for the ship that is up, flagship diamond, done ships in the second strength | the map's fleet lines |
| nameplates with bars on every ship | names only for the ship that is up (ember) and the target; every other name on hover | the board stays the board |
| Heat bar, enemy crest | "Heat 3" as a figure; the faction by name | figures, not furniture |
| speed (1x), threat (T), R, Grid (Z) buttons | keys still work; listed in the menu (Esc) | not part of a shot |
| log ticker, four lines | three lines; L opens the full log | say less |

The tree prompts of issue 529 (PR 533, open): the prompt takes the place of the action while it is open (the game holds
every other action until it is answered, so nothing else is lost). E1 and E2 put it where FIRE sits; E3 lets it take the
whole shot column. The role prompt (three choices) takes the same place.

## Shield colour candidates (R191: one colour, used for nothing else on any screen)

| Name | Value | Read |
|---|---|---|
| S1 Cyan | #3fcbe0 | the old colour; the brightest and most saturated, the closest to Ryan's "neon accent on dark slate" |
| S2 Glacier | #92b8e8 | a pale cold blue; reads as shield light, sits quietly beside the ember, far from the enemy lavender |
| S3 Verdigris | #63c3a0 | aged copper green; close to today's mint ring under your ships (FRIEND #52f0c4), and green reads as "good" or "ready" |

The shield appears only in the ship's four facings (a small plan of the hull, prow up, each facing's figure beside its
arc; the arc's lit share is its charge). Nothing else on these screens uses it: the log is plain text here (today's log
colours shield damage #4fc4ff; the build drops that).

## Readability at 1080 (the rail spec's checks)

READABILITY_TABLE

Method: every drawn word's box and colour is recorded by the overlay (E*_items.json on the PC); contrast is the worst
single pixel under each word on the brightest and on the darkest of six boards (the same veils with no words, the camera
turned through a full circle about the same point: the planet, the nebula and the bright dust all pass behind each edge).
Words on the board itself (the two ship names) use the map's dark halo and are not counted.

## The Board's pick

**E1 LEDGER, with Glacier shields.**

- It is the map's rail, which Ryan already passed (R176), so the map and the battle read as one game and the next
  screens follow one page.
- The decision reads in one column in the order the player makes it: which ship, how healthy, which guns bear, the
  odds, FIRE, then the other orders. Nothing on it needs a second place on the screen to make sense.
- The fight keeps the right 55% of the screen with nothing on it but two names; the one box is the action.
- E2 gives the target the most presence, but it splits the eye across both edges for every shot and squeezes the fight
  into the middle third, where the ships come out small. E3 opens the top of the screen, but its band covers 40% of the
  height and starts to read as a panel, and it separates the ship from its own guns.
- Worth carrying into E1 from E2 if Ryan likes it: the target's four shield facings on hover over its name (E2 shows
  them always).

Glacier over Cyan and Verdigris: it reads as shield light without the neon of Cyan (Ryan's first AI tell), it sits
beside the ember without fighting it, and it is far from every other colour on the screen, where Verdigris collides with
the mint ring under your ships and reads as "good".

## Notes for the build (step 2)

- The 3D board still carries Lime-era colours this job did not touch except for the capture: the ring under the ship
  that is up (ship_view.gd set_selected, lime; ember in these pictures), the hovered hex outline (board.gd, lime), the
  mint ring under your other ships and the lavender enemy markers. The build moves the first two to ember and needs a
  ruling on the mint ring if Verdigris is picked.
- R191 says one shield colour on every screen; the Oct 24 ruling says the 3D shield bubbles keep faction colours. These
  pictures change the interface only. Which of the two governs the bubbles is a question for Ryan.
- The capture tool (contrib/opus/ui_battle_ember/) is reusable for the build's before and after.

## How it was made

- contrib/opus/ui_battle_ember/godot/_ember271/ember_overlay.gd: the three layouts, drawn from the battle's data.
- contrib/opus/ui_battle_ember/godot/_ember271/ember_shots.gd: plays to the moment, hides the game's HUD, frames the two
  ships in the part of the screen each layout leaves clear, and saves every frame.
- contrib/opus/ui_battle_ember/pc/ember271_shots.bat: the PC job (fresh clone of main, ship files and godot\gen from
  build\godot, waits for an idle GPU, 1920x1080 window).
- contrib/opus/ui_battle_ember/make_pictures.py: the named pictures, crops and readability.json.
