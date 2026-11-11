# Sunward flagship image trial, issue #431

Six pictures made with Codex's built-in image tool: three design sheets and their reference-based beauty views.
My pick for the Board's next review is S3 Forge Blade: its lower radiator bank leaves the dagger plan clear.
These are trial concepts, not approved build references. The failures below need the Board's review.

## Tool, model and limits

- Tool: built-in `image_gen.imagegen` (callable as `image_gen__imagegen`), through the signed-in session. No API key or CLI image fallback.
- Model: the built-in image generation model. The tool exposes no model name, version, selector or model metadata, so an exact model ID cannot be verified.
- Codex CLI: `codex-cli 0.166.0`.
- All three beauty calls accepted a local design-sheet PNG through `referenced_image_paths` and returned images. The final beauty views use the final delivered sheets' original PNGs.
- Eleven image calls completed, producing eleven pictures, six selected for delivery. No generation limit or quota error occurred. The run stopped after the requested set, so maximum capacity is unknown.
- No local GPU render, ComfyUI, Blender or game capture was used. System.Drawing only resized and converted generated pictures to JPG; it did not create the art.
- Original PNGs remain untouched in `C:/Users/rcbai/.codex/generated_images/01a1c888-84b6-7620-935c-d98f21dfb4f7/`.

## Delivered pictures and tries

Every JPG has a 1536 pixel longest side, with JPEG quality 92 and size below 700,000 bytes.

| Variation | Design sheet | Tries | Beauty view | Tries |
|---|---|---:|---|---:|
| S1 Oath Blade | [Sheet](voidsworn_S1_sheet.jpg) | 1 | [Beauty](voidsworn_S1_beauty.jpg) | 1 |
| S2 Blade and Hilt | [Sheet](voidsworn_S2_sheet.jpg) | 3 | [Beauty](voidsworn_S2_beauty.jpg) | 1 |
| S3 Forge Blade | [Sheet](voidsworn_S3_sheet.jpg) | 3 | [Beauty](voidsworn_S3_beauty.jpg) | 2 |

S2 try 1 was too wide, about 3:1. Try 2 was still too wide, about 3.9:1. Try 3 overshot toward narrow.
S3 try 1 was about 4.4:1. Try 2 overshot toward narrow, about 5.8:1. Try 3 brought it close to the target.
S3's first beauty matched its first sheet, then was replaced after the sheet's proportion revisions.
No picture exceeded three tries. All final originals and exported sheets were inspected by eye.

## Twelve gate lines

PASS means the visible sheet supports the line. FAIL also covers a feature that cannot be confirmed by eye.
These scores are candid trial notes for the Board, not a claim that all sheets cleared the gate.

| # | Gate | S1 | S2 | S3 |
|---:|---|---|---|---|
| 1 | Exactly four deliberate weapon installations | FAIL: lance and galleries present, but dorsal flak reads as a lit sensor dome and gallery ports resemble windows | PASS: two dark galleries, one axial lance, one compact short-barrel flak mount | PASS: two recessed dark galleries, one axial lance, one compact short-barrel flak mount |
| 2 | Guns clear; none backward or into hull | FAIL: flak muzzles and firing directions are not resolved | FAIL: gallery mouths read partly upward in the plan; outward firing is not unambiguous | PASS: clear forward lance/flak and open lateral gallery recesses |
| 3 | One thrust axis, engines only at stern | PASS: two stern bells; radiator light is visibly solid fins | PASS: stern bells only; solid radiator bank separate | PASS: stern bells only; lower grates read as heat exchangers |
| 4 | Continuous spine from bow to engines | PASS | PASS | PASS |
| 5 | One low command block and one low sensor cluster | FAIL: command block clear, separate/integrated sensor cluster not legible apart from ambiguous flak | PASS: low command block with one flat cap sensor | PASS: one low command block and one small low sensor cluster |
| 6 | No hangar on this ship | PASS: no bay mouth | PASS: no bay mouth | PASS: no bay mouth |
| 7 | Left/right symmetry | PASS in plan | PASS in plan | PASS in plan |
| 8 | Identity reads in top view | PASS: rear-wide dagger and orderly radiator bank | PASS: blade, squared guard and short engine grip | PASS: bare dagger with lower-edge heat slivers |
| 9 | Near 5:1:0.7 proportions | PASS: about 5.08:1:0.68 | FAIL: about 5.93:1:0.82 | PASS: about 5.35:1:0.75 |
| 10 | One small-detail scale, capital reads very large | PASS: consistent fine rivets, seams and scratches | PASS: consistent rivets and seams | PASS: fine rivets, seams and many grate divisions |
| 11 | Space ship, not sea ship or aircraft | PASS: armoured blade, no naval/aircraft tells | PASS: thick squared machinery guard, no aerodynamic wings or naval hull | PASS: thick armoured blade and lower heat bank, no keel |
| 12 | Black iron, frost white, ember; faction never list | PASS: no blue, rust, crosses, statues or literal cathedral windows | PASS | PASS |

S1: 9 PASS, 3 FAIL. S2: 10 PASS, 2 FAIL. S3: 12 PASS on these visible concept gates.
A pass is an image judgement, not proof of mechanical internals or final build readiness.

### Proportion measurements

Approximate manual pixel extents on the final 1536 x 1024 sheets, uncertainty about 4 pixels per edge.
Length includes engine housings and lance, excludes exhaust and bloom. Beam is maximum plan width.
Height is maximum side silhouette, including radiators. Both views have matching bow/stern endpoints.

| Sheet | Plan x bounds | Plan y bounds | Side y bounds | L / B / H pixels | Normalised L:B:H |
|---|---|---|---|---|---|
| S1 | 27 to 1510 | 178 to 470 | 616 to 815 | 1483 / 292 / 199 | 5.08:1:0.68 |
| S2 | 94 to 1518 | 269 to 509 | 620 to 816 | 1424 / 240 / 196 | 5.93:1:0.82 |
| S3 | 75 to 1510 | 194 to 462 | 621 to 822 | 1435 / 268 / 201 | 5.35:1:0.75 |

## What the tool got wrong or left unresolved

- Numerical plan width was the repeated weakness: both correction chains overshot even with pixel dimensions in the prompt.
- S1 rendered the flak as a dome, and its gun ports look like orange windows. These are marked failures, not silently treated as resolved.
- S1 and S2 show multiple engine bells vertically in side view although their plans place the bells side by side. These side projections are not mechanically exact. S3 correctly occludes the far bell.
- S2 broadside gallery orientation is ambiguous. The top and side agree on location, but the top mouths should be more clearly cut into outward-facing walls.
- The S1 beauty changes the lance tip into two apertures within one axial weapon. The broad layout is retained, but the tip is not an exact tracing of the sheet.
- All three beauties include exactly one separate escort with a shorter, simpler hull. Rivet/window scale is broadly related, but exact shared physical dimensions cannot be proved from a perspective painting.
- Abstract frost-white scratches stay nonverbal. No readable text, extra ships, exposed broadside deck barrels, backward guns or exhaust away from the stern were observed.
- References preserved the main layouts and palettes well, but did not enforce orthographic engineering precision.

## Source provenance

All names below are PNG basenames under the original generated_images folder above.
The matching final JPG is a resized copy, never a moved source.

| Delivered JPG | Original PNG |
|---|---|
| voidsworn_S1_sheet.jpg | exec-fc1002ba-9517-4a40-9715-80785b13d692.png |
| voidsworn_S1_beauty.jpg | exec-1a151df8-2bba-4e94-a4e2-80df5b5b5474.png |
| voidsworn_S2_sheet.jpg | exec-4f8cce79-bc0d-484a-be94-1a5df00589c3.png |
| voidsworn_S2_beauty.jpg | exec-25b3ffa6-ba24-4b11-aa82-4a2f049e0fb5.png |
| voidsworn_S3_sheet.jpg | exec-2db7dffb-b15f-4cd2-84bd-e5d29bc4f680.png |
| voidsworn_S3_beauty.jpg | exec-44fb9104-6072-4659-87ff-b155eee3889f.png |

S2 sheet lineage: try 1 `exec-99d1f0d7-64d4-4b5e-b216-6547e19f4cda.png`, try 2
`exec-472b2180-07cc-409d-84a8-0c8f593aaaba.png`, try 3 delivered.
S3 sheet lineage: try 1 `exec-e2382ed8-8571-42d0-97bb-83fe564dd91a.png`, try 2
`exec-3cf2d0b4-44e1-48a0-8229-f4ba0c17a1b7.png`, try 3 delivered.
S3 beauty try 1: `exec-1df58ddd-7ff0-4e30-9e54-77d93f6ad229.png`.
Each sheet correction referenced the preceding try. Each beauty referenced its corresponding sheet.
[Exact prompts](prompts.md) includes the six selected calls and all five earlier calls.

## Board review copies

The six final JPGs are also copied to the task's required Board shots folder:

- [S1 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-431/shots/voidsworn_S1_sheet.jpg)
- [S1 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-431/shots/voidsworn_S1_beauty.jpg)
- [S2 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-431/shots/voidsworn_S2_sheet.jpg)
- [S2 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-431/shots/voidsworn_S2_beauty.jpg)
- [S3 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-431/shots/voidsworn_S3_sheet.jpg)
- [S3 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-431/shots/voidsworn_S3_beauty.jpg)

## Validation

- Six final JPGs exist, are readable landscape images, have longest side 1536, and each is below 700,000 bytes.
- Exact prompt and source lineage recorded; all three beauty references were accepted.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, 41 PASS rows and 2 KNOWN rows, no FAIL or SKIP. The known rows are findings_tests (12 baseline failures) and oracle_drift_guard (12 baseline constant differences).
- Standing-check log: `%TEMP%/voidsworn-issue-431-standing-checks.log`. The pack includes its own headless Godot tests; no separate game render or visual capture was run.
- All six Board shots copies match the delivered JPGs by SHA256. JPG format, dimensions, file sizes and Markdown without em dashes were checked. `git diff --check` passed.
- No game or tool source changed. No GPU captures or separate Godot parity/game suites were run for this art-only trial.
- No commit and no push.

## Chorus C4 Bloom Mouth grown up, issue #437

[Design sheet](chorus_C4_sheet.jpg) and [beauty view](chorus_C4_beauty.jpg) deliver the single picked Chorus direction from R178.
The two huge dark bioplasma throats, one forward-sweeping tendril crown and one bounded dorsal spore field read as four deliberate weapon organs.
The 384 x 256 sheet thumbnail was inspected: both bow throats remain distinct and the crown and spore field remain separate.
This is a concept for Board review, not an approved build reference.

### Method and attempts

Built-in `image_gen.imagegen` only, no API fallback, ComfyUI, Blender, Godot render or code-drawn art.
The tool does not expose an exact image model ID.
Sheet try 1 referenced the named [Muse C1 sheet](../../../muse/design/concept_round2_2026_11/chorus_C1_sheet.jpg).
It was too narrow (about 6.2:1), and its two visible lateral sacs plus ventral sac suggested five total.
Sheet try 2 corrected the beam and removed the extra lateral sac.
Sheet try 3 broadened the stern vents and added two transverse healed break seams.
Beauty try 1 used sheet try 2; beauty try 2 used final sheet try 3 to carry the revised stern and scars through.
Five calls completed, no limit error. [Exact prompts](prompts.md) records all five.

System.Drawing resized and converted generated PNGs to JPEG quality 92; it did not draw or alter the art.
The original PNGs remain untouched in:
`C:/Users/rcbai/.codex/generated_images/01a1c956-ebd6-77d3-97d6-71eca14be5cc/`.

| Output | Original PNG | Tries | Dimensions | Bytes |
|---|---|---:|---|---:|
| chorus_C4_sheet.jpg | exec-af3d2cb9-70c6-47d8-b143-ceec8a3e657f.png | 3 | 1536 x 1024 | 239982 |
| chorus_C4_beauty.jpg | exec-d56edb03-cdc9-4f84-88c3-3f17f94b0466.png | 2 | 1536 x 864 | 210783 |

Rejected sheet try 1: `exec-04b09607-61ff-40a2-b0bd-a6fb54372370.png`.
Superseded sheet try 2: `exec-7ac11287-7bac-4b49-95e2-e2431901e6a7.png`.
Superseded beauty try 1: `exec-4c5d3b31-6c71-4d02-b0f3-bfab1d0bfef4.png`.
No picture exceeded three tries.

### Proportion measurements

Requested sheet extents: 1400 px length, 330 px beam, 297 px height, about 4.24:1:0.90.
This intentionally lengthens the old 3.5:1:0.9 grammar to follow the newer leaner C4 brief.
Approximate manual measurements on the delivered sheet, uncertainty about 8 px per edge, exclude soft glow and include solid membrane tips:

| Projection | x bounds | y bounds | Extent |
|---|---|---|---|
| Top | 28 to 1498 | 117 to 460 | 1470 px length, 343 px beam |
| Side | 30 to 1513 | 556 to 855 | 1483 px length, 299 px height |

Measured L:B:H is about 4.29:1:0.87. Projected lengths differ by under 1 percent.
The forward tubes are roughly 180 px long with roughly 90 px outer diameters, so their silhouettes survive thumbnail reduction.
The final blunt stern has two substantial aft-facing vent mouths. Their combined projected aperture spans about 100 px of a roughly 235 px stern-face span, about 43 percent; this is a concept estimate, not a cross-sectional area measurement.

### Twelve gate lines for C4

PASS is a visible concept judgement. FAIL includes details the pictures cannot establish.
The later C4 brief places the spore field on the upper centre line, overriding the older upper-flank wording.

| # | Gate | C4 judgement |
|---:|---|---|
| 1 | Counted weapons, armed in thumbnail top view | PASS: two huge dark forward throats, one rooted tendril crown and one bounded oval spore field; no added flak or decorative guns |
| 2 | Clear firing paths, nothing backward or into hull | PASS: throat mouths project clear of the open petals; crown sweeps forward and outboard above the hide |
| 3 | One stern thrust axis, enough engine area | FAIL: final broad vents read as strong aft propulsion and span about 43 percent of stern, but top pairs them horizontally while side stacks them vertically, leaving the actual pair layout inconsistent |
| 4 | Continuous spine and two or three break lines | PASS: continuous muscular ridge crossed by two healed scar seams near x=365 and x=1135, wrapping into side view |
| 5 | One protected command and one sensor cluster | PASS: one low central ganglion and adjacent paired-lobe sensory membrane patch between spore organ and crown; no eyes or towers |
| 6 | Three hangars, each a mouth | PASS with occlusion: side shows one lateral sac with dark slit and one median ventral sac aft; its opposite lateral partner is hidden in strict side, giving three total by symmetry |
| 7 | Bilateral symmetry | PASS: paired bow tubes, petals, crown whips, stern lips and lateral sac pair; median ventral sac preserves symmetry |
| 8 | Top carries identity | PASS: elongated bloom-headed silhouette, enormous twin throats and separately readable dorsal organs |
| 9 | Fixed stated proportions and distinct escort | PASS: about 4.29:1:0.87 against revised C4 target 4.24:1:0.90; beauty escort is a simpler single-throat hull with one small spore patch, no crown or brood sacs |
| 10 | Consistent detail scale and capital scale | PASS by eye: fine capillaries and growth scars, more extensive on capital; exact physical pore sizes cannot be proved from perspective |
| 11 | Space, not sea or air | PASS: grown muscular spine and vent tail, no keel, mast, aircraft wings or cockpit |
| 12 | Chorus palette and Never list | PASS: olive-brown hide, ochre cartilage, restrained bile-yellow internal light; no metal, eyes, legs, insect segments, cute face or red/magenta flesh |

11 PASS, 1 FAIL. The gate is not fully cleared after the allowed three sheet attempts.
The visible warship requirement is met. The stern pair's top/side projection mismatch needs Board review before a build brief.
The beauty keeps the accepted weapons and sac positions and contains exactly one separate, simpler escort.
Its perspective emphasises the bow and foreshortens the body; the sheet remains the proportion reference.

### Board review copies and validation

- [C4 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-437/shots/chorus_C4_sheet.jpg)
- [C4 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-437/shots/chorus_C4_beauty.jpg)

Both JPGs were inspected at delivery size; the sheet was also inspected at 384 x 256.
Both have longest side 1536 and are under 700,000 bytes.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, 41 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. The known rows are findings_tests (7 listed failures) and oracle_drift_guard (12 baseline differences).
- Check log: `%TEMP%/voidsworn-issue-437-standing-checks.log`.
- Final JPG dimensions, byte sizes, readability and Board-copy SHA256 equality checked. Changed Markdown has no em dashes; `git diff --check` passed.
- No separate Godot render, parity suite or GPU capture: this job changes concept art and its notes only; the standing pack ran its own checks.
- No files outside the deliver folder changed in the checkout. CODEX_TASK.md was already untracked and left untouched. No commit and no push.

