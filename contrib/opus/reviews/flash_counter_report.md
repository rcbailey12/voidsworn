# The flash counter counts by area (issue 504)

Opus 5.5 worker, Nov 11 2026. Branch opus/issue-504 (merged with main after issue 484 landed).

![Capital death with a torpedo landing on it: main above, this branch below](../../../docs/shots/look_bench/flash_counter/capital_torpedo_before_after.jpg)

## What Ryan will see

When several things blow up in the same second, each keeps its full flash and its light, as long as they are not all
piled into one small patch of screen. On main only three large flashes a second got through anywhere on screen; the
rest became slow orange glows with no light. In the bench picture (a super-dreadnought dying with a torpedo landing at
1.78 s) main had already booked the torpedo, so the dying ship's own 1.55 s chain blast was the one turned soft: it
still glows orange at 1.75 s with no light on the hull. On the branch it flashes white-hot with its light and is over
by 1.75 s; the torpedo looks the same in both. The bigger gain is in crowded moments: in the headless worst second (two
deaths and a torpedo) main turned 8 flashes soft, the branch none. Reduce flashing is unchanged, frame for frame.

## The guideline, word for word

From W3C, Understanding SC 2.3.1 Three Flashes or Below Threshold
(https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html), the sentences built from:

- "there are no more than three general flashes and / or no more than three red flashes within any one-second period"
- "the combined area of flashes occurring concurrently occupies no more than a total of .006 steradians within any 10
  degree visual field on the screen (25% of any 10 degree visual field on the screen) at typical viewing distance"
- "A general flash is defined as a pair of opposing changes in relative luminance of 10% or more of the maximum relative
  luminance (1.0) where the relative luminance of the darker image is below 0.80"
- "The combined area of flashes occurring concurrently and contiguously means the total area that is actually flashing
  at the same time." The page's calculation note: "It is calculated by adding up the contiguous area that is flashing
  simultaneously within any 10 degree angle of view."
- Note 1: "using a 341 x 256 pixel rectangle anywhere on the displayed screen area when the content is viewed at 1024 x
  768 pixels will provide a good estimate of a 10 degree visual field for standard screen sizes and viewing distances
  (e.g., 15-17 inch screen at 22-26 inches)"
- "The specification cannot account for the actual viewing distance that a person chooses."

## How the counter decides (plain words)

1. Every bright, short flash is treated as a round patch as wide as it is drawn on screen, never smaller.
2. All bright flashes that are on screen at the same moment are added up inside every 10 degree box that could hold
   them. Small flashes close together add up; small flashes far apart do not.
3. Only when some box holds more flash than the guideline allows (0.006 steradians, or a quarter of W3C's own
   341 by 256 estimate of the field, whichever is smaller) is it a "general flash". Those still count against
   the same limit as before: at most three in any rolling second. A fourth is drawn soft.
4. A flash within 0.12 s of a counted one is part of it (as before).

## Assumptions (all in one place: godot/fx/fx.gd, the block under FLASH_KINDS)

- The screen: 32 inch, 16:9, seen from 24 inches (`flash_screen_in`, `flash_aspect`, `flash_view_in`; setup options
  `screen_in` and `view_in`). The cautious end of a desk set-up: 10 degrees is 26.8 percent of the screen height, 289 px
  at 1080 lines (rounded down). On a 27 inch screen everything is bigger (more room); a closer seat or a bigger screen
  would need these changed.
- The limit (`flash_limit_px2`, Board review of PR 512): the smaller of two readings of the guideline, both from the
  same screen and distance. (a) Its own number, 0.006 steradians: one pixel at the screen centre spans pixel pitch over
  distance = (15.69 in / 1080) / 24 in = 0.000605 rad, so 0.006 sr = 0.006 / 0.000605^2 = 16,376 px2. (b) A quarter of
  its own rectangle estimate of the field (341 by 256 at 1024 x 768, so 10 degrees wide and 256/341 of that tall):
  289 x 216 / 4 = 15,606 px2. The stricter one, 15,606 px2 at 1080 lines (a disc about 141 px across), is used. The
  first build took a quarter of a 10 by 10 degree square, 20,880 px2, which was 27 to 34 percent too generous; that is
  gone, and no constant meaning "a quarter of a square" is left.
- Where flash is gathered: a 10 by 10 degree square (wider than the 10 by 7.5 rectangle and than the 10 degree circle),
  tested one lattice step wider still. A bigger window only gathers more flash area against the same limit, the safe
  direction.
- The game fills the screen's height. In a smaller window the real 10 degree box is bigger, so the counter is stricter
  than it needs to be there.
- Lit area: a disc as wide as the sprite is drawn, including its pixel floor, rounded up to whole pixels. The baked
  flashes' sizes are their widest lit extent including bloom, and the zoomed-in world size is also taken when bigger.
- Rounding: the 10 degree box is tested on a lattice a quarter of its side apart, each tested box one lattice step
  wider than the real one, so any real box lies inside a tested one. Each flash adds the smaller of its disc area and its
  bounding square's overlap with the box, which is never less than the real overlap. Areas are rounded up, never down.
- "At the same moment": two flashes overlap when their bright lives overlap (at least 0.12 s each).
- Unchanged from main, and stated so the Board can see them: only sprites at intensity 4 or more and 0.6 s or shorter
  are flash candidates (FLASH_I, FLASH_KINDS); a soft lift (kind 18 or a soft flipbook) is not counted; a flash whose
  place is unknown (vent ignition, death core, a light of 8 or more) still counts on its own, as on main; with no camera
  every bright flash counts, as on main; offscreen flashes still count (the box may sit anywhere).

## A refused flash

It keeps its size, colour and smoke as before (the soft sprite and the soft flipbook were already same size and colour)
and now keeps its light: the light rises over at least 0.1 s (new light shape 3), at most 7.2 (under the 8 that counts),
instead of being dropped. A refused capital core also keeps its light this way. The soft brightness of the sprite and
the flipbook is unchanged from main, on purpose: it is the same soft look reduce flashing uses, already accepted as not
a flash.

## Reduce flashing is unchanged

- Every new path returns at once under reduce flashing, before booking anything (flash_at, flash_ok); light() keeps its
  calm branch untouched; the death core's light is still skipped under it.
- A trace of everything the effects system makes in the worst-second staging under reduce flashing (every event light's
  time, life, peak and shape each frame, every flipbook's lifetime, intensity, soft switch and size, the particle count):
  identical on main and the branch, hash f27cbd29acad9e3516f9d2850aac572a on both: twice each against main 01e5560, and
  again after the limit fix against main 6ad59a6. The probe is
  contrib/opus/compute/flash504_calm_trace.gd.
- The calm checks still pass: destruction_staging_check (zero counted in calm at every beat), damage_surface_check,
  fx_smoke (reduce flashing counts nothing), flash_area_check (calm: nothing counted, nothing booked).
- The look bench's reduce-flashing row on the RTX 5080: the five frames of main 01e5560 and of the branch fb27ff8 match
  (four bit for bit, the last within 3 of 255 on any pixel). The bench is repeatable: main's frames from two separate
  runs are bit-identical. Picture: docs/shots/look_bench/flash_counter/capital_torpedo_reduce_flashing.jpg.

## The worst-case check (godot/fx/test/flash_area_check.gd, new, in CI and in check_destruction.bat)

Box ships at the battle camera, 1920x1080. "together": a capital death, a cruiser death 0.6 s later beside it and a
torpedo on the capital at 1.75 s, all in one 10 degree box. "spread": the same across the screen. "salvo": five waves of
sixteen heavy hits 0.3 s apart in one box. Each also under reduce flashing. Every flash drawn bright and uncounted is
re-measured by brute force (exact discs on a 4 px raster, a 10 by 10 degree square slid over every 4 px position,
against the same 15,606 px2 limit). Numbers below are after the limit fix and the latest main merge.

| staging | counted | refused | worst rolling second | uncounted over the limit | counter below brute force |
|---|---|---|---|---|---|
| together | 10 | 0 | 3 | 0 | 0 |
| spread | 6 | 0 | 2 | 0 | 0 |
| salvo | 4 | 7 | 3 | 0 | 0 |
| any, calm | 0 | 0 | 0 | 0 | 0 |

The same "together" staging on main counts 14 and refuses 8, including the torpedo. In the salvo, each wave of sixteen
small hits passes the limit only together, is counted, and the fourth wave in a second is partly drawn soft.

## The salvo test of issue 232 (scene_gate --flash, the real battle scene, RTX 5080)

Per-frame screen luminance with WCAG counting. Main 96099ce7 and the branch (before the 484 merge): both PASS, zero
luminance flash pairs per second (whole screen and per block), counted effect flashes 14 and 11, refused 10 and 10,
largest frame-to-frame luminance change 0.0060 and 0.0044 (the threshold is 0.10). Evidence on the PC under
Downloads\voidsworn_test\opus504\r1_*\salvo.

## The look bench (Ryan's PC, Downloads\voidsworn_test\opus504)

Two rows at the battle camera (a Hegemony super-dreadnought dies, a torpedo from the attacker lands on it 1.78 s in;
the same under reduce flashing), main against the branch, 0 warnings. Round 3 (main 01e5560, branch fb27ff8) is the one
shown; runs in opus504\lb\runs\main_r3 and after_r3. The bench can now land a second volley during an event (row
field "also" in godot/bench/look_bench.gd).

After the limit fix no new bench round was run: in this row the chain blasts (84 px, about 5,500 px2) stay under the
limit alone and do not overlap the torpedo in time, and the torpedo (185 px on a capital) and the core were already
counted, so the frames shown cannot change.

## Frame cost

- The 20-death fleet probe, RTX 5080, 1080p, two runs each: main avg 1.56 and 1.56 ms, p99 3.04 and 2.91 ms; branch avg
  1.29 and 1.30 ms, p99 2.56 and 2.63 ms (no worse; the gap is run noise). The counter itself: 3.5 and 3.7 ms over 660
  frames, about 6 microseconds a frame.
- flash_area_check on the PC: 2 to 6 microseconds a frame on average; the worst single frame is the sixteen-hit salvo
  wave, 0.73 ms on the PC (1.1 ms in the CPU-only sandbox). A cheap exit skips the box search whenever all flashes
  together are under the limit.

## Tests changed on purpose (destruction_staging_check.gd)

The staging of death beats is now checked on bright-flash requests (fx.flash_area_log); the safety checks stay on the
counted flashes (fx.flash_log). Kept as they were: zero counted in calm mode at every beat, at most three counted in any
rolling second. Changed: the vent ignition before the split (was "exactly one counted", now "one request"), chain blasts
during the tell (was "two or more counted"), the core flash 0.28 s after the break (found among requests), the vent,
chain and core sequence (was "three or more counted"), the small hull's vent and core (was "exactly two counted", now
"two or more requests"), secondaries after the core (was "two or more counted"), "normal keeps its core" (was "one or
more counted"). Lines (branch): 95-97 (logging on), 106, 115, 131, 137-138, 141, 144, 160-161, 165. fx_smoke.gd and
death_leap_check.gd are unchanged (their rolling maximum still holds).

## Every line touched in fx.gd, fx_death.gd and fx_weapons.gd (branch numbering)

- fx.gd: 29-59 (assumptions and limit block, new), 216-217 (setup options), 394-395 and 399-404 (spr: flash_at, then
  _emit_spr), 468-472 and 475-487 (flash_ok takes an optional place; its old body is now _flash_count), 527-677
  (flash_at, flash_limit_px2 and helpers, new), 684-687 (pop books once), 699-702, 705 and 708-715 (light: a refused
  flash's light kept, soft), 758 (light shape 3).
- fx_death.gd, three lines: 1748 (_blast: flash_at), 2285 (_core_flash: flash_ok with its place), 2295 (the core's light
  also when refused, never under reduce flashing).
- fx_weapons.gd, two lines: 418 (_burst), 1079 (_staged_hit). No hit, muzzle or hull light size was changed.
- Also: fx/API.md (one new bullet in section 8), godot/bench/look_bench.gd (a row may land a second volley during an
  event, "also"), godot/tools/ci/godot_checks.txt and fx/test/check_destruction.bat (the new check).

## Red flashes, and the Hullbreaker engine corona

No flash sprite or light is saturated red (the reddest is the hit orange, red share 0.53; the rule needs 0.8). The one
saturated red that moves is the Hullbreakers' engine corona (faction accent 1.0, 0.1, 0.05; fx_ship.gd:239, sprite kind
4; the comment there saying no accent is in use is out of date: four factions set one). Worked through:

- How it is drawn (fx_shaders.gd, kind 4): colour = (accent x exp(-4 r^2) + (1.0, 0.95, 0.8) x 1.6 x exp(-14 r^2)) x 0.9
  x fl, where fl = 0.85 + 0.15 x noise at about 31 Hz, a different phase per engine (seeded), and 0.9 to 1.0 slow
  breathing under reduce flashing. So the swing is 15 percent of the corona's own brightness, in both directions.
- Size: the corona is 5 nozzle radii across, and a nozzle radius is at most 0.3 of the hull's smaller dimension
  (fx_hull.gd:473, 0.12 to 0.3). At the battle camera a cruiser hull is about 30 px across, so a corona is at most about
  45 px across (about 1,600 px2), a capital's perhaps twice that.
- Red flash: only the outer ring is saturated red (at half radius the red share is 0.75, from about 0.7 radius out it
  passes 0.8). Its brightest linear red there is about 0.14, relative luminance under 0.03; 15 percent of that is about
  0.005, against the 0.10 a flash needs. Even a pure full red (1, 0, 0) has relative luminance 0.2126, so a 15 percent
  swing of it is 0.032. And the flicker changes brightness, not colour, so it is not a change of saturated red either.
  Ten Hullbreakers in one field: at most about 40 engines x 1,600 px2 = 64,000 px2 of corona, all of it far below the
  luminance step. A red flash from the corona is ruled out, at any number of ships.
- General flash: the corona's white core is not red, but it does flicker. Where its linear brightness passes about
  0.67 (the inner quarter of the corona's diameter) a 15 percent swing can pass 0.10 of maximum before tone mapping.
  At the battle camera that core is at most about 11 px across (about 95 px2, perhaps 380 px2 on a capital): 40 engines
  give at most about 15,000 px2 even if all were in one field and all flickered in step, which they do not (each has its
  own phase). So it stays under the 15,606 px2 limit at the battle camera, narrowly in that worst stacking. At the close
  cameras (60 and 26) it is 3 to 6 times wider, and I cannot rule out a few capitals' cores together passing the limit
  there. This is old behaviour, on main too, and applies to every faction's engine cores, not only the Hullbreakers'.
- Smallest fix (not built here): narrow the fast engine flicker from 0.85 to 1.0 down to 0.95 to 1.0 for the white core
  (one constant in the kind 4 shader line), which keeps the engines alive and puts the core's swing under a third of the
  step at any camera. Desaturating the red is not needed.

## What I am unsure of

- The soft versions are judged "not a flash" by brightness alone, as on main; nothing measures their real luminance
  step at Ryan's screen. The salvo test's frame luminance found no flash pairs on either branch, but its camera is far.
- Light patches on hulls are not given an area: a light under 8 is free, one of 8 or more counts on its own (as on main).
- In the bench picture the difference is small at the battle camera (a refused chain blast on main is a slower orange
  glow, which reads about as big). Which flash main refused there is worked out from main's counter rules (the torpedo
  was booked at launch, 1.78 s ahead, so the 1.55 s blast made four in that torpedo's second), not logged on the PC.
- Round 2 of the bench compared main after the issue 484 merge with the branch before it, so it was rerun once (round 3)
  after merging main into the branch: three bench runs in all, the third a corrective rerun of the second.
- 32 inch at 24 inches is the default; Ryan's two monitors are of unrecorded size. If either is bigger than 32 inch or
  he sits closer, the numbers in the assumptions block should change.
