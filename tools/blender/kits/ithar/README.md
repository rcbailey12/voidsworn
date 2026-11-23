# The Glasswright kit (`ithar`)

Issue 1183, R337 (Ryan, Nov 19 2026: restart CD5 from its concept) and R333 (shared, so every Glasswright gets it).
The look: opaque, reflective pearl ribbons (many and fine, each a bundle of strands with silver lines and a colour shift), sweeping and overlapping stern to bow, over a core of
glowing amber, violet and emerald stained-glass mosaic, each panel lit from behind (hot middle, dark edge). The pearl is the shell: the glass shows only in the seams and openings between ribbons, at most `stack.MOSAIC_MAX` (0.42) bare glass from above or the battle camera, checked by `hull.mosaic_share` in every review (R431, Ryan Nov 23 2026: I8_37 is the look for every Glasswright). Nothing is see-through on an intact hull;
the interior shows only in the break-up. No wear.

| File | What it holds |
|---|---|
| `parts.py` | `Ribbon` (a ribbon laid over the ship's core surface: centre line, leaf width profile, lift and curl), `leaf` (width profiles), `mosaic_tint` (one colour per leaf-length panel of each seam, by weight, graded deep to hot with `TONES`, as on I8_37; R431, Ryan Nov 23; `GW_MIX=marble` (the Nov 21 look test D) or `streaks` for a comparison only), `cut_lens` (a rose-cut faceted stone for optics and drive lenses). Pure geometry. |
| `stack.py` | The paint stack: colours sampled from the CD5 concept (`sample_concept` repeats it), `LOOK` values for the bake and the game, and the Cycles materials `gw_pearl`, `gw_silver`, `gw_mosaic`, `gw_gem_*`, `gw_root_*`, `gw_drive*`, `gw_tip`, `gw_lance`, `gw_light` (stored light) and `gw_beam` (the lance's white core). `tile_swap` gave about a quarter of the mosaic tiles another palette colour (`TILE_SWAP`, Ryan Nov 21); 0 since R431 unless `GW_MIX=marble`. `SATURATION` (1.25) gives every hull, craft and capitals, the same gentle colour lift (Ryan Nov 21). `RELIEF` gives the bake real surface relief and sheen spread (raised leading, tilted and hammered stones, poured pearl ripple, twisted silver) so the hulls pass the surface detail floors (issue 1517). `AUTHORED_LOOK` marks the baked materials so godot/render/look.gd keeps their values (R329). |
| `hull.py` | The shared sheet pieces. `i8_field` and `i8_shell` (R431, Ryan Nov 23 2026: every Glasswright reads as I8_37) lay the CD5 Ark's pearl shell on any body: twelve fine pillowed ribbons spiralling round it, crossing leaves that curl up, the glass only in their leaf seams; `mosaic_share` and `mosaic_gate` fail a hull over `stack.MOSAIC_MAX` bare glass. |

How a ship uses it: the ship file gives a core surface `core(x, a)`, lays its ribbons with `Ribbon(...).mesh(core)` (pearl,
solidified) and `edge()` (silver lines), paints the core with `gw_mosaic` and writes `gw_tint` and `gw_glow` per vertex from
`mosaic_tint`. Worked example: tools/blender/build_sheets/ships/ithar_CD5.py (r5).
