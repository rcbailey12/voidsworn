> Round 3 companion document, Oct 24, 2026. See NOTES.md in contrib/muse/ for the design folder map.

# Design council audit: five lenses on Rey's own design documents

Council, not author. This audit was written as if by an independent five-lens council (sci-fi nerd, gamer, software engineer, QA, designer) pointed at Rey's design documents themselves, not at the game. The game council judged the game; this one judges the pack that is supposed to fix it. Where the game council found strong ingredients and no governing direction, this council asks whether the governing direction actually governs.

## Basis and method

Documents read in full or in key sections from the design staging tree, about 52,000 words across eight files: art_direction_rey.md (3,497 words), ship_kit_upgrade.md (1,186), visual_expansion_research.md (11,868), GRAPHICS_REFERENCES.md (8,656), mod_scene_field_guide.md (10,299), tool_guides.md (14,331), CONVERSATION_CONTEXT.md (1,780), IMAGE_MANIFEST.md (450). Findings are marked OBSERVED (grounded in a quoted line or number from the docs, quotes under 20 words) or INFERRED (council reasoning from observed facts). The council also spot-checked the manifest: four of 40 SHA-256 hashes (bg_belt, bg_solar_corona, ship_voidsworn_basilica, adm_nekhet) were recomputed against the staging images and all four match.

Overall verdict: **GO WITH CONDITIONS.** All five lenses agree. The direction is sound and the two best ideas in the pack (the cyan shield law and the silhouette grammars) are genuinely strong. But the pack is not yet build-ready in its two load-bearing claims: the kit economics and phone-size readability. Both are asserted, neither is measured.

## Lens 1: Sci-fi nerd (universe and theming coherence)

Verdict: GO WITH CONDITIONS.

1. OBSERVED: The gold rationing law fails on the art direction's own text. The law reads "Gold is rationed: patrons and Command UI only". But Chorus trim is "a dull gold that reads as chitin ridge", Ithar trim is "pale gold", and epic rarity "stays gold-adjacent". Gold therefore means patrons, Command, epic rarity, and two faction trims: five things wearing one colour, the exact overload the law was written to end.
2. OBSERVED: The two benchmarks pull in opposite directions and no document reconciles them. The context doc states "when a choice trades fleet size against per activation decision weight, take the decision weight". The expansion research builds its cinematic section on Sins scale contrast, fleet view, and fleets colliding. One benchmark says shrink the battle; the other says stage the spectacle. A builder cannot serve both without a stated target battle size, and none is stated.
3. OBSERVED: The only battle composition reference violates the fiction rule it sits next to. The context doc admits "the defender was drawn as a wet navy battleship" for the tableau mock, flagged as stand-in only. A stand-in that is the sole composition example will be copied; the flag does not survive copying.
4. INFERRED: The Chorus rule bans recognizable Earth-animal anatomy, but the flagship Chorus example is a ring formation "that reads as a maw" with a lure light. A maw is animal anatomy by metaphor. The rule as written bans what its own example does by allusion, so Opus has no line to draw the next Chorus admiral against.
5. INFERRED: The Ithar sail rule says sails are "radiant, near-geometric constructions of light", but the kit spec mounts them as physical fins at dorsal and ventral landmarks. Light constructs and mounted fins need different materials, different silhouettes, and different damage states. The docs never say which one the sail is.
6. INFERRED: Deathless green light "as a core/system light rather than a soul light" is a distinction no player can see on screen. Theming that lives only in a document is not theming; it is a note to the author.
7. OBSERVED: The Sins benchmark rests on secondhand evidence: a review excerpt carried by another site, forum testimony, and a Steam discussion. The cinematic recipes built on it (shot timings, beam caps, fade curves) inherit that evidence tier. The doc is honest about its sources; the recipes are not flagged at point of use.
8. INFERRED: The colour law spends gold on patrons, but no document in this pack explains what a patron is to a new player. The council's original finding that patrons are unexplained survives the entire design pack untouched.

## Lens 2: Gamer (fun, readability, player experience)

Verdict: GO WITH CONDITIONS.

1. OBSERVED: The shield differentiation scheme is defeated by the doc's own phone-size argument. Shield identity is carried by "the faction expressed in the ripple's shape only", while the same document admits "glow is the first thing lost at phone size". Shape detail is lost at phone size for the same reason glow is. The law that saves shields (one cyan) is sound; the shape-only faction expression is not.
2. OBSERVED: The two bright fleets are separated by temperature and geometry only: Hegemony hull "pale grey" against Ithar "pearl". Their luminances are near identical, and no screenshot test at fleet view exists in the pack to prove the separation works. The same holds for the dark pair: Corsair rust against Voidsworn warm charcoal, with red glow against ember glow, adjacent hues.
3. INFERRED: The fleet-size contradiction is a fun problem before it is a strategy problem. Current battles run around 20 ships (the 1.32 GB texture figure assumes a 20-ship battle); the Rogue Trader benchmark fields one to three. Readability budgets, animation-time fixes, and the Sins spectacle all depend on a number the docs never state.
4. OBSERVED: The animation-time problem found by the sims is cited as motivation for fewer, heavier activations, but no document sets an activation budget or an animation-time budget. Meanwhile the cinematic section adds charge-ups, trails, shockwaves, and letterboxed arrival shots: more presentation per activation, which worsens the measured problem it cites.
5. INFERRED: The cinematic numbers (12-beam cap, 40 ms fade in, 80 ms fade out, 3.5 second arrival shots) are invented starting values with no playtest behind them. The doc says "tune on device", which is honest, but the section reads as settled recipes and will be implemented as such.
6. OBSERVED: HUD panels fade "to about 30 percent opacity" during capital events. Status information lives in the HUD (the docs put selection and status in HighlightLayer outlines and UI pips). No rule says what counts as non-essential, so the spectacle rule can hide the information the player needs during the exact moment it matters.
7. INFERRED: The fleet-view readability system depends on a third representation tier (icon) for which no icon designs exist anywhere in the pack. The system is specified; its critical layer is undesigned.
8. OBSERVED: The kit spec's screenshot acceptance test is the pack's best player-facing idea (faction readable at a glance, flat-black silhouette sheet). It is also unbuilt: no silhouette sheet exists for any faction, so the grammars it would test are untested claims.

## Lens 3: Software engineer (architecture, feasibility, the kit spec)

Verdict: GO WITH CONDITIONS.

1. OBSERVED: The kit spec never recomputes the 69-session figure it exists to kill. Its proof set is six hero hulls, leaving 30 hulls of manifest work, silhouette review, and screenshot acceptance uncounted. The claim "the 36-hull queue becomes parameter work" is assertion, not arithmetic. Parameter work still scales per hull.
2. OBSERVED: The spec demands ceilings it never sets: "Per-class vertex and triangle ceilings for phone, enforced at build time". No numbers follow. A ceiling with no number cannot be enforced, and the build cannot fail loudly on a limit that does not exist.
3. OBSERVED: The spec claims "A new hull that violates its pack should be impossible to express, not merely discouraged". No validator, type system, schema, or assertion is described anywhere in the spec. INFERRED: as written, the guarantee is unenforceable, and grammar violations will be discouraged at most.
4. OBSERVED: The kit depends on unbuilt components treated as available: "detail defined once in gfx3d.js" (the pipeline audit called for this block; it does not exist yet) and the "joint paint solve" (specified by the audit, not implemented). The work order's foundations are themselves work orders.
5. OBSERVED: The desktop question gives Opus two masters. The context doc records "Recommendation given: desktop first in Babylon" in the same section that states "the Pixel remains the reference device" and that phone budgets still govern. Budgets in the kit spec and the research memo are phone budgets; the recommendation points at desktop. One of these must win before the first budget is written.
6. INFERRED: The WebGPU hybrid is costed as "days to weeks" with no basis, while the tool guides caveat an "uneven mobile WebGPU landscape". A second test tier, WGSL conversions, and graceful degradation are a standing cost, not a one-time branch.
7. OBSERVED: The 40 percent luminance cap has no measurement method: "no background pixel inside the board area may exceed 40%" of an unlit hull facet's luminance. No tool, no test image procedure, no check in the checkpack. A cap without a meter is a wish.
8. INFERRED: The kit's rollout step 4 calls plate wiring "the fastest visual win in the whole overhaul", but the plates are local-only WebP files, the terrain kinds number five against 18 plates with no mapping table, and the in-game format is unspecified (flat backdrop versus 1024-per-face skybox, both appear in the docs). The fastest win is not shovel-ready.
9. OBSERVED: The bake doctrine differs across documents. The tool guides state the merged chain as AI mesh and AI texture joining "only at the bake", while the kit spec bakes "with DETAIL off" from a shared detail block. Two bake doctrines, no reconciliation.

## Lens 4: QA (verifiability, gaps, internal contradictions)

Verdict: GO WITH CONDITIONS.

1. OBSERVED: Credit where due: the manifest is real. Four of 40 hashes recomputed by this council match exactly, and the staging tree holds exactly 40 files in the manifest's categories. But no document records verification of all 40 or when it happened; 36 hashes are taken on trust.
2. OBSERVED: The art direction Status section is stale: "all twelve plates generated (six hero ship studies, six background plates" against Part C2's 18 plates, and "Next, on Ryan's sign-off: push this pack" after the push happened. The status block contradicts the document it closes.
3. OBSERVED: The context doc opens with "The three design documents in this folder" while the folder now holds eight documents. The onboarding document miscounts its own folder.
4. OBSERVED: Secondhand sourcing is honestly flagged in place but not at point of use: Sins from reviews and forums, Rogue Trader internals "inferred from mod behaviour", tool guide entries resting on a third-party guide and a deprecated official page. A builder reading a recipe will not see the evidence tier.
5. OBSERVED: The field guide's headline claim that three passes "converged" on one pattern overstates independence: all three passes were briefed with the same problems, including save integrity named in the briefs. Convergence under a shared brief is not independent discovery.
6. INFERRED: There is no acceptance checklist for the 18 plates as a set. Hulls get a silhouette sheet; plates get no equivalent (luminance cap measured? variant distinctness? region seasoning visible?). The largest approved asset set in the pack has no acceptance test.
7. OBSERVED: Fifteen portraits "can be produced against the same template whenever the game is ready to display them". No display path for portraits is described anywhere in the pack. Portraits are inventory without a shelf.
8. INFERRED: The docs total about 52,000 words with overlapping content (gltfpack in both the expansion research and the tool guides; references versus field guide; two bake doctrines). NOTES.md's division of labour helps, but nothing maps which document wins when two disagree, except the context doc's ruling-wins rule, which covers owner rulings, not Rey's own documents disagreeing with each other.

## Lens 5: Designer (art direction and visual coherence)

Verdict: GO WITH CONDITIONS.

1. OBSERVED: The cyan shield law is the pack's best idea and it survives this audit intact: one hue family for shields across all factions, learned once, readable at arm's length. Keep it.
2. OBSERVED: The silhouette grammars are the pack's second-best idea and the only visual claim in the pack with a test attached (the flat-black sheet). But no sheet exists yet, so the grammars are untested claims, not verified wins.
3. OBSERVED: The bright pair and dark pair separations rely on subtle discriminators (temperature, bone ribs, patchwork) that the docs themselves say vanish at phone size. The art direction's own phone-size logic is its grammars' hardest critic.
4. INFERRED: Eighteen plates against five terrain kinds with no mapping means variant selection is arbitrary. The rule "a fight should not see the same sky twice in a sector" is a scheduling rule with no scheduler attached.
5. OBSERVED: Region seasoning is specified as "a whisper of the home faction's glow colour". A whisper is not a spec. Compare the 40 percent cap, which at least is a number a builder can test.
6. INFERRED: The portrait template locks "the faction's background plate soft and dark behind them", but the plates are local-only and not in the repo. The template depends on assets Opus cannot access without a relay.
7. OBSERVED: The tableau mock is the only battle composition reference and it violates the fiction rule. A composition reference that is a known-bad example will teach the wrong composition.
8. INFERRED: The effects language assigns every faction a distinct death animation, including Deathless reassembly where a segment "flies home". Reassembly is a mechanic, not an effect. The effects section invents a system the game may not have, and no document flags the dependency.

## Chair synthesis

The five lenses converge on three points. First, the pack's two best ideas (cyan shields, silhouette grammars) are sound but untested at the size that matters: phone screens at fleet view. Second, the pack's two load-bearing numbers (kit economics, phone budgets) are asserted, not measured. Third, the pack contradicts itself in small, fixable ways (gold, bake doctrine, desktop versus Pixel, stale status blocks) that will each cost Opus a wrong turn if left.

Ranked top 10 actions:

1. Decide the target battle size (Rogue Trader one to three ships versus current roughly 20). Everything downstream (readability, animation time, budgets, spectacle) depends on it.
2. Prototype the kit on the Basilica only (loft v2 plus the Voidsworn grammar pack plus one manifest) and publish the measured build time, triangle counts, and recomputed 36-hull cost before any other hull or grammar pack is started.
3. Set numeric per-class budgets (triangles and texture megabytes, phone and desktop) and a measurement procedure for the 40 percent luminance cap.
4. Fix the gold leak: either un-ration gold and name its five real uses, or recolour Chorus trim, Ithar trim, and epic rarity off gold.
5. Run the phone-size readability test: screenshot the six hero hulls at fleet-view thumbnail size and redesign any pair that collides (bright pair, dark pair, shield shapes).
6. Write the plate wiring spec: terrain-kind to plate mapping, variant selection rule, in-game format, and the relay plan for 18 local images.
7. Correct the stale blocks (art direction Status, context doc's document count) and add a plate acceptance checklist.
8. Reconcile the bake doctrine and the desktop-first versus Pixel-governs tension into one governing paragraph each.
9. Build the flat-black silhouette sheets for the six heroes; the kit's own acceptance test currently does not exist.
10. Verify the remaining 36 manifest hashes, record the verification, and design the fleet-view icon tier the readability system depends on.

One recommended next step: build loft v2 plus the Voidsworn grammar pack on the Basilica manifest only, and report measured triangle counts, build time, and the recomputed 36-hull queue cost before any other hull, grammar pack, or plate wiring is started. Everything else on this list is cheap to fix after that measurement exists; nothing on this list is safe to build before it.
