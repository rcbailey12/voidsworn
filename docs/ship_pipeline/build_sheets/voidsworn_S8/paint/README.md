# voidsworn_S8 paint (issue 756): the Sunward paint stack, sandbox previews

Method: [the accepted build sheet](../README.md) (R254), `bake: stack` in `tools/recipe/ships/voidsworn_S8.json`,
`tools/blender/kits/voidsworn/stack.py` on the shared stack (no shared code changed), the direction
`contrib/muse/design/paint_direction_2026_11/sunward.md` (approved by Ryan Nov 14 2026). Geometry masks, own drawn CC0 trim and
decals, colours sampled from S8, never projected. Sheet geometry, mounts, insides and lamps unchanged.

Pictures (Blender 5.3 CPU, game light, Sunward battle lift 1.45 read from look.gd, 2048 maps, 6 bake samples, 16 render samples):
[beside the S8 concept, fitted camera](voidsworn_S8_paint_concept.jpg),
[spires close and the port broadside](voidsworn_S8_paint_spires_broadside.jpg),
[battle camera, 34 degrees, range 170, long lens and true pixels](voidsworn_S8_paint_battle.jpg); evidence close-up:
[the forward deck and the port flank](voidsworn_S8_paint_close.jpg). In-game pictures await the
Board's PC run (Blender 4.5, GPU, 4096 bake).

Checks: [audits_sandbox.json](audits_sandbox.json) (emissive under 0.8 and no blue over green, frost coverage under 6 percent,
lift hue, battle median), [surface_check.json](surface_check.json) (0 room, 0 bare pixels), [density_sandbox.json](density_sandbox.json)
(0 paint and 0 mesh flags), [bake_sandbox.json](bake_sandbox.json) (bake times, maps, decals, the E11 budget comparison at the
same settings, the rivet pitch A/B). Helpers: `contrib/opus/tools/issue756/`.
