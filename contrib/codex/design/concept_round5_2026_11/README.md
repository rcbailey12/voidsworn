# Round 5 concepts, issue 475

Eight requested pictures, four sheets and four beauties, plus a silhouette contact picture. All ship artwork came from the built-in image tool using the named references. No commit or push.

My pick is S8. Its fork and recessed emitter retain S7's ordered batteries without a nose barrel. H8 is visibly heavier, E8 finally reads as a flat broken ring, and A10 has deck rockets and larger salvage steps. These are review concepts, not cleared build references. Remaining gate failures are marked below, including E8's seven plates rather than the required eight to ten.

## Pictures

These links point to the required Board shots folder. Matching JPGs are in this deliver folder.

| Ship | Sheet | Beauty |
|---|---|---|
| Sunward S8 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/voidsworn_S8_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/voidsworn_S8_beauty.jpg) |
| Hegemony H8 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/hegemony_H8_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/hegemony_H8_beauty.jpg) |
| Eclipse E8 cruiser | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/deathless_E8_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/deathless_E8_beauty.jpg) |
| Hullbreaker A10 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/corsair_A10_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/corsair_A10_beauty.jpg) |

![Four top silhouettes, S8 H8 E8 A10 left to right](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-475/shots/top_silhouettes.jpg)

The contact uses extracted top-view pixels converted to black on grey, each fitted inside a 350 px square with uniform scaling. It compares outlines, not physical ship size. No hull outline was invented or redrawn. Small extraction irregularities remain at dark edges. Left to right: forked blade, open twin-rail wedge, broken ring, irregular stepped blocks. No pair can be confused as black shapes. This comparison was inspected before the beauty calls.

## Method and attempts

[Exact prompts and source PNG paths](prompts.md). Built-in image tool only, 21 completed calls. Pillow converted C19 WEBP to PNG in TEMP, resized and encoded JPGs, and extracted/composited the contact. No ComfyUI, Blender, Godot renders, API fallback or code-drawn ships. Originals remain untouched under the tool's generated-images folder.

| Ship | Sheet tries | Beauty tries | Selection and failures |
|---|---:|---:|---|
| S8 | 2 | 1 | Sheet 1 wrongly drew the horizontal fork in side elevation. Sheet 2 overlaps the blades correctly. Beauty retains seven guns per flank and four flak turrets. |
| H8 | 3 | 3 | Sheet 1 stayed slender. Sheet 2 is the strongest heavy version, selected despite proportions and side errors. Sheet 3 collapsed the rails, lost a shoulder turret and put four engines on one bar, rejected. Beauty 1 added a round turret; beauty 2 retained it and pointed a gun aft; beauty 3 removes it and fixes directions. |
| E8 | 3 | 3 | Sheet corrections shorten the doom housing and flatten the ring elevation, but engine cones remain serial and only seven shade segments were drawn. Beauty 2 restores three lateral engine cones and a sentry; beauty 3 removes perimeter links. Some plates still lack visible support. |
| A10 | 3 | 3 | Sheet 1 was a long bar with racks in a row and two near bays. Sheet 2 pairs the racks but remains slender. Sheet 3 compresses the hull and enlarges steps, selected. Beauty 1 aimed both racks alike; beauty 2 turned the far rack aft; beauty 3 turns its mouth toward the far flank. |

FINDINGS R183 is absent from this checkout, whose registry ends at R182. CODEX_TASK.md supplies Ryan's round 4 quote and the two replacement rules. Those instructions override older nose-gun, upright-ring and slender-Hegemony grammar. No other files were changed to reconcile that history.

## Measured proportions

Manual solid-edge measurements on delivered JPGs, approximately +/-8 px per edge. Length includes fixed hull, engine housings and weapons, excludes bloom. Beam includes guns; height includes radiators and turrets. Body-only measurements are reported separately where the brief specifies armour thickness. Beauties are perspective illustrations, not dimension references.

| Ship | Requested L/B/H px in prompts | Top x / y bounds in delivered JPG | Side y bounds | Measured L/B/H px | Ratio L:B:H |
|---|---|---|---|---|---|
| S8 | First 1390/360/240; preserve S7 body, change bow only | 27..1477 / 175..466 | 615..831 | 1450/291/216 | 4.98:1:0.74 |
| H8 | Final target 1400/500 overall, hull beam 450, armour height 112 | 98..1441 / 14..694 | 725..983 | 1343/680/258 | 1.97:1:0.38 |
| E8 | First 1235/950; overall about 1.3:1, ring width 80% length | 61..1394 / 23..1156 | about 1286..1403 | 1333/1133/117 | 1.18:1:0.10 |
| A10 | Final 1400/440/360 | about 314..1216 / 5..267 | about 278..501 | 902/262/223 | 3.44:1:0.85 |

H8 body-only beam is about 520 px, giving 2.58:1 length/beam. Shoulder barrels expand it to 680 px, well short of the requested roughly 3:1 overall. Its armour body is about 171 px deep versus the requested quarter of hull beam, about 130 px. It is heavier, but line 9 fails. The selected sheet's rails are roughly one-third of wedge width.

E8's outer ring is about 1133 px wide vertically on the page, around 85% of overall length, and about 1040 px across horizontally. It is slightly oval and the overall ship is shorter/wider than 1.3:1. Top and side endpoints differ by roughly 3%. A10 is within about 6% of its requested height/beam but the projections are not a reliable build plan.

## Twelve gate lines

PASS means supported at concept level; FAIL includes unreadable or unproven required features. Counts below score each of the eight delivered pictures. Hidden far-side parts are not claimed as independently verified. All top views were also inspected at about 350 px width and read as armed. Interiors and exact mechanical construction cannot be established from these images.

### Sunward S8

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted weapons, armed read | PASS | PASS | Seven short heavy barrels each flank, four paired flak, recessed lance emitter. Dark ports. |
| 2 | Clear arcs, nothing backward | PASS | PASS | Heavy batteries outward, flak forward, emitter between bow halves. |
| 3 | Stern thrust axis | PASS | PASS | Two large stern bells; one overlaps in elevation. |
| 4 | Spine and break lines | FAIL | FAIL | Continuous iron hull, but no two or three unmistakable authored break locations. |
| 5 | Command and sensor | FAIL | FAIL | Low command block retained; distinct sensor cluster not legible. |
| 6 | Hangar doors | PASS | PASS | None required or added. |
| 7 | Symmetry | PASS | PASS | Paired batteries, flak, engines and prow blades. |
| 8 | Top identity, projection agreement | PASS | PASS | Clear open fork; corrected side overlaps the horizontal blade halves. |
| 9 | Proportions, distinct escort | PASS | PASS | S7-like body preserved; escort has one bell, three near gallery guns, one flak and a short radiator bank. |
| 10 | Shared detail scale | PASS | PASS | Comparable rivets and marks; fewer installations on escort. |
| 11 | Space, not sea or air | PASS | PASS | Armoured blade, heat radiators, no naval fittings. |
| 12 | Faction sheet | PASS | PASS | Black iron, chalk marks, ember light; no rust or blue. |

Sheet 10 PASS, 2 FAIL. Beauty 10 PASS, 2 FAIL.

### Hegemony H8

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted weapons, armed read | PASS | PASS | Two heavy twin shoulder turrets, one small flak, flush ion trench. Final beauty removes extra round installation. |
| 2 | Clear arcs, nothing backward | PASS | PASS | Top barrels outward; final beauty barrels clear opposing shoulders. |
| 3 | Stern thrust axis | FAIL | PASS | Top has four blocks, two per rail; side wrongly stacks two visible blocks vertically. Beauty restores transverse groups. |
| 4 | Spine and break lines | PASS | PASS | Joined wedge and structural rails, transverse module joints. |
| 5 | Command and sensor | FAIL | FAIL | One low angular command housing, but a separate sensor cluster is not clearly identifiable. |
| 6 | Hangar doors | PASS | PASS | One dark mouth at front of rail gap. |
| 7 | Symmetry | PASS | PASS | Paired rails, shoulder turrets and four engine blocks in top/beauty. |
| 8 | Top identity, projection agreement | FAIL | PASS | Sheet shifts flak longitudinally and has an incorrect engine elevation; beauty follows selected top arrangement. |
| 9 | Proportions, distinct escort | FAIL | FAIL | Heavy but overall 1.97:1 including guns, hull 2.58:1; armour too deep. Escort correctly uses a short single spine and one gun. |
| 10 | Shared detail scale | PASS | PASS | Repeated machined panels and hatch rows; fewer escort modules. |
| 11 | Space, not sea or air | PASS | PASS | Structural rails and armour belts, no mast or yacht tower. |
| 12 | Faction sheet | PASS | PASS | Pale grey, blue trim and lighting, no warm light or rust. |

Sheet 8 PASS, 4 FAIL. Beauty 10 PASS, 2 FAIL.

### Eclipse E8 cruiser

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted weapons, armed read | PASS | PASS | Two twin gauss turrets, one small stern sentry, one green doom aperture. |
| 2 | Clear arcs, nothing backward | PASS | PASS | Gauss elevated above spine, forward aperture in ring gap, no aft gun. |
| 3 | Stern thrust axis | FAIL | PASS | Sheet puts three cones in a serial row along the spine. Final beauty uses three lateral dark nozzles. |
| 4 | Spine and break lines | FAIL | FAIL | Spine collars present, but several separate plates have no visible structural connection. |
| 5 | Command and sensor | PASS | PASS | Low aft housing and small green-faced sensor patch. |
| 6 | Hangar doors | PASS | PASS | None required or added. |
| 7 | Symmetry | PASS | PASS | Balanced ring halves and centreline guns/core at concept level. |
| 8 | Top identity, projection agreement | FAIL | FAIL | Flat broken-ring identity succeeds, but only SEVEN shade plates versus eight to ten. Sheet retains a tube-like elevation and engine mismatch; beauty still has unsupported sectors. |
| 9 | Proportions, distinct escort | FAIL | FAIL | About 1.18:1 overall, ring mildly oval; beauty inherits unresolved sheet dimensions. Escort correctly has three plates forming a half ring and fewer weapons. |
| 10 | Shared detail scale | PASS | PASS | Similar plate scales and turret hardware; fewer escort parts. |
| 11 | Space, not sea or air | PASS | PASS | Flat shade plates and drive block, no bones, sea fittings or vertical spinning top. |
| 12 | Faction sheet | PASS | PASS | Dark violet scales, thin green-white rims and brightest small core; no pooled light or flames. |

Sheet 8 PASS, 4 FAIL. Beauty 9 PASS, 3 FAIL. Final beauty removes the inter-plate perimeter links but does not solve all plate support. It is the ring cruiser, not a replacement flagship.

### Hullbreaker A10

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted weapons, armed read | PASS | PASS | Two huge deck rocket boxes, one flak, four small flush bow torpedo mouths. Grid launchers dominate deck. |
| 2 | Clear arcs, nothing backward | FAIL | PASS | Sheet does not clearly establish opposite firing directions; final beauty turns far rack toward far flank and leaves near rack outward. |
| 3 | Stern thrust axis | FAIL | PASS | Sheet repeats all three engine cones in side elevation as a vertical stack. Beauty has big centre bell and smaller balanced pair. |
| 4 | Spine and break lines | PASS | PASS | Continuous salvage hulk, two chained transverse joins. |
| 5 | Command and sensor | PASS | PASS | One low command block and one listening dish cluster. |
| 6 | Hangar doors | PASS | PASS | One near-side door visible in elevation/beauty; opposite door is hidden, not separately proven. |
| 7 | Main weapons and engines balance | PASS | PASS | Paired main rack stations across spine, big centre engine and matched outer pair; skins deliberately uneven. |
| 8 | Top identity, projection agreement | FAIL | FAIL | Stepped salvage outline succeeds, but top shows near-frontal torpedo mouths and equipment perspective; beauty uses corrected launcher/engine geometry. |
| 9 | Proportions, distinct escort | PASS | PASS | About 3.44:1:0.85. Escort has two hull blocks, one small rack, two engines, no hangar, two flush torpedo mouths. |
| 10 | Shared detail scale | PASS | PASS | Comparable bolts/tank seams, fewer escort sections and installations. |
| 11 | Space, not sea or air | PASS | PASS | Hull-block steps, no masts, funnels, deck rails, keel or boat stem. |
| 12 | Faction sheet | PASS | PASS | Red oxide, black iron, bare steel, old pale-grey section, chains/tanks, dim red light. No yellow/olive/green. |

Sheet 9 PASS, 3 FAIL. Beauty 11 PASS, 1 FAIL.

## Two new rules, each ship

| Ship | Rule 1: faction bow weapon, no tip barrel/prongs | Rule 2: different top outline |
|---|---|---|
| S8 | PASS sheet/beauty. Recessed ember source in deep fork between broad armour blades, no projecting gun. The fork is hull, not weapon prongs. | PASS. Rear-wide split blade and short side barrels. |
| H8 | PASS sheet/beauty. Blunt armour face with recessed blue ion strip, shoulder guns carry armed look. | PASS. Broad wedge ahead of two open rails. |
| E8 | PASS sheet/beauty. Short green aperture inside front ring gap, no long nose barrel. | PASS. Entire flat broken annulus, despite seven-plate failure. |
| A10 | PASS sheet/beauty. Ram armour and four small flush torpedo mouths, no nose pipes. | PASS. Stepped offset salvage mass, rockets on deck. |

All four outlines differ in the inspected contact. The nose rule passes independently of the other gate failures.

## Validation

| JPG | Dimensions | Bytes |
|---|---|---:|
| voidsworn_S8_sheet.jpg | 1536 x 1024 | 235829 |
| voidsworn_S8_beauty.jpg | 1536 x 1024 | 297973 |
| hegemony_H8_sheet.jpg | 1536 x 1024 | 309812 |
| hegemony_H8_beauty.jpg | 1536 x 512 | 214246 |
| deathless_E8_sheet.jpg | 1536 x 1536 | 326168 |
| deathless_E8_beauty.jpg | 1536 x 864 | 202548 |
| corsair_A10_sheet.jpg | 1536 x 512 | 192147 |
| corsair_A10_beauty.jpg | 1536 x 864 | 327279 |
| top_silhouettes.jpg | 1536 x 430 | 32976 |

- PASS: eight requested pictures plus contact, valid JPEGs, longest side exactly 1536, each below 700,000 bytes. Each beauty has exactly one distinct smaller escort.
- PASS: all nine Board copies match their deliver-folder originals by SHA256.
- PASS: each ship has twelve scored gate rows, separate sheet/beauty totals and both new rules; actual pixel measurements and every image prompt recorded.
- PASS: Markdown has no em dashes or trailing whitespace.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, 41 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. Known findings: KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5. Oracle drift guard: 12 baseline constant differences. Log: `%TEMP%/voidsworn475_standing.log`.
- No separate Godot render, GPU run or additional game checks: only concept artwork and notes changed; the requested standing pack ran.
- All repository additions are under this new folder: nine JPGs, prompts.md and README.md. Existing untracked CODEX_TASK.md was left untouched. Scratch scripts and logs are in TEMP. Only the explicitly requested Board JPG copies were added outside the checkout; nothing was deleted or moved there.
- No commit and no push. No changes to game source or prior concepts.

