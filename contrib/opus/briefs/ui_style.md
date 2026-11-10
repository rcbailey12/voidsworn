# UI style guide: Lime Tactical on the Glass Shell layout (issue #271)

Two picks by Ryan, Nov 9 2026. The layout is round 2 version C bold, Glass Shell (FINDINGS R145: "C bold, let's try").
The identity on top of it is variant 2, Lime Tactical (FINDINGS R149, 12:00 CST: "yeah i like lime tactical, run it").
The battle HUD is the first screen built in it (godot/ui/battle/hud.gd). The title, the campaign map, the end screen
and the menus follow these rules when they are next touched.

Spec images:
- Layout: docs/shots/ui_redesign/mockups_r2/C_glass_shell_bold.png (branch opus/issue-271-r2, PR #301).
- Look: docs/shots/ui_redesign/identity/2_lime_tactical.png and its 20-ship version (PR #314); the three-way sheet is
  identity_sheet.jpg. The mockup's CSS is contrib/opus/ui271_mockups/identity/identity.css, `body.id2`.

The theme is code in godot/ui/theme/glass_shell.gd (palette, fonts, panel, well, strip, tag, key cap, buttons, focus
ring, panel marks), so every screen draws the same pieces from one place. Do not copy its numbers into a screen.

Locked underneath (contrib/opus/briefs/ui_spec.md, R136): one scale law (k = clamp(height / 1080, 0.6, 2.2) x the
player's UI scale), the focus ring (no fill, text colour, 2 px, 3 px outside), no text under 12 at the 1080 design
height, the faction colour rule (5.4), the reserved alarm red, colour meanings and redundant encoding. This guide changes
the look, never those rules.

## 1. The one idea

A combat targeting computer. Black-olive slabs with cut corners and bracket marks; pale sage words; one loud colour,
neon lime, that means "do this next". Every line of text sits on a solid backing. Faction colour is a small accent only.

R141 (Ryan, Nov 8): "one specific UI for the game that is consistent", "a modern, sci fi setting but one that is still
focused on user actions and best practices". So: one look for every screen, no faction-themed screens.

## 2. Panels (the matte slab)

- A panel is `shell(k)`: fill `SHELL` (black-olive #0a0d0a at 80%, near-solid; the scene only hints through), a 1 px
  edge `SHELL_EDGE` (lime at 20%), no shadow, and two **chamfered corners** of 14 at 1080: top left and bottom right
  (StyleBoxFlat with corner_detail 1).
- Its marks are drawn by `frame_marks(panel, k, brackets, bevel)`, over the fill and under the children:
  - a **fine scanline**: a 1 px line of lime at 2.5% every 4 px, kept inside the chamfers;
  - a 2 px **lime bevel** along the top-left chamfer (off on a flat bar such as the battle's top bar);
  - **lime corner brackets** at the top right and bottom left, 18 px arms of 2 px.
- One panel per region, not one per block: the battle's right column is one panel holding seven wells. Fewer frames
  means fewer edges for the eye and one area to measure against the R116 frame-time gate.
- No blur. The mockup blurs behind panels in the browser; in the game the 80% fill does the same work with no cost, and
  every word is on a well anyway (ui_spec.md 5.3: flat until a capture shows text failing).
- Panels sit at the screen margin (12 at 1080), never overlap each other, and keep their content 14 in from the
  chamfered sides so nothing sits in a cut corner.

## 3. Backings (solid)

- **Well**: the solid block inside a panel that holds text. `well(k)`: `WELL` #080a08 at 93%, square, a **2 px lime
  bar on the left** (`WELL_EDGE`, lime at 35%), padding 12 by 8. The Nemesis block's bar is 3 px of ALERT red
  (`well(k, none, 10, 7, ALERT)`).
  A **lit well** (the step you are on, the ship that is up, the armed weapon) has a lime edge all round and a soft lime
  glow; nothing else lights a well.
- **Strip**: text on the board or over the scene without a panel (ship nameplates, the unacted chips, the turn strip,
  toasts, the banner, the key hint). `strip(k, accent)`: `WELL` at 88%, a 3 px accent bar on the left and a **slanted
  right end** (an 8 px cut on the bottom-right corner). The accent says whose it is: FRIEND mint for yours, FOE lavender
  for the enemy's, lime for the one that is up (with a lime edge all round when it is up or targeted), EMBER for
  warnings.
- **Tag**: a small square label in tracked caps (UP, NEMESIS, ENEMY, LOW): filled for a state (UP lime with dark text,
  NEMESIS ALERT red with dark text), outlined for a side (ENEMY lavender).
- **Key cap**: every action shows its key beside it (B Brace, Tab Next ship, Space End ship). `keycap(k)`: a square,
  dark lime-tinted fill (#141a0c), a lime edge at 45%, text `KEY_FG` #d9f78a in the number face, 13 (12 for words
  like Space). On the lime button it is `keycap_on_gilt(k)`: dark text on a light wash.
- Dimming (a ship that has acted, a step that is off) fades the words and bars, never the backing: the well or row
  fill stays at its alpha.
- Rule: if a string can land over the 3D scene, it is on a well, a strip or a tag. Floating callouts over ships
  (damage numbers) are the one exception: they carry a dark outline instead, because they live for a second.

## 4. Type

All faces are SIL Open Font License 1.1, in godot/ui/theme/fonts/ with their licence texts; `glass_shell.gd` loads them
(`body`, `medium`, `semi`, `bold`, `caps(k)`, `display(k)`, `action_font(k)`, `ship_name(k)`, `num`, `num_bold`).
Letter spacing is in whole pixels and follows k, so a screen makes its tracked faces again when it rescales.

| Use | Face | Size at 1080 | Spacing |
|---|---|---|---|
| Display: round title, banner, end card, menu titles | Chakra Petch Bold, caps | 19 to 46 | 0.14 em (`display`) |
| Section heads ("1 MOVE", "FLEET", "HULL") and tags | Chakra Petch Bold, caps, lime | 13 (tags 12 to 13) | 0.18 em (`caps`) |
| The ship that is up (star plus "LONG WATCH") | Chakra Petch Bold, caps | 20 | 0.06 em (`ship_name`) |
| The finish button ("END SHIP") | Chakra Petch Bold, caps, dark on lime | 17 | 0.12 em (`action_font`) |
| Body | Chakra Petch Regular; names and buttons SemiBold | battle 15 labels, 14 rich text and buttons, names 14 to 20, secondary 13 to 14, floor 12 | none |
| Numbers that decide something: odds, damage, hull, Heat, arc and range, cost, key caps | Azeret Mono 500, bold 700 | as the line they sit in | none |

- Campaign and menus keep base 17 (ui_spec.md 4.2).
- Chakra Petch is wider than the old Barlow Semi Condensed: a list that was set at 15 for one line drops to 14 (the
  battle fleet list did), never under 12.
- Rich text: `[code]` is the number face (`mono_font` in `make_theme`); a line that is all numbers ("312/370 to about
  75") is a rich text in the number face (hud.gd `_num_rich`).
- Numbers that decide something are bold and bright (hit chance lime, hull and shields in their bar colours); their
  units and maxima are dim ("312/370" with "/370" in BONE3).
- Glyphs the faces lack (the flagship star, for one) come from the system fallback, as they did with Barlow.
- Plain words, no em dashes, sentence case in body text.

## 5. Colour

`glass_shell.gd` keeps the ui_spec.md 5.1 names so every screen keeps its meanings; Lime Tactical changes the values.
Screens not yet rebuilt still carry the old values until they move onto glass_shell.gd.

| Name | Lime Tactical | Means |
|---|---|---|
| INK, IRON, IRON2, IRON3 | #090c09, #111611, #182019, #283228 | black-olive grounds and quiet edges |
| BONE, BONE2, BONE3 | #e8eee0, #a7b09d, #7c8674 | pale sage text: primary, secondary, dim and disabled (BONE3 4.5:1 or better on a well) |
| GILT, GILT_HOVER, GILT2 | #c8f53a, #d9ff5c, #6f8a1c | **neon lime, the one accent** (the name stays GILT); dim lime for tooltip edges |
| ON_GILT | #0d1200 | text on lime |
| KEY_FG | #d9f78a | key cap text |
| ALERT | #ff4433 | **reserved red**: the Nemesis and danger, nothing else |
| BLOOD | #ff8a72 | threat and loss in text |
| EMBER | #ffb23e | Heat, fire, warnings, cooldowns |
| VERD | #59d6a8 | calm information, your log lines, a found weakness |
| SHIELD, HULL, HULL_LOW | #4fc4ff, #ffad3b, #ff5530 | bars and their numbers |
| BAR_TRACK, SHIELD_TRACK | #2b2a20, #1b2a2e | the empty part of a hull bar, of a shield bar |
| FRIEND | #52f0c4 (mint) | your side in battle: names, nameplate accents, Ready, the ring under your hulls |
| FOE family | #c4a4ff names; #a06bff rings, chip borders, danger badges; #e2d2ff text on the enemy chip | the enemy side in battle |
| SHELL, SHELL_EDGE | #0a0d0a at 80%; lime at 20% | the panel and its edge |
| WELL, WELL_EDGE | #080a08 (93% in a panel, 88% as a strip); lime at 35% | the backing under text; a well's left bar |
| LINE | lime at 12% | row separators, a disabled button's edge |
| SCAN | lime at 2.5% | the panel scanline |

What lime is for:
- **Filled lime** is the next action and nothing else: the finish button (End ship), the UP tag, the odds tag on the
  targeted enemy. Only one filled lime **button** at a time (R148): a step's own confirm (Move here, Fire N weapons) is
  a lit button (`lit_boxes`: dark fill, lime edge, lime text), never a second filled one.
- **Lime lines and words** mark the lit step and the panel furniture: the lit well's edge, the armed weapon row, the
  hit chance, section heads, brackets, the bevel, the hovered hex on the board.
- Lime never marks a side, a faction, a warning or damage.

Friend green moved to mint (R149, this build): the mockup's spring green #5ff0a0 and the lime both read "green" at a
glance, and under deuteranopia they come closer (CIE76 distance 51). Mint #52f0c4 sits 71 from lime (69 under
deuteranopia) and still 61 from SHIELD blue. It replaces the friend green everywhere: nameplates, the fleet list's
Ready, the unacted chips, the move tips, the "Arrived" callout and the 3D ring under your ships (render/ship_view.gd).

Other rules (unchanged):
- The threat map and the reach hatching are lavender, not red. The reach hatching shows only in the Move step and stays
  faint (R148); the danger badges carry the counts in every step.
- Hull bars are segmented (10 cells in panels, 8 on nameplates); HULL_LOW at 35% (HD9). Shields are one bar per facing,
  always in the order prow, starboard, rear, port.
- Expected loss is hatching over the part of a bar a volley should take, always labelled "expected" or "to about N",
  never shown as certain.
- Rich text colours in code (BBCode) use the hex values in this table; a new colour is added here first.

## 6. Faction accent

- In battle, faction colour never touches names, plates, bars or panels (ui_spec.md 5.4). The enemy's faction is its
  crest (22 px) and its name in plain BONE in the top bar; the Nemesis block shows the faction crest as his portrait
  until the battle carries his own portrait index.
- On the campaign map and its screens, faction colour may appear as the 3 px strip accent and on crests, from
  map3d_system LOOKS only. Never as a fill, never on body text, never as a panel's colour, and never lime-like enough
  to be read as the accent (a faction whose look is yellow-green shows it on the crest only).

## 7. Layout rules (any screen)

- Decision order, top to bottom: what threatens you, what you have, what you can do, what it will do, how to finish.
  The battle column is the worked example: Nemesis, the ship that is up, 1 Move, 2 Fire, Orders, Target, 3 End.
- The finishing action is fixed in the bottom right corner and never moves (End ship; on other screens Continue,
  Confirm, Launch). Text above it keeps its height when empty so the button does not jump.
- The finishing action is the screen's one filled lime slab: `finish_boxes` (flat lime, 10 px chamfers top left and
  bottom right, a soft lime glow) plus `gilt_sheen` (a thin top highlight), its label in `action_font` caps and its key
  cap after the label.
- Lists are one line plus bars per item; the battle fleet list fits 20 ships at 1080 with no scroll.
- Details live one layer down: hover a block or a keyword for the rest ("more on hover"), never a second panel.
- A ticker, not a wall: logs show their last four lines; a key (L) opens the full log.

## 8. Rolling it out

- Build every piece from glass_shell.gd: `shell` plus `frame_marks`, `well`, `strip`, `tag`, `keycap`,
  `keycap_on_gilt`, `button_boxes`, `lit_boxes`, `finish_boxes`, `gilt_sheen`, `focus_ring`, `make_theme`, `seg_bar`,
  and the font functions. Do not copy their numbers into a screen.
- Move the screen's own colour constants onto glass_shell.gd's (campaign_ui.gd, title.gd and map3d.gd keep their own
  copies of the old palette today), and its BBCode hex strings onto the table in section 5.
- Swap the screen's fonts from brand.gd (Michroma, Oxanium, Barlow) to the glass_shell.gd faces; brand.gd keeps the
  title and tagline text.
- Title screen: the menu becomes one panel at the left third with a well per group; the game title in `display` caps
  (it may be larger and tracked wider); the menu rows are buttons with the sage focus ring; Start is the one lime slab.
- Campaign map: the side panel becomes one panel with wells (sector, fleet, choices); the fight card is a well with the
  faction accent strip; map labels are strips with the slanted end; the route you will take next is the one lime line.
  The map's danger band green (DANGER 1 #7ddc6a) sits close to lime: it moves to FRIEND mint or takes its word as the
  second channel when the map is rebuilt (ui_spec.md 5.1 collision note).
- End screen and debrief: one panel, the R137 debrief order (ui_spec.md 10) in wells; Continue is the lime slab fixed
  bottom right; Victory in lime `display` caps, Defeat in BLOOD.
- Menus: a well inside a panel with brackets and the bevel; rows are buttons with the sage focus ring (ui_spec.md 6).
