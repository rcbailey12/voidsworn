# F3: effects you can see from the battle camera (53c1b51, final, Nov 1 2026)

Ryan, after the first Godot playtest: "Effects looked very weak, especially at a distance and for smaller ships. You
almost couldn't tell anything was happening." This folder replaces docs/shots/f3/496c53e (kept for the record).

## Look at these first

1. **summary_small.jpg**: a frigate firing at a frigate, every weapon type plus a kill, at the moment it lands.
   Columns: before and after from the normal battle camera, then before and after fully zoomed out (that view is
   enlarged so you can see it). This is where the playtest complaint was worst.
2. **summary_big.jpg**: the same for capital ships.
3. **kill_small.jpg, kill_big.jpg**: a torpedo kill, before (top) and after (bottom). Columns here: just before the
   kill, the break-up, 0.6 s after, 2 s after (the labels printed on the sheet are the weapon ones; ignore them).
4. **clip_20_ships.mp4**: 9 seconds of a 20-ship fight, before on top and after below. The plain white boxes are
   stand-ins the test fleet uses where a ship class has no model for that faction; they never appear in the game.
5. **calm_small.jpg**: with "reduce flashing" on, to show it still works.

## What changed, in plain words

- **Nothing shrinks to nothing any more.** A frigate's shot used to be about 2 pixels wide from the battle camera and
  under one pixel zoomed out, so it vanished. Every shot, spark, flash and beam now keeps a minimum size on screen,
  dimming a little as it grows, so far-off fire reads as a bright streak, not a blob.
- **Small ships' fire is drawn bigger.** A frigate's gun flashes and the hits on a frigate are now at least three
  quarters of the standard size (they were a fifth of a capital's). Guns and damage marks keep their real size.
- **Hits last longer.** A hit leaves a glow and a hot spot that cools over a second or so; sparks live longer.
- **Shield hits show whose shield it is.** A hit lights the whole bubble faintly in that faction's colour.
- **Kills land.** A death leaves a glow where the ship was for a couple of seconds, and big hits and kills give the
  camera a quick small zoom punch (off when screen shake is off, halved with reduce flashing).
- **Hits land where you can see them.** Shots now favour the side of a ship facing the camera. Before, a torpedo on
  the Eclipse Tomb-ark could strike the underside of its ring and the whole explosion went off out of sight.

## Numbers

- How much of the screen the effects light up across all 19 weapon types (visibility.json): from the battle camera
  4 times as much for frigates and 1.8 times for capitals; zoomed out 3.1 times for frigates and 3.6 times for
  capitals. Every weapon is up; the smallest gain is 1.2 times (battle camera) and 1.6 times (zoomed out).
- Frame rate with 20 ships, full effects, Ryan's PC (bench.json). The "1% low" is the frame rate in the slowest
  moments; the goal is above 40. Before and after in one session (r2): 1080p 60 to 64 before, 63 to 64 after; 4K 38
  to 39 before, 39 after, so F3 costs nothing measurable. Final code: 1080p 74 to 75, 4K 44 to 45 (a quieter PC
  that run).
- Flash safety: never more than 3 bright flashes in any second, none with reduce flashing on; the effects test
  reports 0 errors.

## Calls Claude made (you can overrule any of them)

- Minimum sizes on a 1080-line screen: hit flashes 14 pixels, bolts and fireball cores 12, tracers 2.6 by 14,
  sparks 2 by 4, beams 3.5 wide. Smoke and gas have no minimum (no grey haze over distant fights).
- Small ships' effects at least 0.75 (firing) and 0.85 (hits) of standard size.
- The zoom punch: 1% for a frigate kill up to 3.4% for a capital, never more than 6% at once.
- The kill glow 1.8 times the blast size (3 times hid a capital's wreck pieces in a beige haze).
- A little more wide glow (bloom), so small bright effects far away get a soft halo.

## How these were made

Ryan's PC, lane A. Before: run r1 (main 207759e) and k1 for the kill sheets. After: r4b (sheets), r4 (clip,
benches, smoke test), both on 53c1b51. Diagnostics d1 and d2 found the hidden torpedo blast. Tools:
`godot/fx/test/fx_range_probe.gd` (sheets, kill sheet, trace mode), the gallery's `--clip`.
