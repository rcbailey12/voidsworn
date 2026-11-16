# Hullbreaker patchwork, issue 875

R289: A18, A19, A20 and KB1CC now use mixed-size, turned, skewed slabs with
overlapping patches, thickness steps and welded lap joints. Start with the
individual comparisons. Each is 1280 by 720, with its code name, its accepted
concept, its painted build and the unchanged A16 paint reference.

- [A18](A18_patchwork.jpg)
- [A19](A19_patchwork.jpg)
- [A20](A20_patchwork.jpg)
- [KB1CC](KB1CC_patchwork.jpg)

## Cause

A16 and A17 have real mixed-size armour slabs and second layers in their
designs, built by the original sheet plater. Their `PL` settings use mixed
thicknesses and `stack=.45`. A18 to A20 instead selected `courses=True` in
issue 633: small rectangular plates laid in brick rows, with terraces on
upward faces. The issue 651 paint pass then painted those courses. R240
changed the shader cells but left the ordered geometry in place. This was
a geometry-route difference, rather than a missing copy of the paint stack.

KB1CC already split faces without courses, but its shallow slabs, small turns,
low share of second layers and reduced craft paint wear still read as flat notes. Its former local
plater is now shared in the Hullbreaker kit and gives all four ships a wider
range of sizes, skewed corners, stronger turns, physical overlaps and welded
laps. Its thickness and second layers now carry the same relief character
as A16. Tiny mount-clearance scraps are omitted and rivets scale to their
own plate. The sheets keep their material weights. Craft red plates regain
plate-tone variation and broken edge wear; the red colour pairs, grey trophy
zone, trophy share, R274 dark grey tones and capital paint settings stay unchanged.

## Method and proof

The design files remain the source of each ship's masses, parts, material
weights and plating settings. Only these four sheets select
`tools/blender/kits/hullbreakers/plating.py`; the shared sheet kit, A16 and A17
are unchanged. No new downloaded asset is used. Welds use the existing kit's
geometry, so the normal and occlusion bakes see the actual joins.

The existing recipe builds and paints each sheet with geometry masks, trim
and decals at 2048 pixels, 32 samples, OPTIX. The full views use the same
`paint_full` cameras: the saved sheet cameras for A18 to A20 and issue 853's
35-degree azimuth, 30-degree elevation preview for KB1CC. The latter also
keeps its accepted dark-sky specular setting. Lighting is the existing game
light and Hullbreaker lift 1.25. No camera or stack file was edited.

Reproduce on the PC from the repo root using ordinary Python:

```text
python tools/blender/kits/hullbreakers/review_patchwork.py %TEMP%/voidsworn875_review
```

The script runs every Blender command through `tools/pc/tmo.bat`, which owns
the GPU claim and respects `gpu_go.txt`. It uses the existing recipe bake,
sheet renderer, KB1CC capture script and six-view surface check. Scratch
blends, maps, raw renders and logs stay in the chosen temporary folder.
`check_patchwork.py` builds the real sheets, checks mesh integrity, runs the
fit and weapon checks, and reports plate areas, angles, layers and welds.
The area and angle distributions are review evidence, not visual pass bars.

The standing suite (`node contrib/opus/tools/run_all_checks.js`) returned exit
0. Its seven listed findings and twelve constant differences remain the
existing known baselines. Document checks passed. The A16 fixture record
still matches, and normalized source comparisons confirm that A16, A17
and the shared paint stack are unchanged. `check_stack.py` compares the
working stack against pre-job commit `1a536dcd` in memory: every capital setting, the palettes,
trophy share, grey trophy zone and craft-to-capital reset still match. A source
comparison also confirms identical material-weight dictionaries in all four
changed sheets.

[checks.json](checks.json) records each painted build's outside triangle,
object and surface counts, device, bake resolution and surface-check result,
plus its measured geometry. The build sheets and part manifests are the
existing `docs/ship_pipeline/build_sheets/corsair_<code>/` records; the design
files record the course replacement and the craft's stronger plating relief.

| Ship | Outside triangles | Outside objects | Surfaces / merged draws |
|---|---:|---:|---:|
| A18 | 185,760 | 270 | 4 |
| A19 | 220,738 | 263 | 4 |
| A20 | 226,314 | 414 | 5 |
| KB1CC | 48,432 | 136 | 4 |

These are build counts, not a measured frame-time result. All four pass the
fit and weapon checks. Their six-view surface checks find zero pixels of
room colour or unpainted surfaces; texture licence and light checks pass.

The PC copies of these pictures and checks are in
`C:\Users\rcbai\Downloads\voidsworn_test\board_b\issue-875\shots`.
No game export, install or frame-time bench is part of this paint proof.
Issue 726's capital paint run follows this repair.
