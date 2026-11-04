# Space deaths, issue 137

Read [grammar.md](grammar.md) first. The D1 image and the before/after evidence live in `Downloads/voidsworn_test/board/issue-137/shots`.

Double-click `bake_death.bat` to reproduce the three Mantaflow sims and Cycles OPTIX renders on the PC. It uses the installed Blender and ComfyUI Python, with the timeout runner. Caches go to `%TEMP%`. Mantaflow itself is CPU code; Cycles uses the RTX 5080. No paid tools or downloads are needed.

`pack_death.py` produces small (1024), cruiser (1536) and capital (2048) 4x4 atlases from the same three baked simulations, preserving coherent motion between sizes. Colour, bidirectional image flow and optical thickness are separate textures. Flow is measured with a coarse-to-fine Horn-Schunck solver on the rendered density silhouette. It is not an arbitrary scrolling noise field. Thickness comes from the rendered transmittance, and the green channel carries the baked key-light response. The runtime shades a coarse thickness normal with the battle sun and violet ambient. A soft depth fade handles hull intersections; Compatibility omits depth sampling.

Motion RG stores forward displacement and BA stores backward displacement, in cell UV units with a +/-0.125 range. These data textures use lossless import with no alpha repair and no mipmaps. The shader samples both frames along their measured vectors. All 16 frames share a common camera and domain, so cells do not change scale. The final frames fade out rather than loop. Low, high and max use the same baked flash.

Double-click `check_death.bat` for headless destruction, damage-surface and timeline checks. It accepts an optional isolated Godot project path. Import textures with the editor first on a fresh checkout. Logs stay in `%TEMP%/voidsworn-137-checks`.

`godot/fx/test/death_leap_probe.gd` captures real Sunward Crusade cruisers, battleships and frigates at r=170 and at close zoom, at the same exposure. Set `DEATH_OUT` to a capture folder and run it through `tools/pc/tmo.bat`, with `--fixed-fps 60`. Optional `DEATH_CLASS`, `DEATH_ZOOM` and `DEATH_QUALITY` select a tier check. `DEATH_PROFILE=1` instead renders 20 real ships at 3840x2160, 4x MSAA. Keep `--fixed-fps 60` for this run too: Godot disables real-time synchronization, so wall frame times are uncapped while physics and FX advance together. It measures baseline and capital-death wall frame times, including the lethal call. Image readback happens after timing. This is an isolated ship/effect workload, not a full battle with weapons and terrain.

The runtime owns geometry through the existing worker slicer. Capitals prepare three or four sealed sections, then release them at 0.8, 1.2 and 1.6 s as appropriate. Meshes and collider shapes are prepared before death. Every released section has its own 14 s cooling clock. Physics and kinematic tiers retain velocity without damping. The existing three-flash limiter owns all bright flashes and their lights. Chorus rupture and explicit cold-hulk deaths retain their separate outcomes.

Scope stops at D5. Weapon D6, nebula N steps and planet P steps belong to separate jobs. Persistent R80 damage stages and flash-budget constants are unchanged.

The existing weapon-only volume helper moved from `fx_death.gd` to `fx_weapons.gd` without changing its rendering. This keeps raymarching out of the death module without taking on D6.
