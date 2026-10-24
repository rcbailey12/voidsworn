# Reading plan for Opus

From Rey (Muse), Oct 24, 2026. Boundary set by Ryan the same morning: Opus owns the task plan for this codebase, as coder, verifier and orchestrator. This document orders reading only. It does not assign tasks, sequence implementation work, or set priorities. What Opus builds first, and in what order, is Opus's decision. This plan exists so the context lands correctly before that decision is made.

## Errata: read this before anything else

These corrections postdate parts of the design documents. Carry them into every document below:

1. **All 36 hull meshes already exist and the game loads them.** Verified against ships3d.js:800-801 and gallery.py:183: `hulls/` on phone, `hulls_hi/` on desktop, 108 files per tier, and only C19_51 has the compressed `.vsm` plus `_kit.json` path. The procedural builder still runs, but only for anchors (guns, engines, nav lights, turrets). The manifest and kit job is therefore dressing, paint unification and VSM format conversion of existing meshes, not hull shape generation.
2. **SHIP_QUEUE "not started" means pipeline steps, not mesh existence.** The asset inventory proved the meshes exist; the queue rows are stale paperwork on that point.
3. **Gold law REPAIRED Oct 24, 2026; the original text is superseded.** The repair lives in reviews/gold_law_synthesis.md: Chorus rename-first (chitin ridge ochre, dull gold #a4913a kept, matte non-metallic) with a recolor fallback, Ithar rename-first (ivory filigree, pale gold #d7c88a kept) with a recolor fallback, epic recolor to violet-magenta, Belt and Nursery rename-first with fallbacks, and a merged blind viewer test. The gold panel was decided in reviews/acceptance_measurability_synthesis.md (7 viewers, 7/7 do not name Command gold). Adoption plus the viewer test are Opus's.
4. **Density and difficulty, ruled Oct 24, 2026.** Ryan leans 20 ships TOTAL on board ("20 total probably": more would mean too many turns and directions), and difficulty MAY ramp by more ships as a run goes, rejecting the density draft's dial-invariance proposal (intended feel: an elite unit punching above its weight class). The feel target remains the three-way mix (BattleTech plus Sins 2 plus Rogue Trader; see CONVERSATION_CONTEXT section 9). Reconciling the ship-count ramp with the 20/24 envelope is Opus's.
5. **Plate mapping EXISTS as a single-leg synthesis.** reviews/plate_mapping_synthesis.md (DeepSeek leg only) maps all 18 plates: 5 anchors to the 5 code terrain kinds, 6 variants inheriting parent kinds, 6 specials under a proposed anomaly role. Dead Star is background-only per Ryan's Oct 24 ruling (not a sixth kind, not a well mechanic). Variant and special trigger rules are NOT adoptable until Opus checks each state hook. The Qwen leg retries Oct 25, 2026 about 09:45 CDT and folds into an updated two-leg synthesis; until then treat the synthesis as provisional on the Qwen dimension. Plate files remain local only.
6. **The field guide's "convergence" claim overstates independence.** Its three research passes were briefed with the same problems, so their agreement is weaker evidence than three independent discoveries would be.

## Reading order

Total design folder size is about 61,200 words. Do not read it linearly. Read in this order and stop as soon as the context for the decision at hand is in hand.

### 1. NOTES.md (about 850 words)

The folder map: what each area holds, the authority ladder, what is unfinished. Read first, every time, when returning after a gap.

### 2. design/CONVERSATION_CONTEXT.md (about 1,800 words)

The owner's rulings and the list of what he has explicitly not decided (section 7). Rulings beat every other document in this folder, including this plan. Where a ruling and a proposal disagree, the ruling wins and the proposal should be corrected. Section 9 is the Rogue Trader feel benchmark ruling.

Take from it: what is decided, what is explicitly undecided, and the failure modes from the portrait and plate rounds.
Do not take from it: anything as an implementation order. The undecided list is a list of open questions, not a queue.

### 3. design/design_council_audit.md (about 2,600 words)

The five-lens adversarial audit of this folder's own documents, unanimous GO WITH CONDITIONS, 41 findings. Read this before the proposals, so the caveats frame them: the kit spec's economics are asserted rather than measured, per-class ceilings are demanded but never set numerically, and phone-size readability schemes defeat themselves in places.

Take from it: what in the pack is load-bearing and what is unproven.
Do not take from it: a task list. Its ranked actions are findings to weigh, not assignments.

### 4. design/art_direction_rey.md (about 3,500 words)

The governing direction: colour laws, silhouette grammars, hero concepts, the background plate system, the portrait system.

Take from it: the direction to judge visual work against.
Do not take from it: approval. This is a proposal for Ryan's verdict, and the gold rule carries the erratum in section 1 above.

### 5. design/ship_kit_upgrade.md (about 1,200 words)

The kit work order: loft v2, six faction grammar packs, the feature module library, hull manifests, budget gates, the Pixel stress gate, silhouette-sheet acceptance.

Take from it: the proposed mechanism (manifests plus grammar packs plus modules) and its acceptance tests.
Do not take from it: the economics. The 69-session figure was the hand-built kit rate, and the spec never recomputes the queue cost for dressing 35 existing meshes. Also note: the Basilica manifest the spec points at as its proof exemplar does not exist as a file yet; whether to write it, and when, is Opus's call, not an assignment from this plan.

### 6. The reference shelf (read per need, never linearly)

- design/visual_expansion_research.md (about 11,900 words): techniques, tools, engine verdicts, the cinematic section.
- design/GRAPHICS_REFERENCES.md (about 11,200 words): reference games, modding masterclasses, repos, kick-off assets, games actually like Voidsworn, plus the Star Citizen and Squadron 42 graphics-and-effects top-up.
- design/mod_scene_field_guide.md (about 10,300 words): wider mod scene mechanisms and grabbable assets, indexed by problem. Read its front section for the shared pattern; read the rest per problem.
- design/tool_guides.md (about 14,300 words): Blender, Babylon, pipeline glue, AI meshes and local image models. Read per tool, per task.
- design/graphics_craft.md (about 3,200 words): the craft layer (tonemapping, TAA and ghosting, VFX timing, readability, overdraw, accessibility with hard numbers).
- design/claude_skills.md (about 3,400 words): Agent Skills format, community collections, MCP servers (Blender Lab server first), screenshot evidence and blocking validator patterns.
- design/beauty_corner_spec.md (about 3,300 words): the standalone test scene spec, effects proven one by one with frame rate and budget gates, plus reference scoring against the concept plates.
- design/visual_qa_pack.md (about 3,500 words): the screenshot QA pack, capture list, per-shot checklists, scoring rubric, multimodal review packaging, owner verdict loop, plus reference scoring.

Take from these: mechanisms, settings, recipes and sources, each with its own licence and confidence flags in place.
Do not take from these: anything marked secondhand (forum and Reddit wisdom, third-party walkthroughs) as if it were documentation, and nothing version-sensitive (Blender menus, Babylon constants, addon prices) without checking the installed version.

### 7. Evidence on demand

- reviews/: read council_reconciliation.md instead of the three councils when time is short; the pack screenings are the verification layer over the external returns; single reviews (battle rules, enemy AI, effects and world, UI, independent audit, career and story, space_3d, faction asymmetry) per topic.
- design/verification_sweep.md: the Oct 24, 2026 record of which flagged claims in the design documents were verified, corrected or left unverified against primary sources. Corrections from it are already applied to the documents; read it to see what is still open (TripoSG licence, FTL Hyperspace licence, ESA audio terms) rather than re-checking the same sources.
- compute/: read its README.md as the index. Code index, content census and asset inventory are lookup data, basis HEAD 51337c2; trust the repo if it has moved. The balance reference joins this folder when the mega sim finishes.
- prompts/: historical pack files, unless another external run is commissioned.
- Other agents' folders: orientation is in NOTES.md. Raw DeepSeek and Qwen transcripts are archive only, read solely to check a distilled claim. Gemini is leads only, never a citation source unscreened.

## Stop rules

- Stop reading when the context for the decision at hand is in hand. The shelf exists to be consulted, not completed.
- Do not re-read a document to settle a question its own errata or the council audit already flags as open. Open questions go to Ryan or to Opus's own judgment, not back into the same pages.
- Do not treat any Rey document as an approval, a task assignment, or a verification gate. Code claims in Rey's deliverables are observations for Opus to confirm, and the findings registry and code truth are Opus's to own.

8. **Oct 24 human rulings are collected in OPUS_HANDOFF.md (same folder).** That briefing is the decision state as of about 14:20 CDT Oct 24: every human-direction question closed, the Opus pile listed, the barge upgrade commissioned as GO, and the orchestration method for the DeepSeek, Qwen, and Gemini work documented. Where this plan and the briefing disagree, the briefing wins on decision state; this plan still governs reading order. Price ladder synthesis is single-leg like plate mapping (DeepSeek only; Qwen leg retries Oct 25 about 09:45 CDT).

7. **Platform ruling, Oct 24, 2026: PC-only.** The phone target is dropped entirely. The desktop GPU budget is the design floor; there is no phone tier, no phone pass, and no phone acceptance gate. Documents written phone-first are superseded on this point by the ruling: the kit spec's Pixel stress gate and phone ceilings, the beauty corner and QA pack gates as first written (including their 'both tiers' batching, struck Oct 24, 2026), the UI review's phone findings, and the three largest phone-framed documents, the visual expansion research memo ('must perform on a mid-range Android phone'), the tool guides ('phone first with a desktop tier'), and the graphics craft doc ('phone first, desktop tier'). The re-tiered specs record the new gates; the research memo, tool guides, and graphics craft doc still carry phone-first framing in their bodies and need a re-tiering pass before they are used as build guidance. **Engine question REOPENED Oct 24 about 15:28 CDT:** the prior "engine stays Babylon" stance is under active review (Babylon vs Godot vs Rust vs other); NO MIGRATION DECIDED. The engine comparison (research batch 1, two legs) leans stay-on-Babylon for fastest shipping with Godot 4 as the evidence-backed mover; if a switch wins, the kit commission's target needs revisiting (Opus-plus-Ryan call). Battle size stays near the current scale (around 20 ships); PC headroom goes to graphics and effects, not much larger battles. The feel target is a three-way mix: BattleTech (tactical weight, location damage) plus Sins 2 (cinematic spectacle) plus Rogue Trader (small-fleet decision weight); see CONVERSATION_CONTEXT section 9.

9. **Research batches and background pack, Oct 24, 2026.** The Reddit research program (read-only, topic-batched) produced batches 1 through 7, all complete, filed under contrib/muse/research/ (Rey legs) and contrib/deepseek/research/ (DeepSeek legs): batch 1 engine comparison, batch 2 subreddit mining, batch 3 Nemesis plus events, batch 4 wings plus tactics UI, batch 5 ship physics plus graphics plus motion, batch 6 Opus 5.5 plus Blender workflow, batch 7 focused effects pass. A batch 8 (asset packs, material packs, prebuilt assets, template and kit systems) was commissioned late Oct 24 with two legs running; it folds into OPUS_HANDOFF.md when both legs land. The Gemini background pack is filed at contrib/gemini/reviews/gemini_background_pack_argon_high.md (screened CLEAN; treatments stand if the engine changes, Babylon-specific implementation notes re-scope). All research batches are leads, not decisions; the Opus pile in OPUS_HANDOFF.md section 2 carries their design inputs, and each batch's chair screening lives in Rey's goal hidden files, not in the repo.

## Decisions reserved

- Opus: tasking, sequencing, code truth, the findings registry, and whether a filled exemplar (such as a Basilica manifest) is the right first artifact.
- Ryan: visual verdicts, the undecided list in CONVERSATION_CONTEXT.md section 7, and approvals. Nothing in this folder is approved until he says so.
- Rey: external point of view only (audits, lenses, evidence packs, design and text proposals, cross-model synthesis, heavy compute). Rey does not assign Opus work.
