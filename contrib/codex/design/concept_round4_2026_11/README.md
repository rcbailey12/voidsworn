# Round 4 concepts, issue 468

Ten pictures made with the built-in image tool from the named references. My strongest result is S7: the requested seven heavy barrels per side and four paired flak turrets are retained in the sheet and beauty. H7 preserves the selected wedge and twin rails with more surface structure. E7 has its own upright broken ring, G7 returns to a clear glass body, and A7 restores the original patched salvage mass.

These are selected review concepts, not cleared build references. All five retain at least one gate failure after the allowed sheet attempts. The scores below distinguish each sheet from its beauty.

## Pictures and Board copies

All review links below point to the required Board shots folder. Identical JPGs are also in this deliver folder.

| Ship | Sheet | Beauty |
|---|---|---|
| Sunward S7 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/voidsworn_S7_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/voidsworn_S7_beauty.jpg) |
| Hegemony H7 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/hegemony_H7_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/hegemony_H7_beauty.jpg) |
| Eclipse E7 cruiser | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/deathless_E7_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/deathless_E7_beauty.jpg) |
| Glasswright G7 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/ithar_G7_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/ithar_G7_beauty.jpg) |
| Hullbreaker A7 | [sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/corsair_A7_sheet.jpg) | [beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-468/shots/corsair_A7_beauty.jpg) |

## Method and attempts

Built-in `image_gen.imagegen` only, 21 completed image calls. No API fallback, ComfyUI, Blender, Godot rendering or code-drawn artwork. Pillow converted the C19 WEBP reference to PNG in TEMP and resized/encoded the final JPGs at quality 92. Original generated PNGs were left untouched under `C:/Users/rcbai/.codex/generated_images/01a1caa2-5b55-7521-824d-9f319078a3ad/`.

[Exact prompts and all source PNG paths](prompts.md) records every image call, including rejected attempts. Each beauty used its selected sheet, and beauty corrections also used that sheet.

| Ship | Sheet tries | Beauty tries | What changed or failed |
|---|---:|---:|---|
| S7 | 2 | 1 | First sheet had six top gallery barrels versus seven side muzzles, and three side flak silhouettes. Second has seven per flank, four top flak turrets and two overlapping side silhouettes. |
| H7 | 3 | 1 | First sheet aimed heavy turrets forward and stacked rails in side. Second fixed arcs but introduced a central engine tongue. Third restores two rails and four engines, but flak still moves between projections. Beauty follows the top layout. |
| E7 | 3 | 2 | First sheet too slender with stacked side engines; second broadens hull and corrects engine occlusion. Third requested equal ring diameters but did not achieve them. First beauty duplicated the entire dorsal row onto the flank; second removes it. |
| G7 | 3 | 1 | First sheet tapered like a wedge, second was a parallel bar but about 8:1. Third improves length/beam and forward lens housing, but end-cap projections remain inconsistent and the prism is still too slender. |
| A7 | 3 | 2 | First sheet had roof-facing racks/bays and stacked engines. Second fixes rack direction and side bays but adds two extra engine tips. Third has three engines. First beauty stacked both bays on one flank; second leaves one near bay, with the far bay occluded. |

The named FINDINGS R180 is absent from this checkout; its rulings are quoted directly in CODEX_TASK.md, which supplies this round's authority. The newer full-prism G7, dark-drive-cone E7, paired flak S7 and patched-block A7 instructions override older faction grammar where they differ.

## Pixel proportions

Manual solid silhouette measurements on delivered JPGs, approximately +/-8 pixels per edge. Length includes fixed weapons and engine housings, excludes light bloom. Beam includes projecting guns and bow ring. Height includes radiators, turrets and ring. Perspective beauty views are not dimension references.

| Sheet | Requested L/B/H px | Top x bounds | Top y bounds | Side y bounds | Measured L/B/H px | L:B:H |
|---|---|---|---|---|---|---|
| S7 | 1440/288/202 | 27..1510 | 175..469 | 615..831 | 1483/294/216 | 5.04:1:0.73 |
| H7 | Initially 1400/311/156; final prompt 1400/360/156 | 79..1488 | 121..590 | 761..903 | 1409/469/142 | 3.00:1:0.30 |
| E7 | 1400/400/400; final requested ring span 416 | 42..1512 | 60..476 | 574..937 | 1470/416/363 | 3.53:1:0.87 |
| G7 | 1400/280/280 | 81..1457 | 224..461 | 621..820 | 1376/237/199 | 5.81:1:0.84 |
| A7 | 1400/400/360 | 55..1490 | 102..528 | 596..898 | 1435/426/302 | 3.37:1:0.71 |

Top and side horizontal endpoints agree approximately within 1 percent on each selected sheet. That does not make their end-cap or mount projections mechanically consistent.

H7's hull-only beam is about 266 px, roughly 5.30:1; the outward turbolaser barrels expand its total beam to 469 px. That distinction is reported, not used to claim the 4.5:1:0.5 target passed. E7's nominally circular upright ring spans 416 px in plan and 363 px in elevation, a roughly 13 percent disagreement. G7 remains about 16 percent too slender, with height smaller still. A7 has the desired short heavy plan but insufficient height relative to beam.

## Twelve gate lines, each picture

PASS means visibly supported at concept level. FAIL includes unresolved geometry. These scores do not establish interiors, mechanical joints, exact engine aperture area or build readiness. Each sheet was inspected at delivery size and at 384 px width. All five read as armed in the top thumbnail. Beauty gate 9 inherits unresolved sheet proportions even where the escort is correct.

### S7

| # | Gate | Sheet | Beauty | Evidence or failure |
|---|---|---|---|---|
| 1 | Counted weapons; visibly armed | PASS | PASS | Seven heavy gallery barrels each flank, one large bow lance, four small twin flak turrets in two pairs. Dark mouths. |
| 2 | Clear arcs, no backward guns | PASS | PASS | Lance and flak forward; gallery barrels outward clear of hull. |
| 3 | One stern thrust axis | PASS | PASS | Two substantial lateral ember engine bells; side correctly overlaps the far bell. |
| 4 | Spine and authored break lines | FAIL | FAIL | Continuous iron backbone, but no unambiguous two or three authored narrow break locations. Existing panel seams do not prove them. |
| 5 | One command and one sensor | FAIL | FAIL | Single low command block; a distinct sensor cluster is not legible. Kept the reference layout as instructed. |
| 6 | Hangar doors | PASS | PASS | None required or added. |
| 7 | Symmetry | PASS | PASS | Matched broadside batteries, flak pairs and engines. |
| 8 | Top first, identity and agreement | PASS | PASS | Rear-wide dagger and radiator bank; sheet projections agree on weapon positions/counts. |
| 9 | Proportions and distinct escort | PASS | PASS | About 5.04:1:0.73. Beauty escort is a narrow single-engine spear, three near gallery guns and no four-turret array. |
| 10 | One detail scale | PASS | PASS | Fine rivets, hatches and scratches; escort has fewer parts at broadly comparable detail scale. |
| 11 | Space, not sea or air | PASS | PASS | Armoured blade and machinery bank, no keel, mast, aircraft wings or railings. |
| 12 | Faction colours and Never list | PASS | PASS | Black iron, chalk-like frost white and ember; no rust, blue light or religious statues. |

Sheet: 10 PASS, 2 FAIL. Beauty: 10 PASS, 2 FAIL.

### H7

| # | Gate | Sheet | Beauty | Evidence or failure |
|---|---|---|---|---|
| 1 | Counted weapons; visibly armed | PASS | PASS | Two heavy twin turrets, bow ion-prong pair, one small flak. Side flak is less resolved than top. |
| 2 | Clear arcs, no backward guns | PASS | PASS | Heavy turrets outboard, ion forward, no hull-obstructed barrels. |
| 3 | One stern thrust axis | PASS | PASS | Four blocks, two per rail; selected side overlaps laterally. |
| 4 | Spine and break lines | PASS | PASS | Wedge forks into connected parallel rails per brief; repeated transverse module joints. |
| 5 | One command and sensor | PASS | PASS | One low command wedge and flat sensor patch ahead of flak. |
| 6 | One hangar door | PASS | PASS | One recessed dark door at forward end of inter-rail gap. |
| 7 | Symmetry | PASS | PASS | Matched rails, engines, turrets and prongs. |
| 8 | Top first, identity and agreement | FAIL | PASS | Sheet flak is amidships in top, aft in side. Beauty follows top and clearly carries the wedge/twin-rail plan. |
| 9 | Proportions and distinct escort | FAIL | FAIL | Total beam too wide and elevation too low. Escort is correctly a short single-spine modular wedge, not twin-rail hero shrunk. |
| 10 | One detail scale | PASS | PASS | Repeated hatch rows and panels; capital has more modules than escort. |
| 11 | Space, not sea or air | PASS | PASS | No mast, sail, yacht decks or fins; rails are structural hull beams. |
| 12 | Faction colours and Never list | PASS | PASS | Pale grey, blue-grey accents, blue joint/rail light, no rust, warm light or ornament. |

Sheet: 10 PASS, 2 FAIL. Beauty: 11 PASS, 1 FAIL.

### E7, the Annulus cruiser

| # | Gate | Sheet | Beauty | Evidence or failure |
|---|---|---|---|---|
| 1 | Counted weapons; visibly armed | PASS | PASS | Doom F, two upper centreline twin gauss turrets, one small sentry. Corrected beauty has no flank weapon row. |
| 2 | Clear arcs, no backward guns | PASS | PASS | Doom projects through hub; elevated gauss barrels plausibly clear front installation/ring, though exact arcs need a build. |
| 3 | One stern thrust axis | PASS | PASS | Three dark cones, thin exit rims, horizontal top arrangement overlaps as one cone in side. |
| 4 | Spine and break lines | PASS | PASS | Real scaled hull through hub; two transverse collars behind ring. |
| 5 | One command and sensor | PASS | PASS | Low archive command housing and small green-faced sensor patch. |
| 6 | Hangar doors | PASS | PASS | None required or added. |
| 7 | Symmetry | PASS | PASS | Centreline guns and core, balanced ring sectors and engine group. |
| 8 | Top first, identity and agreement | FAIL | PASS | Sheet ring is correctly edge-on, but reads as a crossbar at thumbnail rather than the Annulus identity. Beauty reveals the upright circular broken ring. |
| 9 | Proportions and distinct escort | FAIL | FAIL | Near 3.5:1 in plan, but ring diameters disagree between projections. Escort is a simpler short fan wedge without ring or doom cannon. |
| 10 | One detail scale | PASS | PASS | Repeated scale plates and fewer same-family installations on escort. |
| 11 | Space, not sea or air | PASS | PASS | Shade frame, real hull and drive cones; no naval fittings or aircraft shape. |
| 12 | Faction colours and Never list | PASS | PASS | Violet-black scales, thin green-white rims and small bright core; no skulls, bone, pooled green or flame. |

Sheet: 10 PASS, 2 FAIL. Beauty: 11 PASS, 1 FAIL. The ring is this cruiser's own feature, not a new flagship assignment.

### G7, Long Prism

| # | Gate | Sheet | Beauty | Evidence or failure |
|---|---|---|---|---|
| 1 | Counted weapons; visibly armed | PASS | PASS | Two bow iris housings, large top iris turret, conventional gun, small flak in the specified order. |
| 2 | Clear arcs, no backward guns | PASS | PASS | Forward lens housings and gun barrels; top beam carries unobstructed installations. |
| 3 | One stern thrust axis | FAIL | FAIL | Three stern rings are present, but their faces are shown nearly head-on from incompatible viewpoints. Their triangular layout is not a reliable thrust-axis drawing. |
| 4 | Spine and break lines | PASS | PASS | Continuous longitudinal frame with two intermediate rib/collar seams. |
| 5 | One command and sensor | PASS | PASS | One low command housing and adjacent smaller sensor unit aft. |
| 6 | Hangar doors | PASS | PASS | None required or added. |
| 7 | Symmetry | PASS | PASS | Intended triangular section and lateral bow pair; end-cap projection errors remain under lines 3 and 8. |
| 8 | Top first, identity and agreement | FAIL | PASS | Glass-bar identity is clear, but sheet end-cap faces are perspective and the side repeats both bow lenses and all three rings rather than correct occlusion. Beauty clearly shows the triangular glass-body route. |
| 9 | Proportions and distinct escort | FAIL | FAIL | About 5.81:1:0.84, still too slender/low. Escort has one bow lens, one defence gun and one drive ring, not the capital's five-weapon layout. |
| 10 | One detail scale | PASS | PASS | Small silver hardware and fewer ribs/mounts on escort; exact physical sizes remain concept estimates. |
| 11 | Space, not sea or air | PASS | PASS | Frame, optics and caps, no wings, petals, insects or sea details. |
| 12 | Faction colours and Never list | PASS | PASS | Body is clear glass with internal warm-white light, silver frame and edge-only rainbow. No opaque grey crystal hull. |

Sheet: 9 PASS, 3 FAIL. Beauty: 10 PASS, 2 FAIL. The glass-body route lands more clearly than G4, but this is not an orthographic build plan.

### A7, patched Pyre-Barge

| # | Gate | Sheet | Beauty | Evidence or failure |
|---|---|---|---|---|
| 1 | Counted weapons; visibly armed | PASS | PASS | One short-tube scatter rack per flank, one large prow torpedo cluster and one top flak. Far rack partly occluded in beauty. |
| 2 | Clear arcs, no backward guns | PASS | PASS | Scatter tubes outward/slightly forward, torpedoes forward, no rear-facing weapons. |
| 3 | One stern thrust axis | PASS | PASS | Exactly three main cones: big centre, smaller balanced pair; near side cone overlaps central cone in elevation. |
| 4 | Spine and break lines | PASS | PASS | Continuous central hulk crossed by two chained transverse hull-section joins. |
| 5 | One command and sensor | PASS | PASS | Low armoured command block and one listening dish/scoop cluster. |
| 6 | Two side hangar doors | PASS | PASS | Sheet side has one aft doorway; top has two edge recesses. Corrected beauty has one near doorway, far-side partner hidden. |
| 7 | Balanced main guns/engines | PASS | PASS | Salvage plates vary by side; main rack mounts and stern engines remain balanced in plan. |
| 8 | Top first, identity and agreement | FAIL | PASS | Top carries irregular salvage silhouette, but sheet retains perspective faces on end caps and equipment. Beauty carries the selected patched block route. |
| 9 | Proportions and distinct escort | FAIL | FAIL | Plan near 3.5:1, height only about 0.71 beam versus 0.9. Escort is leaner, with fewer slabs/tubes, two engines and no hangars. |
| 10 | One detail scale | PASS | PASS | Repeated bolts, tank seams and plate patches; escort has fewer blocks and racks. |
| 11 | Space, not sea or air | PASS | PASS | Blunt plate ram, thick belly, vents in place of funnels; no mast, keel, rails or boat stem. |
| 12 | Faction colours and Never list | PASS | PASS | Red oxide, black iron, bare steel, dim red light. No yellow/olive/green camouflage. |

Sheet: 10 PASS, 2 FAIL. Beauty: 11 PASS, 1 FAIL. Stepped salvage hull blocks are intentional per this brief, rather than naval cabin decks.

## File checks and validation

| JPG | Dimensions | Bytes |
|---|---|---:|
| voidsworn_S7_sheet.jpg | 1536 x 1024 | 234750 |
| voidsworn_S7_beauty.jpg | 1536 x 768 | 201052 |
| hegemony_H7_sheet.jpg | 1536 x 1124 | 202212 |
| hegemony_H7_beauty.jpg | 1536 x 1124 | 250173 |
| deathless_E7_sheet.jpg | 1536 x 1024 | 297238 |
| deathless_E7_beauty.jpg | 1536 x 512 | 172586 |
| ithar_G7_sheet.jpg | 1536 x 1024 | 228717 |
| ithar_G7_beauty.jpg | 1536 x 768 | 179677 |
| corsair_A7_sheet.jpg | 1536 x 1024 | 433865 |
| corsair_A7_beauty.jpg | 1536 x 1024 | 424528 |

- Ten readable JPGs, longest side exactly 1536, all below 700,000 bytes, five sheets and five beauties. Each beauty has exactly one distinct escort.
- Board copies checked by SHA256 against all ten delivered JPGs.
- `node contrib/opus/tools/run_all_checks.js`: exit 0, 41 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. Known findings: KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5; oracle drift guard: 12 baseline constant differences.
- Standing-check log: `%TEMP%/voidsworn-issue-468-standing-checks.log`.
- Changed Markdown checked for em dashes and trailing whitespace; JPG structure, dimensions and sizes validated.
- No separate Godot render, rules parity run or GPU capture: this task changes concept art and notes only. The required standing pack ran its own checks.
- Added only the ten JPGs, prompts.md and this README under the requested new folder. CODEX_TASK.md was already untracked and left untouched.
- No commit and no push. No files outside the checkout were deleted or moved; only the required Board picture copies were added there.
