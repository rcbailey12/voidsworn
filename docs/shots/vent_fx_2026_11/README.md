# Vent gas before/after (issue 281, runs 6 and 7: baked flipbooks, size, and the stray-puff fix)

Ryan picked Cone B (a tight forward flash out of the barrel with sparks, FINDINGS R145), but the first build still
showed a pale beige ball, and the flat straight spark lines read as "Microsoft paint" (Ryan, Nov 9 09:20 CST). Run 5
rebuilt the muzzle and impact gas as baked Mantaflow flipbooks, the same recipe the ship deaths use (#137, R90). Ryan
said the flipbooks "definitely look better" (R150), so they stay, about 1.5x bigger (run 6).

- `vent_sheet_close.png`: before and after at the close crop, three moments (macro muzzle, macro hull hit, heavy hull hit).
- `vent_sheet_battle.png`: the same at the battle camera.
- `clips/before_close.mp4`, `clips/after_close.mp4`, `clips/before_battle.mp4`, `clips/after_battle.mp4`: short clips
  (about 3 s, 640x360, 12 fps).
- `clips.json`: frame counts and file sizes.

What changed across the runs:
- Two baked flipbook sets, `godot/fx/atlases/weapons/muzzle` and `godot/fx/atlases/weapons/impact`, baked on the PC
  Blender (Mantaflow smoke, Cycles GPU renders) with `tools/blender/vfx/bake_weapons.py` and packed with
  `tools/blender/vfx/pack_weapons.py` into the same colour, flow and thickness channels as the ship deaths, at the death
  small tier (1024). The muzzle is a fast forward jet of hot gas with a bright core that cools and thins (Cone B shape);
  the impact is a tight burst along the surface normal.
- `godot/fx/fx_weapons.gd` draws the baked gas for the macro muzzle, the macro hull hit and the heavy hull hit, shaded
  through the existing weapon shader (hot core path, full 16-frame life, weapon-tinted). The pre-Cone-B look is kept
  behind `fx.vent_look = "today"` for the before shots only; the game never sets it.
- Sparks are no longer flat straight lines: a few small, soft glowing points (additive) with short trails that slow down
  (drag) and fade hot white to orange, instead of the old straight spark streaks.
- Run 6 (R150): the baked gas reads better about 1.5x bigger (`WEAPON_GAS_SCALE`), for the muzzle gas and both hits.

What run 7 fixed:
- Stray puffs (R150, and the run 6 clips): small white smoke or thruster puffs appeared in empty space above the ship,
  attached to no hull. The cause was `godot/fx/fx_ship.gd` `_rcs()`: after a hit, the attitude thrusters drew braking gas
  at the corners of the hull's bounding box (`hull.c + Vector3(sx*L, sy*H, sz*W)`). On a hull that does not fill its box
  (the Eclipse cruiser: a disc with a tower) those corners are empty space.
- `_rcs` now starts every puff on the real plating: for each box corner it casts a ray from the corner (pushed a further
  L away from the hull centre) back toward it and uses the hit point, skipping the corner if the ray misses. The gas
  blows away from the plating, never into the hull.
- A guard (`fx.record_spawn` / `fx.stray_spawns`, wired from `_rcs`, `_vent` and `_weapon_gas`) fails a test when any
  weapon, vent or thruster gas spawns farther than 0.08 * hull length from its source ship's nearest hull surface
  sample. Muzzle and impact gas points sit off the barrel or along the hit normal, so those two use a wider 0.30 * hull
  length limit. The guard proves the bug (a STRAY_FAIL before the fix) and now reports stray none on every run.

The #232 flash test (`godot/bench/scene_gate.gd --flash`) still passes for the new look, and `fx/test/fx_smoke.gd`
passes with the stray guard on.

Captured with `godot/fx/test/vent_look_probe.gd` on the PC (real G2 hulls from `res://gen`, G4 world and look, fixed
effect clock at 640x360), then `godot/fx/test/vent_clip.py` built the sheets and clips.
