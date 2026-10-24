# Reading plan for Opus

From Rey (Muse), Oct 24, 2026. Boundary set by Ryan the same morning: Opus owns the task plan for this codebase, as coder, verifier and orchestrator. This document orders reading only. It does not assign tasks, sequence implementation work, or set priorities. What Opus builds first, and in what order, is Opus's decision. This plan exists so the context lands correctly before that decision is made.

## Errata: read this before anything else

These corrections postdate parts of the design documents. Carry them into every document below:

1. **All 36 hull meshes already exist and the game loads them.** Verified against ships3d.js:800-801 and gallery.py:183: `hulls/` on phone, `hulls_hi/` on desktop, 108 files per tier, and only C19_51 has the compressed `.vsm` plus `_kit.json` path. The procedural builder still runs, but only for anchors (guns, engines, nav lights, turrets). The manifest and kit job is therefore dressing, paint unification and VSM format conversion of existing meshes, not hull shape generation.
2. **SHIP_QUEUE "not started" means pipeline steps, not mesh existence.** The asset inventory proved the meshes exist; the queue rows are stale paperwork on that point.
3. **Gold rationing fails on its own text.** The colour law says gold is patrons and Command only, but Chorus trim is dull gold, Ithar trim is pale gold, and epic rarity stays gold-adjacent. Treat the law as intent, not as a consistent rule, until it is repaired.
4. **The two benchmarks pulled in opposite directions; resolved in direction Oct 24, 2026.** The feel target is now a three-way mix (BattleTech plus Sins 2 plus Rogue Trader; see CONVERSATION_CONTEXT section 9), with spectacle coming from effects and camera rather than fleet count, and target battle size near the current scale (around 20 ships). The precise number remains open; the earlier 'no target battle size stated anywhere' wording is superseded by that ruling.
5. **Plate wiring is not mapped.** There are 18 background plates against five terrain kinds with no mapping in any document, and the plate files are local only. Nothing about plate wiring is shovel-ready until that mapping exists.
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

7. **Platform ruling, Oct 24, 2026: PC-only in Babylon.** The phone target is dropped entirely. The desktop GPU budget is the design floor; there is no phone tier, no phone pass, and no phone acceptance gate. Documents written phone-first (kit spec's Pixel stress gate, beauty corner and QA pack gates as first written, the UI review's phone findings) are superseded on this point by the ruling; the re-tiered specs record the new gates. The engine stays Babylon; a wrapper or engine migration is a separate, undecided question. Battle size stays near the current scale (around 20 ships); PC headroom goes to graphics and effects, not much larger battles. The feel target is a three-way mix: BattleTech (tactical weight, location damage) plus Sins 2 (cinematic spectacle) plus Rogue Trader (small-fleet decision weight); see CONVERSATION_CONTEXT section 9.

## Decisions reserved

- Opus: tasking, sequencing, code truth, the findings registry, and whether a filled exemplar (such as a Basilica manifest) is the right first artifact.
- Ryan: visual verdicts, the undecided list in CONVERSATION_CONTEXT.md section 7, and approvals. Nothing in this folder is approved until he says so.
- Rey: external point of view only (audits, lenses, evidence packs, design and text proposals, cross-model synthesis, heavy compute). Rey does not assign Opus work.
