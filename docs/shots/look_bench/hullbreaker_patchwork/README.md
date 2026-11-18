# Hullbreaker patchwork, issue 875

## Current: KB1CC paint proof, run 2 (R292)

[KB1CC paint proof](KB1CC_patchwork.jpg) is 1280 by 720. It shows the accepted
concept, the new painted bomber at the same saved paint camera, the unchanged
A18 paint accepted in PR 883, and a close view of the new deck. The picture
carries its code, revision and stage. Ryan's review of this new proof is pending.

Revision: `9fefabe2+875-r2-e0de07e8a6`. This means base `9fefabe2` plus the
source hashes recorded in [checks.json](checks.json), not a new commit.

The cause was the craft-only paint override from issue 853: even `soot` and
`soot2` became bright red, with less grime and occlusion than the capitals.
The first patchwork repair also raised the small plates too far above the skin.
The new craft palette reads the faction's own `CONCEPT` pairs instead of
keeping separate bright reds. The base is dark iron, with different rust,
blood red and salvage tones. Stronger physical seam occlusion and grime,
broad paint loss to iron, and broken bare-metal chips along real convex rims
weather the plates. This uses the faction's panel-layer entry point without
drawing shader tiles or trophy grids on the craft. The grey trophy colour,
wear setting, material weights and trophy share are unchanged.

KB1CC's design keeps the irregular cuts, turns, welded laps and overlaps.
Its plates now stand 0.2 to 0.5 percent of the sheet length above the skin,
instead of 0.5 to 1.4 percent. These are the chosen design settings, not gates.
A16 to A20, the shared painter and the shared Hullbreaker plater are unchanged.

## Reproduce and check

From the repo root with ordinary Python:

```text
python tools/blender/kits/hullbreakers/review_patchwork.py %TEMP%/voidsworn875_run2 KB1CC
```

The saved script uses the existing recipe build and stack bake, 2048-pixel
hull and part maps, 32 bake samples and OPTIX. The beauty uses the unchanged
KB1CC capture script: 35-degree azimuth, 30-degree elevation, 52 mm lens,
game lights, Hullbreaker lift 1.25 and the same dark-sky specular setting.
It also renders the camera 170 preview and full orthographic views. Every
Blender call uses `tools/pc/tmo.bat`, GPU slots and `gpu_go.txt`. Blends, raw
renders, maps and logs stay in the chosen temporary folder.

`check_stack.py` passes against pre-job commit `1a536dcd`: capital settings
and craft-to-capital resets match, as do the faction palette, trophy share
and grey trophy zone. The craft palette check now requires the faction's
colours, replacing the obsolete requirement to keep its separate bright reds.
The A16 fixture record matches. Source comparisons confirm unchanged A16
to A20 designs, accepted capital pictures, shared painter and shared plater;
KB1CC's material-weight dictionaries and the capital evidence records also match.

The standing suite (`node contrib/opus/tools/run_all_checks.js`) finished with
exit 0: seven listed findings and twelve constant differences remain within
the existing baselines, with no new failures. The document check and
`git diff --check` also pass.

The real KB1CC build passes mesh integrity, fit (zero clashes), weapon match,
texture licences, lights and the six-view surface check. Surface checks find
zero room-colour or unpainted pixels. Current outside build counts are
84,184 triangles, 136 objects and four surfaces. These are reported counts;
no frame-time measurement was made. The lower relief also lets more plates
clear the existing machine keep-outs, which raises the triangle count from
the first run's 48,432. The fit check still finds no collisions.

Method: [build sheet](../../../ship_pipeline/build_sheets/corsair_KB1CC/README.md),
[part manifest](../../../ship_pipeline/build_sheets/corsair_KB1CC/manifest.json),
existing sheet/kit geometry plus the Hullbreaker paint stack; the design
change is lower plate relief and its reason, recorded in the design file.
No game export or install is included. Ryan's look is still required.

## Painted-output measurements, for review

These describe visible paint, not acceptance. sRGB luma is
0.2126R + 0.7152G + 0.0722B on pixels whose brightest channel exceeds 20,
excluding the black sky. Red means R > 1.2G and R > 1.15B. Different shapes
and framing affect these numbers. The old KB1CC proof at this same camera
had median luma 76.3; the new proof is 57.8. Its large sloping faces still
show a higher median and more red than the accepted capitals; inspect the
picture for the faction match and the strength of the wear.

| Painted output | Luma p10 | Luma p50 | Luma p90 | Red pixels, percent |
|---|---:|---:|---:|---:|
| KB1CC, run 2 | 35.0 | 57.8 | 75.8 | 26.8 |
| A18, accepted PR 883 | 23.6 | 41.6 | 86.1 | 12.5 |
| A16, accepted reference | 23.5 | 43.0 | 78.0 | 14.3 |

[checks.json](checks.json) also records the geometry size/angle spread, welds,
current source hashes, camera and surface-check results. PC copies of the
proof and this evidence are in
`C:\Users\rcbai\Downloads\voidsworn_test\board\issue-875\shots`.

## Accepted run 1 capitals (R289, PR 883)

[A18](A18_patchwork.jpg), [A19](A19_patchwork.jpg) and [A20](A20_patchwork.jpg)
are unchanged accepted references. A18 to A20 had selected `courses=True`,
which built orderly rows of small plates. Their issue 875 repair selected
`tools/blender/kits/hullbreakers/plating.py` for mixed-size, skewed, overlapping
slabs and welded laps. A16 and A17 kept the original sheet plater. Their
capital evidence remains in the same `checks.json`; it was not regenerated
for this craft-only follow-up.
