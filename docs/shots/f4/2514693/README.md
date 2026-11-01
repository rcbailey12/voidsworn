# F4 backdrops and asteroids: proof at 2514693 (Nov 1, 2026)

Captured on Ryan's PC (RTX 5080, Forward+, max quality, 1920x1080 window), lane A job `f4_r10_2514693`.
"Before" is main at 8c49560, before any F4 work (job `f4_before_8c49560`). The same eleven settings, the same seeds and
the same cameras in both, HUD hidden. (The blue move hexes and the arc lines are F1's board, not part of this stream.)

## What to look at first
1. `deadstar_before_after.jpg`: the dead star keeps its painting, with the lensed far side of the disc arching over the
   shadow and a thin ring under it; the board now has a dark floor under it and gas round it.
2. `frontier_belt_before_after.jpg`: a ringed gas giant with a lit side and a night side, moons, a full belt of rock
   round and below the board, nebula behind.
3. `boneyard_graveyard_before_after.jpg`: rock hexes carry real cratered rock, a moon lit from the side.
4. Any `*_low_and_close.jpg`: the rocks up close (craters, dark rock, rims and floors).

## What changed (since the before shots)
- **Sky**: a painted-looking nebula baked once per battle setting, pin-sharp stars, the galaxy's band; each region of the
  campaign has its own colours; the battles of one sector share a sky.
- **Planets and moons**: every setting has a planet beyond the board (gas giant, ice giant, terran, volcanic, barren or ice
  world) with atmosphere glow, clouds, night lights and rings, plus moons, none alike. New in this round: they are lit
  from the side, so you see a lit face, a soft edge into night and a dark side (before, they were lit full face and
  looked flat).
- **Asteroids**: real asteroid shapes (shards broken by flat faces, rubble piles, two-lobed contact pairs, slabs, ice
  shards) in five rock kinds (stone, iron, carbon, ice, crystal) picked by the region. Rock hexes carry one big rock with
  a few small ones; debris hexes a scatter of small ones; round and below the board a ring of rocks, a deep field, a belt
  stream on belt maps and a few mountain-sized rocks far out. All of them tumble slowly. New in this round: impact
  craters at two sizes (bowls, raised rims, darker floors), and a real dark side (rock no longer takes the full flat
  ambient light), so they read as rock in sunlight instead of grey-blue lumps.
- **Depth**: dust specks near the camera, gas wisps at middle distance that slide past the sky when the camera moves, and
  a dark floor under the board so nothing far below shows through the hexes as if it sat on them.
- **Dead star**: the accretion disc in two parts (a dense inner ring and see-through outer gas), lensing of the sky
  behind it, the bent far side of the disc over the shadow. New in this round: rocks beside the dead star are no longer
  sliced in half by the lens, a ship or rock in front of it hides the shadow as it should, and zooming in close no longer
  folds the disc into flat beige slabs.
- **Terrain reads as terrain**: rocks sit only on rock and debris hexes and look like solid rock; they never use a fill or
  an outline, so they cannot be taken for F1's blue move hexes.

## Frame rate (the 20-ship belt, the heaviest case)
- With the game's normal screen sync (60 fps): no frame slower than 16.8 ms in an 8 second orbit (job r7).
- With the sync off (this job, to see the room left): average 4.9 ms (about 200 fps), 1% low 22.1 ms (45 fps), so above
  the 40 fps bar even uncapped. Every other setting: 1% low 138 to 265 fps. Numbers in `bench.json`.

## Calls I made (vetoable)
- Planets and moons get their own light from the key light's side of the screen, about 70 degrees round, rather than the
  battle's key light exactly (which sits behind the camera and lit them flat). Nobody can compare angles with ships
  3,000 units away; the side stays the same.
- Rocks keep about half of the scene's flat ambient light (board blockers about two thirds), so they have a dark side.
- The dead-star lens stops bending as the camera comes within about 55 to 75 units of the hole (zoomed in on a ship
  beside it); up close the plain view is cleaner than a broken lens.
- Craters are drawn in the rock shader, not modelled, and fade out where they would be only a few pixels wide (no
  sparkle at a distance).

## Still to come / known gaps
- Round 11 (b4b41dd, queued as `f4_r11_b4b41dd`): rocks a little darker and warmer grey-brown (the board's rocks were
  lifted too much and read as pale blue plaster up close), and no rocks under the board where an orbited camera could see
  them through the hexes (the pale ghosts in some close shots). Checked in the cloud; the PC shots replace these when
  the job runs.
- Zoomed right in beside the dead star, a small stepped edge can show on the disc at the very corner of the screen.
- No downloads were needed: everything is made in code (Ryan's free-assets rule holds).
