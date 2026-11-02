# Board look C, step 2: refining the look you picked (Nov 1, 2026)

You picked C ("Yep, C. We can refine from there."). This round works on the gaps the trial left, so the battle reads as
space and not as tiles. Nothing here changes the rules or which hexes a ship can move to. Move hexes stay blue.

All shots come from your PC (RTX 5080, Forward+, max quality), lane A jobs `board_bf_e991dc6` (before) and
`board_af5_10d76b3` (after). Before is look C exactly as the trial showed it (8cbf40c; the code was unchanged up to
e991dc6). After rebasing onto main the same code is commit 8cbc596 (the folder keeps the captured
name). Same battles, seeds and cameras before and after, now in **all ten settings**, not only the three from the trial.

## Start here
1. `all_before_after.jpg`: every setting at the normal battle camera, before on the left, after on the right.
2. `deadstar_ba.jpg`, `nebula_storm_ba.jpg`, `boneyard_graveyard_ba.jpg`: one setting each, before (top) and after
   (bottom), at the battle camera, zoomed out, and with the tactical grid up (Z).
3. `terrain_close.jpg`: the new gas, ion storm and wreckage seen close up.
4. The other `*_ba.jpg` files: the rest of the settings, same layout.

## What changed
- **Gas has no hex shapes any more.** Nebula and ion storm used to have a thin outline round each patch, and a lone gas
  hex looked like a hex-shaped puff. Now each patch is soft, ragged cloud. It still sits inside its own hexes and never
  spills out, but its edge wanders and frays. Several gas hexes side by side merge into one cloud.
- **Ion storms are dark, not pale blue.** The storm is now a dark violet mass, darker than the sky behind it, with a
  violet glow deep inside. Two causes of the old pale look are fixed:
  - the gas itself was lighter than the dark skies;
  - each lightning bolt's light also lit the scene's thin haze, which drew square, pale lavender blocks over the storm.
- **No more white lightning blobs.** Bolts are thinner, their glow is smaller and capped, and a strike lights the gas
  round it softly instead of washing it white.
- **Wreckage looks like wreckage.** The debris fields' plain plates and girders are replaced by four kinds of wreck, two
  shapes each, built fresh for every battle:
  - curved pieces of hull, torn at both ends, with frames and a stringer still on the inside;
  - snapped hull frames (ring ribs), bent where they broke;
  - broken truss spars with cross bracing;
  - gutted hull sections: a deck, a bulkhead with a doorway, one wall standing and the other torn down to stubs.

  They have panel seams and grime, and some torn edges still glow hot. Every piece tumbles slowly. Most are mid-size,
  and often one bigger piece per hex carries the shape from the battle camera.
- **The holo grid reaches further.** At the battle camera the grid now shows over most of the board around the ship that
  is up, instead of a few hexes. It reaches a little further again when you zoom out, then fades out completely. A faint
  scatter of corner ticks out to the board's edge was tried and dropped: over the sky it read as tiles again.
- **The tactical grid (Z) stays crisp and whole when zoomed out.** Grid lines never get thinner than about one pixel, so
  the far side of the board no longer breaks up into dashes. The tactical grid still shows every terrain hex as a tinted
  hex with its outline, the gas thinned so you can see through it.
- **Kept:** the dead star's pull-range warp ring and ripples, its 3 and 5 hex rings in the tactical grid, the objective
  zone edges, and the blue move area.

## Frame rate (6 second orbit per case, screen sync off)
The 20-ship belt is well above the 40 fps bar (25 ms or less for the slowest 1% of frames):

| | before, slowest 1% | after, slowest 1% | after, average |
|---|---|---|---|
| 20-ship belt, tactical grid up | 5.96 ms | 5.46 ms | 4.60 ms |
| 20-ship belt, look C | 22.96 ms | 20.19 ms | 4.65 ms |

The look C number for the 20-ship belt is the first orbit of that battle, so it catches the one-off start-up stutters
(about 50 fps at worst, still above 40). Every other setting stays at 4 to 7 ms for its slowest 1% (about 140 fps or
better), within about 2 ms of before. All numbers are in `bench_before.json` and `bench_after.json`.

## Calls I made (vetoable)
- In look C the hex outline is dropped for **all natural terrain**, not only gas: nebula, ion storm, debris and rock.
  The gas, wrecks and rocks show where they are, and the outline round debris read as a tile too. Objective zones and the
  dead star's rings keep their outlines. Press Z to see every terrain hex.
- The storm's colour is the same in every setting (dark violet with violet cores). Nebula gas still follows each
  setting's own colours, now a little dimmer so pale ones (the Glasswrights' skies) do not go cotton white.
- Wreck pieces are built from simple shapes in code for each battle (no new art files, nothing downloaded).

## Known gaps
- From the battle camera a small lone gas hex still reads as a soft puff rather than a sweeping cloud; patches of
  several hexes read best. Bigger, lower clouds would need more gas drawn and cost frame time.
- On the darkest skies (deep storm) the storm can only show through its glowing cores and lit side, so it reads as dusky
  violet rather than black.
- The grid's reach was judged from these fixed cameras; it is one number to tune after you play.

## Files
- `godot/world/world_living.gd`: the gas (its footprint and noise), the storm colours and lightning, the wreckage.
- `godot/render/board.gd`: the grid's reach and its one-pixel minimum, the natural terrain edges split from the rest.
- `godot/world/board_look.gd`: look C's settings (`gas_edge`).
- `godot/world/world_shots.gd`: new `--terrain` option (close shots of gas and debris).
- `godot/world/tools/board_sheet.py`: new `--ba` option (these before and after sheets).
