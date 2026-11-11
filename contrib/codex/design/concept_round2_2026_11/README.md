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


## Issue 435: H4 Kit Wedge and A4 Scrap Brick, armed

Four new pictures use Codex's built-in image tool and the named Muse references.
These are comparison concepts for the Board, not cleared build references. Both read as armed at 384px sheet width.
My pick is H4 for the stronger match between sheet and beauty. A4 needs its launcher geometry reconciled before a build.

### Deliveries and method

| Ship | Sheet | Sheet tries | Beauty | Beauty tries |
|---|---|---:|---|---:|
| H4 Dominion dreadnought | [Sheet](hegemony_H4_sheet.jpg) | 3 | [Beauty](hegemony_H4_beauty.jpg) | 1 |
| A4 Warlord's Pyre-Barge | [Sheet](corsair_A4_sheet.jpg) | 2 | [Beauty](corsair_A4_beauty.jpg) | 2 |

Eight calls completed without a tool limit. Four pictures were selected. No picture exceeded three tries.
Only built-in image_gen__imagegen made the art. System.Drawing converted to JPEG quality 92 and made TEMP thumbnails for inspection.
No ComfyUI, Blender, Godot render, code-drawn art, API-key fallback or local GPU work was used.
The tool exposes no exact image model ID. [Exact prompts](prompts.md) records all eight calls.

The first H4 sheet aimed the side-view broadside barrels forward. Try 2 fixed the visible muzzle direction but
shortened the top barrels and retained a raised duplicate turret silhouette. Try 3 restored long barrels and removed that silhouette.
H4's third sheet was selected for its readable weapons, with proportion failures retained below.
A4 try 1 used a perspective muzzle array in the top view and a shallow side profile.
Try 2 straightened the tubes, added the command block and deepened the hull; tube counts still drift between views.
The first A4 beauty pointed its far scatter rack across the deck. Try 2 points it outward, but elevates it compared with the sheet.

### H4 gate scores

| # | Gate | Result and visible evidence |
|---:|---|---|
| 1 | Counted, readable weapons | PASS: two matched twin-barrel flank turrets, one massive paired bow ion installation, one compact flak mount. All four are identifiable at 384px sheet width. |
| 2 | Clear firing paths | PASS: top barrels point laterally out; ion and flak point right. Side broadside muzzles face the camera. |
| 3 | One thrust axis, stern engines at 25 to 50 percent | FAIL: all drives are substantial stern rectangles, but the luminous bank appears to occupy more than half the rear face; exact face area cannot be established from these two views. |
| 4 | Continuous spine and break lines | PASS: rectangular modules join the forward wedge through a continuous central structure; three obvious closed transverse joints. |
| 5 | Command and sensors | PASS: one low central command housing, one small flush blue sensor group, separate from flak. |
| 6 | One hangar mouth | PASS: one dark near-flank door in side view, no second mouth or loose drones. |
| 7 | Symmetric structure and guns | PASS: paired heavy turrets and ion prongs balance about the spine; side hangar is the permitted functional opening. |
| 8 | Top first, side confirms | PASS: Kit Wedge identity and all mounts read from above; side view confirms the layout after correction. |
| 9 | Fixed proportions, distinct escort | FAIL: weapon-inclusive beam is too broad for 4.5:1:0.5. Beauty escort has fewer modules and no broadside turrets, but the capital proportions still miss. |
| 10 | One physical detail scale | FAIL: shared hatches and panels are suggested, but beauty escort panel sizing cannot be confirmed as the same real scale. |
| 11 | Space, not sea or air | PASS: flat armoured spine, no keel, mast, rails, funnels, cockpit or wings. |
| 12 | Hegemony grammar and palette | PASS: pale grey modular wedge, exact matching mounts, thin blue strips, rectangular cold drives, no rust or ornament. |

### A4 gate scores

| # | Gate | Result and visible evidence |
|---:|---|---|
| 1 | Counted, readable weapons | PASS: one bow tube cluster dominates the bow, one eight-barrel scatter rack per flank, one small central flak turret. Four deliberate installations; ports dark. |
| 2 | Clear firing paths | PASS on sheet: bow tubes point right; flank racks point straight out; near side rack shows muzzle ends. Beauty correction avoids firing across the deck, but its far rack is elevated. |
| 3 | One thrust axis, stern engines at 25 to 50 percent | FAIL: three chunky stern drives share the axis, but the bank appears to exceed half the stern face. Outer engine housings differ in size; exact thrust balance cannot be verified. |
| 4 | Continuous spine and break lines | PASS: heavy central slab with three closed transverse chain-braced joins. |
| 5 | Command and sensors | PASS: one low brow command block, one grouped pair of listening dishes with adjacent wake scoops. |
| 6 | Two hangar mouths | PASS: paired top-view flank lips and one near-side mouth below its scatter rack; opposite door is hidden in side view. No four-door layout. |
| 7 | Balanced guns and engines | FAIL: scatter racks balance, but mismatched outer engine dimensions do not prove equal thrust; permitted patch asymmetry is present. |
| 8 | Top first, side confirms | FAIL: brick identity is clear from above, but bow launcher has more visible tube rows in top than side, so the two views do not fully describe one object. |
| 9 | Fixed proportions, distinct escort | FAIL: length/beam is close, height remains low and launcher geometry drifts. Pack Hunter escort is leaner with two bow tubes, two engines and one flak, rather than a tiny capital. |
| 10 | One physical detail scale | FAIL: common rivets and patches imply family, but escort hatch/panel dimensions do not establish shared real scale. |
| 11 | Space, not sea or air | PASS: slab hull and folded boarding claws, no keel, crane, mast, rails, funnel or cockpit. |
| 12 | Hullbreaker grammar and palette | PASS: soot, rust, bare steel and old pale paint, dim red lamps, chains and uneven patches; no yellow/olive camouflage. |

### Pixel proportions measured from delivered sheets

Manual pixel bounding-box readings from the final 1536x1024 JPGs, approximately +/-5px.
Length includes weapons and engine housings, beam includes lateral guns, height includes fixed sensors and mounts;
glow is excluded. These measurements describe visible drawings, not a fitted 3D asset.

| Sheet | Requested initial L x B x H | Observed L x B x H | Observed L:B:H normalized to beam |
|---|---|---|---|
| H4 | 1310 x 292 x 146 | about 1418 x 429 x 138 | 3.31:1:0.32 |
| A4 | 1330 x 380 x 342 | about 1479 x 434 x 318 | 3.41:1:0.73 |

H4 top endpoints are about x59..1477, y88..517; side height y697..835.
Its hull body alone is about 230px wide: the long lateral guns substantially widen the armed envelope.
H4's final correction requested a broader 370px armed beam to keep long guns; the result still exceeded that request.
A4 top endpoints are about x26..1505, y104..538; side height about y608..926.
A4's revision requested 1480 x 430 x 370; the returned side remained shallower.
H4 ion prongs are about 275px long; heavy barrels about 100px exposed each.
A4 bow tube cluster is about 230px long and 160px across; scatter barrel projections about 50px.
At 384px sheet width the hull lengths are about 355px and 370px. The paired heavy guns and large bow installations remain visible.
Each beauty shows one separate, simpler escort. H4 escort appears about one third hero length; A4 escort closer to two fifths,
above the requested 32 percent, and retained as a disclosed scale limitation.

### Source provenance for issue 435

Original PNGs remain untouched under:
`C:/Users/rcbai/.codex/generated_images/01a1c93f-fb13-72a2-8b20-f4559d875a5e/`.

| Picture | Original PNG | Reference |
|---|---|---|
| H4 sheet try 1 | exec-3b40efe0-f5be-40e1-ad3b-b331d2fc7fa8.png | contrib/muse/design/concept_round2_2026_11/hegemony_H1_sheet.jpg |
| H4 sheet try 2 | exec-f8f2c8f7-62c7-44d9-a9c1-57bdbcd5f22d.png | H4 try 1 |
| H4 sheet selected | exec-7343970a-10e1-4784-abfb-6c0554019e97.png | H4 try 2 |
| H4 beauty selected | exec-0317a250-1270-4d86-8063-f9bf429cb1d6.png | H4 selected sheet PNG |
| A4 sheet try 1 | exec-784e150f-c454-46a6-892f-b44e6d3d6e3c.png | contrib/muse/design/concept_round2_2026_11/corsair_A1_sheet.jpg |
| A4 sheet selected | exec-0dc8ab16-6f98-4233-a87e-206ba7e75e75.png | A4 try 1 |
| A4 beauty try 1 | exec-2ae70b0c-2747-4cdf-83fa-45180d4909c6.png | A4 selected sheet PNG |
| A4 beauty selected | exec-66d41adf-543f-483f-83e1-866e9c86a867.png | A4 beauty try 1 |

### Board review copies for issue 435

- [H4 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-435/shots/hegemony_H4_sheet.jpg)
- [H4 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-435/shots/hegemony_H4_beauty.jpg)
- [A4 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-435/shots/corsair_A4_sheet.jpg)
- [A4 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-435/shots/corsair_A4_beauty.jpg)

### Issue 435 validation

- Four requested JPGs exist, 1536x1024, each below 700,000 bytes. Inspected full sheets, beauty views and 384px thumbnails.
- Board shots copies match all four delivered JPGs by SHA256.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, 41 PASS, 2 KNOWN, no FAIL or SKIP.
  Known findings: KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5. Oracle drift: 12 baseline constant differences.
- Standing-check log: `%TEMP%/voidsworn-issue-435-standing-checks.log`.
- No separate Godot game capture, GPU render or standalone parity suite: this task is built-in image concepts only.
- JPG format, dimensions, size limits, Markdown without em dashes and git diff --check passed.
- No game or tool source changed. No commit and no push.
