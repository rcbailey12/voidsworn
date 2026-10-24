PYRE-BARGE UPGRADE DESIGN PROPOSAL

Tag rule: OBSERVED means taken from the brief facts. PROPOSED means this draft's invention. This is a design proposal only. Owner rules; Opus owns the task plan.

1. What "upgraded" means for C19_51

OBSERVED: The Pyre-Barge, hull C19_51, is a Corsair battle-barge and ship 1 of the kit pipeline. Ship 2 waits on it.

OBSERVED: v13d clean shell shape has owner OK. v14 adds mixed-shape trimmed plating, belly slabs, uneven rows, and baked finish maps. v14 is a checkpoint, not a finish, and the owner did not sign it off. The owner wants a major graphical upgrade with the new tools before sign-off.

OBSERVED: The upgrade is GO. Corsair grammar is rust-and-bone patchwork: visibly bolted stolen panels, dirty flickering engines, glow #e0402c, and mandatory asymmetry. Parts snap onto the real hull on visible mounts. Guns aim forward or out to the side, never backward. Matched symmetric pairs are the rule except Corsair may be junky. Space ships only: no keels, jackstaffs, bollards, crow's nests, yardarms, or mast ladders.

OBSERVED: All 36 hull meshes exist and load. The manifest and kit job is dressing, paint unification, and VSM conversion of existing meshes, not hull shape generation. Only C19_51 is on the .vsm plus _kit.json path today.

PROPOSED: "Upgraded" for C19_51 means the barge reads as a bolted Corsair salvage capital in one screenshot, not a clean shell with added detail. The upgrade should make theft, repair, dirt, and asymmetry legible at silhouette and beauty-corner distance.

PROPOSED: KEEP from v14: the v13d shell shape as the approved base, the mixed-shape trimmed plating as structural breakup, the belly slab layout as salvage mass, and the uneven row rhythm as Corsair patchwork. Do not reopen the v13d shape.

PROPOSED: CHANGE from v14: baked finish maps become secondary wear and grime masks, not colour authority. FAC3D remains the single colour source plus the joint paint solve. Plating gets clearer stolen-panel boundaries, visible bolt rows, and mount brackets. Belly slabs get exposed seams, bracket shadows, and mixed corrosion so they read as bolted-on salvage. Asymmetry becomes mandatory: one heavier salvage stack, mismatched engine cowling, and uneven panel repair density, while guns stay forward or out to the side. Engines get dirty flicker character with #e0402c glow only. Weathering concentrates at mounts, seams, bolt lines, and engine grime, not as uniform noise. No naval parts are added.

2. Effects pass

OBSERVED: Corsair engines are dirty and flickering. Glow stays #e0402c. Cyan means shields and nothing else is cyan.

PROPOSED: Muzzle character proves the upgrade when forward and side gun shots read as ragged, sooty, stolen-hardware bursts, not clean naval cannon fire. Proven means beauty-corner screenshots show the muzzle flash, soot, and mount reaction clearly, with no backward aim and no cyan.

PROPOSED: Damage states prove the upgrade when light, medium, and heavy damage screenshots show sheared bolted panels, exposed seams, scorched patchwork, and glow leakage in the Corsair palette. Proven means damage still reads as rust-and-bone patchwork at a glance and does not introduce cyan outside shield hits.

PROPOSED: Destruction style proves the upgrade when the barge breaks into stolen-panel clusters and salvage chunks, not a clean keel snap or naval sinking read. Proven means the destruction sheet reads as Corsair wreckage and keeps the silhouette memory of the barge.

PROPOSED: Engine flicker proves the upgrade when the engine glow is irregular, dirty, and #e0402c, with visible cowling repair and soot. Proven means the flicker reads in the beauty corner and never uses cyan.

PROPOSED: Shield reads prove the upgrade when every shield-hit shot uses cyan for shields only and nothing else in frame is cyan. Proven means the colourblind shield check passes on every shield-hit shot and the shield rim is clear against the Corsair hull.

3. Materials audit

OBSERVED: FAC3D is the single colour source, with a joint paint solve. Per-class budgets exist in the mechanism. The 1.32 GB texture memory figure from the kit doc must not be reused because it is asserted without derivation.

PROPOSED: The audit checks PBR material quality: plausible metal and paint response, readable roughness breakup on stolen panels, believable soot and grime, and no material that looks like clean naval paint. It checks texture compression approach for preservation of #e0402c glow, bolt and seam readability, and weathering gradients at beauty-corner distance. It checks paint unification against FAC3D: every visible material colour path must resolve through FAC3D plus the joint paint solve.

PROPOSED: The audit fails if any material authors colour outside FAC3D, if baked finish maps override FAC3D as a second colour authority, if compression smears bolts or seams, if glow drifts from #e0402c, if cyan appears on non-shield surfaces, if PBR response makes stolen panels look uniformly new, or if material quality cannot be judged from screenshots. No texture memory number is proposed or accepted here.

4. Acceptance

OBSERVED: The upgraded barge must pass the desktop-only visual gates: sustained 60 fps in the scripted beauty corner run; background luminance cap, with no background pixel inside the board above 40 percent of an unlit hull facet's luminance, measured by the full-scan procedure against the fixed mid-grey reference facet; flat-black silhouette-sheet test that reads as the faction at a glance; colourblind shield check on every shield-hit shot; and the cyan law, where cyan means shields and nothing else is cyan.

PROPOSED gate 1: Mount proof gate. Beauty-corner screenshots must show every added part snapped onto the real hull on a visible mount, with no floating parts and no naval parts.

PROPOSED gate 2: Damage-state readability gate. Staged light, medium, and heavy damage screenshots must still read as Corsair patchwork, keep guns forward or out to the side, and introduce no cyan outside shield hits.

5. Open questions for Opus

PROPOSED QUESTION: What are the actual per-class budget numbers for C19_51, covering draw calls, material slots, and texture set count?

PROPOSED QUESTION: What measurement hook will run the background luminance full-scan against the fixed mid-grey reference facet inside the scripted beauty corner?

PROPOSED QUESTION: How will the joint paint solve bind FAC3D colours to the existing v14 baked finish maps without creating a second colour authority?

PROPOSED QUESTION: What VSM conversion constraints on the existing C19_51 mesh affect material parity and manifest landmark placement?

PROPOSED QUESTION: What manifest landmark schema will place Corsair mounts and asymmetric pairs on C19_51 without hull regeneration?
