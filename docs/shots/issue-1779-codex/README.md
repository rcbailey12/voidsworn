# Issue 1779 cinematic post-FX

Run 1 adds opt-in Forward+ effects. Start the game with any of these environment variables set to `1` to preview that effect.

| Variable | Effect |
| --- | --- |
| `VS_BATTLE_LUT` | Selects the battle world's 33 x 33 x 33 grade. The Dead Star has its own grade, including on a campaign sector with a different regional sky. |
| `VS_BATTLE_DOF` | Eases in far blur on the close kill camera, hull close-up captures and the flagship podium. The podium has four dim lights in its 3D background. |
| `VS_BATTLE_SSR` | Enables Godot's scene-wide, half-resolution SSR at Max while a live Glasswright, Eclipse or Chorus hull is on the board. The ray march is capped at 32 steps. |
| `VS_BATTLE_LENSING` | Adds a depth-gated ripple outside the Dead Star's core. |
| `VS_BATTLE_SHOCKWAVE` | Adds a short distortion ring timed to the capital's staged core flash. Both comfort options suppress it. |
| `VS_BATTLE_DECALS` | Adds surface-placed scorch and plasma marks to the installed T2 station and up to eight primary blocker rocks. Marked rocks carry their marks through the tumble. |

The grades use a shared mild S-curve with a slight squeeze toward luminance and a regional bias weighted toward the midtones. The PNGs lay out 33 horizontal blue slices, with red along the slice's x axis and green along y. The imports use lossless color and disable mipmaps.

## Board run after green checks and review

From the reviewed checkout, queue `tools\pc\jobs\battle_post_fx_1779.bat capture` and `tools\pc\jobs\battle_post_fx_1779.bat timing`. The launcher uses the installed ship files and `tools\pc\tmo.bat`. Both modes use a 1080p Forward+ viewport at Max. The default output folder is `board_b\issue-1779\shots` under `Downloads\voidsworn_test`. A second argument can supply a different output folder.

- Start with the six `1779_c170_*.png` sheets. The current look is on the left. The enabled effect is on the right. The bench checks that the Glacier swatch on its own CanvasLayer is pixel-identical across each LUT pair.
- Review the capital death, flagship podium, reflective hulls under fire, Dead Star lens, station and asteroid sheets. Each PNG carries a provenance sidecar.
- In `1779_timing.json`, compare the median and 95th percentile GPU milliseconds against the two baseline runs. The reported shockwave delta uses the capital core window. The SSR and lensing deltas use the full sampled window.
