# Playbook: screens

Issue 405. Written by the Board (Fable 5.2), Nov 11 2026. Format: docs/playbooks/PROGRAM.md. Use this to design or rebuild one
screen. The worked example is the campaign map's Briefing layout.

## 1. Target

- Ryan, Nov 10, on the first Lime Tactical map: "it's getting pretty busy and it also reads as AI generated still, rather than
  a clear and consistent human designer." His pick from three options: "Briefing is it but I want that merged with the
  graphical quality of the original map, minus clutter and noise of it."
- What he named as the tells of a machine-made screen: too many colours and glows, everything in a box or tag, uneven type and
  spacing. The cure is restraint and one system.

## 2. The system (what every screen shares): the orders sheet

Lime Tactical is retired (R191). Every screen moves to the orders sheet, the look Ryan passed on the campaign map's rail
(R176, contrib/opus/briefs/campaign_rail_orders_sheet.md) and picked again for the battle screen (E1 LEDGER, R210). The
battle screen (godot/ui/battle/ledger.gd) is the second screen built in it; build the next ones from this section.

- **One accent, the ember (#ff8a3a, glass_shell.gd MAP_EMBER).** It marks the next action and what it acts on: the action
  box, the odds, "Your turn", the ship that is up (its name on the board and its ring), the hovered hex. Nothing else is
  orange. NEM (#ff6050) is the Nemesis only. **Glacier (#92b8e8, GLACIER) is shield readouts only** (R210); the shields drawn
  around ships in space keep their faction colours. A damaged hull figure takes the game's damage colour (HULL_LOW).
- **Three text strengths**: TEXT for what the player must read, TEXT2 for supporting sentences, TEXT3 for joining words only
  ("Hull", "Target", "Heat", "Dossier"), never a sentence.
- **Three faces, one job each**: Big Shoulders Display for names in capitals (never under 28 px at 1080, never a sentence),
  Barlow for every sentence and joining word, Azeret Mono for figures and keys.
- **No panels.** Words sit on a smooth darkening of the scene (about 94% black, full strength under the words, fading to
  nothing), never on a filled rectangle with an edge. Square corners. No pills, key badges, glows or shadows.
- **One box per screen**: the action, a 2 px square ember outline 56 px tall with its key on the right, filled ember under the
  pointer. Dialogs (the menu, the end card) and hover tips are near-black squares with a hairline edge.
- **Width follows the decision (R218).** Sheet and panel widths are set by the decision the screen holds, not by how much
  data exists, and the scene keeps most of the screen. When Ryan rules a width on one screen, it is written here as the rule
  for every sheet. Ryan, Nov 11 2026: "the side left panel takes up a ton of the screen. It's like 30-40% of the screen and
  blocking a lot that's going on."
- **Keys after words**, in the figure face and the second strength: "Brace B", "End ship Space". No key caps.
- **Say less (R177).** Only what the screen's decision needs is on it; the rest is one hover or one key away, and the pull
  request lists every moved item and how it is reached. Nothing is deleted from the game.
- **Readability, checked by a test**: nothing under 17 px at 1080, three strengths, 4.5 to 1 over the brightest and darkest
  board, no overlaps at any fleet size or name length (the battle screen's check, godot/ui/battle/test/ledger_readability_test.gd,
  composites the screen's own darkening over pure white and black, so a pass holds over any backdrop).
- **Board colours follow**: no lime on the 3D board either (the ring under the ship that is up and the hovered hex are ember);
  the threat map and the reach hatching are bone (TEXT), because red is the Nemesis alarm's and purple is on Ryan's list.
- Palette and faces come from godot/ui/theme/glass_shell.gd (MAP_EMBER, TEXT, TEXT2, TEXT3, NEM, GLACIER, sheet_name,
  sheet_body, sheet_medium, num). A screen adds what is missing to the theme, never loose numbers of its own.

### The battle screen (E1 LEDGER, issue 271)

The orders sheet takes about a fifth of the screen width (380 px from a 40 px margin at 1080), never more than a quarter, and
shows detail only for the decision in front of the player; everything else waits behind a key or a hover (R218). A fleet too
big for it folds into "and N more" with a hover (R220). The camera centres the board in the part the sheet leaves clear.

One left sheet, read in the order the player decides: whose turn and how many ships still act; the ship (name, class, hull,
movement, its four shields as a small plan in Glacier); its status line; its guns (name, arc and range, then the odds or why
it cannot fire); the target and the odds, large, with one sentence of expected damage; the action; the orders that can be
given now; the Command and End ship; the fleet at the foot. Top right: Menu, the enemy and Heat, the Nemesis. Bottom right:
the last three log lines. Names on the board only for the ship that is up and the target. The camera centres the board in
the part the sheet leaves clear (camera_rig.gd screen_shift).

What moved behind a hover or a key (all still reachable):

| Was on the screen | Now |
|---|---|
| captain, armour, evasion, turns, sections, perks, the key list | hover the ship's name |
| a gun's damage, cost, reload, arc words | hover the gun; click it or press its number to arm it alone |
| the target's hull and four shields | hover the target's name |
| the Nemesis block (aboard, flees when, adaptations, weakness) | hover the Nemesis line |
| Heat gauge | "Heat 3"; hover for the rules behind it |
| the unacted set, who the enemy can reach first | the count in the top line; hover it |
| fleet bars, status words, LOW, NEW, danger badges | hover a fleet line (click picks the ship) |
| orders that cannot be given now (Ram, Board, a cooling ability) | hidden until they can; their keys work as before |
| the step hints (Move, Fire, End) | one short sentence; the full hint on the action's hover |
| Cancel button | Esc |
| speed, threat map, top-down, grid buttons | Esc menu (and R, T, Z keys) |
| the key line along the bottom | Esc menu, Keys; and the ship name's hover |
| nameplates with bars on every ship | hover a ship |
| the four-line log ticker | three lines; L (or "Log L") opens the full log |
| the status line's state words | hover the status line for their definitions |

## 3. Steps

1. **Name the decision.** One sentence: what does the player decide on this screen? Everything is ranked by how much it
   helps that decision.
2. **Options.** Two or three flat mockups at 1920 by 1080 that differ on real choices (where the list sits, how much is in
   boxes, how many colours), with the same real content in each. The Board makes these on a Design canvas; the generator for
   the map's three is contrib/opus/ui_map_design/mockup_gen.py.
3. **Pick.** Ryan picks, or mixes. Ask what to keep from the present screen before building.
4. **Brief.** One file in contrib/opus/briefs/: his words, the layout with sizes, what stays, what leaves and where it goes,
   the done test. contrib/opus/briefs/campaign_map_briefing.md is the pattern.
5. **Build** in the game from the brief, theme first.
6. **Capture** on the PC at 1080 and 1440: the plain state, a busy state, each overlay, a hover, and a damaged or edge case.
   Look at them at full size against the mockup: alignment to the grid, no overlaps, the ember only where it should be.
7. **One image to Ryan**: the new screen beside the old one.

## 4. The checks that prove it

- contrib/opus/tools/ui_spec_tests.js and the standing checks pass; the screen's own read-only test passes (opening a screen
  never changes the run or the save: test the property, not the spelling of a call).
- The "Godot game checks" job loads every script and scene and plays a bot battle.
- Captures exist for every state in step 6, from the final commit.
- The pull request lists every moved item and where it lives, and carries the impact sweep (callers, saves, twins, every UI
  path, which tests ran).

## 5. Traps

- A screen that only reads up close. Ryan, on the map's first in-game capture: "It's hard to read all the stops after the
  first. I'm okay with no text but it's hard to even see the icons right now." Quiet does not mean invisible: dimmed things
  still need an icon that reads (R170).
- A screen that never changes. Same capture: "There's no change when you're going to a new system or getting closer in round
  2 or 3 to the star?" A screen the player sees many times must show where they are in the run (issue 420).
- Cut-off sentences with dots. Give text its room or write it shorter.
- "Only reads" claims that are not true: a draw call that creates a record (Muse's check of PR 349). Use the read-only
  lookups (C.nemRead).
- Captures that are staged but never committed: the picture Ryan judged must be in docs/shots/ from the final commit.

## 6. Worked examples

The battle screen: three layouts captured over the real battle (issue 271 step 1, contrib/opus/reviews/battle_screen_ember_options.md),
Ryan's pick E1 (R210), the build (step 2, contrib/opus/reviews/battle_screen_ember_build.md, pictures in
docs/shots/ui_battle_ember/build/).

The campaign map: three options (contrib/opus/ui_map_design/), the brief (contrib/opus/briefs/campaign_map_briefing.md), the
build on opus/issue-344 (pull request 349), the finish (issue 418) and round 3 (issue 420: the approach to the star across
three sectors, and stops ahead readable by icon).

## 7. Job template (one screen from a brief)

```
Owner: codex (or an Opus helper at medium effort while Codex is busy)
Brief: contrib/opus/briefs/SCREEN.md; docs/playbooks/screens.md; contrib/opus/briefs/ui_style.md and ui_spec.md
Deliver to: godot/ui/SCREEN/, godot/ui/theme/ (only what the theme lacks), docs/shots/ui_redesign/SCREEN/
Branch: codex/issue-<number>
Effort (Codex): high
Done when: the checks pass with a read-only test for the screen; captures at 1080 and 1440 of every state the brief lists are committed from the final commit; the report lists every moved item and where it lives. What Ryan will see: the new screen beside the old one.
```

One screen is one or two build runs and one or two capture runs, plus one Ryan look.

## 8. Open question for Ryan

Settled: the battle HUD takes the orders sheet (R210, E1 LEDGER). Open: the enemy's violet markers and the acting enemy's
lavender ring on the 3D board, and the mint ring under your other ships, are board colours this rollout did not change.

## 9. Seat

The Board designs the options, writes the brief and judges the captures. Codex or an Opus helper builds. DeepSeek does the
well-specified follow-ups (a string, a test, a moved fact). Muse checks from outside before or straight after the merge.
