# Current return index for Opus

Proposed replacement, October 31, 2026. Reviewed source head: **17268efa081059a6923daa9e19e8b345a437714d**. This index orders reading and records status. It assigns no implementation order and grants no approval.

## Read first

1. `HANDOFF.md` and `contrib/opus/FINDINGS.md` for recorded owner decisions and implementation status. Their October 27 snapshot is supplemented by the explicit October 28-29 ruling addenda in the syntheses below.
2. `contrib/codex/reviews/post_upload_closing_2026_10_31.md` and its `post_upload_2026_10_31/claim_ledger.csv`, then the initial review for earlier source counterexamples. The closing addendum governs uploaded work; copied old test runners must not overwrite the 80-test extension.
3. The one current synthesis or assembled draft relevant to the chosen task, plus its listed correction addendum. Raw legs are provenance and dissent, not alternate instructions.

Authority: explicit owner rulings beat proposals; the source beats a code claim; a later adjudication must travel with the older document it changes. A chair verdict is not a test pass. Use the naming authority `contrib/opus/compute/rename_map_final.md` and approved `lore_bible_r8.md`; stable data ids remain unchanged.

## Settled state carried into the reset

- Desktop target; Godot migration decided in R32. The browser is frozen except permitted fixes. Do not reopen the engine selection from the October 24 handoff.
- Lore round 8 is approved. The game is *Embers of the Hollow Sun*. Old faction names in pins and identifiers are not automatically stale player text.
- Around 20 ships is a typical-density target, not a hard cap, especially for Chorus swarms.
- Phased activation is the October 29 direction. The memo/synthesis is not evidence it has been implemented.
- Admiral leveling with a small tree is ruled; the assembled 360 authored texts are design drafts, not a validated implementation contract.
- Generous repair is accepted as is pending actual play data. Do not tune it from the old economy blocker headline.
- Nemesis loss-debrief reveal, adaptation clash protection, variant trades/disclosure and Ascendant speed 2 are recorded directions. Check source and current parity before marking any done.

## Current review and evidence map

All paths below are under `contrib/muse/` unless otherwise stated. A status of drafted/assembled never means implemented.

| Area | Primary document(s) | Status / required companion |
|---|---|---|
| October 27 faction kits | reviews/kit_coherence_synthesis.md | Read with current source and Codex dispositions; browser palettes are not the Godot FX palette. |
| Admirals, events, text, HUD | reviews/admirals_synthesis_2026_10_27.md; events_synthesis_2026_10_27.md; text_synthesis_2026_10_27.md; hud_synthesis_2026_10_27.md | Source findings need per-row dispositions; HUD composition still needs captures. Shipwright bug is real but later ledger mechanism is wrong. Kassar's lighter-hit text already describes damage. |
| Progression / run loop | reviews/progression_synthesis_2026_10_28.md; rewards_synthesis_2026_10_28.md; loop_synthesis_2026_10_28.md; variety_synthesis_2026_10_28.md | Read their final ruling addenda. Do not revive the old renown shop merely to clear retired unlock findings. |
| Learning-frame validation | reviews/validation_synthesis_2026_10_28.md | Both ruling addenda matter, including equal peer cores and crews learning protocols. |
| Battlefield, fights, rival, roster | reviews/battlefield_synthesis_2026_10_28.md; fights_synthesis_2026_10_28.md; nemesis_synthesis_2026_10_28.md; roster_synthesis_2026_10_28.md | Distinguish table observations from design judgments. Early-sector Nemesis scar escape is explicitly implemented. |
| October 29 systems | reviews/weapons_synthesis_2026_10_29.md; squadrons_synthesis_2026_10_29.md; modules_synthesis_2026_10_29.md; ai_synthesis_2026_10_29.md; boons_synthesis_2026_10_29.md | Companion: reviews/open_checks_resolved_2026_10_29.md, then Codex corrections. Missing preview was disproved; boarding promise holds; module dominance is not proved. |
| Economy, first run, faction shape, drift, interaction | reviews/economy_synthesis_2026_10_29.md; firstrun_synthesis_2026_10_29.md; factionshape_synthesis_2026_10_29.md; drift_synthesis_2026_10_29.md; battleui_synthesis_2026_10_29.md; battleui_activation_models_2026_10_29.md | Correct missing Chorus feed, alleged oracle unlock grant and touchWords ordering before routing fixes. Keep economy acceptance and phased-activation ruling. |
| Naming / table provenance | reviews/naming_qa_synthesis_2026_10_29.md; dead_data_audit_2026_10_27.md | Derived HULLS.cost preserves faction prices in Godot; do not multiply them twice. Naming scan is triage, not semantic proof. |
| Ruled implementation proposals | reviews/ruled_fixes_spec_2026_10_29.md; patch_pack_2026_10_29.md | Mandatory companion: patch_pack_addendum_2026_10_29.md. Replace stale patch blocks before application; resolve duo policy separately from filler favour. |
| Deep QA | reviews/wave3_deepqa_2026_10_29.md; tools/harness/ | Map elite failure reproduced. Committed tool layout needs the proposed portability repairs. |
| Measurements | reviews/measurements_2026_10_29.md | Read measurements_addendum_2026_10_29.md, measurements_nemesis_rerun_2026_10_29.md and boon_favour_sweep_2026_10_29.md together. Original small-sample weakness-payback claims are withdrawn; Chorus fast cadence is the exception. |
| CP / repair model | reviews/sims_cp_repair_2026_10_29.md | Modeled evidence, not observed human play. Repair is accepted pending play data. |
| Tree design spine | reviews/skill_tree_proposal_final_2026_10_28.md; tree_validation_synthesis_2026_10_28.md | Shape/arithmetic validation, not proof every later authored pick changes play. |
| Tree authored text | reviews/skill_tree_phase1_assembled_2026_10_29.md; skill_tree_tier2_assembled_2026_10_29.md; skill_tree_tier3_assembled_2026_10_29.md | Draft pending mechanical prerequisite/no-op checks. Seveth's shield branches are invalid for Eclipse; several timing/sync permissions are already baseline. |
| Tutorial, rival lines, event variants | reviews/tutorial_assembled_2026_10_29.md; nemesis_lines_assembled_2026_10_29.md; event_variants_assembled_2026_10_29.md | Authored copy, not installed or played content. Nemesis pool requires nemesis_lines_correction_2026_10_30.md; proposed consolidated copy includes both withdrawals. |
| New Eclipse battleship | reviews/battleship_entry_2026_10_29.md | HOLD: Oct 30 gamedev synthesis overturns ENTRY SOUND for unchanged offensive battery and void second point-defense mount. Rework data first, then model/export/parity and roster integration. |
| Event exits | reviews/event_guarantee_eval_2026_10_29.md | Distinguish the three fight-start events from the wider seven-event no-free-exit recommendation; do not widen the ruling silently. |
| Telemetry | reviews/telemetry_spec_2026_10_29.md; telemetry_spec_addendum_2026_10_30.md; tools/telemetry_reference/ | Lineage-join demonstration passes. No installed game instrumentation is certified. |
| Importer fixtures | tools/importer_fixtures/README.md | Generated browser input/output expectations, not an implemented Godot importer. Generator layout must be portable first. |
| Findings regression register | tools/findings_tests/README.md | 125 scoped rows, not all historical findings. New portable proposed package reproduces 80 assertions, 8 pass / 72 fail. FAIL is not automatically proof of a bug; current Codex CSV retains dispositions. |
| Godot visual reference | reviews/godot_desktop_3d_brief_2026_10_29.md | Read amended version. Old Babylon comparisons/research shelves are historical or leads. |

## Newly uploaded Oct 30 work: current controls

| Area | Primary document(s) | Governing status |
|---|---|---|
| Nine red-team seats | reviews/redteam_final_synthesis_2026_10_30.md plus seat syntheses | Three prongs, Qwen pending. Correct false missing-feed premise; supersede old win-rate/attrition/task statements with the actual reports and closing review. |
| Balance reference | reviews/balance_design_bible_2026_10_30.md | Reference draft, not authority over rulings/code. Correct feed/damcon premises; quarantine price-grid recommendations. |
| Campaign measurement | reviews/montecarlo_evidence_2026_10_30.md; policy_sensitivity_2026_10_30.md | Bot/policy-specific filed evidence, not human difficulty. Price interventions compound in the committed driver; rerun A2/A3/A4/A5 after the proposed isolation repair. Raw shards intentionally remain outside Git. |
| Tuning | reviews/tuning_grids_2026_10_30.md | A2/A3/A4/A5 HOLD. Healing and boon cells are not refuted by that bug but not independently certified here. |
| Gate/oracle | tools/cutover_gate/; tools/oracle_drift/ | Gate must fail closed for missing components and disappearing checks. Proposed copy ends INCOMPLETE because parity vectors do not exist. Oracle scan reproduces 120 comparisons, 95 match / 25 differ. Known-state tracking is not release approval. |
| Export/import reference | reviews/godot_port_spec_2026_10_30.md; tools/port_export/; tools/importer_reference/ | 65 regenerated JSON files identical; 22 converter checks pass. No transport, migration approval or whole-port parity implied. |
| Text remediation | reviews/text_overhaul_pack_2026_10_30.md; text_dryrun_report_2026_10_30.md | Four blocked rows must be corrected. Proposed full copy carries all four repairs; source anchors checked, full application not repeated. |
| New content | reviews/story_pack_2026_10_30.md; event_expansion_pack_2026_10_30.md; codex_pack_2026_10_30.md | Filed drafts. New events/codex data are not installed; rendered/lore/balance checks still apply. |

Suggested integration sequence: repair tooling and apply false-premise corrections, rerun the affected price cells, then use the corrected existing queue for playable Godot work. The final synthesis's broad audit-freeze recommendation is a recommendation, not a new owner ruling. Do not reopen settled repair generosity from model results alone.

## Late returns requiring explicit disposition

| Return | Where it is filed | Reset status |
|---|---|---|
| Relics audit, four legs | reviews/relics_rey_2026_10_29.md; contrib/deepseek/reviews/relics_2026_10_29.md; contrib/qwen/reviews/relics_2026_10_29.md; contrib/gemini/reviews/relics_2026_10_29.md | Delivered: reviews/relics_synthesis_2026_10_29.md now carries the corrected revive order, payRelic direction and naming counts. Read the synthesis; raw legs remain provenance. |
| Argon holistic Phase 1 tree | contrib/gemini/reviews/tree_phase1_2026_10_29.md | Landed after the three-prong assembly; no later incorporated assembly is filed. Compare useful deltas, then validate against actual baseline mechanics. |
| Argon first-run framing | contrib/gemini/reviews/firstrun_framing_2026_10_29.md | Recommended set delivered: reviews/firstrun_framing_recommended_2026_10_29.md. It is authored copy, not installed teaching. |

## Archives and stop rules

`OPUS_HANDOFF.md`, `READING_PLAN.md` and `NOTES.md` contain useful October 24 history. Their old decision-state claims do not control this reset. Research batches, Gemini shelves and verbatim legs remain reference material. Do not reread the entire archive to recover a ruling already recorded above. Do not implement a new mechanic merely because a sliced evidence pack omitted the existing one.
