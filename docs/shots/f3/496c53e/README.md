# F3: effects you can see from the battle camera (496c53e, Nov 1 2026)

Ryan, after the first Godot playtest: "Effects looked very weak, especially at a distance and for smaller ships. You
almost couldn't tell anything was happening."

## Look at these first

1. **summary_small.jpg**: a frigate firing at a frigate, every weapon type, at the moment the shot lands. Columns:
   before and after from the normal battle camera, then before and after fully zoomed out (that view is enlarged so
   you can see it). This is where the playtest complaint was worst.
2. **summary_big.jpg**: the same for capital ships firing at capital ships.
3. **clip_20_ships.mp4**: 9 seconds of a 20-ship fight, before on top and after below. The plain white boxes are
   stand-ins the test fleet uses where a ship class has no model for that faction; they never appear in the game.
4. **calm_small.jpg**: the same shots with "reduce flashing" switched on, to show it still works.

## What changed, in plain words

- **Nothing shrinks to nothing any more.** Before, a frigate's shot was about 2 pixels wide from the battle camera
  and less than one pixel zoomed out, so it simply vanished. Now every shot, spark, flash and beam keeps a minimum
  size on screen, and it gets slightly dimmer as it grows, so far-off fire reads as a bright streak, not a blob.
- **Small ships' fire is drawn bigger.** A frigate's gun flashes and the hits on a frigate used to be a fifth the size
  of a capital ship's. Now they are at least three quarters of the standard size. (The guns and damage marks on the
  hull keep their real size.)
- **Hits last longer.** A hit now leaves a glow and a hot spot that cools over a second or so, and sparks live
  longer, so you can still see where it landed after the flash.
- **Shield hits show whose shield it is.** A hit lights the whole shield bubble faintly in that faction's colour
  (gold for the Sunward Crusade, blue lattice for the Hegemony, and so on) for half a second.
- **Kills land.** A ship's death leaves a slow glow where it died, and big hits and kills give the camera a quick
  small zoom "punch" (bigger for bigger ships; off when screen shake is off, halved with reduce flashing).
- **Shots hit what they reach.** A shot now always strikes the first part of the hull on its line.

## Numbers

- How much of the screen the effects light up, across all 19 weapon types (bright pixels compared with the frame
  before firing; visibility.json): from the battle camera about 4 times as much for frigates and 1.9 times for
  capital ships; zoomed out about 3 times for frigates and 3.5 times for capitals. Every weapon type is up; the
  smallest gain anywhere is 1.7 times.
- Frame rate with 20 ships, full effects, Ryan's PC (bench.json). The "1% low" is the frame rate in the slowest
  moments; the goal is to stay above 40:
  - same session, before and after F3 (r2): 1080p 60 to 64 before, 63 to 64 after; 4K 38 to 39 before, 39 after.
    F3 costs nothing measurable.
  - the final code (r3b, a quieter PC that run): 1080p 74 to 77, 4K 44.
- Flash safety: never more than 3 bright flashes in any second (the limit), and none at all with reduce flashing
  on. The effects test reports 0 errors.

## Open

- **The torpedo hitting the Eclipse Tomb-ark (summary_big.jpg, torpedo row) still shows no explosion**, before or
  after F3. A torpedo hitting a frigate does explode, and so do the other weapons hitting the Tomb-ark. The
  "shots hit what they reach" fix above was the first guess and did not cure it. A diagnostic run (frames round the
  impact from three angles, with and without the heaviest effects) is queued on the PC; the fix follows it.

## Calls Claude made (you can overrule any of them)

- The minimum sizes (on a 1080-line screen): hit flashes 14 pixels, bolts and fireball cores 12, tracers 2.6 by 14,
  sparks 2 by 4, beams 3.5 wide. Smoke and gas have no minimum, so distant fights don't turn into grey haze.
- Small ships' effects at least 0.75 (firing) and 0.85 (hits) of the standard size.
- The zoom punch: 1% for a frigate kill up to 3.4% for a capital, never more than 6% at once.
- A little more of the wide glow (bloom), so small bright effects far away get a soft halo.

## How these were made

Ryan's PC, lane A: run r1 (before, main 207759e), r2 (30d3db0, the same look, before and after benches in one
session), r3b (496c53e, this folder's "after"). The probe is `godot/fx/test/fx_range_probe.gd`; the clip is the
effects gallery's `--clip` mode; sheets made with Claude's compare and summary scripts.
