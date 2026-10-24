# Voidsworn Acceptance Test - Measurability Spec (DRAFT)

Model: Qwen3.8-Max, Thinking ON, Search OFF. Filed verbatim from the Qwen chat report (chat titled "Voidsworn Acceptance Test Spec"); em dashes normalized to hyphens if any, wording otherwise unchanged. The granted brief file could not be attached in chat (no usable file-input target); the brief's full verbatim text was pasted into the prompt instead.

Status: DRAFT for Ryan's ruling. Nothing here is decided until Ryan rules.

Audience: Ryan (owner, final authority), Opus (coder/verifier, implements and checks).

Scope: PC-only, Babylon engine, desktop frame per the Oct 24, 2026 ruling. No phone frame, no phone tier, no phone acceptance check.

Capture rules (OBSERVED, from QA pack and Oct 24 ruling): in-game only, never in Blender. PNG only for acceptance shots, no JPEG. Desktop frame only.

The gap this draft addresses (OBSERVED, Pack J consensus): acceptance tests are partly subjective. No sample sizes, no pass rates, and no viewer profile are specified anywhere in the current QA pack. "A viewer" is undefined. This document proposes numbers to close that gap. Every number below is PROPOSED, not measured, not standard.

## 1. Silhouette Sheet Test

What is tested (OBSERVED): Two shots per hull at battle zoom on a desktop frame - one lit against its home plate, one flat-black silhouette sheet. A hull that cannot be told apart from another hull of its faction, or that a viewer assigns to the wrong faction, sends the manifest back.

### 1.1 Sample size

- Viewers: PROPOSED 5 independent viewers per faction batch. Rationale: 5 is the minimum at which a single misread can be outvoted without the result hinging on one person's bad day; below 5, one outlier swings the outcome.
- Shots: All hulls in the faction batch, presented as the full silhouette sheet plus the lit hero shot, per the existing two-shot rule (OBSERVED). Rationale: the test is comparative within a faction, so every hull in that faction must appear in the same viewing session.

### 1.2 Pass threshold

- PROPOSED: the test passes when 4 of 5 viewers correctly identify every hull's faction and do not confuse any two hulls within the faction.
- Borderline (3 of 5 correct): PROPOSED the manifest is sent back. Rationale: at 3 of 5 the design is genuinely ambiguous and the QA pack's own language ("cannot be told apart") treats ambiguity as failure, not as a near-miss.
- 4 of 5 with the single dissenting viewer naming a specific wrong faction: PROPOSED this is logged as a finding for Ryan but does not block the manifest. The dissent must be written down (which hull, which wrong faction) and attached to the pass record.

### 1.3 Viewer profile

- PROPOSED: viewers must be "fresh eyes" - they must not have seen the hull designs, the faction briefs, or any prior silhouette sheets for this faction batch. Team members (art, design, code) are excluded.
- Vision: normal or corrected-to-normal visual acuity. No colour-vision requirement for this test because the silhouette sheet is flat black and the identification is shape-based (OBSERVED: the test is about silhouette, not colour).
- The same viewer may judge multiple factions in one sitting, PROPOSED, but must not judge the same faction batch twice. Rationale: fatigue across factions is acceptable; learning within a faction invalidates the fresh-eyes requirement.

### 1.4 Retest rule

- When a hull is re-sculpted or re-proportioned to fix a silhouette failure, PROPOSED: re-shoot only the affected hull (both the lit shot and the silhouette sheet, per the two-shot rule). Re-run the full 5-viewer panel for the entire faction batch, not just the fixed hull. Rationale: changing one hull can change the relative distinctness of its neighbours; a subset re-run would miss new confusions introduced by the fix.

### 1.5 Conditional pass

- PROPOSED: conditional pass is available only when 4 of 5 viewers pass and the single failure is attributable to a presentation defect (wrong zoom, clipping at frame edge, monitor gamut issue) rather than to the hull shape itself. The condition must be named in writing (e.g., "conditional on re-shooting hull K at correct battle zoom"). If the condition is not met within one re-shoot cycle, the conditional pass converts to a full failure.

## 2. Faction at a Glance Test

What is tested (OBSERVED): On the lit hero shot, a viewer who has never seen the hull names the faction in under three seconds.

### 2.1 Sample size

- Viewers: PROPOSED 7 independent viewers. Rationale: the three-second window is short and binary (named it or did not), so a slightly larger panel than the silhouette test reduces the chance that one slow reader sinks a design that is in fact legible. 7 gives a 6-of-7 threshold that still tolerates one outlier.
- Shots: one lit hero shot per hull, presented one at a time in randomised order (PROPOSED randomisation to prevent order-learning). Rationale: sequential presentation within a faction lets viewers narrow by elimination, which defeats the "at a glance" intent.

### 2.2 Pass threshold

- PROPOSED: 6 of 7 viewers name the correct faction within three seconds for the test to pass on a given hull.
- Borderline (5 of 7): PROPOSED the hull is sent back. Rationale: "at a glance" is the design intent (OBSERVED language), and 5 of 7 means nearly a third of fresh viewers could not read it fast enough.
- Timing method: PROPOSED a simple on-screen timer started when the image appears, stopped when the viewer speaks or presses a key. Opus logs the timestamp. No stopwatch-by-eye.

### 2.3 Viewer profile

- PROPOSED: same fresh-eyes and team-exclusion rules as the silhouette test (Section 1.3).
- Vision: normal or corrected-to-normal acuity. No colour-vision restriction here because the test is about overall gestalt recognition, not colour matching, but PROPOSED that at least 1 of the 7 viewers has a documented mild colour-vision deficiency, to flag cases where faction identity leans too heavily on a single hue. This is a flag, not a veto.
- The same viewer may judge multiple hulls but must not have judged any hull from the same faction earlier in the same session (PROPOSED), to prevent priming.

### 2.4 Retest rule

- PROPOSED: if a hull fails and is revised (trim, proportion, plate design), re-shoot the lit hero shot for that hull only. Re-run the full 7-viewer panel for that hull. Other hulls in the faction do not re-run unless their hero shots were also changed. Rationale: faction-at-a-glance is judged per hull, not comparatively, so a subset re-run is safe here (unlike the silhouette test).

### 2.5 Conditional pass

- PROPOSED: conditional pass is available when 6 of 7 pass but the median response time is between 2.5 and 3.0 seconds. The condition must name a specific remediation (e.g., "increase contrast of faction glyph by one step") and a re-test date. If the median drops below 2.5 seconds on re-test, the condition clears. If it does not, the conditional converts to failure.

## 3. Gold-Trim Confusion Test

What is tested (OBSERVED): Gold-adjacent trims (Chorus dull gold, Ithar pale gold, epic rarity) must not read as Command gold. Viewer confusion is a finding against the rationing rule, not against the viewer.

### 3.1 Sample size

- Viewers: PROPOSED 7 independent viewers. Rationale: gold discrimination is a fine-grained colour-and-luminance judgement and individual variation in colour perception is high; 7 gives enough spread to catch a trim that reads as Command gold to a meaningful minority.
- Shots: every hull carrying a gold-adjacent trim, shown as the lit hero shot at battle zoom, plus a reference swatch of Command gold shown first to calibrate the viewer's eye (PROPOSED reference swatch). Rationale: without a reference, the viewer has no anchor for "Command gold" and the test measures guesswork rather than confusion.

### 3.2 Pass threshold

- PROPOSED: the test passes for a given trim when 6 of 7 viewers do NOT identify it as Command gold.
- If 2 or more viewers call a trim "Command gold" or "the same gold as Command," PROPOSED the trim fails and the rationing rule finding is logged (OBSERVED: confusion is a finding against the rule, not the viewer).
- Borderline (exactly 2 of 7 confused): PROPOSED this is a fail, not a borderline pass. Rationale: the rationing rule exists specifically to protect Command gold's exclusivity, so even a 2-in-7 confusion rate undermines the rule's purpose.

### 3.3 Viewer profile

- PROPOSED: fresh eyes, team-excluded, same as Section 1.3.
- Vision: normal colour vision required (Ishihara 14-plate or equivalent screening, PROPOSED). Rationale: this test is specifically about gold discrimination, so viewers with a colour-vision deficiency would produce findings that reflect their vision, not the trim's design. Those viewers are better served by the colourblind check in Section 5.
- The same viewer may judge multiple trims in one session. PROPOSED a five-minute break between the reference swatch and the first test image to reduce afterimage effects.

### 3.4 Retest rule

- PROPOSED: if a trim is re-coloured or re-lit to fix a confusion finding, re-shoot the affected hull's lit hero shot. Re-run the full 7-viewer panel for that trim only. Other gold-adjacent trims do not re-run unless their material or lighting was also changed. Rationale: trims are judged independently against the Command gold reference, not against each other.

### 3.5 Conditional pass

- PROPOSED: conditional pass is not available for this test. Rationale: the rationing rule is a hard design constraint (OBSERVED). A trim either reads as Command gold to a meaningful number of viewers or it does not. There is no "almost distinct enough" state that a condition can fix short of a re-shoot, which is just a retest.

## 4. Luminance Cap Sampling

What is tested (OBSERVED): No background pixel inside the board area exceeds 40% of the luminance of an unlit hull facet. Checked by sampling, not by eye alone.

### 4.1 Sample size

- Viewers: none. This is an instrumental test, not a perceptual one. Opus (or an automated script, PROPOSED) performs the sampling.
- Shots / samples: PROPOSED a minimum of 200 sample points per background region, drawn from a stratified grid (PROPOSED: divide the board area into a 20x20 grid, sample the centre of each cell, plus 20 additional points at random offsets to catch grid-aligned artefacts). Rationale: 200 points across a typical 1920x1080 board area gives roughly one sample per 10,000 pixels, which is dense enough to catch localised hot-spots (a bloom leak, a specular ping) without requiring a full per-pixel scan.
- Reference measurement: the unlit hull facet luminance is sampled from the flat-black silhouette sheet (OBSERVED: this sheet exists per the two-shot rule) at PROPOSED 5 points on the largest visible facet, averaged.

### 4.2 Pass threshold

- PROPOSED: 200 of 200 sampled points must be at or below 40% of the reference luminance. Zero tolerance.
- Borderline: PROPOSED there is no borderline. A single sampled point at 40.1% is a fail. Rationale: the cap is stated as a hard ceiling (OBSERVED: "no background pixel ... exceeds 40%"), and a sampling test that allows exceptions would require defining an acceptable exception rate, which the QA pack does not do.
- If a fail is found at one sample point, PROPOSED Opus re-runs the full 200-point grid to determine whether it is an isolated artefact or a systemic leak. The re-run result stands.

### 4.3 Viewer profile

- Not applicable. Opus runs the sampling. PROPOSED: if Ryan wants a second check, a second team member may independently run the same grid, but this is a verification of the tool, not a viewer judgement.

### 4.4 Retest rule

- PROPOSED: if a lighting or post-process change is made to fix a luminance violation, re-shoot the affected background. Re-run the full 200-point sample. Do not re-run hulls or factions that were not affected by the lighting change. Rationale: luminance is a property of the rendered frame, not of the hull, so only the changed frame needs re-checking.

### 4.5 Conditional pass

- PROPOSED: conditional pass is available only when the violation is at a single sample point and the cause is identified as a transient render artefact (e.g., a one-frame bloom flicker). The condition must name the artefact and require a re-shoot of that frame. If the re-shoot still shows the point above 40%, the conditional converts to failure. No conditional pass for systemic leaks.

## 5. Colourblind Shield Check

What is tested (OBSERVED, added from the Qwen 3.8-Max audit): deuteranopia and protanopia simulation on every shield-hit shot.

### 5.1 Sample size

- Viewers: PROPOSED 3 viewers with documented deuteranopia or protanopia, plus the simulation pass. Rationale: simulation catches the obvious channel collapses, but real colour-vision-deficient viewers catch the subtle ones (e.g., a shield-hit flash that simulates as "still visible" but in practice reads as a brightness-only change with no shape cue). Three is the minimum to get more than one data point per deficiency type.
- Shots: every shield-hit shot in the acceptance set, run through both a deuteranopia simulator and a protanopia simulator (PROPOSED: use the Brettel-Vienot-Mollon model or equivalent, not a simple desaturation filter). Rationale: the audit specifies both deficiency types, and a simple desaturation filter does not model the actual cone-response collapse.
- Simulation coverage: 100% of shield-hit shots, no sampling subset. Rationale (PROPOSED): shield-hit feedback is a gameplay-critical signal; missing one shot in the sample could ship a shield state that is invisible to a subset of players.

### 5.2 Pass threshold

- PROPOSED: a shield-hit shot passes if, under both deuteranopia and protanopia simulation, the hit state is distinguishable from the no-hit state by at least one non-colour channel (brightness, shape, motion, outline). All 3 colour-vision-deficient viewers must confirm distinguishability.
- If any 1 of the 3 viewers cannot distinguish the hit state, PROPOSED the shot fails. Rationale: shield-hit readability is a binary gameplay need, not a gradient.
- The simulation pass is a pre-screen. If the simulation flags a shot, it goes to the 3-viewer panel. If the simulation passes a shot, PROPOSED it still goes to the 3-viewer panel (no shortcut), because simulation is a model, not a measurement.

### 5.3 Viewer profile

- PROPOSED: the 3 viewers must have a documented diagnosis of deuteranopia or protanopia (at least 1 of each type across the 3, PROPOSED). They do not need to be fresh eyes for the hull designs, because the test is about shield-hit readability, not hull identification. However, they must not have been involved in designing the shield-hit effect.
- Team members with the relevant colour-vision deficiency may serve as viewers here (PROPOSED exception to the team-exclusion rule), because the test requires a specific physiological condition that is rare in the general population and the design-knowledge bias is low for a "can you see this flash" task.

### 5.4 Retest rule

- PROPOSED: if a shield-hit effect is revised (colour, brightness, added outline or shape cue), re-shoot the affected shield-hit sequence. Re-run both simulations and the full 3-viewer panel for that shot. Other shield-hit shots do not re-run unless the shared shader or VFX template was changed, in which case all shots using that template re-run.

### 5.5 Conditional pass

- PROPOSED: conditional pass is available when 2 of 3 viewers pass and the single failing viewer's deficiency type is the one not covered by the primary simulation (e.g., the simulation modelled deuteranopia well but the protanopia viewer caught something the simulation missed). The condition must name a specific fallback cue to add (e.g., "add a 2-frame white outline flash independent of colour channel") and a re-test date. If the fallback cue resolves the issue for all 3 viewers, the condition clears.

## Cross-Test Rules

- PNG only, no JPEG (OBSERVED). All acceptance shots in this spec are captured in PNG at desktop frame resolution. Any JPEG submission is rejected before review.
- In-game only, never Blender (OBSERVED). All shots are captured from the Babylon runtime. No Blender viewport screenshots, no Blender EEVEE approximations.
- Desktop frame only (OBSERVED, Oct 24, 2026 PC-only ruling). No phone frame, no phone tier, no phone acceptance check. This spec contains no phone-related criteria.
- Logging (PROPOSED): Opus maintains a single acceptance log per faction batch recording: date, viewer IDs (anonymised), shot filenames, per-viewer results, timestamps for the three-second test, and any findings. Ryan receives the log with the manifest.

## The Test These Numbers Handle Worst, and What Would Settle It

The faction-at-a-glance test (Section 2) is the weakest fit for the numbers proposed here.

The problem: the three-second window is a hard deadline applied to a subjective act (naming a faction), and the 6-of-7 threshold assumes that the one dissenting viewer is an outlier. But "naming a faction" is not a binary perceptual event the way "is this pixel above 40% luminance" is. A viewer might recognise the faction at 2.8 seconds but hesitate because two factions share a silhouette family, and that hesitation is design-relevant information that the stopwatch flattens into a pass. Conversely, a viewer who guesses correctly at 2.9 seconds by elimination has not demonstrated "at a glance" legibility in the way the QA pack intends (OBSERVED), but the timer records a pass.

The 7-viewer panel is also small enough that the composition of the panel matters disproportionately. If 5 of 7 viewers happen to be familiar with the genre's visual language (common sci-fi silhouette vocabularies), they will name factions faster than a true general-audience viewer would, inflating the pass rate.

What would settle it: a two-part study. First, run the existing 7-viewer test but record not just the binary pass/fail and timestamp, but also the viewer's spoken reasoning (think-aloud protocol). This reveals whether a "pass at 2.9 seconds" was genuine recognition or lucky guessing. Second, run a separate 15-viewer panel (PROPOSED, larger to absorb genre-familiarity variance) with a five-second window instead of three, and compare the pass rates. If the pass rate at five seconds is meaningfully higher than at three, the three-second threshold is measuring processing speed more than design legibility, and Ryan would need to rule on whether that is the intent. Until that study is done, the numbers in Section 2 are the best available scaffold, but they are PROPOSED and should be treated as provisional.

End of draft. All numbers and thresholds are PROPOSED. All references to existing QA pack language are OBSERVED. Ryan rules.
