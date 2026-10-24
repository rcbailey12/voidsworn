# Pack J three-way reconciliation: DeepSeek vs Qwen 3.8-Max vs Rey's design council audit

Chair: Rey. Basis: Pack J (73,322 words, commit 663ad30f), read blind by DeepSeek (DeepThink on, search off) and Qwen 3.8-Max (Thinking on, search off), reconciled against Rey's design council audit (contrib/muse/design/design_council_audit.md, unanimous GO WITH CONDITIONS, 41 findings). The Qwen 3.7-Plus run (packJ_qwen_audit.md) is archived but superseded as the Qwen leg by the 3.8-Max run.

Reading condition that matters: both external models read Pack J as built Oct 24, before the fix commits d5580ccd and b9d4f9f and before the fixes in this reconciliation pass. Findings marked FIXED were true of Pack J and are no longer true of main. Nothing below is a verdict for Ryan until he rules on the decision list at the end.

## Verdicts by lens

| Lens | DeepSeek | Qwen 3.8-Max | Council audit |
| Engineer | GO WITH CONDITIONS | GO WITH CONDITIONS | GO WITH CONDITIONS (kit economics is its #1) |
| Designer | GO WITH CONDITIONS | GO WITH CONDITIONS | GO WITH CONDITIONS |
| Gamer | GO WITH CONDITIONS | GO WITH CONDITIONS | GO WITH CONDITIONS |
| Sci-fi | NO-GO, scoped to Chorus and Deathless identity | GO | Harshest lens (called the pack a likeable collage, not yet a universe) |
| QA | GO WITH CONDITIONS | NO-GO, driven by licences | GO WITH CONDITIONS |

Chair's overall verdict: GO WITH CONDITIONS. The direction is unanimous except two scoped NO-GOs, and both name their own fixes: DeepSeek's Sci-fi NO-GO is about Chorus and Deathless wording (reword or regenerate), and Qwen's QA NO-GO rests on licence blocks the chair downgrades below (see contested item 10).

## Consensus: all three agree, or both externals plus the council

1. Gold law fails on its own text. "Gold is rationed: patrons and Command UI only" against Chorus dull gold trim, Ithar pale gold trim, and gold-adjacent epic rarity. The QA gate built on it cannot pass two factions' hulls.
2. Plate wiring is unmapped. 18 plates against five terrain kinds, no mapping document, so the background system is not shovel-ready.
3. Kit economics are asserted, not recomputed. The 69-session figure is a hull-creation rate applied to a dressing job. Nobody has costed dressing, paint unification, and VSM conversion of the 36 existing meshes.
4. Shield identity by ripple shape alone is unproven at battle zoom. Glow is the first thing lost at small size, and shape is the only other carrier. No evidence in the pack shows it passing at fighting zoom.
5. Phone-first stale premises run through the corpus. All three lenses found them independently of each other.
6. Kit mechanisms are named, not specified. A grammar pack with no validator (council #1, DeepSeek E3), per-class ceilings with no numbers (council, DeepSeek E4, Qwen), a manifest and landmark system with no schema (DeepSeek E5), a loft with no interpolation scheme (DeepSeek E2), a paint solve with no gain value (DeepSeek E8).
7. Acceptance tests are partly subjective. "A viewer" with no sample size, pass rate, or viewer profile (DeepSeek D10/Q6, Qwen vibes point, council QA).
8. The 40% luminance cap has no named reference facet (DeepSeek D9/Q8). The cap varies by a factor of several between the dark Voidsworn hull and the bright Hegemony hull. Qwen's "muddy backgrounds" worry is the same tension from the other side.
9. The Chorus wording problems are real. Both externals independently flagged the Matriarch's organ pipes against the no-instruments ban.

## Contested: settled by grep, with the chair's verdict

1. Razormaw. The ruling itself carves out formation names, and Razormaw is a blade formation. Both Qwen models missed the carve-out entirely. DeepSeek acknowledges it but objects to the word itself ("maw" is still a mouth word). Chair: the ruling stands unless Ryan changes it, but three external models tripping on the same word is evidence the word costs more than the carve-out saves. Ryan's call, not a doc error.
2. Errata battle-size staleness. FIXED (commit b9d4f9f). DeepSeek Q1 and Qwen's errata quote were true of Pack J and are stale now.
3. Kit phone ceilings and phone-width frame. FIXED (commit d5580ccd). DeepSeek E4's "for phone" quote is stale-at-read. The underlying point (no numbers at all) stands and is consensus item 6.
4. "Both tiers" remnants in the specs. FIXED in this pass (beauty corner cut order, QA pack sections 2b, 2c, 2d, and batch definition, all now desktop only). DeepSeek D7 confirmed by grep before the fix.
5. Errata phone-doc coverage. REAL, FIXED in this pass. DeepSeek Q2 was right: errata item 7 named only the kit gate, the spec gates, and the UI phone findings. It now names the research memo, the tool guides, and the graphics craft doc as well.
6. TAA in graphics_craft. Qwen 3.8-Max is wrong. The craft doc was patched in Round 4 and states the TAARenderingPipeline position correctly (verified by grep).
7. "Cathedrals violate never naval." Qwen 3.8-Max misreads the ruling. "Never naval" is about ship design language (space ships, not wet-navy ships); a cathedral is architecture, and the Basilica's cathedral grammar is an explicit art choice.
8. Officer-post scaling ("120 micro-decisions"). Qwen 3.8-Max misapplies the benchmark. Rogue Trader's six posts are flagship-level, not per-ship, and Voidsworn has no officer posts. The underlying question (decision weight at 20 ships) is real and sits in decision item 4.
9. Vesper propulsion. Weak. "No visible engines, light bending" is an Ithar light-drive signature, and Ithar propulsion in-fiction is radiant light structures, not reaction engines.
10. Licence blocks. Overstated by Qwen (both runs). TripoSG, FTL Hyperspace, and ESA audio terms are unverified, but none is a dependency of its pipeline: TripoSG is kept out of shipped recommendations, Hyperspace is a field-guide reference, ESA audio is one source among several. DeepSeek's QA verdict (GO WITH CONDITIONS) does not press this, which is the better-calibrated read. The licences stay open as verification items, not blockers.
11. Reference scoring ground truth. Guarded, not broken. The corner spec already limits scoring to a tone and lighting gate and states a high score on a wrong-looking ship is still a fail. DeepSeek's caution stands as a reminder for whoever runs the gate.
12. Battle size, 20 vs 1-3. NOT settled by grep; it is a design judgment. The ruling ("around 20 ships") and the mix ruling (spectacle from effects and camera, not count) stand. DeepSeek's D1/G3 is the sharpest form of the tension: the pack never explains how per-activation decision weight survives at 20 ships. Qwen's proposed "6 heavy ships" is Qwen's invention, not a ruling, and must not displace Ryan's number.
13. Deathless bone and face wording. Genuine tension, verified in the text ("bone-white structural ribs", "prow plate like a blank face" against "sensor light instead of faces"). Whether bone is a ceramic metaphor or a literal claim is Ryan's wording decision.
14. Aelith's seven-fingered hands. All three external lenses flagged it. Chair: risk, not proof. Seven fingers is the non-human marker the doc points at; whether the portrait reads as a costumed human is Ryan's visual verdict.
15. Battle tableau final vs stand-in. Internal contradiction, CONFIRMED by grep. The pack summary counts the tableau as complete and approved while the art text says its defender is a wet-navy stand-in only. FIXED in this pass with an explicit exception note on the pack summary.

## Unique findings: only one model caught these

DeepSeek only (all verified by grep unless noted):
- Six anchor plates against five terrain kinds, and Dead Star has no terrain kind (battle.js:193 lists belt, station, planet, storm, graveyard). The mapping gap is worse than "unmapped": one anchor has nowhere to map to.
- The 1.32 GB texture figure for a 20-ship battle is asserted without derivation and sits uneasily against the 1K-per-hull-family guidance (ship_kit_upgrade.md:15).
- The Dead Star plate is "the argument for the well mechanic on sight alone," but no well mechanic is defined anywhere. Dangling reference.
- The luminance reference facet is unnamed (see consensus item 8).
- The kit underspecification detail: loft scheme, validator, manifest schema, paint gain (see consensus item 6).
- The field-guide convergence caveat lived only in the errata, not in the field guide itself. FIXED in this pass with an inline caveat.
- The research memo's verification claim ("no entry relies on a link that was not opened") is weaker than the sweep's standard, which corrected three of its claims.
- Corsair "stolen Hegemony grey" may blur the Hegemony/Corsair read at distance (mitigated in-doc by the bolted, scarred, misaligned note; still a battle-zoom test item).
- Voidsworn warm black vs Deathless cold black may merge at silhouette distance (mitigated in-doc by ribcage geometry; still a sheet-test item).
- Effects are proven in isolation and the combined test is a single frame, not a 60-second brawl. The corner's 60-second run record exists, but the QA combined-effects check is frame-scoped.
- The silhouette sheet is rendered at desktop size, and battle zoom may be a different size. The sheet should be checked at fighting zoom, not just desktop frame.

Qwen 3.8-Max only:
- Colourblind shield check. Cyan-only shields need a non-hue channel that survives at battle zoom. FIXED in this pass: added to the QA pack's colour law checklist (deuteranopia and protanopia simulation on every shield-hit shot).
- Desktop VRAM ceiling unmeasured. Fair, and by design deferred to the beauty corner measurement run.
- Manual-budget tension: the QA pack's multi-shot batches sit uneasily with Ryan's hard manual budget, even with batching.
- WebGPU fallback as a maintenance trap (two rendering capabilities from boot). Partially fair as a caution; the research memo frames WebGPU as a hybrid path, not a scene swap.
- Trail overdraw, Corsair asymmetry readability, HUD fade during the capital beat, and per-faction destruction pacing. All fair beauty-corner test items. HUD fade is mitigated by the beat being non-interactive (3.5 seconds, data returns before input resumes) but worth verifying.

Council only:
- The chair's recommended next step (prototype loft v2 plus the grammar pack on the Basilica manifest, reporting measured triangle counts, build time, and recomputed queue cost). DeepSeek's E10/D5 reframes it: the Basilica manifest does not exist as a file yet, and whether to write it first is Opus's parked call, so the chair step needs the manifest before it can run.

## Fixes applied during this reconciliation

- READING_PLAN errata item 7 now names all phone-first documents (research memo, tool guides, graphics craft) alongside the kit gate, spec gates, and UI phone findings.
- Beauty corner cut order and QA pack sections 2b, 2c, 2d plus the batch definition: "both tiers" struck, desktop only.
- Art direction pack summary: battle tableau explicitly excepted as a stand-in, not a final plate.
- Field guide convergence claim now carries the errata caveat inline.
- QA pack colour law checklist: colourblind shield simulation check added (from Qwen 3.8-Max).
- Earlier in this pass: kit phone ceilings and frame to desktop, art doc phone-size phrasing, errata battle-size staleness (commits d5580ccd, b9d4f9f).

## Decisions for Ryan (the verdict queue, updated)

1. Gold law repair. Which text wins: the rationing rule, or the faction trims and epic rarity? The QA gate is blocked until this is answered.
2. Chorus admirals. Reword, regenerate, or waive? The comb-jelly description is the clearest violation (sea creature, banned in terms), organ pipes second (instrument), stitching third (constructed action), Razormaw the judgment call (permitted by the ruling's own carve-out, disliked by all three external models).
3. Deathless bone and face wording. Metaphor for ceramic, or literal? The answer decides whether the hull grammar needs rewording.
4. Battle size. Keep "around 20 ships" and add a per-activation density statement explaining how decision weight survives at that count, or lock a different number. Qwen's 6 is not on the table unless Ryan puts it there.
5. Plate mapping. Dead Star needs a role (a sixth terrain kind, or a non-terrain plate role), and the full plate-to-terrain map needs writing. Until then the "fastest visual win" is blocked.
6. Luminance reference facet. Chair recommendation: a fixed mid-grey calibration swatch, not a faction hull, so the cap is one number. This changes the cap's definition, so it needs owner sign-off.
7. Kit rewrite commission. Rewriting the kit doc as a dressing, paint, and VSM-conversion job with a manifest schema and numerical desktop ceilings is substantial proposal work in Rey's lane. Not started; needs a commission.
8. Tool guides re-tiering pass. The largest remaining phone-first body. Not started; needs a commission, since some phone notes are dead framing and others are transferable optimization advice.
9. Acceptance test measurability. Sample size, pass rate, and viewer profile for the "viewer" tests, plus the named reference facet. A spec edit, or Opus measurement work.
10. Torpedo-on-hex and boarding rules. The pack proves the visuals only, by design. The rules live in battle code, not the design pack; flag for Opus, not a design-pack fix.

## Not checked (carried forward, all three sources agree these are open)

Image hashes (binaries not in repo), runtime frame rates and VRAM on desktop hardware, the installed Blender version on Ryan's PC, the Blender Lab MCP licence from a primary source, TripoSG, FTL Hyperspace, and ESA audio licences, the mega sim balance reference (still running at pack time), and the 15 ungenerated admiral portraits.
