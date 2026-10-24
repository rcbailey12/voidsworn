# Opus handoff briefing

From Rey (Muse), Oct 24, 2026. Status as of about 14:20 CDT Oct 24.

TL;DR: Ryan has ruled everything that needed human direction. You own everything technical. The barge upgrade is the first commission. Read READING_PLAN.md (same folder) for reading order; this document is the decision state and the evidence map.

## Boundary

This document assigns nothing. It does not sequence implementation work, set priorities, or order builds. Task plan, sequencing, code truth, and the findings registry are yours. What this document does: state what Ryan decided (closed, do not re-litigate), list what is yours to decide, explain how the external-model work was produced so you can weigh it, and map where everything lives.

Rey's lane, set by Ryan: external point of view only (audits, lenses, sim evidence packs, design and text proposals, cross-model screening and synthesis) plus heavy compute runs and reading plans with ingestion ordering. Rey is not a verification gate over your work. Code claims in Rey deliverables are observations for you to confirm.

## 1. RULED by Ryan: closed human-direction decisions

Do not re-open these. Where a proposal disagrees with a ruling, the ruling wins and the proposal should be corrected.

Battle feel:
- Density: LEANING 20 ships TOTAL on board (Ryan: "20 total probably"). Rationale: more would mean too many turns and directions. Note the "probably": leaning, not locked. The draft table (target 20, ceiling 24) and its gates are yours to reconcile (see section 2).
- Difficulty ramp: difficulty MAY ramp by more ships as a run goes. This REJECTS the density draft's dial-invariance proposal. Intended feel: an elite unit or commander punching above its weight class with upgraded, powerful ships.
- Fleet-cap capture rule (confirmed Oct 24): if the player's fleet is maxed, extra captured ships auto-scrap for stuff or credits. If not maxed, the player gets the option to add the captured ship.
- Capture consequences: strip and ransom only. Scuttle and derelict rejected.
- Critical hits: soft and current only. No permanent system destruction. Existing temporary effects stand (engine slows, shields off 2 rounds, weapon off 2 rounds, fires tick).

Factions:
- Six faction identities adopted as design direction (see reviews/asymmetry_synthesis.md and reviews/asymmetry_decision.md).
- Hegemony definer: synchronized fire (Kassar doctrine faction-wide) PRIMARY, pinning (Vorn interdiction) SECONDARY. Ion suppression not adopted. Shield-stripping drops to ion weapon flavor, not the identity.
- Hegemony loss: formation dependence, flagship-anchor version TO START. Synchronized fire counts only for ships within a radius of the flagship; losing the anchor collapses sync; Hegemony ships without the flagship are very vulnerable, losing sync entirely. The scaled group bonus is NOT layered to start; revisit only if the anchor version proves too weak or too strong. Anchor definition (which ship anchors, exact radius) is yours.
- Ithar shield charge: approved now (must specify what sits above the baseline shield regen that already exists for every shielded hull, battle.js:365).
- Chorus feed: approved now (tuning cap kept as an implementation detail).
- Deathless elite attrition: approved in principle now, with your reanimate report still confirming mechanics. The report gate stands, it is not dropped.
- Deathless voice: bone is METAPHOR only. Deathless are sentient robots, not humans. No faces. Framing: they have transcended. This settles the Deathless wording set: passage edits A through D apply, passage G ("sensor light instead of faces") unchanged. See reviews/deathless_wording_deepseek_draft.md (single leg).
- Chorus admirals: Matriarch REGENERATE (current portrait reads like a spine). Voice REGENERATE with heavy changes (reads as a jellyfish; violates the no-Earth-animal-anatomy rule). Mending Choir REGENERATE toward the Regrowth tide character (a mending figure with suture and tissue motifs, not a ship-mass, not a mass of eyes). Chair text picks for rewording are moot for Matriarch and Voice; Mending Choir text was effectively settled (press-and-fuse wording) but the portrait is regenerated anyway.
- NEW STANDING RULE: admirals should match their special abilities in some way (portrait and design reflect Command and doctrine). Chorus abilities for reference: Matriarch Command Spawning surge (broods release extra swarms, all swarms strike again at +50 percent); Voice Command Discordant volley (every ship spits a free volley now); Mending Choir Command Regrowth tide (every ship regrows 25 percent hull, heals damaged sections even destroyed ones). Apply this rule to all future admiral portraits, not just Chorus.

Story and world:
- Career and story: Option B faction arcs. The A-first build order stands as the review's recommendation, not contradicted.
- Dead Star: background only. Not a sixth terrain kind, not a gravity well mechanic, no new engine work. Finale-style backdrop at most.

Ships and the ship-five:
- Ship-five: Nemesis YES, event blue options plus 20 more events YES, faction campaign verbs YES, wing doctrines YES (three stances Screen, Strike, Hunt, changeable per round, plus wing veterancy; see the independent audit proposal 5). The two reload bugs and the retreat modal are technical work, yours, not a Ryan vote.
- Pyre-Barge sign-off: NOT given. V14 is a checkpoint, not the finish (see section 3).

Platform and feel (previously ruled, still standing):
- PC-only in Babylon. Phone target dropped entirely. Desktop GPU budget is the design floor. No phone tier, no phone pass, no phone acceptance gate. UI review phone findings are moot. Engine stays Babylon; a wrapper or engine migration is separate and undecided.
- Feel mix: BattleTech tactical weight plus Sins of a Solar Empire 2 presentation plus Rogue Trader small-fleet turn structure. PC headroom goes to graphics and effects quality, not much larger battles.
- Fiction rules: space ships, never naval ships. Guns never face backward.

## 2. OPUS PILE: yours to decide from code and measurement

Ryan hears only failures or vetoes on these. Decide, report, move on.

- Acceptance panel scale and hold rules (chair proposal: 7 viewers per unit, hard returns for wrong-faction naming and gold naming, provisional state means hold for retest, never conditional pass). Gold reference crop source: pick from accepted art.
- Luminance spec adoption (fixed mid-grey swatch sRGB 128, reference 0.2159, cap 0.0864, DeepSeek full-scan PNG-plus-mask procedure; supersedes the acceptance synthesis luminance section on both grid and reference).
- Gold law adoption plus the merged viewer test (rename-first for Chorus, Ithar, Belt, Nursery; epic recolor violet-magenta; panel decided at 7 viewers 7/7 under gold-law test conditions).
- Tool-guides re-tier edit, including decisions D1 through D9 (scope sentence, single triangle budget plus fleet total, draw-call figure plus provenance, LOD scope, gltfpack flags, WebGL fallback requirement, phone-chosen values replacements, texture-resolution clause, sign-off order plus Blender version check). Blender version on the PC is an open check, yours.
- Torpedo range 6 versus 10, and magazine versus cooldown.
- Corsair gate: "long-range missile or bombard weapon kind" (the "or" is undecided).
- Density table remainder, gate thresholds, and the wait 12-versus-15 inconsistency (table says 12 seconds per round target at 20 ships, gate text enforces 15; reconcile before the wait gate is testable). Also: 6 to 8 activations per round at a 20-ship target implies multi-ship activations or alternating subsets; the draft does not explain it.
- Density ramp versus the 20/24 envelope: Ryan wants difficulty to ramp by more ships AND leans 20 total. Reconcile (does the ceiling rise across a campaign, or does the ramp stay inside 24?).
- Motion-rule interaction: the motion rule rewards staying still, so sitting in formation must not stack a still bonus on top of the sync bonus into one dominant strategy.
- Council top 10 fix queue (chair item 1 is the save-bricking id hunt; DeepSeek Pack F ran on it, Qwen Pack G ran the guard-pattern hunt).
- CampaignSim one-line guard (the objectives crash guard; the patched harness exists in Rey's sim runs, repo untouched).
- Reanimate report (mechanics confirmation; the report gate stands).
- Economy hook scope (per-faction economy as a separately scoped engine spike, after the data-only pass).
- Data-only pass: price ladder, roster gates, prohibitions (price ladder synthesis is single-leg, see section 5).
- Kit measurement pass (per-real-class distributions, FAC3D channel mapping, handedness and orientation audit) before adopting the kit spec draft.
- Torpedo and boarding code mapping (merged proposal onto fireWeapon torp branch, boardUnit, systemDamage, st.fire, flak).
- Onboarding fixes 1 through 5 (Standard AI for fresh profiles, motion rule in the move tip, Alternating explained at battle start, one-line reward definitions, enemy-activation signal plus Threat prompt).

## 3. First commission: the barge upgrade is GO

Ryan, Oct 24 about 14:20: massive upgrades are the whole point of the audits, reviews, and research. The kit work is un-parked. The Pyre-Barge C19_51 (Corsair battle-barge, ship 1, the worked example) gets a major graphical upgrade with the new tools before any sign-off: loft v2 plus the Corsair grammar pack, desktop-only budgets, paint and material unification, the effects pass, and a material audit over the result. Ship 2 waits on the barge.

What "upgraded" means in the existing documents: the kit spec synthesis (DeepSeek draft as base, with corrections) plus the design docs (art direction, beauty corner spec, visual QA pack, graphics craft, visual expansion research). V14 (mixed-shape trimmed plating, belly slabs, uneven rows, baked finish maps) is the starting point, not the target. The v13d clean shell shape already has Ryan's OK; the upgrade is dressing, paint, materials, and effects on top of a proven shape.

## 4. How Rey orchestrated Gemini, DeepSeek, and Qwen

Method, so you can weigh every external return correctly.

- Blind legs. Each job briefed both models with the same self-contained brief (source facts embedded, OBSERVED versus PROPOSED discipline, drafts not rulings). Models were blind to each other and to Rey's prior verdicts. Three unrelated families converging is the signal; one model wearing several hats is not.
- Settings. DeepSeek chat: DeepThink ON, Search OFF. Qwen chat: locked to Qwen3.8-Max, Thinking ON, Search OFF, with an explicit stop-and-report instruction if 3.8-Max was unavailable (the chat defaults to Qwen3.7-Plus; a Qwen3.7-Plus return is the wrong model and is archived, not used, as happened with Pack J). Stop-and-report-the-number on any phone sign-in prompt. Never switch models mid-job, never upgrade membership to clear a limit.
- Screening before synthesis. Every external return was filed verbatim (em dashes normalized to hyphens on filing, wording otherwise unchanged), then screened by Rey against primary sources with grep: every quoted claim checked, every number recomputed, every code reference verified. Screening notes live in Rey's goal hidden files, not in the repo. Known failure modes, all observed: Qwen publishes pack-boundary absences as facts (things outside its pack stated as if they do not exist); both Qwen models missed the Razormaw formation carve-out; DeepSeek invents plausible stats and flags them honestly; Qwen invented a size ladder and a "cap battles at 6 heavy ships" number (barred; Ryan's ruling is about 20 total). Nothing reached Ryan's verdict unscreened.
- Synthesis. Rey chaired each job into one verdict (GO, GO WITH CONDITIONS, NO-GO) with numbered findings and one recommended next step, labeling chair scalings and single-leg status explicitly. A synthesis is a chair verdict, not a claim dump. Where legs disagreed, the synthesis says so and settles by grep or marks it contested for you or Ryan.
- Model reliability, observed across Oct 23 to 24. DeepSeek: most protocol-disciplined, best at structure, invents stats but flags them. Qwen3.8-Max: sharpest QA lens, best at catching staleness and phone leftovers, weakest at pack boundaries. Gemini: lead and idea generator ONLY, never a verifier. The Gemini verification pass tabled 70 claims: 47 verified, 18 wrong, 2 stale, 3 uncheckable. Never cite Gemini unscreened.
- Limits and pending legs. Qwen free tier has a daily Qwen3.8-Max limit, hit Oct 24 about 11:45 CDT mid-wave. Two Qwen legs blocked with no draft: price ladder and plate mapping. Ryan ruled DeepSeek-first: synthesize from DeepSeek legs now (labeled single-leg), retry the Qwen legs after the limit resets, fold them into updated two-leg syntheses. A one-time retry run is scheduled Sun Oct 25, 2026 about 09:45 CDT. Until it lands, treat reviews/price_ladder_synthesis.md and reviews/plate_mapping_synthesis.md as provisional on the Qwen dimension. Gemini hit a usage cap Oct 23 on the visual idea pack; that pack is parked, not cancelled, and its brief is local-only (see section 6).

## 5. Rey's own work: map

All under contrib/muse/ unless noted. Nothing here is approved until Ryan says so. Code claims are observations for you to confirm.

Design (contrib/muse/design/): art_direction_rey.md (colour law, silhouette grammars, 12 hero concepts, plate system, portrait template); ship_kit_upgrade.md (kit work order; its 1.32 GB texture figure is asserted without derivation, do not reuse it); visual_expansion_research.md (techniques and tools, honesty flags on licences); GRAPHICS_REFERENCES.md (reference games and repos; section 7 is Star Citizen and Squadron 42 learning only, not the feel mix); IMAGE_MANIFEST.md (the 40 final images with hashes; images are LOCAL ONLY, never pushed, because the push route is text-only); CONVERSATION_CONTEXT.md (Ryan's rulings sections 3, 6, 7, 9; the undecided list in section 7 is stale wherever section 1 above rules it); mod_scene_field_guide.md (convergence caveat added inline); tool_guides.md (still phone-first in framing; re-tier plan exists, D1 to D9 are yours); claude_skills.md; graphics_craft.md (TAA corrected: TAARenderingPipeline is separate, not inside DefaultRenderingPipeline); design_council_audit.md (Rey's five-lens audit of his own docs, GO WITH CONDITIONS, 41 findings); beauty_corner_spec.md and visual_qa_pack.md (desktop-only after the Oct 24 strike pass; colourblind shield check added to the QA pack).

Reviews (contrib/muse/reviews/): ship pipeline audit; six protocol reviews (plain parts, ship loading, battle rules, enemy AI, effects and world, UI; UI phone findings moot); independent_audit.md (ship-five source, proposal 5 is wing doctrines); career_story.md (Option B pick, now ruled); space_3d.md (delta-v bands); five-lens council plus council_reconciliation.md; Pack J reconciliation (packJ_reconciliation.md, GO WITH CONDITIONS); asymmetry synthesis and decision page; difficulty_dial_synthesis.md; onboarding_synthesis.md; kit_spec_synthesis.md (DeepSeek draft as base); torpedo_boarding_synthesis.md (revision job: both systems already exist in code); chorus_reword_synthesis.md (text picks; portrait verdicts now superseded by section 1 regenerates); price_ladder_synthesis.md (SINGLE LEG); plate_mapping_synthesis.md (SINGLE LEG); gold_law_synthesis.md; luminance_facet_synthesis.md; acceptance_measurability_synthesis.md (gold panel decided here: 7 viewers, 7/7); deathless_wording_deepseek_draft.md (single leg); tool_guides_retier_deepseek_draft.md (single leg, 49-row table); density_statement_deepseek_draft.md (single leg; 12-versus-15 catch is yours).

External legs (archive only, read solely to check a distilled claim): contrib/deepseek/reviews/ and contrib/qwen/reviews/. Raw transcripts, not evidence. Distilled claims live in the syntheses.

Compute (contrib/muse/compute/): code index (1,016 definitions, zero duplicate names); content census (45 hulls, 25 weapons, 36 boons, 12 relics, 13 modules, 24 admirals, 8 encounters, 6 factions); asset inventory (553 files, 157.5 MB; all 36 hull meshes exist in both tiers); checkpack (RUN_CHECKS.bat plus checks.js, 0 FAIL, 15 CHECK at last run); balance reference pending on the mega sim (Run 1: fuzz 2000 clean, campaign leg relaunched after two runtime kills; repo untouched, harness in Rey's sim runs).

Prompts (contrib/muse/prompts/): packJ_design_audit.txt; five drafting briefs (kit spec, torpedo and boarding, difficulty dial, onboarding lens, asymmetry briefs); second trio briefs (plate mapping, gold law, luminance facet, acceptance measurability, chorus reword, price ladder); third trio briefs (density statement, Deathless wording, tool-guides re-tier). Historical, unless another external run is commissioned.

Gemini visual idea pack: PARKED on the Oct 23 usage cap. The brief is local-only and was never pushed to GitHub at Ryan's earlier direction, so it is not in this repo and you will not find it here. Rey's own visual pack (the design docs above) replaced it as the delivered artifact. If the Gemini pack ever arrives, Rey filters it before it reaches any verdict.

## 6. Suggested ingestion order

READING_PLAN.md governs reading order; this is the short path for the barge commission and the Opus pile.

1. This briefing, then READING_PLAN.md errata (gold law repaired, density leaning 20 total with ship-count ramp, plate mapping single-leg, PC-only supersedes all phone framing).
2. Section 1 above (rulings) against CONVERSATION_CONTEXT.md sections 3, 6, 7, 9. Where they disagree, section 1 wins.
3. Kit spec synthesis plus its measurement-pass condition, then ship_kit_upgrade.md and art_direction_rey.md for the barge upgrade.
4. Gold law, luminance facet, and acceptance measurability syntheses together (they interlock: gold panel, luminance procedure, and hold rules).
5. Price ladder and plate mapping syntheses (single-leg; Qwen legs land Oct 25) before the data-only pass and any plate wiring work.
6. Torpedo and boarding synthesis, onboarding synthesis, difficulty dial synthesis, asymmetry synthesis, chorus reword synthesis, Deathless wording draft, tool-guides re-tier draft, density statement draft, Pack J reconciliation, council reconciliation.

## 7. Standing rules for anything shown to Ryan

- No em dashes, ever, including inside repo deliverables. Verify with grep; count must be 0. (Sole exception: the literal em dash character inside checkpack checks.js's own search regex.)
- Nothing goes out on his behalf without his approval first: recommendation before action, exact draft shown before sending. Settled calls are never re-raised.
- His own primary evidence outranks reviewer inference. Check his source before pushing back on a fact he saw himself.
- Reviews follow docs/REVIEW_PROTOCOL.md: raw view first, line counts and last-line starts before reviewing, never describe unseen code, mark every finding OBSERVED or INFERRED, re-check every quote, cap at ten findings with one recommended next step, close with Not checked.
- Work only inside contrib/muse/ (Rey) and your own folder (you). No game source, tools, docs, or hull assets outside a commission. Ryan runs his own artifacts as double-click .bat files (Windows 10, PowerShell 5.1).
