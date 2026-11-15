# Issue 781 helpers (R256, Ryan Nov 15 2026: S8 paint "Lighten a step")

Sandbox only, not standing checks. The bake and the previews are issue 756's (`../issue756/`, its README gives the order).

| File | What it does | Runs with |
|---|---|---|
| `measure.py` | the hull medians: the concept and the paint at the fitted camera (the render's silhouette and the concept's own, both eroded, the ember left out), the paint at the battle camera (audits.py's figure), and the halfway target | Python, numpy, scipy, Pillow |
| `whatif.py` | a painted blend with its hull and parts albedo maps multiplied in linear by K in memory, rendered at the battle and fitted cameras (evidence, not a paint) | bpy, through `../issue756/run_cpu.py` |
| `evidence.py` | the evidence picture `evidence/voidsworn_S8_lighten_781.jpg` | Python, numpy, Pillow |
| `pictures.py` | issue 756's three named pictures re-made, with the before and after medians on the concept picture | Python, Pillow |
| `evidence/` | the picture, the four medians files and `slope.json` (what the step did to the albedo, the battle percentiles, the concept figures) | |

What it found (1024 maps): the painted S8 already matched the concept's grey at the fitted camera, (52,49,48) against (52,47,47).
"Halfway at the battle camera", (39,37,38), needs the whole albedo about x2.4, which puts the fitted median at (73,69,67), well
over the concept. The iron pairs alone, under the wear tones (sunward.md 4), moved the battle median by about 1 step of 255.
Ryan picked the x1.85 column (R258). The stack now builds it: WEAR_STEP 1.85 on the wear tones and IRON_STEP .60 on the iron
family under the new wear floor (tools/blender/kits/voidsworn/stack.py). At 1024 it measured fitted (66,62,60), battle
(33,34,36), against the what-if's (66,62,60) and (34,34,36); the 2048 figures are in the paint folder's audits.
