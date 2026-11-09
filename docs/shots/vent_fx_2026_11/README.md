# Vent gas before/after (issue 281)

Cone B is the shipped weapon vent look (Ryan's pick, FINDINGS R145). The old look is kept only as the "before" capture,
set through `fx.vent_look = "today"`. The game never sets that value.

- `vent_sheet_close.png`: before and after at the close crop, three moments (macro muzzle, macro hull hit, heavy hull hit).
- `vent_sheet_battle.png`: the same at the battle camera.
- `clips/before_close.mp4`, `clips/after_close.mp4`, `clips/before_battle.mp4`, `clips/after_battle.mp4`: short clips
  (about 3 s, 640x360, 12 fps).
- `clips.json`: frame counts and file sizes.

Run 4 (Nov 9) shrank the effect to match Ryan's Cone B pick. The gas is a narrow jet: each step is about a third of the
old puff's width at the barrel and thins to nothing down the barrel, lives for about half as long and is much more
transparent. The muzzle flash and the hull-hit flash no longer bloom into a round pale ball: the muzzle is a compact
hot core at the barrel mouth that lets the shell tracer carry the brightness forward, and a hull hit is a tight hot core
on the plate with a short jet along the surface normal and a burst of sparks. The gas still cools toward the weapon
colour and darkens with age.

Captured with `godot/fx/test/vent_look_probe.gd` on the PC (real G2 hulls from `res://gen`, G4 world and look, fixed
effect clock at 640x360), then `godot/fx/test/vent_clip.py` built the sheets and clips.

The #232 flash test (`godot/bench/scene_gate.gd --flash`) passes for the new look: 0 WCAG flashes on both readings (mean
and brightest 1/6 block), largest single-frame luminance change 0.036, effect flashes at the budget cap of 3 in any
rolling second (5 counted, 1 refused over the run).
