# Outside check: Board commit 2c5b5596 on codex/issue-463 (death fallback restored, report disclosure)

Verdict: GO.

This commit answers conditions 1 and 2 of opus_check_701 exactly as they were written, and nothing else in it reaches beyond them.

## Condition 1: the empty-pieces fallback is restored

godot/fx/fx_death.gd, _break_up_inner, in the fall-through break-up path after the timed body smoke: when pieces.is_empty(), the code now spawns one pooled physical shard (spawn_debris, count 1) and one visible ember (fx.spr, life 1.2), under a comment that names the restore and cites the check. That is main's recorded behaviour (opus_check_701: "one pooled physical shard plus a visible ember") restored as an equivalent, which is what the condition asked for. It is not byte-identical to main's old branch, and it does not need to be.

DeepSeek graded GO WITH CONDITIONS on two scope questions the pack could not answer (the pack carried the function but not its callers; that gap is the chair's). The chair answers both from the full branch file:

- Wings cannot reach the guard. In _death_inner (line 1893), wings return through _wing_death before any break-up; the sole call site of _break_up_inner (line 2614) is the break-up wrapper. The report's "Wings leave one spark and a short puff, with no wreck or physical shards" stands.
- The guard's reach matches main's. The organic early return and the big-hull timeline path both precede the fallback inside _break_up_inner, and main's fallback sat in this same fall-through spot (PR 701 deleted it from here). So the restore covers what main covered: non-organic hulls reaching break-up with no pre-cut pieces, including the degenerate case of a big hull with no death timeline, which main's fallback also caught. The report's sentence ("A small hull with no pre-cut pieces at the kill frame still throws one physical shard and an ember (the main fallback, kept by the Board)") is the small-deaths report describing its own subject; the code's slightly wider reach is main's reach, not new behaviour.

## Condition 2: the report discloses the shared flash pictures

death_small_report.md's opening paragraph now states that destroyers use their own flash row "drawn over the small row's baked flash pictures (the 384 px cells cover both, no rebake)", with their own size, life and light reach. The code agrees where the pack let the council check it (body_px 218.0 for destroyer against 180.0 otherwise, and the pop call's own comment says the 384 px cells cover both small rows without a rebake). The fallback is disclosed in the same paragraph. Both disclosures sit in the report's summary, where a reader meets them first.

## Notes

- DeepSeek, carried as a note, not a condition: the fallback keys on pieces.is_empty(). A hull whose pieces array is non-empty but whose every piece is skipped in the wreck build (empty surface lists, or a plan with no main pieces) creates no wreck nodes and does not fire the fallback, leaving a light-and-smoke-only break. That case is outside condition 1's literal scope (it is not "no pre-cut pieces"), and main's fallback had the same key, so this commit neither creates nor widens it. It is the natural next hardening if the Board ever sees the symptom in a capture.
- The restore is broader in wording than main's old comment ("Craft have no pre-cut job") and identical in placement; breadth here is main's own, per the chair's verification above.

## Legs and gates

Blind Rey leg first (chair, no pack): GO, one note (the provenance is now on the record in both the code comment and the commit message, which is what the undisclosed removal was about). DeepSeek (DeepThink on, Search off, verified before and after): GO WITH CONDITIONS, both conditions answered above from the full file. Flash (Gemini "Quick answers 3.5 Flash-Lite", verified selected before and after): GO. Qwen: seat empty, the Qwen3.8-Max daily limit was reached earlier in the evening (two confirmed attempts); no substitution was made. Grok: seat empty, bot wall at grok.com, the twenty-fourth consecutive empty seat. Both recorded, never filled.

## Not checked

Runtime behaviour of the restored fallback in a live battle (pool counts, ember visibility), the destroyer row's life and light-reach parameters beyond the report sentence and the body size in the pop call, and the rest of fx_death.gd outside _break_up_inner and its routing.
