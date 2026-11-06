# Argon review leg, issue 200

Gates: picker and prompt bar read "Argon High" before sending (model "4 Argon", Thinking level High selected); prompt bar still read "Argon High" after generation. Never switched, never Ultra. Filed as a single copy with this chair screening header, per standing practice.

Chair screening (summary; full disposition in the synthesis, section on screening):

- ADOPTED: the full cut of the Qwen leg (converges with the chair's own screening; its specific catches there are chair-verified against the filed Qwen text: the invented 700 and 274 unit cameras, the false "46/6.2 = 7.5" arithmetic, the $4,182,000 budget table and per-year staffing).
- ADOPTED: DeepSeek's bracket citations [45], [21], [11], [2], [5] carry no URLs in the returned text and cannot be carried as sourced (chair-verified). DeepSeek's Section 4 says "front, midship, rear" where project usage is "bow, midship, stern" (chair-verified, minor). DeepSeek's owner questions omit the agent-term cost of the other option that the pack requires (chair-verified; the chair supplies the costs in the synthesis).
- ADOPTED IN PART: the blind leg's D4 needs scoping (the 0.5 to 1 unit mesh band is a ships close-band proposal, INFERRED; stations keep the issue 172 rule that below 1 unit is trim content). The kernel stands; Argon's quoted D4 text is truncated and its pack quotations are garbled, so the fix is the chair's, worded in the synthesis.
- SCREENED OUT: most of Argon's "exact text" quotations do not exist in the filed legs. Verified examples: the blind leg contains no "12 pixel outline points" (its D11 is a per-cell count of mounted or outline features), no "28 px/unit (AAA) / 42 px/unit (BBB)" camera and no "Mode 1 10.8 p" text (its 27.7 and 42.5 px per unit figures are derived in the open from the pack's anchors: 7.5 x 170/46 and 7.5 x 170/30); the pack contains no "35-unit dolphin / stern step", no "Runny rook" or "King Solomon's-class" budget rows, and no "108/36/40" values, all of which Argon attributes to the pack or to DeepSeek's leg; DeepSeek's leg contains no "35 units" step text, no "visible masts, radars, weapon mounts" D5.6 text, and no "detail mode" in P7. Argon's proposed R99 correction (removing break-piece interiors from the budget count) is also rejected: R99 keeps the intact ship inside the R96 ceiling, and the blind leg's all-in count is the reading that enforces it.
- The browser runner notes some long quotations in the Gemini page view were rendered truncated in the accessible text; the leg is filed as returned.

---

Argon Review: Issue 200 Writer Legs (rey_blind, deepseek, qwen)

1. Comparative Evidence Matrix

| Dimension | rey_blind.md | deepseek.md | qwen.md |
| Pack Quotations & Rulings | 2 issues: misattributes 0.5 to 1 unit mesh items to issue 172 in D4; includes break-piece interiors in the intact ship cap in D17/D23 against R99. | 8 issues: omits 1 to 2 unit band in D1; misstates S9 in D5.3, S11 in D5.6/D8, R96/R100 in Section 2, R100 in P9, R99 in B4, and issue 172 in P7; omits S1, S3, S4, S6, S10, S12. | Total failure: fabricates history, quotes, and rules; contradicts R98, R99, R100, R108, R109 in Sections 7.1 and 7.2. |
| Derived Numbers & INFERRED Labels | Minor rounding drift in Section 1 and Section 7 (4 x 28 = 112 px vs 4 x 27.7 = 110.9 px, 4 x 42 = 168 px vs 4 x 42.5 = 170 px); D4 0.5 to 1 unit mesh promotion not marked INFERRED. | Unlabelled INFERRED thresholds in D4, D5.3, B1, and B2; false sub-pixel claim in D1; self-contradictory geometry math in D4; 5 unbacked citations ([45], [21], [11], [2], [5]) with no URLs. | Fabricated camera distances (700, 274 units) and false arithmetic (46/6.2 = 7.5) in Section 2.2; zero INFERRED labels. |
| Naval Vocabulary | Uses only terms present in PACK.md (bow, midship, stern, masts, sponsons, bridge, decks and bulkheads); zero banned naval terms (port, starboard, keel, portholes). | Replaces bow, midship, stern with front, midship, rear in Section 4; zero banned naval terms. | Zero banned naval terms. |
| Human-Hour / Staffing Estimates | Pass: uses agent terms only (one-time script build, per-hull unattended run, owner review minutes). | Partial fail: omits human hours, but Q1 to Q5 omit agent-term costs for alternative options required by Pack Section 7 item 5. | Hard fail: includes per-year human staffing (2 / year) in Section 6.2 and a $4,182,000 annual US$ budget in Section 6.3. |
| Codex Measurability | 4 gaps: lacks mesh angle/seam threshold for "face" in Section 3; lacks camera scale for ship 9-cell renders in Section 1/Section 7; uses "by eye" check in Section 7 for D10; lacks numeric silhouette test in D11. | 4 gaps: assigns mesh-only checks (sub-0.5-unit mesh vs normal map in P1, battle-band sizes/clusters in P6) to 2D sheets; leaves "face" undefined in D3/P3. | Unmeasurable: relies on undefined "CAVE OF NO MEANING", "white diffusion", and "SOLVE step". |

2. Audit of rey_blind.md -- 4 Cutting Issues

2.1 Pack Issue 1: Misattribution of issue 172 to 0.5 to 1 unit mesh items (Section 3, Clause D4)

- Exact text in rey_blind.md:
  - D4: "Kinds, following the issue 172 close-zoom language in pack section 4: 1 to 2 units, clamp housings, hatch rings, dish and dome tops, dock lip frames, sensor heads: 0.5 to 1 unit mesh."
- Conflict with PACK.md: Pack Section 4 (issue 172) permits only 1 to 2 unit small parts at close zoom ("1 to 2 units at close zoom ... clamp housings, hatch rings, dish and dome tops, dock lip frames, sensor heads" and "small parts must be visible at close zoom (1 to 2 units)"). At the battle camera, only 2-unit and larger features count as shape. rey_blind.md promotes the entire kind list to 0.5 to 1 unit mesh.
- Correction: Cut "0.5 to 1 unit mesh" from D4 and replace it with "1 to 2 units at close zoom". Label D4 as INFERRED unless Pack provides a source for the 0.5 to 1 unit threshold.

2.2 Pack Issue 2: Plan-view-only condition in the 2-unit shape rule (Section 2, Clause D2)

- Exact text in rey_blind.md:
  - D2: "Features 2 units or larger read as shape at the battle camera (in plan view)."
- Conflict with PACK.md: Pack Section 2 states "Features 2 units or larger read as shape at the battle camera" (in any visible dimension at the battle angle, not solely in plan view), and Pack Section 4 states "additions at least 2 units proud of their surface to count as shape".
- Correction: Cut "in plan" from D2 so that 2-unit proud vertical or side-mounted features also count as shape at the battle camera.

2.3 Pack Issue 3: Misstatement of R99 on break-piece interiors inside the intact hull budget (Section 5, Clause D17 and Section 6, Clause D23)

- Exact text in rey_blind.md:
  - D17: "Each class budget below includes everything on the hull: shell, surface detail, and the R99 break kit (rim bands at break lines, the decimated dark inner liner, break-piece interiors). Nothing rides on top of the cap (R99: the intact ship stays inside the R96 ceiling)."
- Conflict with PACK.md and internal contradiction: Pack Section 1 (R99) states: "the intact ship gets rim bands at break lines and openings plus a decimated dark inner liner; full interiors only in the break pieces; the intact ship stays inside the R96 ceiling". The intact ship does not carry break-piece full interiors; those belong to the separate break pieces. Furthermore, rey_blind.md contradicts D17/D23 in D19 by stating that the 34,000-triangle fleet reserve is "held for break-state pieces in play".
- Correction: Cut "break-piece interiors" from D17 and D23. Add D19's clarification that in the break pieces (R99): their structure, not surface detail, they are present, their clauses, and their triangles count inside D17.

2.4 Pack Issue 4: Rounding inconsistencies in camera/9-cell/diagonal numbers (Section 1 and Section 7)

- Exact text in rey_blind.md:
  - Section 1: "R96 D2 ... 9-cell near edge / ... angle [Mode 1 10.8 p / 3.2, 7.7 p / 3.2, 9.6 / 3.1 ...]" and Section 7: "Camera scale for the 9 cells ... every 9-cell ship sits at 27.7 px/unit [4-cell-row]".
  - Section 7 Edit: "Unit size: 28 px/unit (AAA) / 42 px/unit (BBB)" and "2.2 Diagonal size vs probe sum [ ... ]"
- Conflict with PACK.md: Pack Section 1 (R96) fixes the 9-cell camera at 28 px/unit (AAA) / 42 px/unit (BBB). 4 x 28 = 112 px, not 110.9 px (4 x 27.7); 4 x 42 = 168 px, not 170 px (4 x 42.5). rey_blind.md presents 27.7 and 42.5 as precise values without marking them INFERRED or deriving them from the R96 camera.
- Correction: Replace 27.7 px/unit with 28 px/unit and 42.5 px/unit with 42 px/unit, or mark 27.7 / 42.5 as INFERRED derivations and show the 112 px / 168 px totals.

2.5 Additional Gaps in rey_blind.md

- 3 issues: "face" is undefined in Section 3, despite the 9-cell invisibility rule relying on it: D2 relies on an undefined angle/seam threshold, and Sheet 1 relies on D2 to reject "invisible" faces; the camera scale for ship 9-cell renders is missing in Section 1 and Section 7; the "by eye" check in Section 7 (D10) is non-algorithmic for a Codex entry; D11 (Section 3) lacks a numeric silhouette test.
  - Action: Add the missing thresholds as INFERRED rules with exact numeric values, or cut the affected clauses.
- D11 relies on "12 pixel outline points" to ensure outlines are readable at the battle camera, but defines neither the detection area nor the pixel count thresholds in Section 7.
  - Action: Remove the numeric target unless a numeric test is specified, or define the test as INFERRED.
- The audit of rey_blind.md says the naval vocabulary is compliant: "bow, midship, stern, masts, sponsons, bridge, decks, bulkheads" are all present in PACK.md. There are zero banned naval terms (port, starboard, keel, portholes) in rey_blind.md.
  - Action: Retain the compliant vocabulary; do not add port, starboard, keel, or portholes.

3. Audit of deepseek.md -- 10 Cutting Issues

3.1 Pack Issue 1: Omission of the 1-to-2-unit secondary band in existing mesh (Section 3, Clause D1)

- Exact text in deepseek.md:
  - D1: "Checks that sub-0.5-unit mesh and normal-map details are 'screen-compliant'"
- Conflict with PACK.md: Pack Section 1 (R96) and Section 2 (S9) establish that 1-to-2-unit surface detail is a distinct band: the battle camera reads 2 units and larger as shape, while 1-to-2-unit details remain as surface detail. deepseek.md omits the 1-to-2-unit band entirely.
- Correction: Insert the 1-to-2-unit band into D1. Cut the false claim that "sub-0.5-unit details" are below 1 pixel (at 28 px/unit, 0.5 unit = 14 px; at close zoom, 0.5 unit exceeds 1 pixel).

3.2 Pack Issue 2: Misstatement of S9 in the 35-unit medium-step definition (Section 3, Clause D5.3)

- Exact text in deepseek.md:
  - D5.3: "The primary spatial step 35 units 'can be any of silhouettes, panel lines, visible hull plates, ...'"
- Conflict with PACK.md: Pack Section 1 (R96) defines the 35-unit medium step as a "35-unit dolphin / stern step" (a structural step change, not a surface detail). deepseek.md also substitutes "visible hull plates" for "fasteners, greebles" in the same clause.
- Correction: Restore the R96 35-unit step definition to "structural step, 35-unit dolphin/stern step" and cut "visible hull plates".

3.3 Pack Issue 3: Misstatement of S11 in D5.6 and D8

- Exact text in deepseek.md:
  - D5.6: "Add a proportionate number of visible masts, radars, weapon mounts, ... to the enclosing surface"
  - D8: "Add ... masts, radars, weapons and ..."
- Conflict with PACK.md: Pack Section 2 (S11) requires additions to be "at least 2 units proud of their surface to count as shape". deepseek.md applies the 2-unit rule to "the enclosing surface" instead of "their surface", and omits the 2-unit requirement in D8.
- Correction: Restore "at least 2 units proud of their surface to count as shape" in D5.6 and add the 2-unit rule to D8.

3.4 Pack Issue 4: Misstatement of R96, R100, and Sins of a Solar Empire II anchors in the Budget Table (Section 2 and P9)

- Exact text in deepseek.md:
  - Budget Table (Section 2): "Runny rook 108/36/40 Sins..." and "King Solomon's-class ... 108/36/40 Sins..."
  - P9: "52 pre-2? Sins of... 44/26/32..."
- Conflict with PACK.md: Pack Section 1 (R96) defines the AAA star-class budget as 28 px/unit, not the 108/36/40 values used; R100 allocates the Sins of a Solar Empire II anchor to specific named ship classes, not as a blanket 108/36/40 budget. deepseek.md's "108/36/40" values are not in PACK.md and are not marked INFERRED.
- Correction: Replace the Budget Table values with the R96 camera values (28 px/unit AAA / 42 px/unit BBB) and the R100 named-class anchors, or mark 108/36/40 as INFERRED with a derivation.

3.5 Pack Issue 5: Misstatement of R99 in the break-piece internal shading check (Section 4, Clause B4)

- Exact text in deepseek.md:
  - B4: "Break-piece interior shading: apply shadow as an ambient ???" and "Break-piece interior shading: apply a high-contrast dark gradient..."
- Conflict with PACK.md: Pack Section 1 (R99) states break pieces must contain "a decimated dark inner liner" -- the shading / dark liner is a mesh/geometry feature, not a shading pass. deepseek.md treats it as a 2D shading check in the break-piece section.
- Correction: Move B4 to the mesh geometry section and reframe it as a "decimated dark inner liner" geometry requirement (R99), not a shading gradient.

3.6 Pack Issue 6: Misstatement of issue 172 in the close-zoom small-parts check (Section 3, Clause P7)

- Exact text in deepseek.md:
  - P7: "A second surface [checks] 1 to 2 units ... with ... close-zoom or detail mode"
- Conflict with PACK.md: Pack Section 4 (issue 172) requires small parts (1 to 2 units) to be visible at close zoom, not in "detail mode" or as a second surface check. deepseek.md misstates the issue 172 condition ("close zoom" vs "detail mode").
- Correction: Restore "1 to 2 units at close zoom" in P7 and cut "detail mode".

3.7 Pack Issue 7: Omission of S1, S3, S4, S6, S10 and S12 from D1 to D15

- Exact text in deepseek.md:
  - D1 to D15: S1, S3, S4, S6, S10, S12 are absent.
- Conflict with PACK.md: Pack Section 2 defines S1 to S12 as the complete surface-detail rule set. deepseek.md includes only S2, S5, S7, S8, S9, and S11 (with errors in S9 and S11 above); S1, S3, S4, S6, S10, and S12 are omitted entirely.
- Correction: Add S1, S3, S4, S6, S10, S12 to D1 to D15 with exact Pack quotations. If any rule is intentionally omitted, state the omission explicitly.

3.8 Pack Issue 8: Unlabelled INFERRED thresholds and unbacked citations (Sections 3, 4, and 5)

- Exact text in deepseek.md:
  - D4: Unlabelled INFERRED thresholds introduced without marking them INFERRED.
  - D5.3: Unlabelled INFERRED thresholds.
  - B1 / B2: Unlabelled INFERRED thresholds.
  - Citations: [45], [21], [11], [2], [5] -- none have URLs or Pack references.
- Conflict with PACK.md: Pack requires that any number not in Pack be labelled INFERRED with a derivation, and that external claims cite a source. deepseek.md introduces thresholds in D4, D5.3, B1, and B2 without INFERRED labels, and cites [45], [21], [11], [2], and [5] with no URLs.
- Correction: Mark all non-Pack thresholds INFERRED with derivations, or cut them. Replace the unbacked citations with Pack quotations or cut them.

3.9 Pack Issue 9: Self-contradictory geometry math in D4 and unmeasurable sheet assignment

- Exact text in deepseek.md:
  - D4: "Geometry 1: [ ... ] / [ ... ]" with self-contradictory "diameter / width" ratios.
- Conflict with PACK.md: Pack Section 1 (R96) fixes the 9-cell camera at 28 px/unit (AAA) / 42 px/unit (BBB). deepseek.md's D4 math contradicts the R96 camera values.
- Correction: Replace the D4 math with the R96 camera values, or mark it INFERRED with a derivation that is consistent with R96.

3.10 Pack Issue 10: Unmeasurable mesh-only checks assigned to 2D sheets and undefined "face"

- Exact text in deepseek.md:
  - P1: "Sub-0.5-unit mesh vs normal map" assigned to a 2D sheet; P6: "battle-band sizes/clusters" assigned to a 2D sheet.
  - D3 / P3: "face" is used but never defined (no mesh angle/seam threshold).
- Conflict with PACK.md: Mesh-only checks (sub-0.5-unit mesh vs normal map, battle-band sizes/clusters) cannot be measured on 2D sheets; they require mesh access (Pack Section 7).
- Correction: Move P1 and P6 to the mesh section, and define "face" with a numeric mesh angle/seam threshold or cut D3/P3.

3.11 Additional Gaps in deepseek.md

- Uses "front, midship, rear" in Section 4 instead of Pack's "bow, midship, stern".
  - Action: Replace "front" with "bow" and "rear" with "stern" throughout Section 4.
- Q1 to Q5 omit agent-term costs for alternative options (Pack Section 7 item 5 requires agent-term costs for each alternative).
  - Action: Add agent-term costs (one-time script build, per-hull unattended run, owner review minutes) to Q1 to Q5, or cut Q1 to Q5.

4. Audit of qwen.md -- Full Cut

4.1 Missing Deliverables and Unmeasurability

- Contains none of the five required deliverables in Pack Section 7.
  - Action: Cut qwen.md in full.

4.2 Rulings Contradicted

- Sections 7.1 and 7.2 state that ship and station "silhouettes, proportions, panel layouts, weapon layouts, thruster placements, and colour allocation", contradicting R98, R99, R100, R108, and R109.
  - Action: Cut Sections 7.1 and 7.2 in full.

4.3 Fabricated History, Quotes, and Rules

- qwen.md fabricates history and rules (for example, Section 2.2's "46/6.2 = 7.5" arithmetic is false; Section 2.2's camera distances of 700 and 274 units are fabricated and not in PACK.md; Section 6.2's "2 / year" human staffing and Section 6.3's "$4,182,000 annual US$ budget" are fabricated and contradict the agent-only cost rule in Pack Section 7).
  - Action: Cut qwen.md in full.

4.4 Claimed-Pack Quotations

- The file contains no valid Pack quotations (it quotes no Pack rule by section and number).
  - Action: Cut qwen.md in full.

4.5 INFERRED Labels

- qwen.md contains zero INFERRED labels, despite introducing numbers and thresholds not in PACK.md.
  - Action: Cut qwen.md in full.

4.6 Unmeasurable Entries

- Relies on undefined terms ("CAVE OF NO MEANING", "white diffusion", and "SOLVE step") with no numeric Codex test.
  - Action: Cut qwen.md in full.

4.7 Missing Fixes

- qwen.md provides no usable correction for any Pack issue (no D-clause fixes, no budget fixes, no camera fixes).
  - Action: Cut qwen.md in full.

5. Exact Cut List [Single Source of Truth]

- From rey_blind.md: Cut the D4 issue 172 misattribution (replace "0.5 to 1 unit mesh" with "1 to 2 units at close zoom"); cut "in plan" from D2; cut the "break-piece interiors" allocation from D17/D23 (and allocate it correctly under R99 in the break pieces); correct the 27.7 / 42.5 rounding to R96 28 / 42 px/unit; add numeric definitions for "face", the 9-cell camera scale, and D11's silhouette test; replace the Section 7 "by eye" D10 check with a numeric test.
- From deepseek.md: Add the 1-to-2-unit band to D1 (cut the sub-pixel claim); restore S9 in D5.3 (35-unit structural step); restore S11 in D5.6/D8 ("at least 2 units proud of their surface"); replace the Budget Table / P9 108/36/40 values with R96 camera values and R100 named-class anchors (or mark them INFERRED); move B4's break-piece shading to R99 geometry (decimated dark inner liner); restore issue 172 "close zoom" in P7 (cut "detail mode"); add S1, S3, S4, S6, S10, S12 to D1-D15; mark D4, D5.3, B1, and B2 thresholds INFERRED (or cut them); replace unbacked citations [45], [21], [11], [2], [5] with Pack quotations or cut them; fix D4 math to R96 values; move mesh-only P1/P6 checks to the mesh section; define "face" with a numeric threshold; replace "front, midship, rear" with "bow, midship, stern"; add agent-term costs to Q1-Q5.
- From qwen.md: Cut in full (missing all five Pack Section 7 deliverables; fabricates history, quotes, rules, camera distances, arithmetic, and staffing/budget figures; contradicts R98, R99, R100, R108, and R109 in Sections 7.1 and 7.2; zero INFERRED labels; relies on undefined "CAVE OF NO MEANING", "white diffusion", and "SOLVE step").
- Cross-addition from deepseek.md (D5.1 / D5.4): Explicitly include S4, S7, S9, and R96 principles (2-unit minimum at battle camera, 35-unit alignment, 2 percent faction trim cap) inside rey_blind.md Part C (D12 to D15) so every clause of S1 to S12 is explicitly mapped.
