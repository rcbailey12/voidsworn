# Issue 2001 Material Maker trial

Eight editable Material Maker 1.8 graphs cover four metals, Chorus hide, Glasswright pearl, and two board planets. Enable them by setting `VS_MM_TRIAL=1` before launching Godot. Ship Look V2 uses the trial grain and normals at its usual scale and blend share. The baked terran and volcanic board surfaces use the trial ground detail at close range. Without the flag, the game selects the existing maps and the procedural planet octaves.

## Source and export

Material Maker 1.8 was installed from the official Windows ZIP under Downloads\voidsworn_test\tools\material_maker\1.8. The downloaded ZIP matched the release SHA-256 4dc604a09b8f2143f429aaba42e0829a83137c4e8b0d91b79d610c542c5ee9ff. The CLI exported all eight graphs on SwiftShader's CPU Vulkan device through `tmo.bat`. The app opens a renderer window during export and can run unattended. [Material Maker 1.8 release](https://github.com/RodZill4/material-maker/releases/tag/1.8), [Material Maker command-line documentation](https://rodzill4.github.io/material-maker/doc/command_line.html)

Use Material Maker's command line with absolute graph and output paths. From the installed application's directory, pass one or more of the files in [graphs](graphs/) at a time.

- Command arguments for ships are <code>--export-material --target Blender --size 512 --output-dir &lt;existing-scratch-dir&gt; &lt;graph.ptex&gt;</code>.
- For planets use the same arguments with <code>--size 1024</code>.
- For a CPU bake, set VK_DRIVER_FILES and VK_ICD_FILENAMES to the Edge SwiftShader ICD manifest and pass <code>--rendering-driver vulkan --gpu-index 0</code>. Check that the engine banner names SwiftShader. Use the PC watchdog for both software and hardware baking.

Use the PNGs from the graphs' named Export nodes. Preserve RGBA for ship grain and the two packed planet tiles. Drop the constant opaque alpha for the OpenGL normal PNGs. Save the R channel of the grayscale roughness exports as L8. Keep the tracked Godot import settings beside the game files. [Ship detail](../../../godot/assets/ships/detail/mm_trial/), [planet detail](../../../godot/world/detail/mm_trial/)

Ship roughness is available in [exports](exports/) for material editing. The game reads authored roughness at UV1, while the existing triplanar UV2 detail slots take only grain and normal. The planet shader derives the normal from the two packed height channels. Its other channels are crevice occlusion and dry albedo grain. Separate planet normal and roughness PNGs in the same folder are companion exports for material editing. The runtime trial uses the two packed RGBA8 planet tiles.

## File sizes and VRAM

PNG sizes are on disk. VRAM is the per-set texture payload including all mip levels. Ship grain is BC7 and ship normal is BC5, so each replacement pair has the same footprint as its existing pair. Each trial planet adds 5.33 MiB when its RGBA8 tile is bound.

| Set | Game PNGs (KiB) | Companion PNGs (KiB) | Trial VRAM |
| --- | ---: | ---: | ---: |
| Sunward Crusade | 519 | 80 | 683 KiB |
| Meridian Directorate | 378 | 53 | 683 KiB |
| Ashfall Hullbreakers | 653 | 110 | 683 KiB |
| Eclipse | 434 | 66 | 683 KiB |
| Chorus | 763 | 124 | 683 KiB |
| Glasswrights | 377 | 63 | 683 KiB |
| Terran | 1,575 | 1,851 | 5.33 MiB |
| Volcanic | 1,694 | 2,029 | 5.33 MiB |

## Visual verdict

In the exported maps, Eclipse's flush grid and Glasswrights' curved pearl leaves are the clearest changes. Chorus has visible grain and pores. The Sunward and Directorate panel rhythms are similar in the flat tiles, and Hullbreaker seams can still read as courses of plates. Terran shows rounded erosion ridges. The volcanic tile has ropy folds and darker hollows. The map inspection establishes what is in the textures. Which ones improve the game view is still open.

Keep Material Maker as a trial authoring tool. Its editable graphs and unattended exports worked. Hold broader adoption for the six hull and two planet comparisons, especially for repetition at camera 26 and shimmer or any distracting grain at camera 170.

## PC comparison

After the branch's checks and independent review pass, double-click [capture.bat](capture.bat) from the clean, reviewed checkout with the PC-built hulls and access to a GPU lane. The launcher waits on the watchdog's shared GPU slots and uses the same commit for each pass. The ship bench runs the six [rows](look_moments.json) at cameras 170 and 26. The planet bench uses its standard camera 170 and a camera 26 aimed over lit ground, with fixed clouds and the same baked maps for each pass. The stock planet close view is too far away for the fine-detail fade at full bake resolution.

The launcher expects 32 images and their provenance sidecars and checks every hull code. The before planet pass must finish and write valid pictures, but a band 2 miss does not stop the comparison. Its band result and per-picture means and sample counts are printed in the run summary. The after pass still requires band 2 PASS (0.03 to 0.25 linear, at least 200 samples per view). Images are stamped with the code, before or after, revision and stage. The default output folder is Downloads\voidsworn_test\board_c\issue-2001\shots. The GPU capture and in-game visual verdict are pending under RULEBOOK 3.12.

The run 3 `terran_c26` mean of `0.255` over `81,984` samples is a camera 26 framing limit, not evidence that the stock planet is too bright at the played camera. In `planet_v2_shots.gd`, band 2 samples every third pixel above the stamp and counts rays that hit the sphere on its lit side. At 1280 by 720 that is at most 427 by 192 samples, exactly 81,984. Every sampled ray hit the sphere's lit side, so the sample contained no off-disc or night-side rays. The close camera is aimed using the baked sea and cloud masks to show clear, sunlit ground, so even with full sample coverage it only measures that patch, not the full day-side disc. The patch did exceed the ceiling by 0.005. Use the camera 170 disc reading to judge the stock look at play distance.
