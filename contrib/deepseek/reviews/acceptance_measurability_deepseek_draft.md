# DRAFT: Acceptance test measurability spec for Voidsworn, PC-only

Model: DeepSeek, DeepThink ON, Search OFF. Filed verbatim from the DeepSeek chat report (chat titled "Acceptance measurability spec"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file was attached to the chat. Process note from the run: the first send attempt stalled in generation and that chat never persisted, so the retry in a fresh chat completed in full. This draft is a proposal for the owner (Ryan) and for Opus, not a ruling.

Status: DRAFT for Ryan and for Opus. This is not a ruling. Nothing here is decided until Ryan rules.

Scope: PC-only desktop frame under the OBSERVED Oct 24, 2026 PC-only ruling. No phone frame, phone tier, or phone acceptance check is proposed anywhere in this document.

OBSERVED basis from the brief:

- Kit acceptance: two shots per hull at battle zoom on a desktop frame, one lit against its home plate and one flat-black silhouette sheet. A hull that cannot be told apart from another hull of its faction, or that a viewer assigns to the wrong faction, sends the manifest back.
- Faction at a glance: on the lit hero shot, a viewer who has never seen the hull names the faction in under three seconds.
- Gold-trim confusion: gold-adjacent trims (Chorus dull gold, Ithar pale gold, epic rarity) must not read as Command gold. Viewer confusion is a finding against the rationing rule, not against the viewer.
- Luminance cap: no background pixel inside the board area exceeds 40% of the luminance of an unlit hull facet. Checked by sampling, not by eye alone.
- Colourblind check: deuteranopia and protanopia simulation on every shield-hit shot.
- Capture rules: in game, never in Blender. PNG only for acceptance shots, no JPEG. Desktop frame only under the Oct 24, 2026 PC-only ruling.
- The gap: acceptance tests are partly subjective. No sample sizes, no pass rates, and no viewer profile are specified anywhere. "A viewer" is undefined.

Global PROPOSED conventions:

- Viewer: a person who is not on the design, art, or QA team for the hull or faction under test, and who has not seen the specific acceptance shot before judging it. This is PROPOSED because the OBSERVED brief leaves "a viewer" undefined.
- Shot: one OBSERVED acceptance PNG at battle zoom on a desktop frame. This uses the OBSERVED two-shot kit format and the OBSERVED PNG-only rule.
- Borderline: a result that misses the pass threshold by one proposed viewer or one proposed comparison, with no OBSERVED hard-return finding. Borderline enters a named hold for retest; it is not a pass.
- Conditional pass: I do not propose keeping conditional pass as a passing outcome. The only provisional state I propose is "hold for retest," which is not a pass. If Ryan keeps conditional pass, the condition must name the test, the shot or hull ID, the exact threshold miss, the fix owner, the retest date, and the exact re-run scope. It must not override an OBSERVED manifest-return finding: wrong faction, indistinguishable same-faction hull, gold trim reading as Command gold, or a luminance cap exceedance.

## 1. Silhouette sheet

OBSERVED test: the QA pack includes one flat-black silhouette sheet per hull, from the OBSERVED two shots per hull. A hull that cannot be told apart from another hull of its faction sends the manifest back.

1. Sample size:

- Viewers: 12 PROPOSED per same-faction hull pair. Rationale: 12 gives an 11 of 12 pass rule with one isolated dissent tolerated, while still exposing a pair that is consistently confused; this is a design choice, not a measured standard.
- Shots: 1 silhouette sheet per hull in each same-faction pair, drawn from the OBSERVED 2 shots per hull. Rationale: the silhouette sheet is the OBSERVED artifact for silhouette distinguishability, and the lit shot adds surface detail that would weaken the silhouette test.
- Pair coverage: all unordered same-faction hull pairs in the manifest PROPOSED. Rationale: the OBSERVED failure mode is within-faction indistinguishability, so every same-faction pair is a risk and cannot be sampled away without Ryan ruling.

2. Pass threshold:

- For each same-faction pair, at least 11 of 12 viewers PROPOSED must correctly report that the two silhouettes are different hulls. Rationale: 11 of 12 tolerates one isolated dissent but fails a pair with repeated confusion; this is a proposed threshold, not a standard.
- Borderline: exactly 10 of 12 PROPOSED viewers report different hulls. Rationale: 10 is one below the proposed pass line and is treated as a hold for retest, not a pass.
- Fail: 9 or fewer of 12 PROPOSED viewers report different hulls. Rationale: 9 is two below the pass line and is treated as a manifest-return finding under the OBSERVED indistinguishability rule.

3. Viewer profile:

- Fresh eyes, not design, art, or QA for that faction. This is PROPOSED because the OBSERVED brief distinguishes fresh eyes from team members but does not define them.
- Normal or corrected-to-normal visual acuity. This is PROPOSED because silhouette shape judgement needs acuity, and the OBSERVED brief gives no vision requirement.
- No colour vision requirement for this test. This is PROPOSED because the OBSERVED silhouette sheet is flat black and does not carry faction colour.
- Same viewer may judge multiple pairs PROPOSED, but not the same hull twice, and no more than 8 hulls per session. Rationale: 8 limits fatigue and silhouette learning while allowing one desktop session to cover a small manifest; this is a design choice, not a standard.

4. Retest rule:

- Re-shoot only the silhouette sheet of the changed hull. This follows the OBSERVED two-shot kit and avoids re-shooting unchanged hulls.
- Re-judge every same-faction pair containing that hull with a fresh 12 PROPOSED viewers. Rationale: the OBSERVED failure is pair-specific, so only pairs involving the changed hull need the full proposed sample.
- If the fix changes a shared faction silhouette language, re-run all same-faction pairs in that faction. This is PROPOSED because a shared change can move pairs that were not individually re-shot.

5. Conditional pass:

- Not proposed. A borderline silhouette result is a hold for retest, not a conditional pass.
- If Ryan keeps conditional pass, the named condition must include the failing pair ID, the 10 of 12 PROPOSED borderline count, the fix owner, the retest date, and the statement that only pairs containing the changed hull re-run. It cannot be used if any viewer reports the two silhouettes as the same hull after retest.

## 2. Faction at a glance

OBSERVED test: on the lit hero shot, a viewer who has never seen the hull names the faction in under three seconds. A viewer assigning the wrong faction sends the manifest back.

1. Sample size:

- Viewers: 12 PROPOSED per hull. Rationale: 12 supports a 12 of 12 faction-correctness rule with one proposed timing tolerance, while staying within one desktop review block; this is a design choice, not a measured standard.
- Shots: 1 lit hero shot per hull, from the OBSERVED 2 shots per hull. Rationale: the OBSERVED test is defined on the lit hero shot, so the silhouette sheet is not used for faction naming.
- Timing: under 3 seconds is OBSERVED from the QA pack and is not a proposed number.

2. Pass threshold:

- Faction correctness: 12 of 12 PROPOSED viewers must name the correct faction. Rationale: the OBSERVED rule says a viewer assigning the wrong faction sends the manifest back, so any wrong-faction naming is a hard-return finding and cannot be averaged away.
- Timing: at least 11 of 12 PROPOSED viewers must name the correct faction in under 3 seconds OBSERVED. Rationale: 11 of 12 allows one correct-but-slow viewer as a borderline timing result without weakening the OBSERVED wrong-faction rule; this is a proposed threshold, not a standard.
- Borderline: 12 of 12 PROPOSED correct faction, but exactly 11 of 12 PROPOSED under 3 seconds OBSERVED. Rationale: this is a timing-only miss and enters hold for retest.
- Fail: any wrong-faction naming, or 10 or fewer of 12 PROPOSED under 3 seconds OBSERVED. Rationale: any wrong faction is an OBSERVED manifest return, and 10 is two below the proposed timing line.

3. Viewer profile:

- Fresh eyes who have never seen the hull, as OBSERVED. This is stricter than "not on the team" and is taken directly from the brief.
- Normal or corrected-to-normal visual acuity and normal colour vision or corrected colour vision. This is PROPOSED because faction naming on a lit shot can depend on colour and acuity, and the OBSERVED brief gives no vision requirement.
- No prior Voidsworn faction briefing for that hull set. This is PROPOSED because prior briefing would defeat the OBSERVED "never seen the hull" condition.
- Same viewer may judge multiple hulls PROPOSED, but not the same hull twice, and no more than 6 hulls per session. Rationale: 6 limits faction-learning across a session while allowing a compact review block; this is a design choice, not a standard.

4. Retest rule:

- Re-shoot only the lit hero shot of the changed hull. This follows the OBSERVED lit hero shot requirement and avoids re-shooting unchanged hulls.
- Re-judge that hull with a fresh 12 PROPOSED viewers who have not seen it. Rationale: the OBSERVED rule is about a viewer who has never seen the hull, so the retest sample must be fresh to that hull.
- If the fix changes shared faction material, trim, or silhouette cues, re-run all hulls in that faction with a fresh 12 PROPOSED per hull. Rationale: a shared faction cue can change glance recognition for hulls that were not individually re-shot; this is proposed, not measured.

5. Conditional pass:

- Not proposed. A borderline timing result is a hold for retest, not a conditional pass.
- If Ryan keeps conditional pass, the named condition must include the hull ID, the 11 of 12 PROPOSED timing count, the fix owner, the retest date, and confirmation that no viewer named the wrong faction. It cannot be used if any wrong-faction naming occurred.

## 3. Gold-trim confusion

OBSERVED test: gold-adjacent trims (Chorus dull gold, Ithar pale gold, epic rarity) must not read as Command gold. Viewer confusion is a finding against the rationing rule, not against the viewer.

1. Sample size:

- Viewers: 12 PROPOSED per comparison. Rationale: 12 supports a strict no-Command-gold rule with a named borderline only for one confusion, while keeping the review block finite; this is a design choice, not a measured standard.
- Shots: every lit hero shot in the manifest that contains a gold-adjacent trim, plus 1 Command gold reference crop per batch PROPOSED. Rationale: trim placement varies by shot, so every affected lit hero shot is tested, and 1 reference crop gives viewers a consistent Command gold anchor; this is proposed, not measured.
- Command gold reference source: 1 already accepted PC desktop PNG crop PROPOSED. Rationale: the OBSERVED brief names Command gold but does not define a reference shot, so this requires Ryan to name the source or the test cannot run.

2. Pass threshold:

- For each comparison, 12 of 12 PROPOSED viewers must not name the gold-adjacent trim as Command gold. Rationale: the OBSERVED rule says the trim must not read as Command gold, so any Command gold naming is a hard finding; this is a strict proposed threshold, not a standard.
- Borderline: exactly 11 of 12 PROPOSED viewers do not name Command gold, with 1 viewer naming it. Rationale: 1 confusion is a named borderline for retest, but it remains a finding against the OBSERVED rationing rule; this is proposed, not measured.
- Fail: 10 or fewer of 12 PROPOSED viewers do not name Command gold, or any repeated Command gold naming after retest. Rationale: 10 is two confusions below the strict line and is treated as a rationing-rule failure; this is proposed.

3. Viewer profile:

- Fresh eyes, not design, art, or QA for that faction. This is PROPOSED because the OBSERVED brief calls viewer confusion a finding but does not define the viewer.
- Normal or corrected-to-normal colour vision. This is PROPOSED because the test is about gold hue and trim reading, and the OBSERVED brief gives no vision requirement.
- Viewers are shown the 1 Command gold reference crop once before the block PROPOSED. Rationale: 1 reference anchors the comparison and avoids repeated prompting; this is proposed, not measured.
- Same viewer may judge multiple shots PROPOSED, but not the same hull twice, and no more than 10 comparisons per session. Rationale: 10 limits anchor fatigue and repeated exposure to gold trims; this is a design choice, not a standard.

4. Retest rule:

- Re-shoot only the lit hero shots whose gold-adjacent trim changed, plus the same 1 Command gold reference crop PROPOSED. Rationale: the OBSERVED failure is trim-specific, and 1 unchanged reference keeps the comparison stable; this is proposed.
- Re-judge all affected shots with a fresh 12 PROPOSED viewers. Rationale: the OBSERVED rule is about viewer confusion, so the retest sample must not be primed by the first confusion; this is proposed.
- If the fix changes a shared trim material, re-run every lit hero shot using that material, plus the 1 Command gold reference crop PROPOSED. Rationale: shared material can move confusion to shots that were not individually re-shot; this is proposed.

5. Conditional pass:

- Not proposed. A single Command gold naming is a hold for retest and remains a finding, not a pass.
- If Ryan keeps conditional pass, the named condition must include the shot ID, the trim type, the 1 of 12 PROPOSED confusion count, the fix owner, the retest date, and confirmation that no shared trim material remains. It cannot be used for 2 or more confusions or for repeated confusion after retest.

## 4. Luminance cap sampling

OBSERVED test: no background pixel inside the board area exceeds 40% of the luminance of an unlit hull facet. Checked by sampling, not by eye alone.

1. Sample size:

- Viewers: 0 PROPOSED. Rationale: this is a pixel-sampling test, not a viewer-judgement test, and the OBSERVED brief says checked by sampling, not by eye alone; 0 is proposed because no human viewer count is defined.
- Shots: every acceptance shot with a board area, which is the OBSERVED 2 shots per hull. Rationale: the cap is per shot and background brightness can vary between the lit shot and the silhouette sheet; this uses the OBSERVED kit count, not a new sample.
- Sample points: 49 sample points per board area PROPOSED, using a fixed 7 by 7 grid. Rationale: 49 gives denser coverage than a 5 by 5 grid while still allowing one desktop pass; this is a screening sample, not a proof of every pixel.
- Unlit facet reference: 3 unlit hull facet patches per hull PROPOSED. Rationale: 3 patches reduce the chance that one shadowed facet mis-sets the 40% OBSERVED cap; this is a proposed sampling choice, not a measured standard.

2. Pass threshold:

- Every sampled background pixel in the board area must be at or below 40% OBSERVED of the luminance of the chosen unlit hull facet. This is the OBSERVED cap, not a proposed number.
- All 49 PROPOSED sample points per board area must pass on every shot. Rationale: 49 is the proposed grid, so a single sampled exceedance is a fail; this is a proposed sampling rule, not a standard.
- Borderline: none proposed for the numeric cap. Rationale: a numeric exceedance is binary, and a suspected sampling artifact is handled by full pixel scan, not by a conditional pass; this is proposed.
- Fail: any sampled pixel above the OBSERVED 40% cap. Rationale: the OBSERVED rule is a cap, not a target; this is not a proposed threshold.

3. Viewer profile:

- No viewer profile. This test is not viewer-judged; it is run by Opus or a QA operator on the desktop PNG. This is PROPOSED because the OBSERVED brief says sampling, not by eye alone.
- Operator requirement: same PC-only desktop frame and PNG-only capture rules as OBSERVED. This is not a new viewer profile; it restates the OBSERVED capture rules.
- Same operator may check multiple shots. This is PROPOSED because the test is mechanical and not subject to hull-learning; this is a design choice, not a standard.

4. Retest rule:

- Re-shoot every shot whose board area background or unlit facet changed. This follows the OBSERVED 2 shots per hull and avoids re-shooting unaffected shots.
- Run a full pixel scan on the re-shot board area, not only the 49 PROPOSED grid points. Rationale: a failed sample is a screening signal, and a full scan is needed to settle the OBSERVED "no background pixel" rule; this is proposed.
- If the fix changes a shared home plate or shared background asset, re-sample all shots using that asset. This is PROPOSED because a shared asset can move the cap failure to shots that were not individually re-shot.

5. Conditional pass:

- Not proposed. The OBSERVED cap is numeric and binary; an exceedance is a hold for retest or a fail, not a conditional pass.
- If Ryan keeps conditional pass, the named condition must include the shot ID, the sampled pixel coordinate, the measured luminance ratio, the full-scan result, the fix owner, and the retest date. It cannot be used if the full scan finds any pixel above the OBSERVED 40% cap.

## 5. Colourblind shield check

OBSERVED test: deuteranopia and protanopia simulation on every shield-hit shot.

1. Sample size:

- Viewers: 8 PROPOSED per simulated shot. Rationale: 8 supports a 7 of 8 pass rule and is lower than the 12 proposed for hull-recognition tests because the simulation removes hue discrimination and the judgement is about effect readability; this is a design choice, not a measured standard.
- Shots: every shield-hit shot in the manifest, with both OBSERVED simulations per shot. Rationale: the OBSERVED audit addition says every shield-hit shot, so no sampling of shield-hit shots is proposed; this is not a new number.
- Simulation count: 2 OBSERVED, deuteranopia and protanopia. This is taken from the brief, not proposed.

2. Pass threshold:

- For each shield-hit shot and each OBSERVED simulation, at least 7 of 8 PROPOSED viewers must correctly identify the shield-hit feedback as the intended shield-hit event and not as another combat event or no hit. Rationale: 7 of 8 tolerates one isolated readability miss while failing a simulation that consistently obscures the event; this is a proposed threshold, not a standard.
- Borderline: exactly 6 of 8 PROPOSED viewers correct on one simulation, with no viewer naming a wrong event. Rationale: 6 is one below the proposed pass line and enters hold for retest; this is proposed, not measured.
- Fail: 5 or fewer of 8 PROPOSED viewers correct on either simulation, or any viewer naming a wrong combat event on both simulations after retest. Rationale: 5 is two below the pass line and is treated as a readability failure; this is proposed.

3. Viewer profile:

- Fresh eyes, not design, art, VFX, or QA for that shield-hit effect. This is PROPOSED because the OBSERVED brief requires simulation but does not define the viewer.
- Normal or corrected-to-normal visual acuity. This is PROPOSED because the test judges effect readability, and the OBSERVED brief gives no vision requirement.
- Normal colour vision or corrected colour vision is not required to be excluded, but the OBSERVED simulations are the test artifact. This is PROPOSED because the brief specifies simulation, not actual colourblind viewer recruitment.
- Same viewer may judge multiple simulated shots PROPOSED, but not the same shot twice, and no more than 12 simulated images per session. Rationale: 12 limits simulation fatigue while allowing a compact block; this is a design choice, not a standard.

4. Retest rule:

- Re-shoot only the shield-hit shot whose feedback changed, and re-run both OBSERVED simulations. Rationale: the OBSERVED test is per shield-hit shot and per simulation, so unchanged shots do not need re-shooting.
- Re-judge with a fresh 8 PROPOSED viewers. Rationale: the OBSERVED test is about readability, so the retest sample must not be primed by the first simulated image; this is proposed.
- If the fix changes a shared shield-hit VFX or material, re-run every shield-hit shot using that VFX or material under both OBSERVED simulations. Rationale: shared VFX can move the readability failure to shots that were not individually re-shot; this is proposed.

5. Conditional pass:

- Not proposed. A borderline colourblind simulation result is a hold for retest, not a conditional pass.
- If Ryan keeps conditional pass, the named condition must include the shot ID, the simulation type, the 6 of 8 PROPOSED borderline count, the fix owner, the retest date, and confirmation that no wrong combat event was named. It cannot be used if both simulations fail or if the same shot fails retest.

## Worst-handled test and what would settle it

The test these numbers handle worst is the luminance cap sampling. The OBSERVED rule says no background pixel inside the board area exceeds 40% of the luminance of an unlit hull facet, but the proposed 49-point grid is a screening sample and cannot prove that no pixel exceeds the cap. What would settle it is a full-board pixel scan of decoded PNGs with a fixed luminance formula, plus a Ryan ruling on whether the OBSERVED "checked by sampling" language allows a sampling screen to stand as acceptance or requires the full scan for acceptance.
