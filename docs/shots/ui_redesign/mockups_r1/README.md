# Issue 271, round 1: battle screen mockups

Opus worker thread, Nov 9 2026. Brief: FINDINGS R141 (Ryan's pick on #270), contrib/opus/briefs/ui_spec.md (locked rules),
Muse's #270 package (D6 Glass Bridge, D3 Chart Room). No game code changed.

**Start with contact_sheet.jpg.** Three layouts, each in a restrained (A) and a bold (B) variation, all 1920x1080.
stress_20_ships.jpg shows the same three layouts with a 20-ship fleet.

| File | What |
|---|---|
| 1a_command_dock_restrained.png, 1b_command_dock_bold.png | Layout 1, Command Dock |
| 2a_action_column_restrained.png, 2b_action_column_bold.png | Layout 2, Action Column |
| 3a_chart_frame_restrained.png, 3b_chart_frame_bold.png | Layout 3, Chart Frame |
| contact_sheet.jpg | all six on one page, readable on a phone |
| stress_20_ships.jpg | each layout with 20 ships, plus a close crop of its roster |

## The one shared style (all six)

- One look for every faction. Faction colour only lives in the two crests (your admiral's at the top left, the enemy's beside its name, and in 1B a 2 px ember line under your crest); plates, roster and panels use friend green and foe lavender only (ui_spec.md 5.4).
- Frames are hard rectangles: no rounded cards, no soft drop shadows, no pill buttons. Chart Room registration corners on every pane; the bold variation adds cut corners and etched glass.
- Every piece of text sits on a backing: restrained panes are 94% solid ink; bold panes are frosted glass (blurred and darkened sky behind a tinted pane) so the nebula never shows through crisp. In-world plates now have their own dark backing chip too.
- Bars are segmented (10 steps on the hull, 4 shield quads in prow, starboard, rear, port order), so the value reads by count and length as well as colour. Below 35% hull the bar turns hull-low red and the row says LOW (second channel, ui_spec.md 5.2).
- Palette meanings unchanged: gilt is yours and the primary action (Up, End ship, the current step, hit odds), ALERT red only on the Nemesis tag and his clock, blood for threat text, verdigris for ready and gains.
- Type: Barlow Semi Condensed body with tabular figures, Oxanium for small caps labels and numbers, Michroma only for the bold round title. All three ship with the game already. Nothing under 12 px.
- Every action shows its key in a keycap (1 to 4 weapons, 5 spinal cannon, B, X, G, Q, E, C Command, Tab, Space, Esc). Command gets C and Retreat moves into the Esc menu (ui_spec.md follow-up G).
- What the restrained and bold versions share: identical layout, content and order. Bold changes the material only (glass, etched grid, glow on gilt and the Nemesis tag, cut corners).

## The scene in every mock

A Nemesis fight, round 3, your turn: Long Watch (your flagship dreadnought) is up, 4 of 10 ships have acted, the enemy is the Ashfall Hullbreakers under Warlord Skarn-Maw on the Pyre-Barge (adapted: +20% shields; weakness known: thin stern plating; his clock is full). The planned hex gives 2 of 4 guns on a Hullbreaker wrecker. Heat 3.

## Layout 1: Command Dock

- **What it puts first:** the bottom console. Left bay is the ship (hull, shields by facing, sections, stats), middle bay is "Now": the move, fire, end steps, the four weapon tiles with hit odds and expected damage against the target, then the orders row; right bay is "What happens next" and End ship.
- **20 ships:** the roster on the left drops the captain line (except on the ship that is up) and tightens rows; all 20 fit above the dock with no scrolling.
- **Log:** a full-height column on the right, always present (Chart Room margin log).
- **Nemesis:** a plate hanging from the top bar, centre: portrait, ALERT tag, ship, flee line, adaptation and weakness.
- **Cost:** it takes the bottom 220 px of field across the whole width, the most of the three. Godot: one HBox dock with three bays built from today's hud.gd pieces (card, panel, weapon rows); the roster and log stay where they are. About 2 Opus runs for the restyle, plus one Ryan review round.

## Layout 2: Action Column

- **What it puts first:** one right-hand column read top to bottom in the order you decide: who threatens you (Nemesis), who is up, 1 move, 2 fire (each weapon with odds), orders, the target you are aiming at (its hull, shields and what your guns will do to it), and at the bottom corner 3 end and what happens next, with End ship the last thing your eye reaches and the easiest corner for the mouse.
- **20 ships:** the left rail shows one line and the bars per ship (the captain line only on the ship that is up); 20 rows fit with room to spare.
- **Log:** a four-line ticker at the bottom left, always present; L opens the full log.
- **Nemesis:** the top of the column, above the ship, so it is the first thing read every activation.
- **Cost:** the field keeps the full height and everything left of the column, the widest field of the three. Godot: one VBoxContainer column (the existing panel plus the card's steps and buttons moved into it), a slimmer roster, a ticker log. The cheapest build: about 1 to 2 Opus runs, plus one Ryan review round.

## Layout 3: Chart Frame

- **What it puts first:** the ship. Its order card (bars, steps, weapons with odds, orders, what happens next) docks beside the ship that is up, on a leader line, so your eyes stay on the board. End ship and Command sit in a fixed corner at the bottom right of the field.
- **Order strip:** the top margin shows who acts next, in order, then the enemy turn and the next round: the "what happens next" of the whole turn. At 20 ships it shows the next six and "+N more".
- **20 ships:** the left margin is a ruled table (name, hull %, state, class and captain, bars); all 20 fit.
- **Log:** the right margin, full height, always present, under the Nemesis dossier.
- **Nemesis:** a dossier at the top of the right margin with his clock (four ALERT cells), and the tag on his plate in the field.
- **Chart rulers:** column letters and row numbers along the field edges, as on a plotting chart.
- **Cost:** the card covers part of the field next to your ship, and it has to follow the camera and stay clear of plates. Godot: the card needs the ship's screen position every frame (camera unproject), edge clamping, a leader line, and the order strip is new. The most work: about 3 Opus runs, plus one Ryan review round.

## Bold variation cost (any layout)

Frosted glass in Godot is one shader on each pane that reads the screen texture behind it at a blurred mip level and tints it (no extra viewports). It adds GPU work over the whole pane area, so it gets measured against the scene gate (R116, 12.5 ms) at 1080 and 4K before it ships; if it costs too much, the same panes fall back to the restrained solid fill with the bold edges, corners and glow kept. About half an Opus run on top of the layout.

## Opus's pick

**2B, Action Column, bold.** It is the most action-first of the three: one column read in the order you decide, every weapon with its odds, the target you are hitting, and what happens after you end, with End ship in the bottom corner. It keeps the widest field, holds 20 ships without scrolling, and is the cheapest to build from today's HUD. Bold, because Ryan named Glass Bridge bold as the closest look; the column's frosted panes keep text readable over the brightest nebula in this frame. Second choice: 3A, if Ryan wants his eyes to stay on the board.

## What these are, and are not

- The background is a real battle capture (docs/shots/ship_pipeline/bench207/scene_engagement.webp, Ryan's PC, Nov 2026). Its old HUD panels and plates were painted out (soft blurred fill at the screen edges, small smudges where the old plates were) and the new plates drawn on top. Layouts 2 and 3 show the same frame zoomed out slightly so both fleets sit in the open field. The in-world rings, arcs and ships are today's.
- Rendered as HTML and CSS in headless Chromium in the cloud, not in Godot. Fonts, crests and the Nemesis portrait are the game's own files.
- Not shown yet: the enemy turn (the turn track's lavender segment becomes the enemy phase bar), the Esc menu and end card (both keep the bone focus ring), modal dialogs, tooltips. Those follow the picked layout in the build round.
- Numbers in the mock (odds, damage, crew) are illustrative, not from the rules.
- Rebuild: `sh contrib/opus/ui271_mockups/make.sh` from the repo root (Python with Pillow, OpenCV and Playwright); it reproduces these files exactly.
