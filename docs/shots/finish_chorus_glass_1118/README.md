# Chorus and Glasswright finish review

Refs #1058, run 2. The finish review uses an isolated Godot project. The two hulls still need Ryan's approval for the shared build.

## Run 2 pictures

The columns show A4, run 1 and run 2. Each side uses the same Look Bench nebula, headings and camera radii across the three
columns. CD5's battle views are scaled together to fit the old ship's tall outline. The close views are matched crops.

- [C11 / B21_11 comparison](C11_finish_run2.jpg)
- [CD5 / I8_37 comparison and lower-quality glass](CD5_finish_run2.jpg)
- [CD5 turntable, one six-second orbit at radius 58](CD5_glass_turntable.webp)

## Run 2 finish method

- **C11 Bladeback / B21_11.** Olive and ochre hard chitin follows the build sheet's overlapping shell shapes. The ship's own
  occlusion masks darken the joints. Broad, curved growth ridges carry the sheen at distance. Fine growth lines and grain
  go into the tangent-space normal map. The softer folds, tissue and weapon throats keep their wet finish.
  [C11 build sheet](../../ship_pipeline/build_sheets/chorus_C11/README.md) |
  [Manifest](../../ship_pipeline/build_sheets/chorus_C11/manifest.json) |
  [Chorus stack](../../../tools/blender/kits/chorus/stack.py)
- **CD5 The Unfinished / I8_37.** The full glass finish reflects the battle's live nebula and panorama. The surface bends the
  image of the sky and inner light behind it, with red and blue bending by different amounts. The optical film shifts colour
  with the viewing angle. The old saturated patches become softer, near-white light sources. At lower quality, the baked
  blue-violet tint and the inner lights provide colour without the screen copy.
  [CD5 r3 build sheet](../../ship_pipeline/build_sheets/ithar_CD5/README.md) |
  [Manifest](../../ship_pipeline/build_sheets/ithar_CD5/manifest.json) |
  [Glasswright stack](../../../tools/blender/kits/ithar/stack.py) |
  [Glass shader](../../../tools/blender/kits/ithar/blown_glass.gdshader) |
  [CD5 recipe](../../../tools/recipe/ships/ithar_CD5.json)

The build sheets supply every part and damage seam. C11 still uses a scratch recipe with `bake: stack` for this review.
CD5's Stage 7 export carries the tinted PBR maps. The isolated capture and timing scenes opt into the full shader on CD5's
translucent atlas surfaces. The bake uses the existing silver frame, authored breaks and inside mesh. C10 v7 follows Ryan's
pick in a later run. [Review helper](../../../tools/blender/kits/ithar/glass_review.gd)

Both finishes use two 4096-pixel atlases at 64 OptiX samples, exported to 2048-pixel game maps. On the sampled C11 hull
atlas, the middle 80 percent of roughness spans 0.24-0.64 in run 2 and 0.24-0.43 in run 1. The 90th-percentile normal-map
XY displacement from flat went from 1.6 to 20.6 levels on the same 8-bit scale.

## Run 2 export and install checks

Both ships passed the six-view surface check, Stage 6 LOD bench, Stage 7 hard-point and planted-fault checks, and isolated
ShipView readback.
The GLBs carry the same mesh buffers as run 1. The installed hull and parts albedo maps matched their current JPEGs within
0.49 levels per channel in the cache sample, including with run 1's editor imports present. The isolated cache uses the
raw-texture fix tested in issue 1082.

| Ship | Export triangles | GLB surfaces | Stage 6 draw calls, 20 full-detail copies at 1080p |
| --- | ---: | ---: | ---: |
| C11 / B21_11 | 208,646 | 14 | 130 |
| CD5 r3 / I8_37 | 461,770 | 24 | 170 |

The authored-interior probe passed on both ships. The separate wreck check again found one protruding triangle on C11
and 296 on CD5, with zero split machines out of 13 and eight respectively. These are the same wreck counts as run 1.
The visual review uses the authored geometry. A build-sheet fix is still needed before a shared install.

The C19_51 fixture was rebuilt from the A16 sheet and exported with `unbaked=1`. The regenerated GLB had the same SHA-256 as
the decompressed fixture, so the compressed bytes stay in place. The record now matches the Stage 7 exporter. Its Godot
seam check found zero split machines and zero protruding interior triangles.
[C19_51 fixture record](../../../godot/fx/test/fixtures/C19_51_unbaked.sheet.txt)

Standing checks had one timeout while the first review import and bake were running. The timed-out tree effects check
passed on its own at 154 seconds. Across those runs all 67 checks passed and two known baselines repeated.

## Run 2 Scene 207 cost

The full glass passed the 12.5 ms gate at **11.71 ms frame time at 1080p** and **6.01 ms GPU time at 4K**. The full
shader drew five glass surfaces. Switching only those surfaces from baked glass to the full shader changed median GPU
time by -0.10 ms at 1080p and -0.04 ms at 4K in this scene. Paired GPU differences ranged from -0.16 to -0.06 ms at
1080p and -0.09 to -0.04 ms at 4K.

The isolated run 1 review project (`a9346414` battle code, cache fix `30a23ce4`) used the current Scene 207 probe with the
same roster for every trial. C11 and CD5 occupied the Chorus Spitter and Glasswright Lancet slots so the battle drew both
ship codes. All 12 trials held exclusive access to the RTX 5080. The machine used a Ryzen 7 5800X and NVIDIA driver 617.42.
Godot 4.7.2 ran Forward+ with fitted shields, 4x MSAA, vsync off and full mesh detail. The 4K scene rendered at 2x in a
1920 by 1080 window. Each setup ran three sessions, alternating order, with 120 warm-up frames and 720 timed frames.
Installed ship manifest SHA-256 `32045761e260a6f32cad3d2901256d827041d368981f596ea6214270e5f1faec`.

Each cell reports the median, p95, p99 and worst frame in ms. Percentiles are the middle of the three session results.
The worst is the largest frame sample across the three sessions.

| Drawn resolution and glass | Frame | GPU | Render CPU | Main process monitor |
| --- | --- | --- | --- | --- |
| 1080p, baked fallback | 12.23 / 23.62 / 378.50 / 1604.54 | 2.74 / 3.27 / 3.44 / 3.90 | 2.78 / 5.15 / 5.52 / 11.27 | 27.24 / 982.22 / 1009.20 / 1602.10 |
| 1080p, full glass | 11.71 / 21.06 / 223.24 / 923.11 | 2.65 / 3.25 / 3.41 / 3.89 | 2.54 / 4.83 / 5.37 / 295.88 | 36.88 / 373.82 / 387.31 / 920.18 |
| 4K, baked fallback | 9.87 / 19.12 / 171.21 / 953.63 | 6.05 / 6.75 / 7.34 / 7.97 | 2.44 / 4.23 / 4.61 / 5.22 | 35.89 / 178.50 / 841.72 / 953.03 |
| 4K, full glass | 9.15 / 13.37 / 23.52 / 384.75 | 6.01 / 6.62 / 6.76 / 6.92 | 2.54 / 3.55 / 4.00 / 9.81 | 34.14 / 89.00 / 89.00 / 383.76 |

The second 1080p session went over the frame gate with both materials (13.92 ms fallback, 13.95 ms full). Timing tails
were uneven, especially in the main process monitor. The first rendered frame after applying the full glass took 108 ms
from assignment to post-draw on its first 1080p scene. The later 1080p full-glass starts took 10.4 and 6.9 ms.

In the first scene's installed hull snapshot, C11 counted 208,874 triangles across 16 surfaces. CD5 counted 464,673
triangles across 27 surfaces, including damage surfaces. Its 334 unjoined build-sheet pieces become 24 GLB surfaces,
including the three turning optics. CD5 is above the old capital reference of 256,768 triangles and within the binding
frame budget. Median full-glass scene draws were 487 visible plus 323 shadow at 1080p, and 481 plus 323 at 4K.
[Scene 207 reference](../ship_pipeline/bench207/README.md) | [Rulebook section 3](../../RULEBOOK.md#3-pc-and-tools)

## Run 1 record

The run 1 sheets compare the old A4 hulls with the finished build-sheet hulls in the isolated Godot review project.
The upper row is radius 170 at 1080p native pixel size. The lower row is a close crop at radius 26. The camera, ship heading,
sky and battle lights match across the columns.

### C11 Bladeback

Wet flesh has dark olive sinew and a wet shine across the hide. Hard chitin puts ochre shell on the large curved surfaces
and leaves the joints and throats soft. Both keep the bone crests and the bile-green light from the sheet.
The two finishes are close in colour at radius 170. The close view shows a smoother hide than the concept.

![C11 wet flesh and hard chitin beside the B21_11 A4 hull](C11_no_wear.jpg)

### CD5 The Unfinished

Polished glass follows the six twisted strands. The silver veins and frame are solid. Amber leads the stored light beneath
the glass, with violet and green between it and a pale bloom in the drive optics.
The star highlight is clear in the close crop and the reflected sky is faint. Turning off sky reflection changed mean RGB
by 0.55 of 255 in the crop. Turning off directional specular as well changed it by a further 10.63. The stored light reads as
individual slivers. The approved concept has a denser wash of colour through the glass.

![CD5 r3 blown glass beside the I8_37 A4 hull](CD5_no_wear.jpg)

### Method

- C11 uses the accepted cruiser sheet and its existing material zones. For the two review bakes, the scratch ship entry
  selects `bake: stack` and `CHORUS_FINISH` selects `flesh` or `chitin`. The C10 v7 rollout follows Ryan's pick.
  [C11 build sheet](../../ship_pipeline/build_sheets/chorus_C11/README.md) ·
  [C11 manifest](../../ship_pipeline/build_sheets/chorus_C11/manifest.json) ·
  [C10 v7 build sheet](../../ship_pipeline/build_sheets/chorus_C10/README.md)
- CD5 uses the accepted R298 r3 design with a new `ithar_CD5` recipe entry. The bake uses the sheet's rolled-glass attribute,
  geometry masks and the shared albedo, roughness and normal bakes. The solid frame and translucent glass share the atlas.
  The two lances, three turning optics, stern drives, light slivers and authored fracture paths come from the r3 sheet.
  [CD5 build sheet](../../ship_pipeline/build_sheets/ithar_CD5/README.md) ·
  [CD5 manifest](../../ship_pipeline/build_sheets/ithar_CD5/manifest.json) ·
  [CD5 recipe](../../../tools/recipe/ships/ithar_CD5.json)

Both stacks use clean procedural colours and surface relief. Both use the authored inside geometry. The bakes use
two 4096-pixel atlases at 64 samples, then Stage 7 writes 2048-pixel game maps. The proof uses the GPU queue and a separate
copy of the Godot build. The shared install follows approval.

The isolated install refreshes Godot's editor imports before rebuilding the ship cache. The first C11 readback
verified the new mesh and hard points while the cached albedo still matched the old imported JPEG. The refreshed import
is part of the review capture and cost run.

### Export and damage checks

Both C11 options and CD5 passed the six-view surface check, the Stage 6 LOD export and Godot bench, the Stage 7 hard-point
and broken-export checks, and the isolated install readback. The runtime authored-interior probe passed for all three.
The CD5 export carries seven breach points and six authored seams. Stage 7 now tries same-side spacing when the side
projection alone makes an otherwise clear opposite-side breach point look crowded.

| Export | Triangles | GLB surfaces | Stage 6 draw calls, 20 copies at 1080p |
| --- | ---: | ---: | ---: |
| C11 wet flesh | 208,646 | 14 | 130 |
| C11 hard chitin | 208,646 | 14 | 130 |
| CD5 r3 | 461,770 | 24 | 170 |

CD5 has 440,266 main mesh triangles and 21,504 in three turning optics. The 24 surfaces include those optics. The
build sheet's 334 unjoined pieces collapse into these material surfaces in the export.

The separate destruction check preserved all eight CD5 machines and all 13 C11 machines, with zero split on either hull.
Its interior containment check failed. Both C11 finishes have one triangle outside its own broken piece, matching the
earlier unpainted C11 export. CD5 has 296 there, compared with 294 on the unpainted r3 contract. The review keeps the
authored geometry and tear paths. The breakup finding needs a build-sheet pass before the shared install.

The standing Node suite finished with 67 passes and two known baselines. The corrected CD5 export also passed its
broken-export and turret checks.

### Scene 207 cost

The isolated scene used the same 24-unit roster in every run. The Chorus Bladeback and The Unfinished took the
Chorus Spitter and Glasswright Lancet slots so the test actually drew both target codes. Each row uses three
sessions on the RTX 5080 in Forward+, with 120 warm-up frames and 720 timed frames per session.

| Isolated install | 1080p frame median | 4K GPU median | 1080p scene draws, visible + shadow |
| --- | ---: | ---: | ---: |
| Old A4 for both | 7.17 ms | 5.91 ms | 487 + 326 |
| C11 wet flesh, old Glasswright A4 | 5.71 ms | 5.91 ms | 491 + 326 |
| C11 hard chitin, old Glasswright A4 | 6.25 ms | 5.85 ms | 489 + 326 |
| C11 hard chitin and CD5 r3 | 6.88 ms | 6.10 ms | 480 + 303 |

The CD5 install added 0.25 ms at 4K against the same chitin run with the old Glasswright A4. After the scene warm-up,
CD5 counted 463,012 hull triangles and 27 surfaces, including damage surfaces. That is above the original Scene 207
capital reference of 256,768 triangles. At full detail, CD5 passes the binding flagship budget of 12.5 ms on both
readings. [Scene 207 reference](../ship_pipeline/bench207/README.md) · [Rulebook section 3](../../RULEBOOK.md#3-pc-and-tools)
