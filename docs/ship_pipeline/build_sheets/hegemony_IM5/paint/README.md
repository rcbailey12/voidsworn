# hegemony_IM5 paint (issue 780): the Hegemony paint stack, sandbox previews

Method: [the build sheet](../README.md), `bake: stack` in `tools/recipe/ships/hegemony_IM5.json`,
`tools/blender/kits/hegemony/stack.py` on the shared stack (no shared code changed), the direction
`contrib/muse/design/paint_direction_2026_11/hegemony.md` (approved by Ryan Nov 14 2026). Geometry masks, own drawn CC0 trim and
decals, colours sampled from H10, never projected. Sheet geometry, mounts, insides and lamps unchanged.

Pictures (Blender 5.3 CPU, game light, Hegemony battle lift 0.4 read from look.gd, 2048 maps, 6 bake samples, 16 render samples):
[beside the IM5 concept, fitted camera](hegemony_IM5_paint_concept.jpg),
[close: a module band, the blue line, the nozzle row](hegemony_IM5_paint_close.jpg),
[battle camera, 34 degrees, range 170, long lens and true pixels](hegemony_IM5_paint_battle.jpg). In-game pictures await the
Board's PC run (Blender 4.5, GPU, 4096 bake).

Hull median against the concept (hull pixels, the blue light and the background left out): concept [52, 62, 79];
battle camera long lens [39, 49, 61], cam170 true pixels [52, 62, 74], fitted beauty
camera [49, 59, 71].

Checks: [audits_sandbox.json](audits_sandbox.json) (emissive under 0.8 and nothing warm, the #626d7d value cap on both atlases,
lift hue, the medians, the decal mirror check), [surface_check.json](surface_check.json) (0 room, 0 bare pixels),
[density_sandbox.json](density_sandbox.json) (0 paint flags; 2 mesh flags, the sheet's geometry),
[bake_sandbox.json](bake_sandbox.json) (bake times, maps, decals, the S8 budget comparison). Helpers: `contrib/opus/tools/issue780/`.
