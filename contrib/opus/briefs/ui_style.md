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
neon lime, that means "do this next". Every line of text sits on a solid backing (the campaign map is the one screen
that drops the slabs and the backings: section 3 and section 8). Faction colour is a small accent only.

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
  (damage numbers) are one exception: they carry a dark outline instead, because they live for a second.
- **The campaign map exception (Ryan's pick of the Briefing layout, Nov 10 2026, FINDINGS R165).** Words on the campaign
  map are plain text with a dark halo (`halo_text`: two dark outlines under the words, HALO #070907), with no strip or
  tag behind them. Ryan on the strips and tags of rollout 1: "everything in a box or tag" was one of the tells to
  remove. It holds because the map's backdrop is at half strength, only your stop and the next jumps carry words, and
  the one box on the map is the hover tip (`tip`). It applies to the campaign map only; every other screen keeps the
  rule above.

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
| BLUE | #62a8ff | B4 blue event options: an option your fleet qualifies for (the event dialog only) |
| SHADE | #090c09 at 80% | the dim layer behind a dialog and behind the map's two slide-overs: the scene only hints through |
| COLUMN, HAIR | #0b0e0b, #1c241c | the campaign map's flat briefing column, its slide-overs and the hover tip; the column's quiet edge and its rules |
| ROW_LIT, ROW_HOVER | #161c16, #111611 | the picked route row (a slightly lighter fill); a route row under the pointer |
| HALO | #070907 | the dark halo under plain words on the campaign map (section 3, the campaign map exception) |
| PALE, PALE_CUT | sage at 25%, at 10% (as the eye reads it; map3d.gd `pale` finds the alpha through the tone map) | a route on the map you cannot fly yet (one thin line); a route cut off or already flown |

Retired with the Briefing build (R165), so they have no row: the map's danger band colours (DANGER), the stop glyph
colours (STOP) and the route planner's blue and gold (ROUTE). Danger is four pips and its word (Easy, Even, Hard,
Deadly): two channels, neither a colour (ui_spec.md 5.2). A stop is its 3D model. A route is lime or pale.

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
- On the campaign's between-battle screens, faction colour may appear as the 3 px strip accent and on crests, from
  map3d_system LOOKS only. Never as a fill, never on body text, never as a panel's colour, and never lime-like enough
  to be read as the accent (a faction whose look is yellow-green shows it on the crest only).
- The campaign map itself (the Briefing layout, R165) shows no faction colour in its words: faction and core names are
  plain text. A faction's look stays on its 3D models and their lights.

## 7. Layout rules (any screen)

- Decision order, top to bottom: what threatens you, what you have, what you can do, what it will do, how to finish.
  The battle column is the worked example: Nemesis, the ship that is up, 1 Move, 2 Fire, Orders, Target, 3 End.
- The finishing action is fixed in the bottom right corner and never moves (End ship; on other screens Continue,
  Confirm, Launch). Text above it keeps its height when empty so the button does not jump.
  The campaign map is the exception (R165): its one filled lime button, "JUMP TO <NAME>", sits in the briefing column
  under the route list it acts on, flat and square (`jump_boxes`), with the Enter key cap. The two lines above it keep
  their height, so it does not jump when another route is picked.
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
- Campaign map: the Briefing layout (Ryan's pick, Nov 10 2026, R165; the spec is campaign_map_briefing.md, the picture
  contrib/opus/ui_map_design/map_option_C_briefing.jpg). It replaces rollout 1's strips, tags and side panel, which
  Ryan called "pretty busy" and "AI generated still".
  - Left, one flat column 480 wide (`column`): no chamfers, brackets, scanline, wells or left bars. Padding 40, gaps on
    an 8 px grid, one type ladder (12 the key cap, 13 meta and caps, 14 secondary, 15 body, 16 fleet names, 17 the
    button, 18 and 20 names on the map, 22 route names, 28 and 30 numbers, 40 the sector's name). Top to bottom: where you are, the sector's name, who holds it and the sector
    condition, the routes you can take as numbered rows (name, danger pips and word, what it is and against whom, the
    reward and where it leads), two lines of detail for the picked route, the one filled lime button, the Nemesis in a
    portrait and two or three lines, and the fleet at the foot (one line a ship, a thin hull bar that is sage when full
    and takes the HULL colours when damaged).
  - Right, the real 3D chart with the backdrop at half strength. Your stop and the next jumps keep full models; stops
    further on are 70% size and under half brightness; stops behind you or cut off are dimmer still. No rings, halos,
    hover glows or threat markers. The routes to the next jumps are solid lime lines with no bloom; every other route
    is one thin pale line.
  - Two colours on top of the sage text: lime is the next action and the next jumps (the routes, the square number
    markers, the picked number, the button); ALERT red is the Nemesis (the word, the hunt clock, one small diamond over
    a stop where he meets you and beside that route's name). Nothing else on the screen takes either.
  - Words on the map are plain with a dark halo (section 3). Stops further on carry none: pointing at one, or reaching
    it with the arrow keys, shows the one tip card.
  - What the old screen showed and this one does not is one hover or one click away: the map's tip card, "Map key"
    (the marks, the danger pips, this sector, your run, the controls, Map detail and Tips) and "Dossier" (everything the
    long Nemesis block said). Both are flat slide-overs; Esc, Close or a click on the shade shuts them.
- End screen and debrief: one panel, the R137 debrief order (ui_spec.md 10) in wells; Continue is the lime slab fixed
  bottom right; Victory in lime `display` caps, Defeat in BLOOD.
- Menus: a well inside a panel with brackets and the bevel; rows are buttons with the sage focus ring (ui_spec.md 6).


## Orders sheet (campaign map; other screens follow)

Ryan picked R2 (FINDINGS R174, R176). The campaign map now takes this treatment. Every other screen keeps Lime Tactical until its own job, including the Fleet screen that holds the moved faction purchase.

| Name | Value | Use |
|---|---|---|
| EMBER (GS.MAP_EMBER) | #ff8a3a | Chosen route numeral, jump action, available routes, number boxes, current approach leg |
| TEXT | #f0eade | Names, rules, figures |
| TEXT2 | #c4beb0 | Supporting sentences |
| TEXT3 | #969084 | Joining words only, such as Pays; empty pip outlines |
| NEM | #ff6050 | The Nemesis only |

The older GS.EMBER token remains unchanged for other screens. The map uses GS.MAP_EMBER. Stop models retain their own light and faction colors.

- Big Shoulders Display variable, weight 800: capitalized names, route numerals and the action only. Region 70, chosen route name 54 and numeral 132, other route names 32 and numerals 36, Nemesis 32, ship names 28, action 34. Names wrap whole words and fit down to 28, never below it.
- Barlow Regular and Medium: sentences, labels and joining words, in sentence case. Body 18 to 21, never below 17 at the 1080 design height. Azeret Mono: hull, hunt clock and purse figures. Fonts and their OFL texts live in godot/ui/theme/fonts/.
- No rail panel or edge. A smooth black veil covers the scene below the words, 96% black at the left edge, 94% under the rail, fading to clear by 43% of the window. The stronger veil is the readability pass. Map words sit above it, with the existing dark halo.
- Every corner is square. No pills, key badges, rounded portraits, text glow or text shadow. The action is the only rail box: a 2 px ember outline, 56 px high, filled ember with dark words on hover or keyboard focus.
- The approach strip uses three bars and I, II, III, a ring for the star and a sentence case jump count. Region, holder and one short condition follow. The Map key keeps every condition's full wording.
- Routes always stay in number order. The picked route expands in place with its danger pips and word, one objective sentence, Pays and the reward, then its action. Other routes take two lines. Future stops are shown by the map, without a then line on the rail.
- The square 64 px Nemesis portrait has a 2 px NEM edge. Name and hunt pips remain on the rail. Traits, persona and the longer status explanations live in the Dossier.
- Fleet names and hull figures occupy separate columns, without classes or bars. An ember diamond marks the flagship. Damaged hull uses the existing damage color. Up to seven standard 36 px rows fit at the foot. The rail reserves the full route group first, then fits whole fleet rows into the space left. Extra rows, and names wrapping to multiple lines, scroll in the fleet area. The upper route group can scroll for extreme combinations without moving the fleet off screen.
- The faction purchase lives at the top of Fleet and refits: name, effect sentence, price or Used this sector. The same factionVerb action and affordability check govern it; its explanation remains in the Map key.
- Route and stop labels use Barlow Medium 21 with the dark halo, and Your fleet is here uses Barlow 17. Purse labels use Barlow and figures use Azeret Mono.
- Every sentence and figure on the rail must measure at least 4.5:1 against captured backgrounds from sectors I and III. Capture at 1920x1080 and 2560x1440, with four routes, each selection, action hover/focus, long names and an overflowing fleet. Use res://ui/campaign/rail_orders_shots.gd to repeat those captures. The fixture names explicitly distinguish long-name and fleet stress states from the real seeded run.
