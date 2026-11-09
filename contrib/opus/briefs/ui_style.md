# UI style guide: Glass Shell (issue #271)

Ryan's pick, Nov 9 2026 (FINDINGS R145): "C bold, let's try." The battle HUD is the first screen built in it
(godot/ui/battle/hud.gd). The title, the campaign map, the end screen and the menus follow these rules when they are
next touched. The spec image is docs/shots/ui_redesign/mockups_r2/C_glass_shell_bold.png (branch opus/issue-271-r2,
PR #301). The theme pieces are code in godot/ui/theme/glass_shell.gd, so every screen draws the same frame, well,
strip, tag, key cap and button from one place.

Locked underneath (contrib/opus/briefs/ui_spec.md, R136): one scale law (k = clamp(height / 1080, 0.6, 2.2) x the
player's UI scale), the bone focus ring, no text under 12 at the 1080 design height, faction colour rules, the palette
with meanings. This guide changes the look, never those rules.

## 1. The one idea

One see-through glass frame per region; every line of text on a solid backing. The scene shows through the frame,
never through words. Faction colour is a small accent only.

R141 (Ryan, Nov 8): "one specific UI for the game that is consistent", "a modern, sci fi setting but one that is still
focused on user actions and best practices". So: one look for every screen, no faction-themed screens.

## 2. Frames (glass)

- A frame is a glass shell: fill `SHELL` (ink at 38% alpha), a 1 px etched edge `SHELL_EDGE` (gilt at 30%), square
  corners, a soft dark shadow, and four gilt corner ticks (14 px arms, 2 px lines; `ticks_on`).
- One frame per region, not one per block: the battle's right column is one shell holding seven wells, not seven
  frames. Fewer frames means fewer edges for the eye and one glass area to measure against the R116 frame-time gate.
- No blur. The glass is a flat see-through fill (ui_spec.md 5.3 rules flat until a capture shows text failing; with
  every word on a solid well, it cannot).
- Frames sit at the screen margin (12 at 1080) and never overlap each other; each region owns its rectangle.

## 3. Backings (solid)

- **Well**: the solid block inside a frame that holds text. Fill `WELL` #0b111c at 94%, a 1 px border (IRON3 at 90%),
  2 px corners, padding 12 by 8. A lit well (the step you are on, the ship that is up, the armed weapon) has a GILT
  border and a soft gilt glow; nothing else lights a well.
- **Strip**: text on the board or over the scene without a frame (ship nameplates, the unacted chips, the turn strip,
  toasts, the banner, the key hint): `WELL` at 86% with a 3 px accent bar on the left. The accent says whose it is:
  FRIEND green for yours, the FOE lavender for the enemy's, GILT for the one that is up, EMBER for warnings.
- **Tag**: a small solid label in letter-spaced caps (UP, NEMESIS, ENEMY, LOW): filled for a state (UP gilt, NEMESIS
  alarm red), outlined for a side (ENEMY lavender).
- **Key cap**: every action shows its key beside it (B Brace, Tab Next ship, Space End ship). IRON2 fill, a BONE3 edge,
  bone text, 13 (12 for words like Space).
- Rule: if a string can land over the 3D scene, it is on a well, a strip or a tag. Floating callouts over ships
  (damage numbers) are the one exception: they carry a dark outline instead, because they live for a second.

## 4. Type

- Display: Michroma, upper case, for the round title, the banner, the end card and menu titles (19 to 46 at 1080).
- Section heads: Oxanium small caps, letter-spaced, 13, BONE2, with a gilt step number in front ("1 MOVE", "2 FIRE",
  "3 END, AND WHAT HAPPENS NEXT"). Blocks without a step have no number (ORDERS, TARGET).
- Body: Barlow Semi Condensed. Battle base 15 (labels), 14 (rich text and buttons), names 15 to 20 semibold, secondary
  13 to 14, the floor 12. Campaign and menus keep base 17 (ui_spec.md 4.2).
- Numbers that decide something are semibold and bright (hit chance gilt, hull and shields in their bar colours); their
  units and maxima are dim ("312/370" with "/370" in BONE3).
- Plain words, no em dashes, sentence case in body text.

## 5. Colour

The palette is ui_spec.md 5.1; this guide adds the shell entries (also listed there):

| Name | Value | Means |
|---|---|---|
| SHELL | ink rgb(9, 14, 24) at 38% | the glass frame's fill |
| SHELL_EDGE | GILT at 30% | the etched frame edge (corner ticks are GILT at 85%) |
| WELL | #0b111c (94% in a frame, 86% as a strip) | the solid backing under all text |
| WELL_EDGE | IRON3 at 90% | a well's border |
| SHIELD_TRACK | #16304a | the empty part of a shield bar |

- GILT is the player's own and the current step: the ship that is up, the lit well, the primary action, hit chances.
- FRIEND green and the FOE lavender family carry the sides in battle (names, plate accents, rings, badges). ALERT red
  is the Nemesis tag's alone. The threat map and the reach hatching are lavender, not red.
- Hull bars are segmented (10 cells in panels, 8 on nameplates); HULL_LOW at 35% (HD9). Shields are one bar per facing,
  always in the order prow, starboard, rear, port.
- Expected loss is hatching over the part of a bar a volley should take, always labelled "expected" or "to about N",
  never shown as certain.

## 6. Faction accent

- In battle, faction colour never touches names, plates, bars or panels (ui_spec.md 5.4). The enemy's faction is its
  crest (22 px) and its name in plain BONE in the top bar; the Nemesis block shows the faction crest as his portrait
  until the battle carries his own portrait index.
- On the campaign map and its screens, faction colour may appear as the 3 px strip accent and on crests, from
  map3d_system LOOKS only. Never as a fill, never on body text, never as a whole frame's colour.

## 7. Layout rules (any screen)

- Decision order, top to bottom: what threatens you, what you have, what you can do, what it will do, how to finish.
  The battle column is the worked example: Nemesis, the ship that is up, 1 Move, 2 Fire, Orders, Target, 3 End.
- The finishing action is fixed in the bottom right corner and never moves (End ship; on other screens Continue,
  Confirm, Launch). Text above it keeps its height when empty so the button does not jump.
- Lists are one line plus bars per item; the battle fleet list fits 20 ships at 1080 with no scroll.
- Details live one layer down: hover a block or a keyword for the rest ("more on hover"), never a second panel.
- A ticker, not a wall: logs show their last four lines; a key (L) opens the full log.

## 8. Rolling it out

- Build pieces from glass_shell.gd (`shell`, `well`, `strip`, `tag`, `keycap`, `button_boxes`, `focus_ring`,
  `make_theme`, `ticks_on`, `seg_bar`); do not copy their numbers into a screen.
- Title screen: the menu becomes one shell at the left third with a well per group; the title stays Michroma.
- Campaign map: the side panel becomes one shell with wells (sector, fleet, choices); the fight card is a well with the
  faction accent strip; map labels are strips.
- End screen and debrief: one shell, the R137 debrief order (ui_spec.md 10) in wells; Continue fixed bottom right.
- Menus: a well with the shell edge and corner ticks; rows are buttons with the bone focus ring (ui_spec.md 6).
