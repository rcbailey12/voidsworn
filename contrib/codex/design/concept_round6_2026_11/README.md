# Concepts round 6, issue 483

Six pictures refine H8, A11 and G11/G9 using the built-in image tool. H9 has low short-barrel mounts; A13 removes all hanging objects and the boat profile; G13 combines a leaf plan with prismatic glass and three large lenses. These are review candidates, not clean gate passes or build-ready plans. The Glasswright side section still fails the equal-curvature requirement.

## Pictures

The code names in these links identify each picture. Source sheets deliberately have no text, as required.

| Ship | Design sheet | Beauty with one distinct escort |
|---|---|---|
| hegemony_H9 | [H9 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-483/shots/hegemony_H9_sheet.jpg) | [H9 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-483/shots/hegemony_H9_beauty.jpg) |
| corsair_A13 | [A13 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-483/shots/corsair_A13_sheet.jpg) | [A13 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-483/shots/corsair_A13_beauty.jpg) |
| ithar_G13 | [G13 sheet](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-483/shots/ithar_G13_sheet.jpg) | [G13 beauty](C:/Users/rcbai/Downloads/voidsworn_test/board/issue-483/shots/ithar_G13_beauty.jpg) |

## Method and attempts

[Exact prompts and selected original PNG paths](prompts.md). References were inspected before generation. Sheets came first; beauties use the selected third sheet. Selection accepts a sheet as the strongest reference for the beauty, not as passing every gate. No changes outside this new repository folder. No commit or push.

| Ship | Sheet tries | Beauty tries | Corrections and remaining failures |
|---|---:|---:|---|
| H9 | 3 | 2 | First guns pointed forward and side engines stacked. Second fixed directions but replaced four engines with three central blocks. Third restores four blocks, two per rail. Beauty correction rotates both shoulder guns outward. Engine faces in sheet top remain drawn as visible luminous panels; hangar is a top recess rather than a proven flank/belly mouth. |
| A13 | 3 | 2 | First side view had torpedo holes on flank, vertical engine stack and fore/aft rack projection. Second corrects rack direction and removes false torpedo holes. Third fixes side engine overlap, lowers extra housing and exposes near rack mouths. Beauty correction pairs racks across ship, moves trophy aft and turns flak forward. Sheet cannot prove four hidden bow mouths; beauty does. |
| G13 | 3 | 1 | First sheet lacked flak and had yacht section and top-facing engine rings. Second adds flak only in side and changes side engine. Third adds top flak and longitudinal engine housings. Upper glass contour remains shallower than lower; three tries exhausted. Beauty preserves optics and different escort, but cannot prove symmetric section or underside details. |

Pillow was used only for JPG conversion and resizing. No ship was drawn in code. No ComfyUI, Blender, Godot render or API fallback. Generated originals remain untouched. Fourteen image calls completed, with retries spent on count, direction and projection failures.

## Pixel measurements

Manual solid-edge bounds in delivered 1536 x 1024 JPGs, approximately +/-8 px per edge. Bloom is excluded. Length includes fixed engine housings; overall beam includes weapons. Side height includes installations. Perspective beauties are not dimensional plans. Requested dimensions are image-layout targets, not physical units.

| Ship | Prompt target L/B/H px | Top solid bounds x / y | Side overall y | Measured L/B/H px | L:B:H |
|---|---|---|---|---|---|
| H9 | 1360/610/210; body beam 520, body height 170 | 118..1442 / 95..621 | 750..959 | 1324/526/209 | 2.52:1:0.40 |
| A13 | 1380/420/350; body height 180 | 50..1490 / 10..535 | 618..950 | 1440/525/332 | 2.74:1:0.63 |
| G13 | 1400/350/160; lens body height 100 | 50..1484 / 168..478 | 630..844 | 1434/310/214 | 4.63:1:0.69 |

H9 side begins around x84, versus top x118, so stern alignment is off about 34 px. Body beam stays near H8; short guns reduce overall width. Body depth is approximately 160 px.

A13 body-only beam is about 361 px (y97..458), giving roughly 3.99:1 length/beam; launcher extensions make the overall beam 525 px. Side armour body is about 196 px high (y738..934). It is still more regular and slender than the requested broad offset-block mass.

G13 lens body is about 164 px deep (y680..844). Rim near y749 gives about 69 px above versus 95 px below, so equal curvature FAILS. Forward lens collars are about 80 px across, about 26% of measured beam rather than 20%; central collar about 140 px. Its 4.63:1 plan is longer than the requested roughly 4:1. The beauty does not repair the sheet's dimensional evidence.

## Gate scoring

PASS means visible concept evidence. FAIL also covers a required feature hidden or too ambiguous to verify. No unseen far-side part is counted as proven. Armed top silhouettes were inspected at reduced display size. Interiors and authored fracture geometry cannot be proven by concept art.

### Hegemony H9

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted own weapons, armed read | PASS | PASS | Two heavy twin mounts, one small centreline flak, recessed blue bow ion source; black gun mouths. |
| 2 | Clear arcs, no backward fire | PASS | PASS | Final shoulder barrels point to opposite flanks, clear of body. |
| 3 | Stern thrust axis | FAIL | PASS | Four blocks restored, but top-facing luminous engine faces violate strict projection; beauty places four blocks aft. |
| 4 | Spine and break lines | PASS | PASS | Connected wedge/rails, two repeated transverse module seams. Concept joints only. |
| 5 | Command and sensor | PASS | PASS | Low command housing and separate blue-faced sensor patch; no tower. |
| 6 | Hangar door | FAIL | FAIL | One dark recess between rails retained, but depicted from above; flank/belly entrance orientation unproven. |
| 7 | Symmetry | PASS | PASS | Matching shoulders, rails and engine groups. |
| 8 | Top identity and agreement | FAIL | PASS | H8 twin-rail wedge retained; sheet stern alignment and engine projection disagree. Beauty follows top arrangement. |
| 9 | Fixed proportions, distinct escort | FAIL | FAIL | Overall beam 526 vs target 610; sheet alignment unresolved. Beauty escort is correctly single-spine with one gun, fewer modules, no twin-rail gap. |
| 10 | Shared detail scale | PASS | PASS | Repeated small hatches and panels; escort has fewer at comparable scale. |
| 11 | Naval pass | PASS | PASS | Low armoured mounts, flat worked underside; details below. |
| 12 | Faction sheet | PASS | PASS | Pale grey, blue trim/light, no rust, ornament or warm light. |

Sheet: 8 PASS, 4 FAIL. Beauty: 10 PASS, 2 FAIL.

| Naval point | Sheet side view | Beauty | Evidence |
|---|---|---|---|
| No boat profile | PASS | PASS | Slab sides and flat armoured lower edge, no curved keel. |
| Worked belly | PASS | PASS | Side has lower radiator belt and inset RCS housings; beauty shows lower armour belts, underside mostly occluded. |
| No deck house | PASS | PASS | Low sunk block, no cabin stack. |
| No ship's prow | PASS | PASS | Blunt vertical blue emitter face. |
| Nothing hanging | PASS | PASS | All details attached directly to armour. |
| No battleship turrets | PASS | PASS | Low wide faceted housings and short fat barrels. They remain visibly mounted, not fully flush. |
| No other sea fittings | PASS | PASS | No mast, funnel, crane, rails, porthole rows or flight platform. |

### Hullbreaker A13

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted own weapons, armed read | FAIL | PASS | Two giant racks and one flak visible; four bow torpedo mouths hidden in orthographic sheet. Beauty shows four dark flush rectangular bow ports. |
| 2 | Clear arcs, no backward fire | PASS | PASS | Final racks oppose laterally; small flak points forward. |
| 3 | Stern thrust axis | PASS | PASS | Three bells in top and beauty, large centre and smaller pair; corrected side overlaps engines instead of vertical stack. |
| 4 | Spine and break lines | FAIL | FAIL | Continuous block body and bolted joins; two unmistakable authored cross-spine break locations not established. |
| 5 | Command and sensor | PASS | PASS | One low command box and one small listening cluster. |
| 6 | Hangar doors | PASS | PASS | Two near-side rectangular doors, no extra bays claimed. |
| 7 | Main weapons and engines balance | PASS | PASS | Two racks across spine and balanced three-bell group; skins may differ. |
| 8 | Top identity and agreement | FAIL | FAIL | Stepped salvage identity holds; perspective rack faces intrude into orthographic top, beauty exaggerates frames and body becomes regular brick. |
| 9 | Fixed proportions, distinct escort | FAIL | FAIL | Overall beam too large, body plan too slender/regular. Escort correctly has one rack, two engines, two bow ports, no hangar or trophy. |
| 10 | Shared detail scale | PASS | PASS | Bolts and patch plates comparable across hero and escort. |
| 11 | Naval pass | PASS | PASS | Flat block underside, blunt face, no hanging junk; details below. |
| 12 | Faction sheet | PASS | PASS | Red oxide, soot black, bare steel, pale bolted trophy, dim red; no green/olive. |

Sheet: 8 PASS, 4 FAIL. Beauty: 9 PASS, 3 FAIL.

| Naval point | Sheet side view | Beauty | Evidence |
|---|---|---|---|
| No boat profile | PASS | PASS | Horizontal slab belly with hard steps/chines. |
| Worked belly | PASS | PASS | Attached RCS housings and lower armour belt, not a bare smooth underside. |
| No deck house | PASS | PASS | Command box low between plates; first extra housing flattened. Rocket frames are weapon supports, not cabins. |
| No ship's prow | PASS | PASS | Blunt stepped slab bow, no raised stem or water-cutting point. |
| Nothing hanging | PASS | PASS | No chains/cages/weights; trophy and side containers fixed flat. |
| No battleship turrets | PASS | PASS | Two box racks on frames; only gun turret is small low flak. Frames remain quite tall in beauty. |
| No other sea fittings | PASS | PASS | No masts, cranes, funnels, rails, porthole rows or flight platform. |

### Glasswright G13

| # | Gate | Sheet | Beauty | Evidence |
|---|---|---|---|---|
| 1 | Counted own weapons, armed read | PASS | PASS | Three large smooth lens domes with collars, one small gun and one smaller flak, dark gun mouths. |
| 2 | Clear arcs, no backward fire | PASS | PASS | Two forward optical shoulders and elevated central lens; small barrels forward, no obvious obstruction. |
| 3 | Stern thrust axis | PASS | PASS | Three longitudinal housings in final top, one overlapping side nozzle, three white rings in beauty. |
| 4 | Spine and break lines | PASS | PASS | Continuous silver spine/rim, two structural collars. Actual fracture geometry remains unproven. |
| 5 | Command and sensor | PASS | PASS | Single low dark-window aft housing plus separate small flush patterned sensor patch. |
| 6 | Hangar doors | PASS | PASS | None required or added. |
| 7 | Symmetry | PASS | PASS | Paired shoulder lenses and balanced leaf plan. Required upper/lower section symmetry is scored under 11. |
| 8 | Top identity and agreement | FAIL | PASS | Leaf identity holds; sheet remains an inconsistent side section. Beauty follows top weapon positions. |
| 9 | Fixed proportions, distinct escort | FAIL | FAIL | Plan 4.63:1, height excessive, lenses oversize. Escort correctly compact oval, one large lens, one tiny gun, two drive rings. |
| 10 | Shared detail scale | PASS | FAIL | Sheet has regular hex grid. Beauty escort tile size appears somewhat reduced relative to hero, risking a scaled-copy surface read despite different equipment. |
| 11 | Naval pass | FAIL | FAIL | Side upper/lower curvature unequal; beauty cannot demonstrate correction or underside work. |
| 12 | Faction sheet | PASS | PASS | Clear glass, white internal lines, thin rainbow fringe, silver structure; no insect, sail, open ribs or shard block. Some glass still looks reflective. |

Sheet: 9 PASS, 3 FAIL. Beauty: 9 PASS, 3 FAIL.

| Naval point | Sheet side view | Beauty | Evidence |
|---|---|---|---|
| No boat profile | FAIL | FAIL | Sheet body about 69 px above rim and 95 below, still too flat above. Perspective beauty cannot prove equal section. |
| Worked belly | PASS | FAIL | Sheet underside has flush radiator and RCS panels on lower spine; beauty underside hidden. |
| No deck house | PASS | PASS | Low inset aft housing, no cabin stack. |
| No ship's prow | PASS | PASS | Thin planar leaf tip as explicitly required by G13 brief; no raised or raked water-cutting stem in elevation. |
| Nothing hanging | PASS | PASS | Rim, spine and engines joined directly, no booms or dangling parts. |
| No battleship turrets | PASS | PASS | Big smooth optical domes in collars; small guns low. |
| No other sea fittings | PASS | PASS | No masts, funnels, cranes, rails, porthole rows or flight platform. |

## File validation

| JPG | Dimensions | Bytes |
|---|---|---:|
| hegemony_H9_sheet.jpg | 1536 x 1024 | 320692 |
| hegemony_H9_beauty.jpg | 1536 x 1024 | 334776 |
| corsair_A13_sheet.jpg | 1536 x 1024 | 353866 |
| corsair_A13_beauty.jpg | 1536 x 1024 | 385887 |
| ithar_G13_sheet.jpg | 1536 x 1024 | 250359 |
| ithar_G13_beauty.jpg | 1536 x 1024 | 243745 |

Six requested JPGs exist, each below 700,000 bytes and longest edge exactly 1536. All three beauties contain exactly one different smaller escort. Each sheet has top above side, bow right, grey background and no text, with projection failures recorded above. Board copies are in the requested issue-483/shots folder.

- PASS: JPEG decoding, six-file count, dimensions and file sizes; all six Board copies match by SHA256.
- PASS: each ship has exactly twelve gate rows and seven naval rows, scoring sheet and beauty separately.
- PASS: Markdown has no em dashes or trailing whitespace; git diff --check passed.
- Standing pack: node contrib/opus/tools/run_all_checks.js completed with exit 0: 41 PASS, 2 KNOWN, 0 FAIL, 0 SKIP. Known findings: KIT-1, KIT-3, ROS-9, MOD-2, EVT-1, NEM-6, UI-5; oracle drift guard reports 12 baseline constant differences. Log: %TEMP%/voidsworn483_standing.log.
- Separate Godot runs and game captures skipped because this delivery adds only concept pictures and notes. The requested standing pack ran in full.
- Added only six JPGs, prompts.md and README.md under this new repository folder. Existing untracked CODEX_TASK.md left untouched. Only the required Board picture copies were written outside the checkout. No files deleted or moved, no commit, no push.
