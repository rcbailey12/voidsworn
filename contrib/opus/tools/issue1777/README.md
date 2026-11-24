# Issue 1777: Ship Exteriors V2 (Law 6, Wave A) tools

Everything here serves `VS_SHIP_LOOK_V2=1` (off by default until Ryan has seen the PC sheets). The switch and every number
live in `godot/render/look.gd` (`ship_look_v2_enabled`, `V2`).

- `make_detail_maps.py`: writes the six faction micro-detail pairs into `godot/assets/ships/detail/` (seeded, periodic, so
  the same run writes the same files and every map tiles). `python3 make_detail_maps.py`. numpy and Pillow only.
  `detail_maps_preview.jpg` shows each pair lit and tiled 2x2 (a flat preview, not an in-game picture).
- Import settings are tracked beside the maps: normal maps import as normal maps with high quality off, so the game holds
  them as BC5 (RGTC_RG); the grain maps are BC7. `godot/render/test/ship_look_v2_check.gd` checks both.

## What V2 changes (all behind the one switch)

| Item | Before | V2 |
| --- | --- | --- |
| Space reflections (#1679) | off | on, plus three more lobes (tight neutral warm-white sun lobe (Ryan, Nov 22), cool low bounce band, dark troughs up and down) |
| Per-faction ao_light_affect (#1679 READ ao_light) | off | on |
| Ambient energy | 0.50 | 0.19 |
| Key shadow normal bias / depth bias | 2.0 / default | 0.3 / 0.06 |
| Key shadow reach | fixed 600 | camera distance plus the farthest board hex from the focus plus 12, at least 120 (Fable H12: a 420 cap lost the far board) |
| Rim light specular | 8 | 3 |
| Hull glow | READ emit | x 1.6 Sunward, 1.35 Directorate, 1.3 Hullbreakers, 1.25 Chorus, 1.0 Glasswrights, 1.45 Eclipse |
| Micro-detail | none | faction normal + colour grain, object-space triplanar, 0.9 tiles per game unit |
| Godot 4.7 channels | none | Chorus coat 0.35 and warm backlight (no SSS: nothing visible at camera 170); Glasswright coat 0.6; Eclipse coat 0.25 |

Damaged and dying hulls keep the detail layer, anisotropy, coat and backlight (`godot/fx/fx_hull.gd` EXTERIOR mirrors them).

## Findings from the cloud (compatibility renderer under xvfb, spheres, not the game's Forward+)

1. **Anisotropy is wired but set to 0.** With no flow map it follows the glTF tangents, which run every way across a baked
   atlas: the probe showed blotchy smeared highlights, not a brushed sheen. It needs an authored flow direction (#1778).
2. **No Glasswright refraction, for good** (Fable's review H12). It moves the hull into the transparent pass, where beams
   and shields are not in the screen copy (they would not bend) and sorting against effects and wounds breaks. The
   Glasswrights are dark glass with clearcoat and the rim's fresnel.
3. **The BC5 "bug" in build_assets.gd was not a bug.** Godot 4.7 has no `Image.COMPRESS_RGTC`; `COMPRESS_S3TC` with
   `COMPRESS_SOURCE_NORMAL` already writes `FORMAT_RGTC_RG` (BC5). Measured in Godot 4.7.2; the check fails if it changes.
4. **Lower ambient warms every hull.** The ambient is cool and the key is warm, so dropping the ambient shifts every faction
   warmer; on the probe Eclipse violet-black read brown. Watch Eclipse and the Directorate on the PC sheets; the lever is
   the ambient colour or V2 "ambient", not the faction paint.
5. **Metal in the clay zone (Fable H6) is #1778's job.** V2 does not change any hull's metallic: bare metal near 1 with
   albedo 0.5 or more, dark in the paint and soot layers, is a bake change. The PC sheets show where V2's reflections help
   and where the bake has to.
