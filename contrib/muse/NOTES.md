# NOTES.md: contrib/muse (Rey)

From Rey (Muse), Ryan's external POV agent. Role split set by Ryan: Opus codes, verifies and orchestrates, and owns code truth. Everything in this folder is proposals, audits and precomputed data for Opus to use, not approvals and not a verification gate over his work.

## Read order (do not read this folder linearly)

The folder holds roughly 100,000 words of markdown plus data files. The full ingestion order, with errata and per-document takeaways, is `READING_PLAN.md` in this folder. Read it before the design documents. In short:

1. This file: status, map, and what is unfinished.
2. `READING_PLAN.md`: errata first, then the ordered stages.
3. The one document your task actually needs, from the map below.

READING_PLAN.md orders reading only. It does not assign tasks or sequence implementation work: tasking is Opus's decision as code owner, per Ryan (Oct 24, 2026).

Authority ladder when documents disagree: owner rulings (CONVERSATION_CONTEXT sections 3 and 9) over distilled syntheses (council_reconciliation.md, the pack screenings, asymmetry_decision.md) over single reviews over raw external model returns, which are archive material.

## Map

**reviews/** Audits and lenses, all Rey's unless noted.
- Protocol reviews: plain_parts.md, ship_loading.md, battle_rules.md, enemy_ai.md, effects_world.md, ui.md.
- independent_audit.md (whole game, unprompted; top creative idea: a per-run Nemesis admiral), career_story.md (options for career and story; recommendation unanswered), space_3d.md (three delta-v bands model, owner confirmed; standing rule: space ships, never naval ships).
- council_audit.md plus council/ (five lenses: scifi, gamer, engineer, qa, designer; plus gemini_verification.md and sim_matrix.md). Chair synthesis with a top 10 sequence, unanswered.
- council_reconciliation.md: three-way reconciliation of Rey's council with the blind DeepSeek and Qwen councils. Read this instead of the three councils when time is short.
- faction_asymmetry.md (evidence) and asymmetry_decision.md (the five owner decisions it reduces to, unanswered).
- Screenings of the external pack returns: packDE_screening.md and packDE_screening_round2.md, packFGHI_screening.md and packFGHI_screening_round2.md. These are the verification layer over contrib/deepseek/ and contrib/qwen/.

**design/** The graphics pack (about 61,200 words total). Division of labour:
- art_direction_rey.md: what it should look like. Colour laws, silhouette grammars, hero hull concepts, background plates, admiral portrait system.
- ship_kit_upgrade.md: the work order for rebuilding the ship kit.
- visual_expansion_research.md (about 11,900 words): techniques, tools and asset sources for expanding the in-game visuals, plus engine verdicts and the cinematic (Sins) section.
- GRAPHICS_REFERENCES.md (about 8,700 words): external reading. Reference games, modding masterclasses (EVE, BattleTech and MechWarrior, Stellaris, Empire at War, Endless Space 2, Homeworld Remastered, X4, Cosmoteer), repos, kick-off assets, and section 6, games actually like Voidsworn, headlined by Rogue Trader.
- mod_scene_field_guide.md (about 10,300 words): the wider mod scene and open content, indexed by problem (save integrity, content as data, tuning loops, paint, effects, sound). Read for mechanisms and grabbable assets; GRAPHICS_REFERENCES.md stays the games and repos list. Its front section names the pattern all three research passes converged on: stable ids forever, deltas merged in a declared order, a checker in the build.
- tool_guides.md (about 14,300 words): how to run the toolchain. Blender (glTF export survival rules, headless batch pipeline, decimation and LOD, baking, weighted normals, pre-export checklist), Babylon (rendering pipeline traps, PBR defaults, instancing, KTX2, debugging, WebGPU), pipeline glue (gltfpack two-tier recipe, texture compression, Effekseer routes, Windows batch scripting, AJV and reference checkers), and AI meshes plus local image models (seven-step AI mesh cleanup, kit parts as the fix for fused detail, 16 GB model table, local PBR estimation chains). Its front section states the merged chain: AI mesh and AI texture enter separately and join only at the bake.
- Round 3 guides (Oct 24): claude_skills.md (Claude Agent Skills format, community game dev collections, MCP servers led by the official Blender Lab server from April 2026, screenshot evidence and blocking validator patterns, hype versus real), design_council_audit.md (five-lens adversarial audit of this folder's own documents, unanimous GO WITH CONDITIONS, 41 findings; its recommended next step is to prototype the kit on the Basilica manifest only and report measured cost before any other hull), graphics_craft.md (the craft layer a non developer would not request: tonemapping and grading, TAA and ghosting, VFX timing, readability systems, LOD and overdraw budgets, UI motion, audio as effects, accessibility with hard numbers).
- CONVERSATION_CONTEXT.md: rulings and conversation behind the pack. Section 9 is the Rogue Trader feel benchmark ruling.
- IMAGE_MANIFEST.md: the 40 final images (18 backgrounds, 13 ship plates, 9 portraits) with SHA-256 hashes. The images are local only; the push route accepts text only. Ask Ryan to relay one, or Rey to supply it, and verify against the hash.

**compute/** Precomputed data so Opus does not re-derive it: code_index.md and code_index.json, dead_code.md, referential_integrity.md, content_census.md with census CSVs and strings_corpus.csv, asset_inventory.md and asset_inventory.csv. Basis: repo HEAD 51337c2, Oct 23, 2026; trust the repo if it has moved. A balance reference joins this folder when the mega sim finishes (see Unfinished).

**prompts/** The numbered packs (.txt) Rey built for the external models, packs C to I. Historical unless another external run is commissioned.

**tools/checkpack/** A double-click mechanical checker (RUN_CHECKS.bat, checks.js, README.txt), handed over as a tool Opus may adopt. It is not a gate Rey runs over his work.

## Encoding fix, Oct 24, 2026

Eighteen files in this folder were committed base64 encoded by an earlier upload route, so they opened as gibberish. They have been re-pushed as plain markdown with content unchanged: reviews/battle_rules.md, reviews/career_story.md, reviews/council_audit.md, reviews/space_3d.md, reviews/independent_audit.md, reviews/effects_world.md, reviews/enemy_ai.md, reviews/ui.md, reviews/council/designer.md, reviews/council/engineer.md, reviews/council/gamer.md, reviews/council/qa.md, reviews/council/scifi.md, reviews/council/gemini_verification.md, reviews/council/sim_matrix.md, compute/asset_inventory.md, compute/content_census.md, tools/checkpack/README.txt.

## Other agents' folders (orientation only)

- contrib/deepseek/ and contrib/qwen/: the .txt files at each folder root are raw returns, archive only, read them solely to check a distilled claim. The extracted working copies live in each folder's reviews/.
- contrib/gemini/: idea and lead generation only. Its repo-state claims failed verification too often to trust unscreened (47 verified, 18 wrong, 2 stale, 3 uncheckable of 70; see reviews/council/gemini_verification.md).
- contrib/codex/ and contrib/rey/ belong to other seats. rey/reviews/ship-pipeline-audit.md is Rey's earlier ship pipeline audit, written before the muse folder existed.

## What to merge

Nothing merges itself. Candidates when the owner says go: the checkpack (into the repo's tools, if Opus wants it) and the compute CSVs (as lookup data). The design and review documents stay reference material in this folder.

## Unfinished

- The mega sim (campaign 200, bossmatrix, fmatrix, matrix, archmatrix) was still running when this was written. Its balance_reference.md and per-mode CSVs land in compute/ when it finishes, and the README there already has the slot for them.
- The owner's verdict queue (CONVERSATION_CONTEXT.md section 7): the council top 10, the career and story pick, the five asymmetry decisions, Pyre-Barge sign-off, and the desktop versus phone target question. None is time sensitive, and none should be treated as approved.
- Fifteen of the 24 admiral portraits are unproduced. They are approved as a system against the locked template in art_direction_rey.md, not yet commissioned as a batch.
