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



# Armed Glasswright and Eclipse concepts, issue #436

Four new pictures made with the built-in image tool from the named Muse references. My pick for further refinement is E4: the crescent remains distinct and its large guns read from above. G4 also reads as armed, but has more unresolved geometry. These are review concepts, not approved build references.

## G4: Cut Hull, armed

[Design sheet](ithar_G4_sheet.jpg) and [beauty view](ithar_G4_beauty.jpg).
The first sheet used Muse's `ithar_G3_sheet.jpg`; corrections used the preceding generated sheet.
The beauty used selected sheet try 2, then a correction removed duplicated flank equipment.
Five installations are visible: two bow iris projectors, two centreline lens turrets, one small aft flak mount.
The escort is a shorter wedge with one optical installation and one small defence mount.

Sheet try 1 was too broad and incorrectly stacked the paired bow lenses above and below in side view.
Try 2 fixed that occlusion but became too narrow. Try 3 returned no picture: the tool rejected its output with
`moderation_blocked`, category `violence`, request ID `fb36f86d-20b3-4a04-be4a-77dbcafa9036`.
No further sheet attempt was made. Selected try 2 is the best available sheet, with the failed lines below left open.
Beauty try 1 duplicated a sensor, command block and flak row on the near flank; try 2 removed that row.

## E4: Crescent, made a warship

[Design sheet](deathless_E4_sheet.jpg) and [beauty view](deathless_E4_beauty.jpg).
The first sheet used Muse's `deathless_E2_sheet.jpg`; each correction used the preceding sheet.
The beauty used selected sheet try 3. Four installations are visible: two twin-barrel gauss turrets in a centreline row,
one large doom cannon at the crescent focus and one small aft flak turret.
The escort is a simpler short fan wedge with one gauss installation and one small flak mount.

Sheet try 1 incorrectly treated the lateral crescent horns as upper and lower horns in side view and skewed the gauss
barrels in plan. Try 2 corrected those. Try 3 broadened the crescent, corrected the stern engine plan and elevated the aft
gauss barrels. One beauty try was needed. Its extra flank equipment panel is not in the sheet and should be removed before
a build; its violet is also brighter under the beauty lighting.

## Issue 436: twelve gate lines

PASS means supported by the visible picture. FAIL includes unresolved or ambiguous geometry.
Each sheet was also inspected as a 320-pixel-wide thumbnail: both read as armed, with the large bow installations and
dorsal turrets visible. Neither image proves internal engineering or exact weapon arcs.

| # | Gate | G4 selected sheet | E4 selected sheet |
|---:|---|---|---|
| 1 | Counted, deliberate mounts; reads armed | PASS: five mounts, dark irises and small flak distinct | PASS: four mounts, large gauss barrels and doom cannon distinct |
| 2 | Clear fields; none backward or into hull | FAIL: aft optical turret is raised slightly, but its horizontal beam still appears to intersect the forward turret | PASS: aft gauss barrels elevate over the forward turret; forward gauss is above the shade; doom points through horn gap |
| 3 | Stern thrust axis; adequate engine group | FAIL: three substantial housings and white rings exist, but ring faces look upward in plan and the lateral arrangement is ambiguous | PASS: three dark housings across stern in plan, one occludes others in side; substantial group on common axis |
| 4 | Continuous spine and break locations | PASS: solid bow-to-stern hull with two transverse structural joins | PASS: thick connected archive spine with two transverse joins |
| 5 | One low command block and sensor | PASS: one low aft block and one flat sensor | PASS: one low aft block and one flat sensor |
| 6 | Hangar door only when required | PASS: no hangar required or drawn | PASS: no hangar required or drawn |
| 7 | Centre-plane symmetry | PASS: bow lens pair and kite plan balanced | PASS: paired crescent horns and stern drives balanced |
| 8 | Designed from above first | PASS: faceted kite and five-mount layout read in plan | PASS: crescent and thick stem read in plan |
| 9 | Fixed class proportions | FAIL: about 5.84:1:0.75 rather than 5:1:0.8 | PASS: about 3.5:1.55:0.55, close to 3.5:1.6:0.6 |
| 10 | Common small-detail scale | PASS: small consistent access panels; beauty escort has fewer parts, similar panel size | PASS: fine plate seams and hatches; beauty escort has fewer parts |
| 11 | Space, not sea or air | PASS: armoured faceted volume, no naval or aircraft parts | PASS: archive hull and lateral shade, no naval or aircraft parts |
| 12 | Faction palette and Never list | PASS: silver facets, white seams and bow, no separate crystal, rivets, wings or petals | FAIL: thin green plate/drive rims and small doom core work, but the sensor also has a green tint, outside the focus-only rule |

G4: 9 PASS, 3 FAIL. E4: 11 PASS, 1 FAIL.
The latest task and R178 override the older separate-crystal Glasswright grammar and thin-hoop Eclipse engine grammar.
G4's top still shows lens faces that a strict orthographic camera should hide. E4's side horn curvature is approximate.
Do not trace these as mechanically exact plans. The Board must resolve the failed lines before build approval.

## Issue 436: pixel measurements

Approximate manual bounds on the final 1536 x 1024 JPGs, uncertainty about 4 pixels per edge.
Length includes engine housing and forward weapons, excludes glow. Height includes dorsal mounts.
Targets were stated in pixels in the prompts; the following records the actual output rather than those targets.

| Sheet | Requested L/B/H px | Plan x bounds | Plan y bounds | Side y bounds | Actual L/B/H px | Normalised |
|---|---|---|---|---|---|---|
| G4 | 1416 / 283 / 227 | 78 to 1462 | 191 to 428 | 670 to 847 | 1384 / 237 / 177 | 5.84:1:0.75 |
| E4 | 1376 / 629 / 236, final correction 1440 / 660 / 246 | 45 to 1495 | 19 to 660 | 702 to 930 | 1450 / 641 / 228 | 3.5:1.55:0.55 |

Both views broadly share longitudinal endpoints. G4's bow installations are about 180 px long including mounts;
its large turrets occupy about 130 px each, flak about 65 px. E4's doom assembly occupies about 360 px from focus to muzzle;
gauss base plus barrels about 200 px each, flak about 65 px. The distinctions survive the thumbnail check.
Escort scale and panel consistency are visual judgements from perspective paintings, not calibrated dimensions.

## Issue 436: tool and provenance

Nine built-in tool calls were attempted: eight returned pictures, one rejected its output. No quota or usage-limit error.
No image exceeded three attempts. No API fallback, ComfyUI, Blender, Godot render or code-drawn art.
System.Drawing converted the original 1536 x 1024 PNGs to JPEG quality 92 and made temporary thumbnails for inspection;
it did not alter the artwork. The tool exposes no exact image-model identifier.
[Exact prompts](prompts.md) records all nine calls, including the rejected one.

Originals remain untouched under
`C:/Users/rcbai/.codex/generated_images/01a1c94a-d3a2-7781-820e-baee4912a273/`.

| Output or earlier try | Original PNG basename |
|---|---|
| G4 sheet try 1 | exec-6eef7db0-44c8-4ca5-aa3f-838ae124895a.png |
| ithar_G4_sheet.jpg, try 2 | exec-dd39531c-4566-4b9d-a431-8d01b87224d8.png |
| G4 beauty try 1 | exec-a8f1c537-5161-4157-be29-4db82a29d8fe.png |
| ithar_G4_beauty.jpg, try 2 | exec-d7e863b5-7d0d-4767-96d9-5f1427a845cf.png |
| E4 sheet try 1 | exec-c97dbcfd-435b-4c22-9622-18c814d37582.png |
| E4 sheet try 2 | exec-4b9abc66-61fd-4e0a-8d7c-db654e2a6487.png |
| deathless_E4_sheet.jpg, try 3 | exec-d3d74dda-a340-46c9-9db8-f18ff040ff98.png |
| deathless_E4_beauty.jpg, try 1 | exec-840484ab-b220-4fdf-bfa7-37026a7d08ae.png |

## Issue 436: Board copies and checks

- [G4 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-436/shots/ithar_G4_sheet.jpg)
- [G4 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-436/shots/ithar_G4_beauty.jpg)
- [E4 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-436/shots/deathless_E4_sheet.jpg)
- [E4 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-436/shots/deathless_E4_beauty.jpg)

All four are 1536 x 1024 JPGs under 700,000 bytes: G4 sheet 135,715; G4 beauty 183,278;
E4 sheet 257,478; E4 beauty 246,050. Board copies match by SHA256.
`node contrib/opus/tools/run_all_checks.js` exited 0: 41 PASS, 2 KNOWN, no FAIL or SKIP.
KNOWN: findings_tests has seven listed failures; oracle_drift_guard has twelve baseline constant differences.
Log: `%TEMP%/voidsworn-issue-436-standing-checks.log`.
Final format, dimensions, size, thumbnail views, changed text without em dashes and `git diff --check` were checked.
Separate Godot parity/game suites and GPU captures were skipped because this job changes concept art and notes only.
No game or tool source changed. No commit and no push.

