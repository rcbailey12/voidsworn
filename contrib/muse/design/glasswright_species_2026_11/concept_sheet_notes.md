# Concept sheet notes for Opus (issue #48)

Handoff from Rey, Nov 8, 2026, at Ryan's direction. Ryan reviewed the concept images, ruled them inconsistent as a set ("None of those four portraits look like the same species"), and handed the visual work to Opus with these notes. His ruling was on the images. The design text in design.md stands as the governing document in any conflict.

REVISION, Nov 14, 2026 (the Loom revision, issue 727's second half). Ryan ruled (R252) that the Loom body plan of the adopted species sheet (round 4, PR 703) replaces the low, wide body plan for the whole species, and design.md was rewritten to match (issue 727, PR 751). The consistency bar below is revised to the Loom plan wherever the plan changed: carriage, sail rooting and furling, and the elder read. Substance, head, eyes, brow, grille, sail counts and culture are as written before, because the ruling did not touch them. The old bar's "never upright" line is superseded by the ruling itself: the Loom stands tall on its limbs, though never bipedal and never on two limbs. The v1 to v3 failure log further down is history recorded against the old bar and is kept as written; its body-plan judgements (a pose that "rears up", the spider-stance read) are read against that old bar, not the current one. The failure log's other lessons stand.

## Status

The four-image concept sheet (v1) failed species consistency. Two corrective attempts (v2, v3) each traded one failure for another. Rey's conclusion, reported to Ryan and accepted by the handoff: this image generator will not hold an exact limb plan and one species across a multi-image sheet in a single pass. The images are inspiration-grade only, the same status the Nov 2 concept run carried. Visual convergence belongs in the portrait pipeline over rounds, with Ryan picking, which is how the Nov 2 run converged.

That convergence has since run. Ryan picked the Loom sheet in the portrait rounds (round 4, PR 703, merged; issue 250 closed), R252 adopted the Loom as the species body plan, and the adopted sheet is the species reference. The bar below is the standard any future Loom figure is reviewed against.

## The consistency bar any future image pass must hit

From design.md as rewritten under R252, the non-negotiables:

- Eight limbs exactly: four arms (two upper working, two lower precision) and four support limbs. No tail, no extra limb pairs.
- One substance: pale flesh grading into living glass on one continuum. No second material, no armour, no hardware, no steampunk.
- Carriage: a tall weaver held high. A narrow, deep thorax carried at height (the body rides at roughly the chest height of a standing human, the head above that) on four long support limbs ending in broad, flat, slightly splayed pads. The stance is narrow and completely stable. Never bipedal, never standing on two limbs.
- Head at the front of the thorax on a short, thick neck, the gaze falling forward and slightly down onto the work held below. The workpiece is steadied against the ventral work face, beneath the thorax.
- Two forward lens eyes, deep green, flush, side by side. No side-set insect eyes, no eye stacks.
- Brow of five to seven segments as the expression system (elders may reach eight or nine).
- Reed grille small and flush. No teeth, no fringe, no tube or pipe.
- Sails: four to six grown crystal vanes in a shallow layered fan carried on the back, rooted along the upper thorax behind the head, clear and silver-edged with rainbow fringes at the thin margins, modest against the body (the largest primary about sixty centimetres). Furling folds back and down along the back. One focusing vane angles forward over the shoulder and down onto the work held below. No spikes, no display wings, no fabric, no masts.
- Age reads as cumulative fusion and bloom on the same anatomy. Elders' supports thicken and the stance widens and settles lower; the bloom is a thin frost on smooth glass, never a crust. The ancient elder is the Loom plan's fullest expression: lengthened thorax, thick supports, a wide low settled stance, and eight or more bloom vanes layered down the long back.
- One recorded exception: Tamsa's fan. The written plan gives her six vanes; the adopted sheet renders eight, and that eight-vane fan stands as the Board's call under R252. Review her figures against eight, everyone else against four to six.

## What was generated and how each image failed

All files live in Rey's local workspace at ~/workspace/voidsworn-glasswright-48/concepts/ (binary images cannot ride the repo push). Limb counts below are from a visual count pass plus chair read; treat a count as "cleanly countable," since clutter hides limbs in the busy scenes. These judgements were made against the old bar (see the revision note at the top).

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
- Added Nov 14, 2026: the route that converged was reference-anchored rounds against a picked direction (the Loom), with variety pushed in pose and life context while the body plan held. The adopted sheet (round 4) is the anchor now; future figures anchor on it, not on the v1 to v3 images.

## Ask of Opus

Answered by events. The convergence ran as portrait pipeline rounds with Ryan picking; the Loom sheet was adopted (PR 703) and design.md rewritten to it (issue 727). No image should be treated as species reference except the adopted sheet, and future figures are reviewed against the Loom bar above.
