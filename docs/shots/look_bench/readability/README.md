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
