# voidsworn_S8 paint (issue 756): the Sunward paint stack, sandbox previews

Method: [the accepted build sheet](../README.md) (R254), `bake: stack` in `tools/recipe/ships/voidsworn_S8.json`,
`tools/blender/kits/voidsworn/stack.py` on the shared stack (no shared code changed), the direction
`contrib/muse/design/paint_direction_2026_11/sunward.md` (approved by Ryan Nov 14 2026). Geometry masks, own drawn CC0 trim and
decals, colours sampled from S8, never projected. Sheet geometry, mounts, insides and lamps unchanged.

One step lighter (issue 781; R256 "Lighten a step", R258 "the x1.85 column"): the stack paints the wear tones x1.85 in linear
(WEAR_STEP; edge wear, scuffs and the painted rivet heads) and raises the iron family under that new wear floor (IRON_STEP .60,
hue held), so the whole map rises about x1.85 and the worn edges still read lighter than the plates. Soot, liner, frost, the
light and the lift are unchanged. Hull medians (sRGB, the ember left out): fitted camera (52,49,48) before, (67,63,61) after,
the concept (52,47,47); battle camera, 34 degrees, (26,27,28) before, (34,35,37) after, Ryan's pick (34,34,36). The battle
median sits in the lower third of the sampled iron band (25 to 82), no longer on its dark floor. Helpers and the evidence
picture Ryan picked from: `contrib/opus/tools/issue781/`.

Pictures (Blender 5.3 CPU, game light, Sunward battle lift 1.45 read from look.gd, 2048 maps, 6 bake samples, 16 render samples; re-made for issue 781 with the medians on the concept picture):
[beside the S8 concept, fitted camera](voidsworn_S8_paint_concept.jpg),
[spires close and the port broadside](voidsworn_S8_paint_spires_broadside.jpg),
[battle camera, 34 degrees, range 170, long lens and true pixels](voidsworn_S8_paint_battle.jpg); evidence close-up:
[the forward deck and the port flank](voidsworn_S8_paint_close.jpg). In-game pictures await the
Board's PC run (Blender 4.5, GPU, 4096 bake).

Checks: [audits_sandbox.json](audits_sandbox.json) (emissive under 0.8 and no blue over green, frost coverage under 6 percent,
lift hue, battle median), [surface_check.json](surface_check.json) (0 room, 0 bare pixels), [density_sandbox.json](density_sandbox.json)
(0 paint and 0 mesh flags), [bake_sandbox.json](bake_sandbox.json) (bake times, maps, decals, the E11 budget comparison at the
same settings, the rivet pitch A/B). Helpers: `contrib/opus/tools/issue756/`.
