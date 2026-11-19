# The Glasswright kit (`ithar`)

Issue 1183, R337 (Ryan, Nov 19 2026: restart CD5 from its concept) and R333 (shared, so every Glasswright gets it).
The look: opaque, reflective pearl ribbons (many and fine, each a bundle of strands with silver lines and a colour shift), sweeping and overlapping stern to bow, over a core of
glowing amber, violet and emerald stained-glass mosaic, each panel lit from behind (hot middle, dark edge). Ribbons cover under half. Nothing is see-through on an intact hull;
the interior shows only in the break-up. No wear.

| File | What it holds |
|---|---|
| `parts.py` | `Ribbon` (a ribbon laid over the ship's core surface: centre line, leaf width profile, lift and curl), `leaf` (width profiles), `mosaic_tint` (one colour per leaf panel, by weight, graded deep to hot with `TONES`), `cut_lens` (a rose-cut faceted stone for optics and drive lenses). Pure geometry. |
| `stack.py` | The paint stack: colours sampled from the CD5 concept (`sample_concept` repeats it), `LOOK` values for the bake and the game, and the Cycles materials `gw_pearl`, `gw_silver`, `gw_mosaic`, `gw_gem_*`, `gw_root_*`, `gw_drive*`, `gw_tip`, `gw_lance`. `AUTHORED_LOOK` marks the baked materials so godot/render/look.gd keeps their values (R329). |

How a ship uses it: the ship file gives a core surface `core(x, a)`, lays its ribbons with `Ribbon(...).mesh(core)` (pearl,
solidified) and `edge()` (silver lines), paints the core with `gw_mosaic` and writes `gw_tint` and `gw_glow` per vertex from
`mosaic_tint`. Worked example: tools/blender/build_sheets/ships/ithar_CD5.py (r5).
