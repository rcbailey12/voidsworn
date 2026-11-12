# Issue 559: what a finished ship loses between Blender and the game

Refs #559. Read-only trace by an Opus worker, Nov 12 2026. Game code traced: main e2ffefce (the captures ran on main 72ba72d, which
has no change under godot/ since e2ffefce). Ships: C19_51, the Pyre-Barge (the A4 chain, the finished worked example), and
C15s_23, the only recipe-built hull (recipe round 7, Ab7.blend, exported by stage 7 on the PC but not installed in the game build:
`opus209\out7\export\C15s_23`). Nothing in the game, the tools or the docs was changed.

## For Ryan: the five things that matter most

1. **The guns you build are not where the game fires from.** The barge has 7 real gun muzzles and the recipe cruiser 18; the game
   ignores all of them and fires from four guessed spots per side and from the nose tip. Issue 370 fixes this. The guns also
   cannot turn yet: every gun is welded into one ship mesh on the way out of Blender, so the turret job (issue 560) has to change
   the export as well as the game.
2. **The thruster puffs for braking and sliding start in empty space** on the barge (the white crosses on the sheet), because the
   game places them at fixed fractions of the ship's bounding box. Neither ship carries the braking points the contract asks for.
   Issue 370 plus a re-export.
3. **Damage ignores the built breach points.** The barge has 8 authored breach spots and the cruiser 6; the game picks random
   spots instead. The old pre-built damage and wreck pieces are converted at every build (21 MB for the barge alone) and never
   used in a battle. Insides and break lines are issue 557; breach spots are issue 370.
4. **The shield is a big egg around the ship's box**, about twice the hull's height, not a skin on the hull. Its colour arrives.
   Issue 371.
5. **What does arrive, arrives well.** Every triangle (256,468 on the barge, the same in Blender, the glb and the game), the paint
   (compressed without visible loss at the battle camera; slightly more saturated in the game), the windows and lamps, the
   engine plumes (exactly at the built engines) and the length (41.6 units, 2.4 hexes). The one paint loss: the recipe halves its
   4096 maps to 2048, which only shows when you zoom in close.

Pictures: `docs/shots/handoff_559/sheet.jpg` (Blender beside the game, losses marked), then `camera170_true_pixels.jpg`,
`guns_and_jets.jpg`, `hull_lights.jpg`, `shields.jpg`, `recipe_C15s_23.jpg`.

## How it was traced

- Code: build_assets.gd, hull_table.gd, ship_view.gd, look.gd, godot/fx/ (fx.gd, fx_hull.gd, fx_ship.gd, fx_weapons.gd,
  fx_breach.gd, fx_death.gd), the recipe export (tools/recipe/export7.py), the A4 chain README. Codex's sweep
  (contrib/codex/reviews/dropped_sweep_code.md) is not redone: its C1 and C2 rows are issue 557, C6 is issue 371, C7 is issue 370.
- Files read from Ryan's PC: the barge's game folder (`build\godot\assets\ships\C19_51`, its .import files), its 4096 set
  (`a4\godot_hi\C19_51`), the live `build\godot\gen` manifest and ship scenes, the recipe export and its logs (`opus209\out7`).
- Captures (PC, RTX 5080, GPU checked free first: 22:31 CST): a sparse clone of main's godot/ in `opus559\repo`, the two ships
  copied in, the game's own asset build, then `probe559.gd`: the real ShipView, look.gd and fx at the camera rig's home angle,
  radius 170 and 60, 1920x1080, with every authored hard point and every place the game really uses projected to the screen
  (`probe559.json`). Blender side (`blend559.py`): Cycles, the same camera, the game's key, fill and ambient (Godot energy times pi),
  AgX; the barge from its 4096 glb set (the A4 chain keeps no .blend), the cruiser from Ab7.blend itself. Sources are in
  `contrib/opus/reviews/handoff_559_probe/`.
- The probe exits with an access violation at quit, after all files are written (the known shutdown crash, ship_view.gd:41).

## The trace, worst first

| # | Property | Blender has | The glb has | The game shows | Kept or lost at | Picture | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Gun muzzles (item 5 and 7) | barge: 7 barrels; cruiser: 18 barrel tips registered by the kit | `hp_w<slot>_*` nodes with arc, weapon and slot extras (barge 7, cruiser 18) | shots leave four sampled stations per side, the top row or the nose tip; no authored muzzle is read | godot/fx/fx_hull.gd:507-547 (mount rows, `mounts_for`), fx_weapons.gd:134-140; only `hp_eng*` is read (fx_hull.gd:480-504) | sheet.jpg bottom left, guns_and_jets.jpg | LOST (issue 370) |
| 2 | Turning turrets (item 7) | separate gun parts | one mesh: A4 is one mesh and one material; the recipe joins every part into one mesh with three surfaces (export7.py; glb meshes list) | fixed; no aim code anywhere in render/ or fx/ | the export merges the guns before the game sees them | guns_and_jets.jpg | NOT BUILT YET (issue 560; the export must keep each turret as its own node) |
| 3 | Braking, side and turning jets (item 6, R195) | no thruster parts on either ship | no `hp_rcs_*` on either glb (barge A4; cruiser round 7 predates the contract, RECIPE.md "The round 7 game export has 28 hard points") | puffs at fixed box fractions (L x 0.36 to 0.5, half the box beam), 0.2 units up; on the barge most sit in empty space beside the hull | render/ship_view.gd:1292-1315 (`_couple_puffs`, `_retro_puffs`, `_aft_puffs`, `_side_puffs`), half_w from the box at :188-193 | sheet.jpg (white +), guns_and_jets.jpg top left | LOST (issue 370 reader; both ships need `hp_rcs`) |
| 4 | Breach anchors (item 5 and 8) | barge 8, cruiser 6, spread by the class and faction table | `hp_breach_*` with section, side and outward normal | wounds at random surface samples, three sections, picked once per ship | fx_ship.gd:811-824 (`_anchor` uses `hull.random_sample`, fx_hull.gd:577) | sheet.jpg bottom right, recipe_C15s_23.jpg | LOST (issue 370) |
| 5 | Old A4 damage and wreck pieces (item 8) | barge: torn-plate holes per anchor and per weapon, 8 wreck chunks with capped faces | `C19_51_damage.glb` (14.4 MB), `C19_51_wreck.glb` (7.1 MB), 17 `skin_*` patches in the ship | converted into gen/damage and gen/wreck at every asset build; no battle code loads them (only the campaign map loads the wreck, ui/campaign/map3d.gd:208); the skins show as plain hull | build_assets.gd:347-351 writes them; fx/API.md section 14 marks the swap retired by R80 but its item 5 still says fx looks for them | (code only) | LOST by design (R80); the recipe writes neither file (RECIPE.md "Not written yet" 1 and 2) |
| 6 | Insides and break lines (item 8) | cruiser: 22 interior objects (`p3_interior`), an inner skin modifier, authored break lines | removed: 127,188 triangles in Ab7.blend, 102,072 in the export | the game's own fracture and its fallback caps | export7.py:69 (interior filter), :82 (skin off); fx_death.gd `_break_lines` | (Codex's captures) | issue 557 |
| 7 | Core (item 5 and 8) | centre of mass | `hp_core` | unused; the game uses the box centre, 2.5 units from the authored core on the barge (1.3 on the cruiser), for launches, boarding, the shield and the death fallback | fx_weapons.gd:1150, fx.gd:1146-1150, fx_ship.gd:425, fx_death.gd:1425 | sheet.jpg (green ring, lime X) | LOST (issue 370) |
| 8 | Hangar bays (item 5) | barge has two hangars in data.js (`c_boss`, data.js:84, `hangar:2`) | no `hp_bay` in the A4 glb | wings launch from the box centre, 0.3 of the height up | fx_weapons.gd:1150 | (code only) | NOT BUILT YET on the barge; reader missing (issue 370) |
| 9 | Shield (item 9) | none (the contract's `<CODE>_shield.glb` is not written by any export, HARDPOINTS.md "The shield surface") | none | an ellipsoid at the box centre, radii box x 1.1 to 1.35 plus 0.3 to 0.5; barge 46 x 23 x 29 units round a hull 16 units tall; faction colour (corsair 0.85, 0.16, 0.1 x 2.2) and the patchy style arrive | fx_ship.gd:395-430, fx_hull.gd:591 | shields.jpg | shape LOST, colour ARRIVES (issue 371) |
| 10 | Texture size (item 2) | barge bake 4096; recipe hull and parts 4096 (Ab7.json `res`, `parts_res`) | barge: base and normal 4096, ORM and emissive 2048 (the folder README says all 2048); recipe: all 2048 (export7.py:41, `maps=2048`) | as the glb | export7.py:41; the A4 pack step | camera170_true_pixels.jpg | DEGRADED at close zoom only: at camera 170 the barge is 319 px long at 1080p and its paint has 1,604 texels per ship length (base) and 802 (ORM): no visible loss. At camera 60 the recipe's parts atlas has 660 texels per ship length over about 500 px at 1080p and 1,000 px at 4K: soft on parts at 1440p and 4K |
| 11 | Compression and mips (item 2) | PNG | JPEG (q92 recipe) | BC7 (format BPTC, 12 mip levels at 4096, 11 at 2048) for every map, from the editor's import (project.godot `importer_defaults`); build_assets' own compressor only runs when a map has no import | build_assets.gd:395-422 (`_glb_to_scene`, `_compress_material` skips imported CompressedTexture2D); probe559.json `materials` | camera170_true_pixels.jpg | ARRIVES. Fragile: the built ship scenes point at `res://assets/ships/<CODE>/*.jpg` through the import cache, so a copy of gen/ without that cache loads no ship at all (seen in the sandbox; Codex saw missing textures in a TEMP project) |
| 12 | Colour under the board's lights (item 2) | Cycles under the game's key, fill and ambient | | lightness within 1 to 4 percent (barge mean 99.7, 83.2, 78.3 in Blender, 98.7, 79.4, 72.1 in the game); saturation about 30 percent higher (0.12 to 0.155); hue 2.5 degrees warmer; the game adds the faction rim (0.15) and SSAO | look.gd:33-109 | sheet.jpg top row | ARRIVES (slightly more saturated and contrasty in the game) |
| 13 | Shape detail (item 1) | barge 256,468 triangles; cruiser 127,188 (102,072 without the insides) | barge 217,891 hull plus 38,577 in the skins; cruiser 102,072 | the same triangles, no decimation; smallest parts at camera 170: gun barrels about 6 px across, engine bells 13 to 20 px; shadows from the key at 4096, 4 splits, normal bias 2.0 | build_assets.gd:395-413 keeps the meshes as imported; look.gd:73-77 | camera170_true_pixels.jpg | ARRIVES |
| 14 | Engines and plumes (item 6) | barge 6 bells (two of them mid-ship on the welded hulls), cruiser 3 | `hp_eng_*`, -Z aft, with radius | plumes, cores and trails start exactly on the six and three engine points; ShipView's guessed glows are hidden | fx_hull.gd:480-504 (`_kit_nozzles`), fx_ship.gd:161-166, 220-273 | sheet.jpg (orange rings with cyan dots) | ARRIVES |
| 15 | Hull lights (item 3) | barge emissive map (windows, lamps, engine throats; strength 4); cruiser glow surface (emission 2.2 in the .blend) | barge `C19_51_emissive.jpg` 2048 with KHR emissive strength 4; cruiser glow surface strength 3.3, no light map (`lights` block empty) | windows and lamps arrive (36 lit spots on the barge at camera 170 against 20 in Blender, with bloom); the engine throats are covered by the fx cores; lights do not light the hull around them as they do in Cycles | fx_hull.gd:268-292 keeps the emission when the damage material takes over | hull_lights.jpg | ARRIVES (windows on recipe ships NOT BUILT YET) |
| 16 | Scale (item 4) | barge 1.041 long with the bow patch; cruiser 1.0 | same | 41.6 and 23.2 units: class length times SHIP_K 1.6 (hull_table.gd:26-28); 2.4 and 1.3 hexes across the flats (HEX_S 10); data.js `size` (1.22 for the barge) is used only for effect weight, never for drawing | ship_view.gd:63-71 and 172-193 (the fit uses every mesh, hull and kit together, so a kit part past the bow shrinks the hull) | camera170_true_pixels.jpg | ARRIVES (as ruled; the 1.33x stretch trap cannot happen here because the fit is to the whole ship) |
| 17 | Transparent surfaces (item 10) | Glasswright sails (alpha blend, godot/assets/ships/README.md "Ithar sails") | second surface `<CODE>_sail` | once a section is damaged, and on death, every surface gets the damage shader, which has no alpha: the sails would turn solid | fx_breach.gd:1716-1721, fx_death.gd:1471, fx_hull.gd:48-87 (EXTERIOR has no ALPHA) | not captured (INFERRED from code) | LOST (inferred; check on a Glasswright ship) |
| 18 | LODs (item 10) | recipe stage 6 builds lod0 to lod3 (Ab7_lods.json: 127k, 91k, 60k, 25k) | lod0 only | full detail at every distance; the runtime glTF path makes no LODs (the editor import's `generate_lods` setting is not used) | build_assets.gd:395-413 | (code only) | LOST (cost only, reported per R111; inferred from code) |
| 19 | Baked occlusion (item 2) | Cycles ignores the ORM's AO channel (Ab7_materials.json: BSDF links Base Color, Metallic, Roughness, Normal) | `occlusionTexture` set | the game multiplies the baked AO and adds SSAO, so creases read darker than in Blender | glTF import; look.gd:62-65 | sheet.jpg | DEGRADED (minor; a look call, not a loss) |
| 20 | Parts normal detail (item 2) | the recipe parts material has no normal map either (Ab7_materials.json) | none | none | | recipe_C15s_23.jpg | ARRIVES (nothing to lose) |

## Notes for the jobs already open

- **Issue 370 (attach points):** the probe's JSON gives screen positions of every authored point and every guessed point for
  both ships, ready as a before picture. The reader should also cover the braking jets in ship_view.gd (not only fx), the core
  (four call sites above) and the bays. Both test ships lack `hp_rcs` and `hp_board`; the barge lacks `hp_bay`.
- **Issue 560 (turrets):** today no export keeps a gun as its own node. The A4 chain merges kit parts into one mesh and the recipe's
  export joins every part into the parts surface. A turret needs its own node (pivot at the ring, rest aim along -Z) in the glb.
- **Issue 557 (insides):** confirmed from the other side: Ab7.blend has 22 interior objects and 25,116 triangles more than the
  export; the export's three surfaces are hull, parts and glow.
- **Issue 371 (shield):** the shield takes its size from the hull's bounding box, so on the welded barge it balloons well past
  the hull (the box includes the side hulls).

## Small fixes found on the way (documents only)

- godot/fx/API.md section 14 item 5 says fx looks for `skin_<n>` and `_damage.scn`; nothing does.
- godot/assets/ships/README.md says every map is 2048; the barge ships its base and normal at 4096.
- build_assets.gd's header says S3TC/RGTC and the README says BC7: both happen, but which one depends on whether the editor has
  imported the maps (see row 11).

## Not checked

- No death or break captures (Codex's sweep has them; issue 557).
- No Glasswright ship captured for row 17; no 4K capture for row 10 (the numbers are worked from the measured texel density).
- The barge has no .blend: its Blender side is the 4096 glb set the A4 bake wrote, rendered in Blender.
- The recipe cruiser was traced from its round 7 export in `opus209\out7`, installed only in this job's own copy of the game.
