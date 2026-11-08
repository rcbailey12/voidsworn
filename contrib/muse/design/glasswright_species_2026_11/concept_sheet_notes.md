# Concept sheet notes for Opus (issue #48)

Handoff from Rey, Nov 8, 2026, at Ryan's direction. Ryan reviewed the concept images, ruled them inconsistent as a set ("None of those four portraits look like the same species"), and handed the visual work to Opus with these notes. His ruling was on the images. The design text in design.md stands as delivered and is the governing document in any conflict; Ryan's pick on the text is still his to give.

## Status

The four-image concept sheet (v1) failed species consistency. Two corrective attempts (v2, v3) each traded one failure for another. Rey's conclusion, reported to Ryan and accepted by the handoff: this image generator will not hold an exact limb plan and one species across a multi-image sheet in a single pass. The images are inspiration-grade only, the same status the Nov 2 concept run carried. Visual convergence belongs in the portrait pipeline over rounds, with Ryan picking, which is how the Nov 2 run converged.

## The consistency bar any future image pass must hit

From design.md, the non-negotiables:

- Eight limbs exactly: four arms (two upper working, two lower precision) and four support limbs. No tail, no extra limb pairs.
- One substance: pale flesh grading into living glass on one continuum. No second material, no armour, no hardware, no steampunk.
- Head low at the front of a low, wide, settled body. Never upright.
- Two forward lens eyes, deep green, flush, side by side. No side-set insect eyes, no eye stacks.
- Brow of five to seven segments as the expression system.
- Reed grille small and flush. No teeth, no fringe, no tube or pipe.
- Sails: four to six grown crystal vanes, clear and silver-edged, modest against the body, furling back along the thorax, one focusing vane at the bench. No spikes, no display wings, no fabric, no masts.
- Age reads as cumulative fusion and bloom edges on the same anatomy. The fuller spider stance belongs only past roughly 350 years.

## What was generated and how each image failed

All files live in Rey's local workspace at ~/workspace/voidsworn-glasswright-48/concepts/ (binary images cannot ride the repo push). Limb counts below are from a visual count pass plus chair read; treat a count as "cleanly countable," since clutter hides limbs in the busy scenes.

v1 sheet (the four delivered with the design):

- Bench worker (media-generation-glasswright-48-bench-worker-0-74b2caa1-89c7-406d-8ff4-81be70ec0162.webp): 3 arms and 3 legs cleanly countable, the rest lost in clutter. Grille reads toothy at small size. Head and brow match none of the other three images. Strengths: the weaving action, the focusing vane, the chest glow.
- Face study (media-generation-glasswright-48-face-0-22536cf4-3793-41cd-8372-8e704855d54e.webp): the strongest head. Two flush green lens eyes, lattice texture, small flush grille all land. Flaw: the brow runs about 11 segments against the spec's five to seven, and the head shape (tall, rounded) matches no body in the set.
- Admiral (media-generation-glasswright-48-admiral-0-22b5ae21-cce1-4bb5-8828-acfe8452ea62.webp): only 2 arms rendered; the precision pair is missing entirely. Five leg-like limbs. Face reads muzzle, not the design's face. Vanes oversized against the written modest spec.
- Ancient elder (media-generation-glasswright-48-ancient-elder-0-db24c8de-3062-4504-92a3-41afce34e7ba.webp): 3 arms and 5 legs countable, plus a long rear body extension the design does not have. Bloom edges on the vanes are exactly right; the overall read leans monster past the text's intent.

v2 bench worker (media-generation-glasswright-48-v2-bench-worker-0-8f8afe72-0fbd-47d9-82c4-6d249076e929.webp): generated with explicit limb-count language. The grille fixed (thin vertical reeds, plainly a grille) and the count is arguably four and four under clutter, but the pose rears up instead of settling, the midsection limb arrangement is muddy, and a small tail appears despite an explicit ban. Closest in spirit of any full-body attempt.

v3 canonical (media-generation-glasswright-48-v3-canonical-0-ef080980-c935-4d95-b937-1b858cc948de.webp): clean profile, limbs separated for counting. Slid insectile instead: side-set eyes, the grille rendered as a hanging fringe of strands, vanes as long spikes angled up, too many segmented limbs underneath ending in hands. Countable and wrong.

## Lessons for whoever runs the next pass

- Independent text prompts each reinterpret the species from scratch. Nothing carries across images.
- Explicit counting language ("exactly four arms, exactly four legs") improves countability in a clean composition and degrades the read everywhere else (v3's insect slide, v2's clutter).
- Banned features arrive anyway (v2's tail). Budget verification per image, not per sheet.
- Reference-anchored generation was not tried in this pass. The two usable anchors are the v2 bench worker (body, action, grille) and the v1 face study (head). Anchoring variants on one of them is the untried route if Opus wants one more generator attempt before the portrait pipeline.
- The failure pattern matches the Nov 2 run's lesson: single-pass generation gives options for an owner pick, not a locked design. Convergence took rounds there too.

## Ask of Opus

Route the Glasswright visual convergence as Opus sees fit (portrait pipeline rounds with Ryan picking, or a muse/opus image job under the bar above). No image should be treated as species reference until Ryan picks it. The design text, the pack, the legs, and the synthesis in this folder are unaffected by the image outcome.
