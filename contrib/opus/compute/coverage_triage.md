# Uncited review coverage triage

Counts: LEG 397; SUPERSEDED 85; REFERENCE 6; GAP 11. Total: 499 files.

## Gaps

- `contrib/muse/reviews/redteam_gamedev_synthesis_2026_10_30.md` (battle rules): Check turn-boundary state: hexMoved mixes last-turn evasion with current-turn broadside movement, while turn start may mishandle shieldOff/storm regeneration, damage after death, and risen ships bracing. These are specific, leg-reported checks rather than confirmed current bugs; getting them right protects damage, survival and defensive choices.
- `contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md` (tooling): Give native Godot saves their own fixtures and compare the hand-copied FAC3D, AI_HULLS, CLS_LEN, FINISH, BIOMES, ROCKS and PLANETS constants. Fresh-start saves under R64 do not remove either check: they protect player progress and keep the rendered fleet and world aligned with the data.
- `contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md` (audio): Expose the eight CC BY music attributions in an accessible credits surface; the review found the credit data but no presentation. This is distinct from the already commissioned licence audit and matters before the scored game is distributed.
- `contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md` (audio): Check the Godot mix with master volume at zero and dense simultaneous salvos, and verify event-based cue dispatch and destruction layers. The browser review found reverb bypassing master gain, cues dropped by defer limits, and caption-dependent triggers; these are port verification cases, not proof the current Godot build has the same bugs.
- `contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md` (UI): Check title.gd menu focus: the review identifies FOCUS_NONE as blocking keyboard/controller menu navigation. This concrete port defect is separate from the accessibility brief asking about remapping and helps players reach the game without a mouse.
- `contrib/muse/reviews/dead_data_audit_2026_10_27.md` (tooling): Extend the table reader scan to consumers outside godot/rules before pruning exports: TERRAIN_INFO and WING_PERKS are read by the battle scene. A rules-only scan can silently remove the terrain legend and wing text; the withdrawn FAC_PRICE claim is excluded.
- `contrib/muse/reviews/admirals_synthesis_2026_10_27.md` (UI): Reconcile the hunt Command cards: Malek and Sable promise torpedo reloads while Vorn and Ostrel use the same Command id without that clause. The records do not settle which text matches behavior, and misleading admiral cards undermine fleet selection.
- `contrib/muse/reviews/kit_coherence_synthesis.md` (battle rules): Check ionpulse on shieldless Chorus and Eclipse fleets: the review reports the Cordon destroyer ability only removes shields, leaving a blank action in those matchups. This specific ability check is not the already ruled general spread of combat verbs and would prevent players spending an ability on no effect.
- `contrib/muse/reviews/text_overhaul_pack_2026_10_30.md` (UI): Retain the non-rename accuracy fixes, especially the hunt/iron Command descriptions, launch-versus-carrier wording and weapon trait numbers. The naming rollout and small rules batch do not explicitly adopt this help/card remediation, which tells players what their choices actually do.
- `contrib/muse/reviews/codex_pack_2026_10_30.md` (UI): The 191-entry in-game reference pack proposes a browsable title/fleet codex with source-linked mechanics, beyond the existing help corrections. It could make fleet building understandable without reading project files; refresh its old pin, lore and ruled mechanics before using it.
- `contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md` (story): Correct the assembled tutorial clock tip that says the Nemesis meeting is not optional without explaining events that delay it, and the retreat gloat whose speaker/target orientation is reversed. These narrow copy checks are absent from the story merge brief and prevent the game teaching the wrong choices or attributing a retreat to the wrong side.
- `contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md` (audio): Add or verify distinct boarding, brace and Nemesis-adaptation cues, and listen to fac_corsair.ogg to establish whether its unusually small size is intentional. These targeted sound checks support the central battle/rival actions without reopening the rejected Sonniss issue or backporting music to the frozen browser.
- `contrib/muse/reviews/steam_readiness_2026_10_27.md` (tooling): Keep the concrete release checklist for exact depot file contents, version/copyright fields, final shipping-build launch and low-end requirements measurement. The export reliability fix and RTX 5080 results do not settle packaging or a minimum hardware claim for eventual Steam players.

## Basis and limits

Triage of the 499 paths in coverage_uncited.txt against FINDINGS, next_phase_recommendation_2026_10_31.md sections 3-4 (and its retained work list), the supplied Opus briefs, and BACKLOG.md. R64-R69 and the Nov 1 briefs take precedence over the older recommendation. No live game code is included in this task folder, so a GAP is an unrecorded, useful proposal or verification case, not certification that an old-pin bug still exists.

Raw and formatted model answers are grouped by topic, using the named synthesis or assembled chair review instead of rereading every duplicate leg. LEG also covers an independent research leg assembled by the matching Muse research batch. A LEG pointer does not mean its contents were all adopted, or that its target was cited: some targets cover the same question but remain uncited. SUPERSEDED includes explicit adoption, deferral, rejection or replacement by the named later decision; it does not mean every suggestion was implemented. REFERENCE is reserved for background guides and evidence provenance. Mixed documents receive GAP only for the specific surviving items above; their rejected, scheduled and stale claims are excluded.

Fresh Godot saves, testing unlocks, slow serial movement, the existing Chorus feed, baked-in faction prices, the corrected damcon comparison and the UI-only phased-activation direction are treated as settled. No browser importer, browser-music backport, rejected audit program, deferred faction tuning, deferred event expansion or premature tree implementation is proposed.

## Per-file triage

### a5_effects_sheets

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/a5_effects_sheets_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/a5_effects_sheets_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/a5_effects_sheets_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/a5_effects_sheets_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/a5_effects_sheets_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/a5_effects_sheets_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/a5_effects_sheets_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/a5_effects_sheets_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### acceptance_measurability

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/acceptance_measurability_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/acceptance_measurability_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/acceptance_measurability_synthesis.md` | SUPERSEDED | FINDINGS R6 rejects viewer panels and K1/K2 retain measurement gates; old panel scaling is not a new task. |
| `contrib/qwen/reviews/acceptance_measurability_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/acceptance_measurability_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### accessibility_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/accessibility_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/accessibility_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/accessibility_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/accessibility_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/accessibility_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/accessibility_review.md; triage follows that merged topic. |
| `contrib/qwen/accessibility_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/accessibility_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/accessibility_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/accessibility_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### addendum_validation

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/addendum_validation_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/addendum_validation_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/addendum_validation_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/addendum_validation_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/addendum_validation_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/addendum_validation_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/addendum_validation_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/addendum_validation_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### admirals

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/admirals_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/admirals_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/admirals_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/admirals_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/admirals_rey_2026_10_27.md` | LEG | Blind chair leg for contrib/muse/reviews/admirals_synthesis_2026_10_27.md; triage follows that merged topic. |
| `contrib/muse/reviews/admirals_synthesis_2026_10_27.md` | GAP | Unrecorded checks/proposals: Reconcile the hunt Command cards: Malek and Sable promise torpedo reloads while Vorn and Ostrel use the same Command id without that clause. See Gaps for scope and exclusions. |
| `contrib/qwen/admirals_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/admirals_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/admirals_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/admirals_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |

### ai

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/ai_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ai_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/ai_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ai_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/ai_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/ai_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/ai_synthesis_2026_10_29.md` | SUPERSEDED | Later redteam_gamedev_synthesis_2026_10_30.md revises this verdict; recommendation section 3 adopts brace repair and BACKLOG retains AI polish. |
| `contrib/qwen/ai_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ai_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/ai_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ai_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### asymmetry

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/asymmetry_briefs_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/asymmetry_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/asymmetry_synthesis.md` | SUPERSEDED | FINDINGS R3/R63 and later asymmetry_decision.md/price_ladder_synthesis.md settle the old decision briefs. |
| `contrib/qwen/reviews/asymmetry_briefs_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/asymmetry_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### b2_ramp_capture

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/b2_ramp_capture_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b2_ramp_capture_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/b2_ramp_capture_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b2_ramp_capture_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/b2_ramp_capture_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b2_ramp_capture_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/b2_ramp_capture_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b2_ramp_capture_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### b3_admiral_levers

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/b3_admiral_levers_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b3_admiral_levers_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/b3_admiral_levers_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b3_admiral_levers_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/b3_admiral_levers_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b3_admiral_levers_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/b3_admiral_levers_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/b3_admiral_levers_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### balance_design_bible

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/balance_design_bible_2026_10_30.md` | SUPERSEDED | Recommendation sections 3-4 rejects its R1 claim and refuted mechanics; R61-R64 and canonical_corrections_2026_10_31.md govern. |

### balance_evidence

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/balance_evidence_2026_10_27.md` | SUPERSEDED | FINDINGS G-14 and recommendation sections 3-4 replace early rates with final-rule, bot-relative instruments. |

### barge_upgrade

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/barge_upgrade_deepseek_draft.md` | SUPERSEDED | FINDINGS R12-R16 replace v14 with the approved v15 shape/paint and later effects pass. |

### batch2_workflows

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch2_workflows_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/subreddit_mining_batch2_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### batch3_nemesis

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch3_nemesis_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/nemesis_events_batch3_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### batch4_wings

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch4_wings_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/wings_tactics_batch4_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### batch5_physics_graphics_motion

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch5_physics_graphics_motion_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/physics_graphics_motion_batch5_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### batch6_opus_blender

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch6_opus_blender_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/opus_blender_batch6_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### batch7_effects

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch7_effects_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/effects_batch7_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### batch8_asset_packs

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/batch8_asset_packs_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/asset_packs_batch8_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### battle_rules

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/battle_rules.md` | SUPERSEDED | Later council_reconciliation.md and FINDINGS B-1 to B-19, D17, R32-R35 replace browser-era audits; Godot is the live target. |

### battlefield

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/battlefield_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/battlefield_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/battlefield_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/battlefield_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/battlefield_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/battlefield_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/battlefield_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/battlefield_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### battleship_entry

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/battleship_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleship_entry_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/battleship_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleship_entry_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/battleship_entry_2026_10_29.md` | SUPERSEDED | redteam_gamedev_synthesis_2026_10_30.md overturns ENTRY SOUND; FINDINGS R63 and recommendation section 5 retain the reworked hull. |
| `contrib/qwen/battleship_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleship_entry_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/battleship_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleship_entry_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### battleui

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/battleui_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleui_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/battleui_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleui_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/battleui_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/battleui_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/battleui_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleui_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/battleui_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/battleui_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### boon_favour_sweep

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/boon_favour_sweep_2026_10_29.md` | SUPERSEDED | Recommendation section 3 and FINDINGS R64 adopt the offer fix; faction tuning remains deferred. |

### boons

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/boons_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/boons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/boons_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/boons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/boons_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/boons_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/boons_synthesis_2026_10_29.md` | SUPERSEDED | Recommendation section 3 adopts offer/L_storm fixes; FINDINGS R62-R64 and progression brief govern rarity and effect caps. |
| `contrib/qwen/boons_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/boons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/boons_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/boons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### campaign_map_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/campaign_map_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/campaign_map_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/campaign_map_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/campaign_map_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/campaign_map_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/campaign_map_review.md; triage follows that merged topic. |
| `contrib/qwen/campaign_map_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/campaign_map_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/campaign_map_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/campaign_map_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### canonical_corrections

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/canonical_corrections_2026_10_31.md` | SUPERSEDED | Its four refutations are explicitly upheld in recommendation sections 3-4 and FINDINGS G-14. |

### chorus_a3_highn

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/chorus_a3_highn_2026_10_31.md` | SUPERSEDED | Recommendation section 3 explicitly defers faction/balance grids including Chorus A3; FINDINGS R63 keeps the economy as is. |

### chorus_regenerate

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/chorus_regenerate_deepseek_draft.md` | SUPERSEDED | FINDINGS R37/R40 and recommendation section 1 record the later painted portraits; R68 now requires varied poses/settings. |

### chorus_reword

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/chorus_reword_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/chorus_reword_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/chorus_reword_synthesis.md` | SUPERSEDED | Later rename_map_final.md rollout (FINDINGS R60-R61/G-14) replaces the earlier musical wording options. |
| `contrib/qwen/reviews/chorus_reword_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/chorus_reword_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### claude_skills

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/design/claude_skills.md` | SUPERSEDED | FINDINGS X15 records the three project skills written; generic tool leads remain background. |

### codex_pack

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/codex_pack_2026_10_30.md` | GAP | Unrecorded checks/proposals: The 191-entry in-game reference pack proposes a browsable title/fleet codex with source-linked mechanics, beyond the existing help corrections. See Gaps for scope and exclusions. |

### council_reconciliation

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/council_audit.txt` | LEG | Topic input to contrib/muse/reviews/council_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/designer.md` | LEG | Topic input to contrib/muse/reviews/council_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/gamer.md` | LEG | Topic input to contrib/muse/reviews/council_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/scifi.md` | LEG | Topic input to contrib/muse/reviews/council_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/council/designer.md` | LEG | Council lens/evidence input to contrib/muse/reviews/council_reconciliation.md; later review is redteam_final_synthesis_2026_10_30.md. |
| `contrib/muse/reviews/council/gamer.md` | LEG | Council lens/evidence input to contrib/muse/reviews/council_reconciliation.md; later review is redteam_final_synthesis_2026_10_30.md. |
| `contrib/muse/reviews/council/scifi.md` | LEG | Council lens/evidence input to contrib/muse/reviews/council_reconciliation.md; later review is redteam_final_synthesis_2026_10_30.md. |
| `contrib/muse/reviews/council_audit.md` | SUPERSEDED | FINDINGS B-1 to B-19 and R37-R63 disposition the old council defects, fiction, progression and economy; later redteam_final_synthesis_2026_10_30.md revises the review record. |
| `contrib/muse/reviews/council_reconciliation.md` | SUPERSEDED | FINDINGS B-1 to B-19 and R37-R63 disposition the old council defects, fiction, progression and economy; later redteam_final_synthesis_2026_10_30.md revises the review record. |
| `contrib/qwen/council_audit.txt` | LEG | Topic input to contrib/muse/reviews/council_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |

### customization_brainstorm

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/customization_brainstorm_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/customization_brainstorm_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/customization_brainstorm_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/customization_brainstorm_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/customization_brainstorm_synthesis.md` | SUPERSEDED | FINDINGS R49 explicitly limits cheap reserves to schema only; pod/trim expansion is not a newly missed authorization. |
| `contrib/qwen/customization_brainstorm_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/customization_brainstorm_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/customization_brainstorm_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/customization_brainstorm_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### damage_marks_reference

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/damage_marks_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/damage_marks_reference.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/damage_marks_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/damage_marks_reference.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/damage_marks_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/damage_marks_reference.md; triage follows that merged topic. |
| `contrib/qwen/damage_marks_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/damage_marks_reference.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/damage_marks_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/damage_marks_reference.md; raw and formatted copies belong to the same review, not separate discoveries. |

### dead_data_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/dead_data_audit_2026_10_27.md` | GAP | Unrecorded checks/proposals: Extend the table reader scan to consumers outside godot/rules before pruning exports: TERRAIN_INFO and WING_PERKS are read by the battle scene. See Gaps for scope and exclusions. |

### deathless_wording

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/deathless_wording_deepseek_draft.md` | SUPERSEDED | FINDINGS R52-R59 and rename_map_final.md replace the old Deathless bone/tomb fiction with Eclipse. |

### density_statement

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/density_statement_deepseek_draft.md` | SUPERSEDED | FINDINGS R1 and R23 explicitly settle battle ramp and player-fleet size; R63 says 20 is not a hard cap. |

### design_council_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/design/design_council_audit.md` | SUPERSEDED | FINDINGS D3-D5, K1 and R12-R20 replace the old cyan law, prototype scope and kit gates. |

### desktop_performance_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/desktop_performance_audit_2026_10_29.md` | SUPERSEDED | Browser-only profiling candidates are overtaken by R32-R35 migration/freeze and G-14 Godot measurements; feel_pass_2026-11-01.md sets the current performance bar. |

### difficulty_dial

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/difficulty_dial_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/difficulty_dial_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/difficulty_dial_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/difficulty_dial_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### difficulty_evidence

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/difficulty_evidence_2026_10_28.md` | SUPERSEDED | FINDINGS G-14 and recommendation sections 3-4 replace early rates with final-rule, bot-relative instruments. |

### drift

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/drift_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/drift_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/drift_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/drift_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/drift_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/drift_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/drift_synthesis_2026_10_29.md` | SUPERSEDED | FINDINGS R69 replaces the unlock-grant remedy; canonical_corrections_2026_10_31.md retracts oracle execution and R32-R35 retires the browser target. |
| `contrib/qwen/drift_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/drift_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/drift_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/drift_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### economy

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/economy_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/economy_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/economy_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/economy_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/economy_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/economy_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/economy_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/economy_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### effects_world

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/effects_world.md` | SUPERSEDED | Later council_reconciliation.md and FINDINGS B-1 to B-19, D17, R32-R35 replace browser-era audits; Godot is the live target. |

### enemy_ai

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/enemy_ai.md` | SUPERSEDED | Later council_reconciliation.md and FINDINGS B-1 to B-19, D17, R32-R35 replace browser-era audits; Godot is the live target. |

### engine_choice

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/engine_choice_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_choice_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/engine_choice_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_choice_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/engine_choice_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_choice_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/engine_choice_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_choice_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### engine_comparison

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/engine_comparison_deepseek_2026_10_24.md` | LEG | Independent research input to contrib/muse/research/engine_comparison_2026_10_24.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### engine_port_plan

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/engine_port_plan_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_port_plan_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/engine_port_plan_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_port_plan_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/engine_port_plan_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_port_plan_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/engine_port_plan_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_port_plan_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### engine_proof_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/engine_proof_audit_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_proof_audit_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/engine_proof_audit_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_proof_audit_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/engine_proof_audit_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_proof_audit_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/engine_proof_audit_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/engine_proof_audit_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### event_expansion_pack

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/event_expansion_pack_2026_10_30.md` | SUPERSEDED | Recommendation section 3 explicitly defers the 33-event expansion and variants until after play. |

### event_guarantee_eval

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/events_classification_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_guarantee_eval_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/events_classification_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_guarantee_eval_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/event_guarantee_eval_2026_10_29.md` | SUPERSEDED | FINDINGS R62 and recommendation section 3 adopt haven/seer fixes; R63 accepts the economy, not the broader seven-event interpretation. |
| `contrib/qwen/events_classification_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_guarantee_eval_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/events_classification_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_guarantee_eval_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### event_variants

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/event_variants_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_variants_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/event_variants_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_variants_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/event_variants_assembled_2026_10_29.md` | SUPERSEDED | Recommendation section 3 explicitly defers the 33-event expansion and variants until after play. |
| `contrib/muse/reviews/event_variants_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/event_variants_assembled_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/event_variants_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_variants_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/event_variants_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/event_variants_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### events

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/events_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/events_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/events_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/events_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/events_rey_2026_10_27.md` | LEG | Blind chair leg for contrib/muse/reviews/events_synthesis_2026_10_27.md; triage follows that merged topic. |
| `contrib/qwen/events_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/events_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/events_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/events_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |

### faction_asymmetry

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/faction_asymmetry_audit.txt` | LEG | Topic input to contrib/muse/reviews/faction_asymmetry.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/faction_asymmetry.md` | LEG | Topic input to contrib/muse/reviews/faction_asymmetry.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/faction_asymmetry.md` | SUPERSEDED | Later asymmetry_decision.md and price_ladder_synthesis.md cover the question; FINDINGS R63 governs current faction asymmetry. |
| `contrib/qwen/faction_asymmetry_audit.txt` | LEG | Topic input to contrib/muse/reviews/faction_asymmetry.md; raw and formatted copies belong to the same review, not separate discoveries. |

### factionshape

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/factionshape_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/factionshape_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/factionshape_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/factionshape_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/factionshape_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/factionshape_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/factionshape_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/factionshape_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/factionshape_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/factionshape_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### fights

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/fights_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/fights_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/fights_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/fights_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/fights_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/fights_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/fights_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/fights_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### firstrun

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/firstrun_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/firstrun_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/firstrun_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/firstrun_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/firstrun_synthesis_2026_10_29.md` | SUPERSEDED | FINDINGS R62-R63 and progression_next_2026-11-01.md retain learning/debrief; feel pass F1 replaces battle teaching flow. |
| `contrib/qwen/firstrun_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/firstrun_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### firstrun_framing

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/firstrun_framing_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_framing_recommended_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/firstrun_framing_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_framing_recommended_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/firstrun_framing_recommended_2026_10_29.md` | SUPERSEDED | FINDINGS R62/R69 and progression_next_2026-11-01.md adopt generational learning and debrief framing. |
| `contrib/qwen/firstrun_framing_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_framing_recommended_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/firstrun_framing_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/firstrun_framing_recommended_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### full_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/full_audit_A_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/full_audit_B_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/full_audit_A_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/full_audit_B_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/full_audit_A_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/full_audit_2026_10_27.md; triage follows that merged topic. |
| `contrib/muse/reviews/full_audit_B_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/full_audit_2026_10_27.md; triage follows that merged topic. |
| `contrib/qwen/full_audit_A_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/full_audit_B_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/full_audit_A_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/full_audit_B_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/full_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |

### fx_implementation_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/fx_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/fx_implementation_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/fx_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/fx_implementation_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/fx_implementation_review.md` | SUPERSEDED | FINDINGS X23 routes the concrete port/flash fixes; G-12/G-14 replace old port-completion claims and R64-R65 set the feel pass. |
| `contrib/muse/reviews/fx_implementation_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/fx_implementation_review.md; triage follows that merged topic. |
| `contrib/qwen/fx_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/fx_implementation_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/fx_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/fx_implementation_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### gemini_effects_screening

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/gemini_effects_screening.md` | REFERENCE | Screened effects shelf and engine leads, already qualified as leads in FINDINGS K2; no additional game defect. |

### gemini_verification

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/council/gemini_verification.md` | LEG | Council lens/evidence input to contrib/muse/reviews/council_reconciliation.md; later review is redteam_final_synthesis_2026_10_30.md. |

### godot_desktop_3d_brief

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research_redteam_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/godot_desktop_3d_brief_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/research_redteam_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/godot_desktop_3d_brief_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/research_redteam_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/godot_desktop_3d_brief_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/research_redteam_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/godot_desktop_3d_brief_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### godot_migration_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/migration_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/godot_migration_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/migration_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/godot_migration_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/godot_migration_review.md` | SUPERSEDED | FINDINGS X23 routes the concrete port/flash fixes; G-12/G-14 replace old port-completion claims and R64-R65 set the feel pass. |
| `contrib/muse/reviews/godot_migration_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/godot_migration_review.md; triage follows that merged topic. |
| `contrib/qwen/migration_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/godot_migration_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/migration_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/godot_migration_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### godot_modeling_pipeline_guide

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/design/godot_modeling_pipeline_guide.md` | REFERENCE | Engine/material/tool and source-licence background; not a new game change mandate (FINDINGS D11-D12, X3-X14 qualify old claims). |

### godot_port_spec

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/godot_port_spec_2026_10_30.md` | SUPERSEDED | FINDINGS R64 settles fresh saves; G-12/G-14 and feel_pass_2026-11-01.md replace the earlier cutover scope. |

### godot_space_batch9

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/research/godot_space_batch9_deepseek_2026_10_25.md` | LEG | Independent research input to contrib/muse/research/godot_space_batch9_2026_10_25.md; FINDINGS D7-D12/X1-X14 qualify the old claims. |

### gold_law

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/gold_law_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/gold_law_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/gold_law_synthesis.md` | SUPERSEDED | FINDINGS F12-F13 and R3 replace old rarity/shield assumptions; K1 retains the remaining kit gate. |
| `contrib/qwen/reviews/gold_law_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/gold_law_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### hud

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/hud_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/hud_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/hud_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/hud_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/hud_rey_2026_10_27.md` | LEG | Blind chair leg for contrib/muse/reviews/hud_synthesis_2026_10_27.md; triage follows that merged topic. |
| `contrib/qwen/hud_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/hud_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/hud_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/hud_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |

### hull_surface_diagnosis

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/hull_surface_diagnosis_2026_10_27.md` | SUPERSEDED | FINDINGS R61, R64-R65 and feel_pass_2026-11-01.md A4 explicitly retain V1b waviness, in-game paint checks and H4 rebuild. |

### independent_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/independent_audit.md` | SUPERSEDED | FINDINGS B-1 to B-19 and R37-R63 disposition the old council defects, fiction, progression and economy; later redteam_final_synthesis_2026_10_30.md revises the review record. |

### job_c_doc_verification

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/job_c_doc_verification.md` | SUPERSEDED | FINDINGS X16 and R32 record the checked breaking-change scope and completed Godot choice. |

### kit_coherence

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/kit_coherence_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/kit_coherence_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/kit_coherence_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/kit_coherence_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/kit_coherence_rey_2026_10_27.md` | LEG | Blind chair leg for contrib/muse/reviews/kit_coherence_synthesis.md; triage follows that merged topic. |
| `contrib/muse/reviews/kit_coherence_synthesis.md` | GAP | Unrecorded checks/proposals: Check ionpulse on shieldless Chorus and Eclipse fleets: the review reports the Cordon destroyer ability only removes shields, leaving a blank action in those matchups. See Gaps for scope and exclusions. |
| `contrib/qwen/kit_coherence_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/kit_coherence_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/kit_coherence_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/kit_coherence_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### kit_spec

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/kit_spec_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/kit_spec_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/kit_spec_synthesis.md` | SUPERSEDED | FINDINGS K1 explicitly schedules taxonomy, glow mapping, hardpoints and calibration. |
| `contrib/qwen/reviews/kit_spec_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/kit_spec_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### loop

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/loop_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/loop_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/loop_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/loop_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/loop_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/loop_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/loop_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/loop_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### lore_r4_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/lore_review_deepseek_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/lore_r4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/lore_review_deepseek_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/lore_r4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/lore_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/lore_r4_review.md; triage follows that merged topic. |
| `contrib/qwen/lore_review_qwen_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/lore_r4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/lore_review_qwen_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/lore_r4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### luminance_facet

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/luminance_facet_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/luminance_facet_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/luminance_facet_synthesis.md` | SUPERSEDED | FINDINGS K2 explicitly retains the luminance background scan; R6 rejects viewer panels. |
| `contrib/qwen/reviews/luminance_facet_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/luminance_facet_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### measurements

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/measurements_2026_10_29.md` | SUPERSEDED | measurements_nemesis_rerun_2026_10_29.md and canonical_corrections_2026_10_31.md qualify the early verdict; recommendation adopts boon fixes and defers tuning. |

### measurements_addendum

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/measurements_review_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/measurements_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/measurements_review_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/measurements_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/measurements_addendum_2026_10_29.md` | SUPERSEDED | measurements_nemesis_rerun_2026_10_29.md and canonical_corrections_2026_10_31.md qualify the early verdict; recommendation adopts boon fixes and defers tuning. |
| `contrib/qwen/measurements_review_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/measurements_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/measurements_review_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/measurements_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### mod_scene_field_guide

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/design/mod_scene_field_guide.md` | REFERENCE | Engine/material/tool and source-licence background; not a new game change mandate (FINDINGS D11-D12, X3-X14 qualify old claims). |

### modules

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/modules_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/modules_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/modules_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/modules_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/modules_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/modules_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/modules_synthesis_2026_10_29.md` | SUPERSEDED | Recommendation sections 3/7 adopts module guards, rejects damcon dominance and leaves refit cost as an explicit later question. |
| `contrib/qwen/modules_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/modules_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/modules_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/modules_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### montecarlo_evidence

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/montecarlo_evidence_2026_10_30.md` | SUPERSEDED | Recommendation sections 3-4 adopts the campaign driver and explicitly retains bot-relative 63/80 percent rates, not player validation. |

### montecarlo_evidence_provenance

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/montecarlo_evidence_provenance_2026_10_31.md` | REFERENCE | Evidence provenance/archive restore index; no additional gameplay or implementation proposal. |

### naming_qa

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/naming_qa_synthesis_2026_10_29.md` | SUPERSEDED | FINDINGS R61/G-14 and recommendation section 1 record the later final naming rollout; content pack errata stay with their named assemblies. |

### nemesis

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/nemesis_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/nemesis_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/nemesis_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/nemesis_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/nemesis_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/nemesis_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/nemesis_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/nemesis_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### nemesis_lines

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/nemesis_lines_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/nemesis_lines_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/nemesis_lines_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/nemesis_lines_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/nemesis_lines_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/nemesis_lines_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### nemesis_lines_correction

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/nemesis_lines_correction_2026_10_30.md` | SUPERSEDED | progression_next_2026-11-01.md explicitly includes the Nemesis assembly and its correction as source material. |

### nemesis_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/nemesis_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/nemesis_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/nemesis_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/nemesis_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/nemesis_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/nemesis_review.md; triage follows that merged topic. |
| `contrib/qwen/nemesis_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/nemesis_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/nemesis_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/nemesis_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### NOTES

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/NOTES.md` | SUPERSEDED | Orientation and corrections consolidated in contrib/muse/reviews/canonical_corrections_2026_10_31.md and FINDINGS G-14. |

### onboarding

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/onboarding_lens_deepseek.md` | LEG | Topic input to contrib/muse/reviews/onboarding_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/onboarding_synthesis.md` | SUPERSEDED | Later firstrun_synthesis_2026_10_29.md/redteam_uiux_synthesis_2026_10_30.md revisit teaching; FINDINGS R62/R69 and feel pass F1 set current direction. |
| `contrib/qwen/reviews/onboarding_lens_qwen38max.md` | LEG | Topic input to contrib/muse/reviews/onboarding_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### open_checks_resolved

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/open_checks_resolved_2026_10_29.md` | SUPERSEDED | canonical_corrections_2026_10_31.md retracts oracle-grant and other overclaims; recommendation section 3 adopts module/boon fixes. |

### opus_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/opus_audit_deepseek_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/opus_audit_2026_10_25.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/opus_audit_deepseek_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/opus_audit_2026_10_25.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/opus_audit_qwen_raw_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/opus_audit_2026_10_25.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/opus_audit_qwen_2026_10_25.md` | LEG | Topic input to contrib/muse/reviews/opus_audit_2026_10_25.md; raw and formatted copies belong to the same review, not separate discoveries. |

### packDE_screening

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/packDE_screening.md` | SUPERSEDED | Later council_reconciliation.md and redteam_final_synthesis_2026_10_30.md reconcile these rounds; FINDINGS B/D/X rows and R62-R64 govern retained work. |

### packDE_screening_round2

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/packD_economy.md` | LEG | Topic input to contrib/muse/reviews/packDE_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/packE_onboarding.md` | LEG | Topic input to contrib/muse/reviews/packDE_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/packDE_screening_round2.md` | SUPERSEDED | Later council_reconciliation.md and redteam_final_synthesis_2026_10_30.md reconcile these rounds; FINDINGS B/D/X rows and R62-R64 govern retained work. |
| `contrib/qwen/reviews/packD_economy.md` | LEG | Topic input to contrib/muse/reviews/packDE_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/packE_onboarding.md` | LEG | Topic input to contrib/muse/reviews/packDE_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |

### packFGHI_screening

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/packF_save_integrity.md` | LEG | Topic input to contrib/muse/reviews/packFGHI_screening.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/packFGHI_screening.md` | SUPERSEDED | Later council_reconciliation.md and redteam_final_synthesis_2026_10_30.md reconcile these rounds; FINDINGS B/D/X rows and R62-R64 govern retained work. |

### packFGHI_screening_round2

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/packH_repairs.md` | LEG | Topic input to contrib/muse/reviews/packFGHI_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/packI_enemy_ai.md` | LEG | Topic input to contrib/muse/reviews/packFGHI_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/packFGHI_screening_round2.md` | SUPERSEDED | Later council_reconciliation.md and redteam_final_synthesis_2026_10_30.md reconcile these rounds; FINDINGS B/D/X rows and R62-R64 govern retained work. |
| `contrib/qwen/reviews/packG_guards.md` | LEG | Topic input to contrib/muse/reviews/packFGHI_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/packH_repairs.md` | LEG | Topic input to contrib/muse/reviews/packFGHI_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/packI_enemy_ai.md` | LEG | Topic input to contrib/muse/reviews/packFGHI_screening_round2.md; raw and formatted copies belong to the same review, not separate discoveries. |

### packJ_reconciliation

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/packJ_deepseek_audit.md` | LEG | Topic input to contrib/muse/reviews/packJ_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/packJ_reconciliation.md` | SUPERSEDED | Later council_reconciliation.md and redteam_final_synthesis_2026_10_30.md reconcile these rounds; FINDINGS B/D/X rows and R62-R64 govern retained work. |
| `contrib/qwen/reviews/packJ_qwen38max_audit.md` | LEG | Topic input to contrib/muse/reviews/packJ_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/packJ_qwen_audit.md` | LEG | Topic input to contrib/muse/reviews/packJ_reconciliation.md; raw and formatted copies belong to the same review, not separate discoveries. |

### palette_safety

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/palette_safety_2026_10_27.md` | SUPERSEDED | redteam_vfx_synthesis_2026_10_30.md corrects the flat-colour reassurance; FINDINGS F6 and X23 already retain palette/flash checks. |

### patch_pack

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/patch_pack_2026_10_29.md` | SUPERSEDED | Recommendation section 3 and feel_pass_2026-11-01.md R1 adopt the small fixes; redteam_gamedev_synthesis_2026_10_30.md corrects brace insertion. |

### patch_pack_addendum

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/patch_redteam_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/patch_pack_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/patch_redteam_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/patch_pack_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/patch_pack_addendum_2026_10_29.md` | SUPERSEDED | Recommendation section 3 and feel_pass_2026-11-01.md R1 adopt the small fixes; redteam_gamedev_synthesis_2026_10_30.md corrects brace insertion. |
| `contrib/qwen/patch_redteam_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/patch_pack_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/patch_redteam_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/patch_pack_addendum_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### plain_parts

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/plain_parts.md` | SUPERSEDED | Later council_reconciliation.md and FINDINGS B-1 to B-19, D17, R32-R35 replace browser-era audits; Godot is the live target. |

### plate_mapping

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/plate_mapping_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/plate_mapping_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/plate_mapping_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/plate_mapping_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### policy_sensitivity

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/policy_sensitivity_2026_10_30.md` | SUPERSEDED | Recommendation section 3 explicitly defers faction/balance grids including Chorus A3; FINDINGS R63 keeps the economy as is. |

### preservation_archive_index

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/preservation_archive_index_2026_10_31.md` | REFERENCE | Evidence provenance/archive restore index; no additional gameplay or implementation proposal. |

### price_grid_correction

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/price_grid_correction_2026_10_31.md` | SUPERSEDED | Recommendation section 3 explicitly defers faction/balance grids including Chorus A3; FINDINGS R63 keeps the economy as is. |

### price_ladder

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/price_ladder_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/price_ladder_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/price_ladder_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/price_ladder_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### progression

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/progression_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/progression_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/progression_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/progression_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/progression_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/progression_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/progression_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/progression_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_audio

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_audio_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_audio_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_audio_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md` | GAP | Unrecorded checks/proposals: Expose the eight CC BY music attributions in an accessible credits surface; the review found the credit data but no presentation; Check the Godot mix with master volume at zero and dense simultaneous salvos, and verify event-based cue dispatch and destruction layers; Add or verify distinct boarding, brace and Nemesis-adaptation cues, and listen to fac_corsair.ogg to establish whether its unusually small size is intentional. See Gaps for scope and exclusions. |
| `contrib/qwen/redteam_audio_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_audio_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_audio_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_engineer

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_engineer_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_engineer_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_engineer_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md` | GAP | Unrecorded checks/proposals: Give native Godot saves their own fixtures and compare the hand-copied FAC3D, AI_HULLS, CLS_LEN, FINISH, BIOMES, ROCKS and PLANETS constants. See Gaps for scope and exclusions. |
| `contrib/qwen/redteam_engineer_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_engineer_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_engineer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_final

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/redteam_final_synthesis_2026_10_30.md` | SUPERSEDED | Recommendation sections 3-4 explicitly triage this program; R64 supersedes importer/playtest gating and R69 preserves testing unlocks. |

### redteam_gamedev

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_gamedev_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_gamedev_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_gamedev_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_gamedev_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_gamedev_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_gamedev_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_gamedev_synthesis_2026_10_30.md` | GAP | Unrecorded checks/proposals: Check turn-boundary state: hexMoved mixes last-turn evasion with current-turn broadside movement, while turn start may mishandle shieldOff/storm regeneration, damage after death, and risen ships bracing. See Gaps for scope and exclusions. |

### redteam_narrative

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_narrative_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_narrative_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_narrative_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md` | GAP | Unrecorded checks/proposals: Correct the assembled tutorial clock tip that says the Nemesis meeting is not optional without explaining events that delay it, and the retreat gloat whose speaker/target orientation is reversed. See Gaps for scope and exclusions. |
| `contrib/qwen/redteam_narrative_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_narrative_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_narrative_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_player

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_player_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_player_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_player_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_player_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_player_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_player_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_player_synthesis_2026_10_30.md` | SUPERSEDED | Recommendation section 3 adopts Q5, repairMult and better campaign instrument; R63 keeps economy and progression_next includes debrief work. |

### redteam_producer

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_producer_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_producer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_producer_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_producer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_producer_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_producer_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_producer_synthesis_2026_10_30.md` | SUPERSEDED | FINDINGS R64 adopts audit freeze/fresh saves and the feel-pass order; recommendation sections 5-6 already rank work. |
| `contrib/qwen/redteam_producer_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_producer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_producer_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_producer_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_qa

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_qa_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_qa_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_qa_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_qa_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_qa_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_qa_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_qa_synthesis_2026_10_30.md` | SUPERSEDED | FINDINGS R64 rejects importer premise; recommendation section 3 adopts elite/guards and standing checks; remaining cloud recovery findings concern the frozen browser. |
| `contrib/qwen/redteam_qa_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_qa_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_qa_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_qa_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_uiux

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_uiux_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_uiux_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_uiux_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md` | GAP | Unrecorded checks/proposals: Check title.gd menu focus: the review identifies FOCUS_NONE as blocking keyboard/controller menu navigation. See Gaps for scope and exclusions. |
| `contrib/qwen/redteam_uiux_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_uiux_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_uiux_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### redteam_vfx

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_vfx_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_vfx_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_vfx_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_vfx_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/redteam_vfx_rey_2026_10_30.md` | LEG | Blind chair leg for contrib/muse/reviews/redteam_vfx_synthesis_2026_10_30.md; triage follows that merged topic. |
| `contrib/muse/reviews/redteam_vfx_synthesis_2026_10_30.md` | SUPERSEDED | FINDINGS X23/R43/R46/R49 explicitly route flash bypasses, decal caps, cooling and weapon marks; feel pass F3/A4 continues effects and hull checks. |
| `contrib/qwen/redteam_vfx_raw_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_vfx_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_vfx_2026_10_30.md` | LEG | Topic input to contrib/muse/reviews/redteam_vfx_synthesis_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### relics

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/relics_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/relics_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/relics_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/relics_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/relics_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/relics_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/relics_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/relics_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/relics_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/relics_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### rename_application_pack

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/rename_application_pack_2026_10_27.md` | SUPERSEDED | FINDINGS R60-R61/G-14 and recommendation section 1 record the final rename map and implemented lore rollout. |

### retired_word_sweep

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/retired_word_sweep_2026_10_27.md` | SUPERSEDED | FINDINGS R60-R61/G-14 and recommendation section 1 record the final rename map and implemented lore rollout. |

### rewards

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/rewards_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/rewards_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/rewards_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/rewards_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/rewards_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/rewards_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/rewards_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/rewards_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### rollout_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/rollout_CD_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/rollout_E_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/rollout_CD_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/rollout_E_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/rollout_CD_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/rollout_audit_2026_10_27.md; triage follows that merged topic. |
| `contrib/muse/reviews/rollout_E_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/rollout_audit_2026_10_27.md; triage follows that merged topic. |
| `contrib/qwen/reviews/rollout_CD_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/rollout_E_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/rollout_CD_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/rollout_E_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/rollout_audit_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |

### roster

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/roster_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/roster_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/roster_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/roster_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/roster_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/roster_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/roster_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/roster_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### ruled_fixes_spec

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/redteam_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ruled_fixes_spec_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/redteam_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ruled_fixes_spec_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/ruled_fixes_spec_2026_10_29.md` | SUPERSEDED | Recommendation section 3 and feel_pass_2026-11-01.md R1 adopt the small fixes; redteam_gamedev_synthesis_2026_10_30.md corrects brace insertion. |
| `contrib/qwen/redteam_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ruled_fixes_spec_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/redteam_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/ruled_fixes_spec_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### saves_persistence_audit

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/fixtures_gapcheck_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/saves_persistence_audit_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/reviews/fixtures_gapcheck_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/saves_persistence_audit_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/saves_persistence_audit_2026_10_29.md` | SUPERSEDED | redteam_qa_synthesis_2026_10_30.md corrects recovery claims; FINDINGS R64 explicitly rejects the importer premise with fresh Godot saves. |
| `contrib/qwen/fixtures_gapcheck_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/saves_persistence_audit_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/fixtures_gapcheck_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/saves_persistence_audit_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### ship-model-audit-2026-10-21

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/codex/reviews/ship-model-audit-2026-10-21.md` | SUPERSEDED | FINDINGS D1/D17 and R12-R20/G-14 replace the early C19 state; feel_pass_2026-11-01.md A4 owns current asset verification. |

### ship_kit_upgrade

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/design/ship_kit_upgrade.md` | SUPERSEDED | FINDINGS D3-D5, K1 and R12-R20 replace the old cyan law, prototype scope and kit gates. |

### ship_loading

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/codex/reviews/ship_loading.md` | LEG | Topic input to contrib/muse/reviews/ship_loading.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/ship_loading.md` | SUPERSEDED | Later council_reconciliation.md and FINDINGS B-1 to B-19, D17, R32-R35 replace browser-era audits; Godot is the live target. |

### sim_matrix

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/council/sim_matrix.md` | LEG | Council lens/evidence input to contrib/muse/reviews/council_reconciliation.md; later review is redteam_final_synthesis_2026_10_30.md. |

### sims_cp_repair

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/sims_cp_repair_2026_10_29.md` | SUPERSEDED | Recommendation section 3 explicitly defers faction/balance grids including Chorus A3; FINDINGS R63 keeps the economy as is. |

### skill_tree_phase1

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/tree_phase1_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/tree_phase1_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md` | SUPERSEDED | Recommendation section 3 explicitly defers tree content until effect caps; progression_next_2026-11-01.md explicitly includes this assembly. |
| `contrib/muse/reviews/tree_phase1_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/reviews/tree_phase1_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/tree_phase1_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_phase1_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### skill_tree_tier2

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/tier2_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/tier2_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md` | SUPERSEDED | Recommendation section 3 explicitly defers tree content until effect caps; progression_next_2026-11-01.md explicitly includes this assembly. |
| `contrib/muse/reviews/tree_tier2_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/reviews/tier2_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/tier2_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier2_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### skill_tree_tier3

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/tier3_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/tier3_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md` | SUPERSEDED | Recommendation section 3 explicitly defers tree content until effect caps; progression_next_2026-11-01.md explicitly includes this assembly. |
| `contrib/muse/reviews/tree_tier3_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/reviews/tier3_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/tier3_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/skill_tree_tier3_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### sprint_b3_b4_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/sprint_jobC_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_b3_b4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/sprint_jobC_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_b3_b4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/sprint_jobC_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_b3_b4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/sprint_jobC_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_b3_b4_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### sprint_decision_packs

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/sprint_jobD_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_decision_packs.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/sprint_jobD_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_decision_packs.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/sprint_jobD_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_decision_packs.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/sprint_jobD_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_decision_packs.md; raw and formatted copies belong to the same review, not separate discoveries. |

### sprint_godot_shipping_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/sprint_jobB_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_godot_shipping_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/sprint_jobB_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_godot_shipping_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/sprint_jobB_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_godot_shipping_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/sprint_jobB_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_godot_shipping_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### sprint_rules_port_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/sprint_jobA_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_rules_port_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/sprint_jobA_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_rules_port_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/sprint_jobA_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_rules_port_review.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/sprint_jobA_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/sprint_rules_port_review.md; raw and formatted copies belong to the same review, not separate discoveries. |

### squadrons

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/squadrons_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/squadrons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/squadrons_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/squadrons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/squadrons_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/squadrons_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/squadrons_synthesis_2026_10_29.md` | SUPERSEDED | Later redteam_gamedev_synthesis_2026_10_30.md consolidates duplication; recommendation section 7 explicitly leaves the spore-wing job for later. |
| `contrib/qwen/reviews/squadrons_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/squadrons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/squadrons_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/squadrons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### steam_readiness

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/steam_readiness_2026_10_27.md` | GAP | Unrecorded checks/proposals: Keep the concrete release checklist for exact depot file contents, version/copyright fields, final shipping-build launch and low-end requirements measurement. See Gaps for scope and exclusions. |

### story_review

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/story_review_deepseek_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/story_review_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/story_review_deepseek_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/story_review_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/story_review_rey.md` | LEG | Blind chair leg for contrib/muse/reviews/story_review_synthesis.md; triage follows that merged topic. |
| `contrib/qwen/reviews/story_review_qwen_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/story_review_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/story_review_qwen_raw_2026_10_26.md` | LEG | Topic input to contrib/muse/reviews/story_review_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### telemetry_spec_addendum

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/telemetry_gapcheck_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/telemetry_gapcheck_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md` | SUPERSEDED | progression_next_2026-11-01.md explicitly includes the telemetry addendum; recommendation section 3 and feel pass F1 adopt staged logging. |
| `contrib/qwen/reviews/telemetry_gapcheck_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/telemetry_gapcheck_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/telemetry_spec_addendum_2026_10_30.md; raw and formatted copies belong to the same review, not separate discoveries. |

### text

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/text_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/text_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/text_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/text_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/text_rey_2026_10_27.md` | LEG | Blind chair leg for contrib/muse/reviews/text_synthesis_2026_10_27.md; triage follows that merged topic. |
| `contrib/qwen/reviews/text_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/text_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/text_raw_2026_10_27.md` | LEG | Topic input to contrib/muse/reviews/text_synthesis_2026_10_27.md; raw and formatted copies belong to the same review, not separate discoveries. |

### text_dryrun_report

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/text_dryrun_report_2026_10_30.md` | LEG | Rehearsal/correction input for contrib/muse/reviews/text_overhaul_pack_2026_10_30.md; its four blocked row tokens must be reconciled before applying that old-pin pack. |

### text_overhaul_pack

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/text_overhaul_pack_2026_10_30.md` | GAP | Unrecorded checks/proposals: Retain the non-rename accuracy fixes, especially the hunt/iron Command descriptions, launch-versus-carrier wording and weapon trait numbers. See Gaps for scope and exclusions. |

### tool_guides_retier

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/tool_guides_retier_deepseek_draft.md` | SUPERSEDED | FINDINGS D7 and X15 record desktop retiering and the later project skills. |

### torpedo_boarding

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/torpedo_boarding_deepseek_draft.md` | LEG | Topic input to contrib/muse/reviews/torpedo_boarding_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/torpedo_boarding_synthesis.md` | SUPERSEDED | FINDINGS K2 schedules the torpedo warning/interception call; R4/R23 settle capture and prize scope, later redteam_gamedev_synthesis_2026_10_30.md covers rule boundaries. |
| `contrib/qwen/reviews/torpedo_boarding_qwen38max_draft.md` | LEG | Topic input to contrib/muse/reviews/torpedo_boarding_synthesis.md; raw and formatted copies belong to the same review, not separate discoveries. |

### tree_validation

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/tree_validation_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/tree_validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/tree_validation_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/tree_validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/tree_validation_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/tree_validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/tree_validation_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/tree_validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### tuning_grids

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/tuning_grids_2026_10_30.md` | SUPERSEDED | Recommendation section 3 explicitly defers faction/balance grids including Chorus A3; FINDINGS R63 keeps the economy as is. |

### tutorial

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/tutorial_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/tutorial_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/tutorial_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/tutorial_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/tutorial_assembled_2026_10_29.md` | SUPERSEDED | progression_next_2026-11-01.md retains learning/debrief work and feel pass F1 replaces battle flow; clock-tip correction is retained under redteam_narrative_synthesis_2026_10_30.md. |
| `contrib/muse/reviews/tutorial_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/tutorial_assembled_2026_10_29.md; triage follows that merged topic. |
| `contrib/qwen/reviews/tutorial_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/tutorial_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/tutorial_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/tutorial_assembled_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |

### validation

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/validation_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/validation_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/validation_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/validation_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/validation_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### variety

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/variety_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/variety_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/variety_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/variety_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/reviews/variety_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/variety_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/variety_raw_2026_10_28.md` | LEG | Topic input to contrib/muse/reviews/variety_synthesis_2026_10_28.md; raw and formatted copies belong to the same review, not separate discoveries. |

### verification_sweep

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/design/verification_sweep.md` | REFERENCE | Engine/material/tool and source-licence background; not a new game change mandate (FINDINGS D11-D12, X3-X14 qualify old claims). |

### wave3_deepqa

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/muse/reviews/wave3_deepqa_2026_10_29.md` | SUPERSEDED | FINDINGS G-14 and recommendation sections 3-4 replace early rates with final-rule, bot-relative instruments. |

### weapons

| Path | Verdict | One-line reason |
| --- | --- | --- |
| `contrib/deepseek/reviews/weapons_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/weapons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/deepseek/weapons_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/weapons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/muse/reviews/weapons_rey_2026_10_29.md` | LEG | Blind chair leg for contrib/muse/reviews/weapons_synthesis_2026_10_29.md; triage follows that merged topic. |
| `contrib/muse/reviews/weapons_synthesis_2026_10_29.md` | SUPERSEDED | Recommendation section 3 adopts duplicate gsentry fix; later redteam_gamedev_synthesis_2026_10_30.md corrects mount-separated dominance claims. |
| `contrib/qwen/reviews/weapons_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/weapons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
| `contrib/qwen/weapons_raw_2026_10_29.md` | LEG | Topic input to contrib/muse/reviews/weapons_synthesis_2026_10_29.md; raw and formatted copies belong to the same review, not separate discoveries. |
