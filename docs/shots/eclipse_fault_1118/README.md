# Eclipse install review

Refs #1082. The broken PR 1071 pictures came from the isolated review build. Its cache combined the new Eclipse meshes with old A4 hull textures. The shared build already had the new textures because the install moved the old ship folders, including their editor import sidecars, out of the way.

## Cause and proof

- **Black patches.** Godot's GLB reader looks for imported textures before reading external image bytes. In the retained PR 1071 project, each cached hull albedo was pixel-identical to its editor import. Each differed from the current JPEG by an average of 16 to 20 levels per RGB channel. The cached parts atlases, whose names were new, matched the current JPEGs within one level. Three E11 pixels at (1028, 640), (1083, 611), and (983, 697) in the 1920 by 1080 close frame were black in the review cache. The same pixels read RGB (35, 25, 56), (85, 77, 93), and (15, 12, 23) in the shared build. The triangles and UVs at those spots matched the stage 5 exterior plating. [Godot's GLB reader](https://github.com/godotengine/godot/blob/ed1daf0bf/modules/gltf/gltf_document.cpp#L2235-L2262) · [Ship cache builder](../../../godot/render/build_assets.gd)
- **E11 tilted panel.** The feature is the starboard `Q1s_mount_gunv` attitude thruster. A ray through the centre of the reported rectangle hit that mount, then the exterior hull. Its backing overlaps the hull, and the stage 5 and installed transforms agree. The correctly painted plate beneath it makes the seating visible. [Thruster placement](../../../tools/blender/build_sheets/ships/deathless_E11.py)
- **E13 and E12 grey half-discs.** The left edges of the close views show the stern engine bells in profile. The E13 crop hits `E1_body_gunv` on the rolled lip. The E12 crop hits the outer housing of `E1` and `E2`. The stern views show the open exits and corona rings. They are part of the engine kit. [Eclipse engine bell](../../../tools/blender/kits/eclipse/parts.py)

The cache builder now loads external ship maps from the files beside the GLB. The regression check plants an old texture at the new atlas path, confirms the plain importer loads it, and proves the ship builder reads the new file. The fix also decoded all seven current maps on each ship in the retained PR 1071 project with its old editor imports still present. [Install refresh check](../../../godot/render/test/install_refresh_check.gd)

Stage 7 reproduced all four GLBs and 28 maps byte for byte. The four existing manifest rows already describe the new exports. [Ship manifest](../../../godot/assets/ships/manifest.json)

The shared build was reinstalled through stage 7 after archiving the prior ship folders and cache scenes in `sync_old\eclipse_fault_1118`. All four passed the stage 6 LOD bench, stage 7 export and hard-point checks, export selftests, installed ShipView readback, authored interior check, and wreck plating check. The final manifest reported `MANIFEST OK` for all 259 files.

| Ship | Triangles | Surfaces | Readback nodes | Wound surfaces | Authored breaks | Protruding room triangles | Split machines |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| E11 / `D22_23` | 117,298 | 18 | 34 | 11 | 4/4 | 0 | 0/11 |
| E13 / `D9_23` | 20,660 | 13 | 12 | 2 | 1/1 | 0 | 0/6 |
| E12 / `D21_23` | 55,006 | 17 | 27 | 3 | 2/2 | 0 | 0/11 |
| E14 / `D20_23` | 48,152 | 11 | 10 | 4 | 2/2 | 0 | 0/6 |

E11's separate vertex probe repeated the 19 cut-edge flags seen in issue 1057. Its wreck plating check passed with zero protruding room triangles and zero split machines. E14 kept its 5.15-unit board lift and cleared the board by 0.039 units at the bottom of the idle bob. Standing checks recorded 67 passes and two known baselines. All 284 seeded battles and 30 seeded campaigns passed parity, including the cross-twin save test.

Stock scene 207 ran twice in Forward+ on the RTX 5080 with the GPU held solo and the reinstalled ship cache. The second run passed the 12.5 ms gate at 8.65 ms frame time at 1080p and 5.78 ms GPU time at 4K. Its three 1080p session medians were 9.755, 8.648, and 6.591 ms.

## Comparison sheets

The left column shows the broken PR 1071 review cache. The middle column shows the reinstalled shared PC build. The right column shows the paint blend brought into the same camera and battle light. E11 and E12 use the Nov 14 paint, before E12 gained its armoured core. E13 uses the Nov 15 paint. E14's saved early paint blend has a horizontal ring, so its panel uses stage 5 of the approved upright build. The bottom row shows the reinstalled ships from four directions at both radii. [E14 ring study](../../ship_pipeline/build_sheets/deathless_E14/ring_study.jpg)

- [E11 The Unsetting, D22_23](E11_D22_23.png)
- [E13 Mote, D9_23](E13_D9_23.png)
- [E12 Zenith, D21_23](E12_D21_23.png)
- [E14 Flare, D20_23](E14_D20_23.png)

## Other previews

| Preview | Dark patches | Floating panel or grey disc |
| --- | --- | --- |
| [S8 Daybreak](../swap_sunward_s8_1118/V1b_r_23_S8.png) | Same stale hull atlas. The cached albedo was identical to the editor import and differed by 31.11 levels per RGB channel from the on-disk export. | No loose panel or stray disc identified in the issue 1059 sheet. The stern engine profile is part of the design. |
| C11 Bladeback | The first issue 1058 review reproduced the stale-atlas fault. The final wet-flesh and hard-chitin previews show the corrected continuous hide. | No loose panel or stray disc visible at either review radius. |
| CD5 The Unfinished | No matching patch visible in the final glass preview at either radius. | No loose panel or stray disc visible. The bright stern shape is the drive glow. |
