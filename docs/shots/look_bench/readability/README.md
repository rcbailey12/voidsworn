# Battle camera readability (issue 362)

## The band, stated before any change (Nov 12 2026)

Measured per ship from the look bench fleet stills (camera 170, true pixel size, 1920x1080, the bench's own fleet setup),
with a mask of each hull's own pixels drawn by the readability probe
(contrib/opus/reviews/readability_362/pc/readability_probe.gd; the numbers by contrib/opus/reviews/readability_362/measure.py).
Level = luminance 0 to 255 (Rec. 709 weights on the sRGB values as drawn).

- **Lit side band: 100 to 190.** A ship's lit side is the mean level of its brightest quarter of hull pixels (75th to 98th
  percentile of the interior, so no half-sky pixel and no window speck counts). Why these ends: 100 clears the storm map's
  sky (64.8, the brightest backdrop on the bench, docs/shots/look_bench/skies.txt) by about one and a half times and the
  darkest sky (19.7) five times; 190 leaves room above the lit side for highlights and lines before the tonemapper flattens
  them toward white. Every faction ship (the 30 in render/hull_table.gd AI_HULLS) must sit inside it on the darkest sky,
  the brightest sky and the storm map. The three craft (2 to 4 pixels at this camera, drawn by render/squadron_craft.gd in
  battle) and the three objects are measured and listed, not held to the band.
- **Glasswright lines kept: at most 2 percent of a hull's pixels clipped** (any channel at 250 or more).
- **No hull lost on the darkest sky: at least 60 percent of a hull's outline pixels stand 12 or more levels above the sky
  just outside them** (the median of a ring 2 to 4 pixels out).

These are tuning values judged by eye (RULEBOOK 0.4); Ryan's eye on the sheet is the judge of "can tell every faction
apart".

Added after the first measurement (Nov 12), because the clip rule above did not catch the Glasswright burn-out: their hulls
sat at about 215, just under the clip level, and the white spread off the hull as glow. Two more numbers are reported (not
rules): **halo**, the mean level of the ring 2 to 10 pixels outside the hull minus the open sky's median (a burnt-out
glowing hull has one), and **lines**, the spread (standard deviation) of the hull's own levels (a flat white hull has none).

## Result (main b7cacdc4 before, branch ad627af7 after; Ryan's PC, RTX 5080, Godot 4.7.2, 1920x1080)

After is Ryan's R227 lifts (Nov 12): Eclipse 2.2 and Hullbreakers 1.25, measured in job F (the darkest sky and the storm,
one run; see contrib/opus/reviews/readability_362.md "Job F"). The brightest sky (frontier) was not re-run: its rows and
`fleet_frontier_before_after.jpg` are job E (e6bfef6c), where Eclipse is 3.2. Earlier after runs: ad7daade (4.5 and 1.5)
and e6bfef6c (3.2 and 1.25), rows in contrib/opus/reviews/readability_362/data/. No other faction changed.

Every one of the 30 faction ships is inside the band on all three skies (lit side 101 to 181); every one has at least 70
percent of its outline lit on the darkest sky (before: 55 percent at worst, the Eclipse Tomb-ark); no ship has more than
1.1 percent of its pixels clipped. Before, 18 of the 30 were outside the band on at least one sky (every Hegemony and Glasswright ship above it,
every Eclipse ship and four Sunward and Hullbreaker ships below it).

| Faction | Sky | Lit before | Lit after | Edge before (darkest) | Edge after (darkest) | Max clip after | Max halo before | Max halo after |
|---|---|---|---|---|---|---|---|---|
| Hegemony Navy | world | 192 to 211 | 156 to 180 | 0.95 | 0.91 | 0.2% | 6 | 7 |
| Hegemony Navy | frontier | 192 to 211 | 156 to 180 | - | - | 0.2% | 5 | 5 |
| Hegemony Navy | storm | 192 to 211 | 156 to 180 | - | - | 0.0% | 20 | 19 |
| Sunward Crusade | world | 82 to 118 | 105 to 156 | 0.70 | 0.86 | 0.2% | 7 | 7 |
| Sunward Crusade | frontier | 81 to 118 | 105 to 157 | - | - | 0.2% | 4 | 4 |
| Sunward Crusade | storm | 82 to 119 | 105 to 156 | - | - | 0.2% | 5 | 5 |
| Ashfall Hullbreakers | world | 89 to 115 | 115 to 145 | 0.79 | 0.88 | 0.0% | 4 | 4 |
| Ashfall Hullbreakers | frontier | 89 to 115 | 115 to 144 | - | - | 0.0% | 7 | 7 |
| Ashfall Hullbreakers | storm | 90 to 115 | 115 to 145 | - | - | 0.0% | 11 | 11 |
| Chorus | world | 128 to 155 | 134 to 157 | 0.96 | 0.96 | 0.2% | 3 | 11 |
| Chorus | frontier | 128 to 155 | 134 to 157 | - | - | 0.2% | 4 | 8 |
| Chorus | storm | 128 to 155 | 133 to 157 | - | - | 0.2% | 11 | 11 |
| Glasswrights | world | 206 to 216 | 160 to 180 | 1.00 | 1.00 | 1.1% | 36 | 17 |
| Glasswrights | frontier | 206 to 216 | 160 to 181 | - | - | 1.1% | 24 | 11 |
| Glasswrights | storm | 204 to 216 | 159 to 177 | - | - | 0.9% | 23 | 16 |
| Eclipse | world | 63 to 74 | 101 to 112 | 0.55 | 0.70 | 0.3% | -1 | -1 |
| Eclipse | frontier | 63 to 74 | 108 to 122 (at 3.2) | - | - | 0.3% | -5 | -5 |
| Eclipse | storm | 70 to 119 | 101 to 143 | - | - | 0.3% | 79 | 79 |

Every ship, every sky, before and after: `table.md`. The Eclipse storm halo (79) is the bright storm cloud behind the
frigate's cell, the same before and after, not glow from the hull. Glasswright lines: 10 to 20 before, 18 to 26 after.

## The pictures (camera 170 unless named, 1 to 1 pixels; only eclipse_camera60_r227.jpg is closer, at camera 60)

| File | What |
|---|---|
| `fleet_world_before_after.jpg` | the bench fleet sheet on the darkest sky, before and after side by side, numbers under each pair |
| `fleet_frontier_before_after.jpg` | the same, brightest sky (job E: Eclipse 3.2) |
| `fleet_storm_before_after.jpg` | the same, storm map |
| `phone_world_1.jpg` to `_2.jpg` | for Ryan's phone (1280 wide): every ship but the capitals, before on the left half, after on the right, darkest sky |
| `phone_world_3.jpg` | the same for the beacon (it did not fit on page 2) |
| `phone_world_4.jpg`, `_5.jpg` | the six capitals, before, then after, in the same places |
| `eclipse_camera60_r227.jpg` | the one close picture: the Eclipse ships at camera 60, true pixels, main, lift 3.2, 2.2 (the pick) and 1.8 (out of band) side by side |
| `moments_worst_off_hull.jpg` | the 16 bench moment cells that changed most outside the hulls: before, after, difference (hull mask in blue) |

## How it was made

contrib/opus/reviews/readability_362.md (the report): the probe, the measure, the calibration runs, the moments check and
the scene gate. Remake: the PC run files in contrib/opus/reviews/readability_362/pc/, then measure.py and sheets.py.
