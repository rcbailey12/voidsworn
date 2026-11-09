# Issue 271, round 2: mockup 2B revised

Opus worker thread, Nov 9 2026. Brief: FINDINGS R141 and R142, Ryan's call on round 1 (2B Action Column bold, "the best so far"),
Muse #292's synthesis (contrib/muse/research/ui_best_practice_2026_11/synthesis.md, section 4: changes 1 to 18 and the S2 undo
ruling), contrib/opus/briefs/ui_spec.md (locked rules). No game code changed.

**Start with contact_sheet.jpg.** Three versions of the revised 2B, each restrained and bold, all 1920x1080 over the same real
battle capture as round 1. pieces_closeup.jpg shows the new parts up close. stress_20_ships.jpg is the pick with 20 ships.

| File | What |
|---|---|
| A_solid_slab_restrained.png, A_solid_slab_bold.png | Version A, Solid Slab |
| B_glass_cards_restrained.png, B_glass_cards_bold.png | Version B, Glass Cards |
| C_glass_shell_restrained.png, C_glass_shell_bold.png | Version C, Glass Shell (Opus's pick: bold) |
| pieces_closeup.jpg | heat gauge, weapon rows, ghost expected markers, keyword tooltip, danger badge, unacted set and counted line, at 1.5x |
| C_glass_shell_bold_20_ships.png, stress_20_ships.jpg | the pick with a 20-ship fleet, plus the roster at full size |
| contact_sheet.jpg | all six on one page, readable on a phone |

## What all three share (the numbered changes)

The scene is the Move step: Long Watch is up, the pointer is on a hex two east of it (a planned move with one turn to face
north-east), and the Fire block reads the odds from that planned hex.

Kept, as in round 1:
1. The seven blocks in decision order: Nemesis, the ship that is up, Move, Fire, Orders, Target, End. None added, none removed.
2. Hit chance and expected damage per weapon, and the line for all bearing guns on the target.
3. The End box, with End ship fixed in the bottom right corner.
4. The four-line log ticker, with L for the full log.
5. One roster list, one line plus bars per ship; at 20 ships all rows fit with no scroll (stress_20_ships.jpg).

Changed:
6. Heat is a 9-segment gauge in the top bar (Heat 3 here). The fire rows carry a fixed-width cost tag at the right. See finding 1
   below: in the rules Heat is the run's difficulty level, not a weapon resource, so the tag shows the weapon's cooldown instead
   (free for guns, CD 2 for torpedoes, shown in pieces_closeup.jpg).
7. Each weapon is one line, scanned left to right: key, name, arc and range token (S 1-5 for starboard, range 1 to 5), hit chance,
   expected damage, cost. A gun that cannot fire shows the reason in place of its odds.
8. The ship line keeps ARM, MOVE and TURNS; EVA and CREW move to the hover layer ("more on hover").
9. The End box has a counted line ("5 ships still Ready"). It shows only when the count is above zero, and its height is kept
   either way so End ship never moves.

Added:
10. Reach and danger shading on the board: how many enemies could reach each hex next turn, quiet and in the enemy's lavender
    (palette FOE family, ui_spec.md 5.1). Each roster row whose ship is in reach gets a danger badge (reticle plus a number), and
    the ship that is up shows its own badge.
11. The arc preview: the up ship's current arcs first, faint and dashed; the hovered hex's arcs second, solid and brighter, with the
    path, the destination hex and a ghost chevron facing the new way. It sits above the threat shading and shows only in Move.
    Beside the pointer: "2 enemies can reach this hex, now 1" and "2 hexes, turn to NE, 2 of 4 guns bear".
12. Ghost expected markers: the hatched part of the target's hull bar, and of its port shield (the facing expected to drop), shows
    what the volley is expected to take, labelled "expected". The same ghost shows on the target's plate in the field.
13. The unacted ships (versions B and C only; A is option (a), see below).
14. Keyword tooltips, one layer deep: dotted words (Adapted, Weakness, ARM, Heat, the arc tokens, Braced, LOW, facings) open one
    short definition beside them; from the column they open to the left, over the field (pieces_closeup.jpg, piece 14). The
    definitions are a writing job of their own (#292 S6: content, not code).

Cut, and left out: per-weapon best and worst ranges (15), any order strip or numbered next-three (16), a threat text block in the
column (17: the round 1 line "3 can reach Long Watch" is gone from the End box; threat now lives on the board and the roster), and
hit points as numbers on roster rows (18). No undo slot after a confirmed move (S2, Ryan, Nov 8: option (i)).

The column still has room: about 120 to 160 px free between Target and End in every version, so #292's reserve demotions (TURNS, then ARM,
to tooltips) are not needed.

## The three versions: one open choice in each of three places

| | A Solid Slab | B Glass Cards | C Glass Shell |
|---|---|---|---|
| Threat on the board (10) | contour lines: dashed where reach starts, solid at 2, double at 3 or more, band numbers on the lines; no fill | a lavender tint that deepens with the count, plus an edge line around the 3-or-more band | hatching: sparse lines for 1, dense for 2, cross-hatch for 3 or more |
| Unacted ships (13, #292 S4) | option (a): none on the top bar; the End box's "Then Debt Paid is up" and the counted line carry it | the chair's set (b-set): "5 unacted" and three names in roster order, "+2" | the set (b-set), but the ships in reach come first, each with its badge |
| Backing | one solid column, full height, sections split by rules; no glass anywhere | separate glass panes (round 1's 2B) | one glass shell for the column, every block on its own solid well |
| Restrained vs bold | flat ink vs ink with etched edges, cut corners and glow | heavier frost vs round 1's bold glass | lighter shell vs stronger glass, etched grid, glow |

### A, Solid Slab (the Chart Room end)
- From round 1: the column is one solid slab instead of five glass panes; the top bar and roster are solid too. Threat is drawn as
  lines only, so the board art and the arcs stay fully visible.
- Why: the most legible and cheapest form; no blur anywhere, so nothing to measure against the R116 gate. Weak spots: the dashed
  first line runs under the friendly fleet's plates and gets lost there, and with option (a) the player has no names of who is
  left without reading the roster.
- Godot cost: about 2 Opus runs plus one Ryan round. The contour is new board code (edges between hexes of different counts, drawn
  as a line mesh); the panels are today's flat StyleBoxes.

### B, Glass Cards (round 1's 2B, revised)
- From round 1: same glass panes; the new pieces added inside them; the threat is a tint, the closest to today's R key threat map.
- Why: the smallest step from what Ryan liked, and the tint is the cheapest board form (the board already fills hexes by colour
  through board.set_overlay). Weak spot: the count rides on how strong the tint is, which is close to colour-only (ui_spec.md 5.2
  wants a second channel); only the 3-or-more band has an edge line. The colour-vision pass (U-D, #238) would test it.
- Godot cost: about 2 to 3 Opus runs plus one Ryan round. The blur shader runs under five panes.

### C, Glass Shell (Opus's pick, bold)
- From round 1: the column becomes one glass shell holding seven solid wells; the roster, log and top bar get the same treatment.
  Threat is hatching. The unacted set leads with the ships the enemy can reach.
- Why: it keeps the Glass Bridge look Ryan named while every line of text sits on a solid well, which is R141's rule ("solid or
  frosted backing behind all text") with no dependence on the nebula behind it. The hatch carries the count by pattern as well as
  colour, so it already has the second channel ui_spec.md 5.2 asks for, and it reads as texture, not paint, so it stays passive.
  Putting in-reach ships first in the set answers "who should I move next" without claiming a turn order (no arrows, no numbers;
  the badge is a threat count, not a position). Weak spot: the hatching is busier than the tint over large areas; if Ryan finds it
  noisy, B's tint drops into C unchanged.
- Godot cost: about 2 to 3 Opus runs plus one Ryan round. The hatch is one small shader on the existing hex overlay (a band
  number per hex picks the pattern). The blur runs under one shell instead of five panes, so the R116 measurement covers one area;
  the wells are plain StyleBoxFlat.

### Shared Godot work (in every version's count above)
- The danger count per hex: today battle_api.threat_map() returns damage per hex (summed over enemies) and battle.gd draws it red
  behind the R key. The count needs the same loop to also return how many enemies reach each hex, a small read-only addition to
  the rules API with its twin in ui3d.js computeThreat; shown by default in the player phase, in lavender (ALERT red is the
  Nemesis's alone).
- The arc preview at the hovered hex mostly exists: battle.gd _fans already draws the arcs on the ghost when a move is planned.
  The new part is drawing the current-position arcs faint and dashed underneath.
- Weapon rows, ghost segments on the bar builders (_hull_bar, _shield_quads), the heat gauge, the counted line, the badge and the
  set chips are hud.gd work on today's builders. The keyword tooltip rides on hud.gd show_tip; the definitions are a writing job.

## Opus's pick

**C, Glass Shell, bold.** Glass look, solid text, threat that reads without colour, and the "who next" set pointing at the ships
in danger. Second choice B bold if the hatching reads as noise; A if the glass fails the R116 gate.

## Findings for the Board

1. **#292 change 6 assumes a Heat resource the game does not have.** In the rules, Heat is the run's difficulty level (data.js
   HEAT, core.js heatLevel: 7 optional rules weighing 1 or 2, up to 9). No weapon costs Heat to fire. The gauge is drawn as asked
   (the run's level, with a tooltip), and the per-weapon tag shows the real forward cost, the cooldown (torpedoes CD 2, abilities
   like the spinal cannon CD 3; guns are free). The Board or Muse should confirm this reading.
2. **Round 1 overstated Long Watch's move.** The Daybreak dreadnought has speed 2 (data.js ascendant, sp:2); round 1 showed 3 of 3.
   Round 2 shows 2 of 2.
3. **The capture's fleets stand about 18 hexes apart**, farther than any real reach (these guns reach 5 hexes and ships move a few). The shading
   uses stretched reach radii so the bands sit where they would in a closing fight; in the game the rules layer computes them.
4. Today's threat map is red (battle.gd _threat_fills). The palette gives the enemy side lavender in battle and keeps alarm red for
   the Nemesis tag, so the build recolours it.

## What these are, and are not

- Rendered as HTML and CSS in headless Chromium in the cloud over the bench207 capture (Ryan's PC, Nov 2026), round 1's setup.
  The board shading and arcs are drawn on the capture's real hex grid: a homography fitted to its grid lines (median error about
  1 px over 240 matched corners), so they sit on the hexes you see.
- Numbers (odds, damage, counts) are illustrative, not from the rules.
- Not shown: the enemy turn, the Esc menu, the end card, tooltips other than the arc token.
- Rebuild: `sh contrib/opus/ui271_mockups/r2/make2.sh` from the repo root (Python with Pillow, OpenCV and Playwright).
