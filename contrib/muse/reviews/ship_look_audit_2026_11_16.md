# Ship look audit, 2026-11-16

Refs #881. Owner: muse. Sources: main at 385510b7, fetched Nov 16 2026. One labelled comparison picture per ship sits in `ship_look_audit_2026_11_16/` beside this file; each picture names the ship, the stage, both source paths, and the fetch revision.

## Method and council record

The chair (blind Rey) viewed all 20 comparison pictures and wrote the first pass before any leg ran. Four council legs then tested the chair's reasoning from a text pack: DeepSeek (DeepThink on, Search off, verified both ends), Qwen (Qwen3.8-Max, selector and header verified; it returned two answers under an A/B prompt, neither was selected, both are filed), Grok (Fast), ChatGPT (chat only, GPT-6 at High, verified both ends). The legs cannot see the pictures; they test whether the calls, the ranking and the causes hold together, and the review says so wherever a leg's point is about reasoning rather than pixels. The Flash seat is empty: the Gemini sign-in needs a phone verification the owner declined on Nov 16, the same block recorded on issue 880. No substitution.

Verdict of the council: SOUND WITH CONDITIONS, unanimous (Grok, DeepSeek, ChatGPT, and both Qwen answers). The conditions changed this audit in five places: the headline cause is now the stage boundary violation, the ranking is grouped by severity with three ships moved out of the plain list, the kinds went from five to seven with multi-labelling, the evidence limits are stated per ship, and the fixes are written as stack inputs and one rule, not as reports alone. Dissents are recorded at the end.

One instrument limit, stated plainly because two legs demanded it: the painted proofs are composites, and the build panels the chair judged were cropped from them at roughly half the composite width. Plate size and evenness read clearly at that scale, so the plate and grade calls stand. Fine weathering detail does not, so weathering calls on painted ships are provisional until an equal-scale re-shoot under the rules that landed with issue 880.

## Headline cause: the stage boundary violation

The audit's centre finding is not any single ship. It is that a later stage may overwrite what an earlier stage established, after the checks have already passed on the earlier version. The clearest case is KB1CC: the R275 blockout carried the glacis, the side cutouts and the machinery, and the paint stage re-tiled it into an even quilt. Paint changed plate layout, which is geometry, after the fit, weapon and silhouette checks had passed on the pre-paint ship. The checks validated a ship that no longer exists.

The global fix (R291: fix the kind, not the ship) is a stage-preservation contract across the five handoffs, written into the existing sheet and review documents, not as new gates:

- Concept to sheet: defining silhouette, feature locations, major proportions, and any owner modification of the concept.
- Sheet to geometry: signature shapes, major openings and voids, machinery placement, relief depth.
- Geometry to paint: structural identity and plate character. Paint owns material, weathering, colour and emissive treatment. Paint may not alter plate size, evenness or layout. Any stage that legitimately changes structural geometry shows that change in its own comparison.
- Paint to game rendering: readable colours, contrast, emissive signatures, visual hierarchy at battle scale.
- Rendering to owner proof: correct revision, true stage, representative scale and the exposing view, per the rules landed with issue 880.

Inside that contract sits the paint stack's authority boundary, one paragraph owned by whoever maintains the unified stack: the stack sets a common material language per faction; it must preserve the per-ship values the sheet names (plate character, colour targets, weathering level, emissive elements), which it consumes as inputs, not as documentation. Shared style is the goal; uniform style is the failure this audit keeps finding.

## Ranking principle

Identity recognition at camera 170: identity loss first, signature-feature survival second, surface notice third. A ship that loses its identity outranks a ship that keeps its identity and loses grade, even when the grade loss is more visible. Role weights the read: the flagship and the reference pair carry the faction's look, so a miss there propagates. Ships too small to read at camera 170 are also judged on an exposing close view, and their rank reflects the build error, not the pixel count. Painted ships are judged on shape and surface together; sheet-stage ships on shape and feature only, and the list notes that asymmetry rather than hiding it. For sheet-stage ships, colour and glow words in this audit identify elements only (an element with no concept counterpart is an invented element whatever its colour); they are never counted as a colour miss.

## Approved ships: no drift, held as controls

- A16 (painted, issue 726 dark grey): approved by the owner, no drift. It is the control for the Hullbreaker family: the repaint queued in 726 is judged against it.
- E13 (painted): approved by the owner (R272), no drift. The control for the Eclipse family.
- S8 (painted): approved by the owner, no drift.

Approval protects their reference characteristics; it does not exempt them from regression evidence. After any global stack change, drift-check all three again.

## Ranked misses

### Critical: concept identity lost

1. KB1CC (painted, 853 run 2). Kinds: K1 primary, K4, K5, K3. The concept's battered rust-red glacis, spine, side cutouts, machinery and big engine bells became an even clean tile quilt: cutouts and machinery gone, spine a seam, bells small dark rings, no weathering. This is geometry loss at the paint stage, not a paint tint problem, so the queued 726 repaint alone does not close it; it needs a geometry leg beside the repaint (council condition, adopted).
2. E12 (painted). Kinds: K4 primary, K3. The concept's caged, detailed core is a plain bright green bulb, near fully exposed (the owner's point 8, issue 877 covers the armour-down direction); the open truss ring segments are solid ribbed slabs; the rim glow is a thin pale line. The cage and trusses are geometry, the glow is emissive authoring.
3. CS1BA2 (sheet stage). Kinds: K5 primary, K6. The Sealed Gills organism reads as an olive machine pod: even rings, identical window panels, wheel-like side fittings, blunt nose against the concept's long spike. Held: already flagged for outline rework in the 830 check; this audit cross-links that flag rather than opening a second front.
4. E14 (sheet stage). Kinds: K5 primary. The flare concept's separate splayed sail panels became a closed torus of chunky blocks; the spine is short and thick; the petal flare is absent. Held: redesign is already running under R256 and R266. Target note: this comparison judges the flare concept as modified by those rulings; the Board should confirm the governing target in writing before rework, because the two rulings partly answer the owner's list.

### High: defining feature or silhouette fails

5. SF3 (sheet stage). Kinds: K5 primary. The concept's low dorsal fin became a tall blocky tower, the tallest thing on the ship, topped by a zigzag element with no concept counterpart. A silhouette change plus an invented element.
6. A18 (painted). Kinds: K1 primary, K2, K5. Even small tiles replace the big irregular slabs; the grade is dark and flat and loses the concept's rust contrast; a large dish sits amidships where the concept carries none there; no engine glow reads in the proof. Established: the glow does not read. Not established: whether emissive value, exposure or framing causes it.
7. C10 (sheet stage). Kinds: K4 primary, K6. The flagship's two great maw openings read as narrow folded slits; the hull is smooth where the concept is wrinkled, scarred flesh. Maw size and openness are sheet-stage facts; final glow intensity is not judged. Whether the flesh complexity was assigned to a later surfacing stage is not established by the sheet, and the sheet should say so either way.
8. IM5 (painted). Kinds: K4 primary, K3. The concept's machinery-filled central trench reads as three empty rectangular deck slots in the battle view; the concept's blue machinery accents do not read. Established: the machinery does not read. Not established: absent, recessed, unpainted or undersized. The bow carrier-bay read is the owner's R287, filed in issue 870, and is not re-opened here; the IM5 concept lock stands.

### Moderate: significant departure, identity survives

9. A20 (painted, issue 726 dark grey). Kinds: K1 primary. PROVISIONAL, deck only. The deck is a checkerboard of even pale and violet tiles against the concept's big irregular slabs. The R283 hangar cheek exists in the geometry (PR 866), but the 726 proof is a tight deck crop that does not show it, so the whole-ship rank waits on the exposing view. Do not read this rank as a second confirmed defect.
10. A19 (painted). Kinds: K1 primary, K2. Shape faithful; the patchwork is smaller and more even than the concept, and the grade is darker and flatter. A surface miss on a faithful shape, ranked below the signature losses on the identity-first principle.
11. C11 (sheet stage). Kinds: K5 primary, K6. The concept's continuous bone blade row became a cluster of small pale spikes amidships; the sacs and crest carry.
12. E11 (painted). Kinds: K2 primary. Crescent and cannon faithful; the weathered two-tone lavender became dark monochrome violet, and the cannon's green eye reads as a dot.

### Lower: localised departure

13. SB4 (sheet stage). Kinds: K5, K6. Twin bow rings and mass carry; panel armour and vents are flattened, and a regular triangle strip runs on one flank only. The strip is both an invented element and a symmetry defect in kit assembly; the record carries both.
14. HF1D (sheet stage). Kinds: K5 (proportion). The spined-shield family read is right; the prow is shorter and blunter than the concept's slim prow. Colour not counted at this stage.
15. A17 (painted). Kinds: K1, K2. Shape faithful in every feature; the paint is darker and flatter than the concept and the patchwork contrast is lower. Ranked last as the lightest miss, with one open question for the owner, below.

### Evidence-held and deferred (not ranked)

- H10 (painted, battle view). HELD pending two checks: a re-shoot from an exposing view, and a geometry status check (are the twin hulls present in the geometry and buried by paint and grade, or absent?). The beam proof occludes one hull by construction, and at true camera-170 pixels the ship is a small grey bar with no identity reading. If the re-shoot confirms the slab read, H10 enters the ranking high (rank 5 or above, per two legs) under K7. If the twin hulls are absent from the geometry, it is K5 as well as K2.
- Dominion (painted sweep, a4). DEFERRED under the owner's standing judgment (R287, issue 870): the tall conning tower and clean sloped bow of the C19_51 concept read lower and busier in the sweep, recorded as concept distance only. No competing direction is opened here. The sweep panels are small and dark, which is itself noted under the evidence discipline.

## The kinds, their causes, and the global fix for each

Ships may carry more than one kind; the primary kind is the one named first in the ranked list.

- K1 Plate character overridden at paint (KB1CC, A18, A19, A20, A17). Cause: the unified stack's procedural patchwork sets plate size and evenness whatever the sheet built, and the checks ran on the pre-paint ship. Fix: the sheet names per-ship plate character (size, irregularity, contrast) as a stack input; the 875 plate measure runs on painted output, reported, not gated; the rule in the stage contract forbids paint from altering plate layout; the merge comparison runs on painted output. The 726 Hullbreaker repaint is the test case, judged against A16.
- K2 Grade flattens colour identity (A17, A18, A19, E11, H10 in part). Cause: faction-median tuning and battle lift are applied after per-ship colour is set, with no per-ship target to preserve. Fix: per-ship colour targets (hue, value range, accent placement) taken from the accepted picture, carried as stack inputs, checked in the merge comparison on painted output.
- K3 Weathering and emissive elements not authored (KB1CC no weathering, A18 no reading engine glow, E12 thin rim glow, E11 cannon eye a dot, IM5 blue accents unread). Cause: weathering and emissive are left to stack defaults, so they are the first things lost when the grade flattens. Fix: the sheet names the weathering level and the emissive elements as stack inputs; the merge comparison checks them on painted output, diagnosing tonal separation and emissive visibility separately before prescribing (brightening the hull fixes neither reliably).
- K4 Apertures and negative space fill in (KB1CC cutouts, E12 cage and trusses, C10 maw, CS1BA2 gill chambers, C11 blade-row gaps, IM5 trench). Cause: open space is not named as geometry that must stay open, so kit assembly and paint fill it with the nearest solid treatment. Fix: the sheet names each aperture as a named void with its minimum open read; the merge comparison judges the exposing view for that void.
- K5 Signature form lost, or elements invented, at translation (E12 core, SF3 dorsal and zigzag, E14 ring, CS1BA2 gills and fittings, C10 maw, C11 blade row, A18 dish, SB4 strip, HF1D prow proportion). Cause: fit and weapon checks pass while the one feature the concept is about reads wrong, is replaced by a different form, or gains a neighbour with no concept counterpart; and the kit may hold no part that expresses the named feature at the required scale, so the builder substitutes the nearest block. Fix: the sheet names the signature feature, its required relation to the rest of the form, and the proof view that exposes it, and states when the kit cannot build it (the kit gains the part, or the feature is built bespoke); the merge comparison judges that view and rejects elements with no concept counterpart. Corrections begin with form and silhouette, not with added surface detail.
- K6 Kit grammar: one-scale repetition (CS1BA2, C10, C11, SB4). Cause: kit parts repeat at one scale on forms that need varied, continuous shapes. Fix: varied segment scale and continuous-form parts inside the kits, plus a readability floor: a repeated part must read at camera 170 or merge into a larger form. Kit change, never per-ship patching.
- K7 Battle-scale identity collapse (H10 if confirmed; watch E11, E12, IM5, A18 accents). Cause: defining shapes and light sources fail to survive projection and final rendering even when the asset is concept-faithful. This is a real failure kind, distinct from weak evidence: a clearer proof does not fix a ship that does not read in battle. Fix: the camera-170 comparison joins the existing visual review; legibility treatments (stronger separation, larger landmarks, bow contrast) are guided by the accepted concept, never a silent redesign.

Evidence discipline (cross-cutting, not a kind): a proof that does not expose the claimed feature makes the rank provisional, not wrong; the fix is the labelled revision and stage and the exposing view, landed as rulebook rules with issue 880. Cases in this audit: A20's cheek, H10's beam view, Dominion's sweep size, and the half-size build panels in the paint composites.

## Follow-ups this audit hands to the Board

1. Write the stage-preservation contract and the stack authority paragraph into the sheet and review documents (PROGRAM and the build sheet template are the natural homes).
2. KB1CC: add a geometry leg beside the queued 726 repaint; a repaint cannot restore cutouts, spine or bells.
3. H10: geometry status check, then an exposing-view re-shoot; the rank follows the result.
4. A20: shoot the exposing view of the hangar cheek under the 880 rules and close the provisional flag.
5. E14: confirm the governing target (flare concept as modified by R256 and R266) in writing before rework.
6. C10: the sheet states whether flesh complexity belongs to the sheet stage or a later surfacing stage.
7. After any global stack change: drift-check A16, E13 and S8 as controls.

## Dissents and open questions

- Grok would move no ship and keep the chair's original order and five kinds. The chair adopted the other legs' moves; the disagreement is recorded, and Grok's one adopted point (weight the concept's unique identifier explicitly) is in the ranking principle.
- One Qwen answer keeps the evidence problem as a named kind ("proof does not expose the build") because the proof is part of the pipeline. The chair treats it as a cross-cutting discipline with the same fix; the framing dissent is recorded.
- ChatGPT proposed severity groups instead of any linear ranking. The chair keeps a ranking (the brief for this audit requires one) inside severity groups; the groups are the decision unit, the numbers are the chair's ordering within and across them.
- DeepSeek's alternative for H10 was to rank it high immediately. The chair holds it evidence-held, with two legs, because the beam proof cannot separate a build failure from a view artifact; the conditional entry rank is stated so the hold costs nothing if the slab read confirms.
- Open question for the owner: does A17's reference-pair status with A16 cover paint, or shape only? If it covers paint, A17's paint miss conflicts with its reference status and the pair needs a ruling; if shape only, the miss is ordinary and rank 15 stands.
