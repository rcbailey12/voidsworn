# Issue 569: Glasswright sails stay glass when damaged

One damaged Glasswright ship at camera 60, before and after the fix.

- `sails_before.png`: main's damage shader. The sail membrane is solid; it hides the checker behind it.
- `sails_after.png`: this branch. The damage shader carries the sail's alpha, so the checker shows through.

Both pictures: Ithar Aurora-class cruiser (`I15_11`, faction `ithar`), hurt to stage 4 in
all three sections, camera 60 (the game camera rig at `r=60`, 1280 by 720). A teal and white
checker stands behind the ship so a see-through surface is plain to see.

The probe is `godot/fx/test/damage_alpha_probe.gd`. Run it with `SAIL_ALPHA_OUT` set to an
output folder and `SAIL_ALPHA_LABEL` set to `before` or `after`; it needs `godot/gen` (the
real ship files) and a window. The log prints the real sail surface as
`base=I15_11_sail t=4 a=0.55`: mode 4 is `TRANSPARENCY_ALPHA_DEPTH_PRE_PASS`, which is how
Godot imports a glTF `alphaMode: BLEND` material. The same line prints `writes_alpha=false`
for the before run and `writes_alpha=true` for the after run.
