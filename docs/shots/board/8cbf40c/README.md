# Board look trial: four ways to draw the board (Nov 1, 2026)

Ryan, after today's 16:12 playtest: "it almost ends up just looking like a board game on top of a cool background with
the gray and 2d plane aspect. especially with the environment hexes. some alternative approaches would go a long way."

Here are three alternatives next to today's board. **Nothing is switched on yet.** The game still opens on today's board
until Ryan picks one. The rules, and which hexes a ship can move to, are untouched. Move hexes stay blue in every look.

Captured on Ryan's PC (RTX 5080, Forward+, max quality, 1920x1080), lane A job `board_l2_8cbf40c`. Same battle, seed and
camera for every look. A ship is selected and a move hex two or three out is hovered, so you see the move area and a
planned move. The HUD is hidden. The "Grid (Z)" button in C's shots (top right) is the new toggle.

## Start here
1. `all_battle_camera.jpg`: every look in all three settings at the normal battle camera (columns: frontier belt,
   nebula storm, dead star; rows: today, A, B, C, C with the tactical grid up).
2. `deadstar_looks.jpg`: biggest difference between the looks (the gravity well).
3. `frontier_belt_looks.jpg` and `nebula_storm_looks.jpg`: each look close up, at the battle camera and zoomed out.

## The looks
- **Today**: a dark grey plate under the whole board, every hex outlined, and terrain shown as tinted hexes (violet
  nebula, sand debris, yellow storm).
- **A "Holo war-table"**: no grey plate and no filled hexes. The grid is faint holographic lines with brighter corners.
  It shows only around the ship that is up and around the cursor, and fades to nothing further out. Terrain hexes have
  no colour fill: you see their rocks and clouds plus a thin coloured edge around each patch. The move area is a glowing
  see-through footprint with slow scan lines, so space shows through it. At the dead star the holo grid dips toward the
  hole like a funnel.
- **B "Living terrain"**: the grid is all but gone. It shows only right around the cursor (plus the move area and the
  planned move). Each kind of terrain becomes a thing in space:
  - nebula: soft gas clouds that drift
  - ion storm: dark heavy gas with short lightning strikes, each with a real flash of light on nearby ships and rocks
  - debris: dense clusters of rock, broken hull plates and girders (a few still glowing hot), and fine dust
  - dead star: the space round it bends, with a ring of lensing out to its pull range and slow ripples running inward

  Each terrain patch keeps only a faint edge so you can still tell which hexes count.
- **C "Cinematic + tactical toggle"**: by default A's grid and footprint on top of B's terrain. Press **Z** (or click
  **Grid** at the top right) for a full tactical grid, in the spirit of Sins 2's strategic view. That shows every hex
  outlined evenly, terrain as clear tinted hexes, the gas thinned out, and the dead star's pull range (5 hexes) and its
  damaging rim (3 hexes) as violet rings. Press Z again to go back.

## Try them in the game
In any battle, press **F8** to cycle Today, A, B, C (a line at the top names the look). In C, Z or the Grid button
toggles the tactical grid. The last look picked is kept for the next battle. These keys are for this trial only.

## Frame rate (job `board_b1_2722c0f`, 6 second orbit per look, screen sync off)
Every look stays far above the 40 fps bar on the 20-ship belt: the new looks run 1% lows of 5.8 to 6.0 ms (about
166 to 172 fps). Today's look shows a 26 ms 1% low there, but it was the first orbit of that battle, so it caught the
one-off start-up stutters. That number is not a real cost of today's look. On the nebula storm and dead star, every look
is within a millisecond of today. Numbers in `bench.json`.

## Calls I made (vetoable)
- Objective zones (exit edge, perimeter, relay) and the dead star's rim and pull range show as coloured edges in A, B
  and C instead of fills. The dead star's rings are new: today's board does not show them at all.
- Living nebula gas takes the setting's colours pulled halfway toward the nebula violet, so it matches the violet edge
  and the tactical fill.
- In A and B, each move hex's own outline is half as bright, and the one line round the whole move area carries the
  shape (F1's outline, unchanged).
- The dark floor F4 put under the board is off in A, B and C, and comes back at about half strength with C's tactical
  grid.
- The tactical toggle key is Z, because it was the free key nearest the camera keys. F8 cycles the looks. The Grid button
  sits at the top right. All of these are placeholders until F1 settles the battle HUD.

## Known gaps (for step 2, after the pick)
- Storm gas still reads a little pale and blue against dark skies, and a lightning flash caught mid-strike can blow out
  to a white blob (dead star, B, battle camera). The storm needs more contrast and a softer flash.
- At the default battle camera A's grid shows only near the ship that is up, so far terrain edges carry the board
  zoomed out. The fade distances are easy to tune.
- The wreck pieces in debris are simple plates and girders, which read fine at battle distance but plain up close.
- Shots were checked first in the cloud (software Vulkan), then on the PC.

## Files
- Code: `godot/world/board_look.gd` (the looks and the trial keys), `godot/world/world_living.gd` (B's gas, storm,
  debris and well), `godot/render/board.gd` (grid, footprint, terrain edges, tactical grid), `godot/world/world.gd`
  (switching), `godot/world/world_shots.gd --looks` (captures), `godot/world/tools/board_sheet.py` (these sheets).
