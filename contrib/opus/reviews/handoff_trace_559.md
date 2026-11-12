# Issue 559: build to game trace (PARTIAL, work in progress)

Refs #559. Read-only. Main at e2ffefce. This is a partial push so a restart costs little; the full report with pictures
replaces it.

Code findings so far (file and line on main):

- Hard points: the game reads only `hp_eng_*` (godot/fx/fx_hull.gd:483). Guns fire from four sampled stations per side
  (fx_hull.gd:507-523, used by fx_weapons.gd:136), torpedo and lance shots from the bow point (fx_weapons.gd:138-140),
  hangar launches from the box centre (fx_weapons.gd:1150), boarding from its own side point (fx.gd:1146-1150), section
  damage from random surface samples (fx_ship.gd:811-824), braking jets from box fractions (render/ship_view.gd:1292-1315).
  Issue 370 covers the reader.
- The A4 `_damage.glb` and `_wreck.glb` are converted into gen/damage and gen/wreck (build_assets.gd:347-351) but no battle
  code loads them (only the campaign map loads the wreck, ui/campaign/map3d.gd:208). fx/API.md section 14 item 5 still says fx
  looks for them.
- Textures: the gen ship scenes do not embed base, ORM and emissive: they reference the editor's import of
  assets/ships/<CODE>/*.jpg (BC7 high quality, mips, project.godot importer_defaults). build_assets.gd's own compression
  (lines 133-145) only runs when no import exists.
- Guns are part of one merged mesh (A4: one mesh, one material; recipe: three surfaces in one mesh): nothing can turn.
