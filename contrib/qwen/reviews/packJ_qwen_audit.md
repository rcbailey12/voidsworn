# Pack J adversarial audit: Qwen report (raw return, unverified archive)

Source: Qwen chat, model Qwen3.7-Plus, Thinking mode ON, Search OFF. Pack J uploaded as .txt on the first attempt (no rename needed, no PDF used). Sign-in completed after the user's phone approval. Report received Oct 24, 2026 via browser task. Filed verbatim below. Rey's screening and the three-way reconciliation are separate documents; nothing in this file is a verdict.

## 1. Engineer
Verdict: NO-GO
Recommended Next Step: Rewrite ship_kit_upgrade.md to remove shape-generation tooling and provide a measured time estimate for dressing, paint unification, and VSM conversion of the 36 existing meshes.
Contradictory Kit Scope (High Damage)
Quote: "The manifest and kit job is therefore dressing, paint unification and VSM format conversion of existing meshes, not hull shape generation." (READING_PLAN.md)
Mark: OBSERVED. The spec wastes massive detail on "Section loft v2" and "Faction grammar packs" for procedural shape generation when the errata confirms all 36 hull meshes already exist.
Unmapped Plate Wiring (High Damage)
Quote: "There are 18 background plates against five terrain kinds with no mapping in any document... Nothing about plate wiring is shovel-ready." (READING_PLAN.md)
Mark: OBSERVED. A core visual feature cannot be implemented because the data mapping between terrain kinds and plate files does not exist.
Unmeasured Kit Economics (Medium Damage)
Quote: "the spec never recomputes the queue cost for dressing 35 existing meshes." (READING_PLAN.md)
Mark: OBSERVED. The 69-session figure is for hand-building from scratch, making the current pipeline budget a complete guess.
Lingering Phone Constraints (Medium Damage)
Quote: "Per-class vertex and triangle ceilings for phone, enforced at build time" (ship_kit_upgrade.md)
Mark: OBSERVED. Despite the Oct 24, 2026 PC-only ruling, the kit spec still enforces phone budgets, creating contradictory build gates.
Unverified Tool Licences (Medium Damage)
Quote: "TripoSG licence: STILL UNVERIFIED" and "FTL Hyperspace licence: STILL UNVERIFIED." (verification_sweep.md)
Mark: OBSERVED. Any pipeline or modding architecture relying on these tools is legally blocked until primary sources are found.

## 2. Designer
Verdict: GO WITH CONDITIONS
Recommended Next Step: Force an explicit owner ruling to reconcile the gold colour law exception and lock a hard target battle size number to resolve benchmark tension.
Benchmark Tension Unresolved (High Damage)
Quote: "The two benchmarks pull in opposite directions and no target battle size is stated anywhere." (READING_PLAN.md)
Mark: OBSERVED. Rogue Trader demands decision weight (small fleets), while Sins 2 demands spectacle (large scale), creating a fundamental design rift.
Gold Law Contradiction (High Damage)
Quote: "Gold rationing fails on its own text... colour law says gold is patrons and Command only, but Chorus trim is dull gold" (READING_PLAN.md)
Mark: OBSERVED. The single source of truth for colour is actively violated by the faction palettes it defines, breaking the "one law for colour".
Spectacle vs Scale Dissonance (Medium Damage)
Quote: "Target battle size stays near the current scale (around 20 ships)" (CONVERSATION_CONTEXT.md)
Mark: INFERRED. Twenty ships cannot deliver the "capital-ship spectacle" and "scale contrast" demanded by the Sins 2 benchmark, making the visual target unbuildable at the stated scale.
Undecided Asymmetry Mechanics (Medium Damage)
Quote: "The five owner decisions on the asymmetry decision page" (CONVERSATION_CONTEXT.md)
Mark: OBSERVED. The BattleTech location-damage mix lacks mechanical grounding because core asymmetry decisions remain explicitly undecided.
Chorus Naming Violation (Low Damage)
Quote: "A Chorus admiral's name describes what it does... never an animal body part" (CONVERSATION_CONTEXT.md)
Mark: OBSERVED. Yet art_direction_rey.md names an admiral "Razormaw" and describes a "ring that reads as a maw", directly violating the ruling.

## 3. Gamer
Verdict: GO WITH CONDITIONS
Recommended Next Step: Build a playable prototype of the shield ripple and micro-damage states to verify they are readable at actual in-game battle zoom, not just in hero framing.
Shield Readability at Distance (High Damage)
Quote: "art direction carries shield identity in ripple shape only, while the same document set admits glow is the first thing lost at small size" (beauty_corner_spec.md)
Mark: OBSERVED. If glow is lost at small size, and shape is the only other carrier of faction shield identity, the shield language will fail at battle zoom.
Micro-Damage Invisibility (Medium Damage)
Quote: "damage is readable at fighting zoom, not only at hero zoom" (visual_qa_pack.md)
Mark: INFERRED. art_direction_rey.md describes Ithar sails tearing "panel by panel" and Deathless losing "a rib segment". These micro-details are mechanically invisible at fighting zoom.
Torpedo Herding on Hex Grid (Medium Damage)
Quote: "torpedoes with travel time that herd movement" (GRAPHICS_REFERENCES.md)
Mark: INFERRED. Rogue Trader uses free-movement gridless space. "Herding" movement with multi-turn torpedoes is mechanically unexplained and likely broken on a rigid hex tactics grid.
Hit-Stop Pacing Risk (Medium Damage)
Quote: "too much hit-stop in a 20 ship battle makes the game feel slow" (graphics_craft.md)
Mark: OBSERVED. In a turn-based game with ~20 ships, simultaneous hits will trigger constant micro-pauses, destroying the tactical flow the game claims to prioritize.
UI Density vs Restraint Clash (Low Damage)
Quote: "white and blue boxes, flat panels, zero thematic flair" (visual_expansion_research.md)
Mark: INFERRED. The demand for "cinematic UI restraint" directly conflicts with the BattleTech "paper doll" requirement for dense, per-location damage readouts.

## 4. Sci-fi (Fiction Coherence)
Verdict: GO WITH CONDITIONS
Recommended Next Step: Redesign the Matriarch portrait to remove "organ pipes" and secure an explicit owner waiver for the Ithar "seven-fingered hands" description to avoid the costumed-human failure mode.
Chorus "Organ Pipes" Contradiction (High Damage)
Quote: "buildings, instruments and architecture [are] banned" (CONVERSATION_CONTEXT.md)
Mark: INFERRED. art_direction_rey.md describes the Matriarch as "a faceless column of membrane organ pipes". Organ pipes are constructed instruments, directly violating the ruling.
Ithar "Costumed Human" Risk (High Damage)
Quote: "should not look like norwegian humans, but something truly beautiful and alien/other." (CONVERSATION_CONTEXT.md)
Mark: INFERRED. art_direction_rey.md gives Aelith "huge wide-set black eyes... seven-fingered hands". This is functionally a costumed human with minor tweaks, risking the explicitly banned failure mode.
Deathless "Bone" vs "Machine" (Medium Damage)
Quote: "deathless should be like robots or something AI/cybernetic/robot." (CONVERSATION_CONTEXT.md)
Mark: INFERRED. art_direction_rey.md gives them "pale bone-white structural ribs" and "face-like prow plates". Bone and face-like features contradict pure machine intelligence, leaning into necromantic fantasy.
40k Terminology Bleed (Medium Damage)
Quote: "borrowed 40k terms in data.js for purge" (CONVERSATION_CONTEXT.md)
Mark: INFERRED. art_direction_rey.md names the faction "Voidsworn Crusade" and uses "rood screen", "liturgical military", and "votive seals", skirting the explicit purge order.
Hegemony "Naval" Contradiction (Low Damage)
Quote: "Space ships, never naval ships." (CONVERSATION_CONTEXT.md)
Mark: OBSERVED. art_direction_rey.md describes Hegemony material as "painted naval ceramic", directly using the banned terminology.

## 5. QA (Verification)
Verdict: NO-GO
Recommended Next Step: Halt pipeline dependencies on unverified tools and replace subjective "vibes" acceptance tests with scripted, automated measurement tools.
Blocked by Unverified Licences (High Damage)
Quote: "TripoSG licence: STILL UNVERIFIED" and "FTL Hyperspace licence: STILL UNVERIFIED." (verification_sweep.md)
Mark: OBSERVED. The modding and asset pipeline cannot be finalized while core tool licences remain legally unknown.
Unmeasured Kit Economics (High Damage)
Quote: "the kit spec's economics are asserted rather than measured" (READING_PLAN.md)
Mark: OBSERVED. Relying on a "69-session figure" for hand-built kits to estimate the cost of dressing 35 existing meshes is a QA failure.
Vibes-Based Acceptance (Medium Damage)
Quote: "a viewer who has never seen the hull names the faction in under three seconds" (visual_qa_pack.md)
Mark: OBSERVED. This is a subjective "vibes" test, not a measurable, automated, or reproducible QA acceptance criterion.
Undefined Luminance Measurement (Medium Damage)
Quote: "no background pixel... may exceed 40 percent of the luminance of an unlit hull facet" (beauty_corner_spec.md)
Mark: INFERRED. Programmatically measuring the luminance of a dynamically lit "unlit hull facet" across 18 plates is complex and entirely undefined in the tooling guides.
Inferred Modding Internals (Low Damage)
Quote: "Rogue Trader's data internals are inferred from mod behaviour, with no Owlcat developer document found" (mod_scene_field_guide.md)
Mark: OBSERVED. Basing a core "save doctor" mechanic on inferred behaviour rather than primary documentation is a fragile QA foundation.

## Not Checked
Image Manifest Hashes: I did not verify the 40 final image SHA-256 hashes because the binary WebP images are explicitly stated to not be in the repo (CONVERSATION_CONTEXT.md).
Runtime Performance: I did not execute Babylon.js code to verify frame rates, draw calls, or VRAM usage, as I am an AI text model without a live WebGL/WebGPU runtime environment.
Blender Addon Pricing: I did not independently verify current market pricing for UVPackmaster, Zen UV, etc., beyond the Oct 24, 2026 sweep provided in the text.

## Ranked Top 10 Findings Across All Lenses
1. Engineer: Kit scope contradiction (building shape-generation tools for meshes that already exist).
2. Designer: Gold rationing law fails on its own text (Chorus/Ithar trim violates the "patrons and Command only" rule).
3. QA: Unverified licences (TripoSG, FTL Hyperspace) legally block pipeline and modding architecture decisions.
4. Engineer: Background plate wiring is completely unmapped, making the feature not shovel-ready.
5. Sci-fi: Chorus "organ pipes" description directly violates the explicit "no instruments/architecture" owner ruling.
6. Designer: Benchmark tension (Rogue Trader decision weight vs Sins 2 spectacle) remains fundamentally unresolved.
7. Gamer: Shield identity relies on ripple shape, which the docs admit is the first thing lost at small battle zoom.
8. QA: Kit economics are asserted (69 sessions) rather than measured for the actual dressing/VSM-conversion task.
9. Sci-fi: Ithar Aelith description ("seven-fingered hands") risks the explicitly banned "costumed human" failure mode.
10. Gamer: Micro-damage states (panel-by-panel tearing, lost rib segments) are mechanically invisible at the required "fighting zoom".

## What evidence would change these verdicts:
- Engineer/QA: A revised ship_kit_upgrade.md that deletes shape-generation tooling, provides a measured time estimate for dressing existing meshes, and primary source licence files for TripoSG and FTL Hyperspace.
- Designer: An explicit owner ruling reconciling the gold colour law (e.g., "pale gold is permitted for Ithar as a non-metallic ceramic inlay") and a hard, numerical target battle size.
- Gamer: A playable prototype or recorded video demonstrating that shield ripple shapes and micro-damage states are clearly readable at the actual in-game battle zoom, not just in hero framing.
- Sci-fi: Owner approval explicitly waiving the "no instruments" rule for the Matriarch's organ pipes, or a redesign of the Matriarch to pure flesh/sacs to align with the ruling.
